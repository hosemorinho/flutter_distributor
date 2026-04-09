import 'dart:io';

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

    test('MakeExeConfig generates deterministic app id when yaml omits app_id', () {
      MakeExeConfig buildConfig(Map<String, dynamic> json) {
        return MakeExeConfig.fromJson(json)
          ..buildMode = 'release'
          ..buildOutputDirectory = Directory.current
          ..buildOutputFiles = <File>[]
          ..platform = 'windows'
          ..packageFormat = 'exe'
          ..outputDirectory = Directory.current;
      }

      final orangeConfig = buildConfig({
        'script_template': 'inno_setup.iss',
        'display_name': 'Orange',
        'executable_name': 'Orange.exe',
        'publisher_name': 'hosemorinho',
        'publisher_url': 'https://github.com/hosemorinho/Orange',
      });
      final orangeConfigAgain = buildConfig({
        'display_name': 'Orange',
      });
      final flClashConfig = buildConfig({
        'display_name': 'FlClash',
      });

      expect(
        orangeConfig.appId,
        matches(RegExp(r'^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$')),
      );
      expect(orangeConfig.appId, equals(orangeConfigAgain.appId));
      expect(orangeConfig.appId, isNot(equals(flClashConfig.appId)));
    });
  });
}
