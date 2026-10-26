import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ActivityImage extends StatelessWidget {
  const ActivityImage({super.key, this.url, this.height = 170});
  final dynamic url;
  final double height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: double.infinity,
      color: skySoft,
      child: const Icon(Icons.self_improvement, size: 64, color: hopelyBlue),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url is String && (url as String).startsWith('https://')
          ? Image.network(
              url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => fallback,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : fallback,
            )
          : fallback,
    );
  }
}
