import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import 'ui.dart';

class HopelyMark extends StatelessWidget {
  const HopelyMark({super.key, this.size = 36, this.filled = false});
  final double size;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: filled ? hopelyBlue : surfaceHigh,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.spa_outlined,
      color: filled ? Colors.white : hopelyBlue,
      size: size * .55,
    ),
  );
}

class IconWell extends StatelessWidget {
  const IconWell(
    this.icon, {
    super.key,
    this.size = 48,
    this.radius = 16,
    this.background = skySoft,
    this.foreground = hopelyBlue,
  });
  final IconData icon;
  final double size;
  final double radius;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(icon, color: foreground, size: size * .46),
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
      color: inverse ? Colors.white.withValues(alpha: .16) : surfaceHighest,
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
              height: 16 / 12,
              color: inverse ? Colors.white : hopelyBlue,
              fontWeight: FontWeight.w500,
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
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skySoft, surfaceContainer, Colors.white],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: hopelyCardShadow,
    ),
    child: child,
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
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: mutedInk, size: 18),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: mutedInk,
              fontWeight: FontWeight.w500,
            ),
          ),
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
        const Icon(Icons.lock_outline, color: hopelyBlue, size: 18),
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
              backgroundColor: surfaceHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    ),
  );
}

class CareHero extends StatelessWidget {
  const CareHero({super.key, this.compact = false, this.icon = Icons.favorite});
  final bool compact;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 160 : 240,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const RadialGradient(
        colors: [Colors.white, primaryFixed, skySoft],
      ),
      boxShadow: hopelyCardShadow,
    ),
    child: Center(
      child: Icon(icon, size: compact ? 64 : 96, color: hopelyBlue),
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

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconWell(icon, size: 40, radius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          const Icon(Icons.chevron_right, color: outlineVariant),
        ],
      ),
    ),
  );
}

String dayGreeting([DateTime? at]) {
  final hour = (at ?? DateTime.now()).hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String firstName(String? full) {
  final value = (full ?? '').trim();
  if (value.isEmpty) return '';
  return value.split(RegExp(r'\s+')).first;
}

String relativeScheduleLabel(DateTime when) {
  final local = when.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time =
      '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  if (day == today) return 'Hari ini • $time WIB';
  if (day == today.add(const Duration(days: 1))) return 'Besok • $time WIB';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} • $time WIB';
}
