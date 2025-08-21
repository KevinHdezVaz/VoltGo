import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      // ▼▼▼ CAMBIO PRINCIPAL: LLAMAMOS A LA API EN LUGAR DEL CACHÉ ▼▼▼
      final UserModel? user = await AuthService.fetchUserProfile();

      if (!mounted) return;

      if (user != null) {
        if (user.hasRegisteredVehicle) {
          // Si tiene sesión Y vehículo, va a la pantalla principal
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavBar()),
          );
        } else {
          // Si tiene sesión pero NO tiene vehículo, lo forzamos a registrarlo
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AddVehicleScreen(
                onVehicleAdded: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BottomNavBar()),
                  );
                },
              ),
            ),
          );
        }
      } else {
        // Si no se pudo obtener el usuario (ej. token inválido), limpiamos y vamos al login
        await AuthService.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Si NO hay sesión, va al Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
