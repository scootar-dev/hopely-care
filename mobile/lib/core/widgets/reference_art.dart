import 'package:flutter/material.dart';

/// Displays only decorative artwork from the supplied design. Page controls
/// and text remain native Flutter widgets, not a screenshot of the UI.
class ReferenceArt extends StatelessWidget {
  const ReferenceArt({
    super.key,
    required this.asset,
    required this.imageSize,
    required this.crop,
    this.radius = 28,
  });
  final String asset;
  final Size imageSize;
  final Rect crop;
  final double radius;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: crop.width / crop.height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / crop.width;
          return Stack(
            children: [
              Positioned(
                left: -crop.left * scale,
                top: -crop.top * scale,
                width: imageSize.width * scale,
                height: imageSize.height * scale,
                child: Image.asset(
                  'assets/illustrations/$asset',
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
