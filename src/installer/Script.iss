﻿; Inno Setup
; https://jrsoftware.org/isinfo.php

#define MyAppName "Lively Wallpaper"
#define MyAppVersion "1.7.4.0"
#define MyAppPublisher "rocksdanister"
#define MyAppURL "https://github.com/rocksdanister/lively"
#define MyAppExeName "livelywpf.exe"

[CustomMessages]
english.RunAtStartup=Start with Windows
chinese.RunAtStartup=开机自启动
russian.RunAtStartup=Включение с Windows
spanish.RunAtStartup=Iniciar con Windows

english.DeleteEverythigMsgBox=Do you want to delete data folder?
chinese.DeleteEverythigMsgBox=Do you want to delete data folder?
russian.DeleteEverythigMsgBox=Do you want to delete data folder?
spanish.DeleteEverythigMsgBox=Do you want to delete data folder?

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{E3E43E1B-DEC8-44BF-84A6-243DBA3F2CB1}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Remove the following line to run in administrative install mode (install for all users.)
; lowest - AppData folder, admin - Program Files (x86) 
PrivilegesRequired=lowest
; Ask user which PrivilegesRequired on startup.
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=lively_installer
SetupIconFile=Icons\appicon_96.ico
Compression=lzma
;Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
;Installer/Uninstaller will stop if application is running by checking mutex.
AppMutex=LIVELY:DESKTOPWALLPAPERSYSTEM
;https://jrsoftware.org/ishelp/index.php?topic=winvernotes
;Win10 1903 or above
MinVersion=10.0.18362
WizardSmallImageFile=Theme\wizard_small.bmp
WizardImageFile=Theme\wizard_large.bmp
;Default is hide the welcome page, ms guidelines
DisableWelcomePage=no
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"; LicenseFile: "License\License.txt";
Name: "chinese"; MessagesFile: "Setup Languages\ChineseSimplified.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl";
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl";

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; 
;GroupDescription: "{cm:AdditionalIcons}"
Name: "windowsstartup";Description: "{cm:RunAtStartup}" 

[Registry]
;current user only
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "livelywpf"; ValueData: """{app}\livelywpf.exe"""; Flags: uninsdeletevalue; Tasks:windowsstartup

;[UninstallDelete]

[Files]
Source: "VC\VC_redist.x86.exe"; DestDir: {tmp}; Flags: deleteafterinstall
Source: "dotnetcore\windowsdesktop-runtime-3.1.21-win-x86.exe"; DestDir: {tmp}; Flags: deleteafterinstall
Source: "dotnetcore\netcorecheck.exe"; DestDir: {tmp}; Flags: deleteafterinstall

; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: "Release\livelywpf.exe"; DestDir: "{app}"; Flags: ignoreversion;
Source: "Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs;

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall; Check: AutoLaunch 
;skipifsilent
Filename: "{tmp}\VC_redist.x86.exe"; Parameters: /install /quiet /norestart; Check: VCRedistNeedsInstall and DependencyInstall; StatusMsg: Installing Visual C++ Redistributable...
;todo:write loop for Check
Filename: "{tmp}\windowsdesktop-runtime-3.1.21-win-x86.exe"; Parameters: /install /quiet /norestart; Check: NetCoreNeedsInstall('3.1.20') and DependencyInstall;  StatusMsg: Installing .Net Core 3.1.21...

[Code]
var
  isAlreadyInstalled: Boolean;

// Visual C++ redistributive component install.
// ref: https://bell0bytes.eu/inno-setup-vc/
type
  INSTALLSTATE = Longint;

  const
  INSTALLSTATE_INVALIDARG = -2;  { An invalid parameter was passed to the function. }
  INSTALLSTATE_UNKNOWN = -1;     { The product is neither advertised or installed. }
  INSTALLSTATE_ADVERTISED = 1;   { The product is advertised but not installed. }
  INSTALLSTATE_ABSENT = 2;       { The product is installed for a different user. }
  INSTALLSTATE_DEFAULT = 5;      { The product is installed for the current user. }

#IFDEF UNICODE
  #DEFINE AW "W"
#ELSE
  #DEFINE AW "A"
#ENDIF

{ Visual C++ 2019 v14, the included installer is a bundle consisting of older vers }
VC_2019_REDIST_X86_MIN = '{2E72FA1F-BADB-4337-B8AE-F7C17EC57D1D}';
VC_2019_REDIST_X86_142829515_MIN = '{CAA58D4B-E030-422E-8012-904C3371E68F}';

function MsiQueryProductState(szProduct: string): INSTALLSTATE; 
  external 'MsiQueryProductState{#AW}@msi.dll stdcall';

function VCVersionInstalled(const ProductID: string): Boolean;
begin
  Result := MsiQueryProductState(ProductID) = INSTALLSTATE_DEFAULT;
end;

function VCRedistNeedsInstall: Boolean;
begin
  Result := not VCVersionInstalled(VC_2019_REDIST_X86_MIN);
end;


// event fired when the uninstall step is changed: https://stackoverflow.com/revisions/12645836/1
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  // if we reached the post uninstall step (uninstall succeeded), then...
  if CurUninstallStep = usPostUninstall then
  begin
    // query user to confirm deletion; if user chose "Yes", then...
    if SuppressibleMsgBox(ExpandConstant('{cm:DeleteEverythigMsgBox}')+ ' ' + ExpandConstant('{localappdata}\Lively Wallpaper') + ' ?',
      mbConfirmation, MB_YESNO, IDNO) = IDYES
    then
      // deletion confirmed by user.
      begin
        // Delete the directory "C:\Users\<UserName>\AppData\Local\Lively Wallpaper" and everything inside it
        DelTree(ExpandConstant('{localappdata}\Lively Wallpaper'), True, True, True);
      end;
  end;
end;

//Uninstall previous install: https://stackoverflow.com/questions/2000296/inno-setup-how-to-automatically-uninstall-previous-installed-version
//note: Inno does not delete files, it just overwrites & keeps the old ones if they have different name..it can get accumulated when program structure change!
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;


/////////////////////////////////////////////////////////////////////
function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;


/////////////////////////////////////////////////////////////////////
function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
// Return Values:
// 1 - uninstall string is empty
// 2 - error executing the UnInstallString
// 3 - successfully executed the UnInstallString

  // default return value
  Result := 0;
  // get the uninstall string of the old app
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      begin
        isAlreadyInstalled := True;
        Result := 3;
      end
    else
      begin
      isAlreadyInstalled := True;
      Result := 2;
      end
  end else
    isAlreadyInstalled := False;
    Result := 1;
end;

/////////////////////////////////////////////////////////////////////
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep=ssInstall) then
  begin
    if (IsUpgrade()) then
    begin
      UnInstallOldVersion();
    end;
  end;
end;

function ShouldInstallWallpapers: Boolean;
begin
    Result := not isAlreadyInstalled;
end;

//////////////////////////////////////////////////////////////////////
// Uninstaller promts user whether to close lively if running before proceeding.
function InitializeUninstall(): Boolean;
var
  ErrorCode: Integer;
begin
  if CheckForMutexes('LIVELY:DESKTOPWALLPAPERSYSTEM') and
     (SuppressibleMsgBox('Application is running, do you want to close it?',
             mbConfirmation, MB_OKCANCEL, IDOK) = IDOK) then
  begin
    ShellExec('open','taskkill.exe','/f /im {#MyAppExeName}','',SW_HIDE,ewWaitUntilTerminated,ErrorCode);
  end;

  Result := True;
end;
//////////////////////////////////////////////////////////////////////
// Credits: https://github.com/domgho/InnoDependencyInstaller
// NetCoreCheck tool is necessary for detecting if a specific version of .NET Core/.NET 5.0 is installed: https://github.com/dotnet/runtime/issues/36479
// Source code: https://github.com/dotnet/deployment-tools/tree/master/src/clickonce/native/projects/NetCoreCheck
// Download netcorecheck.exe: https://go.microsoft.com/fwlink/?linkid=2135256
// Download netcorecheck_x64.exe: https://go.microsoft.com/fwlink/?linkid=2135504
function NetCoreNeedsInstall(version: String): Boolean;
var
	netcoreRuntime: String;
	resultCode: Integer;
begin
  // Example: 'Microsoft.NETCore.App', 'Microsoft.AspNetCore.App', 'Microsoft.WindowsDesktop.App'
  netcoreRuntime := 'Microsoft.WindowsDesktop.App'
	Result := not(Exec(ExpandConstant('{tmp}{\}') + 'netcorecheck.exe', netcoreRuntime + ' ' + version, '', SW_HIDE, ewWaitUntilTerminated, resultCode) and (resultCode = 0));
end;

function CmdLineParamNotExists(const Value: string): Boolean;
var
  I: Integer;  
begin
  Result := True;
  for I := 1 to ParamCount do
    if CompareText(ParamStr(I), Value) = 0 then
    begin
      Result := False;
      Exit;
    end;
end;

function DependencyInstall(): Boolean;
begin
  Result := CmdLineParamNotExists('/NODEPENDENCIES');
end;

function AutoLaunch(): Boolean;
begin
 Result := CmdLineParamNotExists('/NOAUTOLAUNCH');
end;
