import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/constants/colors.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/transaksi.dart';
import '../../domain/entities/program.dart';
import '../providers/slip_gaji_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/master_data_providers.dart';
import '../services/pdf_service.dart';

class DashboardPage extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToPage;

  const DashboardPage({super.key, this.onNavigateToPage});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatCurrency(int value) {
    final isNegative = value < 0;
    final absValue = value.abs();
    final buffer = StringBuffer();
    final str = absValue.toString();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final formattedStr = buffer.toString().split('').reversed.join('');
    return '${isNegative ? '-' : ''}Rp $formattedStr';
  }

  String _formatCurrencyOnly(int value) {
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

  Future<void> _handleReprint(BuildContext context, WidgetRef ref, Transaksi tx) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pdfBytes = tx.jenis == 'Invoice'
          ? await PdfService.generateInvoicePdf(
              InvoiceFormState(
                tagihanUntuk: tx.namaTarget,
                tanggalInvoice: tx.tanggal,
                tanggalJatuhTempo: tx.tanggal,
                rows: [
                  InvoiceRowState(
                    id: 'reprint',
                    program: Program(id: 'reprint', namaProgram: 'Layanan Tutoring (Reprint)', defaultFeePengajar: 0, defaultHargaKlien: tx.total),
                    kuantitas: 1,
                    harga: tx.total,
                  ),
                ],
              ),
              'INV_REPRINT_${tx.id}',
              isLunas: tx.isLunas,
            )
          : await PdfService.generateSlipGajiPdf(
              SlipGajiFormState(
                namaPengajar: tx.namaTarget,
                tanggalCetak: tx.tanggal,
                reimburse: 0,
                subsidi: 0,
                rows: [
                  SlipGajiRowState(
                    id: 'reprint',
                    namaAnak: 'Siswa',
                    program: Program(id: 'reprint', namaProgram: 'Honor Mengajar (Reprint)', defaultFeePengajar: tx.total, defaultHargaKlien: 0),
                    sesi: 1,
                    fee: tx.total,
                  ),
                ],
              ),
            );

      final fileName = tx.jenis == 'Invoice'
          ? 'Invoice_Reprint_${tx.namaTarget.replaceAll(' ', '_')}_${tx.id}.pdf'
          : 'SlipGaji_Reprint_${tx.namaTarget.replaceAll(' ', '_')}_${tx.id}.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);

      messenger.showSnackBar(
        SnackBar(content: Text('PDF berhasil disiapkan untuk dicetak/disimpan')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error reprinting PDF: $e\n$stackTrace');
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mencetak ulang PDF: $e')),
      );
    }
  }

  void _handleEdit(WidgetRef ref, Transaksi tx) {
    final programs = ref.read(programListProvider);
    final defaultProgram = programs.isNotEmpty ? programs.first : null;
    final dynamic txKey = tx.key ?? tx.id;

    if (tx.jenis == 'Invoice') {
      final people = ref.read(personListProvider);
      final parent = people.cast<Person?>().firstWhere(
        (p) => p?.kategori == 'Orang Tua' && p?.nama.toLowerCase() == tx.namaTarget.toLowerCase(),
        orElse: () => null,
      );
      String? matchedChildName;
      if (parent != null) {
        final children = people.where((p) => p.kategori == 'Murid' && p.parentId == parent.id).toList();
        if (children.isNotEmpty) {
          matchedChildName = children.map((c) => c.nama).join(', ');
        }
      }

      final notifier = ref.read(invoiceFormProvider.notifier);
      notifier.setForm(
        InvoiceFormState(
          transactionKey: txKey,
          transactionId: tx.id,
          tagihanUntuk: tx.namaTarget,
          namaAnak: matchedChildName,
          tanggalInvoice: tx.tanggal,
          tanggalJatuhTempo: tx.tanggal,
          rows: [
            InvoiceRowState(
              id: '1',
              program: defaultProgram,
              hariMengaji: 'Setiap Pertemuan',
              kuantitas: 1,
              harga: tx.total,
            ),
          ],
        ),
      );
      onNavigateToPage?.call(2); // Navigasi ke Buat Invoice (index 2)
    } else {
      final notifier = ref.read(slipGajiFormProvider.notifier);
      notifier.setForm(
        SlipGajiFormState(
          transactionKey: txKey,
          transactionId: tx.id,
          namaPengajar: tx.namaTarget,
          tanggalCetak: tx.tanggal,
          reimburse: 0,
          subsidi: 0,
          rows: [
            SlipGajiRowState(
              id: '1',
              namaAnak: 'Siswa',
              program: defaultProgram,
              sesi: 1,
              fee: tx.total,
            ),
          ],
        ),
      );
      onNavigateToPage?.call(1); // Navigasi ke Buat Slip Gaji (index 1)
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Transaksi tx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Hapus Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.text),
          ),
          content: Text('Apakah Anda yakin ingin menghapus transaksi "${tx.jenis} - ${tx.namaTarget}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: context.colors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final dynamic txKey = tx.key ?? tx.id;
                try {
                  await ref.read(transaksiListProvider.notifier).deleteTransaksi(txKey);
                  ref.invalidate(transaksiListProvider);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Transaksi berhasil dihapus!')),
                  );
                } catch (e, stackTrace) {
                  debugPrint('Error deleting transaction: $e\n$stackTrace');
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menghapus transaksi: $e')),
                  );
                }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transaksiListProvider);

    int totalPemasukan = 0;
    int totalPengeluaran = 0;

    for (final tx in transactions) {
      if (tx.jenis == 'Invoice') {
        totalPemasukan += tx.total;
      } else if (tx.jenis == 'Slip Gaji') {
        totalPengeluaran += tx.total;
      }
    }

    final sisaSaldo = totalPemasukan - totalPengeluaran;

    final sortedTransactions = List<Transaksi>.from(transactions)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final latestTransactions = sortedTransactions.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul Halaman
          Text(
            'Dashboard Keuangan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.colors.text,
            ),
          ),
          SizedBox(height: 24),

          // 3 Cards Ringkasan Keuangan secara Horizontal
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  title: 'Total Pemasukan',
                  value: totalPemasukan,
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  title: 'Total Pengeluaran',
                  value: totalPengeluaran,
                  icon: Icons.trending_down_rounded,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  title: 'Sisa Saldo',
                  value: sisaSaldo,
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),

          // Judul Riwayat Transaksi
          Text(
            'Riwayat Transaksi Terakhir',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.text,
            ),
          ),
          SizedBox(height: 16),

          // Tabel Transaksi
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2), // Tanggal
                          1: FlexColumnWidth(2), // Jenis Transaksi
                          2: FlexColumnWidth(4), // Deskripsi / Penerima
                          3: FlexColumnWidth(3), // Total Nominal
                          4: FixedColumnWidth(150), // Aksi
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
                        ),
                        children: [
                          _buildTableHeaderRow(context, [
                            'TANGGAL',
                            'JENIS TRANSAKSI',
                            'DESKRIPSI / PENERIMA',
                            'TOTAL NOMINAL',
                            'AKSI'
                          ]),
                          if (latestTransactions.isEmpty)
                            TableRow(
                              children: [
                                _buildTableCell(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Text(
                                      'Tidak ada data transaksi.',
                                      style: TextStyle(
                                          color: context.colors.textLight,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ),
                                _buildTableCell(child: SizedBox()),
                                _buildTableCell(child: SizedBox()),
                                _buildTableCell(child: SizedBox()),
                                _buildTableCell(child: SizedBox()),
                              ],
                            )
                          else
                            ...latestTransactions.map((tx) {
                              final isInvoice = tx.jenis == 'Invoice';
                              return TableRow(
                                children: [
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 16.0),
                                      child: Text(
                                        _formatDate(tx.tanggal),
                                        style: TextStyle(
                                            color: context.colors.text, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 16.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isInvoice
                                                ? (tx.isLunas ? Colors.green.shade50 : Colors.orange.shade50)
                                                : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                                color: isInvoice
                                                    ? (tx.isLunas ? Colors.green.shade100 : Colors.orange.shade100)
                                                    : Colors.red.shade100),
                                          ),
                                          child: Text(
                                            tx.jenis,
                                            style: TextStyle(
                                              color: isInvoice
                                                  ? (tx.isLunas ? Colors.green.shade700 : Colors.orange.shade700)
                                                  : Colors.red.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 16.0),
                                      child: Text(
                                        tx.namaTarget,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: context.colors.text,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 16.0),
                                      child: Text(
                                        '${isInvoice ? '+' : '-'} Rp ${_formatCurrencyOnly(tx.total)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isInvoice
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isInvoice)
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                            icon: Icon(
                                              tx.isLunas ? Icons.check_circle : Icons.radio_button_unchecked,
                                              color: tx.isLunas ? Colors.green : Colors.grey,
                                              size: 20,
                                            ),
                                            tooltip: tx.isLunas ? 'Batalkan Lunas' : 'Tandai Lunas',
                                            onPressed: () async {
                                              final dynamic txKey = tx.key ?? tx.id;
                                              final updatedTx = Transaksi(
                                                id: tx.id,
                                                tanggal: tx.tanggal,
                                                jenis: tx.jenis,
                                                namaTarget: tx.namaTarget,
                                                total: tx.total,
                                                rowsData: tx.rowsData,
                                                catatanSubsidi: tx.catatanSubsidi,
                                                catatanReimburse: tx.catatanReimburse,
                                                catatanPotongan: tx.catatanPotongan,
                                                isLunas: !tx.isLunas,
                                              );
                                              await ref.read(transaksiListProvider.notifier).updateTransaksi(txKey, updatedTx);
                                              ref.invalidate(transaksiListProvider);
                                            },
                                          ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                          icon: Icon(Icons.print_outlined, color: Colors.blue, size: 20),
                                          tooltip: 'Cetak Ulang',
                                          onPressed: () => _handleReprint(context, ref, tx),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                          icon: Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                          tooltip: 'Edit',
                                          onPressed: () => _handleEdit(ref, tx),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                          icon: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                          tooltip: 'Hapus',
                                          onPressed: () => _showDeleteConfirmation(context, ref, tx),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color.shade700,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _formatCurrency(value),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell({required Widget child}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: child,
    );
  }

  TableRow _buildTableHeaderRow(BuildContext context, List<String> headings) {
    return TableRow(
      decoration: BoxDecoration(
        color: context.colors.tableHeader,
      ),
      children: headings.map((title) {
        final isActions = title == 'AKSI';
        return TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
            child: Text(
              title,
              textAlign: isActions ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.text,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
