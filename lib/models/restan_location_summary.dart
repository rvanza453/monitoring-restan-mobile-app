class RestanLocationSummary {
  final String afdeling;
  final String blok;
  final String noTph;
  final int totalPanenJjg;
  final int totalKirimJjg;
  final double totalPanenKg;
  final double totalKirimKg;
  final double bjr;

  RestanLocationSummary({
    required this.afdeling,
    required this.blok,
    required this.noTph,
    required this.totalPanenJjg,
    required this.totalKirimJjg,
    required this.totalPanenKg,
    required this.totalKirimKg,
    required this.bjr,
  });

  int get selisihJjg => totalPanenJjg - totalKirimJjg;
  
  double get selisihKg => totalPanenKg - totalKirimKg;

  // Estimate restan kg based on average BJR from harvest
  double get estRestanKg => selisihJjg > 0 ? selisihJjg * bjr : 0.0;

  String get locationKey => '${afdeling}_${blok}_${noTph}';
}
