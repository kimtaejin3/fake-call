import 'package:flutter/material.dart';

import '../../core/theme/call_theme.dart';

/// iOS 수신/통화 화면 위쪽의 두 줄 — 흐린 캡션(회선 라벨 또는 통화시간)
/// 위에, 굵은 발신자 이름.
///
/// 두 화면이 같은 자리에 같은 모양으로 그려야 응답을 눌렀을 때 글자가
/// 움직이지 않고 캡션만 바뀐다. 실제 아이폰도 그렇게 넘어간다.
class IosCallHeader extends StatelessWidget {
  const IosCallHeader({
    super.key,
    required this.caption,
    required this.name,
    required this.palette,
  });

  final String caption;
  final String name;
  final CallPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            caption,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 21,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
