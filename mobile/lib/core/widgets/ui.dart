import 'package:flutter/material.dart';

import '../routing/navigation.dart';
import '../theme/theme.dart';
import '../api/api.dart';

class CareCard extends StatelessWidget {
  const CareCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
    this.radius = 20,
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
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: .45),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF25315F).withValues(alpha: 0.025),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
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
            colors: [canvas, canvas, canvas],
          ),
        ),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          physics: const AlwaysScrollableScrollPhysics(),
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
      style: const TextStyle(
        color: Color(0xFF351B8A),
        fontWeight: FontWeight.w800,
      ),
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
    onPressed: () => openAppDestination(context, route),
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
    this.mood = false,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool highIsGood;
  final IconData icon;
  final bool mood;
  @override
  Widget build(BuildContext context) {
    const activeColor = hopelyBlue;
    return CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: skySoft,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final size = ((constraints.maxWidth - 24) / 5).clamp(48.0, 100.0);
              return Wrap(
                spacing: 6,
                runSpacing: 8,
                children: List.generate(5, (i) {
                  final selected = value == i + 1;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '$label, ${i + 1} dari 5',
                    child: SizedBox(
                      width: size,
                      child: Material(
                        color: selected ? activeColor : skySoft,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onChanged(i + 1),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : ink,
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
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                highIsGood ? '1: Sangat rendah' : '1: Tidak ada',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                highIsGood ? '5: Sangat baik' : '5: Sangat tinggi',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
