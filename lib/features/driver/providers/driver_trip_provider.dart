import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/driver_trip.dart';
import '../../../data/repositories/driver_trip_repository.dart';
import '../storage/driver_storage.dart';

class SavedTripsNotifier extends StateNotifier<AsyncValue<List<DriverTrip>>> {
  final DriverTripRepository _repository;

  SavedTripsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSavedTrips();
  }

  Future<void> loadSavedTrips() async {
    state = const AsyncValue.loading();
    try {
      final trips = await DriverStorage.getSavedTrips();
      state = AsyncValue.data(trips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Làm mới tất cả chuyến từ API
  Future<void> refreshAll() async {
    final currentList = state.value ?? await DriverStorage.getSavedTrips();
    final List<DriverTrip> updated = [];

    for (final trip in currentList) {
      try {
        DriverTrip refreshed;
        if (trip.token != null && trip.token!.isNotEmpty) {
          refreshed = await _repository.getTripByToken(trip.token!);
        } else if (trip.shareCode != null && trip.shareCode!.isNotEmpty) {
          refreshed = await _repository.getTripByCode(trip.shareCode!);
        } else {
          refreshed = trip;
        }
        await DriverStorage.saveTrip(refreshed);
        updated.add(refreshed);
      } catch (_) {
        // Giữ lại chuyến cũ nếu mất mạng hoặc lỗi tạm thời
        updated.add(trip);
      }
    }

    state = AsyncValue.data(updated);
  }

  Future<void> removeTrip({
    String? token,
    String? shareCode,
    String? deliveryId,
  }) async {
    await DriverStorage.removeTrip(
      token: token,
      shareCode: shareCode,
      deliveryId: deliveryId,
    );
    await loadSavedTrips();
  }

  Future<int> removeExpiredOrDelivered() async {
    final count = await DriverStorage.removeExpiredOrDeliveredTrips();
    await loadSavedTrips();
    return count;
  }

  Future<void> saveTrip(DriverTrip trip) async {
    await DriverStorage.saveTrip(trip);
    await loadSavedTrips();
  }
}

final savedTripsProvider =
    StateNotifierProvider<SavedTripsNotifier, AsyncValue<List<DriverTrip>>>(
        (ref) {
  final repo = ref.watch(driverTripRepositoryProvider);
  return SavedTripsNotifier(repo);
});

final currentTripProvider = StateProvider<DriverTrip?>((ref) => null);
