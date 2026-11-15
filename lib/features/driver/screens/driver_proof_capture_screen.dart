import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/driver_trip.dart';
import '../../../data/repositories/driver_trip_repository.dart';
import '../../../shared_widgets/common/custom_button.dart';
import '../providers/driver_trip_provider.dart';
import '../storage/driver_storage.dart';

class DriverProofCaptureScreen extends ConsumerStatefulWidget {
  final DriverTrip? trip;

  const DriverProofCaptureScreen({super.key, this.trip});

  @override
  ConsumerState<DriverProofCaptureScreen> createState() =>
      _DriverProofCaptureScreenState();
}

class _DriverProofCaptureScreenState
    extends ConsumerState<DriverProofCaptureScreen> {
  final _picker = ImagePicker();
  final _notesController = TextEditingController();
  final _recipientNameController = TextEditingController();

  late final SignatureController _sigController;

  final List<File> _photos = [];
  bool _isItemCountConfirmed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  double? _gpsLat;
  double? _gpsLng;
  bool _isGpsLoading = false;

  DriverTrip? _activeTrip;

  @override
  void initState() {
    super.initState();
    _activeTrip = widget.trip ?? ref.read(currentTripProvider);
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.textPrimary,
      exportBackgroundColor: Colors.white,
    );
    if (_activeTrip?.recipientName != null) {
      _recipientNameController.text = _activeTrip!.recipientName!;
    }
    _autoFetchGps();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _recipientNameController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _autoFetchGps() async {
    setState(() => _isGpsLoading = true);
    try {
      final hasService = await Geolocator.isLocationServiceEnabled();
      if (!hasService) {
        setState(() => _isGpsLoading = false);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          setState(() => _isGpsLoading = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 6),
      );
      if (mounted) {
        setState(() {
          _gpsLat = pos.latitude;
          _gpsLng = pos.longitude;
          _isGpsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGpsLoading = false);
      }
    }
  }

  Future<void> _takePhoto(ImageSource source) async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 5 ảnh bàn giao.')),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _photos.add(File(picked.path));
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chụp ảnh: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    final trip = _activeTrip ?? ref.read(currentTripProvider);
    if (trip == null || trip.token == null) {
      setState(() => _errorMessage = 'Không tìm thấy token của chuyến.');
      return;
    }

    if (!trip.isClaimed) {
      setState(() => _errorMessage =
          'Chưa nhận chuyến. Vui lòng nhận chuyến trước khi nộp nghiệm thu.');
      return;
    }

    if (_photos.isEmpty) {
      setState(() =>
          _errorMessage = 'Vui lòng chụp ít nhất 1 ảnh kiện hàng bàn giao.');
      return;
    }

    if (trip.requiresSignature && _sigController.isEmpty) {
      setState(() => _errorMessage =
          'Chuyến giao này yêu cầu chữ ký cảm ứng của người nhận hàng.');
      return;
    }

    final recipientName = _recipientNameController.text.trim();
    if (recipientName.isEmpty) {
      setState(() =>
          _errorMessage = 'Vui lòng nhập họ tên người ký nhận bàn giao.');
      return;
    }

    if (!_isItemCountConfirmed) {
      setState(() => _errorMessage =
          'Vui lòng tích chọn xác nhận "Đã giao đủ như danh sách".');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    String? signatureBase64;
    if (_sigController.isNotEmpty) {
      try {
        final bytes = await _sigController.toPngBytes();
        if (bytes != null) {
          signatureBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }

    final repo = ref.read(driverTripRepositoryProvider);
    final uploadedUrls = <String>[];
    bool isOfflineMode = false;

    // Tải ảnh lên API
    for (final photo in _photos) {
      try {
        final url = await repo.uploadProofPhoto(trip.token!, photo);
        uploadedUrls.add(url);
      } catch (_) {
        // Lỗi mạng khi upload ảnh
        isOfflineMode = true;
        break;
      }
    }

    final payload = SubmitProofPayload(
      proofType: 'Delivery',
      photoUrl: uploadedUrls.isNotEmpty ? uploadedUrls.first : '',
      photoUrls: uploadedUrls,
      signatureBase64: signatureBase64,
      takenBy: recipientName,
      locationLat: _gpsLat ?? 21.0168,
      locationLng: _gpsLng ?? 105.7838,
      notes: _notesController.text.trim(),
    );

    if (isOfflineMode || uploadedUrls.isEmpty) {
      // Giữ ảnh và payload lưu vào hàng đợi offline
      final offlineItem = OfflineProofQueueItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        token: trip.token!,
        payload: payload.toJson(),
        localPhotoPaths: _photos.map((p) => p.path).toList(),
        createdAt: DateTime.now(),
      );
      await DriverStorage.saveOfflineProof(offlineItem);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showCompletionDialog(
          title: 'Đã lưu tạm ngoại tuyến',
          message:
              'Mất kết nối mạng khi tải ảnh. Bằng chứng nghiệm thu đã được lưu an toàn trên máy và sẽ được gửi lại khi có mạng.',
          isOffline: true,
        );
      }
      return;
    }

    try {
      await repo.submitPublicProof(trip.token!, payload);

      // Cập nhật trạng thái chuyến đã hoàn tất
      final updatedTrip = trip.copyWith(
        status: 'Delivered',
        canSubmitProof: false,
        proofCount: (trip.proofCount + uploadedUrls.length),
      );
      await ref.read(savedTripsProvider.notifier).saveTrip(updatedTrip);
      ref.read(currentTripProvider.notifier).state = updatedTrip;

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showCompletionDialog(
          title: 'Nộp biên bản thành công!',
          message:
              'Biên bản bàn giao PoD đã được ghi nhận trên hệ thống. Cảm ơn bạn đã hoàn thành chuyến giao.',
          isOffline: false,
        );
      }
    } catch (e) {
      // Giữ ảnh để gửi lại nếu có lỗi
      final offlineItem = OfflineProofQueueItem(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        token: trip.token!,
        payload: payload.toJson(),
        localPhotoPaths: _photos.map((p) => p.path).toList(),
        createdAt: DateTime.now(),
      );
      await DriverStorage.saveOfflineProof(offlineItem);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showCompletionDialog(
          title: 'Đã lưu biên bản ngoại tuyến',
          message:
              'Không thể gửi trực tiếp (${e.toString()}). Bằng chứng đã được lưu trên máy để gửi lại.',
          isOffline: true,
        );
      }
    }
  }

  void _showCompletionDialog({
    required String title,
    required String message,
    required bool isOffline,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        title: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off : Icons.check_circle,
              color: isOffline ? AppColors.warning : AppColors.success,
              size: 28,
            ),
            const SizedBox(width: AppTokens.spaceSM),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/driver/trips');
            },
            child: const Text('Về danh sách chuyến'),
          ),
        ],
      ),
    );
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
          'Chụp nghiệm thu PoD',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trip header summary
              if (trip != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceSM,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusDefault),
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
                      const Spacer(),
                      if (trip.requiresSignature)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spaceSM,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBg,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusDefault),
                          ),
                          child: const Text(
                            'Bắt buộc chữ ký',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: AppTokens.spaceSM),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // Photos Section (Max 5 photos)
              _FormSectionHeader(
                title: '1. Ảnh bàn giao kiện hàng (${_photos.length}/5) *',
                subtitle:
                    'Chụp kiện hàng còn nguyên vẹn, tem niêm phong và bối cảnh điểm nhận.',
              ),
              const SizedBox(height: AppTokens.spaceSM),

              // Photos preview grid
              if (_photos.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppTokens.spaceSM),
                    itemBuilder: (_, index) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusDefault),
                            child: Image.file(
                              _photos[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSM),
              ],

              // Camera buttons
              if (_photos.length < 5) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _takePhoto(ImageSource.camera),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusDefault),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt,
                            color: AppColors.primary),
                        label: const Text(
                          'Chụp ảnh',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceMD),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _takePhoto(ImageSource.gallery),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppColors.borderDark),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusDefault),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_outlined,
                            color: AppColors.textSecondary),
                        label: const Text(
                          'Chọn từ máy',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTokens.space2XL),

              // Signature Section
              _FormSectionHeader(
                title: trip?.requiresSignature == true
                    ? '2. Chữ ký người nhận hàng (Bắt buộc) *'
                    : '2. Chữ ký người nhận hàng (Khuyến nghị)',
                subtitle: 'Ký trực tiếp bằng ngón tay vào ô trắng dưới đây.',
              ),
              const SizedBox(height: AppTokens.spaceSM),

              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  child: Signature(
                    controller: _sigController,
                    height: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _sigController.clear(),
                  icon: const Icon(Icons.refresh,
                      size: 16, color: AppColors.textMuted),
                  label: const Text(
                    'Ký lại',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),

              // Recipient Name Field
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên người ký nhận *',
                  hintText: 'Nhập họ và tên người nhận hàng',
                  prefixIcon:
                      Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // Delivery Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú bàn giao',
                  hintText: 'VD: Đã đồng kiểm niêm phong, gửi bảo vệ tòa nhà...',
                  prefixIcon:
                      Icon(Icons.edit_note, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // GPS Status Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMD,
                  vertical: AppTokens.spaceSM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _gpsLat != null
                          ? Icons.location_on
                          : Icons.location_off_outlined,
                      color:
                          _gpsLat != null ? AppColors.success : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: AppTokens.spaceSM),
                    Expanded(
                      child: Text(
                        _isGpsLoading
                          ? 'Đang lấy tọa độ GPS điểm giao...'
                          : _gpsLat != null
                              ? 'Tọa độ GPS: ${_gpsLat!.toStringAsFixed(4)}, ${_gpsLng!.toStringAsFixed(4)}'
                              : 'Chưa có tọa độ (có thể bỏ qua nếu từ chối quyền)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _gpsLat != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (!_isGpsLoading && _gpsLat == null)
                      TextButton(
                        onPressed: _autoFetchGps,
                        child: const Text('Thử lại',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // Checkbox Confirmation (Mandatory)
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceSM),
                decoration: BoxDecoration(
                  color: _isItemCountConfirmed
                      ? AppColors.primaryTint
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                  border: Border.all(
                    color: _isItemCountConfirmed
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: CheckboxListTile(
                  value: _isItemCountConfirmed,
                  onChanged: (val) {
                    setState(() {
                      _isItemCountConfirmed = val ?? false;
                      if (_isItemCountConfirmed) {
                        _errorMessage = null;
                      }
                    });
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Đã giao đủ như danh sách hàng cần giao *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Tôi xác nhận số lượng kiện hàng thực tế khớp với chứng từ giao nhận.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space2XL),

              // Submit Button
              CustomButton(
                title: 'Nộp biên bản nghiệm thu PoD',
                size: ButtonSize.large,
                loading: _isSubmitting,
                onPress: _handleSubmit,
              ),
              const SizedBox(height: AppTokens.space2XL),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
