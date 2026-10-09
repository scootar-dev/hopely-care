import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api.dart';
import '../theme/theme.dart';
import '../widgets/stitch.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/activities/tools_screen.dart';
import '../../features/caregiver/support_alert_screen.dart';
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
  final session = ref.read(sessionProvider);
  final router = GoRouter(
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
        '/onboarding',
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
      if (!session.caregiver &&
          (path == '/caregiver' || path.startsWith('/caregiver/'))) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, s) => const OnboardingScreen()),
      GoRoute(path: '/tools', builder: (_, s) => const ToolsScreen()),
      GoRoute(
        path: '/caregiver/connect',
        builder: (_, s) => const CaregiverConnectScreen(),
      ),
      GoRoute(
        path: '/caregiver/alerts/:id',
        builder: (_, s) =>
            SupportAlertScreen(notificationId: s.pathParameters['id']!),
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
      GoRoute(
        path: '/checkin/saved',
        builder: (_, s) => const CheckinSavedScreen(),
      ),
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
          GoRoute(
            path: '/chat',
            builder: (_, s) =>
                ChatScreen(initialPrompt: s.uri.queryParameters['prompt']),
          ),
          GoRoute(path: '/insights', builder: (_, s) => const InsightsScreen()),
          GoRoute(path: '/profile', builder: (_, s) => const SettingsScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
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
        centerTitle: false,
        leading: caregiver
            ? const BackHomeButton(fallback: '/caregiver')
            : const Padding(padding: EdgeInsets.all(10), child: HopelyMark()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hopely Care',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            Text(
              const {
                    '/home': 'Beranda',
                    '/treatment': 'Perjalanan',
                    '/chat': 'Hopely AI',
                    '/insights': 'Insight',
                    '/profile': 'Profil',
                  }[path] ??
                  '',
              style: const TextStyle(fontSize: 11, color: mutedInk),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifikasi',
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: pillBlue,
              child: Icon(Icons.person_outline, size: 20, color: hopelyBlue),
            ),
            tooltip: 'Profil',
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
                  label: 'Insight',
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
