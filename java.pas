// The bulk of this code came from:
//  http://stackoverflow.com/questions/1297773/check-java-is-present-before-installing

// function RequireJava(MinimalVersion: string): Boolean;

// Both DecodeVersion and CompareVersion functions where taken from the inno setup wiki
procedure DecodeVersion(verstr: String; var verint: array of Integer);
var
  i,p: Integer; s: string;
begin
  // initialize array
  verint := [0,0,0,0];
  i := 0;
  while ((Length(verstr) > 0) and (i < 4)) do
  begin
    p := pos ('.', verstr);
    if p > 0 then
    begin
      if p = 1 then s:= '0' else s:= Copy (verstr, 1, p - 1);
      verint[i] := StrToInt(s);
      i := i + 1;
      verstr := Copy (verstr, p+1, Length(verstr));
    end
    else
    begin
      verint[i] := StrToInt (verstr);
      verstr := '';
    end;
  end;
end;

function CompareVersion(ver1, ver2: String): Integer;
var
  verint1, verint2: array of Integer;
  i: integer;
begin
  SetArrayLength (verint1, 4);
  DecodeVersion (ver1, verint1);

  SetArrayLength (verint2, 4);
  DecodeVersion (ver2, verint2);

  Result := 0; i := 0;
  while ((Result = 0) and ( i < 4 )) do
  begin
    if verint1[i] > verint2[i] then
      Result := 1
    else
      if verint1[i] < verint2[i] then
        Result := -1
      else
        Result := 0;
    i := i + 1;
  end;
end;

function RequireJava(MinimalVersion: string): Boolean;
var
  ErrorCode: Integer;
  JavaVersion: String;
begin
    RegQueryStringValue(HKLM, 'SOFTWARE\JavaSoft\Java Runtime Environment', 'CurrentVersion', JavaVersion);

    if Length(JavaVersion) > 0 then
    begin
        if CompareVersion(JavaVersion, MinimalVersion) >= 0 then
        begin
            Result := true;
            Exit;
        end;
    end;

    if MsgBox('This tool requires Java Runtime Environment (JRE) ' + MinimalVersion + ' or newer to run. Please download and install JRE and run this setup again.' + #13#10#13#10 + 'Do you want to open the download page now?', mbConfirmation, MB_YESNO) = idYes then
    begin
        ShellExec('open', 'http://www.oracle.com/technetwork/java/javase/downloads/', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
    end;

    Result := false;
end;
