import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';
import '../../../services/geocoding_service.dart';

/// 各地点編集用の状態オブジェクト
class LocationEditItem {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController placeNameCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  List<GeocodingResult> suggestions = [];
  bool isSearching = false;
  Timer? debounceTimer;

  LocationEditItem({
    required this.id,
    required String name,
    required String placeName,
    required double lat,
    required double lon,
  })  : nameCtrl = TextEditingController(text: name),
        placeNameCtrl = TextEditingController(text: placeName),
        latCtrl = TextEditingController(text: lat.toStringAsFixed(4)),
        lonCtrl = TextEditingController(text: lon.toStringAsFixed(4));

  void dispose() {
    debounceTimer?.cancel();
    nameCtrl.dispose();
    placeNameCtrl.dispose();
    latCtrl.dispose();
    lonCtrl.dispose();
  }
}

/// 地点設定カードウィジェット（表示名、地名検索オートコンプリート、緯度経度入力）
class LocationEditCard extends StatefulWidget {
  final LocationEditItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const LocationEditCard({
    super.key,
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<LocationEditCard> createState() => _LocationEditCardState();
}

class _LocationEditCardState extends State<LocationEditCard> {
  void _onPlaceQueryChanged(String query) {
    final item = widget.item;
    item.debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        item.suggestions = [];
        item.isSearching = false;
      });
      return;
    }

    item.debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => item.isSearching = true);
      final results = await GeocodingService.search(query);
      if (mounted) {
        setState(() {
          item.suggestions = results;
          item.isSearching = false;
        });
      }
    });
  }

  void _selectSuggestion(GeocodingResult result) {
    final item = widget.item;
    setState(() {
      item.placeNameCtrl.text = result.displayName;
      item.latCtrl.text = result.latitude.toStringAsFixed(4);
      item.lonCtrl.text = result.longitude.toStringAsFixed(4);
      // 表示名が未入力なら地名をデフォルト代入
      if (item.nameCtrl.text.trim().isEmpty) {
        item.nameCtrl.text = result.name;
      }
      item.suggestions = [];
    });
  }

  InputDecoration _inputDecoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: AppColors.slate400, fontSize: 12),
      hintStyle: const TextStyle(color: AppColors.slate600, fontSize: 12),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.sky400, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141D2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorderLight, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title & Remove Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sky400.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '地点 ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sky400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.nameCtrl.text.isNotEmpty ? item.nameCtrl.text : '（未設定）',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate200,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  tooltip: 'この地点を削除',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.tempHot),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Two-column layout for Display Name & Place Search
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 460;
              final displayNameField = TextFormField(
                controller: item.nameCtrl,
                style: const TextStyle(color: AppColors.slate50, fontSize: 13),
                decoration: _inputDecoration(
                  'タブ表示名（空欄時は場所名を自動適用）',
                  hint: item.placeNameCtrl.text.isNotEmpty ? item.placeNameCtrl.text : '例: 自宅, 職場',
                  suffixIcon: item.nameCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.slate400),
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: '入力をクリア',
                          onPressed: () {
                            item.nameCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              );

              final placeSearchField = TextFormField(
                controller: item.placeNameCtrl,
                style: const TextStyle(color: AppColors.slate50, fontSize: 13),
                decoration: _inputDecoration(
                  '場所を検索（例: 渋谷, 横浜市）',
                  suffixIcon: item.isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sky400),
                          ),
                        )
                      : item.placeNameCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.slate400),
                              splashRadius: 14,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: '検索文字をクリア',
                              onPressed: () {
                                item.placeNameCtrl.clear();
                                _onPlaceQueryChanged('');
                              },
                            )
                          : const Icon(Icons.search_rounded, size: 18, color: AppColors.slate400),
                ),
                onChanged: _onPlaceQueryChanged,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: displayNameField),
                    const SizedBox(width: 12),
                    Expanded(child: placeSearchField),
                  ],
                );
              } else {
                return Column(
                  children: [
                    displayNameField,
                    const SizedBox(height: 10),
                    placeSearchField,
                  ],
                );
              }
            },
          ),

          // Autocomplete suggestions popover
          if (item.suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.sky400.withValues(alpha: 0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.sky400),
                        SizedBox(width: 4),
                        Text(
                          '検索候補（タップで場所データと座標を入力）',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sky400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  ...item.suggestions.map((res) {
                    return InkWell(
                      onTap: () => _selectSuggestion(res),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city_rounded, size: 15, color: AppColors.slate300),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.displayName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate200,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '緯度: ${res.latitude.toStringAsFixed(3)}, 経度: ${res.longitude.toStringAsFixed(3)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.sky400),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Lat / Lon Fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.slate50, fontSize: 13),
                  decoration: _inputDecoration('緯度 (Lat)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '入力必須';
                    final val = double.tryParse(v.trim());
                    if (val == null || val < -90 || val > 90) return '-90~90';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.lonCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.slate50, fontSize: 13),
                  decoration: _inputDecoration('経度 (Lon)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '入力必須';
                    final val = double.tryParse(v.trim());
                    if (val == null || val < -180 || val > 180) return '-180~180';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
