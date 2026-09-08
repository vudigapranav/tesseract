import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../host_flow_state.dart';

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  String status = 'Notifications not checked';

  /// Called when the person taps a reminder notification, with the reminder's
  /// id. Set by the app shell so the tap can open the reminder view; without
  /// it a tap would only bring the app to whatever screen it was last on.
  void Function(int reminderId)? onReminderTapped;

  void _handleResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || !payload.startsWith('reminder:')) {
      return;
    }
    final int? id = int.tryParse(payload.substring('reminder:'.length));
    if (id != null) {
      onReminderTapped?.call(id);
    }
  }

  Future<void> initialize() async {
    if (kIsWeb) {
      status = 'Browser preview: Android notifications unavailable';
      return;
    }
    tzdata.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    await plugin.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: _handleResponse);
    ready = true;
  }

  Future<bool> permission() async {
    if (!ready) {
      await initialize();
    }
    if (!ready) {
      return false;
    }
    final allowed = await plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
    status = allowed
        ? 'Notifications allowed'
        : 'Notifications denied. Reminders remain available in the app.';
    return allowed;
  }

  Future<void> restore(List<ReminderItem> reminders,
      {required bool sound}) async {
    if (!ready) {
      await initialize();
    }
    if (!ready) {
      return;
    }
    // Reconcile by persistent IDs, avoiding duplicate schedules after edits/restarts.
    final wanted = {
      for (final r in reminders)
        if (r.enabled) r.id
    };
    for (final pending in await plugin.pendingNotificationRequests()) {
      if (!wanted.contains(pending.id) &&
          !wanted.contains(pending.id - 1000000000)) {
        await plugin.cancel(id: pending.id);
      }
    }
    for (final r in reminders) {
      if (!r.enabled) {
        await plugin.cancel(id: r.id);
        await plugin.cancel(id: r.id + 1000000000);
        continue;
      }
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, r.time.hour, r.time.minute);
      if (!next.isAfter(now)) {
        next = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1,
            r.time.hour, r.time.minute);
      }
      await schedule(r, r.id, next, sound: sound, repeat: true);
      if (r.postponedUntil != null &&
          r.postponedUntil!.isAfter(DateTime.now())) {
        await schedule(r, r.id + 1000000000,
            tz.TZDateTime.from(r.postponedUntil!, tz.local),
            sound: sound);
      }
    }
    final allowed = await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    status = allowed == true
        ? 'Scheduled on this device • ${tz.local.name}. Android may delay delivery.'
        : 'Notifications denied. Open Android settings to allow delivery.';
  }

  Future<void> schedule(ReminderItem r, int id, tz.TZDateTime time,
          {required bool sound, bool repeat = false}) =>
      plugin.zonedSchedule(
        id: id,
        title: 'A gentle reminder',
        body: r.title,
        scheduledDate: time,
        notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
                sound ? 'routine_sound_v1' : 'routine_silent_v1',
                'Routine reminders',
                channelDescription: 'Caregiver-created everyday reminders',
                playSound: sound,
                enableVibration: sound,
                visibility: NotificationVisibility.private)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
        payload: 'reminder:${r.id}',
      );
}
