import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/app_data.dart';
import '../../../shared/models/caller.dart';
import '../../../shared/models/scenario.dart';

/// Immutable snapshot of the user's fake-call setup selections.
class CallSetup {
  final Caller? caller;
  final Scenario? scenario;
  final DelayOption? delay;

  const CallSetup({this.caller, this.scenario, this.delay});

  CallSetup copyWith({Caller? caller, Scenario? scenario, DelayOption? delay}) {
    return CallSetup(
      caller: caller ?? this.caller,
      scenario: scenario ?? this.scenario,
      delay: delay ?? this.delay,
    );
  }

  bool get isComplete => caller != null && scenario != null && delay != null;
}

class CallSetupNotifier extends Notifier<CallSetup> {
  @override
  CallSetup build() => const CallSetup();

  void selectCaller(Caller caller) => state = state.copyWith(caller: caller);
  void selectScenario(Scenario scenario) =>
      state = state.copyWith(scenario: scenario);
  void selectDelay(DelayOption delay) => state = state.copyWith(delay: delay);
  void reset() => state = const CallSetup();
}

final callSetupProvider =
    NotifierProvider<CallSetupNotifier, CallSetup>(CallSetupNotifier.new);
