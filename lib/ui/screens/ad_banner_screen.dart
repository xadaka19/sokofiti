import 'dart:io';

import 'package:eClassify/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  AdBannerWidget({
    this.padding,
    this.margin,
    this.alignment = Alignment.center,
    super.key,
  });

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;

  @override
  _AdBannerWidgetState createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    /*
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? Constant.bannerAdIdAndroid
          ///Ios key
          : Constant.bannerAdIdIOS,

      ///ios key
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Called when an ad is successfully received.
          print("Admob was loaded.");
        },
        onAdFailedToLoad: (ad, err) {
          // Called when an ad request failed.
          print("Admob failed to load with error: $err");
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  */
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  @override
  void dispose() {
    if (_bannerAd != null) _bannerAd!.dispose();
    super.dispose();
  }

  void _loadAd() async {
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (size == null) {
      // Unable to get width of anchored banner.
      return;
    }

    BannerAd(
      adUnitId: Platform.isAndroid
          ? Constant.bannerAdIdAndroid
          ///Ios key
          : Constant.bannerAdIdIOS,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Called when an ad is successfully received.
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          // Called when an ad request failed.
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    return _bannerAd == null
        ? SizedBox.shrink()
        : Container(
            alignment: widget.alignment,
            margin: widget.margin,
            padding: widget.padding,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
  }
}
