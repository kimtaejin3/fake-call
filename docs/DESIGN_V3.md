# 디자인 v3 — 라이트 파스텔 & 심플 (현행 스펙, v2 다크 스펙을 대체)

레퍼런스: 밝은 라벤더/퍼플 파스텔 배경, 흰 카드, 중앙의 귀여운 그라데이션 오브 마스코트(눈 2개),
말풍선 같은 심플 칩. "AI 느낌(어두운 네온/웨이브)"을 걷어내고 부드럽고 친근하게.

## 컬러 팔레트 v3 (AppColors — 필드명 유지, 값 교체)
- `background`: #F6F4FE (라벤더빛 화이트)
- `surface`: #FFFFFF (카드)
- `surfaceBorder`: #E9E5F8 (아주 옅은 보라 테두리)
- `accent`: #8B7CF6 (소프트 바이올렛)
- `accentAlt`: #7C9BF8 (퍼리윙클 블루)
- `glow`: #C4B5FD (라이트 라벤더 — 그라데이션 시작색)
- `danger`: #F87171 (소프트 레드)
- `textPrimary`: #3E3A5F (딥 인디고)
- `textSecondary`: #9A94B8
- accentGradient = [glow, accent, accentAlt]

## 스타일 원칙
- 밝은 배경 + 흰 카드 + **부드러운 그림자**(BoxShadow: accent 8~12% alpha, blur 20+, offset(0,8)) — 네온 글로우 금지.
- 배경에 아주 옅은 파스텔 radial 블러 원 2~3개(라벤더/핑크/블루, alpha 0.15~0.25)를 코너에 배치해 레퍼런스의 몽글몽글한 느낌.
- 라운드는 크고 부드럽게 (카드 20~24, 칩 pill).
- StatusBar/시스템 UI: 라이트 배경용 다크 아이콘.

## SoftOrb (GlowOrb 대체 — lib/shared/widgets/glow_orb.dart를 수정하거나 soft_orb.dart 신설)
```dart
class SoftOrb extends StatefulWidget {
  const SoftOrb({super.key, this.size = 180, this.animate = true, this.speaking = false, this.showFace = true});
}
```
- 구/블롭: RadialGradient(#C4B5FD 상단좌측 하이라이트 → #8B7CF6 중심 → #6D5BD0 하단), 아래에 부드러운 타원 그림자.
- **얼굴**: 중앙에 세로로 긴 라운드 사각 눈 2개(흰색, 레퍼런스처럼). speaking=true면 눈이 살짝 위아래로 통통 튀거나 깜빡임 애니메이션. showFace=false면 눈 없음.
- animate=true: 3~4초 breathing(스케일 1.0~1.04) + 아주 미세한 상하 float.
- 웨이브 라인/네온 링 없음.
- 기존 GlowOrb 사용처와의 호환: GlowOrb를 SoftOrb 기반으로 재작성하고 기존 파라미터(intensity, child)는 받되 무시/매핑해도 됨. 혹은 사용처를 전부 SoftOrb로 교체.

## 홈 탭 — 심플 구성 (레퍼런스 구도 그대로)
위→아래:
1. 캐치프라이즈: "곤란한 자리에선," (작게) / "전화 한 통이면 돼요" (크게, textPrimary, 중앙 정렬)
2. 중앙 대형 SoftOrb(size 200~220, 얼굴 있음) — 화면의 주인공.
3. 하단 2x2 빠른 시나리오 칩 (흰 pill 카드 + 아이콘 + 짧은 라벨, 부드러운 그림자):
   - "👩 엄마가 불러요" → caller=mom, scenario=come_home
   - "💼 회사에 일이" → caller=boss, scenario=work_problem
   - "🚨 급한 일이" → caller=friend, scenario=urgent
   - "💛 그냥 통화" → caller=partner, scenario=casual
   (이모지 대신 Material 아이콘 사용: family/work/priority_high/favorite 등 — 웹 이모지 깨짐 방지)
   선택된 칩은 accent 테두리 + 연보라 배경.
4. 최하단 pill 바 (레퍼런스의 입력바 위치): 흰 pill, 왼쪽에 시간 텍스트 버튼("30초 후" — 탭하면 라운드 바텀시트에서 지금/10초/30초/1분/3분 선택), 오른쪽 끝에 원형 그라데이션 통화 버튼(Icons.call) → `context.go(Routes.incomingCall)`.
- 기본 선택: 엄마 칩 + 30초.
- 상세 선택(다른 조합)은 MVP에선 이 4개 프리셋으로 충분 — 기존 섹션형 UI 제거.
- callSetupProvider 그대로 사용(칩 탭 시 selectCaller+selectScenario 동시 호출).

## 다른 화면 라이트 적용
- 셸 NavigationBar: 흰 배경, 위 1px surfaceBorder, 선택 accent.
- 수신 화면: 밝은 배경 + 파스텔 블러 원, 중앙 SoftOrb(얼굴 있음), 이름/수신전화 textPrimary. 수락=그라데이션 원형, 거절=danger 원형(소프트 그림자).
- 통화 화면: 동일 톤. SoftOrb(speaking = AI 발화 중). VoiceWaveLine은 색만 파스텔로(accent 40%) 유지하거나 제거 — 유지 시 은은하게.
- 완료/기록/설정/선택 화면: 흰 카드 + surfaceBorder + 소프트 그림자, 텍스트 컬러 교체.
- 다크 하드코딩(#050812, #0E1524, Colors.white 계열 텍스트 등) 잔재 전부 제거.

## 테스트
flow_test: 홈 상호작용 변경 — '지금' 선택은 시간 pill 탭 → 바텀시트에서 '지금' 탭으로. 시작은 통화 버튼(Icons.call 아이콘 버튼) 탭. 이후 동일.
