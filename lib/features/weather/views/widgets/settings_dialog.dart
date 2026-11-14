import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/location_config.dart';
import 'settings/location_edit_card.dart';

/// 地点設定モーダルダイアログ
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

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<LocationEditItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.locations.map((loc) {
      return LocationEditItem(
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
        LocationEditItem(
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // タブ表示名が空欄の場合は、場所検索の地名を自動適用
    for (final item in _items) {
      if (item.nameCtrl.text.trim().isEmpty) {
        final place = item.placeNameCtrl.text.trim();
        if (place.isNotEmpty) {
          item.nameCtrl.text = place;
        }
      }
    }

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
                          LocationEditCard(
                            key: ValueKey(_items[i].id),
                            item: _items[i],
                            index: i,
                            canRemove: _items.length > 1,
                            onRemove: () => _removeLocation(i),
                          ),
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
}
