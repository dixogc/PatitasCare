import 'package:flutter/material.dart';

class NotificationHelper {
  static void showCustomNotification(
    BuildContext context, {
    required String message,
    required NotificationType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => CustomNotificationBanner(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {}, // Se manejará internamente
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss después del tiempo especificado
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class CustomNotificationBanner extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const CustomNotificationBanner({
    Key? key,
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<CustomNotificationBanner> createState() => _CustomNotificationBannerState();
}

class _CustomNotificationBannerState extends State<CustomNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFFE8F5E8);
      case NotificationType.error:
        return const Color(0xFFFFEBEE);
      case NotificationType.warning:
        return const Color(0xFFFFF3E0);
      case NotificationType.info:
        return const Color(0xFFF5F6F8);
    }
  }

  Color get _borderColor {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50);
      case NotificationType.error:
        return const Color(0xFFE53935);
      case NotificationType.warning:
        return const Color(0xFFFF9800);
      case NotificationType.info:
        return const Color(0xFFB6A9F8);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor, width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _icon,
                    color: _borderColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: _borderColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        widget.onAction?.call();
                        _dismiss();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _borderColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      color: _borderColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
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

// Extensión para usar fácilmente en cualquier contexto
extension NotificationExtension on BuildContext {
  void showSuccessNotification(String message, {String? actionLabel, VoidCallback? onAction}) {
    NotificationHelper.showCustomNotification(
      this,
      message: message,
      type: NotificationType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showErrorNotification(String message, {String? actionLabel, VoidCallback? onAction}) {
    NotificationHelper.showCustomNotification(
      this,
      message: message,
      type: NotificationType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showWarningNotification(String message, {String? actionLabel, VoidCallback? onAction}) {
    NotificationHelper.showCustomNotification(
      this,
      message: message,
      type: NotificationType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showInfoNotification(String message, {String? actionLabel, VoidCallback? onAction}) {
    NotificationHelper.showCustomNotification(
      this,
      message: message,
      type: NotificationType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}