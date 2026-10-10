import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const patientTabPaths = [
  '/home',
  '/treatment',
  '/chat',
  '/insights',
  '/profile',
];

/// Select a main tab with one shell, including from a detail page above it.
/// Pushing that same shell again would duplicate its page/navigator key.
/// Secondary pages keep a back stack so forms can return to their caller.
void openAppDestination(BuildContext context, String location) {
  if (patientTabPaths.contains(Uri.parse(location).path)) {
    context.go(location);
  } else {
    context.push<void>(location);
  }
}
