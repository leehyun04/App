import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/enums.dart';
import '../providers/app_state.dart';

/// 첫 화면. 모드 선택 → 코드 만들기(host) 또는 코드 입력(guest)
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  AppMode _mode = AppMode.guard;
  final TextEditingController _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final code = await state.createPair(_mode);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('코드 $code 가 만들어졌어요. 상대 기기에 입력해 주세요.')),
    );
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final ok = await state.joinPair(_codeCtrl.text, _mode);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? '코드를 확인해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('두 기기를 연결하세요',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '한쪽에서 코드를 만들고, 다른 쪽에서 그 코드를 입력하면 연결됩니다. '
            '두 기기 모두 이 앱이 설치돼 있어야 해요.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('사용 목적', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<AppMode>(
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
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 8),
          Text(_mode.description, style: textTheme.bodySmall),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_mode.hostLabel} 기기', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text('새 코드를 만들고 상대 기기에 알려주세요.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _create,
                    icon: const Icon(Icons.add),
                    label: const Text('새 코드 만들기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_mode.guestLabel} 기기', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text('상대가 만든 6자리 코드를 입력하세요.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: textTheme.headlineSmall?.copyWith(letterSpacing: 6),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _join(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _join,
                    icon: const Icon(Icons.login),
                    label: const Text('코드로 참여'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
