import 'web_notification_helper_stub.dart'
    if (dart.library.html) 'web_notification_helper_web.dart';

/// Platform-agnostic notification helper.
/// Uses browser Notifications API on web, no-op on native.
class WebNotificationHelper {
  static bool get isSupported => WebNotificationHelperImpl.isSupported;
  static String get permission => WebNotificationHelperImpl.permission;
  static Future<bool> requestPermission() =>
      WebNotificationHelperImpl.requestPermission();
  static void show(String title, {String? body}) =>
      WebNotificationHelperImpl.show(title, body: body);
}
