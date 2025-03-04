import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/game_board.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FreeCellApp(),
    ),
  );
}

class FreeCellApp extends StatelessWidget {
  const FreeCellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FreeCell Solitaire',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.robotoTextTheme(
              Theme.of(context).textTheme,
            ),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: SafeArea(
              child: GameBoard(),
            ),
          ),
        );
      },
    );
  }
}
