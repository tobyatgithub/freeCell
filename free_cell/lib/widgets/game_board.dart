import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;
import 'playing_card.dart';

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  List<game_card.Card> _getMovableCards(List<game_card.Card> column, int cardIndex) {
    if (column.isEmpty || cardIndex >= column.length) {
      return const <game_card.Card>[];
    }
    
    // 从当前牌到最后一张牌
    final cards = column.sublist(cardIndex);
    print('Checking movable cards starting from index $cardIndex');
    print('Cards to check: ${cards.map((c) => c.toString()).join(", ")}');
    
    // 验证这些牌是否可以一起移动
    for (int i = 0; i < cards.length - 1; i++) {
      final topCard = cards[i];
      final bottomCard = cards[i + 1];
      print('Checking if ${bottomCard.toString()} can stack on ${topCard.toString()}');
      
      if (!bottomCard.canStackOnTableau(topCard)) {
        print('Cannot stack, returning only first card');
        return [cards.first];  // 如果不能一起移动，就只返回第一张牌
      }
    }
    
    // 我们暂时不考虑最大可移动牌数的限制，因为这需要访问 Provider
    // 在实际使用时，可以在 build 方法中获取 Provider 并传递给这个方法
    
    print('All cards can be moved together: ${cards.map((c) => c.toString()).join(", ")}');
    return cards;
  }

  Future<bool> _showNewGameDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新游戏'),
          content: const Text('确定要开始新游戏吗？当前进度将会丢失。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _handleDragAccept(BuildContext context, WidgetRef ref, CardDragData data, String target, int targetIndex) {
    final gameNotifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);
    print('Handling drag accept: ${data.card}, additionalCards: ${data.additionalCards.map((c) => c.toString()).join(", ")}');
    print('Source: ${data.source}, sourceIndex: ${data.sourceIndex}, target: $target, targetIndex: $targetIndex');

    // 处理从 tableau 到 tableau 的移动
    if (data.source == 'tableau' && target == 'tableau') {
      final cardCount = data.additionalCards.length + 1; // +1 是因为还有当前牌
      print('Moving $cardCount cards from tableau ${data.sourceIndex} to tableau $targetIndex');
      
      if (data.sourceIndex == targetIndex) {
        print('Source and target are the same, ignoring');
        return;
      }
      
      // 找到拖动的牌在原列中的位置
      final sourceColumn = gameState.tableau[data.sourceIndex];
      int cardIndex = -1;
      for (int i = 0; i < sourceColumn.length; i++) {
        if (sourceColumn[i].suit == data.card.suit && sourceColumn[i].rank == data.card.rank) {
          cardIndex = i;
          break;
        }
      }
      
      if (cardIndex == -1) {
        print('Card not found in source column, this should not happen');
        return;
      }
      
      print('Found card at index $cardIndex in source column');
      final cardsToMove = sourceColumn.length - cardIndex; // 从这张牌到最后的所有牌
      
      gameNotifier.moveCard(
        fromTableau: data.sourceIndex,
        toTableau: targetIndex,
        cardIndex: cardIndex,
      );
    }
    // 处理从 tableau 到 free cell 的移动
    else if (data.source == 'tableau' && target == 'freecell') {
      if (data.additionalCards.isEmpty) {  // 只能移动单张牌到 free cell
        print('Moving single card from tableau ${data.sourceIndex} to freecell $targetIndex');
        
        // 找到拖动的牌在原列中的位置
        final sourceColumn = gameState.tableau[data.sourceIndex];
        int cardIndex = -1;
        for (int i = 0; i < sourceColumn.length; i++) {
          if (sourceColumn[i].suit == data.card.suit && sourceColumn[i].rank == data.card.rank) {
            cardIndex = i;
            break;
          }
        }
        
        if (cardIndex == -1 || cardIndex != sourceColumn.length - 1) {
          print('Can only move the last card to freecell');
          return;
        }
        
        gameNotifier.moveToFreeCell(data.sourceIndex);
      } else {
        print('Cannot move multiple cards to freecell');
      }
    }
    // 处理从 free cell 到 tableau 的移动
    else if (data.source == 'freecell' && target == 'tableau') {
      print('Moving card from freecell ${data.sourceIndex} to tableau $targetIndex');
      gameNotifier.moveFromFreeCell(data.sourceIndex, targetIndex);
    }
    // 处理到 foundation 的移动
    else if (target == 'foundation') {
      if (data.additionalCards.isEmpty) {  // 只能移动单张牌到 foundation
        print('Moving single card to foundation $targetIndex');
        if (data.source == 'tableau') {
          // 找到拖动的牌在原列中的位置
          final sourceColumn = gameState.tableau[data.sourceIndex];
          int cardIndex = -1;
          for (int i = 0; i < sourceColumn.length; i++) {
            if (sourceColumn[i].suit == data.card.suit && sourceColumn[i].rank == data.card.rank) {
              cardIndex = i;
              break;
            }
          }
          
          if (cardIndex == -1 || cardIndex != sourceColumn.length - 1) {
            print('Can only move the last card to foundation');
            return;
          }
          
          gameNotifier.moveToFoundation(data.sourceIndex);
        } else if (data.source == 'freecell') {
          gameNotifier.moveFreeCellToFoundation(data.sourceIndex, targetIndex);
        }
      } else {
        print('Cannot move multiple cards to foundation');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    // 创建DragTarget包装器
    Widget buildDragTarget(Widget child, String target, int targetIndex, game_card.Card? targetCard) {
      return DragTarget<CardDragData>(
        onWillAccept: (data) {
          if (data == null) return false;
          
          print('Checking if can accept card ${data.card} with ${data.additionalCards.length} additional cards');
          print('Target: $target, targetIndex: $targetIndex, targetCard: ${targetCard?.toString() ?? "null"}');
          
          if (target == 'tableau') {
            if (targetCard == null) {
              final canAccept = data.card.rank == game_card.Rank.king;
              print('Empty tableau column, can accept King: $canAccept');
              return canAccept;
            } else {
              final canAccept = data.card.canStackOnTableau(targetCard);
              print('Can stack ${data.card} on ${targetCard.toString()}: $canAccept');
              return canAccept;
            }
          }
          
          if (target == 'foundation') {
            final canAccept = data.additionalCards.isEmpty && 
                   data.card.canStackOnFoundation(targetCard);
            print('Can move to foundation: $canAccept');
            return canAccept;
          }
          
          if (target == 'freecell') {
            final canAccept = data.additionalCards.isEmpty && targetCard == null;
            print('Can move to freecell: $canAccept');
            return canAccept;
          }
          
          return false;
        },
        onAccept: (data) {
          print('Accepting card ${data.card} at $target $targetIndex');
          _handleDragAccept(context, ref, data, target, targetIndex);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              border: isHovering
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8.r),
              color: isHovering ? Colors.blue.withOpacity(0.1) : null,
            ),
            child: child,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeCell'),
        actions: [
          // 自动移动按钮
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: '自动移动',
            onPressed: () {
              gameNotifier.autoMove();
              // TODO: 添加移动音效
            },
          ),
          // 新游戏按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '新游戏',
            onPressed: () async {
              if (await _showNewGameDialog(context)) {
                gameNotifier.newGame();
                // TODO: 添加洗牌音效
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Free cells and foundation area
          Container(
            height: 120.h,
            padding: EdgeInsets.all(8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Free cells
                Row(
                  children: List.generate(4, (index) {
                    final card = gameState.freeCells[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: card != null
                          ? buildDragTarget(
                              PlayingCard(
                                card: card,
                                source: 'freecell',
                                sourceIndex: index,
                                onDragComplete: (success, data) {
                                  print('Drag complete from freecell: success=$success, card=${data?.card}');
                                },
                              ),
                              'freecell',
                              index,
                              card,
                            )
                          : buildDragTarget(
                              Container(
                                width: 70.w,
                                height: 100.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.5),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              'freecell',
                              index,
                              null,
                            ),
                    );
                  }),
                ),
                
                // Foundation piles
                Row(
                  children: List.generate(4, (index) {
                    final pile = gameState.foundation[index];
                    return Padding(
                      padding: EdgeInsets.only(left: 4.w),
                      child: pile.isEmpty
                          ? buildDragTarget(
                              Container(
                                width: 70.w,
                                height: 100.h,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.5),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              'foundation',
                              index,
                              null,
                            )
                          : buildDragTarget(
                              PlayingCard(
                                card: pile.last,
                                source: 'foundation',
                                sourceIndex: index,
                                isDraggable: false,
                                onDragComplete: (success, data) {
                                  print('Drag complete from foundation: success=$success, card=${data?.card}');
                                },
                              ),
                              'foundation',
                              index,
                              pile.last,
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          // Tableau area
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (columnIndex) {
                  final column = gameState.tableau[columnIndex];
                  return Expanded(
                    child: Column(
                      children: [
                        if (column.isEmpty)
                          buildDragTarget(
                            Container(
                              width: 70.w,
                              height: 100.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            'tableau',
                            columnIndex,
                            null,
                          )
                        else
                          Expanded(
                            child: buildDragTarget(
                              Stack(
                                clipBehavior: Clip.none,
                                children: List.generate(column.length, (cardIndex) {
                                  final card = column[cardIndex];
                                  final isLastCard = cardIndex == column.length - 1;
                                  
                                  print('Column $columnIndex - Card at index $cardIndex: ${card.toString()}, isLastCard: $isLastCard, column.length: ${column.length}');
                                  
                                  // 获取可以一起移动的牌
                                  final movableCards = _getMovableCards(column, cardIndex);
                                  final canDrag = movableCards.length > 0; // 如果有可移动的牌，就可以拖动

                                  print('Card ${card.toString()} at index $cardIndex, canDrag: $canDrag, movableCards: ${movableCards.map((c) => c.toString()).join(", ")}');

                                  return Positioned(
                                    top: (cardIndex * 30).h,
                                    left: 0,
                                    right: 0,
                                    child: PlayingCard(
                                      card: card,
                                      source: 'tableau',
                                      sourceIndex: columnIndex,
                                      isDraggable: canDrag, // 任何可以移动的牌都可以拖动
                                      additionalCards: movableCards.length > 1 
                                          ? movableCards.sublist(1)  // 不包含当前牌
                                          : const [],
                                      onDragComplete: (success, data) {
                                        print('Drag complete from tableau: success=$success, card=${data?.card}, column: $columnIndex, cardIndex: $cardIndex');
                                      },
                                    ),
                                  );
                                }),
                              ),
                              'tableau',
                              columnIndex,
                              column.isNotEmpty ? column.last : null,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 