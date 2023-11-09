// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_openwrap_sdk/flutter_openwrap_sdk.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'helper/gam_event_handler_constants.dart';
import 'gam_base_event_handler.dart';
import 'helper/gam_event_handler_utils.dart';

/// This class implements the communication between the OpenWrap SDK plugin and
/// the GAM SDK plugin for a given ad unit. It implements the PubMatic's OpenWrap
/// interface. OpenWrap SDK notifies (using OpenWrap interface) to make a request
/// to GAM SDK and pass the targeting parameters. This class also creates the GAM's
/// PublisherAdView, initialize it and listen for the callback methods. And pass
/// the GAM ad event to OpenWrap SDK via POBBannerEventListener.
class GAMBannerEventHandler extends GAMBaseEventHandler
    implements POBBannerEvent {
  AdManagerBannerAd? _bannerAd;
  List<AdSize> _gamAdSizes;
  POBBannerEventListener? _eventListener;
  List<POBAdSize>? _owAdSizes;

  /// Initialise the event handler with required properties.
  /// Note: OpenWrap SDK does not support fluid ad size, it will be omitted from
  /// OpenWrap ad request.
  GAMBannerEventHandler(
      {required String adUnitId, required List<AdSize> adSizes})
      : _gamAdSizes = adSizes,
        super(tag: 'GAMBannerEventHandler', gamAdUnitId: adUnitId) {
    _owAdSizes = _getConvertedOWBannerAdSizes(gamAdSizes: _gamAdSizes);
  }

  /// Constructs an event handler instance with GAM ad unit and ad size. Use this
  /// constructor to request adaptive sizes from GAM.
  /// Note: OpenWrap SDK does not support fluid ad size, it will be omitted from
  /// OpenWrap ad request.
  GAMBannerEventHandler.withOpenWrapAdSizes(
      {required String adUnitId,
      required AdSize adSize,
      required List<POBAdSize>? openWrapAdSizes})
      : _owAdSizes = openWrapAdSizes,
        _gamAdSizes = [adSize],
        super(tag: 'GAMBannerEventHandler', gamAdUnitId: adUnitId);

  // === POBBannerEvent's methods ===
  @override
  POBEventRequestAd get requestAd =>
      ({Map<String, String>? openWrapTargeting}) {
        if (_eventListener != null) {
          isAppEventExpected = false;

          AdManagerAdRequest adRequest =
              configureListener?.call() ?? AdManagerAdRequest();

          // Update the custom targeting map in AdManagerAdRequest
          if (openWrapTargeting != null && openWrapTargeting.isNotEmpty) {
            isAppEventExpected = true;
            adRequest = GAMEventHandlerUtils.updateAdRequest(
                owTargeting: openWrapTargeting, adRequest: adRequest);
          }

          notifyBidWin = null;

          _bannerAd = AdManagerBannerAd(
            adUnitId: gamAdUnitId,
            request: adRequest,
            sizes: _gamAdSizes,
            listener: _AdManagerBannerAdListenerImpl(eventHandler: this),
          );

          log('Custom targeting : ${adRequest.customTargeting.toString()}');
          log('GAM Banner Ad unit : ${_bannerAd?.adUnitId}');

          _bannerAd?.load();
        } else {
          log('$tag: Cannot initiate ad request as the event listener is null.');
        }
      };

  @override
  POBEventGetAdSizes get requestedAdSizes => () => _owAdSizes;

  @override
  POBEventListener<POBBannerEventListener> get setEventListener =>
      (POBBannerEventListener eventListener) {
        adEventListener = eventListener;
        _eventListener = eventListener;
      };

  @override
  POBAdServerAdEvent get destroy => () {
        cleanUp();
        _bannerAd?.dispose();
        _bannerAd = null;
        _eventListener = null;
        _owAdSizes = null;
        _gamAdSizes = [];
      };

  @override
  POBEventAdServerWidget get getAdServerWidget => () {
        if (_bannerAd != null) {
          return AdWidget(ad: _bannerAd!);
        }
        log('$tag: Returning empty Container as _bannerAd has not been initlized.');
        return Container();
      };

  @override
  POBEventGetAdSize get getAdSize => () async {
        AdSize? size = await _bannerAd?.getPlatformAdSize();
        return (size != null)
            ? POBAdSize(width: size.width, height: size.height)
            : null;
      };
  //end

  /// Optional API can be used to set multiple ad sizes.
  set setGAMAdSizes(List<AdSize> gamAdSizes) => _gamAdSizes = gamAdSizes;

  /// [AdManagerBannerAdListener.onAdLoaded]
  void _onAdLoaded(Ad ad) {
    // Wait only if onAppEvent() is not already called.
    if (notifyBidWin == null) {
      // Check if POB bid delivers non-zero bids to GAM, then only wait
      if (isAppEventExpected) {
        // Wait for 400 milli-sec to get onAppEvent before conveying to POB SDK
        scheduleDelay();
      } else {
        log('Ad Server Won.');
        notifyPOBAboutAdReceived();
      }
    }
  }

  /// Convert GAM Banner's AdSizes into OW Banners [POBAdSize].
  /// This method evaluates GAM [AdSize] and convert them into [POBAdSize] list.
  List<POBAdSize>? _getConvertedOWBannerAdSizes(
      {required List<AdSize> gamAdSizes}) {
    List<POBAdSize> adSizeList = [];
    for (AdSize size in gamAdSizes) {
      if (size != AdSize.fluid) {
        adSizeList.add(POBAdSize(width: size.width, height: size.height));
      } else {
        log("$tag: OpenWrap SDK doesn't support Fluid ad size. It will be filtered from OpenWrap ad request.");
      }
    }
    return adSizeList.isNotEmpty ? adSizeList : null;
  }

  @override
  void onAppEvent(Ad ad, String name, String bidId) async {
    AdSize? size = await _bannerAd?.getPlatformAdSize();
    log('GAM Banner Ad size : ${size?.width}x${size?.height}');
    log('GAM callback partner name: $name bid id: $bidId');
    super.onAppEvent(ad, name, bidId);
    if (name == pubmaticWinKey && notifyBidWin == false) {
      // In this case onAppEvent is called in wrong order and within 400 milli-sec
      // Hence, notify POB SDK about GAM ad win state
      _eventListener?.onFailed(<String, Object>{
        keyErrorCode: POBError.openwrapSignalingError,
        keyErrorMessage: 'GAM ad server mismatched bid win signal.'
      });
      log('OpenWrap Partner Won.');
    }
  }
}

class _AdManagerBannerAdListenerImpl extends AdManagerBannerAdListener {
  final GAMBannerEventHandler _eventHandler;
  final POBBannerEventListener? _eventListener;

  _AdManagerBannerAdListenerImpl({required GAMBannerEventHandler eventHandler})
      : _eventHandler = eventHandler,
        _eventListener = eventHandler._eventListener;

  @override
  AdEventCallback? get onAdClosed => (ad) => _eventListener?.onAdClosed();

  @override
  AdEventCallback? get onAdOpened => (ad) => _eventListener?.onAdOpened();

  @override
  AdLoadErrorCallback? get onAdFailedToLoad => (ad, error) {
        _eventHandler._bannerAd?.dispose();
        //give callback through event listener
        _eventListener?.onFailed(GAMEventHandlerUtils.convertGAMError(error));
      };

  @override
  AdEventCallback? get onAdClicked => (ad) => _eventListener?.onAdClick();

  @override
  AdEventCallback? get onAdImpression => (ad) {
        log('GAM banner recorded the impression');
        _eventListener?.onAdServerImpressionRecorded();
      };

  @override
  AdEventCallback? get onAdLoaded => (ad) => _eventHandler._onAdLoaded(ad);

  @override
  void Function(Ad ad, String name, String data)? get onAppEvent =>
      ((ad, name, data) => _eventHandler.onAppEvent(ad, name, data));
}
