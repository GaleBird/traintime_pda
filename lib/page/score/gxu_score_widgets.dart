import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxu_ids/gxu_score.dart';
import 'package:watermeter/page/score/gxu_score_entry_widgets.dart';
import 'package:watermeter/page/score/gxu_score_state.dart';

class GxuScoreArchiveCard extends StatelessWidget {
  final GxuScoreProfile profile;

  const GxuScoreArchiveCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.95),
                scheme.primaryContainer.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ArchiveHeader(profile: profile)),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 250,
                      child: _ArchiveMetricPanel(profile: profile),
                    ),
                  ],
                )
              else ...[
                _ArchiveHeader(profile: profile),
                const SizedBox(height: 12),
                _ArchiveMetricPanel(profile: profile),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoPill(
                    text: "${profile.programLevel} · ${profile.studentType}",
                  ),
                  _InfoPill(
                    text:
                        "${FlutterI18n.translate(context, "score.gxu_page.required_credit")}: ${profile.requiredCredits}",
                  ),
                  _InfoPill(
                    text:
                        "${FlutterI18n.translate(context, "score.gxu_page.selected_credit")}: ${profile.selectedCredits}",
                  ),
                  _InfoPill(text: profile.generatedAt),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArchiveHeader extends StatelessWidget {
  final GxuScoreProfile profile;

  const _ArchiveHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FlutterI18n.translate(context, "score.gxu_page.archive_title"),
          style: TextStyle(
            color: scheme.onPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          profile.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${profile.major} · ${profile.college}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onPrimary.withValues(alpha: 0.86),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          profile.studentId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onPrimary.withValues(alpha: 0.74),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ArchiveMetricPanel extends StatelessWidget {
  final GxuScoreProfile profile;

  const _ArchiveMetricPanel({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ArchiveMetric(
          label: FlutterI18n.translate(
            context,
            "score.gxu_page.weighted_average",
          ),
          value: profile.weightedAverage,
        ),
        _ArchiveMetric(
          label: FlutterI18n.translate(context, "score.gxu_page.average_gpa"),
          value: profile.averageGpa,
        ),
        _ArchiveMetric(
          label: FlutterI18n.translate(context, "score.gxu_page.earned_credit"),
          value: profile.earnedCredits,
        ),
        _ArchiveMetric(
          label: FlutterI18n.translate(context, "score.gxu_page.degree_credit"),
          value: profile.degreeCredits,
        ),
      ],
    );
  }
}

class GxuSemesterFilters extends StatelessWidget {
  final GxuScoreState state;

  const GxuSemesterFilters({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(FlutterI18n.translate(context, "score.all_semester")),
              selected: state.selectedSemesterCode.isEmpty,
              onSelected: (_) => state.selectedSemesterCode = "",
            ),
          ),
          ...state.semesterCodes.map(
            (code) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(state.semesterLabelOf(code)),
                selected: state.selectedSemesterCode == code,
                onSelected: (_) => state.selectedSemesterCode = code,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GxuSemesterSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<GxuScoreEntry> entries;
  final GxuScoreState state;

  const GxuSemesterSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => GxuScoreEntryCard(
              entry: entry,
              isSelectMode: state.isSelectMode,
              isSelected: state.isEntrySelected(entry),
              onTap: () {
                if (state.isSelectMode) {
                  state.toggleEntrySelection(entry);
                  return;
                }
                showGxuScoreDetail(context, entry);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ArchiveMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 121,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.76),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: scheme.onPrimary, fontSize: 12, height: 1.1),
      ),
    );
  }
}
