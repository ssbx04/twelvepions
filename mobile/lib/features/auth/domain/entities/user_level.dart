/// Niveau auto-déclaré par l'utilisateur, sert à seeder l'ELO initial.
enum UserLevel {
  beginner('BEGINNER', 'Débutant', 1000),
  intermediate('INTERMEDIATE', 'Intermédiaire', 1200),
  advanced('ADVANCED', 'Avancé', 1400),
  expert('EXPERT', 'Expert', 1600);

  /// Valeur envoyée au backend (en majuscules).
  final String apiValue;

  /// Libellé affiché à l'utilisateur (en français).
  final String label;

  /// ELO de départ associé.
  final int seedElo;

  const UserLevel(this.apiValue, this.label, this.seedElo);

  static UserLevel fromApi(String value) =>
      UserLevel.values.firstWhere((e) => e.apiValue == value);
}
