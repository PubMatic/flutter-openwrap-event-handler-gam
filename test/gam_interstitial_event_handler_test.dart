// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_openwrap_sdk/flutter_openwrap_sdk.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_openwrap_event_handler_gam/flutter_openwrap_event_handler_gam.dart';
import 'package:flutter_openwrap_event_handler_gam/src/helper/gam_event_handler_constants.dart';
import 'package:test/test.dart';

dynamic testData;
void main() {
  group('GAMBannerEventHandler Test Cases', () {
    test('Constructor properties.', () async {
      GAMInterstitialEventHandler eventHandler = GAMInterstitialEventHandler(
          adUnitId: "/15671365/pm_sdk/PMSDK-Demo-App-Interstitial");

      //check tag and adunnit
      expect(eventHandler.tag, 'GAMInterstitialEventHandler');
      expect(eventHandler.gamAdUnitId,
          '/15671365/pm_sdk/PMSDK-Demo-App-Interstitial');

      //eventHandlerListener
      expect(eventHandler.adEventListener, isNull);

      //Setting adevent listener
      final temp = _EventListener();
      eventHandler.setInterstitialEventListener(temp);
      expect(eventHandler.adEventListener, isNotNull);
      expect(eventHandler.adEventListener, temp);

      eventHandler.appEventListener = (name, data) {};
      eventHandler.configureListener = () => AdManagerAdRequest();

      eventHandler.destroy();
      expect(eventHandler.configureListener, isNull);
      expect(eventHandler.adEventListener, isNull);
    });

    test('App Event Test', () {
      GAMInterstitialEventHandler eventHandler = GAMInterstitialEventHandler(
          adUnitId: "/15671365/pm_sdk/PMSDK-Demo-App-Interstitial");
      eventHandler.setInterstitialEventListener(_EventListener());
      String bidId = '1234';
      List? appEventData;
      //Test setter of appeventlistener and configlistener
      eventHandler.appEventListener = (name, data) {
        appEventData = [name, data];
      };
      eventHandler.onAppEvent(_GAMTestAd(), pubmaticWinKey, bidId);
      expect(testData, bidId);

      expect(appEventData, isNotNull);
      expect(appEventData, [pubmaticWinKey, bidId]);

      eventHandler.notifyBidWin = false;
      testData = null;
      eventHandler.onAppEvent(_GAMTestAd(), pubmaticWinKey, bidId);
      expect(testData, isNotNull);
      expect(testData[keyErrorCode], POBError.openwrapSignalingError);
      expect(testData[keyErrorMessage],
          'GAM ad server mismatched bid win signal.');
    });

    test('Timer test case', () async {
      GAMInterstitialEventHandler eventHandler = GAMInterstitialEventHandler(
          adUnitId: "/15671365/pm_sdk/PMSDK-Demo-App-Interstitial");
      eventHandler.setInterstitialEventListener(_EventListener());
      eventHandler.notifyBidWin = null;
      eventHandler.scheduleDelay();
      await Future.delayed(const Duration(milliseconds: 500), () {});
      expect(testData, true);
      eventHandler.notifyBidWin = false;
      testData = null;
      eventHandler.scheduleDelay();
      await Future.delayed(const Duration(milliseconds: 500), () {});
      expect(testData, isNull);
    });
  });
}

class _EventListener implements POBInterstitialEventListener {
  @override
  POBAdServerAdEvent get onAdClick => throw UnimplementedError();

  @override
  POBAdServerAdEvent get onAdClosed => throw UnimplementedError();

  @override
  POBAdServerAdEvent get onAdLeftApplication => throw UnimplementedError();

  @override
  POBAdServerAdEvent get onAdOpened => throw UnimplementedError();

  @override
  POBAdServerAdEvent get onAdServerWin => () => testData = true;

  @override
  POBEventError get onFailedToLoad =>
      (Map<String, Object> error) => testData = error;

  @override
  POBEventOpenWrapPartnerWin get onOpenWrapPartnerWin =>
      (bidId) => testData = bidId;

  @override
  POBAdServerAdEvent get onAdExpired => throw UnimplementedError();

  @override
  POBEventError get onFailedToShow => throw UnimplementedError();
}

class _GAMTestAd extends Ad {
  _GAMTestAd() : super(adUnitId: 'adUnitId');
}
