import 'dart:io';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:plain_optional/plain_optional.dart';

class PubspecLock {
  final Map<String, PackageDependencySpec> packages;

  PubspecLock({required this.packages});

  factory PubspecLock.fromPubspecLockFile(File file) {
    final packages = _getAllPackagesFromPubspecLockFile(file);
    return PubspecLock(
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
                prop[0].trim(): prop[1].trim(),
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
    final source = packageProperties['source'];
    print(packageName);
    print(source);
    print('>>>>>>>>');

    return PackageDependencySpec.hosted(
      HostedPackageDependencySpec(
        package: packageName,
      ),
    );
  }
}
