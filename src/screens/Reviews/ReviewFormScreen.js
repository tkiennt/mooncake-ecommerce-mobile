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

export default function ReviewFormScreen({ route, navigation }) {
  const { orderNumber = 'ORD-2026-8711', shopName = 'Bảo Ngọc Đường' } = route.params || {};

  // 4 Tiêu chí đánh giá chuẩn nghiệp vụ Module 8
  const [qualityScore, setQualityScore] = useState(5);
  const [punctualityScore, setPunctualityScore] = useState(5);
  const [serviceScore, setServiceScore] = useState(5);
  const [packagingScore, setPackagingScore] = useState(5);

  const [comment, setComment] = useState(
    'Bánh dẻo nếp cái hoa vàng rất thơm ngon, vị ngọt thanh tự nhiên. Đội xe lạnh giao hàng đúng hẹn, logo công ty in ép kim trên hộp sắc nét và sang trọng.'
  );
  const [attachedPhotos] = useState([
    'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&auto=format&fit=crop&q=80',
  ]);
  const [loading, setLoading] = useState(false);

  const renderStars = (score, setScore) => {
    return (
      <View style={styles.starRow}>
        {[1, 2, 3, 4, 5].map((star) => (
          <TouchableOpacity key={star} onPress={() => setScore(star)} style={styles.starTouch}>
            <Ionicons
              name={star <= score ? 'star' : 'star-outline'}
              size={24}
              color={star <= score ? '#FAAD14' : COLORS.border}
            />
          </TouchableOpacity>
        ))}
        <Text style={styles.scoreText}>{score}/5 sao</Text>
      </View>
    );
  };

  const handleSubmitReview = () => {
    if (!comment.trim()) {
      Alert.alert('Chưa nhập nhận xét', 'Vui lòng chia sẻ cảm nhận thực tế của bạn về đợt nhận bánh này.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      Alert.alert(
        'Đánh Giá Thành Công!',
        'Cảm ơn đánh giá quý báu của quý doanh nghiệp. Đánh giá 5★ đã được cộng +3 điểm uy tín cho xưởng sản xuất.',
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
        title="Đánh Giá Đơn Hàng"
        subtitle={orderNumber}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.shopCard}>
          <Ionicons name="storefront" size={20} color={COLORS.accent} />
          <View style={styles.shopInfo}>
            <Text style={styles.shopName}>{shopName}</Text>
            <Text style={styles.shopSub}>Đơn hàng đã bàn giao xe lạnh thành công</Text>
          </View>
        </View>

        {/* 4 Criteria Card */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>4 TIÊU CHÍ CHẤT LƯỢNG B2B</Text>

          <View style={styles.criterionBox}>
            <Text style={styles.critLabel}>1. Hương vị & Chất lượng bánh</Text>
            {renderStars(qualityScore, setQualityScore)}
          </View>

          <View style={styles.criterionBox}>
            <Text style={styles.critLabel}>2. Đúng hạn bàn giao (Xe lạnh)</Text>
            {renderStars(punctualityScore, setPunctualityScore)}
          </View>

          <View style={styles.criterionBox}>
            <Text style={styles.critLabel}>3. Dịch vụ hỗ trợ & Thái độ phục vụ</Text>
            {renderStars(serviceScore, setServiceScore)}
          </View>

          <View style={styles.criterionBox}>
            <Text style={styles.critLabel}>4. Quy cách đóng gói & Ép kim Logo</Text>
            {renderStars(packagingScore, setPackagingScore)}
          </View>
        </View>

        {/* Comment Card */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>NHẬN XÉT CHI TIẾT</Text>
          <TextInput
            style={styles.commentInput}
            value={comment}
            onChangeText={setComment}
            multiline
            placeholder="Chia sẻ nhận xét về bánh, độ ngọt, chất lượng vỏ bánh và quy cách đóng gói..."
          />
        </View>

        {/* Photo attachments */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>ẢNH CHỤP KIỆN BÁNH THỰC TẾ ({attachedPhotos.length})</Text>
          <View style={styles.photoRow}>
            {attachedPhotos.map((url, idx) => (
              <Image key={idx} source={{ uri: url }} style={styles.attachedImg} />
            ))}
            <TouchableOpacity
              style={styles.addPhotoBtn}
              onPress={() => Alert.alert('Tải ảnh', 'Chụp ảnh hoặc chọn ảnh thực tế từ thư viện.')}
            >
              <Ionicons name="camera-outline" size={24} color={COLORS.primary} />
              <Text style={styles.addPhotoText}>Thêm ảnh</Text>
            </TouchableOpacity>
          </View>
        </View>

        <CustomButton
          title="Gửi Đánh Giá Doanh Nghiệp"
          icon="⭐"
          onPress={handleSubmitReview}
          loading={loading}
          size="large"
          style={styles.submitBtn}
        />
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
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    marginBottom: 16,
  },
  shopInfo: {
    marginLeft: 10,
  },
  shopName: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  shopSub: {
    fontSize: 12,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  card: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  cardHeading: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  criterionBox: {
    marginBottom: 12,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F5F3EF',
  },
  critLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginBottom: 6,
  },
  starRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  starTouch: {
    marginRight: 6,
  },
  scoreText: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.accent,
    marginLeft: 10,
  },
  commentInput: {
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    padding: 12,
    fontSize: 13,
    color: COLORS.textPrimary,
    backgroundColor: '#FAFAF8',
    minHeight: 80,
    textAlignVertical: 'top',
  },
  photoRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  attachedImg: {
    width: 72,
    height: 72,
    borderRadius: 8,
    marginRight: 10,
  },
  addPhotoBtn: {
    width: 72,
    height: 72,
    borderRadius: 8,
    borderWidth: 1,
    borderStyle: 'dashed',
    borderColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(140, 21, 36, 0.03)',
  },
  addPhotoText: {
    fontSize: 10,
    color: COLORS.primary,
    fontWeight: '600',
    marginTop: 2,
  },
  submitBtn: {
    marginTop: 8,
    marginBottom: 20,
  },
});

