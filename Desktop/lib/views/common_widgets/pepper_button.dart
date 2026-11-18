import 'package:flutter/material.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';

class PepperButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double height;
  final double borderRadius;

  const PepperButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = 52.0,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = AppColors.pepperRed;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? effectiveColor : Colors.white,
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: isOutlined ? effectiveColor : Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isOutlined ? effectiveColor : Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: isOutlined ? Colors.transparent : effectiveColor,
      foregroundColor: isOutlined ? effectiveColor : Colors.white,
      disabledBackgroundColor: effectiveColor.withValues(alpha: 0.4),
      elevation: isOutlined ? 0 : 2,
      shadowColor: effectiveColor.withValues(alpha: 0.3),
      side: isOutlined ? BorderSide(color: effectiveColor, width: 1.5) : BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}

