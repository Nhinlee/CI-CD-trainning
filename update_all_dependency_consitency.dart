import 'dart:io';
import 'package:glob/glob.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:functional_data/functional_data.dart';
import 'package:meta/meta.dart';
import 'package:plain_optional/plain_optional.dart';

void main() {
  // Get input: Un-consistency package from <borg probe> command line
  final inconsistentInputFile = File('./dependency_inconsistency.txt');
  final inConsistentPackages =
      getAllPackageWithDependencyInconsistent(inconsistentInputFile);

  // Read & parse all package version from student & teacher app
  final file = File('./automation_testing/app1/pubspec.yaml');
  final pubspecYaml = file.readAsStringSync().toPubspecYaml();

  final dCpy = [...pubspecYaml.dependencyOverrides];
  int index = dCpy.indexWhere((d) => d.package() == "url_launcher");
  dCpy[index] = const PackageDependencySpec.hosted(
    HostedPackageDependencySpec(
      package: 'url_launcher',
      version: Optional("^6.1.5"),
    ),
  );

  final newPubspecYaml = pubspecYaml.copyWith(
    dependencyOverrides: dCpy,
  );

  //
  file.writeAsStringSync(newPubspecYaml.toYamlString());
}

Map<String, List<String>> getAllPackageWithDependencyInconsistent(File file) {
  final Map<String, List<String>> rs = {};
  final inconsistentFileContent = file.readAsLinesSync();
  final headerRegex =
      RegExp(r'.*: inconsistent dependency specifications detected');
  final packagePathRegex = RegExp(r'.*\/.*');

  int i = 0;
  while (i < inconsistentFileContent.length) {
    final headerLine = inconsistentFileContent[i];
    if (headerRegex.hasMatch(headerLine)) {
      final dependencyName = headerLine.trim().split(':')[0];
      final List<String> packagePaths = [];

      while (i + 1 < inconsistentFileContent.length &&
          inconsistentFileContent[i + 1].trim().isNotEmpty) {
        final nextLine = inconsistentFileContent[i + 1];
        if (packagePathRegex.hasMatch(nextLine)) {
          packagePaths.add(nextLine.trim());
        }

        i++;
      }

      rs.addAll({
        dependencyName: [...packagePaths]
      });
    }

    i++;
  }

  return rs;
}
