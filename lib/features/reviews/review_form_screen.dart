import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/review_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class ReviewFormScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String orderNumber;
  final String shopName;

  const ReviewFormScreen({
    super.key,
    this.orderId,
    this.orderNumber = 'Đơn mẫu',
    this.shopName = 'Xưởng bánh',
  });

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final Map<String, int> _scores = {
    'taste': 5,
    'packaging': 5,
    'delivery': 5,
    'contract': 5,
  };

  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  static const List<Map<String, String>> _criteria = [
    {'key': 'taste', 'label': 'Chất lượng bánh & Vị'},
    {'key': 'packaging', 'label': 'Quy cách hộp & Logo'},
    {'key': 'delivery', 'label': 'Đúng hẹn & Xe lạnh'},
    {'key': 'contract', 'label': 'Hóa đơn VAT & Hợp đồng'},
  ];

  static const List<String> _scoreLabels = [
    '',
    'Cần cải thiện (1/5)',
    'Đạt yêu cầu (2/5)',
    'Khá tốt (3/5)',
    'Rất hài lòng (4/5)',
    'Xuất sắc tuyệt đối (5/5)',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double get _overallScore {
    final values = _scores.values;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  Future<void> _handleSubmit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chia sẻ cảm nhận thực tế của bạn về đợt nhận bánh này.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (widget.orderId == null || widget.orderId!.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chế độ xem trước'),
          content: const Text('Đây là đơn hàng mẫu nên đánh giá không được lưu vào hệ thống.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taste = _scores['taste'] ?? 5;
      final packaging = _scores['packaging'] ?? 5;
      final delivery = _scores['delivery'] ?? 5;
      final contract = _scores['contract'] ?? 5;

      final overall = ((taste + packaging + delivery + contract) / 4).round();
      final serviceRating = ((packaging + contract) / 2).round();

      await ref.read(reviewRepositoryProvider).submitTransactionReview({
        'orderId': widget.orderId,
        'qualityRating': taste,
        'deliveryRating': delivery,
        'serviceRating': serviceRating,
        'overallRating': overall,
        'comment': comment,
        'isAnonymous': false,
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Đã gửi đánh giá'),
            ],
          ),
          content: const Text(
            'Cảm ơn bạn đã phản hồi. Đánh giá nghiệm thu này sẽ được tính vào điểm uy tín công khai của xưởng sản xuất.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không gửi được đánh giá: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Đánh giá đơn hàng',
        subtitle: widget.orderNumber,
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Info Card
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentGoldBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: const Icon(Icons.storefront, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shopName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Đơn hàng đã giao và ký nhận PoD thành công',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // 4 B2B Criteria Card (Lazada Review Benchmark layout: tiêu chí trên, 5 sao to ≥30px căn giữa)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đánh giá 4 tiêu chí chất lượng',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Theo chuẩn nghiệm thu thu mua B2B',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBg,
                          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${_overallScore.toStringAsFixed(1)} / 5.0',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),

                  ..._criteria.map((item) {
                    final key = item['key']!;
                    final label = item['label']!;
                    final score = _scores[key] ?? 5;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHover,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _scoreLabels[score],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (starIdx) {
                                final starVal = starIdx + 1;
                                final isFilled = starVal <= score;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _scores[key] = starVal;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: SizedBox(
                                    width: 48,
                                    height: AppTokens.minTapTarget,
                                    child: Center(
                                      child: Icon(
                                        isFilled ? Icons.star : Icons.star_border,
                                        color: isFilled ? AppColors.accent : AppColors.border,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const Divider(height: 16, color: AppColors.border),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // Detailed Comment Card
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhận xét chi tiết đợt giao nhận',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Chia sẻ trải nghiệm về chất lượng bánh, quy cách hộp quà, tiến độ giao nhận PoD...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),

            // Submit Button
            CustomButton(
              title: _isLoading ? 'Đang gửi đánh giá...' : 'Gửi Đánh Giá Nghiệm Thu',
              loading: _isLoading,
              disabled: _isLoading,
              size: ButtonSize.large,
              icon: const Icon(Icons.star, color: Colors.white, size: 18),
              onPress: _handleSubmit,
            ),
            const SizedBox(height: AppTokens.space3XL),
          ],
        ),
      ),
    );
  }
}
