import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/program.dart';
import '../../domain/entities/transaksi.dart';
import '../../domain/repositories/transaksi_repository.dart';
import '../../data/repositories/transaksi_repository_impl.dart';

// --- Transaksi Repositories & State Notifier Providers ---
final transaksiRepositoryProvider = Provider<TransaksiRepository>((ref) {
  return TransaksiRepositoryImpl(Hive.box<Transaksi>('transaksiBox'));
});

class TransaksiListNotifier extends StateNotifier<List<Transaksi>> {
  final TransaksiRepository _repository;

  TransaksiListNotifier(this._repository) : super([]) {
    loadTransactions();
  }

  void loadTransactions() {
    state = _repository.getTransaksi();
  }

  Future<void> addTransaksi(Transaksi transaksi) async {
    await _repository.addTransaksi(transaksi);
    loadTransactions();
  }

  Future<void> updateTransaksi(dynamic key, Transaksi transaksi) async {
    await _repository.updateTransaksi(key, transaksi);
    loadTransactions();
  }

  Future<void> deleteTransaksi(dynamic keyOrId) async {
    await _repository.deleteTransaksi(keyOrId);
    loadTransactions();
  }
}

final transaksiListProvider = StateNotifierProvider<TransaksiListNotifier, List<Transaksi>>((ref) {
  final repo = ref.watch(transaksiRepositoryProvider);
  return TransaksiListNotifier(repo);
});

// --- Slip Gaji Form State Models ---
class SlipGajiRowState {
  final String id;
  final String namaAnak;
  final Program? program;
  final int sesi;
  final int fee;

  SlipGajiRowState({
    required this.id,
    this.namaAnak = '',
    this.program,
    this.sesi = 0,
    this.fee = 0,
  });

  SlipGajiRowState copyWith({
    String? id,
    String? namaAnak,
    Program? program,
    int? sesi,
    int? fee,
  }) {
    return SlipGajiRowState(
      id: id ?? this.id,
      namaAnak: namaAnak ?? this.namaAnak,
      program: program ?? this.program,
      sesi: sesi ?? this.sesi,
      fee: fee ?? this.fee,
    );
  }
}

const _slipGajiSentinel = Object();

class SlipGajiFormState {
  final dynamic transactionKey;
  final String? transactionId;
  final String namaPengajar;
  final DateTime tanggalCetak;
  final List<SlipGajiRowState> rows;
  final int reimburse;
  final int subsidi;

  SlipGajiFormState({
    this.transactionKey,
    this.transactionId,
    this.namaPengajar = '',
    required this.tanggalCetak,
    this.rows = const [],
    this.reimburse = 0,
    this.subsidi = 0,
  });

  bool get isEditMode => transactionKey != null;

  int get subtotal => rows.fold(0, (sum, row) => sum + (row.sesi * row.fee));
  int get totalPendapatan => subtotal + subsidi - reimburse;

  SlipGajiFormState copyWith({
    Object? transactionKey = _slipGajiSentinel,
    Object? transactionId = _slipGajiSentinel,
    String? namaPengajar,
    DateTime? tanggalCetak,
    List<SlipGajiRowState>? rows,
    int? reimburse,
    int? subsidi,
  }) {
    return SlipGajiFormState(
      transactionKey: identical(transactionKey, _slipGajiSentinel) ? this.transactionKey : transactionKey,
      transactionId: identical(transactionId, _slipGajiSentinel) ? this.transactionId : (transactionId as String?),
      namaPengajar: namaPengajar ?? this.namaPengajar,
      tanggalCetak: tanggalCetak ?? this.tanggalCetak,
      rows: rows ?? this.rows,
      reimburse: reimburse ?? this.reimburse,
      subsidi: subsidi ?? this.subsidi,
    );
  }
}

// --- Slip Gaji Form Notifier ---
class SlipGajiFormNotifier extends StateNotifier<SlipGajiFormState> {
  SlipGajiFormNotifier()
      : super(SlipGajiFormState(
          tanggalCetak: DateTime.now(),
          rows: [
            SlipGajiRowState(
              id: '1',
            ),
          ],
        ));

  void setForm(SlipGajiFormState formState) {
    state = formState;
  }

  void updateNamaPengajar(String nama) {
    state = state.copyWith(namaPengajar: nama);
  }

  void updateTanggalCetak(DateTime date) {
    state = state.copyWith(tanggalCetak: date);
  }

  void addRow() {
    state = state.copyWith(rows: [
      ...state.rows,
      SlipGajiRowState(id: DateTime.now().millisecondsSinceEpoch.toString())
    ]);
  }

  void removeRow(String id) {
    if (state.rows.length > 1) {
      state = state.copyWith(rows: state.rows.where((r) => r.id != id).toList());
    }
  }

  void updateRowAnak(String id, String namaAnak) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.id == id ? r.copyWith(namaAnak: namaAnak) : r).toList(),
    );
  }

  void updateRowProgram(String id, Program? program) {
    state = state.copyWith(
      rows: state.rows.map((r) {
        if (r.id == id) {
          return r.copyWith(
            program: program,
            fee: program?.defaultFeePengajar ?? 0,
          );
        }
        return r;
      }).toList(),
    );
  }

  void updateRowSesi(String id, int sesi) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.id == id ? r.copyWith(sesi: sesi) : r).toList(),
    );
  }

  void updateRowFee(String id, int fee) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.id == id ? r.copyWith(fee: fee) : r).toList(),
    );
  }

  void updateReimburse(int value) {
    state = state.copyWith(reimburse: value);
  }

  void updateSubsidi(int value) {
    state = state.copyWith(subsidi: value);
  }

  void resetForm() {
    state = SlipGajiFormState(
      transactionKey: null,
      transactionId: null,
      tanggalCetak: DateTime.now(),
      rows: [
        SlipGajiRowState(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        )
      ],
    );
  }
}

final slipGajiFormProvider = StateNotifierProvider<SlipGajiFormNotifier, SlipGajiFormState>((ref) {
  return SlipGajiFormNotifier();
});
