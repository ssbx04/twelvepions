package sn.twelvepions.auth

/** Niveau auto-déclaré par l'utilisateur, sert à seeder l'ELO initial. */
enum class UserLevel(val seedElo: Int) {
    BEGINNER(1000),
    INTERMEDIATE(1200),
    ADVANCED(1400),
    EXPERT(1600),
}
