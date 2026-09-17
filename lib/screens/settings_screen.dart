import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _radiusDraft;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pair = state.pair;
    if (pair == null) {
      // 연결 해제 직후 이 화면이 남아 있을 수 있음
      return const Scaffold(body: SizedBox.shrink());
    }
    final radius = _radiusDraft ?? pair.alertRadius;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionTitle('동작 모드'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppMode>(
              segments: const [
                ButtonSegment(
                  value: AppMode.guard,
                  icon: Icon(Icons.child_care),
                  label: Text('이탈 방지'),
                ),
                ButtonSegment(
                  value: AppMode.find,
                  icon: Icon(Icons.handshake_outlined),
                  label: Text('약속 장소 찾기'),
                ),
              ],
              selected: {pair.mode},
              onSelectionChanged: (s) => state.updatePair(mode: s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(pair.mode.description,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const _SectionTitle('이탈 경고 거리'),
          ListTile(
            title: Text('${radius.round()}m 이상 멀어지면 경고'),
            subtitle: const Text(
              '블루투스 거리는 추정치입니다. 실내·사람 많은 곳은 여유 있게 설정하세요.',
            ),
          ),
          Slider(
            value: radius,
            min: 5,
            max: 100,
            divisions: 19,
            label: '${radius.round()}m',
            onChanged: (v) => setState(() => _radiusDraft = v),
            onChangeEnd: (v) {
              state.updatePair(alertRadius: v);
              setState(() => _radiusDraft = null);
            },
          ),
          const _SectionTitle('연결 정보'),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('연결 코드'),
            subtitle: Text(pair.code),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('내 역할'),
            subtitle: Text(pair.mode.roleLabel(pair.role)),
          ),
          ListTile(
            leading: Icon(
              state.syncAvailable ? Icons.cloud_done_outlined : Icons.cloud_off,
            ),
            title: const Text('GPS 원거리 동기화'),
            subtitle: Text(
              state.syncAvailable
                  ? 'Firebase 연결됨. 블루투스 범위 밖에서도 거리를 계산합니다.'
                  : '미설정. 블루투스 범위(약 30m) 안에서만 동작합니다. '
                      '설정 방법은 README를 참고하세요.',
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: Icon(Icons.link_off,
                color: Theme.of(context).colorScheme.error),
            title: Text('연결 해제',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('추적을 중지하고 코드를 지웁니다.'),
            onTap: () => _confirmUnpair(context, state),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnpair(BuildContext context, AppState state) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연결을 해제할까요?'),
        content: const Text('상대 기기도 다시 연결해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await state.unpair();
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
