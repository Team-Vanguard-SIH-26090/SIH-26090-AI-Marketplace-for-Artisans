import 'package:flutter/foundation.dart';

String get apiBaseUrl {
  if (kIsWeb) {
    // Automatically switches between your live Render URL and local testing
    return Uri.base.host.contains('onrender.com') 
        ? 'https://craftconnect-backend-li7g.onrender.com' 
        : 'http://127.0.0.1:8000';
  }
  return 'https://craftconnect-backend-li7g.onrender.com';
}