[Setup]
AppId=test-app-id
AppVersion=0.4.2
AppName=TestApp
AppPublisher=TestPublisher
AppPublisherURL=https://example.com
AppSupportURL=https://example.com
AppUpdatesURL=https://example.com
DefaultDirName={autopf64}\flutter_app_packager
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=flutter_app_packager-0.4.2-windows-setup
Compression=lzma
SolidCompression=yes
SetupIconFile=
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Code]
function IsArm64(): Boolean;
begin
  Result := (ProcessorArchitecture = paARM64);
end;

procedure DeleteFirewallRule(const RuleName: String);
var
  ResultCode: Integer;
begin
  Exec('netsh', 'advfirewall firewall delete rule name="' + RuleName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if ResultCode <> 0 then
    Log('Firewall cleanup skipped for rule "' + RuleName + '", netsh exit code=' + IntToStr(ResultCode))
  else
    Log('Firewall cleanup succeeded for rule "' + RuleName + '"');
end;

procedure AddFirewallRule(const RuleName, ExePath, Description: String);
var
  ResultCode: Integer;
begin
  Exec('netsh', 'advfirewall firewall add rule name="' + RuleName + '" dir=in action=allow program="' + ExePath + '" enable=yes profile=any description="' + Description + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if ResultCode <> 0 then
    Log('Firewall rule add failed for rule "' + RuleName + '", netsh exit code=' + IntToStr(ResultCode))
  else
    Log('Firewall rule add succeeded for rule "' + RuleName + '"');
end;

procedure ConfigureFirewall;
var
  AppDir: String;
  DisplayName: String;
  MainExe: String;
  CoreExe: String;
  HelperExe: String;
begin
  AppDir := ExpandConstant('{app}');
  DisplayName := 'TestApp';
  MainExe := AppDir + 'TestApp.exe';
  CoreExe := AppDir + 'flutter_app_packagerCore.exe';
  HelperExe := AppDir + 'flutter_app_packagerHelperService.exe';

  DeleteFirewallRule(DisplayName);
  DeleteFirewallRule('flutter_app_packagerCore.exe');
  DeleteFirewallRule('flutter_app_packagerHelperService.exe');

  if FileExists(MainExe) then
    AddFirewallRule(DisplayName, MainExe, 'Allow ' + DisplayName + ' main program inbound connections');

  if FileExists(CoreExe) then
    AddFirewallRule('flutter_app_packagerCore.exe', CoreExe, 'Allow ' + DisplayName + ' core program network connections');

  if FileExists(HelperExe) then
    AddFirewallRule('flutter_app_packagerHelperService.exe', HelperExe, 'Allow ' + DisplayName + ' helper service network connections');
end;

procedure RemoveFirewallRules;
begin
  DeleteFirewallRule('TestApp');
  DeleteFirewallRule('flutter_app_packagerCore.exe');
  DeleteFirewallRule('flutter_app_packagerHelperService.exe');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    ConfigureFirewall;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RemoveFirewallRules;
end;

[Languages]

Name: "english"; MessagesFile: "compiler:Default.isl"


























[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "launchAtStartup"; Description: "{cm:AutoStartProgram,TestApp}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
[Files]
Source: "flutter_app_packager-0.4.2-windows-setup_exe\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\TestApp"; Filename: "{app}\TestApp.exe"
Name: "{autodesktop}\TestApp"; Filename: "{app}\TestApp.exe"; Tasks: desktopicon
Name: "{userstartup}\TestApp"; Filename: "{app}\TestApp.exe"; WorkingDir: "{app}"; Tasks: launchAtStartup
[Run]
Filename: "{app}\TestApp.exe"; Description: "{cm:LaunchProgram,TestApp}"; Flags: runascurrentuser nowait postinstall skipifsilent
