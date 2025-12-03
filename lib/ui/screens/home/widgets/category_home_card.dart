import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class CategoryHomeCard extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;
  const CategoryHomeCard({
    super.key,
    required this.title,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          spacing: 4,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: context.color.secondaryColor,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: UiUtils.imageType(url, fit: BoxFit.cover),
                ),
              ),
            ),
            Expanded(
              child: CustomText(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                fontSize: context.font.smaller,
                color: context.color.textDefaultColor.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
