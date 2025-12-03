import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/ui/screens/subscription/widget/planHelper.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PackageSelectBottomSheet {
  static Future<void> show(
    BuildContext context,
    ValueChanged<int> onTap,
  ) async {
    return await showModalBottomSheet(
      context: context,
      backgroundColor: context.color.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: context.screenHeight * 0.85),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.color.borderColor,
                    ),
                    height: 6,
                    width: 60,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 17, horizontal: 20),
                child: CustomText(
                  'selectPackage'.translate(context),
                  textAlign: TextAlign.start,
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
              ),

              Divider(height: 1), // Add some space between title and options
              Expanded(child: _PackageList(onTap: onTap)),
            ],
          ),
        );
      },
    );
  }
}

class _PackageList extends StatefulWidget {
  const _PackageList({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  State<_PackageList> createState() => _PackageListState();
}

class _PackageListState extends State<_PackageList> {
  int? _selectedPackageIndex;

  @override
  void initState() {
    super.initState();
    context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:
          BlocBuilder<
            FetchAdsListingSubscriptionPackagesCubit,
            FetchAdsListingSubscriptionPackagesState
          >(
            builder: (context, state) {
              if (state is FetchAdsListingSubscriptionPackagesInitial) {
                context
                    .read<FetchAdsListingSubscriptionPackagesCubit>()
                    .fetchPackages();
              }
              if (state is FetchAdsListingSubscriptionPackagesInProgress) {
                return Center(child: UiUtils.progress());
              }
              if (state is FetchAdsListingSubscriptionPackagesFailure) {
                if (state.errorMessage is ApiException) {
                  if (state.errorMessage == "no-internet") {
                    return NoInternet(
                      onRetry: () {
                        context
                            .read<FetchAdsListingSubscriptionPackagesCubit>()
                            .fetchPackages();
                      },
                    );
                  }
                }

                return const SomethingWentWrong();
              }
              if (state is FetchAdsListingSubscriptionPackagesSuccess) {
                if (state.subscriptionPackages.isEmpty) {
                  return NoDataFound(
                    onTap: () {
                      context
                          .read<FetchAdsListingSubscriptionPackagesCubit>()
                          .fetchPackages();
                    },
                  );
                }

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setStater) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            itemBuilder: (context, index) {
                              return _PackageItem(
                                model: state.subscriptionPackages[index],
                                isSelected: index == _selectedPackageIndex,
                                onTap: () {
                                  _selectedPackageIndex = index;
                                  setState(() {});
                                },
                              );
                            },
                            itemCount: state.subscriptionPackages.length,
                          ),
                        ),
                        UiUtils.buildButton(
                          context,
                          onPressed: () {
                            Navigator.pop(context);
                            if (state
                                .subscriptionPackages[_selectedPackageIndex!]
                                .isActive!) {
                              widget.onTap(
                                state
                                    .subscriptionPackages[_selectedPackageIndex!]
                                    .id!,
                              );
                              // Future.delayed(Duration.zero, () {
                              //   context.read<RenewItemCubit>().renewItem(
                              //     packageId: state
                              //         .subscriptionPackages[_selectedPackageIndex!]
                              //         .id!,
                              //     itemId: model.id!,
                              //   );
                              // });
                            } else {
                              HelperUtils.showSnackBarMessage(
                                context,
                                "pleasePurchasePackage".translate(context),
                              );
                              Navigator.pushNamed(
                                context,
                                Routes.subscriptionPackageListRoute,
                              );
                            }
                          },
                          radius: 10,
                          height: 46,
                          disabled: _selectedPackageIndex == null,
                          disabledColor: context.color.textLightColor
                              .withValues(alpha: 0.3),
                          fontSize: context.font.large,
                          buttonColor: context.color.territoryColor,
                          textColor: context.color.secondaryColor,
                          buttonTitle: "renewItem".translate(context),
                          outerPadding: const EdgeInsets.all(20),
                        ),
                      ],
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
    );
  }
}

class _PackageItem extends StatelessWidget {
  const _PackageItem({
    required this.model,
    required this.onTap,
    required this.isSelected,
  });

  final SubscriptionPackageModel model;
  final VoidCallback onTap;
  final bool isSelected;

  Widget adsWidget(BuildContext context, SubscriptionPackageModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                model.name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${model.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : model.limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  Flexible(
                    child: CustomText(
                      '${model.duration.toString()}\t${"days".translate(context)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      color: context.color.textDefaultColor.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 10.0),
          child: CustomText(
            model.finalPrice! > 0
                ? "${model.finalPrice!.currencyFormat}"
                : "free".translate(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget activeAdsWidget(BuildContext context, SubscriptionPackageModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                model.name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: model.limit == Constant.itemLimitUnlimited
                          ? "${"unlimitedLbl".translate(context)}\t${"adsLbl".translate(context)}\t\t·\t\t"
                          : '',
                      style: TextStyle(
                        color: context.color.textDefaultColor.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      children: [
                        if (model.limit != Constant.itemLimitUnlimited)
                          TextSpan(
                            text:
                                '${model.userPurchasedPackages![0].remainingItemLimit}',
                            style: TextStyle(
                              color: context.color.textDefaultColor,
                            ),
                          ),
                        if (model.limit != Constant.itemLimitUnlimited)
                          TextSpan(
                            text:
                                '/${model.limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: model.duration == Constant.itemLimitUnlimited
                            ? "${"unlimitedLbl".translate(context)}\t${"days".translate(context)}"
                            : '',
                        style: TextStyle(
                          color: context.color.textDefaultColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        children: [
                          if (model.duration != Constant.itemLimitUnlimited)
                            TextSpan(
                              text:
                                  '${model.userPurchasedPackages![0].remainingDays}',
                              style: TextStyle(
                                color: context.color.textDefaultColor,
                              ),
                            ),
                          if (model.duration != Constant.itemLimitUnlimited)
                            TextSpan(
                              text:
                                  '/${model.duration.toString()}\t${"days".translate(context)}',
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 10.0),
          child: CustomText(
            model.finalPrice! > 0
                ? "${model.finalPrice!.currencyFormat}"
                : "free".translate(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7.0),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          if (model.isActive!)
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
          InkWell(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(top: 17),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isSelected
                      ? context.color.territoryColor
                      : context.color.textDefaultColor.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: !model.isActive!
                  ? adsWidget(context, model)
                  : activeAdsWidget(context, model),
            ),
          ),
        ],
      ),
    );
  }
}
