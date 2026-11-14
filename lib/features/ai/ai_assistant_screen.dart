import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _textController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Kính chào Quý Doanh Nghiệp! Tôi là Trợ Lý Tư Vấn Quà Hoàng Gia Nguyệt Phố. Bạn cần tư vấn set quà trung thu theo ngân sách, đối tượng đối tác hay quy chuẩn đóng gói nào?',
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  static const List<String> promptPills = [
    'Ngân sách 500k - 800k/hộp',
    'Tặng đối tác Nhật Bản',
    'Bánh ăn kiêng ít ngọt',
    'In logo ép kim từ 50 hộp',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
    });
    _textController.clear();

    // AI automated response
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Với yêu cầu "$text", tôi đề xuất Set Hộp Sơn Mài Hoàng Triều (4 bánh yến sào & hạt sen cao cấp) với chiết khấu 20% cho đơn từ 50 hộp, miễn phí in logo kim loại và giao xe lạnh tận nơi!',
            isUser: false,
            time: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Trợ Lý Tư Vấn Quà AI', showBack: true),
      body: Column(
        children: [
          // Prompt suggestions
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: promptPills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final pill = promptPills[index];
                return InkWell(
                  onTap: () => _sendMessage(pill),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGoldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Text(
                        pill,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                      border: msg.isUser ? null : Border.all(color: AppColors.border),
                      boxShadow: AppTokens.shadowSubtle,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: msg.isUser ? AppColors.textWhite : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Hỏi AI về vị bánh, chiết khấu, mẫu hộp...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () => _sendMessage(_textController.text),
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
