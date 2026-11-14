import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: NguyetPhoApp(),
    ),
  );
}

class NguyetPhoApp extends ConsumerWidget {
  const NguyetPhoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nguyệt Phố B2B',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
