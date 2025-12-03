import 'dart:io';

import 'package:eClassify/data/cubits/subscription/assign_free_package_cubit.dart';
import 'package:eClassify/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:eClassify/data/cubits/subscription/fetch_featured_subscription_packages_cubit.dart';
import 'package:eClassify/data/cubits/subscription/get_payment_intent_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/cubits/system/get_api_keys_cubit.dart';
import 'package:eClassify/data/model/subscription/subscription_package_model.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/ui/screens/subscription/widget/featured_ads_subscription_plan_item.dart';
import 'package:eClassify/ui/screens/subscription/widget/item_listing_subscription_plans_item.dart';
import 'package:eClassify/ui/screens/subscription/widget/subscription_slider.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionPackageListScreen extends StatefulWidget {
  const SubscriptionPackageListScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        return SubscriptionPackageListScreen();
      },
    );
  }

  @override
  State<SubscriptionPackageListScreen> createState() =>
      _SubscriptionPackageListScreenState();
}

class _SubscriptionPackageListScreenState
    extends State<SubscriptionPackageListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  List<SubscriptionPackageModel> iapListingAdsProducts = [];
  List<String> listingAdsProducts = [];
  List<SubscriptionPackageModel> iapFeaturedAdsProducts = [];
  List<String> featuredAdsProducts = [];
  late final InAppPurchaseManager? _inAppPurchaseManager;

  late final bool isFreeAdListingEnabled;

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
    if (HiveUtils.isUserAuthenticated()) {
      context.read<GetApiKeysCubit>().fetch();
    }
    context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
    context.read<FetchFeaturedSubscriptionPackagesCubit>().fetchPackages();
    if (Platform.isIOS) {
      InAppPurchaseManager.getPending();
      _inAppPurchaseManager = InAppPurchaseManager();
      _inAppPurchaseManager!.listenIAP(context);
    } else {
      _inAppPurchaseManager = null;
    }
    isFreeAdListingEnabled =
        context.read<FetchSystemSettingsCubit>().getSetting(
          SystemSetting.freeAdListing,
        ) ==
        "1";
    if (!isFreeAdListingEnabled) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _inAppPurchaseManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {
        AdHelper.showInterstitialAd();
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: AppBar(
          title: CustomText(
            "subscriptionPlan".translate(context),
            fontSize: context.font.larger,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            //This is required to comply with AppStore's guideline. Do Not Remove.
            if (Platform.isIOS)
              CupertinoButton(
                child: Text("restore".translate(context)),
                onPressed: () async {
                  await InAppPurchase.instance.restorePurchases();
                },
              ),
          ],
          bottom: isFreeAdListingEnabled
              ? null
              : TabBar(
                  controller: _tabController!,
                  tabs: [
                    Tab(text: "adsListing".translate(context)),
                    Tab(text: "featuredAdsLbl".translate(context)),
                  ],
                  dividerHeight: 0,
                  indicatorWeight: 2,
                  indicatorColor: context.color.territoryColor,
                  labelColor: context.color.territoryColor,
                  unselectedLabelColor: context.color.textDefaultColor
                      .withValues(alpha: 0.5),
                  labelStyle: TextStyle(fontSize: 16),
                  labelPadding: EdgeInsets.symmetric(horizontal: 16),
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
        ),
        body: BlocListener<GetApiKeysCubit, GetApiKeysState>(
          listener: (context, state) {
            if (state is GetApiKeysSuccess) {
              setPaymentGateways(state);
            }
          },
          child: isFreeAdListingEnabled
              ? featuredAds()
              : TabBarView(
                  controller: _tabController!,
                  children: [adsListing(), featuredAds()],
                ),
        ),
      ),
    );
  }

  Widget adsListing() {
    return BlocBuilder<
      FetchAdsListingSubscriptionPackagesCubit,
      FetchAdsListingSubscriptionPackagesState
    >(
      builder: (context, state) {
        if (state is FetchAdsListingSubscriptionPackagesInProgress) {
          return Center(child: UiUtils.progress());
        }
        if (state is FetchAdsListingSubscriptionPackagesFailure) {
          if (state.errorMessage == "no-internet") {
            return NoInternet(
              onRetry: () {
                context
                    .read<FetchAdsListingSubscriptionPackagesCubit>()
                    .fetchPackages();
              },
            );
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

          return SubscriptionSlider(
            itemBuilder: (context, index) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => AssignFreePackageCubit()),
                  BlocProvider(create: (context) => GetPaymentIntentCubit()),
                ],
                child: ItemListingSubscriptionPlansItem(
                  model: state.subscriptionPackages[index],
                  inAppPurchaseManager: _inAppPurchaseManager,
                ),
              );
            },
            itemCount: state.subscriptionPackages.length,
          );
        }

        return Container();
      },
    );
  }

  Widget featuredAds() {
    return BlocBuilder<
      FetchFeaturedSubscriptionPackagesCubit,
      FetchFeaturedSubscriptionPackagesState
    >(
      builder: (context, state) {
        if (state is FetchFeaturedSubscriptionPackagesInProgress) {
          return Center(child: UiUtils.progress());
        }
        if (state is FetchFeaturedSubscriptionPackagesFailure) {
          if (state.errorMessage == "no-internet") {
            return NoInternet(
              onRetry: () {
                context
                    .read<FetchFeaturedSubscriptionPackagesCubit>()
                    .fetchPackages();
              },
            );
          }

          return const SomethingWentWrong();
        }
        if (state is FetchFeaturedSubscriptionPackagesSuccess) {
          if (state.subscriptionPackages.isEmpty) {
            return NoDataFound(
              onTap: () {
                context
                    .read<FetchFeaturedSubscriptionPackagesCubit>()
                    .fetchPackages();
              },
            );
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => AssignFreePackageCubit()),
              BlocProvider(create: (context) => GetPaymentIntentCubit()),
            ],
            child: FeaturedAdsSubscriptionPlansItem(
              modelList: state.subscriptionPackages,
              inAppPurchaseManager: _inAppPurchaseManager,
            ),
          );
        }

        return Container();
      },
    );
  }

  void setPaymentGateways(GetApiKeysSuccess state) {
    AppSettings.stripeCurrency = state.stripeCurrency ?? "";
    AppSettings.stripePublishableKey = state.stripePublishableKey ?? "";
    AppSettings.stripeStatus = state.stripeStatus;
    AppSettings.payStackCurrency = state.payStackCurrency ?? "";
    AppSettings.payStackKey = state.payStackApiKey ?? "";
    AppSettings.payStackStatus = state.payStackStatus;
    AppSettings.razorpayKey = state.razorPayApiKey ?? "";
    AppSettings.razorpayStatus = state.razorPayStatus;
    AppSettings.phonePeCurrency = state.phonePeCurrency ?? "";
    AppSettings.phonePeKey = state.phonePeKey ?? "";
    AppSettings.phonePeStatus = state.phonePeStatus;
    AppSettings.flutterwaveKey = state.flutterWaveKey ?? "";
    AppSettings.flutterwaveCurrency = state.flutterWaveCurrency ?? "";
    AppSettings.flutterwaveStatus = state.flutterWaveStatus;
    AppSettings.phonePeCurrency = state.phonePeCurrency ?? "";
    AppSettings.bankAccountNumber = state.bankAccountNumber ?? "";
    AppSettings.bankAccountHolderName = state.bankAccountHolder ?? "";
    AppSettings.bankIfscSwiftCode = state.bankIfscSwiftCode ?? "";
    AppSettings.bankName = state.bankName ?? "";
    AppSettings.bankTransferStatus = state.bankTransferStatus;
    AppSettings.paypalCurrency = state.paypalCurrency ?? '';
    AppSettings.paypalStatus = state.paypalStatus;

    AppSettings.updatePaymentGateways();
  }
}
