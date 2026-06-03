// Point d'entrée de l'application — Configuration des providers et du routage

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/budget_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/notification_controller.dart';

// Views
import 'views/splash/splash_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/home/home_view.dart';
import 'views/transactions/transaction_form_view.dart';

// Utils
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser les notifications locales
  await NotificationService().init();

  // Style de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..init()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TransactionController()),
        ChangeNotifierProvider(create: (_) => BudgetController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Thèmes
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeCtrl.themeMode,

            // Localisation (requis pour les widgets Material en français)
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('fr', 'FR'),

            // Route initiale
            initialRoute: AppConstants.routeSplash,

            // Définition de toutes les routes
            routes: {
              AppConstants.routeSplash: (_) => const SplashView(),
              AppConstants.routeLogin: (_) => const LoginView(),
              AppConstants.routeRegister: (_) => const RegisterView(),
              AppConstants.routeHome: (_) => const HomeView(),
              AppConstants.routeAddTransaction: (_) =>
                  const TransactionFormView(),
              AppConstants.routeEditTransaction: (_) =>
                  const TransactionFormView(),
            },
          );
        },
      ),
    );
  }
}