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
    VERSIONINFO : array[1..MAX_VERSIONS,1..3] of integer = (
      ( 1, 1, 8),( 2, 2, 9),( 3, 3,10),( 4, 4,12),( 5, 5,13),( 6, 6,14),
      ( 7, 7,15),( 8, 2,16),( 9, 3,17),(10, 4,18),(11, 5,18),(12, 6,20),
      (14, 7,21),(15, 8,22),(16, 9,23),(17,10,24),(18,11,25),(19,12,25),
      (20,14,25),(21,15,25),(22,16,25),(23,17,30),(24,18,30),(25,19,30)
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
      'SET TargetVersion=%DelphiVersion%'#13#10+
      'SET VERSIONOVERRIDE=%1' + #13#10 +
      'IF DEFINED VERSIONOVERRIDE (SET DelphiVersion=%VERSIONOVERRIDE%)'+#13#10 +
      'SET ActiveProjectName=CHANGE_ME_IN_START_PROJECT_BAT'#13#10+
      'if %ActiveProjectName%==CHANGE_ME_IN_START_PROJECT_BAT ('#13#10+
      '   @echo Set Project name in StartProject.bat'#13#10+
      '   @Goto END'#13#10+
      ')'+#13#10 +
      'SET ActiveProject=%CD%\'#13#10+
      'SET ActiveProject_Library=%CD%\ComponentLibrary\'#13#10+
      'SET ActiveProject_BPL=%ActiveProject_Library%BPL\%TargetVersion%\'#13#10+
      'SET ActiveProject_DCU=%ActiveProject_Library%DCU\%TargetVersion%\'#13#10+
      'SET ActiveProject_Source=%CD%\ComponentSource\'#13#10+
      'call .\checkbundle'#13#10+
      'start '+DELPHI_EXE +' /r%ActiveProjectName% .\%ActiveProjectName%.'+DELPHI_GROUP+#13#10+
      ':END';

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
    TargetVersion : string;
    ProjectFolder  : string;
    RegistryKey    : string;
    ProjectBPLFolder : string;
    ProjectDCUFolder : string;
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
Function ListDCUFolders: string;
Function ListProjects: string;
Function GetDelphiVersion: string;
Function RTLCompatible(ADelphiVersion:string; ATargetVersion: string): boolean;
Function ProductVersionFromDelphiVersion(ADelphiVersion: string): string;
function extractProjectNamesFromGroupProj(AFilename: string): string ;
function extractProjectNamesFromBPG(AFilename: string): string;

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

Function ListDCUFolders: string;
begin
  // Find all folders under DCUs

end;

Function ListProjects: string;
var lGroupName,
    LGroupProjFilename, LBPGFilename: string;
begin
  // Load All projects in the group
  Result := '';
 lGroupName := GetEnvironmentVariable('ActiveProjectName');
 LGroupProjFilename := ProjectFolder + lGroupName + '.groupproj';
 lBPGFilename := ProjectFolder + lGroupName + '.bpg';
 result :=
    extractProjectNamesFromGroupProj(lGRoupProjFilename) +
    extractProjectNamesFromBPG(lBPGFilename);

end;
//<Projects Include="

function extractProjectNamesFromGroupProj(AFilename: string): string ;
var lGroupProj: TStringlist;
    lProgramList: TStringlist;
    lBinary, lItemGroup : string;
    i,p,q: integer;
    // Extract the XML Node containing the ItemGroup.
    function GetFirstItemGroup: string;
    var pp,qq: integer;
    begin
      result := '';
      pp := 0; qq := 0;
      pp := pos('<ItemGroup>',lProgramList.text);
      if pp>0 then qq := pos('</ItemGroup>',lProgramList.text);
      if qq>0 then result := copy(lProgramList, pp+11, qq-pp-11);
    end;

    Function GetNextProject: string;
    var pp,qq: integer;
        lGroup: string;
    begin
      result := '';
      pp := 0; qq := 0;
      pp := pos('<Projects ', lItemGroup);
      if pp>0 then qq := Pos('</Projects>, lItemGroup) else exit;
      lGroup := Copy(lItemGroup, pp, qq-pp-1);
      lItemGroup := copy(lItemGroup, qq+11, MAXINT);
      pp := pos('Include="', lGroup);
      if pp>0 then
      begin
        lgroup := copy(lGroup,pp+9, MAXINT);
        pp := pos('"',lGroup);
        result := copy(lGroup,1, pp-1);
      end;
    end;
begin
  // Extracts the project Names from a GroupProj file.
  result := '';
  if FileExists(AFilename) then
  begin
    lGroupProj := TStringlist.Create;
    lProgramList := TStringlist.Create;
    try
       lGroupProj.LoadFromFile(AFilename);
       lItemGroup := GetFirstItemGroup;
       lBinary := GetNextProject;
       while length(lBinary>0) do
       begin
         lProgramList.Add(lBinary);
         lBinary := GetNextProject;
       end;
       result := lProgramList.Text;
     finally
      freeandnil(lGroupProj);
      freeandnil(lProgramList);
    end;
  end;
end;

function extractProjectNamesFromBPG(AFilename: string): string;
var lBPG: TStringlist;
    lProgramList: TStringlist;
    lBinary, lDPR : string;
    i,p: integer;
begin
  // Extracts the project Names from a BPG file.
  result := '';
  if FileExists(AFilename) then
  begin
    lBPG := TStringlist.Create;
    lProgramList := TStringlist.Create;
    try
       lBPG.LoadFromFile(AFilename);
       lProgramList.Delimiter := ' ';
       lProgramList.text := lBPG.Values['PROJECTS'];
       p := pos('PROJECTS',lBPG.Text);
       if p>0 then
       begin
         lBPG := stringreplace( copy(lBPG.Text,p,MAXInt),
            ': ', '=', [rfReplaceAll]);
         for i := lProgramList.Count - 1 downto 0 do
         begin
           lBinary := lProgramList[i];
           if length(lBinary)=0 then
           begin
            lProgramList.Delete(i);
            continue;
           end;
           lProgramList[i] := stringREplace(
                     lBPG.Values[lBinary], ' ', #13#10,
                     [rfReplaceAll]);
         end;
       end;
       result := lProgramList.Text;
    finally
      freeandnil(lBPG);
      freeandnil(lProgramList);
    end;
  end;
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

Function RTLCompatible(ADelphiVersion:string;ATargetVersion:string): boolean;
var i, lDelphiVersion, lTargetVersion,
    lDelphiRTL, lTargetRTL: integer;
begin
  result := true;
  if ADelphiVersion=ATargetVersion then exit;
  lDelphiRTL:=-1;
  lTargetRTL:=-2;
  lDelphiVersion := EnvironmentVarToInt(ADelphiVersion);
  lTargetVersion := EnvironmentVarToInt(ATargetVersion);
  For i := 1 TO MAX_VERSIONS do
  begin
    if (lDelphiVersion=VERSIONINFO[i,1]) then lDelphiRTL:=VERSIONINFO[i,3];
    if (lTargetVersion=VERSIONINFO[i,1]) then lTargetRTL:=VERSIONINFO[i,3];
  end;
  Result := lDelphiRTL=lTargetRTL;
end;


Function GetDelphiVersion: string;
begin
  if DelphiVersion='' then
    Result := getEnvironmentVariable('DelphiVersion')
  else Result := DelphiVersion;
  if Result='' then Result:=format('%d.0',[DefaultDelphiVersion]);
  DelphiVersion:=Result;
end;

Function GetTargetVersion: string;
begin
  if TargetVersion='' then
    Result := getEnvironmentVariable('TargetVersion')
  else Result := DelphiVersion;
  if Result='' then Result:=format('%d.0',[DefaultDelphiVersion]);
  TargetVersion:=Result;
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
  if (RegistryKey='') or
     (not RTLCompatible(GetDelphiVersion, GetTargetVersion)) then exit;
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

Procedure CheckDCUPaths;

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
