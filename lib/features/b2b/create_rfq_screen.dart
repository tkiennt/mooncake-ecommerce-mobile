import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/rfq_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class CreateRfqScreen extends ConsumerStatefulWidget {
  const CreateRfqScreen({super.key});

  @override
  ConsumerState<CreateRfqScreen> createState() => _CreateRfqScreenState();
}

class _CreateRfqScreenState extends ConsumerState<CreateRfqScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Đặt 500 hộp quà trung thu doanh nghiệp');
  final _qtyController = TextEditingController(text: '500');
  final _budgetController = TextEditingController(text: '200000000');
  final _addressController = TextEditingController(text: 'Tòa nhà FPT, Phố Duy Tân, Cầu Giấy, Hà Nội');
  final _notesController = TextEditingController(text: 'Yêu cầu in laser logo FPT lên nắp gỗ, giao hàng xe lạnh tận nơi.');

  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 30));
  DateTime _bidDeadline = DateTime.now().add(const Duration(days: 7));
  bool _customPackaging = true;
  bool _sampleBoxNeeded = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _qtyController.dispose();
    _budgetController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY CẦN GIAO HÀNG',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked != null) {
      setState(() {
        _expectedDeliveryDate = picked;
        if (_bidDeadline.isAfter(_expectedDeliveryDate)) {
          _bidDeadline = _expectedDeliveryDate.subtract(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectBidDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bidDeadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: _expectedDeliveryDate,
      helpText: 'HẠN CHÓT NHẬN BÁO GIÁ',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked != null) {
      setState(() {
        _bidDeadline = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề yêu cầu báo giá.')),
      );
      return;
    }

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số lượng phải lớn hơn 0 hộp.')),
      );
      return;
    }

    if (budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ngân sách dự kiến hợp lệ.')),
      );
      return;
    }

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ nhận hàng.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final unitTargetPrice = (budget / qty).roundToDouble();
      final packagingReq = [
        if (_customPackaging) 'Thiết kế bao bì riêng & in logo thương hiệu',
        if (_sampleBoxNeeded) 'Gửi hộp bánh mẫu dùng thử trước khi ký hợp đồng',
      ].join('; ');

      final payload = <String, dynamic>{
        'title': title,
        'description': notes.isNotEmpty ? notes : title,
        'deliveryAddress': address,
        'deliveryDateRequired': DateFormat('yyyy-MM-dd').format(_expectedDeliveryDate),
        'budgetRangeMin': (budget * 0.85).roundToDouble(),
        'budgetRangeMax': budget,
        'bidDeadline': _bidDeadline.toUtc().toIso8601String(),
        'items': [
          {
            'productName': title,
            'description': notes,
            'quantity': qty,
            'unit': 'hộp',
            'targetPrice': unitTargetPrice,
            'specifications': notes,
            'packagingRequirements': packagingReq.isNotEmpty ? packagingReq : 'Quy chuẩn đóng gói tiêu chuẩn',
            'needsCustomPackaging': _customPackaging,
          }
        ],
      };

      final repository = ref.read(rfqRepositoryProvider);
      final rfq = await repository.createRfq(payload);

      // Auto-publish RFQ to market
      try {
        await repository.publishRfq(rfq.id);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Đã gửi yêu cầu báo giá thành công!'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Không tạo được yêu cầu báo giá, bạn thử lại sau nhé.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Tạo yêu cầu báo giá',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border, width: 0.8),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin đặt bánh',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề yêu cầu báo giá *',
                        hintText: 'VD: Đặt 500 hộp bánh trung thu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Số lượng hộp *',
                              hintText: '500',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceMD),
                        Expanded(
                          child: TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Ngân sách (₫) *',
                              hintText: '200000000',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ nhận hàng tận nơi *',
                        hintText: 'Số nhà, đường, quận/huyện, tỉnh/thành phố',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDeliveryDate,
                            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Ngày cần giao *',
                                suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_expectedDeliveryDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceMD),
                        Expanded(
                          child: InkWell(
                            onTap: _selectBidDeadline,
                            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hạn nhận giá *',
                                suffixIcon: const Icon(Icons.access_time, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_bidDeadline),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Yêu cầu quy cách, hương vị & in ấn',
                        hintText: 'Chi tiết về vị bánh, bao bì, vận chuyển...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    CheckboxListTile(
                      value: _customPackaging,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cần thiết kế bao bì & in logo thương hiệu', style: TextStyle(fontFamily: 'Roboto', fontSize: 13)),
                      onChanged: (val) => setState(() => _customPackaging = val ?? false),
                    ),
                    CheckboxListTile(
                      value: _sampleBoxNeeded,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gửi hộp bánh mẫu dùng thử trước khi ký hợp đồng', style: TextStyle(fontFamily: 'Roboto', fontSize: 13)),
                      onChanged: (val) => setState(() => _sampleBoxNeeded = val ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space2XL),
              CustomButton(
                title: 'Gửi yêu cầu báo giá',
                size: ButtonSize.large,
                loading: _isSubmitting,
                disabled: _isSubmitting,
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
