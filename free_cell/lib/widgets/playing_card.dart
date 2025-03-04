import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/card.dart' as game_card;

class PlayingCard extends StatelessWidget {
  final game_card.Card card;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const PlayingCard({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class EmptyCardSlot extends StatelessWidget {
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? color;

  const EmptyCardSlot({
    super.key,
    this.onTap,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 70.w,
        height: height ?? 100.h,
        decoration: BoxDecoration(
          color: color ?? Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.grey.withOpacity(0.5),
            width: 1.0,
          ),
        ),
      ),
    );
  }
} 