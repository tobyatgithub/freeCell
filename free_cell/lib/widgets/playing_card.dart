import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/card.dart' as game_card;

class CardDragData {
  final game_card.Card card;
  final String source;
  final int sourceIndex;

  const CardDragData({
    required this.card,
    required this.source,
    required this.sourceIndex,
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

  @override
  Widget build(BuildContext context) {
    final cardWidget = _buildCard(context);

    if (!isDraggable) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return Draggable<CardDragData>(
      data: CardDragData(
        card: card,
        source: source,
        sourceIndex: sourceIndex,
      ),
      feedback: cardWidget,
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: cardWidget,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: cardWidget,
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
    this.targetCard,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardDragData>(
      onWillAccept: (data) {
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