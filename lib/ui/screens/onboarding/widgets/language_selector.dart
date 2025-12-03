import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A widget that displays the current language and allows the user to change it.
///
/// This widget:
/// - Shows the current language code (e.g., "En", "Sw")
/// - Navigates to the language selection screen when tapped
/// - Hides itself if only one language is available
///
/// Uses [LanguageCubit] for state management instead of direct Hive access.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if multiple languages are available
    if (!_hasMultipleLanguages(context)) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: () => _navigateToLanguageList(context),
      child: _LanguageDisplay(),
    );
  }

  /// Checks if the app has more than one language configured
  bool _hasMultipleLanguages(BuildContext context) {
    final languages = context.read<FetchSystemSettingsCubit>().getSetting(
      SystemSetting.language,
    );
    return languages is List && languages.length > 1;
  }

  /// Navigates to the language selection screen
  void _navigateToLanguageList(BuildContext context) {
    Navigator.pushNamed(context, Routes.languageListScreenRoute);
  }
}

/// Internal widget that displays the current language code with a dropdown icon.
///
/// Listens to [LanguageCubit] for language changes instead of using Hive streams.
class _LanguageDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        final languageCode = _getCurrentLanguageCode(context, state);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              languageCode,
              color: context.color.textColorDark,
            ),
            Icon(
              Icons.keyboard_arrow_down_sharp,
              color: context.color.territoryColor,
            ),
          ],
        );
      },
    );
  }

  /// Gets the current language code from state or falls back to default
  String _getCurrentLanguageCode(BuildContext context, LanguageState state) {
    // Try to get from current language state
    if (state is LanguageLoader) {
      final code = state.language?['code'];
      if (code != null && code.toString().isNotEmpty) {
        return code.toString().firstUpperCase();
      }
    }

    // Fall back to default language from system settings
    final defaultLanguage = context
        .read<FetchSystemSettingsCubit>()
        .getSetting(SystemSetting.defaultLanguage);

    if (defaultLanguage != null && defaultLanguage.toString().isNotEmpty) {
      return defaultLanguage.toString().firstUpperCase();
    }

    // Ultimate fallback
    return "En";
  }
}
