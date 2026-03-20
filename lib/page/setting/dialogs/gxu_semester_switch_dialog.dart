import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart' as i18n;
import 'package:watermeter/model/gxu_ids/gxu_semester_option.dart';
import 'package:watermeter/repository/gxu_ids/gxu_classtable_session.dart';
import 'package:watermeter/repository/preference.dart' as pref;

class GxuSemesterSwitchDialog extends StatefulWidget {
  const GxuSemesterSwitchDialog({super.key});

  @override
  State<GxuSemesterSwitchDialog> createState() =>
      _GxuSemesterSwitchDialogState();
}

class _GxuSemesterSwitchDialogState extends State<GxuSemesterSwitchDialog> {
  bool _loading = false;
  String? _error;
  List<GxuSemesterOption> _options = const [];
  String _currentCode = "";
  String _selectedCode = "";
  String _initialCode = "";
  bool _initialIsUserDefined = false;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await GxuClasstableSession().getSemesterOptions();
      final currentOption = options.firstWhere(
        (item) => item.isSelected,
        orElse: () => options.first,
      );
      final storedCode = pref.getString(pref.Preference.currentSemester);
      final isUserDefined = pref.getBool(pref.Preference.isUserDefinedSemester);
      final selectedCode =
          isUserDefined && options.any((item) => item.code == storedCode)
          ? storedCode
          : currentOption.code;
      if (!mounted) {
        return;
      }
      setState(() {
        _options = options;
        _currentCode = currentOption.code;
        _selectedCode = selectedCode;
        _initialCode = selectedCode;
        _initialIsUserDefined = isUserDefined;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: i18n.I18nText('classtable.semester_switcher.choose_semester'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            _buildHintCard(context),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: i18n.I18nText('cancel'),
        ),
        TextButton(
          onPressed: _loading || _options.isEmpty ? null : _confirmSelection,
          child: i18n.I18nText('confirm'),
        ),
      ],
    );
  }

  Widget _buildHintCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.FlutterI18n.translate(
              context,
              'classtable.semester_switcher.follow_current_hint',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            i18n.FlutterI18n.translate(
              context,
              'classtable.semester_switcher.approximate_hint',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadSemesters,
              child: i18n.I18nText('click_to_refresh'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final option = _options[index];
        final selected = option.code == _selectedCode;
        return Material(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _selectedCode = option.code),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.label),
                        const SizedBox(height: 4),
                        Text(
                          option.code,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (option.code == _currentCode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        i18n.FlutterI18n.translate(
                          context,
                          'classtable.semester_switcher.current_semester',
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSelection() async {
    final isUserDefined = _selectedCode != _currentCode;
    final isSameChoice =
        _selectedCode == _initialCode && isUserDefined == _initialIsUserDefined;
    if (isSameChoice) {
      Navigator.of(context).pop(false);
      return;
    }
    await pref.setString(pref.Preference.currentSemester, _selectedCode);
    await pref.setBool(pref.Preference.isUserDefinedSemester, isUserDefined);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
