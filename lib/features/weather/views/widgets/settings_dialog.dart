import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/location_config.dart';
import '../../services/geocoding_service.dart';

class SettingsDialog extends StatefulWidget {
  final List<LocationConfig> locations;
  final Future<void> Function(List<LocationConfig> newLocations) onSave;
  final Future<void> Function() onReset;

  const SettingsDialog({
    super.key,
    required this.locations,
    required this.onSave,
    required this.onReset,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _LocationEditItem {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController placeNameCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  List<GeocodingResult> suggestions = [];
  bool isSearching = false;
  Timer? debounceTimer;

  _LocationEditItem({
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

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<_LocationEditItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.locations.map((loc) {
      return _LocationEditItem(
        id: loc.id,
        name: loc.name,
        placeName: loc.placeName,
        lat: loc.lat,
        lon: loc.lon,
      );
    }).toList();

    if (_items.isEmpty) {
      _addNewLocation();
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewLocation() {
    setState(() {
      _items.add(
        _LocationEditItem(
          id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
          name: '',
          placeName: '',
          lat: 35.6895,
          lon: 139.6917,
        ),
      );
    });
  }

  void _removeLocation(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('最低1つの地点が必要です'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  void _onPlaceQueryChanged(_LocationEditItem item, String query) {
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

  void _selectSuggestion(_LocationEditItem item, GeocodingResult result) {
    setState(() {
      item.placeNameCtrl.text = result.displayName;
      item.latCtrl.text = result.latitude.toStringAsFixed(4);
      item.lonCtrl.text = result.longitude.toStringAsFixed(4);
      // Auto-populate custom name if it was empty
      if (item.nameCtrl.text.trim().isEmpty) {
        item.nameCtrl.text = result.name;
      }
      item.suggestions = [];
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newLocations = _items.map((item) {
        final name = item.nameCtrl.text.trim();
        final placeName = item.placeNameCtrl.text.trim();
        return LocationConfig(
          id: item.id,
          name: name.isNotEmpty ? name : (placeName.isNotEmpty ? placeName : '地点'),
          placeName: placeName,
          lat: double.parse(item.latCtrl.text.trim()),
          lon: double.parse(item.lonCtrl.text.trim()),
        );
      }).toList();

      await widget.onSave(newLocations);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorderLight, width: 0.8),
        ),
        title: const Text('設定をリセット', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'すべての地点設定をリセットし、初期デフォルト値に戻しますか？',
          style: TextStyle(color: AppColors.slate300, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル', style: TextStyle(color: AppColors.slate400)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tempHot,
              foregroundColor: Colors.white,
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await widget.onReset();
        if (mounted) Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.glassBorderLight, width: 0.8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.sky400.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined, color: AppColors.sky400, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '登録地点の管理',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate50,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          '表示名と場所データを自由に設定・追加できます',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.sky400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Location Items List (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (int i = 0; i < _items.length; i++) ...[
                          _buildLocationCard(_items[i], i),
                          const SizedBox(height: 12),
                        ],

                        // Add Location Button
                        OutlinedButton.icon(
                          onPressed: _addNewLocation,
                          icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                          label: const Text('新しい地点を追加'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.sky400,
                            side: const BorderSide(color: AppColors.sky400, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.glassBorder),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('初期値に戻す'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate300,
                        side: const BorderSide(color: AppColors.slate700),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _handleReset,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('キャンセル', style: TextStyle(color: AppColors.slate400)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slate950),
                            )
                          : const Icon(Icons.check_rounded, size: 17),
                      label: const Text('保存して再取得'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sky400,
                        foregroundColor: AppColors.slate950,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(_LocationEditItem item, int index) {
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
                  '地点 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sky400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.nameCtrl.text.isNotEmpty ? item.nameCtrl.text : '（未設定）',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate200,
                ),
              ),
              const Spacer(),
              if (_items.length > 1)
                IconButton(
                  tooltip: 'この地点を削除',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.tempHot),
                  onPressed: () => _removeLocation(index),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Two-column layout for Display Name & Place Search
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 460;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDisplayNameField(item)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPlaceSearchField(item)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDisplayNameField(item),
                    const SizedBox(height: 10),
                    _buildPlaceSearchField(item),
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
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: AppColors.sky400),
                        const SizedBox(width: 4),
                        const Text(
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
                      onTap: () => _selectSuggestion(item, res),
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

  Widget _buildDisplayNameField(_LocationEditItem item) {
    return TextFormField(
      controller: item.nameCtrl,
      style: const TextStyle(color: AppColors.slate50, fontSize: 13),
      decoration: _inputDecoration('タブ表示名（例: 自宅, 職場）'),
      onChanged: (_) => setState(() {}),
      validator: (v) => (v == null || v.trim().isEmpty) ? '表示名を入力してください' : null,
    );
  }

  Widget _buildPlaceSearchField(_LocationEditItem item) {
    return TextFormField(
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
            : const Icon(Icons.search_rounded, size: 18, color: AppColors.slate400),
      ),
      onChanged: (val) => _onPlaceQueryChanged(item, val),
    );
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
}
