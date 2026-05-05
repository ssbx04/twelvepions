part of 'complete_profile_bloc.dart';

sealed class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();
  @override
  List<Object?> get props => [];
}

/// Vérifie la disponibilité du username (déjà débouncé côté UI).
class UsernameCheckRequested extends CompleteProfileEvent {
  final String username;
  const UsernameCheckRequested(this.username);

  @override
  List<Object?> get props => [username];
}

/// L'utilisateur a effacé / vidé le champ username : reset état dispo.
class UsernameCleared extends CompleteProfileEvent {
  const UsernameCleared();
}

/// Soumission finale du profil.
class ProfileSubmitted extends CompleteProfileEvent {
  final String fullName;
  final String username;
  final UserLevel level;

  const ProfileSubmitted({
    required this.fullName,
    required this.username,
    required this.level,
  });

  @override
  List<Object?> get props => [fullName, username, level];
}
