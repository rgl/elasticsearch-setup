; elasticsearch for Windows Setup Script created by Rui Lopes (ruilopes.com).
;
; TODO there seems to be a bug with procrun install, it will append data to the
;       HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0\elasticsearch\Parameters\Java\@Options
;      instead of override it. this can be problematic if we install the
;      application over an existing installation
; TODO do not override existing configuration files. 
; TODO after uninstall, setup-helper.dll is left behind... figure out why its
;      not being automatically deleted.
; TODO sign the setup?
;      NB: Unizeto Certum has free certificates to open-source authors.
;      See http://www.certum.eu/certum/cert,offer_software_publisher.xml
;      See https://developer.mozilla.org/en/Signing_a_XPI

#define ServiceAccountName "elasticsearch"
#define ServiceName "elasticsearch"
#define AppVersion "0.18.7"
#define ESPath "vendor\elasticsearch-" + AppVersion
#ifdef _WIN64
#define Bits "64"
#define ArchitecturesInstallIn64BitMode "x64"
#define ArchitecturesAllowed "x64"
#define Prunsrv "amd64\prunsrv.exe"
#else
#define Bits "32"
#define ArchitecturesInstallIn64BitMode
#define ArchitecturesAllowed "x86 x64"
#define Prunsrv "prunsrv.exe"
#endif

[Setup]
ArchitecturesInstallIn64BitMode={#ArchitecturesInstallIn64BitMode}
ArchitecturesAllowed={#ArchitecturesAllowed}
AppID={{BBFE3D83-0850-4E17-8BCC-860945E4F485}
AppName=elasticsearch
AppVersion={#AppVersion}
VersionInfoVersion={#AppVersion}
;AppVerName=Redis {#AppVersion}
AppPublisher=rgl
AppPublisherURL=https://github.com/rgl/elasticsearch-setup
AppSupportURL=https://github.com/rgl/elasticsearch-setup
AppUpdatesURL=https://github.com/rgl/elasticsearch-setup
DefaultDirName={pf}\elasticsearch
DefaultGroupName=elasticsearch
OutputDir=.
OutputBaseFilename=elasticsearch-{#AppVersion}-setup-{#Bits}-bit
SetupIconFile=elasticsearch.ico
Compression=lzma2/max
SolidCompression=yes
WizardImageFile=wizard.bmp
WizardImageBackColor=$000000
WizardImageStretch=no
WizardSmallImageFile=wizard-small.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{app}\bin"
Name: "{app}\config"
Name: "{app}\data"
Name: "{app}\logs"

[Files]
Source: "setup-helper.dll"; DestDir: "{app}"
Source: "vendor\SetACL-2.2.0\SetACL.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall ignoreversion
Source: "vendor\commons-daemon-1.0.8-bin-windows\{#Prunsrv}"; DestDir: "{app}\bin"; DestName: "elasticsearchw.exe"
Source: "{#ESPath}\bin\elasticsearch.bat"; DestDir: "{app}\bin"
Source: "{#ESPath}\bin\plugin.bat"; DestDir: "{app}\bin"
Source: "{#ESPath}\lib\elasticsearch-{#AppVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\jline-0.9.94.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\jna-3.2.7.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\log4j-1.2.16.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-analyzers-3.5.0.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-core-3.5.0.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-highlighter-3.5.0.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-memory-3.5.0.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-queries-3.5.0.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\sigar\sigar-1.6.4.jar"; DestDir: "{app}\lib\sigar"
Source: "{#ESPath}\lib\sigar\sigar-amd64-winnt.dll"; DestDir: "{app}\lib\sigar"; Flags: ignoreversion
Source: "{#ESPath}\lib\sigar\sigar-x86-winnt.dll"; DestDir: "{app}\lib\sigar"; Flags: ignoreversion
Source: "{#ESPath}\config\elasticsearch.yml"; DestDir: "{app}\config"
Source: "{#ESPath}\config\logging.yml"; DestDir: "{app}\config"
Source: "{#ESPath}\README.textile"; DestDir: "{app}"; DestName: "README.txt"; Flags: isreadme
Source: "{#ESPath}\NOTICE.txt"; DestDir: "{app}"
Source: "{#ESPath}\LICENSE.txt"; DestDir: "{app}"
Source: "elasticsearchw.jar"; DestDir: "{app}\lib"
Source: "elasticsearchw-update.cmd"; DestDir: "{app}\lib"
Source: "elasticsearchw-uninstall.cmd"; DestDir: "{app}\lib"
Source: "elasticsearch Home.url"; DestDir: "{app}"
Source: "elasticsearch Setup Home.url"; DestDir: "{app}"
Source: "elasticsearch Guide.url"; DestDir: "{app}"

[Icons]
Name: "{group}\elasticsearch Home"; Filename: "{app}\elasticsearch Home.url"
Name: "{group}\elasticsearch Setup Home"; Filename: "{app}\elasticsearch Setup Home.url"
Name: "{group}\elasticsearch Guide"; Filename: "{app}\elasticsearch Guide.url"
Name: "{group}\elasticsearch Read Me"; Filename: "{app}\README.txt"
Name: "{group}\elasticsearch License"; Filename: "{app}\LICENSE.txt"
Name: "{group}\Uninstall elasticsearch"; Filename: "{uninstallexe}"

[Run]
Filename: "{tmp}\SetACL.exe"; Parameters: "-on config -ot file -actn setprot -op ""dacl:p_nc;sacl:p_nc"" -actn ace -ace ""n:Administrators;p:full"" -ace ""n:{#ServiceAccountName};p:read"""; WorkingDir: "{app}"; Flags: runhidden;
Filename: "{tmp}\SetACL.exe"; Parameters: "-on data -ot file -actn setprot -op ""dacl:p_nc;sacl:p_nc"" -actn ace -ace ""n:Administrators;p:full"" -ace ""n:{#ServiceAccountName};p:full"""; WorkingDir: "{app}"; Flags: runhidden;
Filename: "{tmp}\SetACL.exe"; Parameters: "-on logs -ot file -actn setprot -op ""dacl:p_nc;sacl:p_nc"" -actn ace -ace ""n:Administrators;p:full"" -ace ""n:{#ServiceAccountName};p:full"""; WorkingDir: "{app}"; Flags: runhidden;
Filename: "{app}\lib\elasticsearchw-update.cmd"; WorkingDir: "{app}"; Flags: runhidden shellexec waituntilterminated;

[UninstallRun]
Filename: "{app}\lib\elasticsearchw-uninstall.cmd"; WorkingDir: "{app}"; Flags: runhidden shellexec waituntilterminated;

[Code]
#include "service.pas"
#include "service-account.pas"
#include "java.pas"

const
  SERVICE_ACCOUNT_NAME = '{#ServiceAccountName}';
  SERVICE_ACCOUNT_DESCRIPTION = '{#ServiceName} Service';
  SERVICE_NAME = '{#ServiceName}';
  SERVICE_DISPLAY_NAME = '{#ServiceName}';
  SERVICE_DESCRIPTION = 'Distributed Search Engine';

const
  LM20_PWLEN = 14;

function GeneratePassword: string;
var
  N: integer;
begin
  for N := 1 to LM20_PWLEN do
  begin
    Result := Result + Chr(33 + Random(255 - 33));
  end;
end;

function InitializeSetup(): boolean;
begin
  Result := RequireJava('1.6');
  if not Result then
    Exit;

  if IsServiceRunning(SERVICE_NAME) then
  begin
    MsgBox('Please stop the ' + SERVICE_NAME + ' service before running this install', mbError, MB_OK);
    Result := false;
  end
  else
    Result := true
end;

function InitializeUninstall(): boolean;
begin
  if IsServiceRunning(SERVICE_NAME) then
  begin
    MsgBox('Please stop the ' + SERVICE_NAME + ' service before running this uninstall', mbError, MB_OK);
    Result := false;
  end
  else
    Result := true;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ServicePath: string;
  Password: string;
  Status: integer;
begin
  case CurStep of
    ssInstall:
      begin
        if ServiceAccountExists(SERVICE_ACCOUNT_NAME) <> 0 then
        begin
          Password := GeneratePassword;

          Status := CreateServiceAccount(SERVICE_ACCOUNT_NAME, Password, SERVICE_ACCOUNT_DESCRIPTION);

          if Status <> 0 then
          begin
            MsgBox('Failed to create service account for ' + SERVICE_ACCOUNT_NAME + ' (#' + IntToStr(Status) + ')' #13#13 'You need to create it manually.', mbError, MB_OK);
          end;
        end;

        if IsServiceInstalled(SERVICE_NAME) then
          Exit;

        ServicePath := ExpandConstant('{app}\bin\elasticsearchw.exe //RS//' + SERVICE_NAME);

        if not InstallService(ServicePath, SERVICE_NAME, SERVICE_DISPLAY_NAME, SERVICE_DESCRIPTION, SERVICE_WIN32_OWN_PROCESS, SERVICE_AUTO_START, SERVICE_ACCOUNT_NAME, Password) then
        begin
          MsgBox('Failed to install the ' + SERVICE_NAME + ' service.' #13#13 'You need to install it manually.', mbError, MB_OK)
        end
      end
  end
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Status: integer;
begin
  case CurUninstallStep of
    usPostUninstall:
      begin
        // NB the service should already be uinstalled (by elasticsearchw-uninstall.cmd)

        Status := DestroyServiceAccount(SERVICE_ACCOUNT_NAME);

        if Status <> 0 then
        begin
          MsgBox('Failed to delete the service account for ' + SERVICE_ACCOUNT_NAME + ' (#' + IntToStr(Status) + ')' #13#13 'You need to delete it manually.', mbError, MB_OK);
        end;
      end
  end
end;
