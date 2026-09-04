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
import 'package:edu_finance/presentation/providers/invoice_provider.dart';
import 'package:edu_finance/presentation/services/pdf_service.dart';

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
  final Map<dynamic, Transaksi> _box = {};

  @override
  List<Transaksi> getTransaksi() => _box.values.toList();

  @override
  Future<void> addTransaksi(Transaksi transaksi) async {
    _box[transaksi.id] = transaksi;
  }

  @override
  Future<void> updateTransaksi(dynamic key, Transaksi transaksi) async {
    _box[key] = transaksi;
  }

  @override
  Future<void> deleteTransaksi(dynamic keyOrId) async {
    if (_box.containsKey(keyOrId)) {
      _box.remove(keyOrId);
    } else {
      _box.removeWhere((k, v) => v.id == keyOrId.toString());
    }
  }
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

  test('TransaksiListNotifier - CREATE adds new item, EDIT updates existing key without duplication', () async {
    final fakeTransaksiRepo = FakeTransaksiRepository();
    final container = ProviderContainer(
      overrides: [
        transaksiRepositoryProvider.overrideWithValue(fakeTransaksiRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(transaksiListProvider.notifier);

    // 1. CREATE Transaction A
    final txA = Transaksi(
      id: 'tx_001',
      tanggal: DateTime(2026, 9, 4),
      jenis: 'Invoice',
      namaTarget: 'Orang Tua Budi',
      total: 500000,
    );

    await notifier.addTransaksi(txA);

    var list = container.read(transaksiListProvider);
    expect(list.length, equals(1));
    expect(list.first.id, equals('tx_001'));
    expect(list.first.total, equals(500000));
    expect(fakeTransaksiRepo.getTransaksi().length, equals(1));

    // 2. EDIT Transaction A using the existing key 'tx_001'
    final updatedTxA = Transaksi(
      id: 'tx_001',
      tanggal: DateTime(2026, 9, 4),
      jenis: 'Invoice',
      namaTarget: 'Orang Tua Budi (Updated)',
      total: 750000,
    );

    await notifier.updateTransaksi('tx_001', updatedTxA);

    list = container.read(transaksiListProvider);
    // Number of records MUST remain 1 (NO duplication)
    expect(list.length, equals(1));
    expect(list.first.id, equals('tx_001'));
    expect(list.first.namaTarget, equals('Orang Tua Budi (Updated)'));
    expect(list.first.total, equals(750000));
    expect(fakeTransaksiRepo.getTransaksi().length, equals(1));
  });

  testWidgets('Dashboard calculates and refreshes income, expense, and balance accurately', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    final fakeProgramRepo = FakeProgramRepository();
    final fakePersonRepo = FakePersonRepository();
    final fakeTransaksiRepo = FakeTransaksiRepository();

    // Initial transactions
    await fakeTransaksiRepo.addTransaksi(
      Transaksi(
        id: 'tx_inv_1',
        tanggal: DateTime(2026, 9, 1),
        jenis: 'Invoice',
        namaTarget: 'Bapak Ahmad',
        total: 1000000,
      ),
    );
    await fakeTransaksiRepo.addTransaksi(
      Transaksi(
        id: 'tx_sg_1',
        tanggal: DateTime(2026, 9, 2),
        jenis: 'Slip Gaji',
        namaTarget: 'Ustadz Ali',
        total: 400000,
      ),
    );

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

    // Verify initial values on Dashboard
    expect(find.text('Rp 1.000.000'), findsOneWidget); // Pemasukan
    expect(find.text('Rp 400.000'), findsOneWidget);   // Pengeluaran
    expect(find.text('Rp 600.000'), findsOneWidget);   // Sisa Saldo

    // Reset test view configuration
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  test('PdfService generates Invoice and Slip Gaji PDFs cleanly', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final invoiceState = InvoiceFormState(
      tagihanUntuk: 'Ibu Rahmawati',
      namaAnak: 'Zaidan',
      tanggalInvoice: DateTime(2026, 9, 4),
      tanggalJatuhTempo: DateTime(2026, 9, 10),
      rows: [
        InvoiceRowState(
          id: 'row_1',
          program: Program(id: 'prog_1', namaProgram: 'Tahsin Anak', defaultFeePengajar: 50000, defaultHargaKlien: 100000),
          hariMengaji: 'Senin & Kamis',
          kuantitas: 4,
          harga: 100000,
        ),
      ],
    );

    final invoicePdfBytes = await PdfService.generateInvoicePdf(invoiceState, 'INV/2026/0001');
    expect(invoicePdfBytes, isNotEmpty);

    final slipGajiState = SlipGajiFormState(
      namaPengajar: 'Ustadzah Fatimah',
      tanggalCetak: DateTime(2026, 9, 4),
      reimburse: 25000,
      subsidi: 50000,
      rows: [
        SlipGajiRowState(
          id: 'row_sg_1',
          namaAnak: 'Zaidan',
          program: Program(id: 'prog_1', namaProgram: 'Tahsin Anak', defaultFeePengajar: 50000, defaultHargaKlien: 100000),
          sesi: 4,
          fee: 50000,
        ),
      ],
    );

    final slipGajiPdfBytes = await PdfService.generateSlipGajiPdf(slipGajiState);
    expect(slipGajiPdfBytes, isNotEmpty);
  });
}
