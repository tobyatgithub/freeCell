import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart';

class GameState {
  final List<List<Card>> tableau;  // 8 columns
  final List<Card?> freeCells;     // 4 cells
  final List<List<Card>> foundation; // 4 piles
  final bool isGameWon;

  const GameState({
    required this.tableau,
    required this.freeCells,
    required this.foundation,
    this.isGameWon = false,
  });

  GameState copyWith({
    List<List<Card>>? tableau,
    List<Card?>? freeCells,
    List<List<Card>>? foundation,
    bool? isGameWon,
  }) {
    return GameState(
      tableau: tableau ?? this.tableau,
      freeCells: freeCells ?? this.freeCells,
      foundation: foundation ?? this.foundation,
      isGameWon: isGameWon ?? this.isGameWon,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState(
    tableau: List.generate(8, (index) => []),
    freeCells: List.generate(4, (index) => null),
    foundation: List.generate(4, (index) => []),
  )) {
    newGame();
  }

  void newGame() {
    // Create a deck of cards
    final cards = <Card>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(Card(suit: suit, rank: rank));
      }
    }

    // Shuffle the deck
    final random = Random();
    for (var i = cards.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = cards[i];
      cards[i] = cards[j];
      cards[j] = temp;
    }

    // Deal cards to tableau
    final tableau = List.generate(8, (index) => <Card>[]);
    var cardIndex = 0;
    for (var i = 0; i < 52; i++) {
      tableau[i % 8].add(cards[cardIndex++]);
    }

    state = GameState(
      tableau: tableau,
      freeCells: List.generate(4, (index) => null),
      foundation: List.generate(4, (index) => []),
    );
  }

  bool canMoveToFoundation(Card card, int foundationIndex) {
    final foundation = state.foundation[foundationIndex];
    return card.canStackOnFoundation(
      foundation.isEmpty ? null : foundation.last
    );
  }

  bool canMoveToTableau(Card card, int tableauIndex) {
    final column = state.tableau[tableauIndex];
    return column.isEmpty || card.canStackOnTableau(column.last);
  }

  // 计算可移动的最大牌数
  int getMaxMovableCards() {
    int emptyFreeCells = state.freeCells.where((cell) => cell == null).length;
    int emptyTableauColumns = state.tableau.where((column) => column.isEmpty).length;
    return (emptyFreeCells + 1) * (1 << emptyTableauColumns); // 1 << n 等于 2^n
  }

  // 验证一组牌是否可以连续移动
  bool canMoveCards(List<Card> cards) {
    if (cards.isEmpty) return false;
    
    // 检查牌是否按顺序排列
    for (int i = 0; i < cards.length - 1; i++) {
      if (!cards[i + 1].canStackOnTableau(cards[i])) {
        return false;
      }
    }

    // 检查牌数是否超过最大可移动数量
    return cards.length <= getMaxMovableCards();
  }

  // 修改移动卡牌的方法以支持多张牌移动
  void moveCard({
    required int fromTableau,
    required int toTableau,
    int cardIndex = -1,
  }) {
    final sourceColumn = state.tableau[fromTableau];
    if (sourceColumn.isEmpty) return;

    final startIndex = cardIndex == -1 ? sourceColumn.length - 1 : cardIndex;
    final cardsToMove = sourceColumn.sublist(startIndex);
    
    // 验证移动是否合法
    if (!canMoveCards(cardsToMove)) return;
    
    if (state.tableau[toTableau].isEmpty || 
        cardsToMove.first.canStackOnTableau(state.tableau[toTableau].last)) {
      final newTableau = List<List<Card>>.from(state.tableau);
      newTableau[fromTableau] = sourceColumn.sublist(0, startIndex);
      newTableau[toTableau] = [...state.tableau[toTableau], ...cardsToMove];
      
      state = state.copyWith(tableau: newTableau);
      checkWinCondition();
    }
  }

  void moveToFreeCell(int tableauIndex) {
    final sourceColumn = state.tableau[tableauIndex];
    if (sourceColumn.isEmpty) return;

    final freeCellIndex = state.freeCells.indexOf(null);
    if (freeCellIndex == -1) return;

    final newFreeCells = List<Card?>.from(state.freeCells);
    newFreeCells[freeCellIndex] = sourceColumn.last;

    final newTableau = List<List<Card>>.from(state.tableau);
    newTableau[tableauIndex] = sourceColumn.sublist(0, sourceColumn.length - 1);

    state = state.copyWith(
      tableau: newTableau,
      freeCells: newFreeCells,
    );
  }

  void moveFromFreeCell(int freeCellIndex, int tableauIndex) {
    final card = state.freeCells[freeCellIndex];
    if (card == null) return;

    if (canMoveToTableau(card, tableauIndex)) {
      final newFreeCells = List<Card?>.from(state.freeCells);
      newFreeCells[freeCellIndex] = null;

      final newTableau = List<List<Card>>.from(state.tableau);
      newTableau[tableauIndex] = [...state.tableau[tableauIndex], card];

      state = state.copyWith(
        tableau: newTableau,
        freeCells: newFreeCells,
      );
      checkWinCondition();
    }
  }

  void autoMove() {
    bool moved;
    do {
      moved = false;
      
      // Try to move from tableau to foundation
      for (var i = 0; i < 8; i++) {
        final column = state.tableau[i];
        if (column.isEmpty) continue;

        final card = column.last;
        for (var j = 0; j < 4; j++) {
          if (canMoveToFoundation(card, j)) {
            moveToFoundation(i);
            moved = true;
            break;
          }
        }
      }

      // Try to move from free cells to foundation
      for (var i = 0; i < 4; i++) {
        final card = state.freeCells[i];
        if (card == null) continue;

        for (var j = 0; j < 4; j++) {
          if (canMoveToFoundation(card, j)) {
            moveFreeCellToFoundation(i, j);
            moved = true;
            break;
          }
        }
      }
    } while (moved);
  }

  void moveToFoundation(int tableauIndex) {
    final sourceColumn = state.tableau[tableauIndex];
    if (sourceColumn.isEmpty) return;

    final card = sourceColumn.last;
    for (var i = 0; i < 4; i++) {
      if (canMoveToFoundation(card, i)) {
        final newTableau = List<List<Card>>.from(state.tableau);
        newTableau[tableauIndex] = sourceColumn.sublist(0, sourceColumn.length - 1);

        final newFoundation = List<List<Card>>.from(state.foundation);
        newFoundation[i] = [...state.foundation[i], card];

        state = state.copyWith(
          tableau: newTableau,
          foundation: newFoundation,
        );
        checkWinCondition();
        break;
      }
    }
  }

  void moveFreeCellToFoundation(int freeCellIndex, int foundationIndex) {
    final card = state.freeCells[freeCellIndex];
    if (card == null) return;

    if (canMoveToFoundation(card, foundationIndex)) {
      final newFreeCells = List<Card?>.from(state.freeCells);
      newFreeCells[freeCellIndex] = null;

      final newFoundation = List<List<Card>>.from(state.foundation);
      newFoundation[foundationIndex] = [...state.foundation[foundationIndex], card];

      state = state.copyWith(
        freeCells: newFreeCells,
        foundation: newFoundation,
      );
      checkWinCondition();
    }
  }

  void checkWinCondition() {
    var isWon = true;
    for (final pile in state.foundation) {
      if (pile.length != 13) {
        isWon = false;
        break;
      }
    }
    if (isWon) {
      state = state.copyWith(isGameWon: true);
    }
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
}); 