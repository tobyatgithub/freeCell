import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FreeCell'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Implement new game
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Free cells and foundation area
            Container(
              height: 120.h,
              padding: EdgeInsets.all(8.w),
              child: const Row(
                children: [
                  // TODO: Implement free cells
                  // TODO: Implement foundation piles
                ],
              ),
            ),
            
            // Tableau area
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: const Row(
                  children: [
                    // TODO: Implement tableau piles
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 