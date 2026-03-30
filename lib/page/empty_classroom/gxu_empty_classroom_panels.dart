import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';
import 'package:watermeter/repository/network_session.dart';

class GxuEmptyClassroomOverviewPanel extends StatelessWidget {
  final GxuEmptyClassroomState state;
  final GxuEmptyClassroomQueryForm form;

  const GxuEmptyClassroomOverviewPanel({
    super.key,
    required this.state,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    final chips = <Widget?>[
      _MetaChip(
        icon: Icons.auto_awesome_mosaic_rounded,
        label: FlutterI18n.translate(context, form.viewType.translationKey),
      ),
      _selectedChip(context, form.selectField("xqdm"), Icons.school_outlined),
      _selectedChip(
        context,
        form.selectField("jxlh"),
        Icons.location_city_outlined,
      ),
      _selectedClassroomsChip(),
      if (result != null)
        _MetaChip(
          icon: Icons.meeting_room_outlined,
          label: FlutterI18n.translate(
            context,
            "empty_classroom.room_count",
            translationParams: {"count": state.totalRowCount.toString()},
          ),
        ),
      if (result != null)
        _MetaChip(
          icon: Icons.schedule_rounded,
          label: FlutterI18n.translate(
            context,
            "empty_classroom.fetched_at",
            translationParams: {"time": _timeTextOf(result.fetchedAt)},
          ),
        ),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.whereType<Widget>().toList(),
      ),
    );
  }

  Widget? _selectedChip(
    BuildContext context,
    GxuEmptyClassroomSelectField? field,
    IconData icon,
  ) {
    if (field == null || field.selectedValue.isEmpty) {
      return null;
    }
    return _MetaChip(icon: icon, label: "${field.label} ${field.displayText}");
  }

  Widget? _selectedClassroomsChip() {
    final field = form.selectField("jsxxid");
    if (field == null || field.selectedValues.isEmpty) {
      return null;
    }
    return _MetaChip(
      icon: Icons.checklist_rounded,
      label: "已选 ${field.selectedValues.length} 间教室",
    );
  }

  String _timeTextOf(DateTime value) {
    final hour = value.hour.toString().padLeft(2, "0");
    final minute = value.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }
}

class GxuEmptyClassroomFilterPanel extends StatelessWidget {
  final GxuEmptyClassroomQueryForm form;
  final GxuEmptyClassroomState state;

  const GxuEmptyClassroomFilterPanel({
    super.key,
    required this.form,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "empty_classroom.filters"),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            FlutterI18n.translate(context, "empty_classroom.query_hint"),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _ViewTypeSelector(form: form, state: state),
          const SizedBox(height: 12),
          _FullWidthSelectTile(
            field: form.selectField("xqdm"),
            state: state,
            helperText: FlutterI18n.translate(
              context,
              "empty_classroom.semester_hint",
            ),
          ),
          const SizedBox(height: 12),
          _ResponsiveRow(
            left: _FullWidthSelectTile(
              field: form.selectField("jxlh"),
              state: state,
              helperText: FlutterI18n.translate(
                context,
                "empty_classroom.building_hint",
              ),
            ),
            right: _FullWidthSelectTile(
              field: form.selectField("jsxxid"),
              state: state,
              helperText: FlutterI18n.translate(
                context,
                "empty_classroom.classroom_hint",
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TimeRangePanel(form: form, state: state),
          const SizedBox(height: 12),
          _AdvancedCard(form: form, state: state),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.resultState == SessionState.fetching
                  ? null
                  : state.refreshResults,
              icon: state.resultState == SessionState.fetching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                FlutterI18n.translate(context, "empty_classroom.query"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewTypeSelector extends StatelessWidget {
  final GxuEmptyClassroomQueryForm form;
  final GxuEmptyClassroomState state;

  const _ViewTypeSelector({required this.form, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "empty_classroom.view_label"),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final viewType in GxuEmptyClassroomViewType.values)
                ChoiceChip(
                  label: Text(
                    FlutterI18n.translate(context, viewType.translationKey),
                  ),
                  selected: form.viewType == viewType,
                  onSelected: (_) => state.updateViewType(viewType),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeRangePanel extends StatelessWidget {
  final GxuEmptyClassroomQueryForm form;
  final GxuEmptyClassroomState state;

  const _TimeRangePanel({required this.form, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "empty_classroom.range_title"),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            FlutterI18n.translate(context, "empty_classroom.range_hint"),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _LabeledRangeRow(
            label: FlutterI18n.translate(context, "empty_classroom.range_week"),
            startField: form.selectField("kszc"),
            endField: form.selectField("jszc"),
            state: state,
          ),
          const SizedBox(height: 10),
          _LabeledRangeRow(
            label: FlutterI18n.translate(
              context,
              "empty_classroom.range_weekday",
            ),
            startField: form.selectField("ksxq"),
            endField: form.selectField("jsxq"),
            state: state,
          ),
          const SizedBox(height: 10),
          _LabeledRangeRow(
            label: FlutterI18n.translate(
              context,
              "empty_classroom.range_period",
            ),
            startField: form.selectField("ksjc"),
            endField: form.selectField("jsjc"),
            state: state,
          ),
        ],
      ),
    );
  }
}

class _LabeledRangeRow extends StatelessWidget {
  final String label;
  final GxuEmptyClassroomSelectField? startField;
  final GxuEmptyClassroomSelectField? endField;
  final GxuEmptyClassroomState state;

  const _LabeledRangeRow({
    required this.label,
    required this.startField,
    required this.endField,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = _CompactSelectTile(
          field: startField,
          title: FlutterI18n.translate(context, "empty_classroom.range_start"),
          state: state,
        );
        final right = _CompactSelectTile(
          field: endField,
          title: FlutterI18n.translate(context, "empty_classroom.range_end"),
          state: state,
        );
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 10),
                  Expanded(child: right),
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _AdvancedCard extends StatefulWidget {
  final GxuEmptyClassroomQueryForm form;
  final GxuEmptyClassroomState state;

  const _AdvancedCard({required this.form, required this.state});

  @override
  State<_AdvancedCard> createState() => _AdvancedCardState();
}

class _AdvancedCardState extends State<_AdvancedCard> {
  static const _animationDuration = Duration(milliseconds: 180);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('gxu_empty_classroom_advanced_filters_toggle'),
            borderRadius: BorderRadius.circular(18),
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FlutterI18n.translate(
                            context,
                            "empty_classroom.advanced_filters",
                          ),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FlutterI18n.translate(
                            context,
                            "empty_classroom.advanced_filters_hint",
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ExpandableSection(
            expanded: _expanded,
            duration: _animationDuration,
            child: _buildExpandedFilters(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResponsiveRow(
            left: _FullWidthSelectTile(
              field: widget.form.selectField("zyqk"),
              state: widget.state,
            ),
            right: _FullWidthSelectTile(
              field: widget.form.selectField("zylx"),
              state: widget.state,
            ),
          ),
          const SizedBox(height: 12),
          _ResponsiveRow(
            left: _TextFieldTile(
              field: widget.form.textField("zws"),
              label: FlutterI18n.translate(context, "empty_classroom.seat_min"),
              onChanged: widget.state.updateText,
            ),
            right: _TextFieldTile(
              field: widget.form.textField("jszws"),
              label: FlutterI18n.translate(context, "empty_classroom.seat_max"),
              onChanged: widget.state.updateText,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }
}

class _ExpandableSection extends StatelessWidget {
  final bool expanded;
  final Duration duration;
  final Widget child;

  const _ExpandableSection({
    required this.expanded,
    required this.duration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final collapsed = value == 0;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: value,
            child: IgnorePointer(
              ignoring: collapsed,
              child: Opacity(opacity: value, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsiveRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _FullWidthSelectTile extends StatelessWidget {
  final GxuEmptyClassroomSelectField? field;
  final GxuEmptyClassroomState state;
  final String? helperText;

  const _FullWidthSelectTile({
    required this.field,
    required this.state,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    if (field == null) {
      return const SizedBox.shrink();
    }
    return _SelectFieldTile(
      field: field!,
      state: state,
      title: field!.label,
      helperText: helperText,
    );
  }
}

class _CompactSelectTile extends StatelessWidget {
  final GxuEmptyClassroomSelectField? field;
  final String title;
  final GxuEmptyClassroomState state;

  const _CompactSelectTile({
    required this.field,
    required this.title,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (field == null) {
      return const SizedBox.shrink();
    }
    return _SelectFieldTile(
      field: field!,
      state: state,
      title: title,
      dense: true,
    );
  }
}

class _SelectFieldTile extends StatelessWidget {
  final GxuEmptyClassroomSelectField field;
  final GxuEmptyClassroomState state;
  final String title;
  final String? helperText;
  final bool dense;

  const _SelectFieldTile({
    required this.field,
    required this.state,
    required this.title,
    this.helperText,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(dense ? 14 : 16),
      onTap: () => _openSheet(context),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 14,
          vertical: dense ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(dense ? 14 : 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: dense ? 4 : 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    field.displayText,
                    maxLines: dense ? 1 : (field.isMulti ? 2 : 1),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: dense ? 6 : 10),
                Icon(
                  field.isMulti
                      ? Icons.playlist_add_check_rounded
                      : Icons.expand_more_rounded,
                  size: dense ? 18 : 20,
                ),
              ],
            ),
            if (helperText != null && helperText!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                helperText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SelectOptionSheet(field: field, title: title),
    );
    if (result != null) {
      state.updateSelect(field.name, result);
    }
  }
}

class _SelectOptionSheet extends StatefulWidget {
  final GxuEmptyClassroomSelectField field;
  final String title;

  const _SelectOptionSheet({required this.field, required this.title});

  @override
  State<_SelectOptionSheet> createState() => _SelectOptionSheetState();
}

class _SelectOptionSheetState extends State<_SelectOptionSheet> {
  late final TextEditingController _searchController;
  late final Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedValues = widget.field.selectedValues.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = _filteredOptions;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: FlutterI18n.translate(
                    context,
                    "empty_classroom.option_search_hint",
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: options.isEmpty
                    ? Center(
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "empty_classroom.option_empty",
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return widget.field.isMulti
                              ? CheckboxListTile(
                                  value: _selectedValues.contains(option.value),
                                  title: Text(option.label),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (_) => _toggleMulti(option.value),
                                )
                              : ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    _singleValue == option.value
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                  ),
                                  title: Text(option.label),
                                  onTap: () => _selectSingle(option.value),
                                );
                        },
                      ),
              ),
              if (widget.field.isMulti) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(_selectedValues.clear),
                      child: Text(
                        FlutterI18n.translate(
                          context,
                          "empty_classroom.clear_selection",
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_selectedValues.toList()),
                      child: Text(FlutterI18n.translate(context, "confirm")),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<GxuEmptyClassroomOption> get _filteredOptions {
    final keyword = _searchController.text.trim().toLowerCase();
    return [
      for (final option in widget.field.options)
        if (_showOption(option, keyword)) option,
    ];
  }

  String get _singleValue {
    if (_selectedValues.isEmpty) {
      return "";
    }
    return _selectedValues.first;
  }

  bool _showOption(GxuEmptyClassroomOption option, String keyword) {
    if (widget.field.isMulti && option.value.isEmpty) {
      return false;
    }
    if (keyword.isEmpty) {
      return true;
    }
    final haystack = "${option.label} ${option.value}".toLowerCase();
    return haystack.contains(keyword);
  }

  void _toggleMulti(String value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
  }

  void _selectSingle(String value) {
    Navigator.of(context).pop(value.isEmpty ? const <String>[] : [value]);
  }
}

class _TextFieldTile extends StatefulWidget {
  final GxuEmptyClassroomTextField? field;
  final String label;
  final void Function(String name, String value) onChanged;

  const _TextFieldTile({
    required this.field,
    required this.label,
    required this.onChanged,
  });

  @override
  State<_TextFieldTile> createState() => _TextFieldTileState();
}

class _TextFieldTileState extends State<_TextFieldTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field?.value ?? "");
  }

  @override
  void didUpdateWidget(covariant _TextFieldTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.field?.value ?? "";
    if (_controller.text == nextValue) {
      return;
    }
    _controller.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    if (field == null) {
      return const SizedBox.shrink();
    }
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) => widget.onChanged(field.name, value),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: FlutterI18n.translate(context, "empty_classroom.optional"),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
