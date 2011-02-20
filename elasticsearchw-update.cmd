@echo off
setlocal

set SERVICE_NAME=elasticsearch
for %%I in ("%~dp0..") do set ES_HOME=%%~dpfI
set ES_LIB=%ES_HOME%\lib
set PRUNSRV=%ES_HOME%\bin\%SERVICE_NAME%w

rem Initial memory pool size in MB.
set JVM_MS=256
rem Maximum memory pool size in MB.
set JVM_MX=1024
rem Other options.
rem NB the pound (#) and semicolon (;) are separator characters.
set JVM_OPTIONS=-Djline.enabled=false^
#-XX:+AggressiveOpts^
#-XX:+UseParNewGC^
#-XX:+UseConcMarkSweepGC^
#-XX:+CMSParallelRemarkEnabled^
#-XX:+HeapDumpOnOutOfMemoryError

set JVM_CLASSPATH=%ES_LIB%\*;%ES_LIB%\sigar\*

"%PRUNSRV%" //US//%SERVICE_NAME% ^
  --Jvm=auto ^
  --StdOutput auto ^
  --StdError auto ^
  --LogPath "%ES_HOME%\logs" ^
  --StartPath "%ES_HOME%" ^
  --StartMode=jvm --StartClass=org.elasticsearch.service.Service --StartMethod=start ^
  --StopMode=jvm --StopClass=org.elasticsearch.service.Service --StopMethod=stop ^
  --Classpath "%JVM_CLASSPATH%" ^
  --JvmMs %JVM_MS% ^
  --JvmMx %JVM_MX% ^
  --JvmOptions "%JVM_OPTIONS%" ^
  ++JvmOptions "-Des.path.home=%ES_HOME%"

rem These settings are saved in the Windows Registry at:
rem
rem    HKEY_LOCAL_MACHINE\SOFTWARE\Apache Software Foundation\Procrun 2.0\elasticsearch
rem
rem OR, on windows 64-bit when running procrun 32-bit, at:
rem
rem    HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0\elasticsearch
rem
rem See http://commons.apache.org/daemon/procrun.html