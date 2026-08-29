import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/caller/presentation/caller_select_screen.dart';
import '../../features/scenario/presentation/scenario_select_screen.dart';
import '../../features/fake_call/presentation/delay_select_screen.dart';
import '../../features/fake_call/presentation/incoming_call_screen.dart';
import '../../features/voice_call/presentation/active_call_screen.dart';
import '../../features/feedback/presentation/call_complete_screen.dart';

/// Global app router.
///
/// Screens take no arguments; all selection state (caller/scenario/delay)
/// is read from `callSetupProvider` rather than passed via route params.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const ShellScreen(),
    ),
    GoRoute(
      path: Routes.callerSelect,
      builder: (context, state) => const CallerSelectScreen(),
    ),
    GoRoute(
      path: Routes.scenarioSelect,
      builder: (context, state) => const ScenarioSelectScreen(),
    ),
    GoRoute(
      path: Routes.delaySelect,
      builder: (context, state) => const DelaySelectScreen(),
    ),
    GoRoute(
      path: Routes.incomingCall,
      builder: (context, state) => const IncomingCallScreen(),
    ),
    GoRoute(
      path: Routes.activeCall,
      builder: (context, state) => const ActiveCallScreen(),
    ),
    GoRoute(
      path: Routes.callComplete,
      builder: (context, state) => const CallCompleteScreen(),
    ),
  ],
);
