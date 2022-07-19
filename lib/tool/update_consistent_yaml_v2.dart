import 'dart:io';
import './custom_pubspec_lock.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:borg/borg.dart';

// TODO: Update this logic when move to student-app

void main() {
  // Scan all dart packages in mono repos
  final allPackagePaths = _getAllPackagePaths();

  // Read & parse all package version from student & teacher app
  // TODO: Update this logic when move to student-app (because we have multi app)
  final appPubspecLockFile = File('./automation_testing/app1/pubspec.lock');
  final appPubspecYamlFile = File('./automation_testing/app1/pubspec.yaml');
  final allAppDependencies = _getAllAppDependencies(
    appPubspecLockFile,
    appPubspecYamlFile,
  );

  // Loop over all the inconsistent dependency to update
  _solveAllInconsistentDependency(allAppDependencies, allPackagePaths);
}

List<String> _getAllPackagePaths() {
  // TODO: update path relative
  final ignorePackages =
      File('lib/tool/ignore_update_package_list').readAsLinesSync();

  final dartPackages = discoverDartPackages(
    configuration: const BorgConfiguration(
      pathsToScan: ['./'],
      excludedPaths: [],
    ),
  );
  final List<String> allPackagePaths = [];
  for (final p in dartPackages) {
    if (!_isInIgnoreList(ignorePackages, p.path)) allPackagePaths.add(p.path);
  }

  return allPackagePaths;
}

bool _isInIgnoreList(List<String> ignorePackages, String path) {
  for (final package in ignorePackages) {
    if (path.contains(package)) return true;
  }
  return false;
}

Map<String, PackageDependencySpec> _getAllAppDependencies(
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
  Map<String, PackageDependencySpec> allAppDependencies,
  List<String> packagePaths,
) {
  for (final packagePath in packagePaths) {
    final file = File('$packagePath/pubspec.yaml');
    _rewriteYamlDependenciesForPackage(file, allAppDependencies);
  }
}

void _rewriteYamlDependenciesForPackage(
  File fileYaml,
  Map<String, PackageDependencySpec> allAppDependencies,
) {
  final pubspecYaml = fileYaml.readAsStringSync().toPubspecYaml();
  // Copy all dependencies
  final dependencies = [...pubspecYaml.dependencies];
  final devDependencies = [...pubspecYaml.devDependencies];
  final dependencyOverrides = [...pubspecYaml.dependencyOverrides];

  for (int i = 0; i < dependencies.length; i++) {
    final d = dependencies[i];
    if (allAppDependencies.containsKey(d.package())) {
      dependencies[i] = allAppDependencies[d.package()]!;
    }
  }

  for (int i = 0; i < devDependencies.length; i++) {
    final d = devDependencies[i];
    if (allAppDependencies.containsKey(d.package())) {
      devDependencies[i] = allAppDependencies[d.package()]!;
    }
  }

  for (int i = 0; i < dependencyOverrides.length; i++) {
    final d = dependencyOverrides[i];
    if (allAppDependencies.containsKey(d.package())) {
      dependencyOverrides[i] = allAppDependencies[d.package()]!;
    }
  }

  final newPubspecYaml = pubspecYaml.copyWith(
    dependencies: dependencies,
    devDependencies: devDependencies,
    dependencyOverrides: dependencyOverrides,
  );

  fileYaml.writeAsStringSync(newPubspecYaml.toYamlString());
}
