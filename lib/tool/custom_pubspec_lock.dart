import 'dart:io';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:plain_optional/plain_optional.dart';

class CustomPubspecLock {
  final Map<String, PackageDependencySpec> packages;

  CustomPubspecLock({required this.packages});

  factory CustomPubspecLock.fromPubspecLockFile(File file) {
    final packages = _getAllPackagesFromPubspecLockFile(file);
    return CustomPubspecLock(
      packages: packages,
    );
  }

  static Map<String, PackageDependencySpec> _getAllPackagesFromPubspecLockFile(
    File file,
  ) {
    final Map<String, PackageDependencySpec> packages = {};

    final pubspecLockContent = file.readAsLinesSync();
    final packageNameRegex = RegExp(r'^\s{2}[^\s]*:$', multiLine: true);
    final packagePropertiesRegex = RegExp(r'.*:.+');

    int i = 0;
    while (i < pubspecLockContent.length) {
      final line = pubspecLockContent[i];

      if (packageNameRegex.hasMatch(line)) {
        final packageName = line.replaceAll(':', '').trim();
        final Map<String, String> packageProperties = {};

        while (i + 1 < pubspecLockContent.length &&
            !packageNameRegex.hasMatch(pubspecLockContent[i + 1])) {
          // Get all properties of package
          final nextLine = pubspecLockContent[i + 1];
          if (packagePropertiesRegex.hasMatch(nextLine)) {
            final prop = nextLine.trim().split(': ');
            if (prop.length >= 2) {
              packageProperties.addAll({
                prop[0].trim(): prop[1].replaceAll('"', '').trim(),
              });
            }
          }

          i++;
        }

        // Convert package to `PackageDependencySpec`
        final package = _convertRawPackageToPackageDependencySpec(
          packageName,
          packageProperties,
        );

        // Add to packages map
        packages.addAll({
          packageName: package,
        });
      }

      i++;
    }

    return packages;
  }

  static PackageDependencySpec _convertRawPackageToPackageDependencySpec(
    String packageName,
    Map<String, String> packageProperties,
  ) {
    final source = packageProperties['source'] ?? '';
    final version = packageProperties['version'] ?? '';
    final url = packageProperties['url'] ?? '';
    final path = packageProperties['path'] ?? '';
    final ref = packageProperties['ref'] ?? '';
    final sdk = packageProperties['sdk'] ?? '';

    PackageDependencySpec packageDependencySpec = PackageDependencySpec.hosted(
      HostedPackageDependencySpec(
        package: packageName,
        version: Optional(version),
      ),
    );

    switch (source) {
      case 'hosted':
        {
          packageDependencySpec = PackageDependencySpec.hosted(
            HostedPackageDependencySpec(
              package: packageName,
              version: Optional(version),
            ),
          );
        }
        break;
      case 'path':
        {
          packageDependencySpec = PackageDependencySpec.path(
            PathPackageDependencySpec(
              package: packageName,
              path: path,
            ),
          );
        }
        break;
      case 'git':
        {
          packageDependencySpec = PackageDependencySpec.git(
            GitPackageDependencySpec(
              package: packageName,
              url: url,
              path: Optional(path),
              ref: Optional(ref),
            ),
          );
        }
        break;
      case 'sdk':
        {
          packageDependencySpec = PackageDependencySpec.sdk(
            SdkPackageDependencySpec(
              package: packageName,
              sdk: sdk,
              version: Optional(version),
            ),
          );
        }
    }

    return packageDependencySpec;
  }
}
