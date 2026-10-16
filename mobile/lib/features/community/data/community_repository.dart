import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.read(apiProvider)),
);

class CommunityRepository {
  CommunityRepository(this.api);
  final Api api;
  String query(String path, Map<String, String?> values) => Uri(
    path: path,
    queryParameters: Map.fromEntries(
      values.entries.where((e) => e.value?.isNotEmpty == true),
    ),
  ).toString();
  Future<Json> home() async {
    try {
      return Map<String, dynamic>.from(await api.get('/community/home'));
    } catch (error, stack) {
      final results = await Future.wait<Json?>([
        _try(discover()),
        _try(mine()),
        _try(feed()),
      ]);
      if (results.every((value) => value == null)) {
        Error.throwWithStackTrace(error, stack);
      }
      final discovered = items(results[0]);
      return {
        'recommended': discovered
            .take(4)
            .map(
              (community) => {
                'community': community,
                'reason':
                    'Ruang dukungan yang tersedia. Pilih yang terasa sesuai untukmu.',
              },
            )
            .toList(),
        'recommendation_method': 'catalogue',
        'joined': items(results[1]),
        'recent': items(results[2]),
      };
    }
  }

  Future<Json?> _try(Future<Json> request) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }
  Future<Json> discover({
    String search = '',
    String? category,
    String sort = 'relevant',
    int page = 1,
  }) async => Map<String, dynamic>.from(
    await api.get(
      query('/communities', {
        'search': search,
        'category': category,
        'sort': sort,
        'page': '$page',
      }),
    ),
  );
  Future<Json> detail(String id) async =>
      Map<String, dynamic>.from(await api.get('/communities/$id'));
  Future<Json> mine({int page = 1}) async => Map<String, dynamic>.from(
    await api.get('/community/my-communities?page=$page'),
  );
  Future<List<Json>> allMemberships() async {
    final result = <Json>[];
    var page = 1;
    while (true) {
      final response = await mine(page: page);
      result.addAll(items(response));
      if (page >= (response['last_page'] as int? ?? 1)) {
        return result;
      }
      page++;
    }
  }

  Future<void> join(String id, String name) async {
    await api.post('/communities/$id/join', {
      'display_name': name,
      'rules_accepted': true,
    });
  }

  Future<void> leave(String id) => api.delete('/communities/$id/leave');
  Future<Json> feed({
    String? communityId,
    bool mine = false,
    int page = 1,
  }) async => Map<String, dynamic>.from(
    await api.get(
      query(
        communityId == null
            ? '/community/feed'
            : '/communities/$communityId/posts',
        {'page': '$page', if (mine) 'mine': '1'},
      ),
    ),
  );
  Future<Json> post(String id) async =>
      Map<String, dynamic>.from(await api.get('/community/posts/$id'));
  Future<Json> create(
    String communityId,
    String content,
    List<int>? image,
  ) async => Map<String, dynamic>.from(
    await api.createCommunityPost(communityId, content, image),
  );
  Future<Json> edit(Json post, String content) async =>
      Map<String, dynamic>.from(
        await api.put('/community/posts/${post['id']}', {
          'content': content,
          'sharing_acknowledged': true,
          'revision': post['revision'],
        }),
      );
  Future<void> deletePost(String id) => api.delete('/community/posts/$id');
  Future<Json> react(String id, String type) async => Map<String, dynamic>.from(
    await api.post('/community/posts/$id/reactions', {'reaction_type': type}),
  );
  Future<void> unreact(String id) =>
      api.delete('/community/posts/$id/reactions');
  Future<Json> comments(String id, {int page = 1}) async =>
      Map<String, dynamic>.from(
        await api.get('/community/posts/$id/comments?page=$page'),
      );
  Future<Json> comment(String id, String content) async =>
      Map<String, dynamic>.from(
        await api.post('/community/posts/$id/comments', {
          'content': content,
          'sharing_acknowledged': true,
        }),
      );
  Future<void> deleteComment(String id) =>
      api.delete('/community/comments/$id');
  Future<void> report(
    String type,
    String id,
    String reason,
    String description,
  ) async {
    await api.post('/community/reports', {
      'reportable_type': type,
      'reportable_id': id,
      'reason': reason,
      'description': description.isEmpty ? null : description,
    });
  }

  Future<void> block(String id) async {
    await api.post('/users/$id/block');
  }

  Future<void> unblock(String id) => api.delete('/users/$id/block');
  Future<Json> safety({int page = 1}) async =>
      Map<String, dynamic>.from(await api.get('/community/safety?page=$page'));
  Future<Json> preferences() async =>
      Map<String, dynamic>.from(await api.get('/community/preferences'));
  Future<void> savePreferences(Json data) async {
    await api.put('/community/preferences', data);
  }

  Future<Json> queue(String kind, int page) async => Map<String, dynamic>.from(
    await api.get('/community/moderation?kind=$kind&page=$page'),
  );
  Future<void> review(Json item, String action, String note) async {
    await api.post('/community/moderation/${item['kind']}/${item['id']}', {
      'action': action,
      'revision': item['revision'],
      'note': note,
    });
  }
}
