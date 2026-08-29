import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single completed fake-call entry shown in the history tab.
///
/// MVP: kept in memory only (no persistence) — cleared on app restart.
class CallRecord {
  final String callerName;
  final String scenarioTitle;
  final DateTime endedAt;
  final int durationSeconds;

  /// 'positive' / 'negative' / null (no feedback given).
  final String? feedback;

  const CallRecord({
    required this.callerName,
    required this.scenarioTitle,
    required this.endedAt,
    required this.durationSeconds,
    this.feedback,
  });
}

class CallHistoryNotifier extends Notifier<List<CallRecord>> {
  @override
  List<CallRecord> build() => const [];

  /// Inserts [record] at the front so the list stays newest-first.
  void add(CallRecord record) => state = [record, ...state];
}

final callHistoryProvider =
    NotifierProvider<CallHistoryNotifier, List<CallRecord>>(
  CallHistoryNotifier.new,
);

/// Elapsed seconds of the most recently ended call.
///
/// [ActiveCallScreen] writes this right before navigating away so
/// [CallCompleteScreen] — which has no direct access to the call timer —
/// can read it back when building the [CallRecord] to store in
/// [callHistoryProvider].
final lastCallDurationProvider = StateProvider<int>((ref) => 0);
