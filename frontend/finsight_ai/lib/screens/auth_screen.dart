import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = LocalAuthentication();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isAvail = await _auth.isDeviceSupported();
      if (!canCheck || !isAvail) {
        widget.onAuthenticated();
        return;
      }

      final success = await _auth.authenticate(
        localizedReason: 'Use your fingerprint to open FinSight AI',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      if (success) {
        widget.onAuthenticated();
      } else {
        setState(() => _error = 'Authentication failed. Try again.');
      }
    } catch (_) {
      widget.onAuthenticated(); // non-Android or simulator — pass through
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bg,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppTheme.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 44,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FinSight AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your private finance assistant',
                style: TextStyle(fontSize: 15, color: AppTheme.muted),
              ),
              const SizedBox(height: 56),

              GestureDetector(
                onTap: _loading ? null : _authenticate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _loading ? AppTheme.subtle : AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: _loading
                        ? []
                        : [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        )
                      : const Icon(
                          Icons.fingerprint_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _loading ? 'Verifying...' : 'Tap to unlock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _loading ? AppTheme.muted : AppTheme.primary,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerSoft,
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _authenticate,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
