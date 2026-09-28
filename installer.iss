; ==============================================================================
; ADSOLUSOL - Inno Setup Script (.iss)
; Paquetizador e Instalador Nativo de Windows (x64)
; Genera el instalador a partir de los binarios en BUILD\ADSOLUSOL
; ==============================================================================

#define MyAppName "AD SOLUSOL"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "KLIK Soft PRO / solusol.net"
#define MyAppURL "https://solusol.net"
#define MyAppExeName "ADSOLUSOL.Presentation.Desktop.exe"
#define BuildOutputDir "BUILD\ADSOLUSOL"

[Setup]
AppId={{7E1C84D2-998A-4A73-98C3-B3D9D5E4A8C1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\ADSOLUSOL
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=BUILD\Installer
OutputBaseFilename=ADSOLUSOL_Setup_x64
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DisableWelcomePage=no
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Binario principal y artefactos publicados
Source: "{#BuildOutputDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildOutputDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\temp"