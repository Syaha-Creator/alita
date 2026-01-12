import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/product/presentation/helpers/product_area_matcher.dart';

void main() {
  group('ProductAreaMatcher', () {
    group('matchAreaByName', () {
      test('should match exact area name', () {
        // Arrange
        const userAreaName = 'Jabodetabek';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });

      test('should match case-insensitive area name', () {
        // Arrange
        const userAreaName = 'jabodetabek';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });

      test('should match region name to PL area', () {
        // Arrange
        const userAreaName = 'DKI Jakarta';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });

      test('should match partial region name', () {
        // Arrange
        const userAreaName = 'Jakarta';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });

      test('should match Sumatera Selatan to Palembang', () {
        // Arrange
        const userAreaName = 'SUMATRA SELATAN';
        const availableAreas = ['Palembang', 'Medan', 'Bandung'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, equals('Palembang'));
      });

      test('should return null if no match found', () {
        // Arrange
        const userAreaName = 'Unknown Area';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return null if userAreaName is null', () {
        // Arrange
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          null,
          availableAreas,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return null if userAreaName is empty', () {
        // Arrange
        const userAreaName = '';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, isNull);
      });

      test('should handle whitespace in area name', () {
        // Arrange
        const userAreaName = '  Jabodetabek  ';
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.matchAreaByName(
          userAreaName,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });
    });

    group('getAreaNameFromId', () {
      test('should return area name for known ID', () {
        // Arrange
        const areaId = 1; // Jabodetabek
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });

      test('should return area name for ID 0 (Nasional)', () {
        // Arrange
        const areaId = 0; // Nasional
        const availableAreas = ['Nasional', 'Jabodetabek', 'Bandung'];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, equals('Nasional'));
      });

      test('should return area name for ID 9 (Medan)', () {
        // Arrange
        const areaId = 9; // Medan
        const availableAreas = ['Medan', 'Palembang', 'Bandung'];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, equals('Medan'));
      });

      test('should return area name for ID 10 (Palembang)', () {
        // Arrange
        const areaId = 10; // Palembang
        const availableAreas = ['Palembang', 'Medan', 'Bandung'];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, equals('Palembang'));
      });

      test('should return "Nasional" as fallback if area not found', () {
        // Arrange
        const areaId = 999; // Unknown ID
        const availableAreas = ['Nasional', 'Jabodetabek', 'Bandung'];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, equals('Nasional'));
      });

      test('should return first available area if "Nasional" not available',
          () {
        // Arrange
        const areaId = 999; // Unknown ID
        const availableAreas = ['Jabodetabek', 'Bandung', 'Surabaya'];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, equals('Jabodetabek'));
      });

      test('should return null if no areas available', () {
        // Arrange
        const areaId = 1;
        const availableAreas = <String>[];

        // Act
        final result = ProductAreaMatcher.getAreaNameFromId(
          areaId,
          availableAreas,
        );

        // Assert
        expect(result, isNull);
      });
    });
  });
}
