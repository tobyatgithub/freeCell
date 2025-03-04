import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;
import 'playing_card.dart';

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

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

    // 处理从 tableau 到 tableau 的移动
    if (data.source == 'tableau' && target == 'tableau') {
      gameNotifier.moveCard(
        fromTableau: data.sourceIndex,
        toTableau: targetIndex,
      );
    }
    // 处理从 tableau 到 free cell 的移动
    else if (data.source == 'tableau' && target == 'freecell') {
      gameNotifier.moveToFreeCell(data.sourceIndex);
    }
    // 处理从 free cell 到 tableau 的移动
    else if (data.source == 'freecell' && target == 'tableau') {
      gameNotifier.moveFromFreeCell(data.sourceIndex, targetIndex);
    }
    // 处理到 foundation 的移动
    else if (target == 'foundation') {
      if (data.source == 'tableau') {
        gameNotifier.moveToFoundation(data.sourceIndex);
      } else if (data.source == 'freecell') {
        gameNotifier.moveFreeCellToFoundation(data.sourceIndex, targetIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

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
                          ? EmptyCardSlot(
                              target: 'freecell',
                              targetIndex: index,
                              targetCard: card,
                              onAccept: (data) => _handleDragAccept(context, ref, data, 'freecell', index),
                              child: PlayingCard(
                                card: card,
                                source: 'freecell',
                                sourceIndex: index,
                              ),
                            )
                          : EmptyCardSlot(
                              target: 'freecell',
                              targetIndex: index,
                              onAccept: (data) => _handleDragAccept(context, ref, data, 'freecell', index),
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
                          ? EmptyCardSlot(
                              color: Colors.green.withOpacity(0.1),
                              target: 'foundation',
                              targetIndex: index,
                              onAccept: (data) => _handleDragAccept(context, ref, data, 'foundation', index),
                            )
                          : EmptyCardSlot(
                              target: 'foundation',
                              targetIndex: index,
                              targetCard: pile.last,
                              onAccept: (data) => _handleDragAccept(context, ref, data, 'foundation', index),
                              child: PlayingCard(
                                card: pile.last,
                                source: 'foundation',
                                sourceIndex: index,
                                isDraggable: false,
                              ),
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
                          EmptyCardSlot(
                            target: 'tableau',
                            targetIndex: columnIndex,
                            onAccept: (data) => _handleDragAccept(context, ref, data, 'tableau', columnIndex),
                          )
                        else
                          Expanded(
                            child: Stack(
                              children: List.generate(column.length, (cardIndex) {
                                final card = column[cardIndex];
                                final isLastCard = cardIndex == column.length - 1;
                                return Positioned(
                                  top: (cardIndex * 30).h,
                                  left: 0,
                                  right: 0,
                                  child: isLastCard
                                      ? EmptyCardSlot(
                                          target: 'tableau',
                                          targetIndex: columnIndex,
                                          targetCard: card,
                                          onAccept: (data) => _handleDragAccept(context, ref, data, 'tableau', columnIndex),
                                          child: PlayingCard(
                                            card: card,
                                            source: 'tableau',
                                            sourceIndex: columnIndex,
                                            isDraggable: true,
                                          ),
                                        )
                                      : PlayingCard(
                                          card: card,
                                          source: 'tableau',
                                          sourceIndex: columnIndex,
                                          isDraggable: false,
                                        ),
                                );
                              }),
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