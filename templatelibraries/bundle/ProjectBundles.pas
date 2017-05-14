unit ProjectBundles;

interface
  uses Windows, Sysutils, Classes;    // keep uses in old style for earlier versions
  CONST
    REG_PATH_DELPHI = 'SOFTWARE\Borland\Delphi\%s\Known Packages';
    REG_PATH_CODEGEAR = 'SOFTWARE\CodeGear\BDS\%s\Known Packages';
    REG_PATH_EMBARCADERO = 'SOFTWARE\Embarcadero\BDS\%s\Known Packages';

    DELPHI_VERSION= '%DelphiVersion%';
    PRODUCT_VERSION= '%ProductVersion%';
    DELPHI_EXE = '%DelphiExe%';
    DELPHI_GROUP = '%DelphiGroup';
    START_PROJECT_NAME = 'StartProject.bat';
    HG_IGNORE_FILE = '.hgignore';
    GIT_IGNORE_FILE = '.gitignore';

    MAX_VERSIONS=24;
    VERSIONINFO : array[1..MAX_VERSIONS,1..2] of integer = (
         ( 1, 1),( 2, 2),( 3, 3),( 4, 4),( 5, 5),( 6, 6),( 7, 7),
         ( 8, 2),( 9, 3),(10, 4),(11, 5),(12, 6),(14, 7),(15, 8),
         (16, 9),(17,10),(18,11),(19,12),(20,14),(21,15),
         (22,16),(23,17),(24,18),(25,19)
    );


    PROJECT_STRUCTURE =
      'bin'#13#10+
      'client'#13#10+
      'common'#13#10+
      'componentLibrary\dcu\'+DELPHI_VERSION+#13#10+
      'componentLibrary\bpl\'+DELPHI_VERSION+#13#10+
      'componentSource'#13#10+
      'resources'#13#10+
      'server'#13#10+
      'test';
    START_PROJECT =
      'SET DelphiVersion='+DELPHI_VERSION+#13#10+
      'SET ActiveProjectName=CHANGE_ME_IN_START_PROJECT_BAT'#13#10+
      'SET ActiveProject=%CD%\'#13#10+
      'SET ActiveProject_Library=%CD%\ComponentLibrary\'#13#10+
      'SET ActiveProject_BPL=%ActiveProject_Library%BPL\'+DELPHI_VERSION+'\'#13#10+
      'SET ActiveProject_DCU=%ActiveProject_Library%DCU\'+DELPHI_VERSION+'\'#13#10+
      'SET ActiveProject_Source=%CD%\ComponentSource\'#13#10+
      'call .\checkbundle'#13#10+
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
    DelphiVersion : string;
    ProjectFolder  : string;
    RegistryKey    : string;
    ProjectBPLFolder : string;
    StartDir       : string;
    DelphiEXE      : string;
    DelphiGroup    : string;

    ProductVersion: Integer =0;
    DefaultDelphiVersion : integer=0;

procedure UpdateBundle;
procedure SetProjectPath;
Procedure SetEnvironmentVariablesByDelphiVersion(ADelphiVersion: string);
function ReplaceEnvironmentVariables(AText: string; AfirstOnly: boolean = false): string;
Procedure CreateProjectFolders;
Procedure OutputBundleFiles;
Procedure CheckBPLS;
Procedure RemoveThisProject;
Function EnvironmentVarToInt(AVariable:string): integer;
Function ListProjectBPLs: string;
Function GetDelphiVersion: string;
Function ProductVersionFromDelphiVersion(ADelphiVersion: string): string;

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

Function EnvironmentVarToInt(AVariable:string): integer;
var lVersion: single;
begin
  result := 0;
  if not tryStrtoFloat(AVariable,lVersion) then exit;
  Result := trunc(lVersion);
end;

Function ProductVersionFromDelphiVersion(ADelphiVersion: string): string;
var lVersionAsInt,i: Integer;
begin
  result := '';
  lVersionAsInt := EnvironmentVarToInt(ADelphiVersion);
  for i := 1 to Max_Versions do
    if (lVersionAsInt=VERSIONINFO[i,1]) then
    begin
      result := format('%d.0',[VERSIONINFO[i,2]]);
      exit;
    end;
end;

Function DelphiVersionFromProductVersion(AProductVersion: string): string;
var lVersion: single;
    lVersionAsInt,i: Integer;
begin
  result := '';
  lVersionAsInt := EnvironmentVarToInt(AProductVersion);
  for i := 8 to Max_Versions do
    if (lVersionAsInt=VERSIONINFO[i,2]) then
    begin
      result := format('%d.0',[VERSIONINFO[i,1]]);
      exit;
    end;
end;

Function GetDelphiVersion: string;
begin
  if DelphiVersion='' then
    Result := getEnvironmentVariable('DelphiVersion')
  else Result := DelphiVersion;
  if Result='' then Result:=format('%d.0',[DefaultDelphiVersion]);
end;

Function GetProductVersion: string;
begin
  if ProductVersion=0 then
     Result := getEnvironmentVariable('ProductVersion')
  else Result := format('%d.0', [ProductVersion]);
  if Result='' then Result := ProductVersionFromDelphiVersion(GetDelphiVersion);
end;

Procedure SetEnvironmentVariablesByDelphiVersion(ADelphiVersion: string);
var lRegistryFormatStr: string;
    lAltVersion: string;
    lVersion:integer;
begin
  DelphiVersion:=ADelphiVersion;
  DelphiExe := 'Bds';
  DelphiGroup := 'groupproj';
  lVersion := EnvironmentVarToInt(ADelphiVersion);
  case lVersion of
    0..8 :
    begin
      lRegistryFormatStr := REG_PATH_DELPHI;
      DelphiGroup := 'bpg';
      DelphiEXE := 'Delphi32';
    end;
    9..13 :
    begin
      lRegistryFormatStr := REG_PATH_CODEGEAR;
    end;
    14..99 :
    begin
       lRegistryFormatStr := REG_PATH_EMBARCADERO;
    end;
  else
    begin
      Writeln('Delphi Version Cannot be determined!');
      exit;
    end;
  end;
  // Registry Key requires correct Product Version
  RegistryKey := format(lRegistryFormatStr,[GetProductVersion]);
end;

function ReplaceEnvironmentVariables(AText: string; AfirstOnly: boolean): string;
var lReplaceFlags : TReplaceFlags;
begin
  if AfirstOnly then lReplaceFlags := [] else  lReplaceFlags := [rfreplaceAll];
  result := stringreplace(AText,DELPHI_VERSION, DelphiVersion, lReplaceFlags);
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
  if not Reg.KeyExists(RegistryKey) then exit;
  reg.OpenKey(RegistryKey,false);
  reg.GetValueNames(lKnownBPLList);
  lknownBPLS := LowerCase(lKnownBPLList.Text);
  freeandnil(lKnownBPLList);
  lExpectedBPLPath := '$(ActiveProject_BPL)\';
  //now check that the expected Path is present in the registry

  for i := 0 to pred(lBPLList.count) do
  begin
    lBPLName := lBPLList[i];
    if pos(lowercase(lExpectedBPLPath+lBPLName),lknownBPLS)<1 then
    begin
      // not found. Is there a system alternate?
      if pos('\'+lowercase(lBPLName)+#13#10,lknownBPLS)>0 then
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
  SetEnvironmentVariablesByDelphiVersion(GetDelphiVersion);
  SetProjectPath;
  CreateProjectFolders;
  OutputBundleFiles;
  CheckBPLS;
  RemoveThisProject;
end;

initialization
{$IFDEF VER80} DefaultDelphiVersion:=1; {$ENDIF}
{$IFDEF VER90} DefaultDelphiVersion:=2; {$ENDIF}
{$IFDEF VER100} DefaultDelphiVersion:=3; {$ENDIF}
{$IFDEF VER120} DefaultDelphiVersion:=4; {$ENDIF}
{$IFDEF VER130} DefaultDelphiVersion:=5; {$ENDIF}
{$IFDEF VER140} DefaultDelphiVersion:=6; {$ENDIF}
{$IFDEF VER150} DefaultDelphiVersion:=7; {$ENDIF}
{$IFDEF VER160} DefaultDelphiVersion:=8; {$ENDIF}
{$IFDEF VER170} DefaultDelphiVersion:=9; {$ENDIF}
{$IFDEF VER180} DefaultDelphiVersion:=10; {$ENDIF}
{$IFDEF VER180} DefaultDelphiVersion:=11; {$ENDIF}
{$IFDEF VER185} DefaultDelphiVersion:=11; {$ENDIF}
{$IFDEF VER200} DefaultDelphiVersion:=12; {$ENDIF}
{$IFDEF VER210} DefaultDelphiVersion:=14; {$ENDIF}
{$IFDEF VER220} DefaultDelphiVersion:=15; {$ENDIF}
{$IFDEF VER230} DefaultDelphiVersion:=16; {$ENDIF}
{$IFDEF VER240} DefaultDelphiVersion:=17; {$ENDIF}
{$IFDEF VER250} DefaultDelphiVersion:=18; {$ENDIF}
{$IFDEF VER260} DefaultDelphiVersion:=19; {$ENDIF}
{$IFDEF VER270} DefaultDelphiVersion:=20; {$ENDIF}
{$IFDEF VER280} DefaultDelphiVersion:=21; {$ENDIF}
{$IFDEF VER290} DefaultDelphiVersion:=22; {$ENDIF}
{$IFDEF VER300} DefaultDelphiVersion:=23; {$ENDIF}
{$IFDEF VER310} DefaultDelphiVersion:=24; {$ENDIF}
{$IFDEF VER320} DefaultDelphiVersion:=25; {$ENDIF}

end.
