import 'dart:io';

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_app_packager/src/api/app_package_maker.dart';
import 'package:path/path.dart' as p;

class MakeExeConfig extends MakeConfig {
  MakeExeConfig({
    this.scriptTemplate,
    required this.appId,
    this.executableName,
    this.displayName,
    this.publisherName,
    this.publisherUrl,
    this.createDesktopIcon,
    this.launchAtStartup,
    this.installDirName,
    this.setupIconFile,
    this.privilegesRequired,
    this.locales,
  });

  factory MakeExeConfig.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? locales = json['locales'] != null
        ? List<Map<String, dynamic>>.from(json['locales'])
        : null;
    if (locales == null || locales.isEmpty) {
      locales = [
        {'lang': 'en'}
      ];
    }

    final String resolvedAppId =
        (json['app_id'] ?? json['appId'])?.toString() ??
        _defaultAppIdFromAppName(
          (json['app_name'] ?? json['display_name'] ?? 'app').toString(),
        );

    MakeExeConfig makeExeConfig = MakeExeConfig(
      scriptTemplate: json['script_template'],
      appId: resolvedAppId,
      executableName: json['executable_name'],
      displayName: json['display_name'],
      publisherName: json['publisher_name'] ?? json['appPublisher'],

      createDesktopIcon: json['create_desktop_icon'],
      launchAtStartup: json['launch_at_startup'],
      installDirName: json['install_dir_name'],
      setupIconFile: json['setup_icon_file'],
      privilegesRequired: json['privileges_required'],
      locales: locales,
    );
    return makeExeConfig;
  }

  String? scriptTemplate;
  final String appId;
  String? executableName;
  String? displayName;
  String? publisherName;
  String? publisherUrl;
  bool? createDesktopIcon;
  bool? launchAtStartup;
  String? installDirName;
  String? setupIconFile;
  String? privilegesRequired;
  List<Map<String, dynamic>>? locales;

  String get defaultExecutableName {
    File executableFile = packagingDirectory
        .listSync()
        .where((e) => e.path.endsWith('.exe'))
        .map((e) => File(e.path))
        .first;
    return p.basename(executableFile.path);
  }

  String get defaultInstallDirName => '{autopf64}\\$appName';

  String get sourceDir => p.basename(packagingDirectory.path);

  String get outputBaseFileName =>
      p.basename(outputFile.path).replaceAll('.exe', '');

  @override
  Map<String, dynamic> toJson() {
    return {
      'script_template': scriptTemplate,
      'app_id': appId,
      'arch': arch,
      'app_name': appName,
      'app_version': appVersion.toString(),
      'executable_name': executableName,
      'display_name': displayName,
      'publisher_name': publisherName,
      'publisher_url': publisherUrl,
      'create_desktop_icon': createDesktopIcon,
      'launch_at_startup': launchAtStartup,
      'install_dir_name': installDirName,
      'setup_icon_file': setupIconFile,
      'privileges_required': privilegesRequired,
      'locales': locales,
    }..removeWhere((key, value) => value == null);
  }
}

String _defaultAppIdFromAppName(String appName) {
  final hash = sha256.convert(utf8.encode(appName.toLowerCase()));
  final bytes = hash.bytes.take(16).toList();

  String toHex(List<int> chunk) => chunk
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();

  return '${toHex(bytes.sublist(0, 4))}-${toHex(bytes.sublist(4, 6))}-${toHex(bytes.sublist(6, 8))}-${toHex(bytes.sublist(8, 10))}-${toHex(bytes.sublist(10, 16))}';
}

class MakeExeConfigLoader extends DefaultMakeConfigLoader {

  MakeConfig load(
    Map<String, dynamic>? arguments,
    Directory outputDirectory, {
    required Directory buildOutputDirectory,
    required List<File> buildOutputFiles,
  }) {
    final baseMakeConfig = super.load(
      arguments,
      outputDirectory,
      buildOutputDirectory: buildOutputDirectory,
      buildOutputFiles: buildOutputFiles,
    );
    final map = loadMakeConfigYaml(
      '$platform/packaging/$packageFormat/make_config.yaml',
    );
    return MakeExeConfig.fromJson(map).copyWith(baseMakeConfig)
      ..isInstaller = true;
  }
}
