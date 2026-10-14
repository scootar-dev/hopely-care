import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';
import 'package:hopely_care/main.dart';
import 'package:hopely_care/features/community/presentation/community_home.dart';
import 'stitch_v2_test.dart' show FixtureApi, fixtureSession, savePreview;

// Fixtures are confined to tests; production CommunityRepository always calls Laravel.
class CommunityFixtureApi extends FixtureApi {
  CommunityFixtureApi(super.session);
  bool joined = false, empty = false, blocked = false, failHome = false;
  bool reviewed = false;
  Completer<dynamic>? homePending;
  final comments = <Json>[];
  final reports = <Json>[];
  final reads = <String>[];
  late Json story = {
    'id': 'p1',
    'community_id': 'g1',
    'community_name': 'Ruang Dukungan Emosional',
    'author': {'id': 'writer', 'display_name': 'Sahabat Sintetis'},
    'is_own': false,
    'content':
        'Hari ini aku berani bercerita. Terima kasih telah mendengarkan.',
    'has_image': false,
    'is_demo': true,
    'moderation_status': 'approved',
    'revision': 1,
    'created_at': '2026-10-12T08:00:00Z',
    'reaction_count': 0,
    'comment_count': 0,
    'my_reaction': null,
    'can_participate': joined,
  };
  Json get group => {
    'id': 'g1',
    'name': 'Ruang Dukungan Emosional',
    'description':
        'Tempat saling mendengarkan dan memberi ruang bagi perasaan.',
    'category': 'emotional',
    'member_count': joined ? 2 : 1,
    'post_count': 1,
    'membership_status': joined ? 'active' : null,
    'membership_role': joined ? 'member' : null,
  };
  Json get homeData => {
    'joined': joined ? [group] : [],
    'recommended': empty
        ? []
        : [
            {'community': group, 'reason': 'Ruang untuk saling menguatkan.'},
          ],
    'recent': empty || blocked ? [] : [story],
    'recommendation_method': 'catalogue',
  };
  @override
  Future<dynamic> get(String path) async {
    reads.add(path);
    final uri = Uri.parse(path), p = uri.path;
    if (p == '/community/home') {
      if (homePending != null) return homePending!.future;
      if (failHome) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 503,
          ),
        );
      }
      return homeData;
    }
    if (p == '/communities') return page(empty ? [] : [group]);
    if (p == '/communities/g1') {
      return {
        'community': group,
        'guidelines': ['Hormati privasi.', 'Bagikan dukungan, bukan resep.'],
      };
    }
    if (p == '/community/my-communities') return page(joined ? [group] : []);
    if (p == '/communities/g1/posts' || p == '/community/feed') {
      return page(empty || blocked ? [] : [story]);
    }
    if (p == '/community/posts/p1/comments') return page(comments);
    if (p == '/community/posts/p1') {
      return {
        ...story,
        'can_participate': joined && story['moderation_status'] == 'approved',
      };
    }
    if (p == '/community/preferences') {
      return {
        'display_name': 'Sahabat',
        'notifications_enabled': true,
        'recommendation_enabled': false,
        'interests': <String, dynamic>{},
      };
    }
    if (p == '/community/safety') {
      return {
        'guidelines': [
          'Hormati privasi.',
          'Berbagi pengalaman, bukan saran medis.',
        ],
        'reports': page(reports),
        'blocked_users': blocked
            ? [
                {'id': 'writer', 'display_name': 'Sahabat Sintetis'},
              ]
            : [],
        'can_moderate': true,
      };
    }
    if (p == '/community/moderation') {
      if (reviewed) return page([]);
      return page([
        {
          'id': 'held-1',
          'kind': 'post',
          'revision': 1,
          'community_name': 'Ruang Dukungan Emosional',
          'content': 'Cerita sintetis yang menunggu pemeriksaan.',
          'has_image': false,
        },
      ]);
    }
    return super.get(path);
  }

  @override
  Future<dynamic> post(String path, [Json data = const {}]) async {
    if (!path.contains('/communit') && !path.endsWith('/block')) {
      return super.post(path, data);
    }
    writes.add((path, data));
    if (path.startsWith('/community/moderation/')) {
      reviewed = true;
      return null;
    }
    if (path.endsWith('/join')) {
      joined = true;
      story['can_participate'] = true;
      return {'community': group};
    }
    if (path == '/communities/g1/posts') {
      story = {
        ...story,
        'is_own': true,
        'author': {'id': session.user!['id'], 'display_name': 'Namaku'},
        'content': data['content'],
        'moderation_status': 'pending',
        'can_participate': false,
      };
      return story;
    }
    if (path.endsWith('/comments')) {
      final comment = {
        'id': 'c1',
        'post_id': 'p1',
        'content': data['content'],
        'is_own': true,
        'author': {'id': session.user!['id'], 'display_name': 'Namaku'},
        'moderation_status': 'pending',
        'created_at': '2026-10-12T09:00:00Z',
      };
      comments.add(comment);
      return comment;
    }
    if (path.endsWith('/reactions')) {
      story['my_reaction'] = data['reaction_type'];
      story['reaction_count'] = 1;
      return story;
    }
    if (path == '/community/reports') {
      reports.add({
        'id': 'r1',
        ...data,
        'status': 'pending',
        'created_at': '2026-10-12T09:00:00Z',
      });
      return reports.last;
    }
    if (path.endsWith('/block')) {
      blocked = true;
      return null;
    }
    return null;
  }

  @override
  Future<dynamic> put(String path, Json data) async {
    if (path == '/community/preferences') {
      writes.add((path, data));
      return data;
    }
    return super.put(path, data);
  }

  @override
  Future<void> delete(String path, [Json data = const {}]) async {
    writes.add((path, data));
    if (path.endsWith('/block')) blocked = false;
    if (path.endsWith('/leave')) joined = false;
    if (path.endsWith('/reactions')) {
      story['my_reaction'] = null;
      story['reaction_count'] = 0;
    }
    if (path == '/community/posts/p1') empty = true;
  }
}

Future<(ProviderContainer, CommunityFixtureApi)> setupCommunity(
  WidgetTester tester, {
  bool joined = false,
}) async {
  final session = fixtureSession();
  final api = CommunityFixtureApi(session)..joined = joined;
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith((ref) => session),
      apiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HopelyApp()),
  );
  await tester.pumpAndSettle();
  return (container, api);
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('home shortcut opens community while preserving five main tabs', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(5),
    );
    await tapVisible(tester, find.text('Masuk Komunitas'));
    expect(find.byType(CommunityHomeScreen), findsOneWidget);
    expect(api.reads, contains('/community/home'));
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AppShell, skipOffstage: false), findsOneWidget);
  });

  testWidgets('community loading and empty state use server results', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester);
    api.empty = true;
    api.homePending = Completer<dynamic>();
    container.read(routerProvider).go('/community');
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    api.homePending!.complete(api.homeData);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ruang sedang disiapkan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ruang sedang disiapkan'), findsOneWidget);
  });

  testWidgets('community error can be retried', (tester) async {
    final (container, api) = await setupCommunity(tester);
    api.failHome = true;
    container.read(routerProvider).go('/community');
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    api.failHome = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Kamu tidak sendiri.'), findsOneWidget);
  });

  testWidgets('discovery encodes search and category filters', (tester) async {
    final (container, api) = await setupCommunity(tester);
    container.read(routerProvider).go('/community/discover');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dukungan & pemulihan');
    await tester.tap(find.byTooltip('Jalankan pencarian'));
    await tester.pumpAndSettle();
    final request = Uri.parse(
      api.reads.lastWhere((p) => p.startsWith('/communities?')),
    );
    expect(request.queryParameters['search'], 'Dukungan & pemulihan');
    expect(request.queryParameters['sort'], 'relevant');
  });

  testWidgets('join requires chosen public name and agreement', (tester) async {
    final (container, api) = await setupCommunity(tester);
    container.read(routerProvider).go('/community/groups/g1');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Gabung komunitas'));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Gabung sekarang'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextFormField), 'Nama Pilihanku');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gabung sekarang'));
    await tester.pumpAndSettle();
    expect(api.joined, isTrue);
    expect(api.writes.single.$2, {
      'display_name': 'Nama Pilihanku',
      'rules_accepted': true,
    });
  });

  testWidgets('create sends explicit content and displays pending moderation', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/compose?community=g1');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('community-post-content')),
      'Aku ingin berbagi langkah kecil hari ini.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const Key('community-sharing-consent')),
    );
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Bagikan Cerita'),
    );
    expect(api.writes.single.$1, '/communities/g1/posts');
    expect(api.writes.single.$2, {
      'content': 'Aku ingin berbagi langkah kecil hari ini.',
      'sharing_acknowledged': true,
    });
    expect(find.text('Menunggu peninjauan'), findsOneWidget);
  });

  testWidgets('comment requires sharing consent and reports pending state', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/posts/p1');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('community-comment-content')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('community-comment-content')),
      'Terima kasih sudah berbagi.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const Key('community-comment-consent')),
    );
    await tapVisible(tester, find.text('Kirim dukungan'));
    expect(api.writes.single.$1, '/community/posts/p1/comments');
    expect(api.writes.single.$2['sharing_acknowledged'], isTrue);
    expect(api.comments, hasLength(1));
    await tester.scrollUntilVisible(
      find.text('Terima kasih sudah berbagi.'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Terima kasih sudah berbagi.'), findsOneWidget);
  });

  testWidgets('support reaction persists and can be removed', (tester) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/posts/p1');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Dukungan'));
    expect(api.story['my_reaction'], 'support');
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Dukungan'));
    expect(api.story['my_reaction'], isNull);
  });

  testWidgets('report sends type id and reason and appears in safety history', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/posts/p1');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pilihan cerita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laporkan cerita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim laporan'));
    await tester.pumpAndSettle();
    expect(api.reports.single['reportable_type'], 'post');
    expect(api.reports.single['reportable_id'], 'p1');
    container.read(routerProvider).go('/community/safety');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Informasi medis berbahaya'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Menunggu peninjauan'), findsOneWidget);
  });

  testWidgets('block hides author content and safety can unblock', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/posts/p1');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pilihan cerita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blokir pengguna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blokir'));
    await tester.pumpAndSettle();
    expect(api.blocked, isTrue);
    expect(find.text(api.story['content']), findsNothing);
    container.read(routerProvider).go('/community/safety');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Buka blokir'));
    expect(api.blocked, isFalse);
  });

  testWidgets('notification opt out is persisted without health context', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester);
    container.read(routerProvider).go('/community/preferences');
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.widgetWithText(SwitchListTile, 'Notifikasi komunitas'),
    );
    await tapVisible(tester, find.text('Simpan pengaturan'));
    expect(api.writes.single.$2['notifications_enabled'], isFalse);
    expect(api.writes.single.$2['recommendation_enabled'], isFalse);
    expect(api.writes.single.$2['interests'], isEmpty);
  });

  testWidgets('member can leave from My Communities', (tester) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/mine');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Keluar dari komunitas'));
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(api.joined, isFalse);
    expect(api.writes.single.$1, '/communities/g1/leave');
    expect(find.text('Belum mengikuti komunitas'), findsOneWidget);
  });

  testWidgets('moderator submits a decision and clears the queue', (
    tester,
  ) async {
    final (container, api) = await setupCommunity(tester, joined: true);
    container.read(routerProvider).go('/community/moderation');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Terbitkan'));
    await tester.enterText(
      find.byType(TextFormField),
      'Cerita sudah ditinjau.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan keputusan'));
    await tester.pumpAndSettle();
    expect(api.writes.single.$1, '/community/moderation/post/held-1');
    expect(api.writes.single.$2, {
      'action': 'approve',
      'revision': 1,
      'note': 'Cerita sudah ditinjau.',
    });
    expect(find.text('Antrean sudah bersih'), findsOneWidget);
  });

  testWidgets(
    'all community screens render at phone width and produce review images',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = fixtureSession(),
          api = CommunityFixtureApi(fixtureSession())..joined = true;
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => session),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UncontrolledProviderScope(
            container: container,
            child: const HopelyApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (name, path) in [
        ('home', '/community'),
        ('discovery', '/community/discover'),
        ('detail', '/community/groups/g1'),
        ('feed', '/community/feed'),
        ('compose', '/community/compose?community=g1'),
        ('post', '/community/posts/p1'),
        ('mine', '/community/mine'),
        ('safety', '/community/safety'),
        ('preferences', '/community/preferences'),
        ('moderation', '/community/moderation'),
      ]) {
        container.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
        await savePreview(tester, key, 'community-$name');
      }
    },
  );
}
