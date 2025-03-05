import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/card.dart' as game_card;

class CardDragData {
  final game_card.Card card;
  final String source;
  final int sourceIndex;
  final List<game_card.Card> additionalCards;

  const CardDragData({
    required this.card,
    required this.source,
    required this.sourceIndex,
    this.additionalCards = const [],
  });
}

class PlayingCard extends StatelessWidget {
  final game_card.Card card;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final String source;
  final int sourceIndex;
  final bool isDraggable;
  final List<game_card.Card> additionalCards;
  final Function(bool, CardDragData?)? onDragComplete;

  const PlayingCard({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
    required this.source,
    required this.sourceIndex,
    this.isDraggable = true,
    this.additionalCards = const [],
    this.onDragComplete,
  });

  Widget _buildCard(BuildContext context) {
    print('构建卡牌: ${card.rank}-${card.suit}, 可拖拽: $isDraggable');
    
    return Container(
      width: width ?? 55,
      height: height ?? 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              card.toString(),
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              card.suitSymbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontSize: 24,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                card.toString(),
                style: TextStyle(
                  color: card.isRed ? Colors.red : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragFeedback(BuildContext context) {
    print('构建拖拽反馈: ${card.rank}-${card.suit}, 附加卡牌: ${additionalCards.length}张');
    
    if (additionalCards.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: _buildCard(context),
      );
    }
    
    final double cardHeight = height ?? 80.0;
    final totalHeight = cardHeight + (additionalCards.length * 20.0);
    
    print('拖拽反馈高度: $totalHeight (卡牌高度: $cardHeight, 附加卡牌: ${additionalCards.length}张)');
    
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width ?? 55,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildCard(context),
            ...additionalCards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              print('添加附加卡牌到拖拽反馈: ${card.rank}-${card.suit}, 位置: ${(index + 1) * 20}');
              return Positioned(
                top: ((index + 1) * 20).toDouble(),
                left: 0,
                right: 0,
                child: PlayingCard(
                  card: card,
                  source: source,
                  sourceIndex: sourceIndex,
                  isDraggable: false,
                  width: width,
                  height: height,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidget = _buildCard(context);

    if (!isDraggable) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    final dragData = CardDragData(
      card: card,
      source: source,
      sourceIndex: sourceIndex,
      additionalCards: additionalCards,
    );
    
    print('创建可拖拽卡牌: ${card.rank}-${card.suit}, 附加卡牌: ${additionalCards.length}张');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Draggable<CardDragData>(
        data: dragData,
        feedback: _buildDragFeedback(context),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: cardWidget,
        ),
        onDragStarted: () {
          print('开始拖拽: ${card.rank}-${card.suit}, 附加卡牌: ${additionalCards.length}张');
        },
        onDragCompleted: () {
          print('拖拽完成: ${card.rank}-${card.suit}');
          if (onDragComplete != null) {
            onDragComplete!(true, dragData);
          }
        },
        onDraggableCanceled: (_, __) {
          print('拖拽取消: ${card.rank}-${card.suit}');
          if (onDragComplete != null) {
            onDragComplete!(false, dragData);
          }
        },
        child: GestureDetector(
          onTap: () {
            print('点击卡牌: ${card.rank}-${card.suit}');
            if (onTap != null) onTap!();
          },
          child: cardWidget,
        ),
      ),
    );
  }
}

class EmptyCardSlot extends StatelessWidget {
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? color;
  final String target;
  final int targetIndex;
  final Function(CardDragData)? onAccept;
  final bool Function(CardDragData?)? onWillAccept;
  final game_card.Card? targetCard;
  final Widget? child;

  const EmptyCardSlot({
    super.key,
    this.onTap,
    this.width,
    this.height,
    this.color,
    required this.target,
    required this.targetIndex,
    this.onAccept,
    this.onWillAccept,
    this.targetCard,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardDragData>(
      onWillAccept: onWillAccept ?? (data) {
        if (data == null) return false;

        if (targetCard == null) return true;

        if (target == 'tableau') {
          return data.card.canStackOnTableau(targetCard!);
        }

        if (target == 'foundation') {
          return data.card.canStackOnFoundation(targetCard);
        }

        if (target == 'freecell') {
          return targetCard == null;
        }

        return false;
      },
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        return child ?? Container(
          width: width ?? 70.w,
          height: height ?? 100.h,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.blue.withOpacity(0.3)
                : (color ?? Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Colors.blue
                  : Colors.grey.withOpacity(0.5),
              width: candidateData.isNotEmpty ? 2.0 : 1.0,
            ),
          ),
        );
      },
    );
  }
} 