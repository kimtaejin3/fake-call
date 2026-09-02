class Caller {
  final String id;
  final String name;
  final String voiceId;
  final String? avatarUrl;
  final String persona;
  final String emoji;

  /// 통화 화면에 표시할 번호. 실제로 걸리지 않는 가짜 통화지만, 시스템 전화
  /// UI 는 저장된 연락처라도 이름 아래에 번호를 함께 보여주므로 이 값이
  /// 없으면 수신 화면이 진짜처럼 보이지 않는다.
  final String phoneNumber;

  const Caller({
    required this.id,
    required this.name,
    required this.voiceId,
    this.avatarUrl,
    required this.persona,
    required this.emoji,
    this.phoneNumber = '',
  });

  /// 사용자가 직접 입력한 이름으로 만드는 임시 발신자.
  ///
  /// 미리 정의된 [kCallers] 에 없는 이름을 위한 것. 번호는 이름에서
  /// 결정적으로 만들어 같은 이름이면 항상 같은 번호가 나오게 한다 —
  /// 통화할 때마다 번호가 바뀌면 수신 화면이 가짜처럼 보인다.
  factory Caller.custom(String name) {
    return Caller(
      id: 'custom',
      name: name,
      voiceId: 'voice_female_01',
      persona: 'close_friend',
      emoji: '🙂',
      phoneNumber: _fakeNumberFor(name),
    );
  }

  /// 이름 → 010-XXXX-XXXX. `String.hashCode` 는 런타임 버전에 따라 달라질 수
  /// 있어 직접 굴린다.
  static String _fakeNumberFor(String name) {
    var hash = 7;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final middle = (hash % 9000 + 1000).toString();
    final last = ((hash ~/ 9000) % 9000 + 1000).toString();
    return '010-$middle-$last';
  }
}
