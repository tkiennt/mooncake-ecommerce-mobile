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

export default function ReviewFormScreen({ route, navigation }) {
  const { orderNumber = 'ORD-2026-8711', shopName = 'Bảo Ngọc Đường' } = route.params || {};

  const [scores, setScores] = useState({
    taste: 5,
    packaging: 5,
    delivery: 5,
    contract: 5,
  });

  const [comment, setComment] = useState(
    'Bánh dẻo nếp cái hoa vàng rất thơm ngon, vị ngọt thanh tự nhiên. Đội xe lạnh giao hàng đúng hẹn, logo công ty in ép kim trên hộp sắc nét và sang trọng.'
  );
  const [attachedPhotos] = useState([
    'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&auto=format&fit=crop&q=80',
  ]);
  const [loading, setLoading] = useState(false);

  const handleSubmitReview = () => {
    if (!comment.trim()) {
      Alert.alert('Chưa nhập nhận xét', 'Vui lòng chia sẻ cảm nhận thực tế của bạn về đợt nhận bánh này.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      Alert.alert(
        'Đánh Giá Doanh Nghiệp Thành Công!',
        'Cảm ơn đánh giá quý báu của quý công ty. Đánh giá 5★ đã được lưu trữ và cộng +3 điểm tín nhiệm bảo chứng cho xưởng sản xuất.',
        [
          {
            text: 'Về lịch sử đơn',
            onPress: () => navigation.goBack(),
          },
        ]
      );
    }, 1000);
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

          <Text style={styles.subHeading}>Ảnh chụp kiện hàng thực tế tại địa điểm giao:</Text>
          <View style={styles.photoRow}>
            {attachedPhotos.map((uri, idx) => (
              <Image key={idx} source={{ uri }} style={styles.photoThumb} />
            ))}
            <TouchableOpacity
              style={styles.addPhotoBtn}
              onPress={() => Alert.alert('Thêm ảnh', 'Chọn thêm ảnh chụp kiện hàng hoặc hộp quà từ thư viện.')}
            >
              <Ionicons name="camera-outline" size={24} color={COLORS.primary} />
              <Text style={styles.addPhotoText}>Thêm ảnh</Text>
            </TouchableOpacity>
          </View>
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
