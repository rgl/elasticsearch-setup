X64?= false

ES_VERSION=1.3.1
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

ISCC?= '/c/Program Files (x86)/Inno Setup 5/ISCC.exe'

ifneq ($(X64),false)
ISCCOPT+= -d_WIN64
endif

all: 32bit 64bit

32bit:
	@X64=false $(MAKE) setup

64bit:
	@X64=true $(MAKE) setup

setup-helper.dll: src/setup-helper.c
	gcc -o $@ -shared -std=gnu99 -pedantic -Os -Wall -m32 -Wl,--kill-at $< -lnetapi32 -ladvapi32 -luserenv
	strip $@

# NB when you run this outside an Administrator console, UAC will trigger
#    because this executable has the word "setup" in its name.
setup-helper-console.exe: src/setup-helper-console.c src/setup-helper.c
	gcc -o $@ -std=gnu99 -pedantic -Os -Wall -m32 src/setup-helper-console.c -lnetapi32 -ladvapi32 -luserenv
	strip $@

setup: setup-helper.dll vendor $(ES_SERVICE_UPDATE_CMD) $(ES_SERVICE_EXE)
	$(ISCC) elasticsearch.iss $(ISCCOPT)

vendor: $(ES_JAR) $(COMMONS_DAEMON_PRUNSRV) $(JRE)

$(ES_SERVICE_UPDATE_CMD): $(ES_SERVICE_UPDATE_CMD_SRC)
	sed -e "s,@@ES_BITS@@,$(ES_BITS),g" \
		-e "s,@@ES_VERSION@@,$(ES_VERSION),g" \
		$(ES_SERVICE_UPDATE_CMD_SRC) > $(ES_SERVICE_UPDATE_CMD)

$(ES_SERVICE_EXE): $(COMMONS_DAEMON_PRUNSRV)
	cp $(COMMONS_DAEMON_PRUNSRV) $(ES_SERVICE_EXE).tmp
	vendor/verpatch-1.0.10/verpatch $(ES_SERVICE_EXE).tmp $(ES_VERSION) //fn //high //s description "Elasticsearch v$(ES_VERSION) ($(ES_BITS)-bit)"
	mv $(ES_SERVICE_EXE).tmp $(ES_SERVICE_EXE)

$(ES_JAR):
	wget -O $(ES_HOME).zip http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$(ES_VERSION).zip
	(cd vendor && md5sum -c $(ES_NAME).zip.md5)
	unzip -d vendor $(ES_HOME).zip

$(COMMONS_DAEMON_PRUNSRV):
	wget -O $(COMMONS_DAEMON_HOME).zip http://apache.org/dist/commons/daemon/binaries/windows/$(COMMONS_DAEMON_NAME).zip
	(cd vendor && md5sum -c $(COMMONS_DAEMON_NAME).zip.md5)
	unzip -d $(COMMONS_DAEMON_HOME) $(COMMONS_DAEMON_HOME).zip

$(JRE):
	@printf "\n\nyou must manually download JRE by running the following commands:\n\n"
	@phantomjs jre.js
	@printf "\n\n"
	@false

clean:
	rm -rf $(ES_HOME){,.zip}
	rm -rf $(COMMONS_DAEMON_HOME){,.zip}
	rm -rf out
	rm -f *.{jar,exe,dll}
	rm -rf vendor/jre-{32,64}

.PHONY: all jar setup vendor clean 32bit 64bit
