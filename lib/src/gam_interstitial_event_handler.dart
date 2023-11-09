// ignore_for_file: depend_on_referenced_packages

import 'dart:core';
import 'dart:developer';

import 'package:flutter_openwrap_sdk/flutter_openwrap_sdk.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'gam_base_event_handler.dart';
import 'helper/gam_event_handler_constants.dart';
import 'helper/gam_event_handler_utils.dart';

/// This class implements the communication between the OpenWrap SDK plugin and
/// the GAM SDK plugin for a given ad unit. It implements the PubMatic's OpenWrap
/// interface. OpenWrap SDK notifies (using OpenWrap interface) to make a request
/// to GAM SDK and pass the targeting parameters. This class also creates the GAM's
/// PublisherAdView, initialize it and listen for the callback methods. And pass
/// the GAM ad event to OpenWrap SDK via POBInterstitialEventListener.
class GAMInterstitialEventHandler extends GAMBaseEventHandler
    implements POBInterstitialEvent {
  AdManagerInterstitialAd? _interstitialAd;
  POBInterstitialEventListener? _eventListener;

  /// Initialise the event handler with required properties.
  GAMInterstitialEventHandler({required String adUnitId})
      : super(tag: 'GAMInterstitialEventHandler', gamAdUnitId: adUnitId);

  @override
  POBEventRequestAd get requestAd =>
      ({Map<String, String>? openWrapTargeting}) {
        isAppEventExpected = false;
        AdManagerAdRequest? adRequest =
            configureListener?.call() ?? AdManagerAdRequest();
        if (openWrapTargeting != null && openWrapTargeting.isNotEmpty) {
          isAppEventExpected = true;
          adRequest = GAMEventHandlerUtils.updateAdRequest(
              owTargeting: openWrapTargeting, adRequest: adRequest);
        }
        log('Custom targeting : ${adRequest.customTargeting.toString()}');
        log('GAM Interstitial Ad unit : $gamAdUnitId');

        notifyBidWin = null;
        AdManagerInterstitialAd.load(
          adUnitId: gamAdUnitId,
          request: adRequest,
          adLoadCallback: AdManagerInterstitialAdLoadCallback(
            onAdLoaded: _onAdLoaded,
            onAdFailedToLoad: (LoadAdError error) {
              log('$tag AdManagerInterstitialAd failed to load: $error.');
              _eventListener?.onFailedToLoad(
                GAMEventHandlerUtils.convertGAMError(error),
              );
            },
          ),
        );
      };

  @override
  void onAppEvent(Ad ad, String name, String bidId) async {
    super.onAppEvent(ad, name, bidId);
    log('GAM callback partner name: $name bid id: $bidId');
    if (name == pubmaticWinKey && notifyBidWin == false) {
      // In this case onAppEvent is called in wrong order and within 400 milli-sec
      // Hence, notify POB SDK about GAM ad win state
      _eventListener?.onFailedToLoad(<String, Object>{
        keyErrorCode: POBError.openwrapSignalingError,
        keyErrorMessage: 'GAM ad server mismatched bid win signal.'
      });
      log('OpenWrap Partner Won.');
    }
  }

  /// On the Ad Loaded callback from GAM we set the AppEventListener and schedule the delay
  void _onAdLoaded(AdManagerInterstitialAd ad) {
    log('$tag $ad loaded');
    _interstitialAd = ad;
    _interstitialAd?.appEventListener = AppEventListener()
      ..onAppEvent = onAppEvent;
    _interstitialAd?.fullScreenContentCallback = _VideoFullScreenCallbacks(
      tag: tag,
      eventListener: _eventListener,
    );
    // Wait only if onAppEvent() is not already called.
    if (notifyBidWin == null) {
      // Check if POB bid delivers non-zero bids to GAM, then only wait
      if (isAppEventExpected) {
        // Wait for 400 milli-sec to get onAppEvent before conveying to POB Flutter Plugin
        scheduleDelay();
      } else {
        log('Ad Server Won.');
        notifyPOBAboutAdReceived();
      }
    }
  }

  @override
  POBAdServerAdEvent get show => () => _interstitialAd?.show();

  @override
  POBEventListener<POBInterstitialEventListener>
      get setInterstitialEventListener =>
          (POBInterstitialEventListener listener) {
            adEventListener = listener;
            _eventListener = listener;
          };

  @override
  POBAdServerAdEvent get destroy => () {
        cleanUp();
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _eventListener = null;
      };
}

/// Implementation of [FullScreenContentCallback] for [AdManagerInterstitialAd]
/// It takes [POBInterstitialEventListener] as parameter to delegate the callbacks
class _VideoFullScreenCallbacks
    implements FullScreenContentCallback<AdManagerInterstitialAd> {
  final POBInterstitialEventListener? _eventListener;
  String tag;

  _VideoFullScreenCallbacks(
      {required this.tag, POBInterstitialEventListener? eventListener})
      : _eventListener = eventListener;

  @override
  GenericAdEventCallback<AdManagerInterstitialAd>? get onAdClicked =>
      (AdManagerInterstitialAd ad) {
        log('$tag $ad onAdClick');
        _eventListener?.onAdClick();
      };

  @override
  GenericAdEventCallback<AdManagerInterstitialAd>?
      get onAdDismissedFullScreenContent => (AdManagerInterstitialAd ad) {
            log('$tag $ad onAdDismissedFullScreenContent');
            _eventListener?.onAdClosed();
          };

  @override
  void Function(AdManagerInterstitialAd ad, AdError error)?
      get onAdFailedToShowFullScreenContent =>
          (AdManagerInterstitialAd ad, AdError error) {
            log('$tag $ad onAdFailedToShowFullScreenContent : $error');
            _eventListener?.onFailedToShow({
              keyErrorCode: POBError.renderError,
              keyErrorMessage: error.message,
            });
          };

  @override
  GenericAdEventCallback<AdManagerInterstitialAd>? get onAdImpression =>
      (AdManagerInterstitialAd ad) => log('$tag $ad onAdImpression');

  @override
  GenericAdEventCallback<AdManagerInterstitialAd>?
      get onAdShowedFullScreenContent => (AdManagerInterstitialAd ad) {
            log('$tag $ad onAdShowedFullScreenContent');
            _eventListener?.onAdOpened();
          };

  @override
  GenericAdEventCallback<AdManagerInterstitialAd>?
      get onAdWillDismissFullScreenContent => (AdManagerInterstitialAd ad) {
            log('$tag $ad onAdWillDismissFullScreenContent');
          };
}
