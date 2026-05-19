import 'package:brolly/core/units/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitFormat', () {
    test('formats Celsius', () {
      expect(UnitFormat.formatTemperature(20, TemperatureUnit.celsius), '20°C');
    });

    test('converts to Fahrenheit', () {
      expect(UnitFormat.formatTemperature(0, TemperatureUnit.fahrenheit), '32°F');
    });

    test('km/h → mph', () {
      expect(UnitFormat.kphToMph(100).round(), 62);
    });

    test('mm → inches', () {
      expect(UnitFormat.formatPrecipitation(25.4, PrecipitationUnit.inches),
          '1.00"');
    });
  });
}
