import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/custom_packaging.dart';

class CustomPackagingReviewCard extends StatefulWidget {
  final CustomPackagingModel packaging;
  final Future<void> Function(String revisionId) onApprove;
  final Future<void> Function(String revisionId, String notes) onRequestRevision;

  const CustomPackagingReviewCard({
    super.key,
    required this.packaging,
    required this.onApprove,
    required this.onRequestRevision,
  });

  @override
  State<CustomPackagingReviewCard> createState() => _CustomPackagingReviewCardState();
}

class _CustomPackagingReviewCardState extends State<CustomPackagingReviewCard> {
  bool _isSubmitting = false;

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  void _showMockupPreview(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(AppTokens.spaceLG),
                  child: const Text('Không thể tải ảnh mockup'),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleApprove() async {
    final rev = widget.packaging.latestRevision;
    if (rev == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận duyệt thiết kế mockup'),
        content: Text(
          'Bạn có đồng ý phê duyệt mẫu thiết kế mockup #${rev.revisionNumber} cho đơn hàng? '
          'Sau khi duyệt, xưởng sẽ tiến hành in ấn và sản xuất hàng loạt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Xem lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Duyệt thiết kế'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onApprove(rev.id);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleRequestRevision() async {
    final rev = widget.packaging.latestRevision;
    if (rev == null) return;

    final notesController = TextEditingController();
    final isExhausted = widget.packaging.hasExhaustedFreeRevisions;
    final remaining = widget.packaging.remainingFreeRevisions;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu chỉnh sửa mockup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceSM),
                margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                decoration: BoxDecoration(
                  color: isExhausted ? const Color(0xFFFFFBE6) : const Color(0xFFE6F4FF),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  border: Border.all(
                    color: isExhausted ? const Color(0xFFFFE58F) : const Color(0xFF91CAFF),
                  ),
                ),
                child: Text(
                  isExhausted
                      ? 'Lưu ý: Bạn đã dùng hết 3 lần sửa miễn phí. Lần sửa này xưởng có thể áp dụng phụ phí phát sinh.'
                      : 'Bạn còn $remaining lần sửa miễn phí (tối đa 3 lần).',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isExhausted ? const Color(0xFFD48806) : const Color(0xFF0958D9),
                  ),
                ),
              ),
              const Text(
                'Nhập ghi chú chi tiết điểm cần sửa:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Điều chỉnh màu logo sang tông đỏ sẫm hơn, tăng kích thước chữ...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final text = notesController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập nội dung yêu cầu sửa.')),
                );
                return;
              }
              Navigator.of(ctx).pop(text);
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onRequestRevision(rev.id, result.trim());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.packaging;
    final latest = pkg.latestRevision;
    final isAwaiting = pkg.isAwaitingReview;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceLG),
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
              const Row(
                children: [
                  Icon(Icons.brush_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bao Bì & Mockup Thiết Kế',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Counter chip: "X/3 lần miễn phí"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pkg.hasExhaustedFreeRevisions
                      ? const Color(0xFFFFF2E8)
                      : const Color(0xFFE6F7FF),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: pkg.hasExhaustedFreeRevisions
                        ? const Color(0xFFFFBB96)
                        : const Color(0xFF91D5FF),
                  ),
                ),
                child: Text(
                  '${pkg.freeRevisionsUsed}/${pkg.freeRevisionsLimit} lần miễn phí',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: pkg.hasExhaustedFreeRevisions
                        ? const Color(0xFFD4380D)
                        : const Color(0xFF0050B3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),

          // Packaging brief summary
          if (pkg.companyName.isNotEmpty || pkg.packagingType.isNotEmpty) ...[
            Text(
              'Doanh nghiệp: ${pkg.companyName.isNotEmpty ? pkg.companyName : "Khách hàng"} · Loại hộp: ${pkg.packagingType}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
          ],

          // Mockup preview if available
          if (latest != null && latest.mockupUrl.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showMockupPreview(latest.mockupUrl),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    child: Image.network(
                      latest.mockupUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppColors.background,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, size: 40, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Bản #${latest.revisionNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            if (latest.supplierNotes != null && latest.supplierNotes!.isNotEmpty) ...[
              Text(
                'Ghi chú từ xưởng: ${latest.supplierNotes}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTokens.spaceSM),
            ],
          ],

          // Warning banner if free revisions exhausted
          if (pkg.hasExhaustedFreeRevisions) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBE6), // warning bg
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: const Color(0xFFFFE58F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFAAD14), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã dùng hết 3 lần sửa miễn phí. Các lần sửa tiếp theo xưởng có thể áp dụng phụ phí.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11.5,
                        color: Color(0xFFD48806),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Revision surcharge notice
          if (pkg.revisionSurcharge > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD, vertical: 8),
              margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F6),
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: const Color(0xFFFFADD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined, color: Color(0xFFEB2F96), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Phụ phí chỉnh sửa: ${_formatCurrency(pkg.revisionSurcharge)}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC41D7F),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons: Duyệt / Yêu cầu sửa
          if (isAwaiting && latest != null) ...[
            const SizedBox(height: AppTokens.spaceSM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(0, AppTokens.minTapTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleRequestRevision,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text(
                      'Yêu cầu sửa',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, AppTokens.minTapTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Duyệt thiết kế',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
