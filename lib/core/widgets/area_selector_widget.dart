import 'package:flutter/material.dart';
import '../../config/dependency_injection.dart';
import '../../core/utils/area_utils.dart';
import '../../features/product/data/models/area_model.dart';
import '../../theme/app_colors.dart';

/// Widget untuk memilih area dengan data dari API atau fallback ke hardcoded values
class AreaSelectorWidget extends StatefulWidget {
  final Function(AreaModel?) onAreaSelected;
  final AreaModel? initialArea;

  const AreaSelectorWidget({
    super.key,
    required this.onAreaSelected,
    this.initialArea,
  });

  @override
  State<AreaSelectorWidget> createState() => _AreaSelectorWidgetState();
}

class _AreaSelectorWidgetState extends State<AreaSelectorWidget> {
  late AreaUtils _areaUtils;
  List<AreaModel> _areas = [];
  AreaModel? _selectedArea;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _areaUtils = locator<AreaUtils>();
    _selectedArea = widget.initialArea;
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final areas = await _areaUtils.getAllAreas();
      setState(() {
        _areas = areas;
        _isLoading = false;

        // Set initial selection if not already set
        if (_selectedArea == null && areas.isNotEmpty) {
          _selectedArea = areas.first;
          widget.onAreaSelected(_selectedArea);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data area: $e';
        _isLoading = false;
      });
    }
  }

  void _onAreaChanged(AreaModel? area) {
    setState(() {
      _selectedArea = area;
    });
    widget.onAreaSelected(area);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Area',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          _buildErrorWidget()
        else
          _buildAreaDropdown(),
        const SizedBox(height: 16),
        if (!_isLoading && _areas.isNotEmpty) _buildAreaInfo(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: _loadAreas,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return DropdownButtonFormField<AreaModel>(
      value: _selectedArea,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Area',
        hintText: 'Pilih area',
      ),
      items: _areas.map((area) {
        return DropdownMenuItem<AreaModel>(
          value: area,
          child: Text(area.name),
        );
      }).toList(),
      onChanged: _onAreaChanged,
      validator: (value) {
        if (value == null) {
          return 'Area harus dipilih';
        }
        return null;
      },
    );
  }

  Widget _buildAreaInfo() {
    if (_selectedArea == null) return const SizedBox.shrink();

    final areaName = _selectedArea!.name;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Area',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryLight,
                ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('ID', _selectedArea!.id.toString()),
          _buildInfoRow('Nama', _selectedArea!.name),
          if (_selectedArea!.code != null)
            _buildInfoRow('Kode', _selectedArea!.code!),
          _buildInfoRow('Area Name', areaName),
          _buildInfoRow('Status',
              _selectedArea!.isActive ?? true ? 'Aktif' : 'Tidak Aktif'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
