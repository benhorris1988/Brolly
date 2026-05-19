/// Unit preferences and conversion helpers.
///
/// All forecast values flow through the app in metric (°C, km/h, mm) and
/// are converted at the presentation layer using the user's chosen units.

enum TemperatureUnit { celsius, fahrenheit }

enum WindSpeedUnit { kph, mph, ms }

enum PrecipitationUnit { mm, inches }

class UnitFormat {
  UnitFormat._();

  static double cToF(double celsius) => celsius * 9 / 5 + 32;

  static double kphToMph(double kph) => kph * 0.621371;
  static double kphToMs(double kph) => kph / 3.6;

  static double mmToIn(double mm) => mm / 25.4;

  static String formatTemperature(double celsius, TemperatureUnit unit) {
    final double value = unit == TemperatureUnit.celsius ? celsius : cToF(celsius);
    final String symbol = unit == TemperatureUnit.celsius ? '°C' : '°F';
    return '${value.round()}$symbol';
  }

  /// Same as [formatTemperature] but without the unit suffix — for big hero readouts.
  static String formatTemperatureBare(double celsius, TemperatureUnit unit) {
    final double value = unit == TemperatureUnit.celsius ? celsius : cToF(celsius);
    return '${value.round()}°';
  }

  static String formatWindSpeed(double kph, WindSpeedUnit unit) {
    switch (unit) {
      case WindSpeedUnit.kph:
        return '${kph.round()} km/h';
      case WindSpeedUnit.mph:
        return '${kphToMph(kph).round()} mph';
      case WindSpeedUnit.ms:
        return '${kphToMs(kph).toStringAsFixed(1)} m/s';
    }
  }

  static String formatPrecipitation(double mm, PrecipitationUnit unit) {
    if (unit == PrecipitationUnit.mm) {
      return '${mm.toStringAsFixed(mm < 10 ? 1 : 0)} mm';
    }
    return '${mmToIn(mm).toStringAsFixed(2)}"';
  }
}
