import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

// TODO(rio): Refactor this into a cleaner widget
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languages =
        (context.read<FetchSystemSettingsCubit>().getSetting(
              SystemSetting.language,
            )
            as List);
    if (languages.length <= 1) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, Routes.languageListScreenRoute);
      },
      child: StreamBuilder(
        stream: Hive.box(
          HiveKeys.languageBox,
        ).watch(key: HiveKeys.currentLanguageKey),
        builder: (context, AsyncSnapshot<BoxEvent> value) {
          final defaultLanguage = context
              .watch<FetchSystemSettingsCubit>()
              .getSetting(SystemSetting.defaultLanguage)
              .toString()
              .firstUpperCase();

          final languageCode =
              value.data?.value?['code'] ?? defaultLanguage ?? "En";

          return Row(
            children: [
              CustomText(languageCode, color: context.color.textColorDark),
              Icon(
                Icons.keyboard_arrow_down_sharp,
                color: context.color.territoryColor,
              ),
            ],
          );
        },
      ),
    );
  }
}
