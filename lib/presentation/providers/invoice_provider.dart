import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/program.dart';
import 'slip_gaji_provider.dart'; // Import to access transaksiListProvider

class InvoiceRowState {
  final String id;
  final Program? program;
  final String hariMengaji;
  final int kuantitas;
  final int harga;

  InvoiceRowState({
    required this.id,
    this.program,
    this.hariMengaji = '',
    this.kuantitas = 0,
    this.harga = 0,
  });

  InvoiceRowState copyWith({
    String? id,
    Program? program,
    String? hariMengaji,
    int? kuantitas,
    int? harga,
  }) {
    return InvoiceRowState(
      id: id ?? this.id,
      program: program ?? this.program,
      hariMengaji: hariMengaji ?? this.hariMengaji,
      kuantitas: kuantitas ?? this.kuantitas,
      harga: harga ?? this.harga,
    );
  }
}

const _invoiceSentinel = Object();

class InvoiceFormState {
  final dynamic transactionKey;
  final String? transactionId;
  final String tagihanUntuk;
  final String? namaAnak;
  final DateTime tanggalInvoice;
  final DateTime tanggalJatuhTempo;
  final List<InvoiceRowState> rows;

  InvoiceFormState({
    this.transactionKey,
    this.transactionId,
    this.tagihanUntuk = '',
    this.namaAnak,
    required this.tanggalInvoice,
    required this.tanggalJatuhTempo,
    this.rows = const [],
  });

  bool get isEditMode => transactionKey != null;

  int get totalTagihan => rows.fold(0, (sum, row) => sum + (row.kuantitas * row.harga));

  InvoiceFormState copyWith({
    Object? transactionKey = _invoiceSentinel,
    Object? transactionId = _invoiceSentinel,
    String? tagihanUntuk,
    Object? namaAnak = _invoiceSentinel,
    DateTime? tanggalInvoice,
    DateTime? tanggalJatuhTempo,
    List<InvoiceRowState>? rows,
  }) {
    return InvoiceFormState(
      transactionKey: identical(transactionKey, _invoiceSentinel) ? this.transactionKey : transactionKey,
      transactionId: identical(transactionId, _invoiceSentinel) ? this.transactionId : (transactionId as String?),
      tagihanUntuk: tagihanUntuk ?? this.tagihanUntuk,
      namaAnak: identical(namaAnak, _invoiceSentinel) ? this.namaAnak : (namaAnak as String?),
      tanggalInvoice: tanggalInvoice ?? this.tanggalInvoice,
      tanggalJatuhTempo: tanggalJatuhTempo ?? this.tanggalJatuhTempo,
      rows: rows ?? this.rows,
    );
  }
}

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  InvoiceFormNotifier()
      : super(InvoiceFormState(
          tanggalInvoice: DateTime.now(),
          tanggalJatuhTempo: DateTime.now(),
          rows: [
            InvoiceRowState(id: '1'),
          ],
        ));

  void setForm(InvoiceFormState formState) {
    state = formState;
  }

  void updateTagihanUntuk(String nama) {
    state = state.copyWith(tagihanUntuk: nama);
  }

  void updateNamaAnak(String? nama) {
    state = state.copyWith(namaAnak: nama);
  }

  void updateTanggalInvoice(DateTime date) {
    state = state.copyWith(
      tanggalInvoice: date,
      tanggalJatuhTempo: date, // Automatically sync due date to invoice date
    );
  }

  void updateTanggalJatuhTempo(DateTime date) {
    state = state.copyWith(tanggalJatuhTempo: date);
  }

  void addRow() {
    state = state.copyWith(rows: [
      ...state.rows,
      InvoiceRowState(id: DateTime.now().millisecondsSinceEpoch.toString())
    ]);
  }

  void removeRow(String id) {
    if (state.rows.length > 1) {
      state = state.copyWith(rows: state.rows.where((r) => r.id != id).toList());
    }
  }

  void updateRowProgram(String id, Program? program) {
    state = state.copyWith(
      rows: state.rows.map((r) {
        if (r.id == id) {
          return r.copyWith(
            program: program,
            harga: program?.defaultHargaKlien ?? 0,
          );
        }
        return r;
      }).toList(),
    );
  }

  void updateRowHari(String id, String hari) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.id == id ? r.copyWith(hariMengaji: hari) : r).toList(),
    );
  }

  void updateRowKuantitas(String id, int kuantitas) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.id == id ? r.copyWith(kuantitas: kuantitas) : r).toList(),
    );
  }

  void updateRowHarga(String id, int harga) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.id == id ? r.copyWith(harga: harga) : r).toList(),
    );
  }

  void resetForm() {
    state = InvoiceFormState(
      transactionKey: null,
      transactionId: null,
      namaAnak: null,
      tanggalInvoice: DateTime.now(),
      tanggalJatuhTempo: DateTime.now(),
      rows: [
        InvoiceRowState(id: DateTime.now().millisecondsSinceEpoch.toString()),
      ],
    );
  }
}

final invoiceFormProvider = StateNotifierProvider<InvoiceFormNotifier, InvoiceFormState>((ref) {
  return InvoiceFormNotifier();
});

// --- Reactive Invoice Number Generator Provider ---
final invoiceNumberProvider = Provider.family<String, DateTime>((ref, date) {
  final transactions = ref.watch(transaksiListProvider);
  final invoiceYear = date.year;
  
  // Count transactions of type 'Invoice' in that year
  final count = transactions.where((t) => t.jenis == 'Invoice' && t.tanggal.year == invoiceYear).length;
  
  final nextNumStr = (count + 1).toString().padLeft(4, '0');
  return 'INV/$invoiceYear/$nextNumStr';
});
