import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../data/services/region_service.dart';

/// Result returned to the caller when the user completes all 3 steps.
class RegionResult {
  final String provinsi;
  final String kota;
  final String kecamatan;

  const RegionResult({
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
  });
}

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
    _setList(data);
  }

  void _setList(List<Map<String, dynamic>> data) {
    setState(() {
      _isLoading = false;
      _fullList = data;
      _filteredList = data;
      if (data.isEmpty) _error = 'Data tidak ditemukan.';
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
                  (item) => (item['name'] as String).toLowerCase().contains(q))
              .toList();
    });
  }

  void _onItemTap(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final name = item['name'] as String;

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
          provinsi: _selectedProvName!,
          kota: _selectedKotaName!,
          kecamatan: name,
        ),
      );
    }
  }

  void _onBackTap() {
    if (_step == 2) {
      _loadProvinces();
    } else if (_step == 3) {
      _loadRegencies(_selectedProvId!);
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
        color: Colors.white,
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
                color: const Color(0xFFDDDDDD),
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
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: _onBackTap,
                    tooltip: 'Kembali',
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
                color: Color(0xFFBBBBBB),
              ),
              prefixIconColor: const Color(0xFFAAAAAA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
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
            color: active ? AppColors.primary : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_filteredList.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada hasil.',
          style: TextStyle(color: Color(0xFF999999), fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      itemCount: _filteredList.length,
      itemExtent: 52,
      itemBuilder: (context, index) {
        final item = _filteredList[index];
        return ListTile(
          dense: true,
          title: Text(
            item['name'] as String,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: _step < 3
              ? const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFFBBBBBB),
                )
              : const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
          onTap: () => _onItemTap(item),
        );
      },
    );
  }
}
