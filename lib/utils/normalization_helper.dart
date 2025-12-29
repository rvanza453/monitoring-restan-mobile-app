/// Helper class for normalizing location data (afdeling, blok, TPH)
/// to ensure consistent comparison and filtering
class NormalizationHelper {
  /// Normalize afdeling value (handles Roman numerals, case, whitespace)
  static String normalizeAfdeling(String? val) {
    if (val == null || val.isEmpty) return '';
    String clean = val.trim().toUpperCase();
    if (int.tryParse(clean) != null) return int.parse(clean).toString();
    const romanMap = {
      'I': '1', 'II': '2', 'III': '3', 'IV': '4', 'V': '5',
      'VI': '6', 'VII': '7', 'VIII': '8', 'IX': '9', 'X': '10',
      'XI': '11', 'XII': '12', 'XIII': '13', 'XIV': '14', 'XV': '15'
    };
    return romanMap[clean] ?? clean;
  }

  /// Normalize blok value (handles case, whitespace, and leading zeros in numbers)
  /// Examples: "B02" -> "B2", "A01" -> "A1", "A09" -> "A9"
  static String normalizeBlok(String? val) {
    if (val == null || val.isEmpty) return '';
    String clean = val.trim().toUpperCase().replaceAll(' ', '');
    
    // Extract prefix (letters) and number part
    // Match pattern: letters followed by optional numbers
    final regex = RegExp(r'^([A-Z]+)(\d+)$');
    final match = regex.firstMatch(clean);
    
    if (match != null) {
      final prefix = match.group(1) ?? '';
      final numberStr = match.group(2) ?? '';
      
      // Remove leading zeros from number part
      final number = int.tryParse(numberStr);
      if (number != null) {
        return '$prefix$number';
      }
    }
    
    // If pattern doesn't match, return cleaned value as-is
    return clean;
  }

  /// Normalize TPH value (handles numeric conversion, whitespace)
  static String normalizeTph(String? val) {
    if (val == null || val.isEmpty) return '0';
    String clean = val.trim();
    int? number = int.tryParse(clean);
    return number?.toString() ?? clean;
  }
}

