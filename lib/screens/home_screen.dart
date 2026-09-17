import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/pair_info.dart';
import '../providers/app_state.dart';
import 'find_screen.dart';
import 'guard_screen.dart';
import 'pairing_screen.dart';
import 'settings_screen.dart';

/// 페어링 전이면 PairingScreen, 후면 모드별 화면 + 시작/중지 버튼
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pair = state.pair;
    if (pair == null) return const PairingScreen();

    return Scaffold(
      appBar: AppBar(
        title: Text(pair.mode.label),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _PairHeader(pair: pair, syncAvailable: state.syncAvailable),
          if (state.error != null)
            _ErrorBanner(message: state.error!, onClose: state.clearError),
          Expanded(
            child: pair.mode == AppMode.guard
                ? const GuardScreen()
                : const FindScreen(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: state.running
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            icon: Icon(state.running ? Icons.stop : Icons.play_arrow),
            label: Text(state.running ? '추적 중지' : '추적 시작'),
            onPressed: () => _toggle(context, state),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, AppState state) async {
    if (state.running) {
      await state.stopTracking();
      return;
    }
    final ok = await state.startTracking();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? '추적을 시작할 수 없어요.')),
      );
    }
  }
}

class _PairHeader extends StatelessWidget {
  const _PairHeader({required this.pair, required this.syncAvailable});

  final PairInfo pair;
  final bool syncAvailable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('연결 코드', style: textTheme.labelMedium),
                Text(
                  pair.code,
                  style: textTheme.headlineSmall?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Chip(
                avatar: Icon(
                  pair.role == PairRole.host ? Icons.shield : Icons.person,
                  size: 18,
                ),
                label: Text('내 역할: ${pair.mode.roleLabel(pair.role)}'),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 4),
              Text(
                syncAvailable ? 'GPS 동기화 켜짐' : '블루투스 전용 (GPS 동기화 미설정)',
                style: textTheme.labelSmall?.copyWith(
                  color: syncAvailable ? scheme.primary : scheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
