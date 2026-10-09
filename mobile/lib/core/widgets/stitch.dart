import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import 'ui.dart';

class HopelyMark extends StatelessWidget {
  const HopelyMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: skySoft,
      shape: BoxShape.circle,
      border: Border.all(color: pillBlue),
    ),
    child: Icon(
      Icons.health_and_safety_outlined,
      color: hopelyBlue,
      size: size * .6,
    ),
  );
}

class SoftLabel extends StatelessWidget {
  const SoftLabel(this.text, {super.key, this.icon, this.inverse = false});
  final String text;
  final IconData? icon;
  final bool inverse;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: inverse ? Colors.white.withValues(alpha: .16) : skySoft,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: inverse ? Colors.white : hopelyBlue),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: inverse ? Colors.white : hopelyBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class BlueCard extends StatelessWidget {
  const BlueCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3979F4), Color(0xFF0049D6), Color(0xFF4466C8)],
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: hopelyBlue.withValues(alpha: .15),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: child,
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.action,
    this.onTap,
    this.icon,
  });
  final String title;
  final String? action;
  final VoidCallback? onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 14),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: hopelyBlue, size: 22),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class PrivacyNote extends StatelessWidget {
  const PrivacyNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => CareCard(
    color: skySoft,
    padding: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, color: hopelyBlue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class ScoreBar extends StatelessWidget {
  const ScoreBar(this.label, this.value, {super.key, this.color = hopelyBlue});
  final String label;
  final num? value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value == null
                  ? 'Belum tercatat'
                  : '${value!.toStringAsFixed(1)} / 5',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (value != null)
          Semantics(
            label: '$label ${value!.toStringAsFixed(1)} dari 5',
            child: LinearProgressIndicator(
              value: value!.toDouble().clamp(0, 5) / 5,
              minHeight: 8,
              color: color,
              backgroundColor: pillBlue,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    ),
  );
}

class CareHero extends StatelessWidget {
  const CareHero({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 190 : 275,
    margin: const EdgeInsets.symmetric(vertical: 20),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [Colors.white, Color(0xFFE2E9FF), canvas],
      ),
    ),
    child: Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: compact ? 140 : 205,
            height: compact ? 140 : 205,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: hopelyBlue.withValues(alpha: .12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Icon(
            Icons.volunteer_activism_outlined,
            size: compact ? 82 : 120,
            color: hopelyBlue,
          ),
          if (!compact)
            const Positioned(
              bottom: 4,
              child: SoftLabel(
                'Ruang untuk didengarkan',
                icon: Icons.favorite_outline,
              ),
            ),
        ],
      ),
    ),
  );
}

class BackHomeButton extends StatelessWidget {
  const BackHomeButton({super.key, this.fallback = '/home'});
  final String fallback;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Kembali',
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
  );
}
