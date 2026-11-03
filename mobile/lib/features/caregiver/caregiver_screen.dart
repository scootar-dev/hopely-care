import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/stitch.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/account_action.dart';
import 'quick_help_screen.dart';
import '../../core/notifications/notification_action.dart';

class CaregiverScreen extends ConsumerWidget {
  const CaregiverScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      centerTitle: false,
      leading: const Padding(padding: EdgeInsets.all(10), child: HopelyMark()),
      title: const Text('Dashboard Kerabat'),
      actions: [
        NotificationAction(key: ValueKey(ref.watch(sessionProvider).token)),
        const AccountAction(),
      ],
    ),
    body: PageBody(
      children: [
        QuickHelpPanel(
          key: ValueKey(ref.watch(sessionProvider).token),
          caregiver: true,
        ),
        _CaregiverDashboard(key: ValueKey(ref.watch(sessionProvider).token)),
      ],
    ),
  );
}

class _CaregiverDashboard extends ConsumerStatefulWidget {
  const _CaregiverDashboard({super.key});
  @override
  ConsumerState<_CaregiverDashboard> createState() =>
      _CaregiverDashboardState();
}

class _CaregiverDashboardState extends ConsumerState<_CaregiverDashboard>
    with WidgetsBindingObserver {
  String? selected;
  Timer? refreshTimer;
  int generation = 0;
  bool active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (active) reload();
    });
  }

  @override
  void dispose() {
    generation++;
    refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) reload();
  }

  late Future<Json> future = load();
  Future<Json> load() async {
    final request = ++generation;
    final session = ref.read(sessionProvider);
    final identity = session.token;
    final key = 'hopely.patient.${session.user?['id']}';
    String? stored;
    try {
      stored = await session.storage.read(key: key);
    } catch (_) {
      /* No persistence on unsupported platforms. */
    }
    final patients = await ref.read(apiProvider).get('/caregiver/patients');
    if (!mounted || request != generation || identity != session.token) {
      throw StateError('Sesi berubah.');
    }
    selected ??= stored;
    if (!items(patients).any((p) => p['patient_id'] == selected)) {
      selected = null;
      try {
        await session.storage.delete(key: key);
      } catch (_) {}
    }
    return {
      'patients': patients,
      'notifications': await ref
          .read(apiProvider)
          .get('/notifications')
          .catchError((Object e) => e),
    };
  }

  Future<void> choose(String? value) async {
    setState(() => selected = value);
    final session = ref.read(sessionProvider);
    try {
      await session.storage.write(
        key: 'hopely.patient.${session.user?['id']}',
        value: value,
      );
    } catch (_) {}
  }

  void reload() => setState(() { future = load(); });
  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError) return ErrorNotice(snapshot.error!, retry: reload);
      final data = snapshot.data!;
      final patients = items(data['patients']);
      final featuredPatient =
          patients.where((p) => p['patient_id'] == selected).firstOrNull ??
          patients.firstOrNull;
      final notificationError =
          data['notifications'] is Exception || data['notifications'] is Error;
      final alerts =
          (notificationError ? <Json>[] : items(data['notifications'])).where(
            (n) =>
                n['notification_type'] == 'support_alert' &&
                n['read_at'] == null,
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notificationError)
            ErrorNotice(data['notifications'], retry: reload),
          const SoftLabel('Mode Kerabat Aktif', icon: Icons.people_outline),
          const SizedBox(height: 14),
          Text(
            '${dayGreeting()}, ${ref.watch(sessionProvider).user?['name'] ?? 'Pendamping'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            featuredPatient == null
                ? 'Pendampingan yang penuh perhatian'
                : 'Pendampingan ${featuredPatient['name'] ?? 'pasien'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          if (patients.length > 1)
            DropdownButtonFormField<String>(
              initialValue: featuredPatient?['patient_id'] as String?,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pasien yang didampingi',
              ),
              items: [
                for (final p in patients)
                  DropdownMenuItem(
                    value: p['patient_id'] as String,
                    child: Text(p['name'] ?? 'Pasien'),
                  ),
              ],
              key: ValueKey(featuredPatient?['patient_id']),
              onChanged: choose,
            ),
          if (featuredPatient != null)
            CaregiverPatientScreen(
              key: ValueKey(featuredPatient['patient_id']),
              patientId: featuredPatient['patient_id'],
              embedded: true,
            ),
          const Text(
            'Pilih pasien untuk melihat informasi yang diizinkan dan meminta panduan pendampingan.',
          ),
          const SizedBox(height: 16),
          for (final alert in alerts)
            CareCard(
              color: warningSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    'Pengingat dukungan',
                    icon: Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Luangkan waktu untuk menyapa orang yang kamu dampingi.',
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/caregiver/alerts/${alert['id']}'),
                    icon: const Icon(Icons.favorite_outline),
                    label: const Text('Lihat pengingat'),
                  ),
                ],
              ),
            ),
          if (patients.isEmpty)
            const CareCard(
              child: Text(
                'Belum ada pasien yang terhubung. Terima undangan pribadi dari orang yang akan kamu dampingi.',
              ),
            ),
          if (patients.isNotEmpty)
            const SectionHeading('Orang yang kamu dampingi'),
          for (final patient in patients)
            CareCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconWell(Icons.person_outline, size: 48),
                title: Text(patient['name'] ?? 'Pasien'),
                subtitle: Text(
                  '${patient['relationship_label']} · Terhubung\nRingkasan & Panduan Pendamping',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/caregiver/${patient['patient_id']}'),
              ),
            ),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/caregiver/connect');
              reload();
            },
            icon: const Icon(Icons.link),
            label: const Text('Hubungkan dengan Pasien'),
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const ActionLink(
            'Komunitas pendamping',
            '/community',
            icon: Icons.groups_outlined,
          ),
          const SizedBox(height: 16),
          const PrivacyNote(
            'Data yang tersedia mengikuti persetujuan dan izin pasien. Isi jurnal dan percakapan AI tidak dibagikan.',
          ),
        ],
      );
    },
  );
}

class CaregiverConnectScreen extends ConsumerStatefulWidget {
  const CaregiverConnectScreen({super.key});
  @override
  ConsumerState<CaregiverConnectScreen> createState() =>
      _CaregiverConnectScreenState();
}

class _CaregiverConnectScreenState
    extends ConsumerState<CaregiverConnectScreen> {
  final token = TextEditingController();
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    token.dispose();
    super.dispose();
  }

  Future<void> accept() async {
    if (token.text.trim().isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).post('/caregivers/accept', {
        'token': token.text.trim(),
      });
      if (mounted) {
        context.go('/caregiver');
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackHomeButton(fallback: '/caregiver'),
      title: const Text('Pendamping & Keluarga'),
    ),
    body: PageBody(
      children: [
        const CareHero(compact: true),
        const Heading(
          'Terhubung sebagai Kerabat',
          'Masukkan kode undangan dari pasien untuk mulai mendampingi.',
        ),
        const CareCard(
          color: skySoft,
          child: Text(
            'Hadirkan rasa nyaman tanpa mengambil alih ruang pribadi orang terdekatmu.',
          ),
        ),
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                'Kode Undangan Pasien',
                icon: Icons.key_outlined,
              ),
              TextField(
                controller: token,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tempel kode undangan',
                  helperText: 'Gunakan email akun yang diundang pasien.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : accept,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(busy ? 'Menghubungkan…' : 'Hubungkan Sekarang'),
                ),
              ),
            ],
          ),
        ),
        if (error != null) CareCard(child: Text(invitationError(error!))),
        const PrivacyNote(
          'Kode berlaku 48 jam dan hanya dapat dipakai sekali. Belum punya kode? Minta pasien membuka Profil → Undang Kerabat.',
        ),
        const SectionHeading('Kenapa perlu terhubung?'),
        const CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pahami ringkasan yang dibagikan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Pasien memilih jenis ringkasan wellbeing, keluhan, jadwal, dan aktivitas yang dapat kamu lihat.',
              ),
              SizedBox(height: 18),
              Text(
                'Belajar menawarkan dukungan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'AI Coach membantu menyiapkan komunikasi yang hangat, tanpa menggantikan tim perawatan.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String invitationError(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      404 => 'Kode tidak dapat digunakan. Kode mungkin salah, kedaluwarsa, sudah digunakan, atau ditujukan untuk email lain. Minta pasien memeriksa undangan.',
      401 => 'Sesi berakhir. Masuk kembali untuk menerima undangan.',
      403 => 'Akun ini tidak diizinkan menerima undangan pendamping.',
      409 => 'Hubungan atau undangan sudah berubah. Periksa daftar pasien sebelum mencoba lagi.',
      null => 'Tidak dapat terhubung. Periksa koneksi internet lalu coba lagi.',
      _ => 'Undangan belum dapat diproses. Periksa kode dan coba lagi.',
    };
  }
  return 'Undangan belum dapat diproses. Coba lagi.';
}

class CaregiverPatientScreen extends ConsumerStatefulWidget {
  const CaregiverPatientScreen({
    super.key,
    required this.patientId,
    this.embedded = false,
  });
  final String patientId;
  final bool embedded;
  @override
  ConsumerState<CaregiverPatientScreen> createState() =>
      _CaregiverPatientScreenState();
}

class _CaregiverPatientScreenState extends ConsumerState<CaregiverPatientScreen>
    with WidgetsBindingObserver {
  final message = TextEditingController();
  Json? coach;
  Object? error;
  bool busy = false;
  Json? summary;
  Object? accessError;
  int generation = 0;
  Timer? accessTimer;
  late Session session;
  String? identity;
  GoRouter? router;
  bool visible = true;
  bool foreground = true;

  @override
  void initState() {
    super.initState();
    session = ref.read(sessionProvider);
    identity = session.token;
    session.addListener(sessionChanged);
    WidgetsBinding.instance.addObserver(this);
    revalidate();
    accessTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (visible && foreground && !busy) revalidate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GoRouter.maybeOf(context);
    if (router != next) {
      router?.routerDelegate.removeListener(routeChanged);
      router = next;
      router?.routerDelegate.addListener(routeChanged);
    }
  }

  void clearSensitive() {
    generation++;
    summary = null;
    coach = null;
    error = null;
    accessError = null;
    busy = false;
  }

  void sessionChanged() {
    if (identity == session.token && session.loggedIn) return;
    identity = session.token;
    setState(() {
      clearSensitive();
      message.clear();
    });
    if (session.loggedIn && session.caregiver) revalidate();
  }

  void routeChanged() {
    if (!mounted) return;
    setState(clearSensitive);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      visible = ModalRoute.of(context)?.isCurrent ?? true;
      if (visible && foreground) revalidate();
    });
  }

  @override
  void didUpdateWidget(CaregiverPatientScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      message.clear();
      revalidate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    setState(clearSensitive);
    if (foreground && visible) revalidate();
  }

  Future<void> revalidate() async {
    setState(clearSensitive);
    if (!session.loggedIn || !session.caregiver) {
      setState(() => accessError = StateError('Sesi pendamping tidak aktif.'));
      return;
    }
    final request = generation;
    final patient = widget.patientId;
    final token = session.token;
    try {
      final data =
          await ref
                  .read(apiProvider)
                  .get('/caregiver/patients/$patient/summary')
              as Json;
      if (!mounted ||
          request != generation ||
          patient != widget.patientId ||
          token != session.token ||
          !foreground ||
          !visible) {
        return;
      }
      setState(() => summary = data);
    } catch (e) {
      if (mounted && request == generation) setState(() => accessError = e);
    }
  }

  @override
  void dispose() {
    generation++;
    accessTimer?.cancel();
    session.removeListener(sessionChanged);
    router?.routerDelegate.removeListener(routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    summary = null;
    coach = null;
    message.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    if (message.text.trim().isEmpty) {
      return;
    }
    final startingPatient = widget.patientId;
    final startingToken = session.token;
    final question = message.text;
    await revalidate();
    if (!mounted ||
        summary == null ||
        startingPatient != widget.patientId ||
        startingToken != session.token) {
      return;
    }
    final request = generation;
    final patient = widget.patientId;
    final permitted = jsonEncode(summary);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data =
          await ref.read(apiProvider).post(
                '/caregiver/patients/$patient/coach',
                {'message': question},
              )
              as Json;
      if (!mounted || request != generation) return;
      final current = await ref
          .read(apiProvider)
          .get('/caregiver/patients/$patient/summary');
      if (mounted && request == generation && patient == widget.patientId) {
        if (jsonEncode(current) != permitted) {
          await revalidate();
          return;
        }
        setState(() => coach = data);
      }
    } catch (e) {
      if (mounted && request == generation) {
        setState(() {
          clearSensitive();
          accessError = e;
        });
      }
    } finally {
      if (mounted && request == generation) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? (accessError != null
            ? ErrorNotice(accessError!, retry: revalidate)
            : summary == null
            ? const LinearProgressIndicator()
            : patientBody(summary!))
      : Scaffold(
          appBar: AppBar(
            leading: const BackHomeButton(fallback: '/caregiver'),
            title: const Text('Dashboard Kerabat'),
          ),
          body: accessError != null
              ? PageBody(
                  children: [ErrorNotice(accessError!, retry: revalidate)],
                )
              : summary == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: revalidate,
                  child: patientBody(summary!),
                ),
        );

  Widget patientBody(Json data) {
    if (widget.embedded) {
      return CareCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading('Ringkasan yang dibagikan'),
            Text(
              data['wellbeing_summary'] == null
                  ? 'Kondisi emosional belum diizinkan.'
                  : '${data['wellbeing_summary']['recorded_days']} hari tercatat dalam 7 hari terakhir.',
            ),
            Text(
              data['symptom_summary'] == null
                  ? 'Ringkasan gejala belum diizinkan.'
                  : '${data['symptom_summary']['record_count']} catatan gejala dalam 7 hari terakhir.',
            ),
            Text(
              data['treatment_schedule'] == null
                  ? 'Jadwal pengobatan belum diizinkan.'
                  : (data['treatment_schedule'] as List).isEmpty
                  ? 'Belum ada jadwal mendatang.'
                  : 'Jadwal terdekat: ${data['treatment_schedule'][0]['treatment_type']}',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push('/caregiver/${widget.patientId}'),
              child: const Text('Panduan Pendamping & detail kondisi'),
            ),
          ],
        ),
      );
    }
    final children = <Widget>[
      const Heading(
        'Informasi yang dibagikan',
        'Ringkasan laporan pasien, bukan penilaian medis. Izin dapat berubah kapan saja.',
      ),
      for (final group in const {
        'can_view_wellbeing_summary': 'Kondisi emosional',
        'can_view_symptom_summary': 'Kondisi fisik',
        'can_view_treatment_schedule': 'Jadwal pengobatan',
        'can_view_activity_status': 'Aktivitas pendukung',
      }.entries)
        if (data['permissions'][group.key] != true)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${group.value}: pasien belum mengizinkan informasi ini dibagikan.',
            ),
          ),
      if (data['wellbeing_summary'] != null)
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kondisi emosional · 7 hari terakhir'),
              Text(
                '${data['wellbeing_summary']['recorded_days']} hari tercatat dalam 7 hari terakhir',
              ),
              for (final e in const {
                'mood': 'Suasana hati',
                'anxiety': 'Kecemasan',
                'energy': 'Energi',
                'sleep': 'Kualitas tidur',
              }.entries)
                ScoreBar(e.value, data['wellbeing_summary'][e.key] as num?),
            ],
          ),
        ),
      if (data['symptom_summary'] != null)
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kondisi fisik · 7 hari terakhir'),
              Text(
                '${data['symptom_summary']['record_count']} catatan dalam 7 hari terakhir',
              ),
              for (final e in const {
                'pain': 'Nyeri',
                'fatigue': 'Kelelahan',
                'nausea': 'Mual',
                'dizziness': 'Pusing',
                'appetite': 'Nafsu makan',
                'sleep_quality': 'Kualitas tidur',
              }.entries)
                ScoreBar(e.value, data['symptom_summary'][e.key] as num?),
            ],
          ),
        ),
      if (data['treatment_schedule'] != null)
        const SectionHeading('Jadwal pengobatan'),
      if (data['treatment_schedule'] is List &&
          (data['treatment_schedule'] as List).isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('Belum ada jadwal pengobatan mendatang.'),
        ),
      if (data['treatment_schedule'] != null)
        for (final t in data['treatment_schedule'] as List)
          CareCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: hopelyBlue,
              ),
              title: Text(t['treatment_type']),
              subtitle: Text(
                DateTime.parse(
                  t['scheduled_at'],
                ).toLocal().toString().substring(0, 16),
              ),
            ),
          ),
      if (data['activity_status'] != null)
        CareCard(
          child: Text(
            'Aktivitas selesai: ${data['activity_status']['completed_count']}',
          ),
        ),
      if (!(data['permissions'] as Json).values.any((v) => v == true))
        const CareCard(
          child: Text('Belum ada jenis ringkasan yang diizinkan.'),
        ),
      CareCard(
        color: skySoft,
        child: Column(
          children: [
            Text(
              'Panduan Pendamping',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tanyakan cara berkomunikasi dan menawarkan dukungan. Jawaban memakai informasi yang diizinkan pasien.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: message,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Bagaimana menawarkan dukungan dengan nyaman?',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : ask,
              child: Text(
                busy ? 'Menyiapkan dukungan…' : 'Minta saran komunikasi',
              ),
            ),
          ],
        ),
      ),
      if (error != null) ErrorNotice(error!),
      if (coach != null) ...[
        MockNotice(coach!['metadata']),
        CareCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(coach!['support_message']),
              const SizedBox(height: 16),
              Text(coach!['communication_tip']),
              const SizedBox(height: 16),
              Text(coach!['suggested_action']),
            ],
          ),
        ),
      ],
    ];
    return widget.embedded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : PageBody(children: children);
  }
}
