import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_openwrap_event_handler_gam/src/helper/gam_event_handler_utils.dart';
import 'package:test/test.dart';

void main() {
  group('updateAdRequest method test', () {
    test('Testing with existing custom targeting in AdRequest', () {
      AdManagerAdRequest adRequest = AdManagerAdRequest(
          contentUrl: "https://pubmatic.com",
          customTargeting: {'existingKey': 'existingValue'},
          nonPersonalizedAds: true);
      Map<String, String> openWrapTargeting = {};
      openWrapTargeting['stringKey'] = 'value';
      openWrapTargeting['intKey'] = '1';
      AdManagerAdRequest newAdRequest = GAMEventHandlerUtils.updateAdRequest(
          owTargeting: openWrapTargeting, adRequest: adRequest);
      expect(newAdRequest.contentUrl, "https://pubmatic.com");
      expect(newAdRequest.customTargeting?.containsKey('stringKey'), true);
      expect(newAdRequest.customTargeting!['stringKey'], 'value');
      expect(newAdRequest.customTargeting?.containsKey('intKey'), true);
      expect(newAdRequest.customTargeting!['intKey'], '1');
      expect(newAdRequest.customTargeting?.containsKey('existingKey'), true);
      expect(newAdRequest.customTargeting!['existingKey'], 'existingValue');
      expect(newAdRequest.nonPersonalizedAds, true);
      expect(newAdRequest == adRequest, true);
    });

    test('Testing with no custom targeting in AdRequest', () {
      AdManagerAdRequest adRequest = AdManagerAdRequest(
        contentUrl: "https://pubmatic.com",
        extras: {'extraKey': 'extraValue'},
      );
      Map<String, String> openWrapTargeting = {};
      openWrapTargeting['stringKey'] = 'value';
      openWrapTargeting['intKey'] = '1';
      AdManagerAdRequest newAdRequest = GAMEventHandlerUtils.updateAdRequest(
          owTargeting: openWrapTargeting, adRequest: adRequest);
      expect(newAdRequest.contentUrl, "https://pubmatic.com");
      expect(newAdRequest.customTargeting?.containsKey('stringKey'), true);
      expect(newAdRequest.customTargeting!['stringKey'], 'value');
      expect(newAdRequest.customTargeting?.containsKey('intKey'), true);
      expect(newAdRequest.customTargeting!['intKey'], '1');
      expect(newAdRequest.extras?.containsKey('extraKey'), true);
      expect(newAdRequest.extras!['extraKey'], 'extraValue');
      expect(newAdRequest == adRequest, false);
    });

    test('Testing with existing custom targeting key in AdRequest', () {
      AdManagerAdRequest adRequest = AdManagerAdRequest(
        customTargeting: {'existingKey': 'existingValue'},
      );
      Map<String, String> openWrapTargeting = {};
      openWrapTargeting['existingKey'] = 'newValue';
      AdManagerAdRequest newAdRequest = GAMEventHandlerUtils.updateAdRequest(
          owTargeting: openWrapTargeting, adRequest: adRequest);
      expect(newAdRequest.customTargeting?.containsKey('existingKey'), true);
      expect(newAdRequest.customTargeting!['existingKey'], 'existingValue');
    });
  });
}
