import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';

enum _ChatContextCategory {
  order('Đơn hàng', Icons.local_shipping_outlined),
  pricing('Báo giá sỉ', Icons.sell_outlined),
  packaging('In ấn bao bì', Icons.card_giftcard_outlined),
  contract('Hợp đồng & VAT', Icons.assignment_outlined);

  final String label;
  final IconData icon;
  const _ChatContextCategory(this.label, this.icon);
}

class ChatScreen extends ConsumerStatefulWidget {
  final String? threadId;
  final String? shopId;
  final String? shopName;

  const ChatScreen({
    super.key,
    this.threadId,
    this.shopId,
    this.shopName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // If activeThread is null, we show the inbox threads list
  ChatThread? _activeThread;
  List<ChatThread> _threads = [];
  List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  _ChatContextCategory _selectedCategory = _ChatContextCategory.order;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StorageService _storage = StorageService();

  HubConnection? _hubConnection;

  // Contextual question prompts (pattern ShopeeFood)
  static const Map<_ChatContextCategory, List<String>> _contextualPrompts = {
    _ChatContextCategory.order: [
      'Tiến độ sản xuất đơn hàng của tôi đến đâu rồi?',
      'Đơn hàng khi nào xuất kho và giao đến nơi?',
      'Xưởng gửi giúp ảnh chụp kiện hàng thực tế và tem niêm phong',
      'Đơn hàng vận chuyển bằng xe lạnh hay xe thường?',
      'Tôi muốn cập nhật thông tin nhận hàng của đơn này',
    ],
    _ChatContextCategory.pricing: [
      'Tư vấn báo giá sỉ cho số lượng từ 100 hộp',
      'Mức chiết khấu cho đơn doanh nghiệp 500+ hộp',
      'Gửi giúp tôi catalogue và bảng giá bánh trung thu 2026',
      'Chính sách thanh toán và đặt cọc chia 3 đợt',
    ],
    _ChatContextCategory.packaging: [
      'Yêu cầu quy cách in logo ép kim nhũ vàng lên hộp',
      'Thời gian duyệt maket thiết kế bao bì là bao lâu?',
      'Có hỗ trợ làm thiệp chúc mừng riêng từng hộp không?',
      'Xưởng có mẫu hộp 4 bánh và 6 bánh sẵn không?',
    ],
    _ChatContextCategory.contract: [
      'Yêu cầu lập hợp đồng mua bán pháp nhân',
      'Cung cấp thông tin để xuất hóa đơn điện tử VAT',
      'Giấy chứng nhận an toàn thực phẩm ISO 22000 / HACCP',
    ],
  };

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _disposeSignalR();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(chatRepositoryProvider);

    try {
      if (widget.threadId != null && widget.threadId!.isNotEmpty) {
        final thread = await repo.getThread(widget.threadId!);
        _activeThread = thread;
        await _loadMessages(thread.id);
      } else if (widget.shopId != null && widget.shopId!.isNotEmpty) {
        final thread = await repo.openThread(shopId: widget.shopId!);
        _activeThread = thread;
        await _loadMessages(thread.id);
      } else {
        // Show inbox list
        final list = await repo.getThreads();
        if (!mounted) return;
        setState(() {
          _threads = list;
          _isLoading = false;
        });
        return;
      }

      await _connectSignalR();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant
    return [
      values.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }

  Future<void> _markRead(String threadId, String messageId) async {
    if (messageId.isEmpty) return;
    try {
      final client = ref.read(apiClientProvider);
      await client.dio.post(
        ApiEndpoints.chatRead(threadId),
        data: {
          'messageId': messageId,
        },
      );
    } catch (_) {
      // Non-blocking read receipt update
    }
  }

  Future<void> _loadMessages(String threadId) async {
    final client = ref.read(apiClientProvider);
    final user = ref.read(authProvider).user;

    try {
      final response = await client.dio.get(
        ApiEndpoints.chatMessages(threadId),
        queryParameters: {'pageSize': 50},
      );
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      final msgs = rawList.map((m) {
        final map = m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map);
        final sId = map['senderId']?.toString() ?? map['userId']?.toString() ?? '';
        return ChatMessage(
          id: map['id']?.toString() ?? map['messageId']?.toString() ?? '',
          threadId: map['threadId']?.toString() ?? threadId,
          senderId: sId,
          senderName: map['senderName']?.toString() ?? map['sender']?['fullName']?.toString(),
          content: map['body']?.toString() ?? map['content']?.toString() ?? map['message']?.toString() ?? '',
          createdAt: map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          isFromMe: user?.id != null && sId == user!.id,
        );
      }).toList();

      if (msgs.isNotEmpty) {
        final lastMsg = msgs.last;
        if (lastMsg.id.isNotEmpty) {
          await _markRead(threadId, lastMsg.id);
        }
      }

      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _connectSignalR() async {
    if (_activeThread == null) return;

    try {
      final hubUrl = ApiEndpoints.chatHubUrl.contains('/api/v1')
          ? ApiEndpoints.chatHubUrl
          : '${ApiEndpoints.baseUrl}/hubs/chat';

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => (await _storage.getAccessToken()) ?? '',
            ),
          )
          .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000])
          .build();

      _hubConnection?.on('MessageCreated', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final data = arguments.first;
          final jsonMap = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
          final user = ref.read(authProvider).user;
          final sId = jsonMap['senderId']?.toString() ?? jsonMap['userId']?.toString() ?? '';
          final newMsg = ChatMessage(
            id: jsonMap['id']?.toString() ?? jsonMap['messageId']?.toString() ?? '',
            threadId: jsonMap['threadId']?.toString() ?? '',
            senderId: sId,
            senderName: jsonMap['senderName']?.toString() ?? jsonMap['sender']?['fullName']?.toString(),
            content: jsonMap['body']?.toString() ?? jsonMap['content']?.toString() ?? jsonMap['message']?.toString() ?? '',
            createdAt: jsonMap['createdAt'] != null
                ? DateTime.tryParse(jsonMap['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now(),
            isFromMe: user?.id != null && sId == user!.id,
          );

          if (newMsg.threadId == _activeThread?.id) {
            if (!mounted) return;
            setState(() {
              if (!_messages.any((m) => m.id == newMsg.id)) {
                _messages.add(newMsg);
              }
            });
            _scrollToBottom();

            if (!newMsg.isFromMe && newMsg.id.isNotEmpty) {
              _markRead(_activeThread!.id, newMsg.id);
            }
          }
        }
      });

      await _hubConnection?.start();
      await _hubConnection?.invoke('JoinThread', args: [_activeThread!.id]);
    } catch (_) {
      // Non-blocking fallback for offline or signalr error
    }
  }

  Future<void> _disposeSignalR() async {
    if (_hubConnection != null && _activeThread != null) {
      try {
        await _hubConnection?.invoke('LeaveThread', args: [_activeThread!.id]);
        await _hubConnection?.stop();
      } catch (_) {}
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

  Future<void> _sendMessage([String? presetContent]) async {
    final text = presetContent ?? _textController.text.trim();
    if (text.isEmpty || _activeThread == null || _isSending) return;

    if (presetContent == null) {
      _textController.clear();
    }

    setState(() => _isSending = true);

    final client = ref.read(apiClientProvider);
    final user = ref.read(authProvider).user;
    final clientMsgId = _generateUuid();

    try {
      final response = await client.dio.post(
        ApiEndpoints.chatMessages(_activeThread!.id),
        data: {
          'clientMessageId': clientMsgId,
          'body': text,
        },
      );

      final data = ApiClient.unwrap(response);
      final respMap = data is Map<String, dynamic>
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : null);

      final sId = respMap?['senderId']?.toString() ?? user?.id ?? '';
      final newMsg = ChatMessage(
        id: respMap?['id']?.toString() ?? clientMsgId,
        threadId: _activeThread!.id,
        senderId: sId,
        senderName: respMap?['senderName']?.toString() ?? user?.fullName,
        content: respMap?['body']?.toString() ??
            respMap?['content']?.toString() ??
            text,
        createdAt: respMap?['createdAt'] != null
            ? DateTime.tryParse(respMap!['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isFromMe: true,
      );

      if (!mounted) return;
      setState(() {
        if (!_messages.any((m) => m.id == newMsg.id)) {
          _messages.add(newMsg);
        }
        _isSending = false;
      });
      _scrollToBottom();

      if (newMsg.id.isNotEmpty) {
        _markRead(_activeThread!.id, newMsg.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không gửi được tin nhắn: ${ApiClient.handleError(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _selectThread(ChatThread thread) async {
    setState(() {
      _activeThread = thread;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadMessages(thread.id);
      await _connectSignalR();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeThread == null) {
      return _buildInboxScreen();
    }

    return _buildConversationScreen();
  }

  // --- Inbox View ---
  Widget _buildInboxScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Tin Nhắn Với Xưởng Bánh',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _buildInboxBody(),
    );
  }

  Widget _buildInboxBody() {
    if (_isLoading) {
      return _buildInboxSkeleton();
    }

    if (_errorMessage != null) {
      return Center(
        child: AppErrorState(
          title: 'Không thể tải cuộc trò chuyện',
          message: _errorMessage,
          retryLabel: 'Thử lại',
          onRetry: _initChat,
        ),
      );
    }

    if (_threads.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Chưa có cuộc trò chuyện nào',
          message:
              'Bạn có thể vào trang chi tiết sản phẩm hoặc gian hàng xưởng bánh để bắt đầu trao đổi, hỏi giá sỉ và mẫu hộp quà.',
          actionLabel: 'Khám phá sản phẩm',
          onAction: () => context.go('/search'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initChat,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceMD,
        ),
        itemCount: _threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final t = _threads[index];
          final timeStr = t.lastMessageAt != null
              ? DateFormat('HH:mm dd/MM').format(t.lastMessageAt!)
              : '';

          return Material(
            color: Colors.transparent,
            child: ListTile(
              minVerticalPadding: AppTokens.spaceMD,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceSM,
                vertical: AppTokens.spaceXS,
              ),
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentGoldBg,
                child: Icon(Icons.storefront, color: AppColors.accent, size: 24),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.shopName,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceXS),
                child: Text(
                  t.lastMessage ?? 'Nhấn để bắt đầu trao đổi với xưởng...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12.5,
                    color: t.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: t.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              trailing: t.unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(AppTokens.spaceXS + 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${t.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () => _selectThread(t),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInboxSkeleton() {
    return AppSkeleton.shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceMD),
          child: Row(
            children: [
              const AppSkeleton.circle(radius: 24),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        AppSkeleton(width: 140, height: 14),
                        AppSkeleton(width: 50, height: 10),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceSM),
                    const AppSkeleton.text(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Active 1-1 Conversation View ---
  Widget _buildConversationScreen() {
    final shopName = _activeThread?.shopName ?? widget.shopName ?? 'Xưởng bánh đối tác';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: shopName,
        subtitle: 'Xưởng sản xuất đối tác · Trực tuyến',
        showBack: true,
        onBack: () {
          if (widget.shopId != null || widget.threadId != null) {
            context.pop();
          } else {
            setState(() {
              _activeThread = null;
              _initChat();
            });
          }
        },
      ),
      body: Column(
        children: [
          // Messages list or loading/empty state
          Expanded(
            child: _buildMessagesArea(shopName),
          ),

          // Contextual prompt chips (ShopeeFood pattern)
          _buildContextualPromptChips(),

          // Bottom Input Bar with SafeArea
          _buildBottomInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(String shopName) {
    if (_isLoading) {
      return _buildMessagesSkeleton();
    }

    if (_errorMessage != null && _messages.isEmpty) {
      return Center(
        child: AppErrorState(
          title: 'Không thể tải tin nhắn',
          message: _errorMessage,
          retryLabel: 'Thử lại',
          onRetry: () => _activeThread != null ? _loadMessages(_activeThread!.id) : _initChat(),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.chat_outlined,
          title: 'Bắt đầu cuộc trò chuyện với $shopName',
          message:
              'Gửi câu hỏi về tiến độ đơn hàng, chiết khấu sỉ, quy cách bao bì hoặc thời gian sản xuất bánh.',
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceMD,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildContextualPromptChips() {
    final currentPrompts = _contextualPrompts[_selectedCategory] ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Horizontal Context Categories (ShopeeFood tabs)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMD,
              vertical: AppTokens.spaceXS,
            ),
            child: Row(
              children: _ChatContextCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTokens.spaceSM),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceMD,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceHover,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppTokens.spaceXS),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Contextual question chips with min tap target >= 44px
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppTokens.spaceMD,
              right: AppTokens.spaceMD,
              bottom: AppTokens.spaceSM,
            ),
            child: Row(
              children: currentPrompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppTokens.spaceSM),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                    child: Center(
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        label: Text(
                          prompt,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11.5,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: AppColors.accentGoldBg,
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceSM,
                          vertical: AppTokens.spaceSM,
                        ),
                        onPressed: _isSending ? null : () => _sendMessage(prompt),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMD,
        vertical: AppTokens.spaceSM,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: AppTokens.elevationSticky,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn trao đổi với xưởng...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceLG,
                    vertical: AppTokens.spaceMD,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
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
                    : const Icon(Icons.send_rounded, color: AppColors.primary, size: 24),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isFromMe;
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXS),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accentGoldBg,
              child: Icon(Icons.storefront, size: 14, color: AppColors.accent),
            ),
            const SizedBox(width: AppTokens.spaceSM),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMD,
                vertical: AppTokens.spaceSM + 2,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTokens.radiusCard),
                  topRight: const Radius.circular(AppTokens.radiusCard),
                  bottomLeft: Radius.circular(isMe ? AppTokens.radiusCard : 2),
                  bottomRight: Radius.circular(isMe ? 2 : AppTokens.radiusCard),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
                boxShadow: AppTokens.elevationSubtle,
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXS),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: AppTokens.spaceXS),
        ],
      ),
    );
  }

  Widget _buildMessagesSkeleton() {
    return AppSkeleton.shimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 220,
              height: 52,
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
              width: 170,
              height: 40,
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
              width: 250,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
