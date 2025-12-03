import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/ui/screens/subscription/widget/planHelper.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class FeaturedAdsSubscriptionPlansItem extends StatefulWidget {
  final List<SubscriptionPackageModel> modelList;
  final InAppPurchaseManager? inAppPurchaseManager;

  const FeaturedAdsSubscriptionPlansItem({
    super.key,
    required this.modelList,
    required this.inAppPurchaseManager,
  });

  @override
  _FeaturedAdsSubscriptionPlansItemState createState() =>
      _FeaturedAdsSubscriptionPlansItemState();
}

class _FeaturedAdsSubscriptionPlansItemState
    extends State<FeaturedAdsSubscriptionPlansItem> {
  String? _selectedGateway;
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      margin: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Card(
        color: context.color.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, //temp
          children: [
            SizedBox(height: 50),
            UiUtils.getSvg(AppIcons.featuredAdsIcon),
            SizedBox(height: 35),
            CustomText(
              "featureAd".translate(context),
              fontWeight: FontWeight.w600,
              fontSize: context.font.larger,
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                itemBuilder: (context, index) {
                  return itemData(widget.modelList[index], index);
                },
                separatorBuilder: (context, index) => 2.vGap,
                itemCount: widget.modelList.length,
              ),
            ),
            if (selectedIndex != null) payButtonWidget(),
          ],
        ),
      ),
    );
  }

  Widget itemData(SubscriptionPackageModel package, int index) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      alignment: Alignment.topCenter,
      curve: Curves.decelerate,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          if (package.isActive!)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 13.0),
              child: ClipPath(
                clipper: CapShapeClipper(),
                child: Container(
                  color: context.color.territoryColor,
                  width: MediaQuery.of(context).size.width / 3,
                  height: 17,
                  padding: EdgeInsets.only(top: 3),
                  child: CustomText(
                    'activePlanLbl'.translate(context),
                    color: context.color.secondaryColor,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: 17),
            child: GestureDetector(
              onTap: !package.isActive!
                  ? () {
                      setState(() {
                        selectedIndex = index;
                      });
                    }
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: package.isActive! || index == selectedIndex
                        ? context.color.territoryColor
                        : context.color.textDefaultColor.withValues(
                            alpha: 0.13,
                          ),
                    width: 1.5,
                  ),
                ),
                child: adsWidget(
                  widget.modelList[index],
                  isSelected: selectedIndex == index,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget adsWidget(
    SubscriptionPackageModel package, {
    required bool isSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    package.name!,
                    firstUpperCaseWidget: true,
                    fontWeight: FontWeight.w600,
                    fontSize: context.font.large,
                  ),
                  if (package.isActive ?? false)
                    activeAdLimits(package)
                  else
                    inactiveAdLimits(package),
                ],
              ),
            ),
            CustomText(
              package.finalPrice! > 0
                  ? package.finalPrice!.currencyFormat
                  : "free".translate(context),
              fontSize: context.font.large,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        if (package.description != null && package.description!.isNotEmpty)
          CustomText(package.description!, maxLines: isSelected ? null : 1),
      ],
    );
  }

  Widget inactiveAdLimits(SubscriptionPackageModel package) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          '${package.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : package.limit.toString()}\t${"adsLbl".translate(context)} ',
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          color: context.color.textDefaultColor.withValues(alpha: 0.5),
        ),
        Flexible(
          child: CustomText(
            '${package.duration.toString()}\t${"days".translate(context)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            color: context.color.textDefaultColor.withAlpha(50),
          ),
        ),
      ],
    );
  }

  Widget activeAdLimits(SubscriptionPackageModel package) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: package.limit == Constant.itemLimitUnlimited
                ? "${"unlimitedLbl".translate(context)}\t${"adsLbl".translate(context)}\t\t·\t\t"
                : '',
            style: TextStyle(
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
            ),
            children: textRichChildNotForUnlimited(
              package.limit == Constant.itemLimitUnlimited,
              '${package.userPurchasedPackages![0].remainingItemLimit}',
              '/${package.limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
            ),
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: package.duration == Constant.itemLimitUnlimited
                  ? "${"unlimitedLbl".translate(context)}\t${"days".translate(context)}"
                  : '',
              style: TextStyle(
                color: context.color.textDefaultColor.withValues(alpha: 0.5),
              ),
              children: textRichChildNotForUnlimited(
                package.limit == Constant.itemLimitUnlimited,
                '${package.userPurchasedPackages![0].remainingDays}',
                '/${package.duration.toString()}\t${"days".translate(context)}',
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  List<InlineSpan>? textRichChildNotForUnlimited(
    bool isUnlimited,
    String text1,
    String text2,
  ) {
    if (isUnlimited) return null;
    return [
      TextSpan(
        text: text1,
        style: TextStyle(color: context.color.textDefaultColor),
      ),
      TextSpan(text: text2),
    ];
  }

  Widget payButtonWidget() {
    return PlanHelper().purchaseButtonWidget(
      context,
      widget.modelList[selectedIndex!],
      _selectedGateway,
      iosCallback: (String productId, String packageId) {
        widget.inAppPurchaseManager!.buy(productId, packageId);
      },
      changePaymentGateway: (String selectedPaymentGateway) {
        setState(() {
          _selectedGateway = selectedPaymentGateway;
        });
      },
    );
  }
}
