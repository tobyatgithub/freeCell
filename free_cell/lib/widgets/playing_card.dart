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
    return Container(
      width: width ?? 70.w,
      height: height ?? 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
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
            top: 4.h,
            left: 4.w,
            child: Text(
              card.toString(),
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              card.suitSymbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontSize: 32.sp,
              ),
            ),
          ),
          Positioned(
            bottom: 4.h,
            right: 4.w,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                card.toString(),
                style: TextStyle(
                  color: card.isRed ? Colors.red : Colors.black,
                  fontSize: 16.sp,
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
    if (additionalCards.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: _buildCard(context),
      );
    }
    
    final totalHeight = 100.h + (additionalCards.length * 30.h);
    
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 70.w,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildCard(context),
            ...additionalCards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return Positioned(
                top: ((index + 1) * 30).h,
                left: 0,
                right: 0,
                child: PlayingCard(
                  card: card,
                  source: source,
                  sourceIndex: sourceIndex,
                  isDraggable: false,
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Draggable<CardDragData>(
        data: dragData,
        feedback: _buildDragFeedback(context),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: cardWidget,
        ),
        onDragCompleted: () {
          if (onDragComplete != null) {
            onDragComplete!(true, dragData);
          }
        },
        onDraggableCanceled: (_, __) {
          if (onDragComplete != null) {
            onDragComplete!(false, dragData);
          }
        },
        child: GestureDetector(
          onTap: onTap,
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