import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';

/// 처음 켰을 때 들어 있는 태그.
///
/// '친구', '직장 상사', '연인' 같은 말은 넣지 않는다 — 관계를 가리키는 말이지
/// 연락처에 저장해 둘 이름이 아니다. 수신 화면에 "직장 상사"라고 뜨면 그 자체로
/// 가짜라는 표시가 된다. 실제로 그렇게 저장하는 '엄마', '아빠' 만 남기고
/// 나머지는 사용자가 자기 연락처에 있는 이름으로 직접 채우게 한다.
const kDefaultCallerTags = ['엄마', '아빠'];

class CallerTagsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final saved = ref.watch(sharedPreferencesProvider)?.getStringList(
          PrefKeys.callerTags,
        );
    return saved ?? kDefaultCallerTags;
  }

  /// [name] 을 태그로 저장한다. 이미 있으면 아무것도 하지 않는다.
  void add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    _save([...state, trimmed]);
  }

  void remove(String name) => _save(state.where((t) => t != name).toList());

  void _save(List<String> tags) {
    state = tags;
    ref.read(sharedPreferencesProvider)?.setStringList(
          PrefKeys.callerTags,
          tags,
        );
  }
}

/// 홈에서 한 번에 채워 넣을 수 있는 이름 목록. 기기에 저장된다.
final callerTagsProvider =
    NotifierProvider<CallerTagsNotifier, List<String>>(
  CallerTagsNotifier.new,
);
