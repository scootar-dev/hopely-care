import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';

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
  const QuickHelpPanel({super.key, this.caregiver = false});
  final bool caregiver;
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
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_busy) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final data = await ref
          .read(apiProvider)
          .get(
            widget.caregiver
                ? '/caregiver/support-alerts'
                : '/support-alerts/active',
          );
      if (mounted) {
        setState(() {
          _alerts = (data['alerts'] as List).cast<Json>();
          _eligible = data['eligible_count'] as int? ?? 0;
          _loading = false;
          if (!_sendFailed) {
            _error = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Status bantuan belum dapat diperbarui. Periksa koneksimu.';
        });
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _act(
    String path, {
    bool send = false,
    bool cancel = false,
  }) async {
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
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiProvider).post(path, {});
      if (!mounted) return;
      setState(() {
        _sendFailed = false;
        if (send) _alerts = [result as Json];
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
          Text(
            'Butuh bantuan sekarang?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Gunakan fitur ini jika kamu membutuhkan bantuan segera dari pendampingmu.',
          ),
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
                  if (widget.caregiver || a['status'] == 'ACKNOWLEDGED')
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
