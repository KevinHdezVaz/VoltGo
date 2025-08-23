import 'package:Voltgo_User/data/services/vehicles_service.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddVehicleScreen extends StatefulWidget {
  final Function onVehicleAdded;
  const AddVehicleScreen({Key? key, required this.onVehicleAdded})
      : super(key: key);

  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  int _currentStep = 0;

  // Controladores para los campos del formulario
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _connectorTypeController = TextEditingController();

  // Listas para los dropdowns y selecciones
  final List<String> _connectorTypes = [
    'Type 1 (J1772)',
    'Type 2 (Mennekes)',
    'CCS Combo 1',
    'CCS Combo 2',
    'CHAdeMO',
    'Tesla Supercharger',
    'GB/T',
  ];

  // ✅ Se agregó la opción 'Otro'
  final List<Map<String, dynamic>> _popularBrands = [
    {'name': 'Tesla', 'icon': '⚡'},
    {'name': 'Nissan', 'icon': '🚗'},
    {'name': 'Chevrolet', 'icon': '🚙'},
    {'name': 'BMW', 'icon': '🏎️'},
    {'name': 'Volkswagen', 'icon': '🚐'},
    {'name': 'Audi', 'icon': '🚘'},
    {'name': 'Ford', 'icon': '🛻'},
    {'name': 'Hyundai', 'icon': '🚕'},
    {'name': 'Otro', 'icon': '➕'},
  ];

  // ✅ Se agregó la opción 'Otro' con un ícono para diferenciarla
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Blanco', 'color': Colors.white},
    {'name': 'Negro', 'color': Colors.black},
    {'name': 'Gris', 'color': Colors.grey},
    {'name': 'Plata', 'color': Colors.grey.shade300},
    {'name': 'Rojo', 'color': Colors.red},
    {'name': 'Azul', 'color': Colors.blue},
    {'name': 'Verde', 'color': Colors.green},
    {'name': 'Otro', 'color': null, 'icon': Icons.add},
  ];

  String? _selectedBrand;
  String? _selectedConnectorType;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _connectorTypeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validar el formulario antes de avanzar
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitVehicle();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ Lógica de validación actualizada para 'Otro'
  bool _validateCurrentStep() {
    // La validación del Form ahora maneja los campos de texto.
    // Aquí solo validamos las selecciones que no son campos de texto.
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        final isColorSelected = _selectedColor != null;
        return isColorSelected && (_formKey.currentState?.validate() ?? false);
      case 2:
        return _selectedConnectorType != null;
      default:
        return false;
    }
  }

  // ✅ Lógica de envío actualizada
  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      final String finalColor = (_selectedColor == 'Otro')
          ? _colorController.text.trim()
          : _selectedColor!;

      await VehicleService.addVehicle(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        plate: _plateController.text.trim(), // Añadido
        color: finalColor, // Añadido
        connectorType: _connectorTypeController.text.trim(),
      );

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al registrar el vehículo: $e',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ El diálogo ahora llama a onVehicleAdded para la navegación
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Vehículo Registrado!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu vehículo ha sido registrado exitosamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                    widget.onVehicleAdded(); // Llama al callback para navegar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.electric_car,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Registra tu Vehículo Eléctrico',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paso ${_currentStep + 1} de 3',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información del Vehículo'),
          const SizedBox(height: 24),
          const Text('Marca'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularBrands.map((brand) {
              final isSelected = _selectedBrand == brand['name'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(brand['icon']),
                    const SizedBox(width: 4),
                    Text(brand['name']),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBrand = brand['name'];
                      if (_selectedBrand == 'Otro') {
                        _makeController.clear();
                      } else {
                        _makeController.text = _selectedBrand!;
                      }
                    }
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _makeController,
            enabled: _selectedBrand == 'Otro' || _selectedBrand == null,
            decoration: InputDecoration(
              hintText: 'Escribe una marca si no está en la lista',
              filled: true,
              fillColor: (_selectedBrand != 'Otro' && _selectedBrand != null)
                  ? AppColors.gray300.withOpacity(0.3)
                  : AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, selecciona o ingresa una marca';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _modelController,
            label: 'Modelo',
            hint: 'Ej: Model 3, Leaf, ID.4',
            icon: Icons.car_rental,
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _yearController,
            label: 'Año',
            hint: DateTime.now().year.toString(),
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identificación'),
          const SizedBox(height: 24),
          _buildEnhancedTextField(
            controller: _plateController,
            label: 'Placa',
            hint: 'ABC-123',
            icon: Icons.pin,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          const Text('Color'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final colorData = _colors[index];
              final isSelected = _selectedColor == colorData['name'];

              // Caso especial para el botón 'Otro'
              if (colorData['name'] == 'Otro') {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorData['name'];
                      _colorController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.gray300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(colorData['icon'],
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(height: 4),
                        Text('Otro',
                            style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }

              // Botones de colores normales
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = colorData['name'];
                    _colorController.text = colorData['name'];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorData['color'],
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gray300),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(colorData['name'],
                          style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            },
          ),
          // Campo de texto condicional para 'Otro' color
          if (_selectedColor == 'Otro') ...[
            const SizedBox(height: 16),
            _buildEnhancedTextField(
              controller: _colorController,
              label: 'Especifica el color',
              hint: 'Ej: Dorado, Morado',
              icon: Icons.color_lens_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un color';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Especificaciones Técnicas'),
          const SizedBox(height: 24),
          const Text('Tipo de Conector'),
          const SizedBox(height: 12),
          ...(_connectorTypes.map((type) {
            final isSelected = _selectedConnectorType == type;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedConnectorType = type;
                    _connectorTypeController.text = type;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electrical_services),
                      const SizedBox(width: 12),
                      Expanded(child: Text(type)),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
          ),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                if (label == 'Año') {
                  final year = int.tryParse(value);
                  if (year == null || year > DateTime.now().year + 1) {
                    return 'Ingresa un año válido';
                  }
                }
                return null;
              },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.gray300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Anterior'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed:
                  _isLoading || !_validateCurrentStep() ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                // ✅ CAMBIO AQUÍ: Se cambió de AppColors.primary a AppColors.brandBlue
                backgroundColor: AppColors.brandBlue,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep < 2 ? 'Siguiente' : 'Registrar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep < 2 ? Icons.arrow_forward : Icons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
