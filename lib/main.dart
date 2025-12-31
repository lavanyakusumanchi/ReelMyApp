import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/reel_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/chat_provider.dart'; 
import 'utils/api_config.dart';
import 'utils/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_root_screen.dart';
import 'providers/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadFromPrefs();
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => ReelProvider()),

        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
 
    return ScreenUtilInit(
      designSize: const Size(375, 812), 
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        
        final settings = Provider.of<SettingsProvider>(context);

        return MaterialApp(
          key: ValueKey(settings.locale.languageCode),
          debugShowCheckedModeBanner: false,
          title: 'ReelMyApp',
        
       
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          locale: settings.locale,
          supportedLocales: const [
             Locale('en'),
             Locale('te'),
          ],
          localizationsDelegates: const [
             AppLocalizationsDelegate(),
             GlobalMaterialLocalizations.delegate,
             GlobalWidgetsLocalizations.delegate,
             GlobalCupertinoLocalizations.delegate,
          ],

          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return (auth.isAuthenticated == true)
                  ? (auth.isAdmin ? const AdminRootScreen() : const HomeScreen())
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
