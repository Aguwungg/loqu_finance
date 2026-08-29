import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/slip_gaji_provider.dart';
import '../providers/invoice_provider.dart';

class PdfService {
  // Simple currency formatter: e.g. 150000 -> 150.000
  static String _formatCurrency(int value) {
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

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // --- GENERATE SLIP GAJI PDF (PENGELUARAN) ---
  static Future<Uint8List> generateSlipGajiPdf(SlipGajiFormState data) async {
    final pdf = pw.Document();

    pw.MemoryImage? pdfLogo;
    try {
      final byteData = await rootBundle.load('assets/logo.png');
      final imageBytes = byteData.buffer.asUint8List();
      pdfLogo = pw.MemoryImage(imageBytes);
    } catch (e) {
      debugPrint('Error loading logo for PDF: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (pdfLogo != null) ...[
                pw.Center(
                  child: pw.Image(pdfLogo, width: 80),
                ),
                pw.SizedBox(height: 15),
              ],
              // Header Kop Surat
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LOQU',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF001F3F), // Deep Navy Blue
                        ),
                      ),
                      pw.Text(
                        'Tutoring Financial System',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SLIP GAJI PENGAJAR',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF001F3F),
                        ),
                      ),
                      pw.Text(
                        'Tanggal: ${_formatDate(data.tanggalCetak)}',
                        style: const pw.TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF001F3F)),
              pw.SizedBox(height: 20),

              // Metadata Karyawan/Pengajar
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Nama Pengajar:',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            data.namaPengajar.isEmpty ? '-' : data.namaPengajar,
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Status Pembayaran:',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            'LUNAS (Offline)',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              // Rincian Kegiatan Mengajar (Tabel)
              pw.Text(
                'Rincian Mengajar',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F)),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FlexColumnWidth(2),
                  5: pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Nama Anak', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Program', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Sesi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Fee / Sesi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(data.rows.length, (index) {
                    final row = data.rows[index];
                    final rowTotal = row.sesi * row.fee;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row.namaAnak.isEmpty ? '-' : row.namaAnak, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row.program?.namaProgram ?? '-', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${row.sesi}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rp ${_formatCurrency(row.fee)}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rp ${_formatCurrency(rowTotal)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // Rincian Akumulasi Biaya
              pw.Row(
                children: [
                  pw.Spacer(flex: 3),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('Rp ${_formatCurrency(data.subtotal)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subsidi (+):', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('Rp ${_formatCurrency(data.subsidi)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Reimburse (-):', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('Rp ${_formatCurrency(data.reimburse)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Pendapatan:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F))),
                            pw.Text('Rp ${_formatCurrency(data.totalPendapatan)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Tanda Tangan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Penerima,', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 50),
                      pw.Container(width: 100, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text(data.namaPengajar.isEmpty ? 'Pengajar' : data.namaPengajar, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Pengelola LOQU,', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 50),
                      pw.Container(width: 100, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Administrasi', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateInvoicePdf(InvoiceFormState data, String invoiceNumber) async {
    final pdf = pw.Document();

    pw.MemoryImage? pdfLogo;
    try {
      final byteData = await rootBundle.load('assets/logo.png');
      final imageBytes = byteData.buffer.asUint8List();
      pdfLogo = pw.MemoryImage(imageBytes);
    } catch (e) {
      debugPrint('Error loading logo for PDF: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (pdfLogo != null) ...[
                pw.Center(
                  child: pw.Image(pdfLogo, width: 80),
                ),
                pw.SizedBox(height: 15),
              ],
              // Header Kop Surat
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LOQU',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF001F3F), // Deep Navy Blue
                        ),
                      ),
                      pw.Text(
                        'Tutoring Financial System',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE TAGIHAN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF001F3F),
                        ),
                      ),
                      pw.Text(
                        'No: $invoiceNumber',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Tanggal: ${_formatDate(data.tanggalInvoice)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF001F3F)),
              pw.SizedBox(height: 20),

              // Metadata Invoice
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Tagihan Untuk (Orang Tua / Murid):',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            data.tagihanUntuk.isEmpty ? '-' : data.tagihanUntuk,
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Jatuh Tempo: ${_formatDate(data.tanggalJatuhTempo)}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Status Tagihan:',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            'BELUM LUNAS',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.amber700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              // Rincian Item Tagihan (Tabel)
              pw.Text(
                'Rincian Item Tagihan',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F)),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(4),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FlexColumnWidth(2),
                  5: pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item Program', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Hari Mengaji', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Kuantitas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Harga / Sesi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(data.rows.length, (index) {
                    final row = data.rows[index];
                    final rowTotal = row.kuantitas * row.harga;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row.program?.namaProgram ?? '-', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row.hariMengaji.isEmpty ? '-' : row.hariMengaji, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${row.kuantitas}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rp ${_formatCurrency(row.harga)}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rp ${_formatCurrency(rowTotal)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 15),

              // Rincian Akumulasi Tagihan
              pw.Row(
                children: [
                  pw.Spacer(flex: 3),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Tagihan:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F))),
                            pw.Text('Rp ${_formatCurrency(data.totalTagihan)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Bank Details & Terms & Conditions & Signatures (Side-by-side)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Bank & Terms
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INFORMASI PEMBAYARAN',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Bank: BCA\nNo. Rek: 8610735992\nA/N: Harits Ar-Royhan H',
                          style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Text(
                          'SYARAT & KETENTUAN',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF001F3F)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          width: 250,
                          child: pw.Text(
                            'Penagihan invoice kami kirimkan setiap tanggal 1. Apabila hari mengaji ananda pada bulan berikutnya bertepatan dengan tanggal 1, maka kami tagihkan pada bulan berjalan.',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, lineSpacing: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: Signatures
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Hormat Kami,', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 50),
                        pw.Container(width: 120, height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('LOQU Administration', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 24),
                        pw.Text('Penerima / Orang Tua,', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 50),
                        pw.Container(width: 120, height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('(....................................)', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
