import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/help_center_data.dart';
import '../widgets/faq_tile.dart';
import '../widgets/help_contact_footer.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _searchCtrl = TextEditingController();
  String? _expandedId;
  int? _activeCategoryIndex;

  List<FlatFaq> get _filteredFaqs {
    final query = _searchCtrl.text.trim().toLowerCase();
    final List<FlatFaq> result = [];

    for (var si = 0; si < helpCenterSections.length; si++) {
      if (_activeCategoryIndex != null && si != _activeCategoryIndex) continue;
      final section = helpCenterSections[si];
      for (var qi = 0; qi < section.items.length; qi++) {
        final item = section.items[qi];
        if (query.isEmpty ||
            item.q.toLowerCase().contains(query) ||
            item.a.toLowerCase().contains(query) ||
            section.title.toLowerCase().contains(query)) {
          result.add(FlatFaq(
            sectionIndex: si,
            itemIndex: qi,
            sectionTitle: section.title,
            sectionIcon: section.icon,
            item: item,
          ));
        }
      }
    }
    return result;
  }

  void _onCategoryTap(int index) {
    setState(() {
      _activeCategoryIndex = _activeCategoryIndex == index ? null : index;
      _expandedId = null;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;
    final isFiltering =
        _searchCtrl.text.trim().isNotEmpty || _activeCategoryIndex != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // ─── Search bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() => _expandedId = null),
              textInputAction: TextInputAction.search,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari pertanyaan...',
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _searchCtrl.clear();
                          _expandedId = null;
                        }),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),

          // ─── Category chips ────────────────────────────────
          if (_searchCtrl.text.isEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: helpCenterSections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final section = helpCenterSections[i];
                  final isActive = _activeCategoryIndex == i;
                  return GestureDetector(
                    onTap: () => _onCategoryTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            section.icon,
                            size: 15,
                            color: isActive
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            section.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // ─── FAQ list ──────────────────────────────────────
          Expanded(
            child: faqs.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ditemukan',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba kata kunci lain atau reset filter',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const HelpContactFooter(),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      final id = '${faq.sectionIndex}-${faq.itemIndex}';
                      final isExpanded = _expandedId == id;

                      final showSectionHeader = index == 0 ||
                          faq.sectionTitle != faqs[index - 1].sectionTitle;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showSectionHeader) ...[
                            if (index > 0) const SizedBox(height: 16),
                            _buildSectionHeader(faq),
                            const SizedBox(height: 10),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FaqTile(
                              key: ValueKey('faq-$id'),
                              question: faq.item.q,
                              answer: faq.item.a,
                              isExpanded: isExpanded,
                              highlight:
                                  isFiltering ? _searchCtrl.text.trim() : null,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _expandedId = expanded ? id : null;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(FlatFaq faq) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(faq.sectionIcon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Text(
          faq.sectionTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
