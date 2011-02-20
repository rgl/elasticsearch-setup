@echo off
setlocal

set SERVICE_NAME=elasticsearch
for %%I in ("%~dp0..") do set ES_HOME=%%~dpfI
set PRUNSRV=%ES_HOME%\bin\%SERVICE_NAME%w

"%PRUNSRV%" //DS//%SERVICE_NAME%
