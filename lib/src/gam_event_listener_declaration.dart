// ignore_for_file: depend_on_referenced_packages

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// App Event Listener
typedef GAMAppEventListener = void Function(String name, String data);

/// Configure Listener
typedef GAMConfigureListener = AdManagerAdRequest Function();
