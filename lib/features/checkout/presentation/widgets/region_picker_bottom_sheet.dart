import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../data/models/region_result.dart';
import '../../data/services/region_service.dart';

/// 3-step region picker (Provinsi → Kota/Kab → Kecamatan).
/// Pop with a [RegionResult] on success, or null if dismissed.
class RegionPickerBottomSheet extends StatefulWidget {
  const RegionPickerBottomSheet({super.key});

  @override
  State<RegionPickerBottomSheet> createState() =>
      _RegionPickerBottomSheetState();
}

class _RegionPickerBottomSheetState extends State<RegionPickerBottomSheet> {
  final RegionService _service = RegionService();
  final TextEditingController _searchCtrl = TextEditingController();

  int _step = 1; // 1 = Provinsi, 2 = Kota, 3 = Kecamatan
  bool _isLoading = true;
  String _error = '';

  List<Map<String, dynamic>> _fullList = [];
  List<Map<String, dynamic>> _filteredList = [];

  String? _selectedProvId;
  String? _selectedProvName;
  String? _selectedKotaName;

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

  // ─────────────────────── Data loaders ────────────────────────

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

  Future<void> _loadRegencies(String provId) async {
    _resetSearch();
    setState(() {
      _isLoading = true;
      _error = '';
      _step = 2;
    });
    final data = await _service.getRegencies(provId);
    if (!mounted) return;
    _setList(data);
  }

  Future<void> _loadDistricts(String kotaId) async {
    _resetSearch();
    setState(() {
      _isLoading = true;
      _error = '';
      _step = 3;
    });
    final data = await _service.getDistricts(kotaId);
    if (!mounted) return;
    _setList(data);
  }

  void _setList(List<Map<String, dynamic>> data) {
    setState(() {
      _isLoading = false;
      _fullList = data;
      _filteredList = data;
      if (data.isEmpty) {
        _error = 'Gagal memuat data wilayah.\nPeriksa koneksi internet dan coba lagi.';
      }
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
  }

  // ─────────────────────── Interactions ────────────────────────

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filteredList = q.isEmpty
          ? _fullList
          : _fullList
              .where(
                  (item) => (item['name']?.toString() ?? '').toLowerCase().contains(q))
              .toList();
    });
  }

  void _onItemTap(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? '';

    if (_step == 1) {
      _selectedProvId = id;
      _selectedProvName = name;
      _loadRegencies(id);
    } else if (_step == 2) {
      _selectedKotaName = name;
      _loadDistricts(id);
    } else {
      Navigator.of(context).pop(
        RegionResult(
          provinsi: _selectedProvName ?? '',
          kota: _selectedKotaName ?? '',
          kecamatan: name,
        ),
      );
    }
  }

  void _onBackTap() {
    if (_step == 2) {
      _loadProvinces();
    } else if (_step == 3) {
      final provId = _selectedProvId;
      if (provId != null) _loadRegencies(provId);
    }
  }

  void _retryCurrentStep() {
    final provId = _selectedProvId;
    if (_step == 1) {
      _loadProvinces();
    } else if (_step == 2 && provId != null) {
      _loadRegencies(provId);
    } else if (_step == 3 && provId != null) {
      _loadRegencies(provId);
    }
  }

  // ─────────────────────── Build ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Pilih Provinsi',
      'Pilih Kota / Kabupaten',
      'Pilih Kecamatan'
    ];
    final title = titles[_step - 1];
    final hintText = 'Cari ${title.replaceAll('Pilih ', '')}...';

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle bar ─────────────────────────────────────────
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

          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Back / spacer
                if (_step > 1)
                  IconButton(
                    tooltip: 'Kembali',
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: _onBackTap,
                  )
                else
                  const SizedBox(width: 48),

                // Title + step indicator
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

                // Close
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          // ── Search bar ────────────────────────────────────────
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

          // ── List ─────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
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
        child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(AppColors.accent)),
      );
    } else if (_error.isNotEmpty) {
      content = Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                _error,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 14),
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
      itemExtent: 52,
      itemBuilder: (context, index) {
        final item = _filteredList[index];
        return RepaintBoundary(
          child: ListTile(
          dense: true,
          title: Text(
            item['name']?.toString() ?? '',
            style: const TextStyle(fontSize: 14),
          ),
          trailing: _step < 3
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
