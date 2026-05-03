package sn.twelvepions.game

sealed class GameException(message: String) : RuntimeException(message)

class GameNotFoundException : GameException("Partie introuvable")
class NotAPlayerException : GameException("Vous ne participez pas à cette partie")
class NotYourTurnException : GameException("Ce n'est pas votre tour")
class GameNotActiveException : GameException("La partie n'est plus en cours")
class IllegalMoveException(detail: String) : GameException("Coup illégal : $detail")
