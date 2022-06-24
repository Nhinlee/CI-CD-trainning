import 'package:ci_cd_trainning/app_utils.dart';
import 'package:test/test.dart';

void main() {
  group('App utils test', () {
    test('is normal https link', () {
      // Given
      const link = "https://manabie.com";

      // When
      final isLink = AppUtils.isContainLinks(link);

      // Then
      expect(isLink, true);
    });

    test('is normal http link', () {
      // Given
      const link = "http://manabie.com";

      // When
      final isLink = AppUtils.isContainLinks(link);

      // Then
      expect(isLink, true);
    });

    test('isn\'t a link', () {
      // Given
      const link = "http//manabie.com";

      // When
      final isLink = AppUtils.isContainLinks(link);

      // Then
      expect(isLink, false);
    });
  });
}
