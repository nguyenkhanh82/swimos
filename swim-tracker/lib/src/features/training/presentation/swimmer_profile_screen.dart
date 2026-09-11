import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/swimmers_repository.dart';
import '../data/swim_times_sync_service.dart';
import '../utils/unit_converter.dart';

class SwimmerProfileScreen extends ConsumerStatefulWidget {
  final String? swimmerId;

  const SwimmerProfileScreen({super.key, this.swimmerId});

  @override
  ConsumerState<SwimmerProfileScreen> createState() => _SwimmerProfileScreenState();
}

class _SwimmerProfileScreenState extends ConsumerState<SwimmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _swimcloudIdController = TextEditingController();
  final _swimcloudPersonIdController = TextEditingController();
  final _swimUsaIdController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();
  String? _selectedGender;
  DateTime? _birthDate;
  String _unitPreference = 'metric';

  @override
  void initState() {
    super.initState();
    if (widget.swimmerId != null) {
      _loadSwimmer();
    }
  }

  Future<void> _loadSwimmer() async {
    final repository = ref.read(swimmersRepositoryProvider);
    final swimmer = await repository.getSwimmerById(widget.swimmerId!);
    if (swimmer != null && mounted) {
      setState(() {
        _fullNameController.text = swimmer.fullName ?? '';
        _swimcloudIdController.text = swimmer.swimcloudId;
        _swimcloudPersonIdController.text = swimmer.swimcloudPersonId ?? '';
        _swimUsaIdController.text = swimmer.swimUsaId ?? '';
        _selectedGender = swimmer.gender;
        _birthDate = swimmer.birthDate;
        _unitPreference = swimmer.unitPreference;
        _allergiesController.text = swimmer.allergies ?? '';
        
        // Load weight and height in user's preferred units
        if (swimmer.weightKg != null) {
          _weightController.text = UnitConverter.formatWeightInput(
            swimmer.weightKg,
            _unitPreference,
          );
        }
        if (swimmer.heightCm != null) {
          _heightController.text = UnitConverter.formatHeightInput(
            swimmer.heightCm,
            _unitPreference,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _swimcloudIdController.dispose();
    _swimcloudPersonIdController.dispose();
    _swimUsaIdController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _onUnitPreferenceChanged(String? newUnit) {
    if (newUnit == null || newUnit == _unitPreference) return;
    
    setState(() {
      // Convert weight
      if (_weightController.text.isNotEmpty) {
        final currentValue = double.tryParse(_weightController.text);
        if (currentValue != null) {
          // Convert from current unit to kg, then to new unit
          final kg = UnitConverter.convertWeightToKg(currentValue, _unitPreference);
          final newValue = UnitConverter.convertWeightFromKg(kg, newUnit);
          _weightController.text = newValue.toStringAsFixed(1);
        }
      }
      
      // Convert height
      if (_heightController.text.isNotEmpty) {
        final currentValue = double.tryParse(_heightController.text);
        if (currentValue != null) {
          // Convert from current unit to cm, then to new unit
          final cm = UnitConverter.convertHeightToCm(currentValue, _unitPreference);
          final newValue = UnitConverter.convertHeightFromCm(cm, newUnit);
          _heightController.text = newValue.toStringAsFixed(1);
        }
      }
      
      _unitPreference = newUnit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.swimmerId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Swimmer Profile' : 'Create Swimmer Profile',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Unit Preference
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Unit Preference',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'metric',
                                label: Text('Metric'),
                              ),
                              ButtonSegment(
                                value: 'imperial',
                                label: Text('Imperial'),
                              ),
                            ],
                            selected: {_unitPreference},
                            onSelectionChanged: (Set<String> newSelection) {
                              _onUnitPreferenceChanged(newSelection.first);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // SwimCloud ID
                      TextFormField(
                        controller: _swimcloudIdController,
                        decoration: InputDecoration(
                          labelText: 'SwimCloud ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'SwimCloud profile ID',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter SwimCloud ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // SwimCloud Person ID (optional)
                      TextFormField(
                        controller: _swimcloudPersonIdController,
                        decoration: InputDecoration(
                          labelText: 'SwimCloud Person ID (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Encoded person ID from USA Swimming API',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weight
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Weight (${_unitPreference == 'imperial' ? 'lbs' : 'kg'})',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: _unitPreference == 'imperial'
                              ? 'Enter weight in pounds'
                              : 'Enter weight in kilograms',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final numValue = double.tryParse(value);
                            if (numValue == null) {
                              return 'Please enter a valid number';
                            }
                            if (_unitPreference == 'imperial') {
                              if (numValue < 20 || numValue > 440) {
                                return 'Weight must be between 20 and 440 lbs';
                              }
                            } else {
                              if (numValue < 9 || numValue > 200) {
                                return 'Weight must be between 9 and 200 kg';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Height
                      TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          labelText: _unitPreference == 'imperial'
                              ? 'Height (inches)'
                              : 'Height (cm)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: _unitPreference == 'imperial'
                              ? 'Enter total inches (e.g., 68 for 5\'8") or feet.inches (e.g., 5.8)'
                              : 'Enter height in centimeters',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final parsed = UnitConverter.parseHeight(value, _unitPreference);
                            if (parsed == null) {
                              return 'Please enter a valid height';
                            }
                            if (_unitPreference == 'imperial') {
                              // Check reasonable range in inches (20-100 inches)
                              final inches = double.tryParse(value);
                              if (inches != null && (inches < 20 || inches > 100)) {
                                return 'Height must be between 20 and 100 inches';
                              }
                            } else {
                              // Check reasonable range in cm (50-250 cm)
                              if (parsed < 50 || parsed > 250) {
                                return 'Height must be between 50 and 250 cm';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Swim USA ID
                      TextFormField(
                        controller: _swimUsaIdController,
                        decoration: InputDecoration(
                          labelText: 'Swim USA ID (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'USA Swimming registration ID',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Allergies
                      TextFormField(
                        controller: _allergiesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Allergies (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Comma-separated list (e.g., peanuts, dairy, shellfish)',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Birth Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _birthDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _birthDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Birth Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _birthDate != null
                                ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
                                : 'Select birth date',
                            style: TextStyle(
                              color: _birthDate != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveSwimmer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF0EA5E9),
                ),
                child: Text(
                  isEditing ? 'Update Profile' : 'Create Profile',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _deleteSwimmer,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    'Delete Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSwimmer() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(swimmersRepositoryProvider);

    // Parse and convert weight/height to metric for storage
    double? weightKg;
    if (_weightController.text.isNotEmpty) {
      weightKg = UnitConverter.parseWeight(_weightController.text, _unitPreference);
    }

    double? heightCm;
    if (_heightController.text.isNotEmpty) {
      heightCm = UnitConverter.parseHeight(_heightController.text, _unitPreference);
    }

    // Trim allergies
    String? allergies;
    if (_allergiesController.text.trim().isNotEmpty) {
      allergies = _allergiesController.text.trim();
    }

    try {
      if (widget.swimmerId != null) {
        // Update existing
        final oldSwimmer = await repository.getSwimmerById(widget.swimmerId!);
        final oldSwimcloudId = oldSwimmer?.swimcloudId;
        
        await repository.updateSwimmer(
          widget.swimmerId!,
          fullName: _fullNameController.text,
          swimcloudId: _swimcloudIdController.text,
          swimcloudPersonId: _swimcloudPersonIdController.text.isEmpty
              ? null
              : _swimcloudPersonIdController.text,
          gender: _selectedGender,
          birthDate: _birthDate,
          weightKg: weightKg,
          heightCm: heightCm,
          swimUsaId: _swimUsaIdController.text.trim().isEmpty
              ? null
              : _swimUsaIdController.text.trim(),
          allergies: allergies,
          unitPreference: _unitPreference,
        );

        // Auto-fetch swim times if swimcloud_id was added or changed
        if (_swimcloudIdController.text.isNotEmpty && 
            _swimcloudIdController.text != oldSwimcloudId) {
          try {
            // Fetch times if swimcloud_id was added/changed (force refresh since it's new data)
            final syncService = ref.read(swimTimesSyncServiceProvider);
            await syncService.fetchSwimmerTimes(widget.swimmerId!, forceRefresh: true);
          } catch (e) {
            debugPrint('Error auto-fetching times: $e');
            // Don't show error to user, just log it
          }
        }
      } else {
        // Create new
        final newSwimmer = await repository.createSwimmer(
          swimcloudId: _swimcloudIdController.text,
          swimcloudPersonId: _swimcloudPersonIdController.text.isEmpty
              ? null
              : _swimcloudPersonIdController.text,
          fullName: _fullNameController.text,
          birthDate: _birthDate,
          gender: _selectedGender,
          isPrimary: false, // New swimmers are not primary by default
          weightKg: weightKg,
          heightCm: heightCm,
          swimUsaId: _swimUsaIdController.text.trim().isEmpty
              ? null
              : _swimUsaIdController.text.trim(),
          allergies: allergies,
          unitPreference: _unitPreference,
        );

        // Auto-fetch swim times if swimcloud_id is provided
        if (_swimcloudIdController.text.isNotEmpty) {
          try {
            // Fetch times for new swimmer with swimcloud_id (force refresh since it's new)
            final syncService = ref.read(swimTimesSyncServiceProvider);
            await syncService.fetchSwimmerTimes(newSwimmer.id, forceRefresh: true);
          } catch (e) {
            debugPrint('Error auto-fetching times: $e');
            // Don't show error to user, just log it
          }
        }
      }

      if (mounted) {
        ref.invalidate(swimmersListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.swimmerId != null
                ? 'Swimmer profile updated'
                : 'Swimmer profile created'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSwimmer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Swimmer Profile'),
        content: const Text(
          'Are you sure you want to delete this swimmer profile? All associated data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(swimmersRepositoryProvider);
        await repository.deleteSwimmer(widget.swimmerId!);
        ref.invalidate(swimmersListProvider);
        ref.invalidate(selectedSwimmerIdProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Swimmer profile deleted')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
