import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

enum DialogType { success, warning, error }

Future<void> showCustomDialog({
  required BuildContext context,
  required DialogType type,
  required Widget title, // Cambiado a Widget
  required Widget subtitle,
  required List<Widget> actions,
}) {
  String imagePath;
  switch (type) {
    case DialogType.success:
      imagePath = 'assets/images/saved_success.png';
      break;
    case DialogType.warning:
      imagePath = 'assets/images/caution_img.png';
      break;
    case DialogType.error:
      imagePath = 'assets/images/img_error.png';
      break;
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(imagePath, height: 120),
              const SizedBox(height: 24),
              title,
              const SizedBox(height: 8),
              subtitle,
              const SizedBox(height: 24),
              ...actions,
            ],
          ),
        ),
      );
    },
  );
}

void showWarningDialog(BuildContext context,
    {required String title,
    required String subtitle,
    required VoidCallback onConfirm}) {
  showCustomDialog(
    context: context,
    type: DialogType.warning,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 25, // Tamaño personalizado
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black)),
    actions: [
      Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      10), // Esquinas completamente cuadradas
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      10), // Esquinas completamente cuadradas
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

void showSuccessDialog(BuildContext context,
    {required String title, required String subtitle}) {
  showCustomDialog(
    context: context,
    type: DialogType.success,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black)),
    actions: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10), // Esquinas redondeadas 10
            ),
          ),
          child: const Text('Salir', style: TextStyle(color: Colors.white)),
        ),
      ),
    ],
  );
}

void showErrorDialog(BuildContext context) {
  showCustomDialog(
    context: context,
    type: DialogType.error,
    title: Text(
      "Ha ocurrido un error.",
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
        children: const [
          TextSpan(text: 'Favor comunícate al '),
          TextSpan(
            text: '80090022',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' o a '),
          TextSpan(
            text: 'sac@Voltgo.cl',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
    actions: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10), // Esquinas redondeadas 10
            ),
          ),
          child: const Text('Salir', style: TextStyle(color: Colors.white)),
        ),
      ),
    ],
  );
}
