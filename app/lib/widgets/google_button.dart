import 'package:flutter/material.dart';

class GoogleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (!widget.isLoading) _controller.forward();
      },
      onPointerUp: (_) {
        if (!widget.isLoading) _controller.reverse();
      },
      onPointerCancel: (_) {
        if (!widget.isLoading) _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.grey[300],
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(double.infinity, 54),
          ),
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: widget.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      "https://firebasestorage.googleapis.com/v0/b/flutterbricks-public.appspot.com/o/crypto%2Fsearch%20(2).png?alt=media&token=24a918f7-3564-4290-b7e4-08ff54b3c94c",
                      width: 24,
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
