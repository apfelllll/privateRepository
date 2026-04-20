import 'package:doordesk/app.dart';
import 'package:doordesk/core/config/supabase_config.dart';
import 'package:doordesk/mobile/app_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void _ensureWebViewPlatformRegistered() {
  if (WebViewPlatform.instance != null) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      WebViewPlatform.instance = AndroidWebViewPlatform();
      break;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      WebViewPlatform.instance = WebKitWebViewPlatform();
      break;
    default:
      break;
  }
}

bool _isMobilePlatform() {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureWebViewPlatformRegistered();
  await SupabaseConfig.initialize();

  final Widget appRoot =
      _isMobilePlatform() ? const DoorDeskMobileApp() : const DoorDeskApp();

  runApp(
    ProviderScope(
      child: appRoot,
    ),
  );
}
