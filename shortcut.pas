// IShellLink descriptions code came from https://github.com/jrsoftware/issrc/blob/master/Examples/CodeAutomation2.iss

// procedure CreateShortcut(AtPath: string; ToPath: string; RunAsAdministrator: boolean);

const
  CLSID_ShellLink = '{00021401-0000-0000-C000-000000000046}';

const
  // IShellLinkDataList::GetFlags()/SetFlags()
  SLDF_HAS_ID_LIST         = $00000001;   // Shell link saved with ID list
  SLDF_HAS_LINK_INFO       = $00000002;   // Shell link saved with LinkInfo
  SLDF_HAS_NAME            = $00000004;
  SLDF_HAS_RELPATH         = $00000008;
  SLDF_HAS_WORKINGDIR      = $00000010;
  SLDF_HAS_ARGS            = $00000020;
  SLDF_HAS_ICONLOCATION    = $00000040;
  SLDF_UNICODE             = $00000080;   // the strings are unicode
  SLDF_FORCE_NO_LINKINFO   = $00000100;   // don't create a LINKINFO (make a dumb link)
  SLDF_HAS_EXP_SZ          = $00000200;   // the link contains expandable env strings
  SLDF_RUN_IN_SEPARATE     = $00000400;   // Run the 16-bit target exe in a separate VDM/WOW
  SLDF_HAS_LOGO3ID         = $00000800;   // this link is a special Logo3/MSICD link
  SLDF_HAS_DARWINID        = $00001000;   // this link is a special Darwin link
  SLDF_RUNAS_USER          = $00002000;   // Run this link as a different user
  SLDF_HAS_EXP_ICON_SZ     = $00004000;   // contains expandable env string for icon path
  SLDF_NO_PIDL_ALIAS       = $00008000;   // don't ever resolve to a logical location
  SLDF_FORCE_UNCNAME       = $00010000;   // make GetPath() prefer the UNC name to the local name
  SLDF_RUN_WITH_SHIMLAYER  = $00020000;   // Launch the target of this link w/ shim layer active
  SLDF_RESERVED            = $80000000;   // Reserved-- so we can use the low word as an index value in the future

type
  IShellLinkW = interface(IUnknown)
    '{000214F9-0000-0000-C000-000000000046}'
    procedure Dummy;
    procedure Dummy2;
    procedure Dummy3;
    function GetDescription(pszName: String; cchMaxName: Integer): HResult;
    function SetDescription(pszName: String): HResult;
    function GetWorkingDirectory(pszDir: String; cchMaxPath: Integer): HResult;
    function SetWorkingDirectory(pszDir: String): HResult;
    function GetArguments(pszArgs: String; cchMaxPath: Integer): HResult;
    function SetArguments(pszArgs: String): HResult;
    function GetHotkey(var pwHotkey: Word): HResult;
    function SetHotkey(wHotkey: Word): HResult;
    function GetShowCmd(out piShowCmd: Integer): HResult;
    function SetShowCmd(iShowCmd: Integer): HResult;
    function GetIconLocation(pszIconPath: String; cchIconPath: Integer; out piIcon: Integer): HResult;
    function SetIconLocation(pszIconPath: String; iIcon: Integer): HResult;
    function SetRelativePath(pszPathRel: String; dwReserved: DWORD): HResult;
    function Resolve(Wnd: HWND; fFlags: DWORD): HResult;
    function SetPath(pszFile: String): HResult;
  end;

  IShellLinkDataList = interface(IUnknown)
    '{45E2B4AE-B1C3-11D0-B92F-00A0C90312E1}'
    function AddDataBlock(pDataBlock: cardinal): HResult;
    function CopyDataBlock(dwSig: DWORD; var ppDataBlock: cardinal): HResult;
    function RemoveDataBlock(dwSig: DWORD): HResult;
    function GetFlags(var pdwFlags: DWORD): HResult;
    function SetFlags(dwFlags: DWORD): HResult;
  end;

  IPersist = interface(IUnknown)
    '{0000010C-0000-0000-C000-000000000046}'
    function GetClassID(var classID: TGUID): HResult;
  end;

  IPersistFile = interface(IPersist)
    '{0000010B-0000-0000-C000-000000000046}'
    function IsDirty: HResult;
    function Load(pszFileName: String; dwMode: Longint): HResult;
    function Save(pszFileName: String; fRemember: BOOL): HResult;
    function SaveCompleted(pszFileName: String): HResult;
    function GetCurFile(out pszFileName: String): HResult;
  end;

procedure CreateShortcut(AtPath, ToPath, IconPath, WorkingDirectoryPath: string; RunAsAdministrator: boolean);
var
  Obj: IUnknown;
  SL: IShellLinkW;
  PF: IPersistFile;
  DL: IShellLinkDataList;
  Flags: DWORD;
begin
  Obj := CreateComObject(StringToGuid(CLSID_ShellLink));

  SL := IShellLinkW(Obj);
  OleCheck(SL.SetPath(ToPath));
  OleCheck(SL.SetWorkingDirectory(WorkingDirectoryPath));
  OleCheck(Sl.SetIconLocation(IconPath, 0));

  if RunAsAdministrator then
  begin
    DL := IShellLinkDataList(Obj);
    OleCheck(DL.GetFlags(Flags));
    OleCheck(Dl.SetFlags(Flags or SLDF_RUNAS_USER));
  end;

  PF := IPersistFile(Obj);
  OleCheck(PF.Save(AtPath, True));
end;
