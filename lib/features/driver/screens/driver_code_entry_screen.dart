import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/driver_trip.dart';
import '../../../data/repositories/driver_trip_repository.dart';
import '../../../shared_widgets/common/custom_button.dart';
import '../providers/driver_trip_provider.dart';
import '../storage/driver_storage.dart';
import 'driver_qr_scanner_screen.dart';

class ShareCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned =
        newValue.text.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (cleaned.length > 8) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i == 4) buffer.write('-');
      buffer.write(cleaned[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DriverCodeEntryScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  final String? initialToken;

  const DriverCodeEntryScreen({
    super.key,
    this.initialCode,
    this.initialToken,
  });

  @override
  ConsumerState<DriverCodeEntryScreen> createState() =>
      _DriverCodeEntryScreenState();
}

class _DriverCodeEntryScreenState extends ConsumerState<DriverCodeEntryScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null || widget.initialToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
          _lookupTrip(token: widget.initialToken);
        } else if (widget.initialCode != null &&
            widget.initialCode!.isNotEmpty) {
          _formatAndDisplayCode(widget.initialCode!);
          _lookupTrip(shareCode: widget.initialCode);
        }
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Phân tích chuỗi nhập vào: link web có ?token=, ?code= hoặc mã trần/token trần
  void _processInputAndSearch(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    String? token;
    String? code;

    final uri = Uri.tryParse(text);
    if (uri != null &&
        (uri.hasScheme ||
            text.contains('giao-hang-tai-xe') ||
            uri.queryParameters.isNotEmpty)) {
      token = uri.queryParameters['token'];
      code = uri.queryParameters['code'] ?? uri.queryParameters['shareCode'];
    }

    if (token == null && text.contains('token=')) {
      final m = RegExp(r'token=([^&\s]+)').firstMatch(text);
      if (m != null) token = m.group(1);
    }
    if (code == null && text.contains('code=')) {
      final m = RegExp(r'code=([^&\s]+)').firstMatch(text);
      if (m != null) code = m.group(1);
    }

    if (token != null && token.isNotEmpty) {
      _lookupTrip(token: token);
      return;
    }

    if (code != null && code.isNotEmpty) {
      final clean = code.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
      _formatAndDisplayCode(clean);
      _lookupTrip(shareCode: clean);
      return;
    }

    // Nếu là chuỗi trần
    final cleaned = text.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (cleaned.length == 8) {
      _formatAndDisplayCode(cleaned);
      _lookupTrip(shareCode: cleaned);
    } else if (text.length > 8) {
      // Token trần
      _lookupTrip(token: text);
    } else {
      _formatAndDisplayCode(cleaned);
      _lookupTrip(shareCode: cleaned);
    }
  }

  void _formatAndDisplayCode(String clean) {
    if (clean.length <= 4) {
      _codeController.text = clean;
    } else {
      final first = clean.substring(0, 4);
      final second = clean.substring(4, clean.length.clamp(4, 8));
      _codeController.text = '$first-$second';
    }
  }

  Future<void> _handlePasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khay nhớ tạm trống.')),
        );
      }
      return;
    }
    _processInputAndSearch(text);
  }

  Future<void> _handleScanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DriverQrScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      _processInputAndSearch(result);
    }
  }

  Future<void> _lookupTrip({String? shareCode, String? token}) async {
    final codeToQuery = shareCode ??
        _codeController.text.replaceAll('-', '').replaceAll(' ', '').trim();

    if ((token == null || token.isEmpty) && (codeToQuery.isEmpty)) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã chuyến hoặc dán liên kết.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(driverTripRepositoryProvider);
      DriverTrip trip;
      if (token != null && token.isNotEmpty) {
        trip = await repo.getTripByToken(token);
      } else {
        trip = await repo.getTripByCode(codeToQuery);
      }

      // Lưu chuyến vào storage cục bộ
      await ref.read(savedTripsProvider.notifier).saveTrip(trip);
      ref.read(currentTripProvider.notifier).state = trip;

      if (!mounted) return;

      if (!trip.isClaimed) {
        // Chưa nhận chuyến -> màn Nhận chuyến
        context.push('/driver/claim', extra: trip);
      } else {
        // Đã nhận chuyến -> màn Chi tiết chuyến
        context.push('/driver/detail', extra: trip);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Không tìm thấy chuyến hoặc mã đã hết hạn. Vui lòng liên hệ xưởng để lấy mã mới.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exitDriverMode() async {
    await DriverStorage.setDriverModeActive(false);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedTripsAsync = ref.watch(savedTripsProvider);
    final savedCount = savedTripsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              _exitDriverMode();
            }
          },
        ),
        title: const Text(
          'Tôi là tài xế',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _exitDriverMode,
            icon: const Icon(Icons.logout, size: 18, color: AppColors.primary),
            label: const Text(
              'Thoát',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space2XL,
            vertical: AppTokens.spaceXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner / Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              const Text(
                'Nhập mã chuyến giao hàng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTokens.spaceXS),
              const Text(
                'Nhập mã 8 ký tự hoặc quét mã QR do xưởng cung cấp để nhận chuyến và nộp biên bản PoD.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTokens.space2XL),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

              // 8-character Code Input Field
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                inputFormatters: [
                  ShareCodeInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Mã chuyến giao hàng',
                  hintText: 'VD: ABCD-1234',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    letterSpacing: 2.0,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(Icons.pin_outlined,
                      color: AppColors.primary),
                  suffixIcon: _codeController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () {
                            _codeController.clear();
                            setState(() => _errorMessage = null);
                          },
                        )
                      : null,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                onSubmitted: (val) => _processInputAndSearch(val),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // Fast action buttons: Scan QR & Paste Link
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleScanQr,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.accent, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusDefault),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner,
                          color: AppColors.accent),
                      label: const Text(
                        'Quét mã QR',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handlePasteLink,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusDefault),
                        ),
                      ),
                      icon: const Icon(Icons.content_paste,
                          color: AppColors.primary),
                      label: const Text(
                        'Dán link web',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceXL),

              // Lookup Button (large one-handed button)
              CustomButton(
                title: 'Tra cứu chuyến',
                size: ButtonSize.large,
                loading: _isLoading,
                onPress: () => _lookupTrip(),
              ),
              const SizedBox(height: AppTokens.space2XL),

              // Saved Trips Access
              if (savedCount > 0) ...[
                const Divider(),
                const SizedBox(height: AppTokens.spaceMD),
                OutlinedButton.icon(
                  onPressed: () => context.push('/driver/trips'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                  ),
                  icon: const Icon(Icons.list_alt, color: AppColors.textPrimary),
                  label: Text(
                    'Xem chuyến của tôi ($savedCount chuyến đã mở)',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
