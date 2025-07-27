import 'package:flutter/material.dart';


class SuccessFeedbackWidget extends StatefulWidget {
  final Widget child;
  final bool showSuccess;
  final String successMessage;
  final VoidCallback? onComplete;

  const SuccessFeedbackWidget({
    Key? key,
    required this.child,
    required this.showSuccess,
    required this.successMessage,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SuccessFeedbackWidget> createState() => _SuccessFeedbackWidgetState();
}

class _SuccessFeedbackWidgetState extends State<SuccessFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _fadeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(SuccessFeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSuccess && !oldWidget.showSuccess) {
      _showSuccessAnimation();
    }
  }

  void _showSuccessAnimation() async {
    await _scaleController.forward();
    await _checkController.forward();
    await _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    await _fadeController.reverse();
    await _scaleController.reverse();
    _checkController.reset();
    
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (widget.showSuccess)
          Container(
            color: Colors.black26,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _checkAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(40, 40),
                            painter: CheckmarkPainter(_checkAnimation.value),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          widget.successMessage,
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ignore: unused_local_variable
    final path = Path();
    
    // Dibuja el círculo de fondo
    final circlePaint = Paint()
      ..color = const Color(0xFFE8F5E8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );

    // Dibuja el checkmark
    if (progress > 0) {
      final checkPath = Path();
      
      // Primer trazo del checkmark
      final firstStroke = progress.clamp(0.0, 0.5) * 2;
      checkPath.moveTo(size.width * 0.25, size.height * 0.5);
      checkPath.lineTo(
        size.width * 0.25 + (size.width * 0.15) * firstStroke,
        size.height * 0.5 + (size.height * 0.15) * firstStroke,
      );

      // Segundo trazo del checkmark
      if (progress > 0.5) {
        final secondStroke = (progress - 0.5) * 2;
        checkPath.lineTo(
          size.width * 0.4 + (size.width * 0.35) * secondStroke,
          size.height * 0.65 - (size.height * 0.35) * secondStroke,
        );
      }

      canvas.drawPath(checkPath, paint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}