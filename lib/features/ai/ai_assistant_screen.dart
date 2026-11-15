import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../data/repositories/ai_repository.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _sessionToken;
  bool _isInitializing = true;
  String? _initError;
  bool _isSending = false;

  final List<ChatMessage> _messages = [];

  static const List<String> promptPills = [
    'Ngân sách 500k - 800k/hộp',
    'Tặng đối tác Nhật Bản',
    'Bánh ăn kiêng ít ngọt',
    'In logo ép kim từ 50 hộp',
    'Chính sách chiết khấu B2B',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final session = await aiRepo.startSession(context: 'B2B Mooncake Consultant Mobile');

      if (!mounted) return;
      setState(() {
        _sessionToken = session.sessionToken;
        _isInitializing = false;
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text: 'Kính chào Quý Doanh Nghiệp! Tôi là Trợ Lý Tư Vấn Quà Hoàng Gia Nguyệt Phố. Bạn cần tư vấn set quà trung thu theo ngân sách, đối tượng đối tác hay quy chuẩn đóng gói nào?',
              isUser: false,
              time: DateTime.now(),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = e.toString().replaceFirst('Exception: ', '');
        // Keep initial welcome message ready for fallback
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text: 'Kính chào Quý Doanh Nghiệp! Tôi là Trợ Lý Tư Vấn Quà Hoàng Gia Nguyệt Phố. Hệ thống AI đang ở chế độ dự phòng.',
              isUser: false,
              time: DateTime.now(),
            ),
          );
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true, time: DateTime.now()));
      _isSending = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final aiRepo = ref.read(aiRepositoryProvider);

      // Re-init session if token missing
      if (_sessionToken == null || _sessionToken!.isEmpty) {
        final session = await aiRepo.startSession(context: 'B2B Mooncake Consultant Mobile');
        _sessionToken = session.sessionToken;
      }

      final response = await aiRepo.sendMessage(
        sessionToken: _sessionToken!,
        message: query,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: response.content,
          isUser: false,
          time: response.createdAt,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Xin lỗi Quý khách, không thể kết nối tới máy chủ AI tư vấn: ${e.toString().replaceFirst('Exception: ', '')}. Vui lòng thử lại.',
          isUser: false,
          time: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Trợ Lý Tư Vấn Quà AI', showBack: true),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang khởi tạo phiên làm việc với Trợ lý AI...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_initError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.warningBg,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không kết nối được phiên AI: $_initError',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.warning),
                  ),
                ),
                TextButton(
                  onPressed: _initSession,
                  child: const Text('Thử lại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],

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
                onTap: _isSending ? null : () => _sendMessage(pill),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
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
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.smart_toy_outlined, size: 48, color: AppColors.accent),
                      const SizedBox(height: 12),
                      const Text(
                        'Trợ Lý AI Sẵn Sàng Hỗ Trợ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hỏi về set quà, ngân sách doanh nghiệp hoặc chiết khấu số lượng.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isSending) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppTokens.shadowSubtle,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Trợ lý AI đang soạn câu trả lời...',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final msg = _messages[index];
                    return Align(
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? AppColors.primary
                              : (msg.isError ? AppColors.errorBg : AppColors.surface),
                          borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                          border: msg.isUser
                              ? null
                              : Border.all(color: msg.isError ? AppColors.error : AppColors.border),
                          boxShadow: AppTokens.shadowSubtle,
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: msg.isUser
                                ? AppColors.textWhite
                                : (msg.isError ? AppColors.error : AppColors.textPrimary),
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
                    enabled: !_isSending,
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
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _isSending ? null : () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
