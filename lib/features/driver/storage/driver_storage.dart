import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/driver_trip.dart';

class DriverStorage {
  static const _keyDriverModeActive = 'driver_mode_active';
  static const _keySavedTrips = 'driver_saved_trips';
  static const _keyLastName = 'driver_last_name';
  static const _keyLastPhone = 'driver_last_phone';
  static const _keyLastPlate = 'driver_last_plate';
  static const _keyOfflineProofs = 'driver_offline_proofs';

  static Future<bool> isDriverModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDriverModeActive) ?? false;
  }

  static Future<void> setDriverModeActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDriverModeActive, active);
  }

  static Future<List<DriverTrip>> getSavedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keySavedTrips) ?? [];
    final List<DriverTrip> trips = [];
    for (final item in rawList) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        trips.add(DriverTrip.fromJson(map));
      } catch (_) {}
    }
    return trips;
  }

  static Future<void> saveTrip(DriverTrip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSavedTrips();
    final index = current.indexWhere((t) =>
        (trip.token != null && t.token == trip.token) ||
        (trip.shareCode != null && t.shareCode == trip.shareCode) ||
        (t.deliveryId.isNotEmpty && t.deliveryId == trip.deliveryId));

    if (index >= 0) {
      current[index] = trip;
    } else {
      current.insert(0, trip);
    }

    final rawList = current.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_keySavedTrips, rawList);
    await setDriverModeActive(true);
  }

  static Future<void> removeTrip({
    String? token,
    String? shareCode,
    String? deliveryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSavedTrips();
    current.removeWhere((t) =>
        (token != null && t.token == token) ||
        (shareCode != null && t.shareCode == shareCode) ||
        (deliveryId != null && t.deliveryId == deliveryId));
    final rawList = current.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_keySavedTrips, rawList);
  }

  static Future<int> removeExpiredOrDeliveredTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSavedTrips();
    final beforeCount = current.length;
    current.removeWhere((t) => t.isExpired || t.isDelivered);
    final rawList = current.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_keySavedTrips, rawList);
    return beforeCount - current.length;
  }

  static Future<Map<String, String>> getLastDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'driverName': prefs.getString(_keyLastName) ?? '',
      'driverPhone': prefs.getString(_keyLastPhone) ?? '',
      'vehiclePlate': prefs.getString(_keyLastPlate) ?? '',
    };
  }

  static Future<void> saveLastDriverProfile({
    required String driverName,
    required String driverPhone,
    required String vehiclePlate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (driverName.trim().isNotEmpty) {
      await prefs.setString(_keyLastName, driverName.trim());
    }
    if (driverPhone.trim().isNotEmpty) {
      await prefs.setString(_keyLastPhone, driverPhone.trim());
    }
    if (vehiclePlate.trim().isNotEmpty) {
      await prefs.setString(_keyLastPlate, vehiclePlate.trim());
    }
  }

  static Future<void> saveOfflineProof(OfflineProofQueueItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyOfflineProofs) ?? [];
    list.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_keyOfflineProofs, list);
  }

  static Future<List<OfflineProofQueueItem>> getOfflineProofs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyOfflineProofs) ?? [];
    final List<OfflineProofQueueItem> list = [];
    for (final s in rawList) {
      try {
        list.add(OfflineProofQueueItem.fromJson(
            jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> removeOfflineProof(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getOfflineProofs();
    current.removeWhere((it) => it.id == id);
    await prefs.setStringList(
      _keyOfflineProofs,
      current.map((it) => jsonEncode(it.toJson())).toList(),
    );
  }
}
