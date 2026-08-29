import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/program.dart';
import '../providers/master_data_providers.dart';

class MasterDataPage extends ConsumerStatefulWidget {
  const MasterDataPage({super.key});

  @override
  ConsumerState<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends ConsumerState<MasterDataPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  // Search Controllers
  final TextEditingController _searchController = TextEditingController();

  // Pagination states
  int _programPage = 1;
  int _pengajarPage = 1;
  int _muridPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index;
          _searchController.clear();
          // Reset search query provider
          ref.read(programSearchQueryProvider.notifier).state = '';
          ref.read(personSearchQueryProvider.notifier).state = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  // Program Add/Edit Dialog
  void _showProgramDialog({Program? program}) {
    final isEdit = program != null;
    final namaController = TextEditingController(text: isEdit ? program.namaProgram : '');
    final feeController = TextEditingController(text: isEdit ? program.defaultFeePengajar.toString() : '');
    final hargaController = TextEditingController(text: isEdit ? program.defaultHargaKlien.toString() : '');
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Edit Program' : 'Tambah Program Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Program',
                      hintText: 'Masukkan nama program (misal: Reguler Offline)',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nama program tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Standar Fee Pengajar (Rp)',
                      hintText: 'Masukkan nominal fee pengajar (misal: 150000)',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Fee pengajar tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Masukkan nominal angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: hargaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Standar Harga Klien (Rp)',
                      hintText: 'Masukkan nominal tagihan klien (misal: 200000)',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harga klien tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Masukkan nominal angka yang valid';
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newProgram = Program(
                    id: isEdit ? program.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    namaProgram: namaController.text.trim(),
                    defaultFeePengajar: int.parse(feeController.text.trim()),
                    defaultHargaKlien: int.parse(hargaController.text.trim()),
                  );

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  if (isEdit) {
                    await ref.read(programListProvider.notifier).updateProgram(newProgram);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Program berhasil diperbarui!')),
                    );
                  } else {
                    await ref.read(programListProvider.notifier).addProgram(newProgram);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Program berhasil ditambahkan!')),
                    );
                  }
                  navigator.pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Person (Pengajar/Murid) Add/Edit Dialog
  void _showPersonDialog({Person? person, required String kategori}) {
    final isEdit = person != null;
    final namaController = TextEditingController(text: isEdit ? person.nama : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Edit Data $kategori' : 'Tambah $kategori Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama $kategori',
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newPerson = Person(
                    id: isEdit ? person.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    nama: namaController.text.trim(),
                    kategori: kategori,
                  );

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  if (isEdit) {
                    await ref.read(personListProvider.notifier).updatePerson(newPerson);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Data $kategori berhasil diperbarui!')),
                    );
                  } else {
                    await ref.read(personListProvider.notifier).addPerson(newPerson);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Data $kategori berhasil ditambahkan!')),
                    );
                  }
                  navigator.pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Delete Confirmation Dialog
  void _showDeleteConfirmation(dynamic item, bool isProgram) {
    final name = isProgram ? (item as Program).namaProgram : (item as Person).nama;
    final typeName = isProgram ? 'Program' : (item as Person).kategori;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi Hapus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('Apakah Anda yakin ingin menghapus $typeName "$name"? Data yang dihapus tidak bisa dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
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

                if (isProgram) {
                  await ref.read(programListProvider.notifier).deleteProgram((item as Program).id);
                } else {
                  await ref.read(personListProvider.notifier).deletePerson((item as Person).id);
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('$typeName "$name" berhasil dihapus!')),
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Judul Halaman
          const Text(
            'Kelola Data Master',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),

          // Tab Bar Navigation
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: const [
              Tab(text: 'Data Pengajar'),
              Tab(text: 'Data Murid'),
              Tab(text: 'Data Program'),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 24),

          // Controls Area (Search & Add Button)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Search box
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        if (_activeTab == 2) {
                          ref.read(programSearchQueryProvider.notifier).state = val;
                        } else {
                          ref.read(personSearchQueryProvider.notifier).state = val;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: _activeTab == 0
                            ? 'Cari nama pengajar...'
                            : _activeTab == 1
                                ? 'Cari nama murid...'
                                : 'Cari nama program...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Add Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.action,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_activeTab == 0) {
                      _showPersonDialog(kategori: 'Pengajar');
                    } else if (_activeTab == 1) {
                      _showPersonDialog(kategori: 'Murid');
                    } else {
                      _showProgramDialog();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    _activeTab == 0
                        ? 'Tambah Pengajar Baru'
                        : _activeTab == 1
                            ? 'Tambah Murid Baru'
                            : 'Tambah Program Baru',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main data tables list with Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPengajarTable(),
                _buildMuridTable(),
                _buildProgramTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DATA TAB 1: PENGAJAR TABLE
  Widget _buildPengajarTable() {
    final allFiltered = ref.watch(pengajarListProvider);
    final totalCount = allFiltered.length;
    final totalPages = (totalCount / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

    if (_pengajarPage > totalPages) {
      _pengajarPage = totalPages;
    }

    final start = (_pengajarPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, totalCount);
    final paginated = allFiltered.sublist(start, end);

    return _buildTableWrapper(
      title: 'Daftar Pengajar',
      totalItems: totalCount,
      currentPage: _pengajarPage,
      totalPages: totalPages,
      startIndex: start,
      endIndex: end,
      onPageChanged: (page) {
        setState(() {
          _pengajarPage = page;
        });
      },
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(120),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        children: [
          // Header Row
          _buildTableHeaderRow(const ['NAMA PENGAJAR', 'KATEGORI', 'AKSI']),
          // Data Rows
          if (paginated.isEmpty)
            TableRow(
              children: [
                _buildTableCell(
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Tidak ada data pengajar.',
                      style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                _buildTableCell(child: const SizedBox()),
                _buildTableCell(child: const SizedBox()),
              ],
            )
          else
            ...paginated.map((person) {
              return TableRow(
                children: [
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        person.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text, fontSize: 15),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        person.kategori,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _showPersonDialog(person: person, kategori: 'Pengajar'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          onPressed: () => _showDeleteConfirmation(person, false),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // DATA TAB 2: MURID TABLE
  Widget _buildMuridTable() {
    final allFiltered = ref.watch(muridListProvider);
    final totalCount = allFiltered.length;
    final totalPages = (totalCount / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

    if (_muridPage > totalPages) {
      _muridPage = totalPages;
    }

    final start = (_muridPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, totalCount);
    final paginated = allFiltered.sublist(start, end);

    return _buildTableWrapper(
      title: 'Daftar Murid',
      totalItems: totalCount,
      currentPage: _muridPage,
      totalPages: totalPages,
      startIndex: start,
      endIndex: end,
      onPageChanged: (page) {
        setState(() {
          _muridPage = page;
        });
      },
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(120),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        children: [
          // Header Row
          _buildTableHeaderRow(const ['NAMA MURID', 'KATEGORI', 'AKSI']),
          // Data Rows
          if (paginated.isEmpty)
            TableRow(
              children: [
                _buildTableCell(
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Tidak ada data murid.',
                      style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                _buildTableCell(child: const SizedBox()),
                _buildTableCell(child: const SizedBox()),
              ],
            )
          else
            ...paginated.map((person) {
              return TableRow(
                children: [
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        person.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text, fontSize: 15),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        person.kategori,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _showPersonDialog(person: person, kategori: 'Murid'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          onPressed: () => _showDeleteConfirmation(person, false),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // DATA TAB 3: PROGRAM TABLE
  Widget _buildProgramTable() {
    final allFiltered = ref.watch(filteredProgramsProvider);
    final totalCount = allFiltered.length;
    final totalPages = (totalCount / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

    if (_programPage > totalPages) {
      _programPage = totalPages;
    }

    final start = (_programPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, totalCount);
    final paginated = allFiltered.sublist(start, end);

    return _buildTableWrapper(
      title: 'Daftar Program',
      totalItems: totalCount,
      currentPage: _programPage,
      totalPages: totalPages,
      startIndex: start,
      endIndex: end,
      onPageChanged: (page) {
        setState(() {
          _programPage = page;
        });
      },
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FixedColumnWidth(120),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        children: [
          // Header Row
          _buildTableHeaderRow(const [
            'NAMA PROGRAM',
            'STANDAR FEE PENGAJAR (RP)',
            'STANDAR HARGA KLIEN (RP)',
            'AKSI'
          ]),
          // Data Rows
          if (paginated.isEmpty)
            TableRow(
              children: [
                _buildTableCell(
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Tidak ada data program.',
                      style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                _buildTableCell(child: const SizedBox()),
                _buildTableCell(child: const SizedBox()),
                _buildTableCell(child: const SizedBox()),
              ],
            )
          else
            ...paginated.map((program) {
              return TableRow(
                children: [
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        program.namaProgram,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text, fontSize: 15),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        'Rp ${_formatCurrency(program.defaultFeePengajar)}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.text, fontSize: 14),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        'Rp ${_formatCurrency(program.defaultHargaKlien)}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.text, fontSize: 14),
                      ),
                    ),
                  ),
                  _buildTableCell(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _showProgramDialog(program: program),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          onPressed: () => _showDeleteConfirmation(program, true),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // TABLE DECORATIONS HELPERS
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
        final isActions = title == 'AKSI';
        return TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
            child: Text(
              title,
              textAlign: isActions ? TextAlign.center : TextAlign.left,
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

  // TABLE CONTAINER & PAGINATION WRAPPER
  Widget _buildTableWrapper({
    required String title,
    required int totalItems,
    required int currentPage,
    required int totalPages,
    required int startIndex,
    required int endIndex,
    required ValueChanged<int> onPageChanged,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table main content
          Expanded(
            child: SingleChildScrollView(
              child: child,
            ),
          ),
          
          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Displaying X-Y of Z text
                Text(
                  totalItems == 0
                      ? 'Menampilkan 0-0 dari 0 data'
                      : 'Menampilkan ${startIndex + 1}-$endIndex dari $totalItems data',
                  style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
                
                // Pagination Buttons
                if (totalPages > 1)
                  Row(
                    children: [
                      // Previous button
                      _buildPageArrow(
                        icon: Icons.chevron_left_rounded,
                        isEnabled: currentPage > 1,
                        onPressed: () => onPageChanged(currentPage - 1),
                      ),
                      const SizedBox(width: 8),
                      // Page numbers
                      ...List.generate(totalPages, (index) {
                        final pageNum = index + 1;
                        final isSelected = pageNum == currentPage;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => onPageChanged(pageNum),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                pageNum.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      // Next button
                      _buildPageArrow(
                        icon: Icons.chevron_right_rounded,
                        isEnabled: currentPage < totalPages,
                        onPressed: () => onPageChanged(currentPage + 1),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageArrow({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEnabled ? AppColors.border : AppColors.border.withAlpha(128),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? AppColors.text : AppColors.textLight.withAlpha(77),
        ),
      ),
    );
  }
}
