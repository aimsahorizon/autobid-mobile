import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/modules/auth/auth_routes.dart';
import 'package:autobid_mobile/core/utils/navigator_key.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const SessionTimeoutManager({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 15), // Default 15 mins
  });

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    // Only start timer if user is logged in
    if (SupabaseConfig.client.auth.currentUser != null) {
      _timer = Timer(widget.timeoutDuration, _handleTimeout);
    }
  }

  void _handleUserInteraction([_]) {
    _startTimer();
  }

  Future<void> _handleTimeout() async {
    // Check if user is actually logged in
    if (SupabaseConfig.client.auth.currentUser != null) {
      await SupabaseConfig.client.auth.signOut();
      
      final context = navigatorKey.currentState?.context;
      if (context != null && mounted) {
         navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AuthRoutes.login, 
            (route) => false
         );
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Session expired due to inactivity')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}
