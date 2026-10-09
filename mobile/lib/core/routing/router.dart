import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api.dart';
import '../theme/theme.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/checkin/checkin_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/ai_companion/chat_screen.dart';
import '../../features/treatment/treatment_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/doctor_summary/summary_screen.dart';
import '../../features/activities/activities_screen.dart';
import '../../features/care_circle/care_circle_screen.dart';
import '../../features/caregiver/caregiver_screen.dart';
import '../../features/knowledge/knowledge_screen.dart';
import '../../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!session.initialized) {
        return path == '/splash' ? null : '/splash';
      }
      if (path == '/splash') {
        return session.loggedIn
            ? (session.caregiver ? '/caregiver' : '/home')
            : '/welcome';
      }
      final public = [
        '/welcome',
        '/login',
        '/register',
        '/role',
      ].contains(path);
      if (!session.loggedIn) {
        return public ? null : '/welcome';
      }
      if (public) {
        return session.caregiver ? '/caregiver' : '/home';
      }
      if (session.needsConsent && path != '/privacy' && path != '/profile') {
        return '/privacy';
      }
      if (session.caregiver &&
          !path.startsWith('/caregiver') &&
          !['/profile', '/privacy', '/notifications'].contains(path)) {
        return '/caregiver';
      }
      if (!session.caregiver && path.startsWith('/caregiver/')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, s) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.spa_outlined, size: 56, color: forest),
                SizedBox(height: 16),
                Text(
                  'Hopely Care',
                  style: TextStyle(fontSize: 28, color: forest),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      GoRoute(path: '/welcome', builder: (_, s) => const WelcomeScreen()),
      GoRoute(path: '/role', builder: (_, s) => const RoleSelectionScreen()),
      GoRoute(path: '/login', builder: (_, s) => const AuthScreen()),
      GoRoute(
        path: '/register',
        builder: (_, s) => AuthScreen(
          register: true,
          initialRole: s.uri.queryParameters['role'] == 'caregiver'
              ? 'CAREGIVER'
              : 'PATIENT',
        ),
      ),
      GoRoute(path: '/privacy', builder: (_, s) => const PrivacyScreen()),
      GoRoute(path: '/checkin', builder: (_, s) => const CheckinScreen()),
      GoRoute(
        path: '/symptoms',
        builder: (_, s) => const CheckinScreen(symptoms: true),
      ),
      GoRoute(path: '/journal', builder: (_, s) => const JournalScreen()),
      GoRoute(
        path: '/doctor-summary',
        builder: (_, s) => const SummaryScreen(),
      ),
      GoRoute(path: '/activities', builder: (_, s) => const ActivitiesScreen()),
      GoRoute(
        path: '/care-circle',
        builder: (_, s) => const CareCircleScreen(),
      ),
      GoRoute(path: '/caregiver', builder: (_, s) => const CaregiverScreen()),
      GoRoute(
        path: '/caregiver/:id',
        builder: (_, s) =>
            CaregiverPatientScreen(patientId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/knowledge', builder: (_, s) => const KnowledgeScreen()),
      GoRoute(path: '/edit-profile', builder: (_, s) => const ProfileEditor()),
      GoRoute(
        path: '/notifications',
        builder: (_, s) => const NotificationsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, s) => const HomeScreen()),
          GoRoute(
            path: '/treatment',
            builder: (_, s) => const TreatmentScreen(),
          ),
          GoRoute(path: '/chat', builder: (_, s) => const ChatScreen()),
          GoRoute(path: '/insights', builder: (_, s) => const InsightsScreen()),
          GoRoute(path: '/profile', builder: (_, s) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const paths = ['/home', '/treatment', '/chat', '/insights', '/profile'];
    final caregiver = ref.watch(sessionProvider).caregiver;
    return Scaffold(
      appBar: AppBar(
        leading: caregiver
            ? IconButton(
                onPressed: () => context.go('/caregiver'),
                icon: const Icon(Icons.arrow_back),
              )
            : const Padding(
                padding: EdgeInsets.all(10),
                child: CircleAvatar(
                  backgroundColor: lavender,
                  child: Icon(Icons.favorite, color: hopelyBlue),
                ),
              ),
        title: const Text('Hopely\nCare'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifikasi',
          ),
        ],
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: caregiver
          ? null
          : NavigationBar(
              selectedIndex: paths.indexOf(path).clamp(0, 4).toInt(),
              onDestinationSelected: (i) => context.go(paths[i]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timeline),
                  label: 'Perjalanan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  label: 'Hopely AI',
                ),
                NavigationDestination(
                  icon: Icon(Icons.health_and_safety_outlined),
                  label: 'Wawasan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}
