import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Importante
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wisetrack_app/firebase_options.dart';
import 'package:wisetrack_app/ui/MenuPage/notifications/NotificationDetailScreen.dart';
import 'package:wisetrack_app/ui/SplashScreen.dart';
import 'package:wisetrack_app/utils/AuthWrapper.dart';
import 'package:wisetrack_app/utils/NotificationCountService.dart';

// Importa tus pantallas
import 'package:wisetrack_app/ui/IntroPage/OnboardingWrapper.dart';
import 'package:wisetrack_app/ui/login/LoginScreen.dart';
import 'package:wisetrack_app/ui/MenuPage/DashboardScreen.dart';
import 'package:wisetrack_app/ui/MenuPage/dashboard/CombinedDashboardScreen.dart';
import 'package:wisetrack_app/ui/MenuPage/moviles/MobilesScreen.dart';
import 'package:wisetrack_app/ui/MenuPage/auditoria/AuditoriaScreen.dart';
import 'package:wisetrack_app/ui/MenuPage/notifications/NotificationsScreen.dart';
import 'package:wisetrack_app/ui/profile/SettingsScreen.dart';
// Importa la pantalla de detalle de notificación
 

// ✅ PASO 1: CREA LA CLAVE GLOBAL PARA EL NAVEGADOR
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ PASO 2: CREA LA FUNCIÓN MANEJADORA DE NOTIFICACIONES
/// Esta función debe ser global (fuera de cualquier clase)
void _handleMessage(RemoteMessage message) {
  // Extrae el ID de la notificación de la data payload
  final notificationId = message.data['notificationId'];

  if (notificationId != null) {
    print('Notificación recibida, navegando a detalle ID: $notificationId');
    try {
      // Usa la GlobalKey para navegar a la pantalla de detalle
      navigatorKey.currentState?.pushNamed(
        '/notification_detail',
        arguments: int.parse(notificationId), // Pasamos el ID convertido a entero
      );
    } catch (e) {
      print('Error al parsear el ID de la notificación o al navegar: $e');
    }
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ PASO 3: CONFIGURA LOS LISTENERS DE FIREBASE MESSAGING
  // 1. Para cuando la app está en segundo plano y se abre desde la notificación
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

  // 2. Para cuando la app está cerrada y se abre desde la notificación
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      _handleMessage(message);
    }
  });

  // (Opcional) Manejo de notificaciones en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notificación recibida en primer plano: ${message.notification?.title}');
    // Aquí podrías mostrar una notificación local si lo deseas
  });


  NotificationCountService.updateCount();

  HttpOverrides.global = MyHttpOverrides();
  initializeDateFormatting('es_ES', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ PASO 4: MODIFICA TU MATERIALAPP
    return MaterialApp(
      title: 'WiseTrack',
      debugShowCheckedModeBanner: false,
      // Asigna la GlobalKey aquí
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      // La pantalla inicial
      home: const SplashScreen(),
      // Reemplaza 'routes' con 'onGenerateRoute' para manejar argumentos
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/auth_wrapper':
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingWrapper());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/dashboard_combined':
            return MaterialPageRoute(builder: (_) => const CombinedDashboardScreen());
          case '/mobiles':
            return MaterialPageRoute(builder: (_) => MobilesScreen());
          case '/auditoria':
            return MaterialPageRoute(builder: (_) => AuditoriaScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());

          // ESTA ES LA NUEVA RUTA PARA EL DETALLE
          case '/notification_detail':
            // Extrae el argumento (el ID de la notificación)
            final int notificationId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => NotificationDetailScreen(notificationId: notificationId),
            );

          default:
            // Si la ruta no se encuentra, puedes mostrar una página de error o la splash
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}

// Clase para anular la verificación de certificados si la necesitas
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}