@echo off
rem NB the installer is not actually using this file. its here
rem    just for reference.
setlocal

set SERVICE_NAME=elasticsearch
for %%I in ("%~dp0..") do set ES_HOME=%%~dpfI
set PRUNSRV=%ES_HOME%\bin\%SERVICE_NAME%w

"%PRUNSRV%" //IS//%SERVICE_NAME%
