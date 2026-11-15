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
import '../../data/models/chat.dart';
import '../../data/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

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

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StorageService _storage = StorageService();

  HubConnection? _hubConnection;

  static const List<String> _quickPrompts = [
    'Tư vấn báo giá sỉ 100+ hộp',
    'Yêu cầu quy cách in logo hộp quà',
    'Thời hạn giao hàng và chính sách vận chuyển',
    'Hóa đơn VAT & hợp đồng mua bán B2B',
  ];

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
        _errorMessage = e.toString();
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
        _errorMessage = e.toString();
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
        _errorMessage = e.toString();
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
      appBar: AppHeader(
        title: 'Tin nhắn với xưởng bánh',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách cuộc trò chuyện...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        const Text('Không thể tải tin nhắn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        CustomButton(title: 'Thử lại', size: ButtonSize.small, onPress: _initChat),
                      ],
                    ),
                  ),
                )
              : _threads.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: AppColors.accentGoldBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline, size: 36, color: AppColors.accent),
                            ),
                            const SizedBox(height: 16),
                            const Text('Chưa có cuộc trò chuyện nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            const SizedBox(height: 8),
                            const Text(
                              'Bạn có thể vào trang chi tiết sản phẩm hoặc gian hàng xưởng bánh để bắt đầu trao đổi, hỏi giá sỉ và mẫu hộp quà.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              title: 'Khám phá sản phẩm',
                              size: ButtonSize.small,
                              onPress: () => context.go('/search'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _initChat,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _threads.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final t = _threads[index];
                          final timeStr = t.lastMessageAt != null
                              ? DateFormat('HH:mm dd/MM').format(t.lastMessageAt!)
                              : '';

                          return Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.accentGoldBg,
                                child: const Icon(Icons.storefront, color: AppColors.accent, size: 24),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.shopName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (timeStr.isNotEmpty)
                                    Text(
                                      timeStr,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  t.lastMessage ?? 'Nhấn để bắt đầu trao đổi với xưởng...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: t.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontWeight: t.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              trailing: t.unreadCount > 0
                                  ? Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${t.unreadCount}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : null,
                              onTap: () => _selectThread(t),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  // --- Active 1-1 Conversation View ---
  Widget _buildConversationScreen() {
    final shopName = _activeThread?.shopName ?? widget.shopName ?? 'Xưởng bánh';

    return Scaffold(
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
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_outlined, size: 44, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'Bắt đầu cuộc trò chuyện với $shopName',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Hãy gửi câu hỏi về chiết khấu sỉ, quy cách bao bì hoặc thời gian sản xuất bánh.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),

          // Quick prompt chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        prompt,
                        style: const TextStyle(fontSize: 11, color: AppColors.primaryDark),
                      ),
                      backgroundColor: AppColors.surfaceHover,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn trao đổi với xưởng...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
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
                        : const Icon(Icons.send_rounded, color: AppColors.primary, size: 24),
                    onPressed: _isSending ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isFromMe;
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accentGoldBg,
              child: const Icon(Icons.storefront, size: 14, color: AppColors.accent),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 14),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
