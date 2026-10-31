import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from './src/context/AuthContext';
import { CartProvider } from './src/context/CartContext';
import { NotificationProvider } from './src/context/NotificationContext';
import AppNavigator from './src/navigation/AppNavigator';
import DevBar from './src/components/dev/DevBar';

export default function App() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <CartProvider>
          <NotificationProvider>
            <StatusBar style="light" />
            <AppNavigator />
            <DevBar />
          </NotificationProvider>
        </CartProvider>
      </AuthProvider>
    </SafeAreaProvider>
  );
}
