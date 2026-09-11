import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/training_goals_repository.dart';
import '../data/teams_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/training_goal.dart';
import '../domain/stroke.dart';
import '../domain/goal_template.dart';
import '../../profile/data/profile_repository.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  final TrainingGoal? goalToEdit;
  final GoalTemplate? template;
  final VoidCallback? onSave;

  const CreateGoalScreen(
      {super.key, this.goalToEdit, this.template, this.onSave});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetTimeMinutesController = TextEditingController();
  final _targetTimeSecondsController = TextEditingController();
  final _targetDistanceController = TextEditingController();
  final _targetFrequencyController = TextEditingController();
  final _customTargetValueController = TextEditingController();
  final _customUnitController = TextEditingController();

  GoalType _selectedGoalType = GoalType.time;
  String? _selectedTeamId;
  Stroke? _selectedStroke;
  int? _selectedDistance;
  String? _selectedPoolType;
  String? _selectedDistancePeriod;
  String? _selectedFrequencyPeriod;
  DateTime? _selectedTargetDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _initializeFormWithGoal(widget.goalToEdit!);
    } else if (widget.template != null) {
      _initializeFormWithTemplate(widget.template!);
    } else {
      // Load default team from profile for new goals
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(defaultTeamIdProvider.future).then((defaultTeamId) {
          if (mounted && _selectedTeamId == null) {
            setState(() {
              _selectedTeamId = defaultTeamId;
            });
          }
        });
      });
    }
  }

  void _initializeFormWithGoal(TrainingGoal goal) {
    _titleController.text = goal.title;
    _descriptionController.text = goal.description ?? '';
    _selectedGoalType = goal.goalType;
    _selectedTeamId = goal.teamId;
    _selectedTargetDate = goal.targetDate;

    switch (goal.goalType) {
      case GoalType.time:
        if (goal.stroke != null) {
          _selectedStroke = Stroke.values.firstWhere(
            (s) => s.value == goal.stroke,
            orElse: () => Stroke.free,
          );
        }
        _selectedDistance = goal.distance;
        _selectedPoolType = goal.poolType;
        if (goal.targetTimeSeconds != null) {
          final minutes = (goal.targetTimeSeconds! / 60).floor();
          final seconds = goal.targetTimeSeconds! % 60;
          _targetTimeMinutesController.text = minutes.toString();
          _targetTimeSecondsController.text = seconds.toStringAsFixed(2);
        }
        break;
      case GoalType.distance:
        _targetDistanceController.text = goal.targetDistance?.toString() ?? '';
        _selectedDistancePeriod = goal.distancePeriod;
        break;
      case GoalType.frequency:
        _targetFrequencyController.text =
            goal.targetFrequency?.toString() ?? '';
        _selectedFrequencyPeriod = goal.frequencyPeriod;
        break;
      case GoalType.custom:
        _customTargetValueController.text =
            goal.customTargetValue?.toString() ?? '';
        _customUnitController.text = goal.customUnit ?? '';
        break;
    }
  }

  void _initializeFormWithTemplate(GoalTemplate template) {
    _titleController.text = template.name;
    _descriptionController.text = template.description;
    _selectedGoalType = template.goalType;

    final defaults = template.defaultValues;

    switch (template.goalType) {
      case GoalType.time:
        if (defaults['stroke'] != null) {
          _selectedStroke = Stroke.values.firstWhere(
            (s) => s.value == defaults['stroke'],
            orElse: () => Stroke.free,
          );
        }
        _selectedDistance = defaults['distance'] as int?;
        _selectedPoolType = defaults['pool_type'] as String?;
        break;
      case GoalType.distance:
        _targetDistanceController.text =
            defaults['target_distance']?.toString() ?? '';
        _selectedDistancePeriod = defaults['distance_period'] as String?;
        break;
      case GoalType.frequency:
        _targetFrequencyController.text =
            defaults['target_frequency']?.toString() ?? '';
        _selectedFrequencyPeriod = defaults['frequency_period'] as String?;
        break;
      case GoalType.custom:
        _customTargetValueController.text =
            defaults['custom_target_value']?.toString() ?? '';
        _customUnitController.text = defaults['custom_unit']?.toString() ?? '';
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetTimeMinutesController.dispose();
    _targetTimeSecondsController.dispose();
    _targetDistanceController.dispose();
    _targetFrequencyController.dispose();
    _customTargetValueController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get selected swimmer ID first
      final selectedSwimmerId =
          await ref.read(selectedSwimmerIdProvider.future);
      if (selectedSwimmerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select a swimmer profile first')),
          );
        }
        return;
      }

      final repository = ref.read(trainingGoalsRepositoryProvider);
      final now = DateTime.now();
      final isEditing = widget.goalToEdit != null;

      TrainingGoal goal;

      switch (_selectedGoalType) {
        case GoalType.time:
          // Parse time input
          final minutes = int.tryParse(_targetTimeMinutesController.text) ?? 0;
          final seconds =
              double.tryParse(_targetTimeSecondsController.text) ?? 0;
          final targetTimeSeconds = (minutes * 60) + seconds;

          if (_selectedStroke == null || _selectedDistance == null) {
            throw Exception('Please select stroke and distance');
          }

          goal = TrainingGoal(
            id: isEditing ? widget.goalToEdit!.id : '',
            userId: isEditing ? widget.goalToEdit!.userId : '',
            swimmerId:
                isEditing ? widget.goalToEdit!.swimmerId : selectedSwimmerId,
            teamId: _selectedTeamId == 'personal' ? null : _selectedTeamId,
            goalType: GoalType.time,
            title: _titleController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            stroke: _selectedStroke!.value,
            distance: _selectedDistance,
            poolType: _selectedPoolType,
            targetTimeSeconds: targetTimeSeconds,
            targetDate: _selectedTargetDate,
            status: isEditing ? widget.goalToEdit!.status : GoalStatus.active,
            isActive: isEditing ? widget.goalToEdit!.isActive : true,
            createdAt: isEditing ? widget.goalToEdit!.createdAt : now,
            updatedAt: now,
          );
          break;

        case GoalType.distance:
          final targetDistance = int.tryParse(_targetDistanceController.text);
          if (targetDistance == null || _selectedDistancePeriod == null) {
            throw Exception('Please enter target distance and period');
          }

          goal = TrainingGoal(
            id: isEditing ? widget.goalToEdit!.id : '',
            userId: isEditing ? widget.goalToEdit!.userId : '',
            swimmerId:
                isEditing ? widget.goalToEdit!.swimmerId : selectedSwimmerId,
            teamId: _selectedTeamId == 'personal' ? null : _selectedTeamId,
            goalType: GoalType.distance,
            title: _titleController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            targetDistance: targetDistance,
            distancePeriod: _selectedDistancePeriod,
            targetDate: _selectedTargetDate,
            status: isEditing ? widget.goalToEdit!.status : GoalStatus.active,
            isActive: isEditing ? widget.goalToEdit!.isActive : true,
            createdAt: isEditing ? widget.goalToEdit!.createdAt : now,
            updatedAt: now,
          );
          break;

        case GoalType.frequency:
          final targetFrequency = int.tryParse(_targetFrequencyController.text);
          if (targetFrequency == null || _selectedFrequencyPeriod == null) {
            throw Exception('Please enter target frequency and period');
          }

          goal = TrainingGoal(
            id: isEditing ? widget.goalToEdit!.id : '',
            userId: isEditing ? widget.goalToEdit!.userId : '',
            swimmerId:
                isEditing ? widget.goalToEdit!.swimmerId : selectedSwimmerId,
            teamId: _selectedTeamId == 'personal' ? null : _selectedTeamId,
            goalType: GoalType.frequency,
            title: _titleController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            targetFrequency: targetFrequency,
            frequencyPeriod: _selectedFrequencyPeriod,
            targetDate: _selectedTargetDate,
            status: isEditing ? widget.goalToEdit!.status : GoalStatus.active,
            isActive: isEditing ? widget.goalToEdit!.isActive : true,
            createdAt: isEditing ? widget.goalToEdit!.createdAt : now,
            updatedAt: now,
          );
          break;

        case GoalType.custom:
          final customTargetValue =
              double.tryParse(_customTargetValueController.text);
          if (customTargetValue == null) {
            throw Exception('Please enter target value');
          }

          goal = TrainingGoal(
            id: isEditing ? widget.goalToEdit!.id : '',
            userId: isEditing ? widget.goalToEdit!.userId : '',
            teamId: _selectedTeamId == 'personal' ? null : _selectedTeamId,
            goalType: GoalType.custom,
            title: _titleController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            customTargetValue: customTargetValue,
            customUnit: _customUnitController.text.isEmpty
                ? null
                : _customUnitController.text,
            targetDate: _selectedTargetDate,
            status: isEditing ? widget.goalToEdit!.status : GoalStatus.active,
            isActive: isEditing ? widget.goalToEdit!.isActive : true,
            createdAt: isEditing ? widget.goalToEdit!.createdAt : now,
            updatedAt: now,
          );
          break;
      }

      TrainingGoal savedGoal;
      if (isEditing) {
        await repository.updateGoal(goal);
        savedGoal = goal;
      } else {
        savedGoal =
            await repository.createGoal(goal, swimmerId: selectedSwimmerId);
      }

      if (mounted) {
        ref.invalidate(goalsListProvider);
        ref.invalidate(activeGoalsProvider);
        if (widget.onSave != null) {
          widget.onSave!();
        } else {
          // Navigate to AI Generator if it is a time goal, otherwise pop
          if (savedGoal.goalType == GoalType.time) {
            context.pushReplacement('/training/goals/${savedGoal.id}/practice',
                extra: {'swimmerId': selectedSwimmerId});
          } else {
            context.pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedTargetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedTargetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Goal', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Goal Type Selector
              Text(
                'Goal Type',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<GoalType>(
                segments: GoalType.values.map((type) {
                  return ButtonSegment<GoalType>(
                    value: type,
                    label: Text(type.value.toUpperCase()),
                  );
                }).toList(),
                selected: {_selectedGoalType},
                onSelectionChanged: (Set<GoalType> newSelection) {
                  setState(() => _selectedGoalType = newSelection.first);
                },
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Team Selector
              teamsAsync.when(
                data: (teams) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedTeamId,
                    decoration: InputDecoration(
                      labelText: 'Team (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: 'personal',
                        child: Text('Personal Goal'),
                      ),
                      ...teams.map((team) => DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTeamId = value);
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Dynamic Fields Based on Goal Type
              _buildGoalTypeFields(),

              const SizedBox(height: 24),

              // Target Date (Optional)
              InkWell(
                onTap: _selectTargetDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Target Date (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedTargetDate != null
                        ? DateFormat('MMM dd, yyyy')
                            .format(_selectedTargetDate!)
                        : 'Select target date',
                    style: GoogleFonts.outfit(
                      color: _selectedTargetDate != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Create Goal',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTypeFields() {
    switch (_selectedGoalType) {
      case GoalType.time:
        return _buildTimeGoalFields();
      case GoalType.distance:
        return _buildDistanceGoalFields();
      case GoalType.frequency:
        return _buildFrequencyGoalFields();
      case GoalType.custom:
        return _buildCustomGoalFields();
    }
  }

  Widget _buildTimeGoalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stroke
        DropdownButtonFormField<Stroke>(
          initialValue: _selectedStroke,
          decoration: InputDecoration(
            labelText: 'Stroke',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: Stroke.values.map((stroke) {
            return DropdownMenuItem(
              value: stroke,
              child: Text(stroke.value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedStroke = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a stroke';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Distance
        DropdownButtonFormField<int>(
          initialValue: _selectedDistance,
          decoration: InputDecoration(
            labelText: 'Distance',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: [50, 100, 200, 400, 800, 1500].map((distance) {
            return DropdownMenuItem(
              value: distance,
              child: Text('${distance}m'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedDistance = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a distance';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Pool Type
        DropdownButtonFormField<String>(
          initialValue: _selectedPoolType,
          decoration: InputDecoration(
            labelText: 'Pool Type (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: ['SCY', 'SCM', 'LCM'].map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPoolType = value);
          },
        ),
        const SizedBox(height: 16),

        // Target Time
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _targetTimeMinutesController,
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _targetTimeSecondsController,
                decoration: InputDecoration(
                  labelText: 'Seconds',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final seconds = double.tryParse(value);
                  if (seconds == null || seconds < 0 || seconds >= 60) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceGoalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _targetDistanceController,
          decoration: InputDecoration(
            labelText: 'Target Distance (meters)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter target distance';
            }
            final distance = int.tryParse(value);
            if (distance == null || distance <= 0) {
              return 'Please enter a valid distance';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedDistancePeriod,
          decoration: InputDecoration(
            labelText: 'Period',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: ['daily', 'weekly', 'monthly'].map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(period.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedDistancePeriod = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a period';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyGoalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _targetFrequencyController,
          decoration: InputDecoration(
            labelText: 'Target Sessions',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter target frequency';
            }
            final frequency = int.tryParse(value);
            if (frequency == null || frequency <= 0) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedFrequencyPeriod,
          decoration: InputDecoration(
            labelText: 'Period',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: ['weekly', 'monthly'].map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(period.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedFrequencyPeriod = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a period';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCustomGoalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _customTargetValueController,
          decoration: InputDecoration(
            labelText: 'Target Value',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter target value';
            }
            final val = double.tryParse(value);
            if (val == null || val <= 0) {
              return 'Please enter a valid value';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _customUnitController,
          decoration: InputDecoration(
            labelText: 'Unit (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'e.g., kg, lbs, reps',
          ),
        ),
      ],
    );
  }
}
