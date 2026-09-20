; ADSOLUSOL Inno Setup Script

[Setup]
AppId={{F2A7A6D4-7B8E-4E9A-8C1F-3A9B7E6D0A1B}
AppName=ADSOLUSOL
AppVersion=1.0.0
DefaultDirName={autopf}\ADSOLUSOL
DefaultGroupName=ADSOLUSOL
OutputBaseFilename=ADSOLUSOL_Setup_v1.0.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
OutputDir=..\BUILD\INSTALLER

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\BUILD\ADSOLUSOL\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: The source path is relative to this script file.

[Icons]
Name: "{group}\ADSOLUSOL"; Filename: "{app}\ADSOLUSOL.Presentation.Api.exe"
Name: "{group}\{cm:UninstallProgram,ADSOLUSOL}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\ADSOLUSOL"; Filename: "{app}\ADSOLUSOL.Presentation.Api.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\ADSOLUSOL.Presentation.Api.exe"; Description: "{cm:LaunchProgram,ADSOLUSOL}"; Flags: nowait postinstall skipifsilent