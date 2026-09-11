enum Stroke {
  free('Free'),
  back('Back'),
  breast('Breast'),
  fly('Fly'),
  im('IM');

  final String value;
  const Stroke(this.value);

  static Stroke fromString(String value) {
    return Stroke.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Stroke.free,
    );
  }
}
