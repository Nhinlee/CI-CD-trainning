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
  // TODO: Update this logic when move to student-app (because we have multi app)
  final appPubspecLockFile = File('./automation_testing/app1/pubspec.lock');
  final appPubspecYamlFile = File('./automation_testing/app1/pubspec.yaml');
  final allAppPackages = _getAllAppPackages(
    appPubspecLockFile,
    appPubspecYamlFile,
  );

  // Loop over all the inconsistent dependency to update
  _solveAllInconsistentDependency(allAppPackages, inConsistentPackages);
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

Map<String, PackageDependencySpec> _getAllAppPackages(
  File appPubspecLockFile,
  File appPubspecYamlFile,
) {
  final appPubspecLock = CustomPubspecLock.fromPubspecLockFile(
    appPubspecLockFile,
  );
  final appPubspecYaml = appPubspecYamlFile.readAsStringSync().toPubspecYaml();

  final allPackages = appPubspecLock.packages;
  final allAppDependenciesInYaml = [
    ...appPubspecYaml.dependencies,
    ...appPubspecYaml.devDependencies,
    ...appPubspecYaml.dependencyOverrides,
  ];

  // If package already have in file yaml of teacher app / learner app
  // ->>> re-write that package for all packages from `pubspec.lock`
  for (final dep in allAppDependenciesInYaml) {
    if (allPackages.containsKey(dep.package())) {
      allPackages[dep.package()] = dep;
    }
  }

  return allPackages;
}

void _solveAllInconsistentDependency(
  Map<String, PackageDependencySpec> allAppPackages,
  Map<String, List<String>> inConsistentPackages,
) {
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
