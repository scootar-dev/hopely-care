import 'package:flutter/material.dart';
import '../../features/checkin/record_history_screen.dart';
import '../../features/doctor_summary/summary_history_screen.dart';
import '../../features/knowledge/article_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api.dart';
import '../theme/theme.dart';
import '../widgets/stitch.dart';
import '../widgets/ai_launcher.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/activities/tools_screen.dart';
import '../../features/caregiver/support_alert_screen.dart';
import '../../features/caregiver/quick_help_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/password_screen.dart';
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
import '../widgets/account_action.dart';
import '../../features/community/presentation/community_home.dart';
import '../../features/community/presentation/community_detail.dart';
import '../../features/community/presentation/community_compose.dart';
import '../../features/community/presentation/community_post_detail.dart';
import '../../features/community/presentation/community_safety.dart';
import '../../features/stitch_v2/stitch_v2_detail_screens.dart';

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
        '/forgot-password',
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
          !path.startsWith('/community') &&
          ![
            '/profile',
            '/privacy',
            '/notifications',
            '/data-account',
            '/notification-settings',
          ].contains(path)) {
        return '/caregiver';
      }
      if (!session.caregiver &&
          (path == '/caregiver' || path.startsWith('/caregiver/'))) {
        return '/home';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AiLauncher(child: child),
        routes: [
          GoRoute(path: '/splash', builder: (_, s) => const SplashScreen()),
          GoRoute(
            path: '/onboarding',
            builder: (_, s) => const OnboardingScreen(),
          ),
          GoRoute(path: '/tools', builder: (_, s) => const ToolsScreen()),
          GoRoute(
            path: '/quick-help',
            builder: (_, s) => const QuickHelpScreen(),
          ),
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
          GoRoute(
            path: '/role',
            builder: (_, s) => const RoleSelectionScreen(),
          ),
          GoRoute(path: '/login', builder: (_, s) => const AuthScreen()),
          GoRoute(
            path: '/forgot-password',
            builder: (_, s) => const PasswordScreen(),
          ),
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
            path: '/chat',
            pageBuilder: (context, s) => CustomTransitionPage<void>(
              key: s.pageKey,
              opaque: false,
              barrierDismissible: true,
              barrierColor: Colors.black54,
              barrierLabel: 'Tutup Hopely AI',
              transitionDuration: const Duration(milliseconds: 220),
              reverseTransitionDuration: const Duration(milliseconds: 180),
              transitionsBuilder: (context, animation, secondary, child) =>
                  MediaQuery.disableAnimationsOf(context)
                  ? child
                  : FadeTransition(
                      opacity: animation.drive(
                        CurveTween(curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
              child: SafeArea(
                child: Dialog(
                  insetPadding: const EdgeInsets.all(12),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AccountAction(),
                              IconButton(
                                tooltip: 'Tutup Hopely AI',
                                icon: const Icon(Icons.close),
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/home'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ChatScreen(
                            initialPrompt: s.uri.queryParameters['prompt'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/community/discover',
            builder: (_, s) => const CommunityDiscoveryScreen(),
          ),
          GoRoute(
            path: '/community/mine',
            builder: (_, s) => const MyCommunitiesScreen(),
          ),
          GoRoute(
            path: '/community/feed',
            builder: (_, s) =>
                CommunityFeedScreen(mine: s.uri.queryParameters['mine'] == '1'),
          ),
          GoRoute(
            path: '/community/groups/:id',
            builder: (_, s) =>
                CommunityDetailScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/community/compose',
            builder: (_, s) => CommunityComposeScreen(
              communityId: s.uri.queryParameters['community'],
              postId: s.uri.queryParameters['post'],
            ),
          ),
          GoRoute(
            path: '/community/posts/:id',
            builder: (_, s) =>
                CommunityPostDetailScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/community/safety',
            builder: (_, s) => const CommunitySafetyScreen(),
          ),
          GoRoute(
            path: '/community/preferences',
            builder: (_, s) => const CommunityPreferencesScreen(),
          ),
          GoRoute(
            path: '/community/moderation',
            builder: (_, s) => const CommunityModerationScreen(),
          ),
          GoRoute(
            path: '/checkin/saved',
            builder: (_, s) => const CheckinSavedScreen(),
          ),
          GoRoute(path: '/checkin', builder: (_, s) => const CheckinScreen()),
          GoRoute(
            path: '/history',
            builder: (_, s) => const RecordHistoryScreen(),
          ),
          GoRoute(
            path: '/summary-history',
            builder: (_, s) => const SummaryHistoryScreen(),
          ),
          GoRoute(
            path: '/symptoms',
            builder: (_, s) => const CheckinScreen(symptoms: true),
          ),
          GoRoute(path: '/journal', builder: (_, s) => const JournalScreen()),
          GoRoute(
            path: '/journal/new',
            builder: (_, s) => JournalEditor(
              initialTitle: s.uri.queryParameters['letter'] == '1'
                  ? 'Surat untuk diriku'
                  : '',
            ),
          ),
          GoRoute(
            path: '/journal/:id/reflection',
            builder: (_, s) =>
                JournalReflectionScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/doctor-summary',
            builder: (_, s) => const SummaryScreen(),
          ),
          GoRoute(
            path: '/doctor-summary/new',
            builder: (_, s) => const SummaryScreen(),
          ),
          GoRoute(
            path: '/doctor-summary/:id',
            builder: (_, s) => SavedSummaryScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/activities',
            builder: (_, s) => const ActivitiesScreen(),
          ),
          GoRoute(
            path: '/activities/:id',
            builder: (_, s) => ActivityRouteScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/care-circle',
            builder: (_, s) => const CareCircleScreen(),
          ),
          GoRoute(
            path: '/caregiver',
            builder: (_, s) => const CaregiverScreen(),
          ),
          GoRoute(
            path: '/caregiver/:id',
            builder: (_, s) =>
                CaregiverPatientScreen(patientId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/knowledge',
            builder: (_, s) => const KnowledgeScreen(),
          ),
          GoRoute(
            path: '/knowledge/articles/:id',
            builder: (_, s) => ArticleScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (_, s) => const ProfileEditor(),
          ),
          GoRoute(
            path: '/treatment-profile',
            builder: (_, s) => const TreatmentProfileScreen(),
          ),
          GoRoute(
            path: '/notification-settings',
            builder: (_, s) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: '/data-account',
            builder: (_, s) => const DataAccountScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, s) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/insights/detail',
            builder: (_, s) => InsightDetailScreen(
              days: int.tryParse(s.uri.queryParameters['days'] ?? '') ?? 14,
            ),
          ),
          GoRoute(
            path: '/treatment/new',
            builder: (_, s) => const TreatmentEditor(),
          ),
          GoRoute(
            path: '/treatment/:id',
            builder: (_, s) =>
                TreatmentDetailScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/chat/voice',
            builder: (_, s) => const VoiceAssistantUnavailableScreen(),
          ),
          GoRoute(
            path: '/chat/audio',
            builder: (_, s) =>
                const VoiceAssistantUnavailableScreen(kind: 'audio'),
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
                path: '/community',
                builder: (_, s) => const CommunityHomeScreen(),
              ),
              GoRoute(
                path: '/insights',
                builder: (_, s) => const InsightsScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (_, s) => const SettingsScreen(),
              ),
            ],
          ),
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
    final caregiver = ref.watch(sessionProvider).caregiver;
    final titles = const {
      '/home': 'Beranda',
      '/treatment': 'Perjalanan',
      '/chat': 'Hopely AI',
      '/insights': 'Insight',
      '/profile': 'Profil',
    };
    return Scaffold(
      backgroundColor: canvas,
      appBar: path == '/community'
          ? null
          : AppBar(
              toolbarHeight: 64,
              centerTitle: false,
              leadingWidth: 56,
              leading: caregiver
                  ? const BackHomeButton(fallback: '/caregiver')
                  : const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Center(child: HopelyMark(size: 36)),
                    ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hopely Care',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: tertiaryInk,
                      letterSpacing: 0.24,
                    ),
                  ),
                  Text(
                    titles[path] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      height: 26 / 18,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/quick-help'),
                  icon: const Icon(Icons.support_agent_outlined),
                  tooltip: 'Bantuan cepat',
                ),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_outlined),
                  tooltip: 'Notifikasi',
                ),
                if (path != '/profile')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: const AccountAction(),
                  ),
              ],
            ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: caregiver || MediaQuery.sizeOf(context).width >= 1024
          ? null
          : NavigationBar(
              height: 68,
              backgroundColor: Colors.white,
              indicatorColor: skySoft,
              selectedIndex: switch (path) {
                '/treatment' => 1,
                '/community' => 2,
                '/insights' => 3,
                '/profile' => 4,
                _ => 0,
              },
              onDestinationSelected: (index) => context.go(
                const [
                  '/home',
                  '/treatment',
                  '/community',
                  '/insights',
                  '/profile',
                ][index],
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Perjalanan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Komunitas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Insight',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}
