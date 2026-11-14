import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../models/location_config.dart';

class SettingsDialog extends StatefulWidget {
  final LocationConfig leftLocation;
  final LocationConfig rightLocation;
  final Future<void> Function(LocationConfig left, LocationConfig right) onSave;
  final Future<void> Function() onReset;

  const SettingsDialog({
    super.key,
    required this.leftLocation,
    required this.rightLocation,
    required this.onSave,
    required this.onReset,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _leftNameCtrl;
  late final TextEditingController _leftLatCtrl;
  late final TextEditingController _leftLonCtrl;

  late final TextEditingController _rightNameCtrl;
  late final TextEditingController _rightLatCtrl;
  late final TextEditingController _rightLonCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _leftNameCtrl = TextEditingController(text: widget.leftLocation.name);
    _leftLatCtrl = TextEditingController(text: widget.leftLocation.lat.toString());
    _leftLonCtrl = TextEditingController(text: widget.leftLocation.lon.toString());

    _rightNameCtrl = TextEditingController(text: widget.rightLocation.name);
    _rightLatCtrl = TextEditingController(text: widget.rightLocation.lat.toString());
    _rightLonCtrl = TextEditingController(text: widget.rightLocation.lon.toString());
  }

  @override
  void dispose() {
    _leftNameCtrl.dispose();
    _leftLatCtrl.dispose();
    _leftLonCtrl.dispose();
    _rightNameCtrl.dispose();
    _rightLatCtrl.dispose();
    _rightLonCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newLeft = LocationConfig(
        id: 'left',
        name: _leftNameCtrl.text.trim(),
        lat: double.parse(_leftLatCtrl.text.trim()),
        lon: double.parse(_leftLonCtrl.text.trim()),
      );
      final newRight = LocationConfig(
        id: 'right',
        name: _rightNameCtrl.text.trim(),
        lat: double.parse(_rightLatCtrl.text.trim()),
        lon: double.parse(_rightLonCtrl.text.trim()),
      );

      await widget.onSave(newLeft, newRight);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('地点設定をリセットし、local_config.json または初期デフォルト値（東京・大阪）に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red400),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_outlined, color: AppColors.sky400, size: 26),
                      const SizedBox(width: 12),
                      const Text(
                        '地点設定（プライベート設定）',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate50,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.slate400),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '左右2地点の表示名・緯度・経度を設定します。設定値は端末ローカルに安全に保存されます。',
                    style: TextStyle(fontSize: 13, color: AppColors.slate400),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 500;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLocationFields('地点1（左側）', _leftNameCtrl, _leftLatCtrl, _leftLonCtrl)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildLocationFields('地点2（右側）', _rightNameCtrl, _rightLatCtrl, _rightLonCtrl)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildLocationFields('地点1（左側）', _leftNameCtrl, _leftLatCtrl, _leftLonCtrl),
                            const SizedBox(height: 20),
                            _buildLocationFields('地点2（右側）', _rightNameCtrl, _rightLatCtrl, _rightLonCtrl),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('初期値に戻す'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate300,
                          side: const BorderSide(color: AppColors.slate600),
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
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slate950),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('保存して再取得'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sky400,
                          foregroundColor: AppColors.slate950,
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
      ),
    );
  }

  Widget _buildLocationFields(
    String sectionTitle,
    TextEditingController nameCtrl,
    TextEditingController latCtrl,
    TextEditingController lonCtrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.sky400,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameCtrl,
            decoration: _inputDecoration('地点名（例: 自宅, 会社）'),
            validator: (v) => (v == null || v.trim().isEmpty) ? '地点名を入力してください' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: latCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration('緯度 (Latitude)', hint: '例: 35.6895'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '緯度を入力してください';
              final val = double.tryParse(v.trim());
              if (val == null || val < -90 || val > 90) return '-90 〜 90 の数値を指定してください';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: lonCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration('経度 (Longitude)', hint: '例: 139.6917'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '経度を入力してください';
              final val = double.tryParse(v.trim());
              if (val == null || val < -180 || val > 180) return '-180 〜 180 の数値を指定してください';
              return null;
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      labelStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.slate600, fontSize: 13),
      filled: true,
      fillColor: AppColors.slate900,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.sky400, width: 1.5),
      ),
    );
  }
}
