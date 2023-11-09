// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';

import 'package:flutter_openwrap_sdk/flutter_openwrap_sdk.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:meta/meta.dart';

import 'gam_event_listener_declaration.dart';
import 'helper/gam_event_handler_constants.dart';

/// Base class for GAM's event handlers, for holding common properties and methods.
abstract class GAMBaseEventHandler {
  @protected
  final String tag;

  /// GAM Ad Unit Id.
  @protected
  final String gamAdUnitId;

  /// [Timer] to synchronize the [onAppEvent] of GAM SDK's onAdLoaded callback.
  Timer? _timer;

  /// Flag to identify if PubMatic bid wins the current impression.
  @protected
  bool? notifyBidWin;

  /// Listener to pass GAM app event.
  @protected
  POBAdEventListener? adEventListener;

  /// Listener to pass GAM app event
  GAMAppEventListener? _appEventListener;

  /// Config listener to check if publisher want to config properties in GAM ad
  @protected
  GAMConfigureListener? configureListener;

  /// Flag to check whether app event is expected.
  @protected
  bool isAppEventExpected = false;

  /// Base class for gam event handler implementation.
  @protected
  GAMBaseEventHandler({required this.tag, required this.gamAdUnitId});

  void _resetDelay() {
    _timer?.cancel();
    _timer = null;
  }

  @protected
  void scheduleDelay() {
    log('$tag: Schedule Delay of 400 milliseconds.');
    _resetDelay();
    _timer = Timer(Duration(milliseconds: 400), notifyPOBAboutAdReceived);
  }

  @protected
  void notifyPOBAboutAdReceived() {
    // If onAppEvent is not called within 400 milli-sec, consider that GAM wins
    if (notifyBidWin == null) {
      // Notify POB Flutter Plugin about GAM ad win state and set the state
      log('Ad Server Won.');
      notifyBidWin = false;
      adEventListener?.onAdServerWin();
    }
  }

  void onAppEvent(Ad ad, String name, String bidId) {
    log('$tag: On app event received');
    log('$tag: $ad onAppEvent: $name : $bidId');
    if (name == pubmaticWinKey && notifyBidWin == null) {
      // If onAppEvent is called before onAdLoaded(), it means POB bid wins
      notifyBidWin = true;
      adEventListener?.onOpenWrapPartnerWin(bidId);
    }
    // Give callback to publisher.
    _appEventListener?.call(name, bidId);
  }

  /// Publisher should set the [GAMAppEventListener] only when publisher need GAM
  /// SDK's app event callback
  set appEventListener(GAMAppEventListener appEventListener) =>
      _appEventListener = appEventListener;

  /// Publisher should set the [GAMConfigureListener] only when publisher needs
  /// to set the targeting parameters over GAM banner ad.
  set gamConfigureListener(GAMConfigureListener configureListener) =>
      this.configureListener = configureListener;

  @protected
  void cleanUp() {
    _resetDelay();
    adEventListener = null;
    _appEventListener = null;
    configureListener = null;
  }
}
