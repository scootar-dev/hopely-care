import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../api/api.dart';

class CareCard extends StatelessWidget {
  const CareCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 22,
    this.radius = 24,
    this.borderColor,
  });
  final Widget child;
  final Color color;
  final double padding;
  final double radius;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? const Color(0xFFEDEDFC)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF25315F).withOpacity(0.07),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
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
      constraints: const BoxConstraints(maxWidth: 620),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [canvas, Color(0xFFF8F6FF), canvas],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: children,
        ),
      ),
    ),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.title, this.subtitle, {super.key, this.badge});
  final String title, subtitle;
  final String? badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          _SoftBadge(label: badge!),
          const SizedBox(height: 12),
        ],
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: const ShapeDecoration(color: lavender, shape: StadiumBorder()),
    child: Text(
      label,
      style: const TextStyle(color: Color(0xFF351B8A), fontWeight: FontWeight.w800),
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
    icon: Icon(icon, size: 19),
    label: Text(label),
    style: TextButton.styleFrom(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: const StadiumBorder(),
    ),
  );
}

class MockNotice extends StatelessWidget {
  const MockNotice(this.metadata, {super.key});
  final dynamic metadata;
  @override
  Widget build(BuildContext context) =>
      metadata is Map && metadata['mode'] == 'mock'
      ? const CareCard(
          color: warningSoft,
          padding: 14,
          radius: 18,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: hopelyBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mode demo offline - respons simulasi, bukan hasil AI nyata.',
                ),
              ),
            ],
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
    color: warningSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD33131)),
            const SizedBox(width: 10),
            Expanded(child: Text(friendlyError(error))),
          ],
        ),
        if (retry != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('Coba lagi')),
        ],
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
        color: hopelyBlue,
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
    final activeColor = highIsGood ? lavender : warningSoft;
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: activeColor,
                child: Icon(icon, size: 21, color: hopelyBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(5, (i) {
              final selected = value == i + 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Semantics(
                    selected: selected,
                    label: '$label, ${i + 1} dari 5',
                    child: Material(
                      color: selected ? activeColor : const Color(0xFFF5F6FE),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onChanged(i + 1),
                        child: SizedBox(
                          height: 58,
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selected ? hopelyBlue : ink,
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
          const SizedBox(height: 10),
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
