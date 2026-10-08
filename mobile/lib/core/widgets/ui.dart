import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../api/api.dart';

class CareCard extends StatelessWidget {
  const CareCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFF0F2F0)),
    ),
    child: child,
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: ListView(padding: const EdgeInsets.all(20), children: children),
    ),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class ActionLink extends StatelessWidget {
  const ActionLink(
    this.label,
    this.route, {
    super.key,
    this.icon = Icons.arrow_forward,
  });
  final String label, route;
  final IconData icon;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.push(route),
    icon: Icon(icon, size: 20),
    label: Text(label),
  );
}

class MockNotice extends StatelessWidget {
  const MockNotice(this.metadata, {super.key});
  final dynamic metadata;
  @override
  Widget build(BuildContext context) =>
      metadata is Map && metadata['mode'] == 'mock'
      ? const CareCard(
          color: peach,
          padding: 12,
          child: Text(
            'Mode demo offline • Respons simulasi, bukan hasil AI nyata.',
          ),
        )
      : const SizedBox.shrink();
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.error, {super.key, this.retry});
  final Object error;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => CareCard(
    color: peach,
    child: Column(
      children: [
        Text(friendlyError(error)),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

class DataPage extends StatefulWidget {
  const DataPage({super.key, required this.load, required this.builder});
  final Future<dynamic> Function() load;
  final Widget Function(dynamic value, VoidCallback reload) builder;
  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  late Future<dynamic> future;
  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  void reload() => setState(() {
    future = widget.load();
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return PageBody(
          children: [ErrorNotice(snapshot.error!, retry: reload)],
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          reload();
          await future;
        },
        child: widget.builder(snapshot.data, reload),
      );
    },
  );
}

class MetricSelector extends StatelessWidget {
  const MetricSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.highIsGood = true,
    this.icon = Icons.favorite_outline,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool highIsGood;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: highIsGood ? mint : peach,
                child: Icon(icon, size: 20, color: forest),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Semantics(
                    selected: value == i + 1,
                    label: '$label, ${i + 1} dari 5',
                    child: Material(
                      color: value == i + 1
                          ? (highIsGood ? mint : peach)
                          : const Color(0xFFF1F4F2),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onChanged(i + 1),
                        child: SizedBox(
                          height: 56,
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            highIsGood
                ? '1: Sangat rendah                 5: Sangat baik'
                : '1: Tidak ada                        5: Sangat tinggi',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
