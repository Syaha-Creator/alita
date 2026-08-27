import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../data/models/region_result.dart';
import '../../data/services/region_service.dart';
import '../../data/utils/region_api_parser.dart';

/// 4-step region picker (Provinsi → Kota → Kecamatan → Kelurahan + kode pos).
class RegionPickerBottomSheet extends StatefulWidget {
  const RegionPickerBottomSheet({super.key});

  @override
  State<RegionPickerBottomSheet> createState() =>
      _RegionPickerBottomSheetState();
}

class _RegionPickerBottomSheetState extends State<RegionPickerBottomSheet> {
  final RegionService _service = RegionService();
  final TextEditingController _searchCtrl = TextEditingController();

  /// 1=Provinsi, 2=Kota, 3=Kecamatan, 4=Kelurahan
  int _step = 1;
  bool _isLoading = true;
  String _error = '';

  List<RegionItem> _fullList = const [];
  List<RegionItem> _filteredList = const [];

  String? _selectedProvKode;
  String? _selectedProvName;
  String? _selectedKotaKode;
  String? _selectedKotaName;
  String? _selectedKecKode;
  String? _selectedKecName;

  static const _titles = [
    'Pilih Provinsi',
    'Pilih Kota / Kabupaten',
    'Pilih Kecamatan',
    'Pilih Kelurahan / Desa',
  ];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    _resetSearch();
    setState(() {
      _isLoading = true;
      _error = '';
      _step = 1;
    });
    final data = await _service.getProvinces();
    if (!mounted) return;
    _setList(data);
  }

  Future<void> _loadRegencies(String provKode) async {
    _resetSearch();
    setState(() {
      _isLoading = true;
      _error = '';
      _step = 2;
    });
    final data = await _service.getRegencies(provKode);
    if (!mounted) return;
    _setList(data);
  }

  Future<void> _loadDistricts(String kotaKode) async {
    _resetSearch();
    setState(() {
      _isLoading = true;
      _error = '';
      _step = 3;
    });
    final data = await _service.getDistricts(kotaKode);
    if (!mounted) return;
    _setList(data);
  }

  Future<void> _loadVillages(String kecKode) async {
    _resetSearch();
    setState(() {
      _isLoading = true;
      _error = '';
      _step = 4;
    });
    final data = await _service.getVillages(kecKode);
    if (!mounted) return;
    _setList(data);
  }

  void _setList(List<RegionItem> data) {
    setState(() {
      _isLoading = false;
      _fullList = data;
      _filteredList = data;
      if (data.isEmpty) {
        _error =
            'Gagal memuat data wilayah.\nPeriksa koneksi internet dan coba lagi.';
      }
    });
  }

  void _resetSearch() => _searchCtrl.clear();

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filteredList = q.isEmpty
          ? _fullList
          : _fullList
              .where((item) => item.nama.toLowerCase().contains(q))
              .toList();
    });
  }

  void _onItemTap(RegionItem item) {
    if (_step == 1) {
      _selectedProvKode = item.kode;
      _selectedProvName = item.nama;
      _loadRegencies(item.kode);
    } else if (_step == 2) {
      _selectedKotaKode = item.kode;
      _selectedKotaName = item.nama;
      _loadDistricts(item.kode);
    } else if (_step == 3) {
      _selectedKecKode = item.kode;
      _selectedKecName = item.nama;
      _loadVillages(item.kode);
    } else {
      Navigator.of(context).pop(
        RegionResult(
          provinsi: _selectedProvName ?? '',
          kota: _selectedKotaName ?? '',
          kecamatan: _selectedKecName ?? '',
          kelurahan: item.nama,
          kodepos: item.kodepos ?? '',
        ),
      );
    }
  }

  void _onBackTap() {
    if (_step == 2) {
      _loadProvinces();
    } else if (_step == 3) {
      final kode = _selectedProvKode;
      if (kode != null) _loadRegencies(kode);
    } else if (_step == 4) {
      final kode = _selectedKotaKode;
      if (kode != null) _loadDistricts(kode);
    }
  }

  void _retryCurrentStep() {
    final prov = _selectedProvKode;
    final kota = _selectedKotaKode;
    final kec = _selectedKecKode;
    if (_step == 1) {
      _loadProvinces();
    } else if (_step == 2 && prov != null) {
      _loadRegencies(prov);
    } else if (_step == 3 && kota != null) {
      _loadDistricts(kota);
    } else if (_step == 4 && kec != null) {
      _loadVillages(kec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _titles[_step - 1];
    final hintText = 'Cari ${title.replaceAll('Pilih ', '')}...';

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (_step > 1)
                  IconButton(
                    tooltip: 'Kembali',
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: _onBackTap,
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      _buildStepIndicator(),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: AppSearchField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              hintText: hintText,
              textCapitalization: TextCapitalization.words,
              textStyle: const TextStyle(fontSize: 14),
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              prefixIconColor: AppColors.textTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i < _step;
        final current = i + 1 == _step;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current ? 20 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildBody() {
    final Widget content;
    if (_isLoading) {
      content = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
      );
    } else if (_error.isNotEmpty) {
      content = Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                _error,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _retryCurrentStep,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ],
          ),
        ),
      );
    } else if (_filteredList.isEmpty) {
      content = const Center(
        key: ValueKey('empty'),
        child: Text(
          'Tidak ada hasil.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: _filteredList.length,
        itemExtent: _step == 4 ? 64 : 52,
        itemBuilder: (context, index) {
          final item = _filteredList[index];
          final pos = item.kodepos;
          return RepaintBoundary(
            child: ListTile(
              dense: true,
              title: Text(item.nama, style: const TextStyle(fontSize: 14)),
              subtitle: _step == 4 && pos != null && pos.isNotEmpty
                  ? Text(
                      'Kode pos $pos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
              trailing: _step < 4
                  ? const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textTertiary,
                    )
                  : const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.accent,
                    ),
              onTap: () => _onItemTap(item),
            ),
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      child: content,
    );
  }
}
