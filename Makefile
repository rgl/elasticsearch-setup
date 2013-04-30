X64?= false

ES_VERSION=0.90.0
ES_NAME=elasticsearch-$(ES_VERSION)
ES_HOME=vendor/$(ES_NAME)
ES_LIB=$(ES_HOME)/lib
ES_JAR=$(ES_LIB)/$(ES_NAME).jar

COMMONS_DAEMON_VERSION=1.0.11
COMMONS_DAEMON_NAME=commons-daemon-$(COMMONS_DAEMON_VERSION)-bin-windows
COMMONS_DAEMON_HOME=vendor/$(COMMONS_DAEMON_NAME)
ifeq ($(X64),false)
COMMONS_DAEMON_PRUNSRV=$(COMMONS_DAEMON_HOME)/prunsrv.exe
else
COMMONS_DAEMON_PRUNSRV=$(COMMONS_DAEMON_HOME)/amd64/prunsrv.exe
endif

ISCC?= '/c/Program Files (x86)/Inno Setup 5/ISCC.exe'

ifneq ($(X64),false)
ISCCOPT+= -d_WIN64
endif

all: 32bit 64bit

32bit:
	@X64=false $(MAKE) setup

64bit:
	@X64=true $(MAKE) setup

jar: elasticsearchw.jar

elasticsearchw.jar: src/org/elasticsearch/service/*.java
	mkdir -p out
	javac -d out -target 6 -source 6 -cp "$(ES_LIB)/elasticsearch-$(ES_VERSION).jar" src/org/elasticsearch/service/*.java	
	jar cvf $@ -C out .

setup-helper.dll: src/setup-helper.c
	gcc -o $@ -shared -std=gnu99 -pedantic -Os -Wall -m32 -Wl,--kill-at $< -lnetapi32 -ladvapi32
	strip $@

setup: setup-helper.dll vendor jar
	$(ISCC) elasticsearch.iss $(ISCCOPT)

vendor: $(ES_JAR) $(COMMONS_DAEMON_PRUNSRV)

$(ES_JAR):
	wget -O $(ES_HOME).zip http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$(ES_VERSION).zip
	(cd vendor && md5sum -c $(ES_NAME).zip.md5)
	unzip -d vendor $(ES_HOME).zip

$(COMMONS_DAEMON_PRUNSRV):
	wget -O $(COMMONS_DAEMON_HOME).zip http://apache.org/dist/commons/daemon/binaries/windows/$(COMMONS_DAEMON_NAME).zip
	(cd vendor && md5sum -c $(COMMONS_DAEMON_NAME).zip.md5)
	unzip -d $(COMMONS_DAEMON_HOME) $(COMMONS_DAEMON_HOME).zip

clean:
	rm -rf $(ES_HOME){,.zip}
	rm -rf $(COMMONS_DAEMON_HOME){,.zip}
	rm -rf out
	rm -f *.{jar,exe,dll}

.PHONY: all jar setup vendor clean 32bit 64bit
