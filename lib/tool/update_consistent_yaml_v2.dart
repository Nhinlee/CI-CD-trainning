import 'dart:io';
import 'package:ci_cd_trainning/tool/pubspec_lock_extension.dart';

import './custom_pubspec_lock.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:pubspec_lock/pubspec_lock.dart';
import 'package:borg/borg.dart';

// TODO: Update this logic when move to student-app

void main() {
  // Scan all dart packages in mono repos
  final allPackagePaths = _getAllPackagePaths();

  // TODO: Update this logic when move to student-app (because we have multi app)
  final appPubspecLockFile = File('./automation_testing/app1/pubspec.lock');
  final appPubspecYamlFile = File('./automation_testing/app1/pubspec.yaml');

  /// --- Pubspec YAML -----
  // Read & parse all dependencies version from student & teacher app yaml
  final allAppDependenciesYaml = _getAllAppDependenciesYaml(
    appPubspecLockFile,
    appPubspecYamlFile,
  );

  // Loop over all packages to update pubspec yaml
  _solveAllInconsistentDependencyYaml(allAppDependenciesYaml, allPackagePaths);

  /// --- Pubspec LOCK -----

  // Read & parse all dependencies version from student & teacher app lock file
  final allAppDependenciesLock = _getAllAppDependenciesLock(appPubspecLockFile);

  // Loop over all packages to update pubspec lock
  _solveAllInconsistentDependencyLock(allAppDependenciesLock, allPackagePaths);
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

Map<String, PackageDependencySpec> _getAllAppDependenciesYaml(
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

  // Remove all path dependencies (don't need to override path dependency)
  allPackages.removeWhere(
    (key, value) => value.iswitcho(
      path: (_) => true,
      otherwise: () => false,
    ),
  );

  return allPackages;
}

void _solveAllInconsistentDependencyYaml(
  Map<String, PackageDependencySpec> allAppDependencies,
  List<String> packagePaths,
) {
  for (final packagePath in packagePaths) {
    final file = File('$packagePath/pubspec.yaml');
    _rewriteDependenciesForPackageYaml(file, allAppDependencies);
  }
}

void _rewriteDependenciesForPackageYaml(
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

Map<String, PackageDependency> _getAllAppDependenciesLock(
  File appPubspecLockFile,
) {
  final pubspecLock =
      appPubspecLockFile.readAsStringSync().loadPubspecLockFromYaml();

  final Map<String, PackageDependency> dependencies = {};
  dependencies.addEntries(
    pubspecLock.packages.map(
      (e) => MapEntry(e.package(), e),
    ),
  );

  // Remove all path dependencies (don't need to override path dependency)
  dependencies.removeWhere(
    (key, value) => value.iswitcho(
      path: (_) => true,
      otherwise: () => false,
    ),
  );

  return dependencies;
}

void _solveAllInconsistentDependencyLock(
  Map<String, PackageDependency> allAppDependenciesLock,
  List<String> packagePaths,
) {
  for (final packagePath in packagePaths) {
    final file = File('$packagePath/pubspec.lock');
    _rewriteDependenciesForPackageLock(file, allAppDependenciesLock);
  }
}

void _rewriteDependenciesForPackageLock(
  File fileLock,
  Map<String, PackageDependency> allAppDependenciesLock,
) {
  final pubspecLock = fileLock.readAsStringSync().loadPubspecLockFromYaml();

  final dependencies = [...pubspecLock.packages];

  for (int i = 0; i < dependencies.length; i++) {
    final d = dependencies[i];
    if (allAppDependenciesLock.containsKey(d.package())) {
      // Copy dependency but still reserve the dependency type
      final newDependency = PubspecLockUtils.copyDependencyWithType(
        allAppDependenciesLock[d.package()]!,
        d.type(),
      );

      // Override old dependency
      dependencies[i] = newDependency;
    }
  }

  final newPubspecLock = pubspecLock.copyWith(packages: dependencies);

  fileLock.writeAsStringSync(newPubspecLock.toYamlString());
}
