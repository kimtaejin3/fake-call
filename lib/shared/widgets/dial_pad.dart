import 'package:flutter/material.dart';

import '../../core/theme/call_theme.dart';

/// 다이얼 키 하나의 정의 — 숫자와 그 아래 알파벳.
class _DialKey {
  final String digit;
  final String letters;

  const _DialKey(this.digit, [this.letters = '']);
}

const List<_DialKey> _keys = [
  _DialKey('1'),
  _DialKey('2', 'ABC'),
  _DialKey('3', 'DEF'),
  _DialKey('4', 'GHI'),
  _DialKey('5', 'JKL'),
  _DialKey('6', 'MNO'),
  _DialKey('7', 'PQRS'),
  _DialKey('8', 'TUV'),
  _DialKey('9', 'WXYZ'),
  _DialKey('*'),
  _DialKey('0', '+'),
  _DialKey('#'),
];

/// 통화 중 화면에서 '키패드' 를 눌렀을 때 올라오는 숫자판.
///
/// 실제 전화 앱과 동일하게 입력한 숫자를 위에 누적해 보여주고, 아래
/// [onHide] 로 닫는다. 가짜 통화이므로 DTMF 톤을 실제로 보내지는 않는다.
class DialPad extends StatefulWidget {
  const DialPad({super.key, required this.palette, required this.onHide});

  final CallPalette palette;
  final VoidCallback onHide;

  @override
  State<DialPad> createState() => _DialPadState();
}

class _DialPadState extends State<DialPad> {
  String _entered = '';

  void _press(String digit) {
    // 실제 통화 중 키패드도 무한히 늘어나진 않는다. 화면을 넘기지 않을
    // 만큼만 남기고 앞을 버린다.
    setState(() {
      _entered += digit;
      if (_entered.length > 20) {
        _entered = _entered.substring(_entered.length - 20);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: Center(
            child: Text(
              _entered,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 26),
                  _DialKeyButton(
                    entry: _keys[row * 3 + col],
                    palette: palette,
                    onTap: () => _press(_keys[row * 3 + col].digit),
                  ),
                ],
              ],
            ),
          ),
        TextButton(
          onPressed: widget.onHide,
          child: Text(
            '숨기기',
            style: TextStyle(color: palette.textPrimary, fontSize: 17),
          ),
        ),
      ],
    );
  }
}

class _DialKeyButton extends StatelessWidget {
  const _DialKeyButton({
    required this.entry,
    required this.palette,
    required this.onTap,
  });

  final _DialKey entry;
  final CallPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: palette.controlIdle,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.digit,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
              if (entry.letters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    entry.letters,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
