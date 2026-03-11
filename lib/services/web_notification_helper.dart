// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebNotificationHelper {
  static bool get isSupported {
    try {
      return html.Notification.supported;
    } catch (_) {
      return false;
    }
  }

  static String get permission {
    try {
      return html.Notification.permission ?? 'default';
    } catch (_) {
      return 'denied';
    }
  }

  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final result = await html.Notification.requestPermission();
      return result == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void show(String title, {String? body}) {
    if (permission != 'granted') return;
    try {
      html.Notification(title, body: body ?? '', icon: 'icons/Icon-192.png');
    } catch (_) {
      // Notification failed — ignore
    }
  }
}
