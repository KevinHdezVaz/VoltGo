import 'package:Voltgo_User/data/services/vehicles_service.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  final Function onVehicleAdded;
  const AddVehicleScreen({Key? key, required this.onVehicleAdded})
      : super(key: key);

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _connectorController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await VehicleService.addVehicle(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        connectorType: _connectorController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehículo registrado con éxito',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      widget.onVehicleAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al registrar el vehículo: $e',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _connectorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnLight,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: TextStyle(color: AppColors.textSecondary),
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIconColor: AppColors.primary,
          errorStyle: TextStyle(color: AppColors.error),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Registrar Vehículo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Registra tu vehículo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa los detalles para continuar',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _makeController,
                    label: 'Marca',
                    hint: 'Ej. Tesla',
                    icon: Icons.car_repair,
                    validator: (value) =>
                        value!.isEmpty ? 'Ingresa la marca' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _modelController,
                    label: 'Modelo',
                    hint: 'Ej. Model 3',
                    icon: Icons.directions_car,
                    validator: (value) =>
                        value!.isEmpty ? 'Ingresa el modelo' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _yearController,
                    label: 'Año',
                    hint: 'Ej. 2023',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Ingresa el año';
                      if (int.tryParse(value) == null ||
                          int.parse(value) < 1900 ||
                          int.parse(value) > DateTime.now().year) {
                        return 'Ingresa un año válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _connectorController,
                    label: 'Tipo de Conector',
                    hint: 'Ej. CCS2',
                    icon: Icons.ev_station,
                    validator: (value) =>
                        value!.isEmpty ? 'Ingresa el tipo de conector' : null,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: AnimatedOpacity(
                      opacity: _isLoading ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitVehicle,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textOnPrimary),
                                ),
                              )
                            : const Text(
                                'Guardar Vehículo',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
