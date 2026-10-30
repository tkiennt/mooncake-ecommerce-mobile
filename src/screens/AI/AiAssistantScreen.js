import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import { apiClient } from '../../api/apiClient';
import { ENDPOINTS } from '../../api/endpoints';

const PRESET_PROMPTS = [
  'Tư vấn 200 hộp quà ngân sách 600k/hộp',
  'Set quà nào phù hợp biếu đối tác chiến lược?',
  'Quy trình xuất hóa đơn VAT & ký quỹ SafeTrade?',
  'Bánh lava trứng chảy có hạn dùng bao lâu?',
];

export default function AiAssistantScreen({ navigation }) {
  const [messages, setMessages] = useState([
    {
      id: 'msg-1',
      sender: 'ai',
      text: 'Xin chào quý doanh nghiệp! Tôi là Trợ lý AI Nguyệt Phố. Tôi có thể giúp quý khách lập kế hoạch ngân sách quà tặng, chọn hương vị bánh nghệ nhân phù hợp với văn hóa đối tác, hoặc giải đáp các chính sách đấu thầu B2B.',
      time: 'Vừa xong',
    },
  ]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(false);
  const scrollViewRef = useRef();

  const handleSend = async (customText) => {
    const textToSend = customText || inputText;
    if (!textToSend.trim()) return;

    const userMsg = {
      id: `msg-${Date.now()}`,
      sender: 'user',
      text: textToSend,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    if (!customText) setInputText('');
    setLoading(true);

    try {
      // Thử gọi backend AI Chat API
      const res = await apiClient.post(ENDPOINTS.AI_CHAT, { message: textToSend });
      const aiReply = res?.data?.reply || res?.reply;
      if (aiReply) {
        setMessages((prev) => [
          ...prev,
          {
            id: `ai-${Date.now()}`,
            sender: 'ai',
            text: aiReply,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          },
        ]);
        return;
      }
      throw new Error('Fallback AI');
    } catch (e) {
      // Smart Fallback phản hồi theo ngữ cảnh
      setTimeout(() => {
        let replyText = '';
        const lower = textToSend.toLowerCase();

        if (lower.includes('600k') || lower.includes('ngân sách') || lower.includes('200')) {
          replyText =
            'Với ngân sách khoảng 600.000 ₫/hộp cho 200 suất quà, đề xuất tối ưu nhất là Hộp Hoàng Triều Thượng Hạng (4 Bánh + Trà Ô Long) từ Xưởng Kinh Đô Cổ. Khi đặt số lượng 200 hộp, quý doanh nghiệp được hưởng mức chiết khấu bậc thang -15%, đơn giá thực tế chỉ còn khoảng 552.500 ₫/hộp và được miễn phí in logo doanh nghiệp ép kim nổi.';
        } else if (lower.includes('đối tác') || lower.includes('vip') || lower.includes('chiến lược')) {
          replyText =
            'Dành cho đối tác chiến lược cấp cao, quý khách nên chọn Set Hộp Sơn Mài Nguyệt Dạ Thưởng Hoa với vị nhân Bào Ngư Vi Cá và Lava Trứng Chảy Hồng Kông. Mẫu hộp gỗ sơn mài dập kim không chỉ thể hiện đẳng cấp hoàng gia mà còn đi kèm thiệp chúc mừng thiết kế riêng.';
        } else if (lower.includes('vat') || lower.includes('ký quỹ') || lower.includes('safetrade')) {
          replyText =
            'Tất cả các đơn hàng và hợp đồng trên sàn Nguyệt Phố B2B đều được xuất hóa đơn điện tử VAT đầy đủ. Cơ chế ký quỹ SafeTrade Escrow giữ tiền cọc an toàn, sàn chỉ giải ngân cho xưởng khi quý doanh nghiệp đã ký biên bản bàn giao xe lạnh PoD đạt chuẩn.';
        } else {
          replyText =
            `Tôi đã ghi nhận yêu cầu của quý khách: "${textToSend}". Hệ thống khuyến nghị quý khách có thể mở một gói thầu RFQ để hơn 50 xưởng nghệ nhân gửi báo giá cạnh tranh nhất, hoặc liên hệ Hotline B2B 1900 8899 để chuyên viên thu mua hỗ trợ trực tiếp.`;
        }

        setMessages((prev) => [
          ...prev,
          {
            id: `ai-${Date.now()}`,
            sender: 'ai',
            text: replyText,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          },
        ]);
        setLoading(false);
      }, 900);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <AppHeader
        title="Trợ Lý Ảo Nguyệt Phố"
        subtitle="AI tư vấn quà tặng & ngân sách B2B"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      {/* Preset suggestions */}
      <View style={styles.presetContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.presetScroll}>
          {PRESET_PROMPTS.map((prompt, idx) => (
            <TouchableOpacity
              key={idx}
              style={styles.presetChip}
              onPress={() => handleSend(prompt)}
            >
              <Text style={styles.presetText}>{prompt}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      {/* Chat messages */}
      <ScrollView
        ref={scrollViewRef}
        contentContainerStyle={styles.messagesScroll}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
      >
        {messages.map((m) => {
          const isAi = m.sender === 'ai';
          return (
            <View
              key={m.id}
              style={[
                styles.messageRow,
                isAi ? styles.messageRowAi : styles.messageRowUser,
              ]}
            >
              {isAi && (
                <View style={styles.aiAvatar}>
                  <Ionicons name="sparkles" size={14} color="#FFF" />
                </View>
              )}
              <View
                style={[
                  styles.messageBubble,
                  isAi ? styles.messageBubbleAi : styles.messageBubbleUser,
                ]}
              >
                <Text
                  style={[
                    styles.messageText,
                    isAi ? styles.messageTextAi : styles.messageTextUser,
                  ]}
                >
                  {m.text}
                </Text>
                <Text
                  style={[
                    styles.messageTime,
                    isAi ? styles.messageTimeAi : styles.messageTimeUser,
                  ]}
                >
                  {m.time}
                </Text>
              </View>
            </View>
          );
        })}

        {loading && (
          <View style={styles.loadingRow}>
            <View style={styles.aiAvatar}>
              <Ionicons name="sparkles" size={14} color="#FFF" />
            </View>
            <View style={styles.loadingBubble}>
              <ActivityIndicator size="small" color={COLORS.primary} />
              <Text style={styles.loadingText}>Trợ lý AI đang phân tích dữ liệu xưởng bánh...</Text>
            </View>
          </View>
        )}
      </ScrollView>

      {/* Input area */}
      <View style={styles.inputBar}>
        <TextInput
          style={styles.input}
          placeholder="Nhập câu hỏi hoặc yêu cầu tư vấn..."
          value={inputText}
          onChangeText={setInputText}
          multiline
        />
        <TouchableOpacity
          style={[styles.sendBtn, !inputText.trim() && styles.sendBtnDisabled]}
          onPress={() => handleSend()}
          disabled={!inputText.trim()}
        >
          <Ionicons name="send" size={18} color="#FFF" />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  presetContainer: {
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    paddingVertical: 8,
  },
  presetScroll: {
    paddingHorizontal: 16,
  },
  presetChip: {
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 8,
  },
  presetText: {
    fontSize: 12,
    color: '#873800',
    fontWeight: '600',
  },
  messagesScroll: {
    padding: 16,
    paddingBottom: 20,
  },
  messageRow: {
    flexDirection: 'row',
    marginBottom: 14,
    alignItems: 'flex-end',
  },
  messageRowAi: {
    justifyContent: 'flex-start',
  },
  messageRowUser: {
    justifyContent: 'flex-end',
  },
  aiAvatar: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
    marginBottom: 4,
  },
  messageBubble: {
    maxWidth: '82%',
    padding: 14,
    borderRadius: 14,
  },
  messageBubbleAi: {
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderBottomLeftRadius: 2,
  },
  messageBubbleUser: {
    backgroundColor: COLORS.primary,
    borderBottomRightRadius: 2,
  },
  messageText: {
    fontSize: 13,
    lineHeight: 20,
  },
  messageTextAi: {
    color: COLORS.textPrimary,
  },
  messageTextUser: {
    color: '#FFF',
  },
  messageTime: {
    fontSize: 10,
    marginTop: 6,
  },
  messageTimeAi: {
    color: COLORS.textMuted,
    textAlign: 'left',
  },
  messageTimeUser: {
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'right',
  },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 14,
  },
  loadingBubble: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: COLORS.border,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
  },
  loadingText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginLeft: 8,
  },
  inputBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  input: {
    flex: 1,
    backgroundColor: '#FAFAF8',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 8,
    fontSize: 14,
    color: COLORS.textPrimary,
    maxHeight: 90,
  },
  sendBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: 10,
  },
  sendBtnDisabled: {
    backgroundColor: COLORS.border,
  },
});

