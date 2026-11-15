import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/ai_repository.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';

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
    'Bánh thập cẩm bào ngư vi cá',
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
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Trợ Lý Tư Vấn Quà AI', showBack: true),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return _buildSkeleton();
    }

    if (_initError != null && _messages.isEmpty) {
      return Center(
        child: AppErrorState(
          title: 'Không thể kết nối trợ lý AI',
          message: _initError,
          retryLabel: 'Thử lại',
          onRetry: _initSession,
        ),
      );
    }

    return Column(
      children: [
        if (_initError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLG,
              vertical: AppTokens.spaceSM,
            ),
            color: AppColors.warningBg,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: AppTokens.spaceSM),
                Expanded(
                  child: Text(
                    'Kết nối AI gặp gián đoạn: $_initError',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11.5,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _initSession,
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Prompt suggestions with touch target >= 44px
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.surface,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
            itemCount: promptPills.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTokens.spaceSM),
            itemBuilder: (context, index) {
              final pill = promptPills[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                  child: Material(
                    color: AppColors.accentGoldBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: InkWell(
                      onTap: _isSending ? null : () => _sendMessage(pill),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                          vertical: AppTokens.spaceSM,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          pill,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // Message history or empty state
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.smart_toy_outlined,
                    title: 'Trợ Lý AI Sẵn Sàng Hỗ Trợ',
                    message: 'Hỏi về set quà trung thu, ngân sách doanh nghiệp hoặc chiết khấu số lượng lớn.',
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTokens.spaceLG),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isSending) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spaceLG,
                            vertical: AppTokens.spaceSM,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppTokens.elevationSubtle,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: AppTokens.spaceSM),
                              Text(
                                'Trợ lý AI đang soạn câu trả lời...',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final msg = _messages[index];
                    final isUser = msg.isUser;
                    final timeStr = DateFormat('HH:mm').format(msg.time);

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceLG,
                          vertical: AppTokens.spaceMD,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary
                              : (msg.isError ? AppColors.errorBg : AppColors.surface),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppTokens.radiusCard),
                            topRight: const Radius.circular(AppTokens.radiusCard),
                            bottomLeft: Radius.circular(isUser ? AppTokens.radiusCard : 2),
                            bottomRight: Radius.circular(isUser ? 2 : AppTokens.radiusCard),
                          ),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: msg.isError ? AppColors.error : AppColors.border,
                                ),
                          boxShadow: AppTokens.elevationSubtle,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                color: isUser
                                    ? AppColors.textWhite
                                    : (msg.isError ? AppColors.error : AppColors.textPrimary),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spaceXS),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: isUser ? Colors.white70 : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Sticky Bottom Input Bar with SafeArea
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMD,
            vertical: AppTokens.spaceSM,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: AppTokens.elevationSticky,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: 'Hỏi AI về vị bánh, chiết khấu, mẫu hộp...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
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
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceMD,
                        vertical: AppTokens.spaceMD,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSM),
                SizedBox(
                  width: AppTokens.minTapTarget,
                  height: AppTokens.minTapTarget,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.send, color: AppColors.primary, size: 22),
                    onPressed: _isSending ? null : () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton.shimmer(
      child: Column(
        children: [
          // Prompt pills skeleton
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppTokens.spaceMD),
            child: Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(right: AppTokens.spaceSM),
                  width: 110,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Messages skeleton
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 240,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 180,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 260,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
