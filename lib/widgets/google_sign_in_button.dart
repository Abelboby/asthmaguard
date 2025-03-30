import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String message)? onError;

  const GoogleSignInButton({
    Key? key,
    required this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _buttonAnimationController.forward();

      // Sign in with Google directly without showing dialog
      await _authService.signInWithGoogle();

      if (!mounted) return;

      // Call the success callback
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;

      // Call the error callback if provided
      if (widget.onError != null) {
        widget.onError!(e.toString());
      }

      await _buttonAnimationController.reverse();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _handleGoogleSignIn,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: Colors.red,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        )
                      : Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTextColor,
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
