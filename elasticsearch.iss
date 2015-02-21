; elasticsearch for Windows Setup Script created by Rui Lopes (ruilopes.com).
;
; TODO do not override existing configuration files. 
; TODO after uninstall, setup-helper.dll is left behind... figure out why its
;      not being automatically deleted.
; TODO sign the setup?
;      NB: Unizeto Certum has free certificates to open-source authors.
;      See http://www.certum.eu/certum/cert,offer_software_publisher.xml
;      See https://developer.mozilla.org/en/Signing_a_XPI

#define ServiceAccountName "elasticsearch"
#define ServiceName "elasticsearch"
#define AppVersion "1.4.4"
#define LuceneVersion "4.10.3"
#define JreVersion "8u31"
#define ESPath "vendor\elasticsearch-" + AppVersion
#ifdef _WIN64
#define Bits "64"
#define ArchitecturesInstallIn64BitMode "x64"
#define ArchitecturesAllowed "x64"
#else
#define Bits "32"
#define ArchitecturesInstallIn64BitMode
#define ArchitecturesAllowed "x86 x64"
#endif

[Setup]
ArchitecturesInstallIn64BitMode={#ArchitecturesInstallIn64BitMode}
ArchitecturesAllowed={#ArchitecturesAllowed}
AppID={{BBFE3D83-0850-4E17-8BCC-860945E4F485}
AppName=Elasticsearch
AppVersion={#AppVersion}
VersionInfoVersion={#AppVersion}
AppPublisher=rgl
AppPublisherURL=https://github.com/rgl/elasticsearch-setup
AppSupportURL=https://github.com/rgl/elasticsearch-setup
AppUpdatesURL=https://github.com/rgl/elasticsearch-setup
DefaultDirName={pf}\Elasticsearch
DefaultGroupName=Elasticsearch
OutputDir=.
OutputBaseFilename=elasticsearch-{#AppVersion}-jre-{#JreVersion}-setup-{#Bits}-bit
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
Source: "{#ESPath}\bin\elasticsearchw-{#Bits}.exe"; DestDir: "{app}\bin"; DestName: "elasticsearchw.exe"
Source: "{#ESPath}\bin\plugin.bat"; DestDir: "{app}\bin"
Source: "{#ESPath}\lib\elasticsearch-{#AppVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\antlr-runtime-3.5.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\asm-4.1.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\asm-commons-4.1.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\groovy-all-2.3.2.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\jna-4.1.0.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\jts-1.13.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\log4j-1.2.17.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-analyzers-common-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-core-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-expressions-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-grouping-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-highlighter-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-join-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-memory-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-misc-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-queries-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-queryparser-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-sandbox-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-spatial-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\lucene-suggest-{#LuceneVersion}.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\spatial4j-0.4.1.jar"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\sigar\sigar-1.6.4.jar"; DestDir: "{app}\lib\sigar"
#ifdef _WIN64
Source: "{#ESPath}\lib\sigar\sigar-amd64-winnt.dll"; DestDir: "{app}\lib\sigar"; Flags: ignoreversion
#else
Source: "{#ESPath}\lib\sigar\sigar-x86-winnt.dll"; DestDir: "{app}\lib\sigar"; Flags: ignoreversion
#endif
Source: "{#ESPath}\config\elasticsearch.yml"; DestDir: "{app}\config"
Source: "{#ESPath}\config\logging.yml"; DestDir: "{app}\config"
Source: "{#ESPath}\README.textile"; DestDir: "{app}"; DestName: "README.txt"; Flags: isreadme
Source: "{#ESPath}\NOTICE.txt"; DestDir: "{app}"
Source: "{#ESPath}\LICENSE.txt"; DestDir: "{app}"
Source: "{#ESPath}\lib\elasticsearch-cmd.cmd"; DestDir: "{app}\lib"
Source: "{#ESPath}\lib\elasticsearchw-update-{#Bits}.cmd"; DestDir: "{app}\lib"; DestName: "elasticsearchw-update.cmd"
Source: "elasticsearchw-uninstall.cmd"; DestDir: "{app}\lib"
Source: "Elasticsearch Home.url"; DestDir: "{app}"
Source: "Elasticsearch Setup Home.url"; DestDir: "{app}"
Source: "Elasticsearch Guide.url"; DestDir: "{app}"
Source: "vendor\jre-{#Bits}\jre\*"; DestDir: "{app}\jre"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Elasticsearch Home"; Filename: "{app}\Elasticsearch Home.url"
Name: "{group}\Elasticsearch Setup Home"; Filename: "{app}\Elasticsearch Setup Home.url"
Name: "{group}\Elasticsearch Guide"; Filename: "{app}\Elasticsearch Guide.url"
Name: "{group}\Elasticsearch Read Me"; Filename: "{app}\README.txt"
Name: "{group}\Elasticsearch License"; Filename: "{app}\LICENSE.txt"
Name: "{group}\Uninstall Elasticsearch"; Filename: "{uninstallexe}"

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
#include "shortcut.pas"

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
  //NB we now bundle JRE; so no need to check for this.
  //Result := RequireJava('1.6');
  //if not Result then
  //  Exit;

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
  CmdPath: string;
  IconPath: string;
  WorkingDirectoryPath: string;
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
      end;
    ssPostInstall:
      begin
        CmdPath := ExpandConstant('{app}\lib\elasticsearch-cmd.cmd');
        IconPath := ExpandConstant('{uninstallexe}');
        WorkingDirectoryPath := ExpandConstant('{app}');
        CreateShortcut(ExpandConstant('{app}\bin\Elasticsearch Command Prompt.lnk'), CmdPath, IconPath, WorkingDirectoryPath, True);
        CreateShortcut(ExpandConstant('{group}\Elasticsearch Command Prompt.lnk'), CmdPath, IconPath, WorkingDirectoryPath, True);
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
        DeleteFile(ExpandConstant('{app}\bin\Elasticsearch Command Prompt.lnk'));
        DeleteFile(ExpandConstant('{group}\Elasticsearch Command Prompt.lnk'));

        // NB the service should already be uinstalled (by elasticsearchw-uninstall.cmd)

        Status := DestroyServiceAccount(SERVICE_ACCOUNT_NAME);

        if Status <> 0 then
        begin
          MsgBox('Failed to delete the service account for ' + SERVICE_ACCOUNT_NAME + ' (#' + IntToStr(Status) + ')' #13#13 'You need to delete it manually.', mbError, MB_OK);
        end;
      end
  end
end;
