program checkbundle;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  ProjectBundles in 'ProjectBundles.pas';

begin
  try
    { Compile and Run this program the first time you create the
      project.  The exe will move itself and then close;
     }
    StartDir := extractFilePath(paramstr(0));
    UpdateBundle;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
