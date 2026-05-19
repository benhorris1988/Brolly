import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/env/env.dart';
import '../../data/repositories/warnings_repository.dart';
import '../../domain/models/warning.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';

final FutureProvider<List<SevereWarning>> activeWarningsProvider =
    FutureProvider<List<SevereWarning>>(
        (Ref ref) => ref.watch(warningsRepositoryProvider).getActiveWarnings());

class WarningsScreen extends ConsumerWidget {
  const WarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SevereWarning>> data =
        ref.watch(activeWarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warnings'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeWarningsProvider),
          ),
        ],
      ),
      body: !Env.hasMetOfficeKey
          ? const _NoKeyState()
          : data.when(
              loading: () => const LoadingView(),
              error: (Object e, StackTrace _) => ErrorView(
                message: 'Could not load warnings.\n$e',
                onRetry: () => ref.invalidate(activeWarningsProvider),
              ),
              data: (List<SevereWarning> list) {
                if (list.isEmpty) {
                  return const _AllClearState();
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(activeWarningsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext _, int i) =>
                        _WarningCard(warning: list[i]),
                  ),
                );
              },
            ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning});
  final SevereWarning warning;

  @override
  Widget build(BuildContext context) {
    final Color severityColor = warning.severity.color;
    final DateFormat fmt = DateFormat('EEE d MMM, HH:mm');

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: severityColor, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    warning.severity.label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  warning.type.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(warning.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${fmt.format(warning.validFrom)} → ${fmt.format(warning.validTo)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (warning.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(warning.description),
            ],
            if (warning.regions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: warning.regions.map((String r) {
                  return Chip(
                    label: Text(r),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllClearState extends StatelessWidget {
  const _AllClearState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check_circle_outline,
              size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text('All clear', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('No active UK severe weather warnings.'),
        ],
      ),
    );
  }
}

class _NoKeyState extends StatelessWidget {
  const _NoKeyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.key_off_outlined,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('No Met Office key',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Severe weather warnings need a Met Office DataHub API key. '
              'See the README for setup.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
