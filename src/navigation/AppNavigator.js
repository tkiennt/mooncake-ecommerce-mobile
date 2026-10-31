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
import HomeScreen from '../screens/Home/HomeScreen';
import SearchScreen from '../screens/Catalog/SearchScreen';
import ProductDetailScreen from '../screens/Catalog/ProductDetailScreen';
import CartScreen from '../screens/Cart/CartScreen';
import CheckoutScreen from '../screens/Cart/CheckoutScreen';
import OrderHistoryScreen from '../screens/Profile/OrderHistoryScreen';
import ProfileScreen from '../screens/Profile/ProfileScreen';

// Phase 2: B2B Core Screens
import CreateRfqScreen from '../screens/B2B/CreateRfqScreen';
import RfqListScreen from '../screens/B2B/RfqListScreen';
import RfqDetailBiddingScreen from '../screens/B2B/RfqDetailBiddingScreen';
import ContractsScreen from '../screens/B2B/ContractsScreen';
import ContractSignScreen from '../screens/B2B/ContractSignScreen';
import DeliveryPoDScreen from '../screens/B2B/DeliveryPoDScreen';
import NotificationScreen from '../screens/Notification/NotificationScreen';

// Phase 3: AI & Reviews Screens
import AiAssistantScreen from '../screens/AI/AiAssistantScreen';
import ReviewFormScreen from '../screens/Reviews/ReviewFormScreen';

// UI Showcase Screen & Lucian Notched Tab Bar (#041)
import UiCatalogScreen from '../screens/Dev/UiCatalogScreen';
import NotchedTabBar from '../components/lucian/NotchedTabBar';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

function MainTabs() {
  const { getCartTotals } = useCart();
  const { totalItems } = getCartTotals();

  return (
    <Tab.Navigator
      tabBar={(props) => <NotchedTabBar {...props} cartBadgeCount={totalItems} />}
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
        options={{ tabBarLabel: 'Hợp đồng' }}
      />
      <Tab.Screen
        name="ProfileTab"
        component={ProfileScreen}
        options={{ tabBarLabel: 'Doanh nghiệp' }}
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
    <NavigationContainer ref={navigationRef}>
      <Stack.Navigator
        initialRouteName="MainTabs"
        screenOptions={{ headerShown: false }}
      >
        <Stack.Screen name="MainTabs" component={MainTabs} />
        <Stack.Screen name="Login" component={LoginScreen} />
        <Stack.Screen name="Search" component={SearchScreen} />
        <Stack.Screen name="ProductDetail" component={ProductDetailScreen} />
        <Stack.Screen name="Checkout" component={CheckoutScreen} />

        {/* B2B Screens */}
        <Stack.Screen name="Notification" component={NotificationScreen} />
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
