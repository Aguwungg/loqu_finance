import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/program.dart';
import '../../domain/entities/transaksi.dart';
import '../providers/master_data_providers.dart';
import '../providers/invoice_provider.dart';
import '../providers/slip_gaji_provider.dart';
import '../services/pdf_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class InvoicePage extends ConsumerStatefulWidget {
  const InvoicePage({super.key});

  @override
  ConsumerState<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends ConsumerState<InvoicePage> {
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers (Non-tabular)
  late TextEditingController _tagihanUntukController;
  late TextEditingController _tanggalController;
  late TextEditingController _jatuhTempoController;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(invoiceFormProvider);
    _tagihanUntukController = TextEditingController(text: formState.tagihanUntuk);
    _tanggalController = TextEditingController(text: _formatDate(formState.tanggalInvoice));
    _jatuhTempoController = TextEditingController(text: _formatDate(formState.tanggalJatuhTempo));
  }

  @override
  void dispose() {
    _tagihanUntukController.dispose();
    _tanggalController.dispose();
    _jatuhTempoController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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

  Future<void> _selectInvoiceDate(BuildContext context) async {
    final formState = ref.read(invoiceFormProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: formState.tanggalInvoice,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(invoiceFormProvider.notifier).updateTanggalInvoice(picked);
      _tanggalController.text = _formatDate(picked);
      // Auto-sync due date text
      _jatuhTempoController.text = _formatDate(picked);
    }
  }

  Future<void> _selectJatuhTempoDate(BuildContext context) async {
    final formState = ref.read(invoiceFormProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: formState.tanggalJatuhTempo,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(invoiceFormProvider.notifier).updateTanggalJatuhTempo(picked);
      _jatuhTempoController.text = _formatDate(picked);
    }
  }

  // Program Creator Dialog popup "+ Tambah Item Baru"
  Future<Program?> _showQuickProgramDialog() async {
    final nameController = TextEditingController();
    final hargaController = TextEditingController();
    final feeController = TextEditingController(text: '0'); // default fee
    final quickFormKey = GlobalKey<FormState>();

    return showDialog<Program>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Program Baru', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
          content: Form(
            key: quickFormKey,
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Program',
                      hintText: 'Misal: Reguler Online',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nama program wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: hargaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Standar Harga Klien (Rp)',
                      hintText: 'Misal: 120000',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harga wajib diisi';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Nominal angka harus valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Standar Fee Pengajar (Rp)',
                      hintText: 'Default: 0',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Nominal angka harus valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (quickFormKey.currentState!.validate()) {
                  final newProgram = Program(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    namaProgram: nameController.text.trim(),
                    defaultHargaKlien: int.parse(hargaController.text.trim()),
                    defaultFeePengajar: int.parse(feeController.text.trim()),
                  );

                  final navigator = Navigator.of(context);
                  
                  // Save directly to Hive
                  await ref.read(programListProvider.notifier).addProgram(newProgram);

                  navigator.pop(newProgram);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(invoiceFormProvider);
    final allPeople = ref.watch(personListProvider);
    final allPrograms = ref.watch(programListProvider);

    final parents = allPeople.where((p) => p.kategori == 'Orang Tua').toList();

    // Listen to formState to sync controllers when loaded for edit
    ref.listen<InvoiceFormState>(invoiceFormProvider, (previous, next) {
      if (next.tagihanUntuk != _tagihanUntukController.text) {
        _tagihanUntukController.text = next.tagihanUntuk;
      }
      final nextDateText = _formatDate(next.tanggalInvoice);
      if (nextDateText != _tanggalController.text) {
        _tanggalController.text = nextDateText;
      }
      final nextDueDateText = _formatDate(next.tanggalJatuhTempo);
      if (nextDueDateText != _jatuhTempoController.text) {
        _jatuhTempoController.text = nextDueDateText;
      }
    });

    // Watch generated invoice number reactively
    final invoiceNo = ref.watch(invoiceNumberProvider(formState.tanggalInvoice));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title & Auto-generated Invoice Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formState.isEditMode ? 'Edit Invoice Tagihan' : 'Buat Invoice Tagihan',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nomor Invoice: $invoiceNo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Top Inputs (Tagihan Untuk, Tanggal Invoice, Tanggal Jatuh Tempo)
            Row(
              children: [
                // Autocomplete Nama Klien / Orang Tua
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TAGIHAN UNTUK (NAMA ORANG TUA)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<Person>(
                        initialValue: TextEditingValue(text: formState.tagihanUntuk),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Person>.empty();
                          }
                          return parents.where((Person option) {
                            return option.nama.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (Person option) => option.nama,
                        onSelected: (Person selection) {
                          final children = allPeople.where((p) => p.kategori == 'Murid' && p.parentId == selection.id).toList();
                          final childName = children.isNotEmpty ? children.map((c) => c.nama).join(', ') : null;
                          ref.read(invoiceFormProvider.notifier).updateTagihanUntuk(selection.nama);
                          ref.read(invoiceFormProvider.notifier).updateNamaAnak(childName);
                          _tagihanUntukController.text = selection.nama;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text != formState.tagihanUntuk && formState.tagihanUntuk.isNotEmpty) {
                            controller.text = formState.tagihanUntuk;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) {
                              ref.read(invoiceFormProvider.notifier).updateTagihanUntuk(val);
                              final matchedParent = parents.cast<Person?>().firstWhere(
                                (p) => p?.nama.toLowerCase() == val.trim().toLowerCase(),
                                orElse: () => null,
                              );
                              if (matchedParent != null) {
                                final children = allPeople.where((p) => p.kategori == 'Murid' && p.parentId == matchedParent.id).toList();
                                ref.read(invoiceFormProvider.notifier).updateNamaAnak(
                                  children.isNotEmpty ? children.map((c) => c.nama).join(', ') : null,
                                );
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nama orang tua...',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textLight),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: AppColors.accent, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Nama tagihan wajib diisi' : null,
                          );
                        },
                      ),
                      if (formState.namaAnak != null && formState.namaAnak!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Murid: ${formState.namaAnak}',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Tanggal Invoice Picker
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TANGGAL INVOICE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: () => _selectInvoiceDate(context),
                        decoration: InputDecoration(
                          hintText: 'mm/dd/yyyy',
                          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.accent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Tanggal Jatuh Tempo Picker
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TANGGAL JATUH TEMPO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _jatuhTempoController,
                        readOnly: true,
                        onTap: () => _selectJatuhTempoDate(context),
                        decoration: InputDecoration(
                          hintText: 'mm/dd/yyyy',
                          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.accent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Dynamic Table Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Table Header Column Labels
                    Container(
                      color: AppColors.tableHeader,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('ITEM PROGRAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('HARI MENGAJI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('KUANTITAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('HARGA (RP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text))),
                          SizedBox(width: 16),
                          Expanded(flex: 2, child: Text('JUMLAH (RP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text))),
                          SizedBox(width: 60, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    // Table Body List Rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: formState.rows.length,
                        itemBuilder: (context, index) {
                          final row = formState.rows[index];
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: InvoiceTableRowWidget(
                              row: row,
                              programs: allPrograms,
                              onProgramChanged: (program) {
                                ref.read(invoiceFormProvider.notifier).updateRowProgram(row.id, program);
                              },
                              onQuickProgramTrigger: () async {
                                final newlyCreated = await _showQuickProgramDialog();
                                if (newlyCreated != null) {
                                  ref.read(invoiceFormProvider.notifier).updateRowProgram(row.id, newlyCreated);
                                }
                              },
                              onHariChanged: (hari) {
                                ref.read(invoiceFormProvider.notifier).updateRowHari(row.id, hari);
                              },
                              onKuantitasChanged: (qty) {
                                ref.read(invoiceFormProvider.notifier).updateRowKuantitas(row.id, qty);
                              },
                              onHargaChanged: (price) {
                                ref.read(invoiceFormProvider.notifier).updateRowHarga(row.id, price);
                              },
                              onDelete: () {
                                ref.read(invoiceFormProvider.notifier).removeRow(row.id);
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
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            ref.read(invoiceFormProvider.notifier).addRow();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('TAMBAH ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bottom calculations section (Total Tagihan and Save/Print Action)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Tagihan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            Text(
                              'Rp ${_formatCurrency(formState.totalTagihan)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Save and layout PDF print button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.action,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => _simpanDanCetakInvoice(context),
                          icon: const Icon(Icons.print, size: 18),
                          label: Text(
                            formState.isEditMode ? 'UPDATE & CETAK INVOICE' : 'SIMPAN & CETAK INVOICE',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanDanCetakInvoice(BuildContext context) async {
    final formState = ref.read(invoiceFormProvider);
    final invoiceNo = ref.read(invoiceNumberProvider(formState.tanggalInvoice));

    if (_formKey.currentState!.validate()) {
      // Validate rows
      bool rowsValid = true;
      for (final r in formState.rows) {
        if (r.program == null || r.hariMengaji.trim().isEmpty || r.kuantitas <= 0 || r.harga <= 0) {
          rowsValid = false;
          break;
        }
      }

      final messenger = ScaffoldMessenger.of(context);

      if (!rowsValid) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Mohon lengkapi seluruh baris item tagihan (program, hari mengaji, kuantitas > 0, harga > 0).')),
        );
        return;
      }

      try {
        // Generate PDF doc
        final pdfBytes = await PdfService.generateInvoicePdf(formState, invoiceNo);

        final isEdit = formState.isEditMode;
        final txId = formState.transactionId ?? (isEdit ? formState.transactionKey.toString() : DateTime.now().millisecondsSinceEpoch.toString());

        // Save or update Transaction record in Hive
        final transaksiData = Transaksi(
          id: txId,
          tanggal: formState.tanggalInvoice,
          jenis: 'Invoice',
          namaTarget: formState.tagihanUntuk,
          total: formState.totalTagihan,
        );

        if (isEdit) {
          await ref.read(transaksiListProvider.notifier).updateTransaksi(formState.transactionKey, transaksiData);
        } else {
          await ref.read(transaksiListProvider.notifier).addTransaksi(transaksiData);
        }

        ref.invalidate(transaksiListProvider);

        // Save PDF locally and open it
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${invoiceNo.replaceAll('/', '_')}_${formState.tagihanUntuk.replaceAll(' ', '_')}.pdf';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        // Open PDF automatically
        await OpenFilex.open(filePath);

        messenger.showSnackBar(
          SnackBar(content: Text(isEdit ? 'Invoice berhasil diperbarui!' : 'PDF berhasil disimpan di: $filePath')),
        );

        // Reset form fields
        ref.read(invoiceFormProvider.notifier).resetForm();
        _tagihanUntukController.clear();
        _tanggalController.text = _formatDate(DateTime.now());
        _jatuhTempoController.text = _formatDate(DateTime.now());
      } catch (e, stackTrace) {
        debugPrint('Error saving/printing invoice: $e\n$stackTrace');
        messenger.showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }
}

// --- STATEFUL ROW COMPONENT FOR INVOICE TABLE ---
class InvoiceTableRowWidget extends StatefulWidget {
  final InvoiceRowState row;
  final List<Program> programs;
  final ValueChanged<Program?> onProgramChanged;
  final VoidCallback onQuickProgramTrigger;
  final ValueChanged<String> onHariChanged;
  final ValueChanged<int> onKuantitasChanged;
  final ValueChanged<int> onHargaChanged;
  final VoidCallback onDelete;
  final bool showDelete;

  const InvoiceTableRowWidget({
    super.key,
    required this.row,
    required this.programs,
    required this.onProgramChanged,
    required this.onQuickProgramTrigger,
    required this.onHariChanged,
    required this.onKuantitasChanged,
    required this.onHargaChanged,
    required this.onDelete,
    required this.showDelete,
  });

  @override
  State<InvoiceTableRowWidget> createState() => _InvoiceTableRowWidgetState();
}

class _InvoiceTableRowWidgetState extends State<InvoiceTableRowWidget> {
  late TextEditingController _hariController;
  late TextEditingController _qtyController;
  late TextEditingController _hargaController;

  // Add new sentinel Program instance
  final _addNewSentinel = Program(
    id: 'ADD_NEW_PROGRAM_SENTINEL',
    namaProgram: '+ Tambah Item Baru',
    defaultFeePengajar: 0,
    defaultHargaKlien: 0,
  );

  @override
  void initState() {
    super.initState();
    _hariController = TextEditingController(text: widget.row.hariMengaji);
    _qtyController = TextEditingController(text: widget.row.kuantitas == 0 ? '' : widget.row.kuantitas.toString());
    _hargaController = TextEditingController(text: widget.row.harga == 0 ? '' : widget.row.harga.toString());
  }

  @override
  void didUpdateWidget(covariant InvoiceTableRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.row.hariMengaji != _hariController.text) {
      _hariController.text = widget.row.hariMengaji;
    }
    final targetQtyText = widget.row.kuantitas == 0 ? '' : widget.row.kuantitas.toString();
    if (targetQtyText != _qtyController.text) {
      _qtyController.text = targetQtyText;
    }
    final targetHargaText = widget.row.harga == 0 ? '' : widget.row.harga.toString();
    if (targetHargaText != _hargaController.text) {
      _hargaController.text = targetHargaText;
    }
  }

  @override
  void dispose() {
    _hariController.dispose();
    _qtyController.dispose();
    _hargaController.dispose();
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
    final rowTotal = widget.row.kuantitas * widget.row.harga;

    // Build the dropdown options list incorporating the new item sentinel
    final dropdownItems = widget.programs.map((prog) {
      return DropdownMenuItem<Program>(
        value: prog,
        child: Text(prog.namaProgram),
      );
    }).toList();

    dropdownItems.add(
      DropdownMenuItem<Program>(
        value: _addNewSentinel,
        child: Text(
          '+ Tambah Item Baru',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return Row(
      children: [
        // Column 1: Dropdown Item Program
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
                hint: const Text('Pilih program...', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                value: widget.row.program,
                isExpanded: true,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                items: dropdownItems,
                onChanged: (selection) {
                  if (selection == _addNewSentinel) {
                    widget.onQuickProgramTrigger();
                  } else {
                    widget.onProgramChanged(selection);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Column 2: Hari Mengaji input
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _hariController,
            decoration: InputDecoration(
              hintText: 'Misal: Selasa',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: widget.onHariChanged,
          ),
        ),
        const SizedBox(width: 16),
        // Column 3: Kuantitas Sesi input
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              widget.onKuantitasChanged(int.tryParse(val) ?? 0);
            },
          ),
        ),
        const SizedBox(width: 16),
        // Column 4: Harga input (Editable default)
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _hargaController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              widget.onHargaChanged(int.tryParse(val) ?? 0);
            },
          ),
        ),
        const SizedBox(width: 16),
        // Column 5: Subtotal
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Rp ${_formatCurrency(rowTotal)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Delete button
        SizedBox(
          width: 44,
          child: widget.showDelete
              ? IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}
