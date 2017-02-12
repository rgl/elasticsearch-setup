@echo off
setlocal

set SERVICE_NAME=elasticsearch
set ES_VERSION=@@ES_VERSION@@
set ES_BITS=@@ES_BITS@@
for %%I in ("%~dp0..") do set ES_HOME=%%~dpfI
set ES_LIB=%ES_HOME%\lib
set PRUNSRV=%ES_HOME%\bin\%SERVICE_NAME%w

rem Initial memory pool size in MB.
set JVM_MS=1024
rem Maximum memory pool size in MB.
set JVM_MX=1024

rem Other options.
rem NB the pound (#) and semicolon (;) are separator characters.

rem Force the JVM to use IPv4 stack
rem JVM_OPTIONS=%JVM_OPTIONS% -Djava.net.preferIPv4Stack=true

rem GC configuration.
set JVM_OPTIONS=%JVM_OPTIONS% -XX:+UseConcMarkSweepGC
set JVM_OPTIONS=%JVM_OPTIONS% -XX:CMSInitiatingOccupancyFraction=75
set JVM_OPTIONS=%JVM_OPTIONS% -XX:+UseCMSInitiatingOccupancyOnly

rem Pre-touch memory pages used by the JVM during initialization.
set JVM_OPTIONS=%JVM_OPTIONS% -XX:+AlwaysPreTouch

REM GC logging options -- uncomment to enable
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:+PrintGCDetails
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:+PrintGCTimeStamps
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:+PrintGCDateStamps
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:+PrintClassHistogram
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:+PrintTenuringDistribution
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:+PrintGCApplicationStoppedTime
REM JVM_OPTIONS=%JVM_OPTIONS% -Xloggc:%ES_HOME%/logs/gc.log

REM Causes the JVM to dump its heap on OutOfMemory.
set JVM_OPTIONS=%JVM_OPTIONS% -XX:+HeapDumpOnOutOfMemoryError
REM The path to the heap dump location, note directory must exists and have enough
REM space for a full heap dump.
REM JVM_OPTIONS=%JVM_OPTIONS% -XX:HeapDumpPath=$ES_HOME/logs/heapdump.hprof

REM Disables explicit GC
set JVM_OPTIONS=%JVM_OPTIONS% -XX:+DisableExplicitGC

REM Ensure UTF-8 encoding by default (e.g. filenames)
set JVM_OPTIONS=%JVM_OPTIONS% -Dfile.encoding=UTF-8

REM Use our provided JNA always versus the system one
set JVM_OPTIONS=%JVM_OPTIONS% -Djna.nosys=true

REM Flags to configure Netty
set JVM_OPTIONS=%JVM_OPTIONS% -Dio.netty.noUnsafe=true
set JVM_OPTIONS=%JVM_OPTIONS% -Dio.netty.noKeySetOptimization=true
set JVM_OPTIONS=%JVM_OPTIONS% -Dio.netty.recycler.maxCapacityPerThread=0

REM log4j 2
set JVM_OPTIONS=%JVM_OPTIONS% -Dlog4j.shutdownHookEnabled=false
set JVM_OPTIONS=%JVM_OPTIONS% -Dlog4j2.disable.jmx=true
set JVM_OPTIONS=%JVM_OPTIONS% -Dlog4j.skipJansi=true

set JVM_CLASSPATH=%ES_LIB%\elasticsearch-%ES_VERSION%.jar;%ES_LIB%\*

set JVM=auto
if exist "%ES_HOME%\jre\bin\server\jvm.dll" set JVM=%ES_HOME%\jre\bin\server\jvm.dll
if exist "%ES_HOME%\jre\bin\client\jvm.dll" set JVM=%ES_HOME%\jre\bin\client\jvm.dll

"%PRUNSRV%" //US//%SERVICE_NAME% ^
  --Jvm "%JVM%" ^
  --DisplayName "Elasticsearch v%ES_VERSION% (%ES_BITS%-bit)" ^
  --StdOutput auto ^
  --StdError auto ^
  --LogPath "%ES_HOME%\logs" ^
  --StartPath "%ES_HOME%" ^
  --StartMode jvm ^
  --StartClass org.elasticsearch.bootstrap.Elasticsearch ^
  --StartMethod main ^
  --StopMode jvm ^
  --StopClass org.elasticsearch.bootstrap.Elasticsearch ^
  --StopMethod close ^
  --Classpath "%JVM_CLASSPATH%" ^
  --JvmMs %JVM_MS% ^
  --JvmMx %JVM_MX% ^
  %JVM_OPTIONS: = ++JvmOptions % ^
  ++JvmOptions "-Des.path.home=%ES_HOME%"

rem These settings are saved in the Windows Registry at:
rem
rem    HKEY_LOCAL_MACHINE\SOFTWARE\Apache Software Foundation\Procrun 2.0\elasticsearch
rem
rem OR, on windows 64-bit procrun always uses the 32-bit registry at:
rem
rem    HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0\elasticsearch
rem
rem See http://commons.apache.org/daemon/procrun.html
