import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String module = 'activities';
  int page = 1;
  String search = '';
  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionProvider).user?['role'];
    final full = role == 'ADMIN' || role == 'SUPER_ADMIN';
    final modules = <String, String>{
      if (full || role == 'CONTENT_ADMIN') 'activities': 'Tools Kesehatan',
      if (full || role == 'COMMUNITY_MODERATOR') ...{
        'communities': 'Komunitas',
        'reports': 'Laporan',
      },
      if (full) ...{
        'users': 'Pengguna',
        'support-alerts': 'Bantuan Cepat',
        'audit': 'Audit Log',
      },
    };
    if (modules.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Akses admin diperlukan.')),
      );
    }
    if (!modules.containsKey(module)) {
      module = modules.keys.first;
    }
    final menu = ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Hopely Care Admin'),
        ),
        for (final entry in modules.entries)
          ListTile(
            selected: module == entry.key,
            title: Text(entry.value),
            onTap: () => setState(() {
              module = entry.key;
              page = 1;
              search = '';
            }),
          ),
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    return Scaffold(
      appBar: AppBar(title: Text(modules[module]!)),
      drawer: wide ? null : Drawer(child: menu),
      body: Row(
        children: [
          if (wide) SizedBox(width: 232, child: menu),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    key: ValueKey(module),
                    decoration: const InputDecoration(
                      labelText: 'Cari',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) => setState(() {
                      search = value.trim();
                      page = 1;
                    }),
                  ),
                ),
                Expanded(
                  child: DataPage(
                    key: ValueKey('$module:$page:$search'),
                    load: () => ref
                        .read(apiProvider)
                        .get(
                          '/admin/workspace/$module?page=$page&search=${Uri.encodeQueryComponent(search)}',
                        ),
                    builder: (data, reload) {
                      final rows = (data['data'] as List).cast<Json>();
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          if (rows.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Belum ada data.'),
                            ),
                          for (final row in rows)
                            ListTile(
                              title: Text(
                                '${row['title'] ?? row['name'] ?? row['event'] ?? row['status'] ?? row['reason'] ?? row['id']}',
                              ),
                              subtitle: Text(
                                '${row['email'] ?? row['created_at'] ?? ''}',
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Halaman $page / ${data['last_page']}'),
                              IconButton(
                                tooltip: 'Halaman sebelumnya',
                                onPressed: page > 1
                                    ? () => setState(() => page--)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              IconButton(
                                tooltip: 'Halaman berikutnya',
                                onPressed: page < (data['last_page'] as int)
                                    ? () => setState(() => page++)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
