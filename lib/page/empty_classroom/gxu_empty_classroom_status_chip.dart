import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/page/empty_classroom/gxu_empty_classroom_state.dart';

class GxuEmptyClassroomStatusChip extends StatelessWidget {
  final GxuEmptyClassroomCell cell;

  const GxuEmptyClassroomStatusChip({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (backgroundColor, textColor) = _colorsOf(scheme, cell.state);
    final content = Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cell.header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cell.shortLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return InkWell(
      onTap: cell.hasDetail ? () => _showDetailSheet(context) : null,
      borderRadius: BorderRadius.circular(16),
      child: _wrapTooltipIfNeeded(context, content),
    );
  }

  Future<void> _showDetailSheet(BuildContext context) async {
    final state = context.read<GxuEmptyClassroomState>();
    final detailFuture = state.loadCellDetail(cell);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: FutureBuilder<String>(
            future: detailFuture,
            builder: (context, snapshot) {
              return _DetailContent(cell: cell, snapshot: snapshot);
            },
          ),
        ),
      ),
    );
  }

  Widget _wrapTooltipIfNeeded(BuildContext context, Widget child) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return Tooltip(message: "${cell.header}：${cell.value}", child: child);
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return child;
    }
  }

  (Color, Color) _colorsOf(
    ColorScheme scheme,
    GxuEmptyClassroomCellState state,
  ) {
    switch (state) {
      case GxuEmptyClassroomCellState.available:
        return (
          scheme.primaryContainer.withValues(alpha: 0.78),
          scheme.onPrimaryContainer,
        );
      case GxuEmptyClassroomCellState.occupied:
        return (
          scheme.errorContainer.withValues(alpha: 0.55),
          scheme.onErrorContainer,
        );
      case GxuEmptyClassroomCellState.unavailable:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
      case GxuEmptyClassroomCellState.unknown:
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
  }
}

class _DetailContent extends StatelessWidget {
  final GxuEmptyClassroomCell cell;
  final AsyncSnapshot<String> snapshot;

  const _DetailContent({required this.cell, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "empty_classroom.detail_title"),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(cell.header, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snapshot.hasError)
            Text(snapshot.error.toString())
          else
            SelectableText(snapshot.data ?? cell.value),
        ],
      ),
    );
  }
}
