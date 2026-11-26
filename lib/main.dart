import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/home_page.dart';
import 'ui/setup_wizard.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.init();
  runApp(BpbApp(state: state));
}

class BpbApp extends StatelessWidget {
  final AppState state;
  const BpbApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      // Rebuilds only when the theme colour or mode changes (picked in Settings).
      child: ListenableBuilder(
        listenable: Listenable.merge([state.themeColor, state.themeMode]),
        builder: (context, _) => MaterialApp(
          title: 'Pani Mesh',
          debugShowCheckedModeBanner: false,
          // Android can draw the app into the navigation bar area (notably with
          // gesture navigation). Keep every route's content above that inset.
          builder: (context, child) => SafeArea(
            top: false,
            child: child ?? const SizedBox.shrink(),
          ),
          theme: buildTheme(Brightness.light, state.themeColor.value),
          darkTheme: buildTheme(Brightness.dark, state.themeColor.value),
          themeMode: state.themeMode.value,
          home: const _SplashScreen(),
        ),
      ),
    );
  }
}
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _done
          ? const _Root()
          : Scaffold(
              backgroundColor: const Color(0xFF121528),
              body: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x597C4DFF),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: Color(0x4000E5FF),
                                blurRadius: 48,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/pani_mesh_logo.png',
                              width: 132,
                              height: 132,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.hub_rounded,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Pani Mesh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'پانی اتصالی امن به دنیای آزاد',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Color(0xFFB8C0D9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The setup wizard until a VPN worker is set up, then the home page.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final needsSetup = AppScope.of(context).needsSetup;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: needsSetup ? const SetupWizard(key: ValueKey('setup')) : const HomePage(key: ValueKey('home')),
    );
  }
}
