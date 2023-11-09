// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'dart:io';

import 'package:flutter_openwrap_sdk/flutter_openwrap_sdk.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'gam_event_handler_constants.dart';

/// Common utility class
class GAMEventHandlerUtils {
  static const String tag = 'GAMEventHandlerUtils';

  /// Function to update the [AdManagerAdRequest] with the openWrapTargeting
  /// create the new [AdManagerAdRequest] if the [AdManagerAdRequest.customTargeting]
  /// is not present else update the targeting in the existing [AdManagerAdRequest]
  static AdManagerAdRequest updateAdRequest(
      {required Map<String, String> owTargeting,
      required AdManagerAdRequest adRequest}) {
    Map<String, String> openWrapTargeting = adRequest.customTargeting ?? {};
    for (var entry in owTargeting.entries) {
      openWrapTargeting.putIfAbsent(
          entry.key.toString(), () => entry.value.toString());
      log("Targeting param: [${entry.key}] : ${entry.value}");
    }
    if (adRequest.customTargeting != null) {
      return adRequest;
    }
    return AdManagerAdRequest(
        customTargeting: openWrapTargeting,
        keywords: adRequest.keywords,
        contentUrl: adRequest.contentUrl,
        customTargetingLists: adRequest.customTargetingLists,
        extras: adRequest.extras,
        httpTimeoutMillis: adRequest.httpTimeoutMillis,
        mediationExtrasIdentifier: adRequest.mediationExtrasIdentifier,
        neighboringContentUrls: adRequest.neighboringContentUrls,
        nonPersonalizedAds: adRequest.nonPersonalizedAds,
        publisherProvidedId: adRequest.publisherProvidedId);
  }

  /// Function is used to convert the [LoadAdError] to [POBError].
  static Map<String, Object> convertGAMError(LoadAdError loadAdError) {
    Map<String, Object> error = {
      keyErrorMessage:
          'Ad Server Error(${loadAdError.code} - ${loadAdError.message})'
    };
    if (Platform.isAndroid) {
      switch (loadAdError.code) {
        case errorCodeInvalidRequestAndroid:
          error[keyErrorCode] = POBError.invalidRequest;
          break;
        case errorCodeNetworkErrorAndroid:
          error[keyErrorCode] = POBError.networkError;
          break;
        case errorCodeNoFillAndroid:
          error[keyErrorCode] = POBError.noAdsAvailable;
          break;
        default:
          error[keyErrorCode] = POBError.internalError;
          break;
      }
    } else if (Platform.isIOS) {
      switch (loadAdError.code) {
        case errorCodeInvalidRequestIOS:
          error[keyErrorCode] = POBError.invalidRequest;
          break;
        case errorCodeNetworkErrorIOS:
          error[keyErrorCode] = POBError.networkError;
          break;
        case errorCodeNoFillIOS:
          error[keyErrorCode] = POBError.noAdsAvailable;
          break;
        default:
          error[keyErrorCode] = POBError.internalError;
          break;
      }
    } else {
      error[keyErrorCode] = POBError.internalError;
    }
    return error;
  }
}
