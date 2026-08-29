import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:edu_finance/main.dart';
import 'package:edu_finance/domain/entities/program.dart';
import 'package:edu_finance/domain/entities/person.dart';
import 'package:edu_finance/domain/entities/transaksi.dart';
import 'package:edu_finance/domain/repositories/program_repository.dart';
import 'package:edu_finance/domain/repositories/person_repository.dart';
import 'package:edu_finance/domain/repositories/transaksi_repository.dart';
import 'package:edu_finance/presentation/providers/master_data_providers.dart';
import 'package:edu_finance/presentation/providers/slip_gaji_provider.dart';

class FakeProgramRepository implements ProgramRepository {
  final List<Program> _programs = [];
  
  @override
  List<Program> getPrograms() => _programs;
  
  @override
  Future<void> addProgram(Program program) async => _programs.add(program);
  
  @override
  Future<void> updateProgram(Program program) async {
    final index = _programs.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      _programs[index] = program;
    }
  }
  
  @override
  Future<void> deleteProgram(String id) async => _programs.removeWhere((p) => p.id == id);
}

class FakePersonRepository implements PersonRepository {
  final List<Person> _people = [];
  
  @override
  List<Person> getPeople() => _people;
  
  @override
  Future<void> addPerson(Person person) async => _people.add(person);
  
  @override
  Future<void> updatePerson(Person person) async {
    final index = _people.indexWhere((p) => p.id == person.id);
    if (index != -1) {
      _people[index] = person;
    }
  }
  
  @override
  Future<void> deletePerson(String id) async => _people.removeWhere((p) => p.id == id);
}

class FakeTransaksiRepository implements TransaksiRepository {
  final List<Transaksi> _transaksi = [];

  @override
  List<Transaksi> getTransaksi() => _transaksi;

  @override
  Future<void> addTransaksi(Transaksi transaksi) async => _transaksi.add(transaksi);

  @override
  Future<void> updateTransaksi(Transaksi transaksi) async {
    final index = _transaksi.indexWhere((t) => t.id == transaksi.id);
    if (index != -1) {
      _transaksi[index] = transaksi;
    }
  }

  @override
  Future<void> deleteTransaksi(String id) async => _transaksi.removeWhere((t) => t.id == id);
}

void main() {
  testWidgets('App renders main layout and Buat Slip Gaji page by default', (WidgetTester tester) async {
    // Set custom screen width to ensure desktop layout sizes don't overflow in test constraints
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    final fakeProgramRepo = FakeProgramRepository();
    final fakePersonRepo = FakePersonRepository();
    final fakeTransaksiRepo = FakeTransaksiRepository();

    // Build our app under ProviderScope overriding all Hive data repository providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programRepositoryProvider.overrideWithValue(fakeProgramRepo),
          personRepositoryProvider.overrideWithValue(fakePersonRepo),
          transaksiRepositoryProvider.overrideWithValue(fakeTransaksiRepo),
        ],
        child: const MyApp(),
      ),
    );

    // Rebuild frames to let widgets settle
    await tester.pumpAndSettle();

    // Verify that our main layout renders the logo image and not the old layout titles
    expect(find.text('Financial Management'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    
    // Verify that the default active page is "Dashboard Keuangan"
    expect(find.text('Dashboard Keuangan'), findsOneWidget);

    // Reset test view configuration
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('App can navigate to Buat Invoice page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    final fakeProgramRepo = FakeProgramRepository();
    final fakePersonRepo = FakePersonRepository();
    final fakeTransaksiRepo = FakeTransaksiRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programRepositoryProvider.overrideWithValue(fakeProgramRepo),
          personRepositoryProvider.overrideWithValue(fakePersonRepo),
          transaksiRepositoryProvider.overrideWithValue(fakeTransaksiRepo),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the "Buat Invoice" menu item on the sidebar
    await tester.tap(find.text('Buat Invoice'));
    await tester.pumpAndSettle();

    // Verify that the title switches to "Buat Invoice Tagihan"
    expect(find.text('Buat Invoice Tagihan'), findsOneWidget);

    // Reset test view configuration
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
