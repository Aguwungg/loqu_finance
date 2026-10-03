import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/program.dart';
import '../../domain/entities/transaksi.dart';
import '../providers/master_data_providers.dart';
import '../providers/slip_gaji_provider.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'dart:convert';

class SlipGajiPage extends ConsumerStatefulWidget {
  const SlipGajiPage({super.key});

  @override
  ConsumerState<SlipGajiPage> createState() => _SlipGajiPageState();
}

class _SlipGajiPageState extends ConsumerState<SlipGajiPage> {
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers (Non-tabular)
  late TextEditingController _pengajarController;
  late TextEditingController _tanggalController;
  late TextEditingController _reimburseController;
  late TextEditingController _subsidiController;
  late TextEditingController _potonganController;
  late TextEditingController _catatanReimburseController;
  late TextEditingController _catatanSubsidiController;
  late TextEditingController _catatanPotonganController;

  @override
  void initState() {
    super.initState();
    // Initialize form values
    final formState = ref.read(slipGajiFormProvider);
    _pengajarController = TextEditingController(text: formState.namaPengajar);
    _tanggalController = TextEditingController(text: _formatDate(formState.tanggalCetak));
    _reimburseController = TextEditingController(text: formState.reimburse == 0 ? '' : formState.reimburse.toString());
    _subsidiController = TextEditingController(text: formState.subsidi == 0 ? '' : formState.subsidi.toString());
    _potonganController = TextEditingController(text: formState.potongan == 0 ? '' : formState.potongan.toString());
    _catatanReimburseController = TextEditingController(text: formState.catatanReimburse);
    _catatanSubsidiController = TextEditingController(text: formState.catatanSubsidi);
    _catatanPotonganController = TextEditingController(text: formState.catatanPotongan);
  }

  @override
  void dispose() {
    _pengajarController.dispose();
    _tanggalController.dispose();
    _reimburseController.dispose();
    _subsidiController.dispose();
    _potonganController.dispose();
    _catatanReimburseController.dispose();
    _catatanSubsidiController.dispose();
    _catatanPotonganController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _getActiveMonth() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return 'Bulan Aktif: ${months[now.month - 1]} ${now.year}';
  }

  // Formatting utility: e.g. 150000 -> 150.000
  String _formatCurrency(int value) {
    final buffer = StringBuffer();
    final str = value.toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  Future<void> _selectDate(BuildContext context) async {
    final formState = ref.read(slipGajiFormProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: formState.tanggalCetak,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.colors.primary,
              onPrimary: Colors.white,
              onSurface: context.colors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(slipGajiFormProvider.notifier).updateTanggalCetak(picked);
      _tanggalController.text = _formatDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(slipGajiFormProvider);
    final allPeople = ref.watch(personListProvider);
    final allPrograms = ref.watch(programListProvider);

    final pengajars = allPeople.where((p) => p.kategori == 'Pengajar').toList();
    final murids = allPeople.where((p) => p.kategori == 'Murid').toList();

    // Listen to formState to sync controllers when loaded for edit
    ref.listen<SlipGajiFormState>(slipGajiFormProvider, (previous, next) {
      if (next.namaPengajar != _pengajarController.text) {
        _pengajarController.text = next.namaPengajar;
      }
      final nextDateText = _formatDate(next.tanggalCetak);
      if (nextDateText != _tanggalController.text) {
        _tanggalController.text = nextDateText;
      }
      final nextReimburseText = next.reimburse == 0 ? '' : next.reimburse.toString();
      if (nextReimburseText != _reimburseController.text) {
        _reimburseController.text = nextReimburseText;
      }
      final nextSubsidiText = next.subsidi == 0 ? '' : next.subsidi.toString();
      if (nextSubsidiText != _subsidiController.text) {
        _subsidiController.text = nextSubsidiText;
      }
      final nextPotonganText = next.potongan == 0 ? '' : next.potongan.toString();
      if (nextPotonganText != _potonganController.text) {
        _potonganController.text = nextPotonganText;
      }
      if (next.catatanReimburse != _catatanReimburseController.text) {
        _catatanReimburseController.text = next.catatanReimburse;
      }
      if (next.catatanSubsidi != _catatanSubsidiController.text) {
        _catatanSubsidiController.text = next.catatanSubsidi;
      }
      if (next.catatanPotongan != _catatanPotonganController.text) {
        _catatanPotonganController.text = next.catatanPotongan;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title & Active Month Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formState.isEditMode ? 'Edit Slip Gaji Pengajar' : 'Buat Slip Gaji Pengajar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.colors.text,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Formulir untuk menghasilkan slip gaji pengajar berdasarkan sesi mengajar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active Month Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: context.colors.text),
                      SizedBox(width: 8),
                      Text(
                        _getActiveMonth(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Top Inputs (Pengajar, Tanggal Cetak)
            Row(
              children: [
                // Autocomplete Nama Pengajar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAMA PENGAJAR',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.text),
                      ),
                      SizedBox(height: 8),
                      Autocomplete<Person>(
                        initialValue: TextEditingValue(text: formState.namaPengajar),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Person>.empty();
                          }
                          return pengajars.where((Person option) {
                            return option.nama.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (Person option) => option.nama,
                        onSelected: (Person selection) {
                          ref.read(slipGajiFormProvider.notifier).updateNamaPengajar(selection.nama);
                          _pengajarController.text = selection.nama;

                          // Auto-fill dari riwayat bulan lalu
                          final transactions = ref.read(transaksiListProvider);
                          final riwayat = transactions.where((t) => 
                            t.jenis == 'Slip Gaji' && 
                            t.namaTarget == selection.nama && 
                            t.rowsData != null && 
                            t.rowsData!.isNotEmpty
                          ).toList();

                          if (riwayat.isNotEmpty) {
                            riwayat.sort((a, b) => b.tanggal.compareTo(a.tanggal));
                            final latest = riwayat.first;
                            ref.read(slipGajiFormProvider.notifier).loadFromPrevious(latest.rowsData!, allPrograms);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Berhasil menyalin riwayat mengajar dari slip gaji sebelumnya (${_formatDate(latest.tanggal)}).'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Sync initial/state value
                          if (controller.text != formState.namaPengajar && formState.namaPengajar.isNotEmpty) {
                            controller.text = formState.namaPengajar;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) {
                              ref.read(slipGajiFormProvider.notifier).updateNamaPengajar(val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nama pengajar...',
                              hintStyle: TextStyle(fontSize: 14, color: context.colors.textLight),
                              prefixIcon: Icon(Icons.search, size: 20, color: context.colors.textLight),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: context.colors.accent, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: context.colors.border),
                              ),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Nama pengajar wajib diisi' : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                // Tanggal Cetak Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TANGGAL CETAK',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.text),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          hintText: 'mm/dd/yyyy',
                          suffixIcon: Icon(Icons.calendar_today, size: 18, color: context.colors.textLight),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: context.colors.accent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.colors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Teaching Input Section Header
            Text(
              'Input Mengajar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.text),
            ),
            SizedBox(height: 12),

            // Dynamic Table Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Table Header Column Labels
                    Container(
                      color: context.colors.tableHeader,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text('NAMA ANAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 3, child: Text('PROGRAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('JUMLAH (SESI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('FEE (RP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('TOTAL (RP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.text))),
                          SizedBox(width: 60, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.text), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: context.colors.border),
                    // Table Body List Rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: formState.rows.length,
                        itemBuilder: (context, index) {
                          final row = formState.rows[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: context.colors.border, width: 0.5)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: TableRowWidget(
                              row: row,
                              murids: murids,
                              programs: allPrograms,
                              onAnakChanged: (namaAnak) {
                                ref.read(slipGajiFormProvider.notifier).updateRowAnak(row.id, namaAnak);
                              },
                              onProgramChanged: (program) {
                                ref.read(slipGajiFormProvider.notifier).updateRowProgram(row.id, program);
                              },
                              onSesiChanged: (sesi) {
                                ref.read(slipGajiFormProvider.notifier).updateRowSesi(row.id, sesi);
                              },
                              onFeeChanged: (fee) {
                                ref.read(slipGajiFormProvider.notifier).updateRowFee(row.id, fee);
                              },
                              onDelete: () {
                                ref.read(slipGajiFormProvider.notifier).removeRow(row.id);
                              },
                              showDelete: formState.rows.length > 1,
                            ),
                          );
                        },
                      ),
                    ),
                    // Add Row Action Button Area
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: BorderSide(color: context.colors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            ref.read(slipGajiFormProvider.notifier).addRow();
                          },
                          icon: Icon(Icons.add, size: 16),
                          label: Text('TAMBAH BARIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Bottom calculations section (Reimburse, Subsidi, and Grand Total)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Reimburse & Subsidi inputs
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Reimburse input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reimburse (Rp)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.text),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _reimburseController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.receipt_long_outlined, size: 18, color: context.colors.textLight),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: context.colors.accent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.colors.border),
                                ),
                              ),
                              onChanged: (val) {
                                ref.read(slipGajiFormProvider.notifier).updateReimburse(int.tryParse(val) ?? 0);
                              },
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _catatanReimburseController,
                              decoration: InputDecoration(
                                hintText: 'Catatan reimburse...',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: context.colors.accent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.colors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: TextStyle(fontSize: 12),
                              onChanged: (val) {
                                ref.read(slipGajiFormProvider.notifier).updateCatatanReimburse(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Subsidi input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subsidi (Rp)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.text),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _subsidiController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.monetization_on_outlined, size: 18, color: context.colors.textLight),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: context.colors.accent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.colors.border),
                                ),
                              ),
                              onChanged: (val) {
                                ref.read(slipGajiFormProvider.notifier).updateSubsidi(int.tryParse(val) ?? 0);
                              },
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _catatanSubsidiController,
                              decoration: InputDecoration(
                                hintText: 'Catatan subsidi...',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: context.colors.accent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.colors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: TextStyle(fontSize: 12),
                              onChanged: (val) {
                                ref.read(slipGajiFormProvider.notifier).updateCatatanSubsidi(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Potongan input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Potongan (Rp)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.text),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _potonganController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.money_off_outlined, size: 18, color: context.colors.textLight),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: context.colors.accent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.colors.border),
                                ),
                              ),
                              onChanged: (val) {
                                ref.read(slipGajiFormProvider.notifier).updatePotongan(int.tryParse(val) ?? 0);
                              },
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _catatanPotonganController,
                              decoration: InputDecoration(
                                hintText: 'Catatan potongan...',
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: context.colors.accent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.colors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: TextStyle(fontSize: 12),
                              onChanged: (val) {
                                ref.read(slipGajiFormProvider.notifier).updateCatatanPotongan(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 48),
                // Total panel & Save print action button
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Total Panel Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pendapatan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textLight),
                            ),
                            Text(
                              'Rp ${_formatCurrency(formState.totalPendapatan)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: context.colors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Save and layout PDF print button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.action,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => _simpanDanCetakPDF(context),
                          icon: Icon(Icons.print, size: 18),
                          label: Text(
                            formState.isEditMode ? 'UPDATE & CETAK PDF' : 'SIMPAN & CETAK PDF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Note:\n- Subsidi: Tambahan penghasilan/bonus\n- Reimburse: Penggantian uang\n- Potongan: Pengurangan dana',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanDanCetakPDF(BuildContext context) async {
    final formState = ref.read(slipGajiFormProvider);

    if (_formKey.currentState!.validate()) {
      // Validate rows
      bool rowsValid = true;
      for (final r in formState.rows) {
        if (r.namaAnak.trim().isEmpty || r.program == null || r.sesi <= 0 || r.fee <= 0) {
          rowsValid = false;
          break;
        }
      }

      final messenger = ScaffoldMessenger.of(context);

      if (!rowsValid) {
        messenger.showSnackBar(
          SnackBar(content: Text('Mohon lengkapi seluruh baris input mengajar (nama anak, program, sesi > 0, fee > 0).')),
        );
        return;
      }

      try {
        // Generate PDF doc
        final pdfBytes = await PdfService.generateSlipGajiPdf(formState);

        final isEdit = formState.isEditMode;
        final txId = formState.transactionId ?? (isEdit ? formState.transactionKey.toString() : DateTime.now().millisecondsSinceEpoch.toString());

        // Generate JSON for rows
        final rowsJsonData = jsonEncode(formState.rows.map((r) => r.toJson()).toList());

        // Save or update Transaction record in Hive
        final transaksiData = Transaksi(
          id: txId,
          tanggal: formState.tanggalCetak,
          jenis: 'Slip Gaji',
          namaTarget: formState.namaPengajar,
          total: formState.totalPendapatan,
          rowsData: rowsJsonData,
          catatanSubsidi: formState.catatanSubsidi,
          catatanReimburse: formState.catatanReimburse,
          catatanPotongan: formState.catatanPotongan,
        );

        if (isEdit) {
          await ref.read(transaksiListProvider.notifier).updateTransaksi(formState.transactionKey, transaksiData);
        } else {
          await ref.read(transaksiListProvider.notifier).addTransaksi(transaksiData);
        }

        ref.invalidate(transaksiListProvider);

        if (!context.mounted) return;
        final fileName = 'SlipGaji_${formState.namaPengajar.replaceAll(' ', '_')}_${_formatDate(formState.tanggalCetak).replaceAll('/', '-')}.pdf';
        
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        
        messenger.showSnackBar(
          SnackBar(content: Text(isEdit ? 'Slip gaji berhasil diperbarui dan diunduh!' : 'Transaksi berhasil disimpan dan PDF diunduh!')),
        );

        // Reset form fields
        ref.read(slipGajiFormProvider.notifier).resetForm();
        _pengajarController.clear();
        _reimburseController.clear();
        _subsidiController.clear();
        _potonganController.clear();
        _tanggalController.text = _formatDate(DateTime.now());
      } catch (e, stackTrace) {
        debugPrint('Error saving/printing slip gaji: $e\n$stackTrace');
        messenger.showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }
}

// --- STATEFUL ROW COMPONENT TO AVOID KEYBOARD INPUT LAG ---
class TableRowWidget extends StatefulWidget {
  final SlipGajiRowState row;
  final List<Person> murids;
  final List<Program> programs;
  final ValueChanged<String> onAnakChanged;
  final ValueChanged<Program?> onProgramChanged;
  final ValueChanged<int> onSesiChanged;
  final ValueChanged<int> onFeeChanged;
  final VoidCallback onDelete;
  final bool showDelete;

  const TableRowWidget({
    super.key,
    required this.row,
    required this.murids,
    required this.programs,
    required this.onAnakChanged,
    required this.onProgramChanged,
    required this.onSesiChanged,
    required this.onFeeChanged,
    required this.onDelete,
    required this.showDelete,
  });

  @override
  State<TableRowWidget> createState() => _TableRowWidgetState();
}

class _TableRowWidgetState extends State<TableRowWidget> {
  late TextEditingController _anakController;
  late TextEditingController _sesiController;
  late TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _anakController = TextEditingController(text: widget.row.namaAnak);
    _sesiController = TextEditingController(text: widget.row.sesi == 0 ? '' : widget.row.sesi.toString());
    _feeController = TextEditingController(text: widget.row.fee == 0 ? '' : widget.row.fee.toString());
  }

  @override
  void didUpdateWidget(covariant TableRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync UI text fields with updated state
    if (widget.row.namaAnak != _anakController.text) {
      _anakController.text = widget.row.namaAnak;
    }
    final targetSesiText = widget.row.sesi == 0 ? '' : widget.row.sesi.toString();
    if (targetSesiText != _sesiController.text) {
      _sesiController.text = targetSesiText;
    }
    final targetFeeText = widget.row.fee == 0 ? '' : widget.row.fee.toString();
    if (targetFeeText != _feeController.text) {
      _feeController.text = targetFeeText;
    }
  }

  @override
  void dispose() {
    _anakController.dispose();
    _sesiController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  String _formatCurrency(int value) {
    final buffer = StringBuffer();
    final str = value.toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    final rowTotal = widget.row.sesi * widget.row.fee;

    return Row(
      children: [
        // Column 1: Autocomplete Nama Anak
        Expanded(
          flex: 3,
          child: Autocomplete<Person>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Person>.empty();
              }
              return widget.murids.where((Person option) {
                return option.nama.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            displayStringForOption: (Person option) => option.nama,
            onSelected: (Person selection) {
              widget.onAnakChanged(selection.nama);
              _anakController.text = selection.nama;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text != widget.row.namaAnak) {
                controller.text = widget.row.namaAnak;
              }
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onChanged: widget.onAnakChanged,
                decoration: InputDecoration(
                  hintText: 'Nama anak...',
                  hintStyle: TextStyle(fontSize: 13, color: context.colors.textLight),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.colors.accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 16),
        // Column 2: Dropdown Program
        Expanded(
          flex: 3,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Program>(
                hint: Text('Pilih program...', style: TextStyle(fontSize: 13, color: context.colors.textLight)),
                value: widget.row.program,
                isExpanded: true,
                style: TextStyle(color: context.colors.text, fontSize: 14),
                items: widget.programs.map((prog) {
                  return DropdownMenuItem<Program>(
                    value: prog,
                    child: Text(prog.namaProgram),
                  );
                }).toList(),
                onChanged: widget.onProgramChanged,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        // Column 3: Sesi Count TextField
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _sesiController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: context.colors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              widget.onSesiChanged(int.tryParse(val) ?? 0);
            },
          ),
        ),
        SizedBox(width: 16),
        // Column 4: Fee TextField (Editable default program fee)
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _feeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: context.colors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              widget.onFeeChanged(int.tryParse(val) ?? 0);
            },
          ),
        ),
        SizedBox(width: 16),
        // Column 5: Total Sesi Price Text
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Rp ${_formatCurrency(rowTotal)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.colors.text),
            ),
          ),
        ),
        SizedBox(width: 16),
        // Delete button
        SizedBox(
          width: 44,
          child: widget.showDelete
              ? IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                )
              : SizedBox(),
        ),
      ],
    );
  }
}
