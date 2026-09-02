import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 저장소.
///
/// `SharedPreferences.getInstance()` 는 비동기라 위젯 트리 안에서 바로 쓸 수
/// 없다. `main()` 에서 한 번 열어 [ProviderScope.overrides] 로 주입하고,
/// 나머지 코드는 동기적으로 읽고 쓴다.
///
/// 기본값이 null 인 이유: 위젯 테스트는 이 override 없이 [ProviderScope] 를
/// 만든다. null 이면 각 Notifier 가 "저장 안 함"으로 동작해 테스트는 항상
/// 깨끗한 기본값에서 시작하고, 앱만 실제로 값을 남긴다.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// 저장 키. 오타로 값이 조용히 사라지지 않게 한곳에 모아둔다.
abstract class PrefKeys {
  /// 수신 알림 방식 ([RingtoneMode] 의 name).
  static const ringtoneMode = 'ringtone_mode';

  /// 마지막으로 전화를 건 상대 이름.
  static const lastCallerName = 'last_caller_name';
}
