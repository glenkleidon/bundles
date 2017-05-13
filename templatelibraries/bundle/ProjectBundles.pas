unit ProjectBundles;

interface
  uses Windows, Sysutils, Classes;    // keep uses in old style for earlier versions
  CONST
    REG_PATH_DELPHI = 'SOFTWARE\Borland\Delphi\%s\Known Packages';
    REG_PATH_CODEGEAR = 'SOFTWARE\CodeGear\BDS\%s\Known Packages';
    REG_PATH_EMBARCADERO = 'SOFTWARE\Embarcadero\BDS\%s\Known Packages';

    PRODUCT_VERSION= '%ProductVersion%';
    DELPHI_EXE = '%DelphiExe%';
    DELPHI_GROUP = '%DelphiGroup';
    START_PROJECT_NAME = 'StartProject.bat';
    HG_IGNORE_FILE = '.hgignore';
    GIT_IGNORE_FILE = '.gitignore';

    PROJECT_STRUCTURE =
      'bin'#13#10+
      'client'#13#10+
      'common'#13#10+
      'componentLibrary\dcu\'+PRODUCT_VERSION+#13#10+
      'componentLibrary\bpl\'+PRODUCT_VERSION+#13#10+
      'componentSource'#13#10+
      'resources'#13#10+
      'server'#13#10+
      'test';
    START_PROJECT =
      'SET ProductVersion='+PRODUCT_VERSION+#13#10+
      'SET ActiveProjectName=CHANGE_ME_IN_START_PROJECT_BAT'#13#10+
      'SET ActiveProject=%CD%\'#13#10+
      'SET ActiveProject_Library=%CD%ComponentLibrary\'#13#10+
      'SET ActiveProject_BPL=%ActiveProject_Library%BPL\'+PRODUCT_VERSION+'\'#13#10+
      'SET ActiveProject_DCU=%ActiveProject_Library%DCU\'+PRODUCT_VERSION+'\'#13#10+
      'SET ActiveProject_Source=%CD%ComponentSource\'#13#10+
      'call .\bin\checkbundle'#13#10+
      'start '+DELPHI_EXE +' .\%ActiveProjectName%.'+DELPHI_GROUP+#13#10;

    VC_IGNORES =
      '*.local'#13#10+
      '*.identcache'#13#10+
      '*.~*'#13#10+
      '__history/'#13#10+
      'Test/**.dcu'#13#10+
      'bin/'#13#10+
      'Win64/'#13#10+
      'Win32/'#13#10;

    GIT_IGNORE = VC_IGNORES;

    HG_IGNORE = 'syntax: glob'#13#10+VC_IGNORES;

  var
    ProductVersion : string;
    ProjectFolder  : string;
    RegistryKey    : string;
    ProjectBPLFolder : string;
    StartDir       : string;
    DelphiEXE      : string;
    DelphiGroup    : string;

    DelphiInternalVersion: Integer;
    DelphiProductVersion : string;

procedure UpdateBundle;
procedure SetProjectPath;
function ReplaceEnvironmentVariables(AText: string; AfirstOnly: boolean = false): string;
Procedure CreateProjectFolders;
Procedure OutputBundleFiles;
Procedure CheckBPLS;
Procedure RemoveThisProject;
Function ListProjectBPLs: string;
Function GetProductVersion: string;
Function DelphiVersionFromProductVersion(AProductVersion: string): integer;

implementation
  uses Registry;

Procedure SetProjectPath;
begin
  ProjectFolder := includetrailingBackSlash(ExpandFileName(StartDir));
end;

Function ListFiles(ASearchPath : string): string;
var lFileRecord : TSearchRec;
begin
   result := '';
   if findfirst(ASearchPath,0,lFileRecord)>0 then exit;
   try
     repeat
       result := result + lFileRecord.Name+#13#10;
     until findNext(lFileRecord)<>0;
   finally
     findclose(lFileRecord);
   end;
end;


Function ListProjectBPLs: string;
begin
   result := '';
   if ProjectBPLFolder='' then
   begin
      ProjectBPLFolder := GetEnvironmentVariable('ActiveProject_BPL');
      if ProjectBPLFolder<>'' then ProjectBPLFolder:=includeTrailingPathDelimiter(ProjectBPLFolder);
   end;
   if ProjectBPLFolder='' then exit;
   result := ListFiles(ProjectBPLFolder+'*.bpl');
end;

function DelphiVersionFromProductVersion(AProductVersion: string): integer;
var lVersion: single;
begin
  result := 0;
  tryStrtoFloat(AProductVersion,lVersion);
  result := trunc(lVersion);
end;

Function GetProductVersion: string;
begin
  if ProductVersion='' then
    Result := getEnvironmentVariable('ProductVersion')
  else Result := ProductVersion;
  if Result='' then Result:=DelphiProductVersion;
end;

Procedure SetEnvironmentVariablesByProductVersion(AProductVersion: string);
var lRegistryFormatStr: string;
    lAltVersion: string;
    lVersion:integer;
begin
  ProductVersion:=AProductVersion;
  DelphiExe := 'Bds';
  DelphiGroup := 'groupproj';
  lVersion := DelphiVersionFromProductVersion(AProductVersion);
  case lVersion of
    0..8 :
    begin
      lRegistryFormatStr := format(REG_PATH_DELPHI,[ProductVersion]);
      DelphiGroup := 'bpg';
      DelphiEXE := 'Delphi32';
    end;
    9..13 :
    begin
      lAltVersion := IntTostr(lVersion-3) + '.0';
      lRegistryFormatStr := format(REG_PATH_CODEGEAR,[lAltVersion]);
    end;
    14..99 :
    begin
       lRegistryFormatStr := format(REG_PATH_EMBARCADERO,[ProductVersion]);
    end;
  end;

end;

function ReplaceEnvironmentVariables(AText: string; AfirstOnly: boolean): string;
var lReplaceFlags : TReplaceFlags;
begin
  if AfirstOnly then lReplaceFlags := [] else  lReplaceFlags := [rfreplaceAll];
  result := stringreplace(AText,PRODUCT_VERSION, ProductVersion, lReplaceFlags);
  result := stringreplace(Result,DELPHI_EXE, DelphiExe, lReplaceFlags);
  result := stringreplace(Result,DELPHI_GROUP, DelphiGroup, lReplaceFlags);
end;

Procedure CreateProjectFolders;
var lList:TStringlist;
    lFolderPath: string;
    i : integer;
begin

  lList:=TStringlist.Create;
  try
    lList.Text := ReplaceEnvironmentVariables(PROJECT_STRUCTURE);
    for i := 0 to pred(lList.Count) do
    begin
      lFolderPath := ProjectFolder + lList[i];
      if not(DirectoryExists(lFolderPath)) then forceDirectories(lFolderPath);
    end;
  finally
    freeandnil(lList);
  end;
end;

Procedure OutputBundleFiles;
var lList:TStringList;
begin
  lList := TStringList.Create;
  try
    if (not fileexists(ProjectFolder+GIT_IGNORE_FILE)) and
       (not fileexists(ProjectFolder+HG_IGNORE_FILE )) then
    begin
       lList.Text := GIT_IGNORE;
       lList.SaveToFile(ProjectFolder+GIT_IGNORE_FILE);
       lList.Text := HG_IGNORE;
       lList.SaveToFile(ProjectFolder+HG_IGNORE_FILE);
    end;
    if (not FileExists(ProjectFolder+START_PROJECT_NAME)) then
    begin
      lList.Text := ReplaceEnvironmentVariables(START_PROJECT,true);
      lList.SaveToFile(ProjectFolder+START_PROJECT_NAME);
    end;
  finally
    freeandnil(lList);
  end;
end;

Procedure CheckBPLS;
var reg : TRegistry;
    lBPLList : TStringlist;
    lKnownBPLList : TStringlist;
    lExpectedBPLPath, lBPLName, lknownBPLS : string;
    i:integer;
begin
  if RegistryKey='' then exit;
  reg := TRegistry.Create;
  lKnownBPLList := TStringlist.Create;
  lBPLList := TStringlist.Create;
  try
  reg.RootKey := HKEY_CURRENT_USER;
  if not reg.KeyExists(RegistryKey) then exit;
  lBPLList.Text := LowerCase(ListProjectBPLs);
  if lBPLList.Count=0 then exit;
  // There are BPLs to check
  reg.OpenKey(RegistryKey,false);
  reg.GetKeyNames(lKnownBPLList);
  lknownBPLS := LowerCase(lKnownBPLList.Text);
  freeandnil(lKnownBPLList);
  lExpectedBPLPath := '$(ActiveProject_BPL)\';
  //now check that the expected Path is present in the registry

  for i := 0 to pred(lBPLList.count) do
  begin
    lBPLName := lBPLList[i];
    if lKnownBPLList.IndexOf(lExpectedBPLPath+lBPLName)<0 then
    begin
      // not found. Is there a system alternate?
      if pos('\'+lBPLName+#13#10,lBPLList.text)>0 then
      begin
        writeln(format(
          'Warning: Component Library %s is installed outside the package', [lBPLName]));
      end else
      begin
        reg.WriteString(lExpectedBPLPath+lBPLName,'Bundled Project Components');
      end;
    end;
  end;

  finally
    freeandnil(reg);
    freeandnil(lKnownBPLList);
    freeandnil(lBPLList);
  end;
end;

Procedure RemoveThisProject;
var lTargetFiles: TStringlist;
    {$IFNDEF DEBUG}i:integer;{$ENDIF}
begin
  // When this project is first run, it may not be able to remove
  // all the files, but eventually it will.
  lTargetFiles := TStringList.Create;
  try
    lTargetFiles.text := Listfiles(ProjectFolder+'checkbundle.*');
    lTargetFiles.Add('ProjectBundles.pas');
    lTargetFiles.Add('ProjectBundles.dcu');
   {$IFNDEF DEBUG}
    for i := 0 to lTargetFiles.Count-1 do
    begin
      deletefile(ProjectFolder+lTargetFiles[i]);
    end;
   {$ENDIF}
  finally
    freeandnil(lTargetFiles);
  end;
end;

procedure UpdateBundle;
begin
  SetEnvironmentVariablesByProductVersion(GetProductVersion);
  SetProjectPath;
  CreateProjectFolders;
  OutputBundleFiles;
  CheckBPLS;
  RemoveThisProject;
end;

initialization
{$IFDEF VER80} DelphiProductVersion:='1.0'; DelphiInternalVersion:=8; {$ENDIF}
{$IFDEF VER90} DelphiProductVersion:='2.0'; DelphiInternalVersion:=9; {$ENDIF}
{$IFDEF VER100} DelphiProductVersion:='3.0'; DelphiInternalVersion:=10; {$ENDIF}
{$IFDEF VER120} DelphiProductVersion:='4.0'; DelphiInternalVersion:=12; {$ENDIF}
{$IFDEF VER130} DelphiProductVersion:='5.0'; DelphiInternalVersion:=13; {$ENDIF}
{$IFDEF VER140} DelphiProductVersion:='6.0'; DelphiInternalVersion:=14; {$ENDIF}
{$IFDEF VER150} DelphiProductVersion:='7.0'; DelphiInternalVersion:=15; {$ENDIF}
{$IFDEF VER160} DelphiProductVersion:='8.0'; DelphiInternalVersion:=16; {$ENDIF}
{$IFDEF VER170} DelphiProductVersion:='9.0'; DelphiInternalVersion:=17; {$ENDIF}
{$IFDEF VER180} DelphiProductVersion:='10.0'; DelphiInternalVersion:=18; {$ENDIF}
{$IFDEF VER180} DelphiProductVersion:='11.0'; DelphiInternalVersion:=18.5; {$ENDIF}
{$IFDEF VER185} DelphiProductVersion:='11.0'; DelphiInternalVersion:=18.5; {$ENDIF}
{$IFDEF VER200} DelphiProductVersion:='12.0'; DelphiInternalVersion:=20; {$ENDIF}
{$IFDEF VER210} DelphiProductVersion:='14.0'; DelphiInternalVersion:=21; {$ENDIF}
{$IFDEF VER220} DelphiProductVersion:='15.0'; DelphiInternalVersion:=22; {$ENDIF}
{$IFDEF VER230} DelphiProductVersion:='16.0'; DelphiInternalVersion:=23; {$ENDIF}
{$IFDEF VER240} DelphiProductVersion:='17.0'; DelphiInternalVersion:=24; {$ENDIF}
{$IFDEF VER250} DelphiProductVersion:='18.0'; DelphiInternalVersion:=25; {$ENDIF}
{$IFDEF VER260} DelphiProductVersion:='19.0'; DelphiInternalVersion:=26; {$ENDIF}
{$IFDEF VER270} DelphiProductVersion:='20.0'; DelphiInternalVersion:=27; {$ENDIF}
{$IFDEF VER280} DelphiProductVersion:='21.0'; DelphiInternalVersion:=28; {$ENDIF}
{$IFDEF VER290} DelphiProductVersion:='22.0'; DelphiInternalVersion:=29; {$ENDIF}
{$IFDEF VER300} DelphiProductVersion:='23.0'; DelphiInternalVersion:=30; {$ENDIF}
{$IFDEF VER310} DelphiProductVersion:='24.0'; DelphiInternalVersion:=31; {$ENDIF}
{$IFDEF VER320} DelphiProductVersion:='25.0'; DelphiInternalVersion:=32; {$ENDIF}

end.
