import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/reader_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/models/reader_settings.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderController>(
      builder: (context, controller, child) {
        final settings = controller.settings;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Reading Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Theme Selector
              const Text(
                'BACKGROUND THEME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _themeOption(
                    title: 'Light',
                    color: AppColors.readerLightBg,
                    textColor: AppColors.readerLightText,
                    isSelected: settings.themeMode == ReaderThemeMode.light,
                    onTap: () => controller.updateThemeMode(ReaderThemeMode.light),
                  ),
                  const SizedBox(width: 12),
                  _themeOption(
                    title: 'Sepia',
                    color: AppColors.readerSepiaBg,
                    textColor: AppColors.readerSepiaText,
                    isSelected: settings.themeMode == ReaderThemeMode.sepia,
                    onTap: () => controller.updateThemeMode(ReaderThemeMode.sepia),
                  ),
                  const SizedBox(width: 12),
                  _themeOption(
                    title: 'Dark',
                    color: AppColors.readerDarkBg,
                    textColor: AppColors.readerDarkText,
                    isSelected: settings.themeMode == ReaderThemeMode.dark,
                    onTap: () => controller.updateThemeMode(ReaderThemeMode.dark),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Font Size Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FONT SIZE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${settings.fontSize.toInt()} sp',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pepperRed,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: 13.0,
                      max: 26.0,
                      divisions: 13,
                      activeColor: AppColors.pepperRed,
                      inactiveColor: AppColors.pepperRedSoft,
                      onChanged: (val) => controller.updateFontSize(val),
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // Font Family Selector
              const Text(
                'TYPEFACE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _fontFamilyChip(
                    label: 'Serif',
                    isSelected: settings.fontFamily == ReaderFontFamily.serif,
                    onTap: () => controller.updateFontFamily(ReaderFontFamily.serif),
                  ),
                  const SizedBox(width: 8),
                  _fontFamilyChip(
                    label: 'Sans-Serif',
                    isSelected: settings.fontFamily == ReaderFontFamily.sansSerif,
                    onTap: () => controller.updateFontFamily(ReaderFontFamily.sansSerif),
                  ),
                  const SizedBox(width: 8),
                  _fontFamilyChip(
                    label: 'Monospace',
                    isSelected: settings.fontFamily == ReaderFontFamily.monospace,
                    onTap: () => controller.updateFontFamily(ReaderFontFamily.monospace),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption({
    required String title,
    required Color color,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.pepperRed : AppColors.divider,
              width: isSelected ? 2.2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fontFamilyChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: isSelected,
        selectedColor: AppColors.pepperRedSoft,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.pepperRed : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.pepperRed : AppColors.divider,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

