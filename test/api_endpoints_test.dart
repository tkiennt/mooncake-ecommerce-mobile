import 'package:flutter_test/flutter_test.dart';
import 'package:mooncake_mobile/core/constants/api_endpoints.dart';
import 'package:mooncake_mobile/core/constants/app_config.dart';
import 'package:mooncake_mobile/data/models/driver_trip.dart';

void main() {
  group('ApiEndpoints Staging & Production Tests', () {
    test('Default baseUrl uses port 8089 matching BE staging Docker compose', () {
      expect(ApiEndpoints.baseUrl, contains(':8089/api/v1'));
    });

    test('SignalR hubs evaluate correctly with api/v1 base URL', () {
      expect(ApiEndpoints.hubUrl, contains('/api/v1/hubs/notifications'));
      expect(ApiEndpoints.chatHubUrl, contains('/api/v1/hubs/chat'));
    });

    test('Staging feature flags default to false to protect un-implemented BE APIs', () {
      expect(AppConfig.enableDriverMode, isFalse);
      expect(AppConfig.enablePublicShopProfile, isFalse);
    });

    test('Staging PoD public endpoints format accurately', () {
      expect(ApiEndpoints.deliveryPublic('sample-token'), '/deliveries/public/sample-token');
      expect(
        ApiEndpoints.deliveryPublicUploadPhoto('sample-token'),
        '/deliveries/public/sample-token/proofs/upload-photo',
      );
      expect(
        ApiEndpoints.deliveryPublicProofs('sample-token'),
        '/deliveries/public/sample-token/proofs',
      );
    });

    test('DriverTrip parses Staging PublicDriverDeliveryResponse without crashing', () {
      final stagingJson = {
        'deliveryId': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'deliveryNumber': 'DEL-20261116-0001',
        'status': 'InTransit',
        'token': 'tok-xyz-123',
        'fromAddress': 'Xưởng Bánh Kinh Đô, Q1, TP.HCM',
        'toAddress': '123 Nguyễn Huệ, Q1, TP.HCM',
        'recipientName': 'Nguyễn Văn A',
        'recipientPhone': '0901234567',
        'canSubmitProof': true,
        'requiresSignature': false,
        'proofCount': 0,
      };

      final trip = DriverTrip.fromJson(stagingJson);
      expect(trip.deliveryId, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(trip.deliveryNumber, 'DEL-20261116-0001');
      expect(trip.token, 'tok-xyz-123');
      expect(trip.canSubmitProof, isTrue);
    });
  });
}
