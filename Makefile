X64?= false

ES_FILE_VERSION=5.6.2
ES_VERSION=$(ES_FILE_VERSION)
ES_SHA512=db4ec26915d2dc1673307522c168560f2ff7aa6cd3834d2d19effd398c05881b4cb2b08cbad3c8e7dd223a91ddfa2ff8401aae7ac9d69805dc1db8b88d30e393
ES_NAME=elasticsearch-$(ES_VERSION)
ES_HOME=vendor/$(ES_NAME)
ES_LIB=$(ES_HOME)/lib
ES_JAR=$(ES_LIB)/$(ES_NAME).jar
ifeq ($(X64),false)
ES_BITS=32
else
ES_BITS=64
endif

JRE_HOME=vendor/jre-$(ES_BITS)/jre
JRE=$(JRE_HOME)/bin/java.exe

COMMONS_DAEMON_VERSION=1.0.15
COMMONS_DAEMON_NAME=commons-daemon-$(COMMONS_DAEMON_VERSION)-bin-windows
COMMONS_DAEMON_HOME=vendor/$(COMMONS_DAEMON_NAME)
ifeq ($(X64),false)
COMMONS_DAEMON_PRUNSRV=$(COMMONS_DAEMON_HOME)/prunsrv.exe
else
COMMONS_DAEMON_PRUNSRV=$(COMMONS_DAEMON_HOME)/amd64/prunsrv.exe
endif

ES_SERVICE_EXE=$(ES_HOME)/bin/elasticsearchw-$(ES_BITS).exe

ES_SERVICE_UPDATE_CMD_SRC=elasticsearchw-update.cmd
ES_SERVICE_UPDATE_CMD=$(ES_HOME)/lib/elasticsearchw-update-$(ES_BITS).cmd

ES_CMD_CMD_SRC=elasticsearch-cmd.cmd
ES_CMD_CMD=$(ES_HOME)/lib/elasticsearch-cmd.cmd

SETEXECUTABLEICON_EXE=vendor/SetExecutableIcon.exe

ISCC?= '/c/Program Files (x86)/Inno Setup 5/ISCC.exe'

ifneq ($(X64),false)
ISCCOPT+= -d_WIN64
endif

all: 64bit

32bit:
	@X64=false $(MAKE) setup

64bit:
	@X64=true $(MAKE) setup

setup-helper.dll: src/setup-helper.c
	gcc -o $@ -shared -std=gnu99 -pedantic -Os -Wall -m32 -Wl,--kill-at $< -lnetapi32 -ladvapi32 -luserenv
	strip $@

HasUnlimitedStrength.class: src/HasUnlimitedStrength.java
	javac -d . $<

# NB when you run this outside an Administrator console, UAC will trigger
#    because this executable has the word "setup" in its name.
setup-helper-console.exe: src/setup-helper-console.c src/setup-helper.c
	gcc -o $@ -std=gnu99 -pedantic -Os -Wall -m32 src/setup-helper-console.c -lnetapi32 -ladvapi32 -luserenv
	strip $@

setup: setup-helper.dll vendor $(ES_CMD_CMD) $(ES_SERVICE_UPDATE_CMD) $(ES_SERVICE_EXE)
	$(ISCC) elasticsearch.iss $(ISCCOPT) -dAppVersion=$(ES_VERSION) -dVersionInfoVersion=$(ES_FILE_VERSION)

vendor: $(ES_JAR) $(COMMONS_DAEMON_PRUNSRV) $(JRE)

$(ES_CMD_CMD): $(ES_CMD_CMD_SRC)
	sed -e "s,@@ES_VERSION@@,$(ES_VERSION),g" \
		$(ES_CMD_CMD_SRC) > $(ES_CMD_CMD)

$(ES_SERVICE_UPDATE_CMD): $(ES_SERVICE_UPDATE_CMD_SRC)
	sed -e "s,@@ES_BITS@@,$(ES_BITS),g" \
		-e "s,@@ES_VERSION@@,$(ES_VERSION),g" \
		$(ES_SERVICE_UPDATE_CMD_SRC) > $(ES_SERVICE_UPDATE_CMD)

$(ES_SERVICE_EXE): $(COMMONS_DAEMON_PRUNSRV) $(SETEXECUTABLEICON_EXE)
	cp $(COMMONS_DAEMON_PRUNSRV) $(ES_SERVICE_EXE).tmp
	vendor/verpatch-1.0.10/verpatch $(ES_SERVICE_EXE).tmp $(ES_VERSION) //fn //high //s description "Elasticsearch v$(ES_VERSION) ($(ES_BITS)-bit)"
	$(SETEXECUTABLEICON_EXE) elasticsearch.ico $(ES_SERVICE_EXE).tmp
	mv $(ES_SERVICE_EXE).tmp $(ES_SERVICE_EXE)

$(ES_JAR):
	wget -qO $(ES_HOME).zip https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$(ES_VERSION).zip
	[ `openssl sha512 $(ES_HOME).zip | awk '{print $$2}'` == $(ES_SHA512) ]
	rm -rf vendor-tmp && mkdir vendor-tmp
	unzip -q -d vendor-tmp $(ES_HOME).zip
	for batch in vendor-tmp/elasticsearch-*/bin/elasticsearch-*.bat; do \
		sed -i -E 's,(@echo off),\1\n\nfor %%I in ("%~dp0..") do set JAVA_HOME=%%~dpfI\\jre,' "$$batch"; \
		unix2dos "$$batch"; \
	done
	mv vendor-tmp/elasticsearch-* vendor
	rmdir vendor-tmp

$(COMMONS_DAEMON_PRUNSRV):
	wget -qO $(COMMONS_DAEMON_HOME).zip http://apache.org/dist/commons/daemon/binaries/windows/$(COMMONS_DAEMON_NAME).zip
	(cd vendor && md5sum -c $(COMMONS_DAEMON_NAME).zip.md5)
	unzip -q -d $(COMMONS_DAEMON_HOME) $(COMMONS_DAEMON_HOME).zip

$(SETEXECUTABLEICON_EXE):
	wget -qO $@ https://github.com/rgl/SetExecutableIcon/releases/download/v0.0.1/SetExecutableIcon.exe

$(JRE): HasUnlimitedStrength.class
	rm -rf vendor/jre-64
	mkdir vendor/jre-64
	curl \
		--silent \
		--insecure \
		-L \
		-b oraclelicense=accept-securebackup-cookie \
		-o vendor/jre-64/server-jre-8u144-windows-x64.tar.gz \
		http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/server-jre-8u144-windows-x64.tar.gz
	[ `openssl sha256 vendor/jre-64/server-jre-8u144-windows-x64.tar.gz | awk '{print $$2}'` == '20d5e1b2b4c789b6d0c378ffa9b2ff12448f31f0224ba482a338790cff18020a' ]
	tar xf vendor/jre-64/server-jre-*.tar.gz -C vendor/jre-64
	mv vendor/jre-64/jdk*/jre vendor/jre-64
	curl \
		--silent \
		--insecure \
		-L \
		-b oraclelicense=accept-securebackup-cookie \
		-o vendor/jre-64/jce_policy-8.zip \
		http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
	unzip vendor/jre-64/jce_policy-8.zip -d vendor/jre-64
	mv vendor/jre-64/UnlimitedJCEPolicy*/*.jar vendor/jre-64/jre/lib/security
	[ "$$(./vendor/jre-64/jre/bin/java HasUnlimitedStrength)" == 'YES' ]
	# NB if you need to update the JRE run phantomjs jre.js

clean:
	rm -rf $(ES_HOME){,.zip}
	rm -rf $(COMMONS_DAEMON_HOME){,.zip}
	rm -f $(SETEXECUTABLEICON_EXE)
	rm -rf out
	rm -f *.{class,jar,exe,dll}
	rm -rf vendor/jre-{32,64}

.PHONY: all jar setup vendor clean 32bit 64bit
