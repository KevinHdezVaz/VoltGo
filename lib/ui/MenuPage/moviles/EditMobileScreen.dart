import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:Voltgo_app/data/models/vehicles/Vehicle.dart';
import 'package:Voltgo_app/data/services/vehicles_service.dart';
import 'package:Voltgo_app/ui/MenuPage/moviles/SuccessDialog.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';

class EditMobileScreen extends StatefulWidget {
  final String plate;

  const EditMobileScreen({Key? key, required this.plate}) : super(key: key);

  @override
  _EditMobileScreenState createState() => _EditMobileScreenState();
}

class _EditMobileScreenState extends State<EditMobileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<VehicleType> _vehicleTypes = [];
  int? _selectedVehicleTypeId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Duración de la animación
    );
    _fetchVehicleTypes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicleTypes() async {
    try {
      _animationController.repeat(); // Inicia la animación
      final types = await VehicleService.getVehicleTypes();
      if (mounted) {
        setState(() {
          _vehicleTypes = types;
          _isLoading = false;
        });
        _animationController.stop(); // Detiene la animación
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al cargar tipos: ${e.toString()}";
          _isLoading = false;
        });
        _animationController.stop(); // Detiene la animación en caso de error
      }
    }
  }

  Future<void> _handleSaveChanges() async {
    if (_selectedVehicleTypeId == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });
    _animationController.repeat(); // Inicia la animación al guardar

    try {
      final success = await VehicleService.setVehicleType(
        plate: widget.plate,
        type: _selectedVehicleTypeId!.toString(),
      );

      if (mounted) {
        _animationController.stop(); // Detiene la animación
        if (success) {
          showDialog(
            context: context,
            builder: (BuildContext context) => const SuccessDialog(),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudieron guardar los cambios.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop(); // Detiene la animación en caso de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _animationController.reset(); // Resetea la animación
      }
    }
  }

  String? get _selectedVehicleName {
    if (_selectedVehicleTypeId == null) return null;
    try {
      return _vehicleTypes
          .firstWhere((type) => type.id == _selectedVehicleTypeId)
          .name;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: _buildBackButton(context),
        title: const Text(
          'Editar móvil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBodyContent(),
                const Spacer(),
                _buildSaveChangesButton(),
              ],
            ),
          ),
          if (_isSaving)
            Center(
              child: AnimatedTruckProgress(
                animation: _animationController,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: Center(
          child: AnimatedTruckProgress(
            animation: _animationController,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildCustomDropdown();
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        'assets/images/backbtn.png',
        width: 40,
        height: 40,
      ),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildCustomDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<int>(
        isExpanded: true,
        customButton: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.image_outlined, size: 22, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de móvil:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedVehicleName ?? 'Selecciona un tipo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
            ],
          ),
        ),
        items: _vehicleTypes.map((type) {
          return DropdownMenuItem<int>(
            value: type.id,
            child: _buildDropdownItem(type.name),
          );
        }).toList(),
        value: _selectedVehicleTypeId,
        onChanged: (value) {
          setState(() {
            _selectedVehicleTypeId = value;
          });
        },
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String text) {
    return Row(
      children: [
        const Icon(Icons.image_outlined, size: 22, color: Colors.grey),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSaveChangesButton() {
    final bool isEnabled = _selectedVehicleTypeId != null && !_isSaving;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled ? _handleSaveChanges : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.disabled,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
          ),
          child: const Text(
            'Guardar cambios',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
