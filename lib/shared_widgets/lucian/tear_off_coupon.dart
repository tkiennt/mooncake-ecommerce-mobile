import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class TearOffCoupon extends StatefulWidget {
  final String code;
  final String discountText;
  final String conditionText;
  final int initialSeconds;
  final ValueChanged<String>? onApply;

  const TearOffCoupon({
    super.key,
    this.code = 'B2BMOON2026',
    this.discountText = 'GIẢM 500.000₫',
    this.conditionText = 'Đơn doanh nghiệp từ 30 hộp',
    this.initialSeconds = 5 * 3600 + 42 * 60 + 15,
    this.onApply,
  });

  @override
  State<TearOffCoupon> createState() => _TearOffCouponState();
}

class _TearOffCouponState extends State<TearOffCoupon> {
  late int _secondsLeft;
  bool _isTorn = false;
  bool _copied = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final s = totalSecs % 60;
    final pad = (int n) => n < 10 ? '0$n' : '$n';
    return '${pad(h)}:${pad(m)}:${pad(s)}';
  }

  void _handleTearOff() {
    setState(() {
      _isTorn = true;
    });
    widget.onApply?.call(widget.code);
  }

  void _handleCopyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _copied = true;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.accentGoldBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                const Text(
                  'Ưu đãi mùa vụ kết thúc sau: ',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  _formatTime(_secondsLeft),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          // Ticket Card Body
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: AppTokens.shadowCard,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left side: Offer Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Đặc quyền doanh nghiệp',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.discountText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.conditionText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isTorn)
                            Row(
                              children: [
                                Text(
                                  widget.code,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _handleCopyCode,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _copied ? AppColors.success : AppColors.primaryTint,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _copied ? Icons.check : Icons.copy_outlined,
                                          size: 11,
                                          color: _copied ? AppColors.textWhite : AppColors.primary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _copied ? 'Đã chép' : 'Sao chép',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _copied ? AppColors.textWhite : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Bấm bên phải để xé phiếu & nhận mã',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Perforation separator
                  CustomPaint(
                    size: const Size(1, double.infinity),
                    painter: _DashedLinePainter(),
                  ),

                  // Right side: Tear Stub
                  Container(
                    width: 95,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isTorn ? AppColors.accentGoldBg : AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: InkWell(
                      onTap: _isTorn ? null : _handleTearOff,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isTorn) ...[
                            const Icon(Icons.card_giftcard, size: 24, color: AppColors.accent),
                            const SizedBox(height: 4),
                            const Text(
                              'Đã nhận',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                            const Text(
                              'Sẵn sàng dùng',
                              style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Icon(Icons.content_cut, size: 20, color: AppColors.textWhite),
                            const SizedBox(height: 4),
                            const Text(
                              'Xé phiếu',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const Text(
                              'Nhận ngay',
                              style: TextStyle(fontSize: 10, color: AppColors.accentGoldLight),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
