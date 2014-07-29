// developed by Rui Lopes (ruilopes.com). licensed under GPLv3.

// TODO set a global timeout and abort the process if it expires.

phantom.onError = function(msg, trace) {
  var msgStack = ["PHANTOM ERROR: " + msg];
  if (trace && trace.length) {
    msgStack.push("TRACE:");
    trace.forEach(function(t) {
      msgStack.push(" -> " + (t.file || t.sourceURL) + ": " + t.line + (t.function ? " (in function " + t.function + ")" : ""));
    });
  }
  console.error(msgStack.join("\n"));
  phantom.exit(2);
};

function printArgs() {
  var i, ilen;
  for (i = 0, ilen = arguments.length; i < ilen; ++i) {
    console.log("    arguments[" + i + "] = " + JSON.stringify(arguments[i]));
  }
  console.log("");
}

function open(url, cb) {
  var page = require("webpage").create();

  // window.console.log(msg);
  page.onConsoleMessage = function() {
    console.log("page console:");
    printArgs.apply(this, arguments);
  };

  // NB even thou the global phantom.onError should have run when there is a
  //    page error... in practice, it does not happen on phantom 1.9.7... so
  //    set the handler on the page too.
  // See https://github.com/ariya/phantomjs/wiki/API-Reference-phantom#onerror
  page.onError = phantom.onError;

  page.open(url, function(status) { cb(page, status); });
}

// as-of phantomjs 1.9.7, things returned from page.evaluate are read-only,
// this function makes them read-write by JSON serializing.
function rw(o) {
  return JSON.parse(JSON.stringify(o));
};

function getIndexFromPage(page, filter) {
  return page.evaluate(function() {
    var $$ = function(selector) {
      return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
    };

    // look for url alike:
    //    http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html
    //    http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html
    //
    // and return something like:
    //    [
    //      {
    //        version: "8",
    //        type: "client",
    //        url: "http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html"
    //      }
    //    ]

    var index = $$("a[href*='javase/downloads/server-jre'], a[href*='javase/downloads/jre']").map(function(a) {
      var m = a.href.match(/[\-/]((server)-)?jre([^-]+)-/);
      return {
        version: m[3],
        type: m[2] || "client",
        url: a.href
      };
    });

    return index;
  }).filter(function(v) {
    return v &&
            v.version.match(filter.version) &&
            v.type.match(filter.type);
  });
}

function getVersionsFromPage(page) {
  return page.evaluate(function() {
    // Patch since PhantomJS does not implement click() on HTMLElement.
    if (!HTMLElement.prototype.click) {
      HTMLElement.prototype.click = function() {
        var ev = document.createEvent("MouseEvent");
        ev.initMouseEvent(
          "click",
          true, // bubble
          true, // cancelable
          window,
          null,
          0, 0, 0, 0, // coordinates
          false, false, false, false, // modifier keys
          0, // button=left
          null
        );
        this.dispatchEvent(ev);
      };
    }

    var $ = function(selector) {
      return document.querySelector(selector);
    };

    var $$ = function(selector) {
      return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
    };

    // accept the agreement so it reveals the href
    $("input[onclick*='acceptAgreement']").click();

    return $$("a[onclick*='youMustAgree']").map(function(a) {
      // TODO parse os, arch, type, version from url.
      return {
        name: a.innerText.trim(),
        url: a.href
      };
    });
  });
}

function toCookieJar(cookies) {
  // See https://github.com/bagder/curl/blob/master/lib/cookie.c
  // See https://github.com/bagder/curl/blob/master/lib/parsedate.c

  // example cookie:
  //
  //    {
  //      "domain": ".oracle.com",
  //      "expires": "qui, 28 jul 2016 16:56:35 GMT",
  //      "expiry": 1469724995,
  //      "httponly": false,
  //      "name": "s_cc",
  //      "path": "/",
  //      "secure": false,
  //      "value": "true"
  //    }
  //
  // is returned as:
  //
  //    Set-cookie: s_cc=true; domain=.oracle.com; path=/; expires=Tue, 28 Jul 2014 16:56:35 GMT

  return cookies.map(function(c) {
    return "Set-cookie: " +
              c.name + "=" + c.value +
              ";domain=" + c.domain +
              ";path=" + c.path +
              ((c.expires && ";expires=" + (new Date(c.expiry * 1000)).toUTCString()) || "") +
              ((c.httponly && ";HttpOnly") || "") +
              ((c.secure && ";secure") || "")
              ;
  }).join("\n") + "\n";
}

function getLatestVersions(filter, cb) {
  open("http://www.oracle.com/technetwork/java/javase/downloads/index.html", function(page, status) {
    if (status !== "success") {
      console.log("ERROR: Unable to access network:", status);
      phantom.exit(1);
      return;
    }

    var index = rw(getIndexFromPage(page, filter));

    page.close();

    //
    // go into all download pages and grab the available versions.

    var versions = [];

    function process(i, cb) {
      open(i.url, function(page, status) {
        if (status !== "success") {
          console.log("ERROR: Unable to access network:", status);
          phantom.exit(1);
          return;
        }

        var cookies = rw(phantom.cookies);
        var cookieJar = toCookieJar(phantom.cookies);

        var pageVersions = getVersionsFromPage(page)
          .filter(function(v) {
            return v.url.match(filter.url);
          })
          .map(function(v) {
            v.cookies = cookies;
            v.cookieJar = cookieJar;
            return v;
          });

        versions.push.apply(versions, pageVersions);

        page.close();

        cb();
      });
    }

    function next() {
      if (index.length == 0) {
        cb(versions);
        phantom.exit(0);
        return;
      }

      process(index.shift(), next);
    }

    next();
  });
}

function main() {
  // TODO accept the filter from command line.
  var filter = {
    // accept only version 8.
    version: /^8/,

    // type: server|client.
    type: /.+/,

    // accept only windows tar balls versions.
    // e.g. http://.../server-jre-8u11-windows-x64.tar.gz
    url: /-windows-.+\.tar\.gz$/
  };

  getLatestVersions(filter, function(versions) {
    var seen = [];

    versions.forEach(function(version) {
      if (!version.name.match(/^[0-9a-z\.\-]+$/))
        throw "invalid name " + version.name;

      var bits = version.name.indexOf("x64") > 0 ? 64 : 32;

      // we just want the latest version of each bits. this works because the
      // server returns the versions in the preferable order.
      if (seen.indexOf(bits) >= 0)
        return;
      seen.push(bits);

      var vendorPath = "vendor/jre-" + bits;
      var tarballPath = vendorPath + "/" + version.name;
      var cookie = "oraclelicense=accept-securebackup-cookie";

      if (false) {
        // this is here just in case they change the way the license is accepted.
        // here we can store all the cookies.
        var fs = require("fs");

        var cookiesFilename = version.name + ".cookies.txt";

        fs.write(cookiesFilename, version.cookieJar, "w");

        cookie = cookiesFilename;
      }

      // TODO if vendor/$(version.name) does not exists, download it, and extract
      //      into vendor/jre-32 or vendor/jre-64.

      var commandLine = "rm -rf " + vendorPath + " && mkdir " + vendorPath
         + " && curl --insecure -b " + cookie + " -L -o " + tarballPath + " " + version.url
         // NB we do not extract the tarball ourself because on windows tar is fubar with warnings like:
         //     tar: Archive value 127667 is out of uid_t range 0..65535
         //    and 7z does not directly support extracting a tarball... well,
         //    maybe another day I'll fix this to download things automatically...
         + " && echo now extract " + tarballPath + " into " + vendorPath + " and move the jre sub-directory within to " + vendorPath
         //+ " && tar xf " + tarballPath + " -C " + vendorPath
         ;

      console.log(commandLine);
    });
  });
}

main();
