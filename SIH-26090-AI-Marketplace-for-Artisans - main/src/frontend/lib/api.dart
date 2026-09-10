import 'package:flutter/foundation.dart';

String get apiBaseUrl {
  if (kIsWeb) {
    // If opened via your Render URL, use the live backend. 
    // Otherwise, fallback to localhost for local testing.
    return Uri.base.host.contains('onrender.com') 
        ? 'https://craftconnect-backend-li7g.onrender.com' 
        : 'http://127.0.0.1:8000';
  }
  // For physical mobile devices/emulators
  return 'https://craftconnect-backend-li7g.onrender.com';
}