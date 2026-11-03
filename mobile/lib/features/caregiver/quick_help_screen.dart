import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../core/notifications/push_service.dart';

const _emergencyRed = Color(0xFFB42332);

class QuickHelpScreen extends StatelessWidget {
  const QuickHelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bantuan Cepat')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(child: SizedBox(width: 600, child: QuickHelpPanel())),
    ),
  );
}

class QuickHelpPanel extends ConsumerStatefulWidget {
  const QuickHelpPanel({
    super.key,
    this.caregiver = false,
    this.notificationId,
  });
  final bool caregiver;
  final String? notificationId;
  @override
  ConsumerState<QuickHelpPanel> createState() => _QuickHelpPanelState();
}

class _QuickHelpPanelState extends ConsumerState<QuickHelpPanel> {
  Timer? _timer;
  List<Json> _alerts = [];
  int _eligible = 0;
  bool _loading = true, _busy = false, _fetching = false;
  String? _error;
  bool _sendFailed = false;
  int _generation = 0;
  String? _result;
  void _pushChanged() {
    if (!_busy) _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
    PushService.changes.addListener(_pushChanged);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_busy) _load();
    });
  }

  @override
  void dispose() {
    _generation++;
    PushService.changes.removeListener(_pushChanged);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    final request = ++_generation;
    final token = ref.read(sessionProvider).token;
    try {
      final data = await ref
          .read(apiProvider)
          .get(
            widget.notificationId != null
                ? '/caregiver/support-alerts/notification/${widget.notificationId}'
                : widget.caregiver
                ? '/caregiver/support-alerts'
                : '/support-alerts/active',
          );
      if (mounted &&
          request == _generation &&
          token == ref.read(sessionProvider).token) {
        setState(() {
          _alerts = widget.notificationId != null
              ? [data as Json]
              : (data['alerts'] as List).cast<Json>();
          _eligible = data['eligible_count'] as int? ?? 0;
          _loading = false;
          if (!_sendFailed) {
            _error = null;
          }
        });
      }
    } catch (e) {
      if (mounted && request == _generation) {
        setState(() {
          _loading = false;
          _alerts = [];
          _error =
              e is DioException && [401, 403].contains(e.response?.statusCode)
              ? 'Akses bantuan ditolak. Periksa sesi dan izin pendamping.'
              : 'Status bantuan belum dapat diperbarui. Periksa koneksimu.';
        });
      }
    } finally {
      if (request == _generation) _fetching = false;
    }
  }

  Future<void> _act(
    String path, {
    bool send = false,
    bool cancel = false,
  }) async {
    if (_busy) return;
    if (widget.caregiver && path.endsWith('/resolve')) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Selesaikan permintaan bantuan?'),
          content: const Text(
            'Permintaan akan ditandai selesai. Pastikan kebutuhan bantuan sudah ditangani.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Selesaikan'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true || _busy) return;
    }
    if (send || cancel) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            cancel ? 'Batalkan alert?' : 'Kirim alert ke pendamping?',
          ),
          content: Text(
            cancel
                ? 'Alert akan ditandai selesai.'
                : 'Permintaan akan dicatat dan pemberitahuan dicoba dikirim ke pendamping berizin. Pengiriman tidak menjamin pesan diterima atau bantuan datang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _emergencyRed),
              onPressed: () => Navigator.pop(c, true),
              child: Text(cancel ? 'Batalkan Alert' : 'Kirim Alert'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _generation++;
      _fetching = false;
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(apiProvider).post(path, {});
      if (!mounted) return;
      setState(() {
        _sendFailed = false;
        if (send) _alerts = [result as Json];
        if (!send && result is Map) {
          if (result['status'] == 'ACKNOWLEDGED') {
            _result = 'Permintaan telah kamu tanggapi.';
          }
          if (result['status'] == 'RESOLVED') {
            _result = cancel
                ? 'Permintaan bantuan dibatalkan.'
                : 'Permintaan bantuan selesai.';
          }
        }
      });
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _sendFailed = send;
          _error = send
              ? 'Alert belum berhasil dikirim.'
              : 'Perubahan belum berhasil disimpan. Perbarui status dan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Memuat status bantuan',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_result != null) Semantics(liveRegion: true, child: Text(_result!)),
        if (widget.caregiver && _alerts.isEmpty && _error == null)
          const Text('Tidak ada permintaan Bantuan Cepat aktif.'),
        if (!widget.caregiver) ...[
          Text(
            'Butuh bantuan sekarang?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Kirim permintaan bantuan kepada pendamping yang terhubung melalui Care Circle dan memiliki izin menerima alert.',
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Untuk keadaan medis darurat, segera hubungi layanan kegawatdaruratan setempat atau fasilitas kesehatan terdekat. Jangan menunggu tanggapan aplikasi.',
        ),
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: const TextStyle(color: _emergencyRed)),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _sendFailed
                      ? _act('/support-alerts', send: true)
                      : _load(),
            child: const Text('Coba Lagi'),
          ),
        ],
        if (_busy)
          const LinearProgressIndicator(semanticsLabel: 'Menyimpan alert'),
        if (!widget.caregiver && _alerts.isEmpty && _error == null) ...[
          const SizedBox(height: 32),
          if (_eligible == 0) ...[
            const Text('Belum ada pendamping yang terhubung.'),
            const Text(
              'Bantuan Cepat membutuhkan Care Circle aktif dengan izin menerima alert.',
            ),
            FilledButton(
              onPressed: () => context.push('/care-circle'),
              child: const Text('Tambah Pendamping'),
            ),
          ] else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _emergencyRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(96),
                padding: const EdgeInsets.all(24),
              ),
              onPressed: _busy
                  ? null
                  : () => _act('/support-alerts', send: true),
              icon: const Icon(Icons.warning_amber_rounded, size: 32),
              label: const Text(
                'Kirim Bantuan Sekarang',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
        ],
        for (final a in _alerts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    widget.caregiver
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: _emergencyRed,
                    size: 48,
                  ),
                  Text(
                    widget.caregiver
                        ? 'Bantuan Dibutuhkan'
                        : 'Permintaan bantuan tercatat',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (a['created_at'] != null)
                    Text(
                      'Diminta ${DateTime.tryParse(a['created_at'].toString())?.toLocal().toString().substring(0, 16) ?? a['created_at']}',
                    ),
                  Text(switch (a['status']) {
                    'ACTIVE' => 'Membutuhkan tanggapan',
                    'ACKNOWLEDGED' => 'Sudah ditanggapi',
                    'RESOLVED' => 'Sudah selesai',
                    _ => 'Status sedang diperbarui',
                  }),
                  Text(
                    widget.caregiver
                        ? '${a['patient_name']} meminta bantuan sekarang.'
                        : 'Belum berarti pendamping telah menerima atau membaca pemberitahuan.',
                  ),
                  if (!widget.caregiver)
                    Text('${a['recipient_count']} pendamping dituju'),
                  if (!widget.caregiver)
                    Text(
                      'Diterima layanan push: ${a['notification_status']?['provider_accepted_count'] ?? 0}. '
                      'Belum terkonfirmasi terkirim: ${a['notification_status']?['unconfirmed_count'] ?? a['recipient_count']}. '
                      'Jika belum ada tanggapan, hubungi pendamping secara langsung.',
                    ),
                  if (a['status'] == 'ACKNOWLEDGED')
                    Text(
                      'Sedang ditangani oleh ${a['acknowledged_name'] ?? 'pendamping'}',
                    ),
                  if (widget.caregiver && a['status'] == 'ACTIVE')
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () =>
                                _act('/support-alerts/${a['id']}/acknowledge'),
                      child: const Text('Saya Tanggapi'),
                    ),
                  if (widget.caregiver)
                    const Text(
                      'Hubungi pasien melalui kontak yang kamu miliki.',
                    ),
                  if (!widget.caregiver)
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Kembali ke Beranda'),
                    ),
                  if (!widget.caregiver && a['status'] == 'ACTIVE')
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              '/support-alerts/${a['id']}/cancel',
                              cancel: true,
                            ),
                      child: const Text('Batalkan Alert'),
                    ),
                  if (a['status'] == 'RESOLVED')
                    const Text('Permintaan bantuan sudah selesai.'),
                  if (a['status'] != 'RESOLVED' &&
                      (widget.caregiver || a['status'] == 'ACKNOWLEDGED'))
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _act('/support-alerts/${a['id']}/resolve'),
                      child: const Text('Tandai Selesai'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
