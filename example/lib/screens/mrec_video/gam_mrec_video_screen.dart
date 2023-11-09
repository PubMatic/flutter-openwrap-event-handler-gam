import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_openwrap_event_handler_gam/flutter_openwrap_event_handler_gam.dart';
import 'package:flutter_openwrap_sdk/flutter_openwrap_sdk.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../helper/constants.dart';

class GAMMRECVideoScreen extends StatefulWidget {
  const GAMMRECVideoScreen({Key? key}) : super(key: key);

  @override
  State<GAMMRECVideoScreen> createState() => _GAMMRECVideoScreen();
}

class _GAMMRECVideoScreen extends State<GAMMRECVideoScreen> {
  late POBBannerAd _bannerAd;

  @override
  void initState() {
    super.initState();
    POBApplicationInfo applicationInfo = POBApplicationInfo();

    if (Platform.isAndroid) {
      // A valid Play Store Url of an Android application is required.
      applicationInfo.storeURL = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.example.android&hl=en');
    } else if (Platform.isIOS) {
      // Set a valid App Store URL, containing the app id of your iOS app.
      applicationInfo.storeURL = Uri.parse(
          'https://itunes.apple.com/us/app/pubmatic-sdk-app/id1175273098?mt=8');
    }

    // This app information is a global configuration & you need not set this for
    // every ad request(of any ad type)
    OpenWrapSDK.setApplicationInfo(applicationInfo);

    List<AdSize> adSizes = [AdSize.mediumRectangle];

    // Create a banner custom event handler for your ad server. Make sure you use
    // separate event handler objects to create each banner ad.
    // For example, The code below creates an event handler for GAM ad server.
    GAMBannerEventHandler eventHandler =
        GAMBannerEventHandler(adUnitId: bannerHBAdUnitId, adSizes: adSizes);

    // Initialise banner ad.
    _bannerAd = POBBannerAd.eventHandler(
      pubId: pubId,
      profileId: videoProfileId,
      adUnitId: gamBannerAdUnitId,
      bannerEvent: eventHandler,
    );

    // Optional listener to listen banner events.
    _bannerAd.listener = _BannerAdListener();

    // Call loadAd method on POBBannerAd instance.
    _bannerAd.loadAd();
  }

  @override
  void dispose() {
    // Destroy banner before disposing screen.
    _bannerAd.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text('GAM MREC Video'),
      ),
      body: Center(
        child: _bannerAd.getAdWidget,
      ),
    );
  }
}

/// Implementation of [POBBannerAdListener].
class _BannerAdListener implements POBBannerAdListener {
  final String _tag = 'POBBannerAdListener';

  /// Callback method Notifies that an ad has been successfully loaded and rendered.
  @override
  POBAdEvent<POBBannerAd>? get onAdReceived =>
      (POBBannerAd ad) => developer.log('$_tag: Ad Received');

  /// Callback method Notifies an error encountered while loading or rendering an ad.
  @override
  POBAdFailed<POBBannerAd>? get onAdFailed =>
      (POBBannerAd ad, POBError error) =>
          developer.log('$_tag: Ad failed with error : ${error.errorMessage}');

  /// Callback method Notifies whenever current app goes in the background due to user click.
  @override
  POBAdEvent<POBBannerAd>? get onAppLeaving =>
      (POBBannerAd ad) => developer.log('$_tag: App leaving');

  /// Callback method Notifies that the banner ad will launch a dialog on top of the current widget.
  @override
  POBAdEvent<POBBannerAd>? get onAdOpened =>
      (POBBannerAd ad) => developer.log('$_tag: Ad opened');

  /// Callback method Notifies that the banner ad has dismissed the modal on top of the current widget.
  @override
  POBAdEvent<POBBannerAd>? get onAdClosed =>
      (POBBannerAd ad) => developer.log('$_tag: Ad closed');

  /// Callback method Notifies that the banner widget is clicked.
  @override
  POBAdEvent<POBBannerAd>? get onAdClicked =>
      (POBBannerAd ad) => developer.log('$_tag: Ad Clicked');
}
