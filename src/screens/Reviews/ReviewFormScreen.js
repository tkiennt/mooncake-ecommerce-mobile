import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Image,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import ReviewFilterStars from '../../components/lucian/ReviewFilterStars';
import { reviewService } from '../../services/api/reviewService';

export default function ReviewFormScreen({ route, navigation }) {
  // orderId is the real order (from order history); without it the screen is a demo.
  const { orderId, orderNumber = 'Đơn mẫu', shopName = 'Xưởng bánh' } = route.params || {};

  const [scores, setScores] = useState({
    taste: 5,
    packaging: 5,
    delivery: 5,
    contract: 5,
  });

  const [comment, setComment] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmitReview = () => {
    if (!comment.trim()) {
      Alert.alert('Chưa nhập nhận xét', 'Vui lòng chia sẻ cảm nhận thực tế của bạn về đợt nhận bánh này.');
      return;
    }

    if (!orderId) {
      Alert.alert('Chế độ demo', 'Đây là đơn mẫu nên đánh giá không được gửi đi.', [{ text: 'Quay lại', onPress: () => navigation.goBack() }]);
      return;
    }
    setLoading(true);
    // POST /reviews/transaction — the four on-screen criteria map onto the backend's ratings.
    const overall = Math.round((scores.taste + scores.packaging + scores.delivery + scores.contract) / 4);
    reviewService.submitTransactionReview({
      orderId,
      qualityRating: scores.taste,
      deliveryRating: scores.delivery,
      serviceRating: Math.round((scores.packaging + scores.contract) / 2),
      overallRating: overall,
      comment: comment.trim(),
      isAnonymous: false,
    })
      .then(() => Alert.alert('Đã gửi đánh giá', 'Cảm ơn bạn. Đánh giá sẽ được tính vào điểm uy tín của xưởng.', [
        { text: 'Về lịch sử đơn', onPress: () => navigation.goBack() },
      ]))
      .catch((error) => Alert.alert('Không gửi được đánh giá', error?.response?.data?.message || 'Vui lòng thử lại.'))
      .finally(() => setLoading(false));
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Đánh Giá Đơn Hàng B2B"
        subtitle={orderNumber}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Shop Info Card */}
        <View style={styles.shopCard}>
          <View style={styles.shopIconCircle}>
            <Ionicons name="storefront" size={22} color={COLORS.accent} />
          </View>
          <View style={styles.shopInfo}>
            <Text style={styles.shopName}>{shopName}</Text>
            <Text style={styles.shopSub}>Đơn hàng đã bàn giao xe lạnh & ký PoD thành công</Text>
          </View>
        </View>

        {/* 1. Lucian Review Filter Stars: 4 B2B Criteria */}
        <ReviewFilterStars
          initialScores={scores}
          onChange={setScores}
        />

        {/* Comment Section */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>NHẬN XÉT CHI TIẾT ĐỢT GIAO NHẬN</Text>
          <TextInput
            style={styles.commentInput}
            value={comment}
            onChangeText={setComment}
            multiline
            numberOfLines={4}
            placeholder="Chia sẻ trải nghiệm về chất lượng bánh, quy cách hộp quà, tiến độ giao vận..."
          />

        </View>

        {/* Action Button */}
        <CustomButton
          title={loading ? 'Đang gửi đánh giá...' : 'Gửi Đánh Giá Nghiệm Thu'}
          icon="⭐"
          onPress={handleSubmitReview}
          disabled={loading}
          style={styles.submitBtn}
        />
        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  shopCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    padding: 14,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  shopIconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: COLORS.accentGoldBg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  shopInfo: {
    flex: 1,
  },
  shopName: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 2,
  },
  shopSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    marginVertical: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  cardHeading: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 10,
    letterSpacing: 0.5,
  },
  commentInput: {
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    padding: 12,
    fontSize: 13,
    color: COLORS.textPrimary,
    minHeight: 80,
    textAlignVertical: 'top',
    marginBottom: 14,
  },
  subHeading: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginBottom: 8,
  },
  photoRow: {
    flexDirection: 'row',
    gap: 10,
  },
  photoThumb: {
    width: 70,
    height: 70,
    borderRadius: 8,
    backgroundColor: '#EAE5DB',
  },
  addPhotoBtn: {
    width: 70,
    height: 70,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.primary,
    borderStyle: 'dashed',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFF1F0',
  },
  addPhotoText: {
    fontSize: 10,
    color: COLORS.primary,
    fontWeight: '700',
    marginTop: 2,
  },
  submitBtn: {
    marginTop: 10,
  },
});
