import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/driver_trip.dart';
import '../../../data/repositories/driver_trip_repository.dart';
import '../../../shared_widgets/common/custom_button.dart';
import '../providers/driver_trip_provider.dart';
import '../storage/driver_storage.dart';

class DriverClaimScreen extends ConsumerStatefulWidget {
  final DriverTrip? trip;

  const DriverClaimScreen({super.key, this.trip});

  @override
  ConsumerState<DriverClaimScreen> createState() => _DriverClaimScreenState();
}

class _DriverClaimScreenState extends ConsumerState<DriverClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  DriverTrip? _activeTrip;

  @override
  void initState() {
    super.initState();
    _activeTrip = widget.trip ?? ref.read(currentTripProvider);
    _initPrefill();
  }

  Future<void> _initPrefill() async {
    final lastProfile = await DriverStorage.getLastDriverProfile();
    final trip = _activeTrip;

    setState(() {
      // Ưu tiên thông tin xưởng đã gán trước, sau đó tới thông tin đã lưu trên máy
      _nameController.text = (trip?.driverName != null && trip!.driverName!.isNotEmpty)
          ? trip.driverName!
          : (lastProfile['driverName'] ?? '');

      _phoneController.text = (trip?.driverPhone != null && trip!.driverPhone!.isNotEmpty)
          ? trip.driverPhone!
          : (lastProfile['driverPhone'] ?? '');

      _plateController.text = (trip?.vehiclePlate != null && trip!.vehiclePlate!.isNotEmpty)
          ? trip.vehiclePlate!
          : (lastProfile['vehiclePlate'] ?? '');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _handleClaim() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _activeTrip?.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage =
            'Không tìm thấy token của chuyến giao. Vui lòng thử quét lại mã QR hoặc nhập mã chuyến.';
      });
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final plate = _plateController.text.trim().toUpperCase();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(driverTripRepositoryProvider);
      final updatedTrip = await repo.claimTrip(
        token,
        ClaimTripPayload(
          driverName: name,
          driverPhone: phone,
          vehiclePlate: plate,
        ),
      );

      // Lưu thông tin tài xế cho các lần sau
      await DriverStorage.saveLastDriverProfile(
        driverName: name,
        driverPhone: phone,
        vehiclePlate: plate,
      );

      // Cập nhật trip vào storage
      await ref.read(savedTripsProvider.notifier).saveTrip(updatedTrip);
      ref.read(currentTripProvider.notifier).state = updatedTrip;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhận chuyến thành công! Bạn có thể bắt đầu giao hàng.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Chuyển sang màn Chi tiết chuyến
      context.pushReplacement('/driver/detail', extra: updatedTrip);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _activeTrip ?? ref.watch(currentTripProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Nhận chuyến giao hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceLG,
            vertical: AppTokens.spaceLG,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Delivery Overview Card
                if (trip != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spaceSM,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(
                                    AppTokens.radiusDefault),
                              ),
                              child: Text(
                                trip.shareCode ?? trip.deliveryNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSM),
                            Text(
                              trip.batchDisplay,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        Text(
                          'Địa chỉ giao: ${trip.toAddress ?? "Chưa rõ"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Người nhận: ${trip.recipientName ?? "Khách hàng"} - ${trip.recipientPhone ?? ""}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceLG),
                ],

                // Notification prompt
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warning, size: 20),
                      SizedBox(width: AppTokens.spaceSM),
                      Expanded(
                        child: Text(
                          'Vui lòng điền thông tin tài xế để nhận chuyến. Thông tin này sẽ được lưu để tự động điền các lần sau.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceLG),
                ],

                // Driver Name input
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên tài xế *',
                    hintText: 'VD: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textMuted),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên tài xế.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.spaceMD),

                // Driver Phone input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại tài xế *',
                    hintText: 'VD: 0912345678',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: AppColors.textMuted),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại tài xế.';
                    }
                    if (value.trim().length < 9) {
                      return 'Số điện thoại không hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.spaceMD),

                // Vehicle Plate input
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleClaim(),
                  decoration: const InputDecoration(
                    labelText: 'Biển số xe vận chuyển *',
                    hintText: 'VD: 29A-12345',
                    prefixIcon: Icon(Icons.directions_car_outlined,
                        color: AppColors.textMuted),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập biển số xe.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.space2XL),

                // Submit Claim Button
                CustomButton(
                  title: 'Xác nhận nhận chuyến',
                  size: ButtonSize.large,
                  loading: _isLoading,
                  onPress: _handleClaim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
