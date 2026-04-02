import 'dart:async';

import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _startupTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final user = await ref
          .read(sessionUserProvider.future)
          .timeout(_startupTimeout);
      if (!mounted) return;
      if (user != null) {
        final profile = await ref
            .read(profileProvider.future)
            .timeout(_startupTimeout, onTimeout: () => null);
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          profile == null
              ? CareerAiCoachApp.profileRoute
              : CareerAiCoachApp.dashboardRoute,
        );
        return;
      }

      final role = await ref
          .read(selectedRoleProvider.future)
          .timeout(_startupTimeout, onTimeout: () => null);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        role == null ? CareerAiCoachApp.roleRoute : CareerAiCoachApp.authRoute,
      );
    } catch (error, stackTrace) {
      debugPrint('[SplashScreen._bootstrap] failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, CareerAiCoachApp.roleRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFF090913),
                  Color(0xFF150E28),
                  Color(0xFF100F1D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x229B30FF),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x44D946EF),
                  width: 26,
                ),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0x229B30FF),
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    size: 50,
                    color: Color(0xFFD946EF),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'CareerAI Coach',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Персональный карьерный рост полностью офлайн.',
                  style: TextStyle(color: Color(0xFFA7A0C8)),
                ),
                SizedBox(height: 28),
                CircularProgressIndicator(color: Color(0xFF9B30FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
