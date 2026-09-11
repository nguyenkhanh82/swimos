import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/swim_times_repository.dart';
import '../domain/swim_time.dart';
import '../../training/domain/stroke.dart';
import '../../training/data/swimmers_repository.dart';

class AddSwimTimeScreen extends ConsumerStatefulWidget {
  final SwimTime? timeToEdit;

  const AddSwimTimeScreen({super.key, this.timeToEdit});

  @override
  ConsumerState<AddSwimTimeScreen> createState() => _AddSwimTimeScreenState();
}

class _AddSwimTimeScreenState extends ConsumerState<AddSwimTimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _meetNameController = TextEditingController();

  Stroke? _selectedStroke;
  int? _selectedDistance;
  String _selectedCourse = 'SCY';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Common swimming distances by stroke
  final Map<Stroke, List<int>> _distancesByStroke = {
    Stroke.free: [50, 100, 200, 500, 1000, 1650],
    Stroke.back: [50, 100, 200],
    Stroke.breast: [50, 100, 200],
    Stroke.fly: [50, 100, 200],
    Stroke.im: [100, 200, 400],
  };

  @override
  void initState() {
    super.initState();
    if (widget.timeToEdit != null) {
      _initializeFormWithTime(widget.timeToEdit!);
    }
  }

  void _initializeFormWithTime(SwimTime time) {
    _selectedStroke = time.stroke;
    _selectedDistance = time.distance;
    _selectedCourse = time.course;
    _selectedDate = time.date;
    _meetNameController.text = time.meetName ?? '';

    // Format time to MM:SS.CC
    _timeController.text = _formatTime(time.timeSeconds);
  }

  /// Format total seconds to MM:SS.CC or SS.CC format
  String _formatTime(double totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;

    if (minutes > 0) {
      // Format as MM:SS.CC
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      // Format as SS.CC
      return seconds.toStringAsFixed(2);
    }
  }

  /// Parse time from MM:SS.CC or SS.CC format to total seconds
  /// Returns null if parsing fails
  double? _parseTime(String timeStr) {
    final trimmed = timeStr.trim();
    if (trimmed.isEmpty) return null;

    // Check if it contains a colon (MM:SS.CC format)
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) return null;

      final minutes = int.tryParse(parts[0]);
      final seconds = double.tryParse(parts[1]);

      if (minutes == null || seconds == null) return null;
      if (minutes < 0 || seconds < 0 || seconds >= 60) return null;

      return (minutes * 60) + seconds;
    } else {
      // SS.CC format
      final seconds = double.tryParse(trimmed);
      if (seconds == null || seconds < 0) return null;
      return seconds;
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _meetNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get selected swimmer ID
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

      // Validate required fields
      if (_selectedStroke == null || _selectedDistance == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select stroke and distance')),
          );
        }
        return;
      }

      // Parse time input using MM:SS.CC or SS.CC format
      final totalSeconds = _parseTime(_timeController.text);

      if (totalSeconds == null || totalSeconds <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid time')),
          );
        }
        return;
      }

      final repository = ref.read(swimTimesRepositoryProvider);

      if (widget.timeToEdit != null) {
        // Update existing time
        await repository.updateSwimTime(
          id: widget.timeToEdit!.id,
          stroke: _selectedStroke,
          distance: _selectedDistance,
          timeSeconds: totalSeconds,
          date: _selectedDate,
          course: _selectedCourse,
          meetName: _meetNameController.text.isEmpty
              ? null
              : _meetNameController.text,
        );
      } else {
        // Add new time
        await repository.addSwimTime(
          swimmerId: selectedSwimmerId,
          stroke: _selectedStroke!,
          distance: _selectedDistance!,
          timeSeconds: totalSeconds,
          date: _selectedDate,
          course: _selectedCourse,
          meetName: _meetNameController.text.isEmpty
              ? null
              : _meetNameController.text,
        );
      }

      if (mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(swimTimesListProvider);
        ref.invalidate(recentSwimTimesProvider);
        ref.invalidate(personalBestsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.timeToEdit != null
                ? 'Time updated successfully'
                : 'Time added successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<int> _getAvailableDistances() {
    if (_selectedStroke == null) {
      return [50, 100, 200, 500, 1000, 1650];
    }
    return _distancesByStroke[_selectedStroke] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.timeToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Swim Time' : 'Add Swim Time',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Event Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stroke Selector - Searchable
                    Autocomplete<Stroke>(
                      initialValue: _selectedStroke != null
                          ? TextEditingValue(text: _selectedStroke!.value)
                          : const TextEditingValue(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return Stroke.values;
                        }
                        return Stroke.values.where((stroke) {
                          return stroke.value
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (Stroke stroke) => stroke.value,
                      onSelected: (Stroke stroke) {
                        setState(() {
                          _selectedStroke = stroke;
                          // Reset distance if it's not valid for the new stroke
                          if (_selectedDistance != null &&
                              !_getAvailableDistances()
                                  .contains(_selectedDistance)) {
                            _selectedDistance = null;
                          }
                        });
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Stroke',
                            border: const OutlineInputBorder(),
                            suffixIcon: _selectedStroke != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedStroke = null;
                                        _selectedDistance = null;
                                      });
                                      textEditingController.clear();
                                    },
                                  )
                                : const Icon(Icons.search),
                          ),
                          validator: (value) {
                            if (_selectedStroke == null) {
                              return 'Please select a stroke';
                            }
                            return null;
                          },
                          onTap: () {
                            if (textEditingController.text.isNotEmpty) {
                              textEditingController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: textEditingController.text.length,
                              );
                            }
                          },
                        );
                      },
                      optionsViewBuilder: (
                        BuildContext context,
                        AutocompleteOnSelected<Stroke> onSelected,
                        Iterable<Stroke> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Stroke option =
                                      options.elementAt(index);
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(option.value),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Distance Selector - Searchable
                    Autocomplete<int>(
                      initialValue: _selectedDistance != null
                          ? TextEditingValue(text: _selectedDistance.toString())
                          : const TextEditingValue(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final availableDistances = _getAvailableDistances();
                        if (textEditingValue.text.isEmpty) {
                          return availableDistances;
                        }
                        return availableDistances.where((distance) {
                          return distance
                              .toString()
                              .contains(textEditingValue.text);
                        });
                      },
                      displayStringForOption: (int distance) =>
                          distance.toString(),
                      onSelected: (int distance) {
                        setState(() {
                          _selectedDistance = distance;
                        });
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Distance (yards)',
                            border: const OutlineInputBorder(),
                            suffixIcon: _selectedDistance != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDistance = null;
                                      });
                                      textEditingController.clear();
                                    },
                                  )
                                : const Icon(Icons.search),
                            helperText: _selectedStroke == null
                                ? 'Select a stroke first'
                                : null,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_selectedDistance == null) {
                              return 'Please select a distance';
                            }
                            return null;
                          },
                          enabled: _selectedStroke != null,
                          onTap: () {
                            if (textEditingController.text.isNotEmpty) {
                              textEditingController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: textEditingController.text.length,
                              );
                            }
                          },
                        );
                      },
                      optionsViewBuilder: (
                        BuildContext context,
                        AutocompleteOnSelected<int> onSelected,
                        Iterable<int> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final int option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text('$option yards'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter time in MM:SS.CC format (e.g., 01:23.45 or 23.45)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        hintText: '01:23.45 or 23.45',
                        helperText: 'Format: MM:SS.CC or SS.CC',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a time';
                        }
                        final time = _parseTime(value);
                        if (time == null) {
                          return 'Invalid format. Use MM:SS.CC or SS.CC';
                        }
                        if (time <= 0) {
                          return 'Time must be greater than 0';
                        }
                        // Additional validation for reasonable swim times
                        if (time > 3600) {
                          return 'Time seems too long (> 1 hour)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pool Type Selector
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Pool Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'SCY',
                            child: Text('Short Course Yards (SCY)')),
                        DropdownMenuItem(
                            value: 'SCM',
                            child: Text('Short Course Meters (SCM)')),
                        DropdownMenuItem(
                            value: 'LCM',
                            child: Text('Long Course Meters (LCM)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCourse = value ?? 'SCY';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date Selector
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM d, yyyy')
                                .format(_selectedDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Meet Name (Optional)
                    TextFormField(
                      controller: _meetNameController,
                      decoration: const InputDecoration(
                        labelText: 'Meet Name (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., State Championships',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update Time' : 'Save Time',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
