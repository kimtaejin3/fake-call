> **[구버전 — 대체됨]** 이 문서는 `docs/DESIGN_V3.md`로 완전히 대체되었습니다. 현행 테마는
> 다크 네온이 아니라 라이트 파스텔(`lib/core/theme/app_theme.dart`)입니다. 아래 내용은
> 히스토리 보존 목적으로만 남겨두며, 구현 참고용으로 사용하지 마세요.

# AI Fake Call — 디자인 스펙 v2 (Voice AI 스타일)

레퍼런스: 최신 Voice User Interface 디자인 트렌드 — 딥 네이비/블랙 배경 위에 빛나는 블루 웨이브 오브(orb), 글로우 효과, 미래적이고 프리미엄한 AI 어시스턴트 느낌.

## 컬러 팔레트 (AppColors — 기존 필드명 유지, 값만 교체)
- `background`: #050812 (거의 검정에 가까운 딥 네이비)
- `surface`: #0E1524 (카드/타일)
- `surfaceBorder`: #FFFFFF 8% (카드 테두리, 유리 느낌) — 새 필드 추가 가능
- `accent`: #4D9FFF (블루) — CTA/수락 버튼. 초록 #4ADE80은 전부 제거
- `accentAlt`: #818CF8 (인디고, 그라데이션 끝색) — 새 필드
- `glow`: #38BDF8 (글로우/사이언) — 새 필드
- `danger`: #F43F5E (거절/종료)
- `textPrimary`: #F2F5FF
- `textSecondary`: #7E8AA6

## 그라데이션
- 주 그라데이션: #38BDF8 → #4D9FFF → #818CF8 (좌상→우하). CTA 버튼과 글로우 오브에 사용.
- 배경 비네트: 화면 상단 중앙 또는 오브 뒤에 radial glow (accent 12~18% → 투명).

## 핵심 공유 위젯 (lib/shared/widgets/)
### glow_orb.dart — `GlowOrb`
빛나는 AI 오브. CustomPainter + AnimationController로 구현 (외부 패키지 금지).
```dart
class GlowOrb extends StatefulWidget {
  const GlowOrb({super.key, this.size = 180, this.animate = true, this.intensity = 1.0, this.child});
  final double size;      // 오브 지름
  final bool animate;     // 숨쉬는/흐르는 애니메이션 여부
  final double intensity; // 글로우 강도 0.0~1.5 (말하는 중엔 1.2 등)
  final Widget? child;    // 중앙에 겹칠 위젯(이모지 아바타 등), null 가능
}
```
- 구현: 여러 겹의 반투명 원 + MaskFilter.blur 글로우, 그 위에 2~3개의 sin 곡선 웨이브 라인(시간에 따라 위상이 흐르는 파형)을 원형 클리핑 안에 그려 "에너지 웨이브" 느낌. 색은 glow→accent→accentAlt 그라데이션.
- animate=true면 3~4초 주기로 스케일 1.0~1.05 breathing + 웨이브 위상 이동.

### wave_line.dart — `VoiceWaveLine`
말하는 중 하단에 표시할 가로 파형 라인 (sin 합성, 애니메이션). `height`, `active`(true면 진폭 크게 움직임, false면 잔잔한 라인) 파라미터.

## 화면별 적용
- **Home**: 배경 딥 네이비 + 상단 radial glow. 중앙에 큰 GlowOrb(size 200 내외, child 없음). 앱명/부제는 오브 아래. CTA는 그라데이션 필 버튼(radius 20, 높이 58, 은은한 blue shadow glow).
- **선택 화면 3종**: surface 카드 + 1px surfaceBorder, 선택 항목 아이콘/이모지 원에 미묘한 blue glow. 진행 캡션(1/3 등)은 accent 색.
- **Incoming Call**: 대기 단계 — 화면 중앙 작은 GlowOrb(잔잔) + 카운트다운. 수신 단계 — caller 이름 위쪽, 중앙 GlowOrb(child로 이모지 아바타, breathing) + 뒤 radial glow, 하단 수락(그라데이션 블루)/거절(danger) 원형 버튼.
- **Active Call**: 중앙 대형 GlowOrb(child 이모지, AI가 말하는 중이면 intensity 1.2 + VoiceWaveLine active) — AI 발화 자막은 오브 아래 부드러운 페이드. 하단 컨트롤은 유리 느낌 원형 버튼(surface + border).
- **Call Complete**: 상단에 작은 GlowOrb(잔잔), 피드백 버튼 선택 시 accent 그라데이션 강조.

## 금지
- 초록색 계열 CTA(기존 #4ADE80) 사용 금지 — 전부 블루 그라데이션으로.
- 외부 패키지 추가 금지 (CustomPainter/기본 애니메이션만).
- 과한 네온 채도 금지 — 레퍼런스처럼 어둡고 은은한 글로우.
