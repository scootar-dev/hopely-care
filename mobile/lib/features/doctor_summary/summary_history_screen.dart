import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';

class SummaryHistoryScreen extends ConsumerStatefulWidget {
  const SummaryHistoryScreen({super.key});
  @override
  ConsumerState<SummaryHistoryScreen> createState() => _SummaryHistoryState();
}

class _SummaryHistoryState extends ConsumerState<SummaryHistoryScreen> {
  int page = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Arsip ringkasan')),
    body: DataPage(
      key: ValueKey(page),
      load: () => ref.read(apiProvider).get('/doctor-summary?page=$page'),
      builder: (data, reload) => PageBody(
        children: [
          if (items(data).isEmpty)
            const CareCard(child: Text('Belum ada ringkasan tersimpan.')),
          for (final row in items(data))
            CareCard(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('${row['period_start']} – ${row['period_end']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/doctor-summary/${row['id']}'),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page > 1 ? () => setState(() => page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Halaman $page / ${data['last_page']}'),
              IconButton(
                onPressed: page < (data['last_page'] as int)
                    ? () => setState(() => page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
