enum Suit {
  hearts,
  diamonds,
  clubs,
  spades,
}

enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
}

class Card {
  final Suit suit;
  final Rank rank;

  const Card({
    required this.suit,
    required this.rank,
  });

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
  bool get isBlack => suit == Suit.clubs || suit == Suit.spades;

  String get suitSymbol {
    switch (suit) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  String get rankSymbol {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      default:
        return (Rank.values.indexOf(rank) + 1).toString();
    }
  }

  @override
  String toString() => '$rankSymbol$suitSymbol';

  bool canStackOnTableau(Card other) {
    if (isRed == other.isRed) return false;
    return Rank.values.indexOf(rank) == Rank.values.indexOf(other.rank) - 1;
  }

  bool canStackOnFoundation(Card? other) {
    if (other == null) return rank == Rank.ace;
    return suit == other.suit && 
           Rank.values.indexOf(rank) == Rank.values.indexOf(other.rank) + 1;
  }
} 