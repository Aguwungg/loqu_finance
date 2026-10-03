import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import entitas yang sudah kita buat
import 'domain/entities/program.dart';
import 'domain/entities/person.dart';
import 'domain/entities/transaksi.dart';
import 'presentation/pages/main_layout.dart';
import 'presentation/providers/theme_provider.dart';
import 'core/constants/colors.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi database lokal Hive
    await Hive.initFlutter();

    // Registrasi Adapter agar Hive mengenali format data kita
    Hive.registerAdapter(ProgramAdapter());
    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(TransaksiAdapter());

    await Hive.openBox<Program>('programBoxV2');
    await Hive.openBox<Person>('personBoxV2');
    await Hive.openBox<Transaksi>('transaksiBoxV2');
  } catch (e, stackTrace) {
    debugPrint('Error initializing Hive boxes: $e\n$stackTrace');
    // Jika gagal buka (misal karena beda struktur data), hapus box lama lalu buat ulang
    try {
      await Hive.deleteBoxFromDisk('programBoxV2');
      await Hive.deleteBoxFromDisk('personBoxV2');
      await Hive.deleteBoxFromDisk('transaksiBoxV2');
      await Hive.openBox<Program>('programBoxV2');
      await Hive.openBox<Person>('personBoxV2');
      await Hive.openBox<Transaksi>('transaksiBoxV2');
    } catch (fallbackError) {
      debugPrint('Tetap gagal setelah dihapus: $fallbackError');
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduFinance',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.light.background,
        extensions: <ThemeExtension<dynamic>>[
          AppColors.light,
        ],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.dark.background,
        extensions: <ThemeExtension<dynamic>>[
          AppColors.dark,
        ],
      ),
      home: const MainLayout(),
    );
  }
}