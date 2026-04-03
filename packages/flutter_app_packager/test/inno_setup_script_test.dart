import 'dart:io';

import 'package:flutter_app_packager/src/makers/exe/inno_setup/inno_setup_script.dart';
import 'package:flutter_app_packager/src/makers/exe/make_exe_config.dart';
import 'package:test/test.dart';

void main() {
  group('InnoSetupScript firewall configuration', () {
    MakeExeConfig createTestConfig() {
      final config = MakeExeConfig(
        appId: 'test-app-id',
        displayName: 'TestApp',
        executableName: 'TestApp.exe',
        publisherName: 'TestPublisher',
        publisherUrl: 'https://example.com',
        privilegesRequired: 'admin',
        locales: [
          {'lang': 'en'},
        ],
      );

      config
        ..isInstaller = true
        ..buildMode = 'release'
        ..buildOutputDirectory = Directory.current
        ..buildOutputFiles = <File>[]
        ..platform = 'windows'
        ..packageFormat = 'exe'
        ..outputDirectory = Directory.current;

      return config;
    }

    Future<String> renderScript() async {
      final config = createTestConfig();
      final innoScript = InnoSetupScript.fromMakeConfig(config);
      final scriptFile = await innoScript.createFile();
      return scriptFile.readAsString();
    }

    test('generated .iss does not contain add_firewall_rules.bat', () async {
      final content = await renderScript();
      expect(content, isNot(contains('add_firewall_rules.bat')));
    });

    test('generated .iss contains native firewall functions', () async {
      final content = await renderScript();
      expect(content, contains('ConfigureFirewall'));
      expect(content, contains('AddFirewallRule'));
      expect(content, contains('DeleteFirewallRule'));
    });

    test('generated .iss contains uninstall firewall cleanup hook', () async {
      final content = await renderScript();
      expect(content, contains('RemoveFirewallRules'));
      expect(content, contains('CurUninstallStepChanged'));
      expect(content, contains('usUninstall'));
    });

    test('generated .iss contains tolerant firewall cleanup logging', () async {
      final content = await renderScript();
      expect(content, contains('Log('));
      expect(content, contains('IntToStr(ResultCode)'));
      expect(content, contains('ResultCode <> 0'));
    });

    test('generated .iss contains netsh command', () async {
      final content = await renderScript();
      expect(content, contains("Exec('netsh'"));
      expect(content, contains('advfirewall firewall'));
    });

    test('generated .iss does not call cmd to execute bat', () async {
      final content = await renderScript();
      expect(content, isNot(contains('{cmd}')));
      expect(content, isNot(contains('/C')));
    });
  });
}
