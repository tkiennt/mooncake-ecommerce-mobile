import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../theme/colors';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { navigationRef } from './navigationRef';

// Core Screens
import LoginScreen from '../screens/Auth/LoginScreen';
import RegisterScreen from '../screens/Auth/RegisterScreen';
import VerifyEmailScreen from '../screens/Auth/VerifyEmailScreen';
import ForgotPasswordScreen from '../screens/Auth/ForgotPasswordScreen';
import ResetPasswordScreen from '../screens/Auth/ResetPasswordScreen';
import HomeScreen from '../screens/Home/HomeScreen';
import SearchScreen from '../screens/Catalog/SearchScreen';
import ProductDetailScreen from '../screens/Catalog/ProductDetailScreen';
import CartScreen from '../screens/Cart/CartScreen';
import CheckoutScreen from '../screens/Cart/CheckoutScreen';
import PaymentResultScreen from '../screens/Cart/PaymentResultScreen';
import OrderHistoryScreen from '../screens/Profile/OrderHistoryScreen';
import OrderDetailScreen from '../screens/Profile/OrderDetailScreen';
import ProfileScreen from '../screens/Profile/ProfileScreen';
import EditProfileScreen from '../screens/Profile/EditProfileScreen';

// Phase 2: B2B Core Screens
import CreateRfqScreen from '../screens/B2B/CreateRfqScreen';
import RfqListScreen from '../screens/B2B/RfqListScreen';
import RfqDetailBiddingScreen from '../screens/B2B/RfqDetailBiddingScreen';
import ContractsScreen from '../screens/B2B/ContractsScreen';
import ContractSignScreen from '../screens/B2B/ContractSignScreen';
import DeliveryPoDScreen from '../screens/B2B/DeliveryPoDScreen';
import NotificationScreen from '../screens/Notification/NotificationScreen';
import NotificationSettingsScreen from '../screens/Notification/NotificationSettingsScreen';

// Phase 3: AI & Reviews Screens
import AiAssistantScreen from '../screens/AI/AiAssistantScreen';
import ReviewFormScreen from '../screens/Reviews/ReviewFormScreen';

// UI Showcase Screen
import UiCatalogScreen from '../screens/Dev/UiCatalogScreen';
import BottomTabBar from '../components/common/BottomTabBar';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

const linking = {
  prefixes: ['nguyetpho://', 'http://localhost:19006', 'http://localhost:8081'],
  config: {
    screens: {
      MainTabs: {
        screens: {
          HomeTab: '',
          SearchTab: 'kham-pha',
          CartTab: 'gio-hang',
          OrdersTab: 'don-hang',
          ProfileTab: 'tai-khoan',
        },
      },
      PaymentResult: 'thanh-toan/ket-qua',
      OrderDetail: 'don-hang/:orderId',
      Contracts: 'hop-dong',
      DeliveryPoD: 'giao-hang/:orderId',
      Register: 'dang-ky',
      VerifyEmail: 'xac-thuc-email',
      ForgotPassword: 'quen-mat-khau',
      ResetPassword: 'dat-lai-mat-khau',
      EditProfile: 'sua-ho-so',
      NotificationSettings: 'thong-bao/cai-dat',
    },
  },
};

function MainTabs() {
  const { getCartTotals } = useCart();
  const { totalItems } = getCartTotals();

  return (
    <Tab.Navigator
      tabBar={(props) => <BottomTabBar {...props} cartBadgeCount={totalItems} />}
      screenOptions={{
        headerShown: false,
      }}
    >
      <Tab.Screen
        name="HomeTab"
        component={HomeScreen}
        options={{ tabBarLabel: 'Trang chủ' }}
      />
      <Tab.Screen
        name="SearchTab"
        component={SearchScreen}
        options={{ tabBarLabel: 'Khám phá' }}
      />
      <Tab.Screen
        name="CartTab"
        component={CartScreen}
        options={{ tabBarLabel: 'Giỏ hàng' }}
      />
      <Tab.Screen
        name="OrdersTab"
        component={OrderHistoryScreen}
        options={{ tabBarLabel: 'Đơn hàng' }}
      />
      <Tab.Screen
        name="ProfileTab"
        component={ProfileScreen}
        options={{ tabBarLabel: 'Tài khoản' }}
      />
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  const { user, loading } = useAuth();

  if (loading) {
    return null;
  }

  return (
    <NavigationContainer ref={navigationRef} linking={linking}>
      <Stack.Navigator
        initialRouteName="MainTabs"
        screenOptions={{ headerShown: false }}
      >
        <Stack.Screen name="MainTabs" component={MainTabs} />
        <Stack.Screen name="Login" component={LoginScreen} />
        <Stack.Screen name="Register" component={RegisterScreen} />
        <Stack.Screen name="VerifyEmail" component={VerifyEmailScreen} />
        <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
        <Stack.Screen name="ResetPassword" component={ResetPasswordScreen} />
        <Stack.Screen name="Search" component={SearchScreen} />
        <Stack.Screen name="ProductDetail" component={ProductDetailScreen} />
        <Stack.Screen name="Checkout" component={CheckoutScreen} />
        <Stack.Screen name="OrderDetail" component={OrderDetailScreen} />
        <Stack.Screen name="PaymentResult" component={PaymentResultScreen} />
        <Stack.Screen name="EditProfile" component={EditProfileScreen} />

        {/* B2B Screens */}
        <Stack.Screen name="Notification" component={NotificationScreen} />
        <Stack.Screen name="NotificationSettings" component={NotificationSettingsScreen} />
        <Stack.Screen name="CreateRfq" component={CreateRfqScreen} />
        <Stack.Screen name="RfqList" component={RfqListScreen} />
        <Stack.Screen name="RfqDetailBidding" component={RfqDetailBiddingScreen} />
        <Stack.Screen name="Contracts" component={ContractsScreen} />
        <Stack.Screen name="ContractSign" component={ContractSignScreen} />
        <Stack.Screen name="DeliveryPoD" component={DeliveryPoDScreen} />

        {/* AI & Reviews */}
        <Stack.Screen name="AiAssistant" component={AiAssistantScreen} />
        <Stack.Screen name="ReviewForm" component={ReviewFormScreen} />

        {/* UI Showcase AntD & Lucian */}
        <Stack.Screen name="UiCatalog" component={UiCatalogScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
