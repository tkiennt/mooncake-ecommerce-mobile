import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_endpoints.dart';
import '../storage/storage_service.dart';

typedef SignalRNotificationCallback = void Function(Map<String, dynamic> payload);

class SignalRService {
  HubConnection? _connection;
  final StorageService _storage = StorageService();
  final List<SignalRNotificationCallback> _listeners = [];

  void addListener(SignalRNotificationCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(SignalRNotificationCallback callback) {
    _listeners.remove(callback);
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (var listener in _listeners) {
      try {
        listener(data);
      } catch (_) {}
    }
  }

  Future<void> startConnection() async {
    if (_connection?.state == HubConnectionState.Connected) return;

    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                return (await _storage.getAccessToken()) ?? '';
              },
            ),
          )
          .withAutomaticReconnect(reconnectIntervals: [0, 2000, 5000, 10000])
          .build();

      _connection?.on('ReceiveNotification', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final data = arguments.first as Map<String, dynamic>;
          _notifyListeners(data);
        }
      });

      _connection?.on('BidReceived', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final bid = arguments.first as Map<String, dynamic>;
          _notifyListeners({
            'type': 'NEW_BID',
            'title': 'Báo giá mới!',
            'message': 'Xưởng ${bid['supplierName'] ?? 'bánh'} vừa nộp báo giá cho yêu cầu ${bid['rfqNumber'] ?? ''}',
            'data': bid,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      });

      await _connection?.start();
    } catch (_) {
      // Offline / fallback silently
    }
  }

  Future<void> stopConnection() async {
    await _connection?.stop();
  }
}
