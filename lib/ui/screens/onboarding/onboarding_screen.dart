import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/ui/screens/onboarding/widgets/language_selector.dart';
import 'package:eClassify/ui/screens/onboarding/widgets/onboarding_page_view.dart';
import 'package:eClassify/ui/screens/onboarding/widgets/page_indicator.dart';
import 'package:eClassify/ui/screens/widgets/skip_button_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: SafeArea(
          top: false,
          bottom: Platform.isAndroid,
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: .1),
                        blurRadius: 4,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    spacing: 20,
                    children: [
                      MediaQuery.paddingOf(context).top.vGap,
                      Padding(
                        padding: Constant.appContentPadding,
                        child: Row(
                          children: [
                            LanguageSelector(),
                            const Spacer(),
                            SkipButtonWidget(
                              onTap: () {
                                HiveUtils.setUserIsNotNew();
                                HiveUtils.setUserSkip();

                                Navigator.pushReplacementNamed(
                                  context,
                                  Routes.login,
                                  arguments: {
                                    "from": "login",
                                    "isSkipped": true,
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: Constant.appContentPadding,
                          child: OnboardingPageView(controller: _controller),
                        ),
                      ),
                      PageIndicator(
                        controller: _controller,
                        count: kSlidersList.length,
                      ),
                      10.vGap,
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Center(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      final isLast =
                          _controller.page?.round() == kSlidersList.length - 1;
                      return UiUtils.buildButton(
                        context,
                        onPressed: () {
                          if (isLast) {
                            HiveUtils.setUserIsNotNew();
                            HiveUtils.setUserSkip();

                            Navigator.pushReplacementNamed(
                              context,
                              Routes.login,
                              arguments: {"from": "login", "isSkipped": true},
                            );
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.decelerate,
                            );
                          }
                        },
                        outerPadding: Constant.appContentPadding,
                        radius: 16,
                        buttonTitle: isLast
                            ? 'getStarted'.translate(context)
                            : 'next'.translate(context),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
