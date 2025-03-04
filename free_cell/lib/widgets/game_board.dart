import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;
import 'playing_card.dart';

class GameBoard extends ConsumerWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    return Column(
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
                        ? PlayingCard(
                            card: card,
                            onTap: () {
                              // TODO: Implement free cell tap
                            },
                          )
                        : EmptyCardSlot(
                            onTap: () {
                              // TODO: Implement empty free cell tap
                            },
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
                            onTap: () {
                              // TODO: Implement empty foundation tap
                            },
                          )
                        : PlayingCard(
                            card: pile.last,
                            onTap: () {
                              // TODO: Implement foundation pile tap
                            },
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
                          onTap: () {
                            // TODO: Implement empty tableau column tap
                          },
                        )
                      else
                        Expanded(
                          child: Stack(
                            children: List.generate(column.length, (cardIndex) {
                              return Positioned(
                                top: (cardIndex * 30).h,
                                left: 0,
                                right: 0,
                                child: PlayingCard(
                                  card: column[cardIndex],
                                  onTap: () {
                                    // TODO: Implement tableau card tap
                                  },
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
    );
  }
} 