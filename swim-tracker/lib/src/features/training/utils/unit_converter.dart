/// Utility functions for converting between imperial and metric units
/// All values are stored in metric (kg, cm) in the database
/// and converted for display based on user preference
library;

class UnitConverter {
  // Conversion constants
  static const double kgToLbs = 2.20462;
  static const double lbsToKg = 0.453592;
  static const double cmToInches = 0.393701;
  static const double inchesToCm = 2.54;
  static const double cmToFeet = 0.0328084;
  static const double feetToCm = 30.48;

  /// Convert weight to kilograms (from any unit)
  static double convertWeightToKg(double value, String fromUnit) {
    if (fromUnit == 'imperial') {
      return value * lbsToKg;
    }
    // Already in kg (metric)
    return value;
  }

  /// Convert weight from kilograms (to any unit)
  static double convertWeightFromKg(double kg, String toUnit) {
    if (toUnit == 'imperial') {
      return kg * kgToLbs;
    }
    // Already in kg (metric)
    return kg;
  }

  /// Convert height to centimeters (from any unit)
  /// For imperial, expects value in inches
  static double convertHeightToCm(double value, String fromUnit) {
    if (fromUnit == 'imperial') {
      return value * inchesToCm;
    }
    // Already in cm (metric)
    return value;
  }

  /// Convert height from centimeters (to any unit)
  /// Returns inches for imperial, cm for metric
  static double convertHeightFromCm(double cm, String toUnit) {
    if (toUnit == 'imperial') {
      return cm * cmToInches;
    }
    // Already in cm (metric)
    return cm;
  }

  /// Convert feet and inches to centimeters
  static double feetInchesToCm(int feet, double inches) {
    return (feet * feetToCm) + (inches * inchesToCm);
  }

  /// Convert centimeters to feet and inches
  static ({int feet, double inches}) cmToFeetInches(double cm) {
    final totalInches = cm * cmToInches;
    final feet = (totalInches / 12).floor();
    final inches = totalInches % 12;
    return (feet: feet, inches: inches);
  }

  /// Format weight for display
  static String formatWeight(double kg, String unit) {
    if (unit == 'imperial') {
      final lbs = convertWeightFromKg(kg, unit);
      return '${lbs.toStringAsFixed(1)} lbs';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  /// Format height for display
  static String formatHeight(double cm, String unit) {
    if (unit == 'imperial') {
      final (feet: ft, inches: inches) = cmToFeetInches(cm);
      return '$ft\' ${inches.toStringAsFixed(1)}"';
    }
    return '${cm.toStringAsFixed(1)} cm';
  }

  /// Parse weight input (handles both units)
  static double? parseWeight(String input, String unit) {
    if (input.trim().isEmpty) return null;
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    // Convert to kg for storage
    return convertWeightToKg(value, unit);
  }

  /// Parse height input (handles both units)
  /// For imperial, expects format like "5.8" (5 feet 8 inches) or "68" (inches)
  static double? parseHeight(String input, String unit) {
    if (input.trim().isEmpty) return null;
    
    if (unit == 'imperial') {
      // Try to parse as feet.inches format (e.g., "5.8" = 5 feet 8 inches)
      if (input.contains('.')) {
        final parts = input.split('.');
        if (parts.length == 2) {
          final feet = int.tryParse(parts[0]);
          final inches = double.tryParse(parts[1]);
          if (feet != null && inches != null) {
            return feetInchesToCm(feet, inches);
          }
        }
      }
      // Otherwise, treat as total inches
      final inches = double.tryParse(input.trim());
      if (inches != null) {
        return inches * inchesToCm;
      }
    } else {
      // Metric: parse as cm
      final cm = double.tryParse(input.trim());
      if (cm != null) {
        return cm;
      }
    }
    return null;
  }

  /// Format weight input value for display in form field
  static String formatWeightInput(double? kg, String unit) {
    if (kg == null) return '';
    final displayValue = convertWeightFromKg(kg, unit);
    return displayValue.toStringAsFixed(1);
  }

  /// Format height input value for display in form field
  /// For imperial, returns inches only (user can enter feet.inches format)
  static String formatHeightInput(double? cm, String unit) {
    if (cm == null) return '';
    if (unit == 'imperial') {
      final totalInches = convertHeightFromCm(cm, unit);
      return totalInches.toStringAsFixed(1);
    }
    return cm.toStringAsFixed(1);
  }
}
