import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/scheduler.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;
import 'playing_card.dart';

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  // 用于跟踪最近一次显示弹窗的时间
  static DateTime? _lastDialogTime;

  List<game_card.Card> _getMovableCards(List<game_card.Card> column, int cardIndex, {required int emptyFreeCells, required int emptyTableauColumns}) {
    if (column.isEmpty || cardIndex >= column.length) {
      print('列为空或索引超出范围: column.length=${column.length}, cardIndex=$cardIndex');
      return const <game_card.Card>[];
    }
    
    // 从当前牌到最后一张牌
    final cards = column.sublist(cardIndex);
    print('尝试移动牌: ${cards.map((c) => '${c.rank}-${c.suit}').join(', ')}');
    
    // 验证这些牌是否可以一起移动（颜色交替，数字递减）
    for (int i = 0; i < cards.length - 1; i++) {
      final topCard = cards[i];
      final bottomCard = cards[i + 1];
      
      print('检查牌是否可以堆叠: ${topCard.rank}-${topCard.suit} -> ${bottomCard.rank}-${bottomCard.suit}, 结果: ${bottomCard.canStackOnTableau(topCard)}');
      
      if (!bottomCard.canStackOnTableau(topCard)) {
        print('牌不能堆叠，只返回第一张牌');
        return [cards.first];  // 如果不能一起移动，就只返回第一张牌
      }
    }
    
    // 计算最大可移动牌数
    // 公式: (n + 1) * 2^m, 其中 n 是空闲单元格数量，m 是空列数量
    final maxMovableCards = (emptyFreeCells + 1) * (1 << emptyTableauColumns);
    print('最大可移动牌数: $maxMovableCards (空闲单元格: $emptyFreeCells, 空列: $emptyTableauColumns)');
    
    // 如果要移动的牌数超过最大可移动牌数，则只返回能移动的部分
    if (cards.length > maxMovableCards) {
      print('要移动的牌数(${cards.length})超过最大可移动牌数($maxMovableCards)，只返回部分牌');
      return cards.sublist(0, maxMovableCards);
    }
    
    print('返回所有可移动的牌: ${cards.length}张');
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
    print('处理拖拽接受: ${data.card.rank}-${data.card.suit}, 源: ${data.source}-${data.sourceIndex}, 目标: $target-$targetIndex, 附加卡牌: ${data.additionalCards.length}张');
    
    final gameNotifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);

    // 处理从 tableau 到 tableau 的移动
    if (data.source == 'tableau' && target == 'tableau') {
      final cardCount = data.additionalCards.length + 1; // +1 是因为还有当前牌
      
      if (data.sourceIndex == targetIndex) {
        print('源列和目标列相同，不执行移动');
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
        print('在源列中找不到拖动的牌');
        return;
      }
      
      final cardsToMove = sourceColumn.length - cardIndex; // 从这张牌到最后的所有牌
      print('从索引 $cardIndex 开始移动 $cardsToMove 张牌');
      
      gameNotifier.moveCard(
        fromTableau: data.sourceIndex,
        toTableau: targetIndex,
        cardIndex: cardIndex,
      );
      print('移动完成');
    }
    // 处理从 tableau 到 free cell 的移动
    else if (data.source == 'tableau' && target == 'freecell') {
      if (data.additionalCards.isEmpty) {  // 只能移动单张牌到 free cell
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
          return;
        }
        
        gameNotifier.moveToFreeCell(data.sourceIndex);
      }
    }
    // 处理从 free cell 到 tableau 的移动
    else if (data.source == 'freecell' && target == 'tableau') {
      gameNotifier.moveFromFreeCell(data.sourceIndex, targetIndex);
    }
    // 处理到 foundation 的移动
    else if (target == 'foundation') {
      if (data.additionalCards.isEmpty) {  // 只能移动单张牌到 foundation
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
            return;
          }
          
          gameNotifier.moveToFoundation(data.sourceIndex);
        } else if (data.source == 'freecell') {
          gameNotifier.moveFreeCellToFoundation(data.sourceIndex, targetIndex);
        }
      }
    }
  }

  // 显示移动限制提示
  void _showMoveLimitDialog(BuildContext context, int cardsToMove, int maxMovableCards, int emptyFreeCells, int emptyTableauColumns) {
    print('显示移动限制弹窗：尝试移动 $cardsToMove 张牌，最大可移动 $maxMovableCards 张牌');
    
    // 不使用Future.microtask，直接显示对话框
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('移动受限'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('你尝试移动 $cardsToMove 张牌，但当前最多只能移动 $maxMovableCards 张牌。'),
              const SizedBox(height: 8),
              const Text('在FreeCell中，可移动的牌数受以下限制:'),
              const SizedBox(height: 4),
              Text('• 空闲单元格: $emptyFreeCells'),
              Text('• 空列: $emptyTableauColumns'),
              const SizedBox(height: 8),
              const Text('最大可移动牌数 = (空闲单元格数 + 1) × 2^(空列数)'),
              const SizedBox(height: 8),
              const Text('提示: 先移动一些牌到空闲单元格或创建空列，然后再尝试移动多张牌。'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('了解了'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      print('弹窗已关闭');
    }).catchError((error) {
      print('显示弹窗时出错: $error');
    });
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
          
          print('尝试接受拖拽: ${data.card.rank}-${data.card.suit}, 目标: $target-$targetIndex, 附加卡牌: ${data.additionalCards.length}张');
          
          // 检查是否超过最大可移动牌数
          final emptyFreeCells = gameState.freeCells.where((cell) => cell == null).length;
          final emptyTableauColumns = gameState.tableau.where((col) => col.isEmpty).length;
          
          // 如果源列是空列，不应该计算在内
          final effectiveEmptyTableauColumns = data.source == 'tableau' && 
              gameState.tableau[data.sourceIndex].isEmpty ? 
              emptyTableauColumns - 1 : 
              emptyTableauColumns;
          
          final maxMovableCards = (emptyFreeCells + 1) * (1 << effectiveEmptyTableauColumns);
          final totalCards = data.additionalCards.length + 1; // +1 是因为还有当前牌
          
          print('检查移动限制: 总牌数=$totalCards, 最大可移动牌数=$maxMovableCards, 空闲单元格=$emptyFreeCells, 空列=$effectiveEmptyTableauColumns');
          
          if (totalCards > maxMovableCards) {
            print('超过最大可移动牌数，显示弹窗');
            // 确保在主线程上显示对话框
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showMoveLimitDialog(context, totalCards, maxMovableCards, emptyFreeCells, effectiveEmptyTableauColumns);
            });
            return false;
          }
          
          if (target == 'tableau') {
            if (targetCard == null) {
              final result = data.card.rank == game_card.Rank.king;
              print('目标是空列，检查是否为K: ${data.card.rank == game_card.Rank.king}');
              return result;
            } else {
              final result = data.card.canStackOnTableau(targetCard);
              print('检查是否可以堆叠: ${data.card.rank}-${data.card.suit} -> ${targetCard.rank}-${targetCard.suit}, 结果: $result');
              return result;
            }
          }
          
          if (target == 'foundation') {
            final result = data.additionalCards.isEmpty && 
                   data.card.canStackOnFoundation(targetCard);
            print('检查是否可以放到基础堆: ${data.card.rank}-${data.card.suit}, 结果: $result');
            return result;
          }
          
          if (target == 'freecell') {
            final result = data.additionalCards.isEmpty && targetCard == null;
            print('检查是否可以放到空闲单元格: ${data.card.rank}-${data.card.suit}, 结果: $result');
            return result;
          }
          
          return false;
        },
        onAccept: (data) {
          print('接受拖拽: ${data.card.rank}-${data.card.suit}, 目标: $target-$targetIndex, 附加卡牌: ${data.additionalCards.length}张');
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
            height: 150.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Column(
              children: [
                // Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Free Cells',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Foundation',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                // Cards area
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Free cells
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            final card = gameState.freeCells[index];
                            return SizedBox(
                              width: 60,
                              child: card != null
                                  ? buildDragTarget(
                                      PlayingCard(
                                        card: card,
                                        source: 'freecell',
                                        sourceIndex: index,
                                        width: 55,
                                        onDragComplete: (success, data) {},
                                      ),
                                      'freecell',
                                      index,
                                      card,
                                    )
                                  : buildDragTarget(
                                      Container(
                                        width: 55,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.5),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.crop_free,
                                            color: Colors.blue.withOpacity(0.5),
                                            size: 24,
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
                      ),
                      
                      // Foundation piles
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            final pile = gameState.foundation[index];
                            return SizedBox(
                              width: 60,
                              child: pile.isEmpty
                                  ? buildDragTarget(
                                      Container(
                                        width: 55,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.5),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green.withOpacity(0.5),
                                            size: 24,
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
                                        width: 55,
                                        onDragComplete: (success, data) {},
                                      ),
                                      'foundation',
                                      index,
                                      pile.last,
                                    ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tableau area
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (columnIndex) {
                  final column = gameState.tableau[columnIndex];
                  return SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        if (column.isEmpty)
                          buildDragTarget(
                            Container(
                              width: 55,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
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
                                  
                                  // 获取可以一起移动的牌
                                  final emptyFreeCells = gameState.freeCells.where((cell) => cell == null).length;
                                  final emptyTableauColumns = gameState.tableau.where((col) => col.isEmpty).length;
                                  
                                  // 如果当前列是源列，不应该计算在内
                                  final effectiveEmptyTableauColumns = column.isEmpty ? 
                                      emptyTableauColumns - 1 : 
                                      emptyTableauColumns;
                                  
                                  final movableCards = _getMovableCards(
                                    column, 
                                    cardIndex, 
                                    emptyFreeCells: emptyFreeCells,
                                    emptyTableauColumns: effectiveEmptyTableauColumns
                                  );
                                  final canDrag = movableCards.length > 0; // 如果有可移动的牌，就可以拖动

                                  return Positioned(
                                    top: (cardIndex * 20),
                                    left: 0,
                                    right: 0,
                                    child: PlayingCard(
                                      card: card,
                                      source: 'tableau',
                                      sourceIndex: columnIndex,
                                      width: 55,
                                      height: 80,
                                      isDraggable: canDrag, // 任何可以移动的牌都可以拖动
                                      additionalCards: movableCards.length > 1 
                                          ? movableCards.sublist(1)  // 不包含当前牌
                                          : const [],
                                      onDragComplete: (success, data) {},
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