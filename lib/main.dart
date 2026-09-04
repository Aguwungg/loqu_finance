import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import entitas yang sudah kita buat
import 'domain/entities/program.dart';
import 'domain/entities/person.dart';
import 'domain/entities/transaksi.dart';
import 'presentation/pages/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi database lokal Hive
    await Hive.initFlutter();

    // Registrasi Adapter agar Hive mengenali format data kita
    Hive.registerAdapter(ProgramAdapter());
    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(TransaksiAdapter());

    // Buka Box (Ini ibarat membuka/membuat tabel di dalam database)
    await Hive.openBox<Program>('programBox');
    await Hive.openBox<Person>('personBox');
    await Hive.openBox<Transaksi>('transaksiBox');
  } catch (e, stackTrace) {
    debugPrint('Error initializing Hive boxes: $e\n$stackTrace');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduFinance',
      theme: ThemeData(
        primaryColor: const Color(0xFF001F3F), 
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainLayout(),
    );
  }
}