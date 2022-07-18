import 'dart:io';
import './pubspec_lock.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

// TODO: Update this logic when move to student-app
final ignoreList =
    File('lib/tool/ignore_update_package_list').readAsStringSync();

void main() {
  // Get input: Un-consistency package from <borg probe> command line
  final inconsistentInputFile = File('./dependency_inconsistency.txt');
  final inConsistentPackages =
      getAllPackageWithDependencyInconsistent(inconsistentInputFile);

  // Read & parse all package version from student & teacher app
  // TODO: Update this logic when move to student-app
  final appPubspecLock = PubspecLock.fromPubspecLockFile(
    File('./automation_testing/app1/pubspec.lock'),
  );

  // Loop over all the inconsistent dependency to update
  _solveAllInconsistentDependency(appPubspecLock, inConsistentPackages);
}

Map<String, List<String>> getAllPackageWithDependencyInconsistent(File file) {
  final Map<String, List<String>> rs = {};
  final inconsistentFileContent = file.readAsLinesSync();
  final headerRegex = RegExp(
    r'.*: inconsistent dependency specifications detected',
  );
  final packagePathRegex = RegExp(r'.*\/.*');

  int i = 0;
  while (i < inconsistentFileContent.length) {
    final headerLine = inconsistentFileContent[i];

    if (headerRegex.hasMatch(headerLine)) {
      final dependencyName = headerLine.trim().split(':')[0];
      final List<String> packagePaths = [];

      while (i + 1 < inconsistentFileContent.length &&
          inconsistentFileContent[i + 1].trim().isNotEmpty) {
        // Get all package paths have dependency inconsistent
        final nextLine = inconsistentFileContent[i + 1];
        if (packagePathRegex.hasMatch(nextLine)) {
          final packagePath = nextLine.trim();
          if (!ignoreList.contains(packagePath)) {
            packagePaths.add(packagePath);
          }
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

void _solveAllInconsistentDependency(
  PubspecLock appPubspecLock,
  Map<String, List<String>> inConsistentPackages,
) {
  final allAppPackages = appPubspecLock.packages;

  for (final entry in inConsistentPackages.entries) {
    final dependencyName = entry.key;
    final packagePaths = entry.value;

    if (allAppPackages.containsKey(dependencyName)) {
      for (final packagePath in packagePaths) {
        _rewriteDependencyForPackage(
          packagePath,
          allAppPackages[dependencyName]!,
        );
      }
    }
  }
}

void _rewriteDependencyForPackage(
  String packagePath,
  PackageDependencySpec dependencySpec,
) {
  final file = File('$packagePath/pubspec.yaml');
  final pubspecYaml = file.readAsStringSync().toPubspecYaml();

  // Copy all dependencies
  final dependencies = [...pubspecYaml.dependencies];
  final devDependencies = [...pubspecYaml.devDependencies];
  final dependencyOverrides = [...pubspecYaml.dependencyOverrides];

  // Get index of
  int depsIndex = dependencies.indexWhere(
    (d) => d.package() == dependencySpec.package(),
  );
  int devDepsIndex = devDependencies.indexWhere(
    (d) => d.package() == dependencySpec.package(),
  );
  int depsOverrideIndex = dependencyOverrides.indexWhere(
    (d) => d.package() == dependencySpec.package(),
  );

  // Re-write dependency
  if (depsIndex >= 0) {
    dependencies[depsIndex] = dependencySpec;
  }

  if (devDepsIndex >= 0) {
    devDependencies[devDepsIndex] = dependencySpec;
  }

  if (depsOverrideIndex >= 0) {
    dependencyOverrides[depsOverrideIndex] = dependencySpec;
  }

  final newPubspecYaml = pubspecYaml.copyWith(
    dependencies: dependencies,
    devDependencies: devDependencies,
    dependencyOverrides: dependencyOverrides,
  );

  file.writeAsStringSync(newPubspecYaml.toYamlString());
}
