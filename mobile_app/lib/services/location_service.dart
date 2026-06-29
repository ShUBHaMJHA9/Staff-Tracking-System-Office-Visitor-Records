import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'iod_foreground', 
    'IOD Duty Service', 
    description: 'Required for active GPS tracking while on duty.', 
    importance: Importance.high, 
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'iod_foreground',
      initialNotificationTitle: 'IOD Duty Active',
      initialNotificationContent: 'GPS Tracking Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Fetch location every 30 seconds and send to backend
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      // Check permission before requesting location
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Update notification to show tracking paused
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            flutterLocalNotificationsPlugin.show(
              id: 888,
              title: 'IOD Duty Active',
              body: 'Location permission not granted. Please enable in Settings.',
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'iod_foreground',
                  'IOD Duty Service',
                  icon: 'ic_notification',
                  ongoing: true,
                  importance: Importance.high,
                ),
              ),
            );
          }
        }
        return; // Skip this tick gracefully
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            id: 888,
            title: 'IOD Duty Active',
            body: 'Tracking Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'iod_foreground',
                'IOD Duty Service',
                icon: 'ic_notification',
                ongoing: true,
                importance: Importance.high,
              ),
            ),
          );
        }
      }

      await ApiService().updateLocation(position.latitude, position.longitude);
      
    } catch (e) {
      // Silently log - do not crash the service
      debugPrint('Background Location Error: $e');
    }
  });
}
