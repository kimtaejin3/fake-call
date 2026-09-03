import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/fake_call/presentation/incoming_call_screen.dart';
import '../../features/voice_call/presentation/active_call_screen.dart';

/// Builds a fresh router.
///
/// Screens take no arguments; all selection state (caller/scenario/delay)
/// is read from `callSetupProvider` rather than passed via route params.
///
/// The app uses the single [appRouter] instance below, but tests need a new
/// router per test — a shared one carries its current location from one test
/// into the next.
GoRouter createAppRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const ShellScreen(),
    ),
    GoRoute(
      path: Routes.incomingCall,
      builder: (context, state) => const IncomingCallScreen(),
    ),
    GoRoute(
      path: Routes.activeCall,
      builder: (context, state) => const ActiveCallScreen(),
    ),
  ],
);

/// Router instance used by the running app.
final GoRouter appRouter = createAppRouter();
