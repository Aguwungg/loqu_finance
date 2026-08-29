import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../domain/entities/transaksi.dart';
import '../providers/slip_gaji_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

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
          const Text(
            'Dashboard Keuangan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),

          // 3 Cards Ringkasan Keuangan secara Horizontal
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Pemasukan',
                  value: totalPemasukan,
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Pengeluaran',
                  value: totalPengeluaran,
                  icon: Icons.trending_down_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Sisa Saldo',
                  value: sisaSaldo,
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Judul Riwayat Transaksi
          const Text(
            'Riwayat Transaksi Terakhir',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),

          // Tabel Transaksi
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
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
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
                        ),
                        children: [
                          _buildTableHeaderRow([
                            'TANGGAL',
                            'JENIS TRANSAKSI',
                            'DESKRIPSI / PENERIMA',
                            'TOTAL NOMINAL'
                          ]),
                          if (latestTransactions.isEmpty)
                            TableRow(
                              children: [
                                _buildTableCell(
                                  child: const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Text(
                                      'Tidak ada data transaksi.',
                                      style: TextStyle(
                                          color: AppColors.textLight,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ),
                                _buildTableCell(child: const SizedBox()),
                                _buildTableCell(child: const SizedBox()),
                                _buildTableCell(child: const SizedBox()),
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
                                          horizontal: 24.0, vertical: 16.0),
                                      child: Text(
                                        _formatDate(tx.tanggal),
                                        style: const TextStyle(
                                            color: AppColors.text, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0, vertical: 16.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isInvoice
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: isInvoice
                                                      ? Colors.green.shade100
                                                      : Colors.red.shade100),
                                            ),
                                            child: Text(
                                              tx.jenis,
                                              style: TextStyle(
                                                color: isInvoice
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0, vertical: 16.0),
                                      child: Text(
                                        tx.namaTarget,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  _buildTableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0, vertical: 16.0),
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
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
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

  TableRow _buildTableHeaderRow(List<String> headings) {
    return TableRow(
      decoration: const BoxDecoration(
        color: AppColors.tableHeader,
      ),
      children: headings.map((title) {
        return TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
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
