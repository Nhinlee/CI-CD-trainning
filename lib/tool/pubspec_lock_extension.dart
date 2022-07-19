import 'package:pubspec_lock/pubspec_lock.dart';

class PubspecLockUtils {
  static PackageDependency copyDependencyWithType(
    PackageDependency dependency,
    DependencyType type,
  ) {
    return dependency.iswitch<PackageDependency>(
      sdk: (sdk) => PackageDependency.sdk(
        sdk.copyWith(type: type),
      ),
      hosted: (hosted) => PackageDependency.hosted(
        hosted.copyWith(type: type),
      ),
      git: (git) => PackageDependency.git(
        git.copyWith(type: type),
      ),
      path: (path) => PackageDependency.path(
        path.copyWith(type: type),
      ),
    );
  }
}
