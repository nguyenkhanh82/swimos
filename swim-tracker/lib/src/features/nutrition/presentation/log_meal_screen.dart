import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/nutrition_repository.dart';
import '../../training/presentation/widgets/swimmer_selector_widget.dart';
import '../../training/data/swimmers_repository.dart';

class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key});

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  DateTime _selectedDate = DateTime.now();
  String _mealType = 'Lunch';
  final _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  String? _uploadedImageUrl;

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _analyzeAndLog() async {
    final swimmerId = ref.read(selectedSwimmerIdProvider).valueOrNull;
    if (swimmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a swimmer first.')),
      );
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please provide a description or a photo of your meal.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final repo = ref.read(nutritionRepositoryProvider);

      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // Analyze the meal using Edge Function & Groq
      final analysis = await repo.analyzeNutrition(
        description: desc.isNotEmpty ? desc : null,
        base64Image: base64Image,
      );

      // Upload image to Supabase Storage if present
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        _uploadedImageUrl = await repo.uploadFoodImage(swimmerId, bytes);
      }

      // Automatically Log the result
      await repo.addNutritionLog(
        swimmerId: swimmerId,
        logDate: _selectedDate,
        mealType: _mealType,
        description: desc,
        imageUrl: _uploadedImageUrl,
        calories: analysis['calories'] ?? 0,
        protein: analysis['protein'] ?? 0,
        carbs: analysis['carbs'] ?? 0,
        fat: analysis['fat'] ?? 0,
        sugar: analysis['sugar'] ?? 0,
      );

      // Invalidate dashboard provider so it pulls new data
      ref.invalidate(nutritionLogsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Meal logged successfully: ${analysis['calories']} calories!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error analyzing/logging meal: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF),
              onPrimary: Colors.black,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherited theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Log Meal',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001B33), Color(0xFF000B1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SwimmerSelectorWidget(compact: true),
                const SizedBox(height: 32),

                // Date & Meal Type Selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(_selectedDate),
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.calendar_today,
                                  color: Colors.white70, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _mealType,
                            dropdownColor: const Color(0xFF0F172A),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white70),
                            isExpanded: true,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _mealType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Photo Area
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF0F172A),
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              title: Text('Take a photo',
                                  style:
                                      GoogleFonts.outfit(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library,
                                  color: Colors.white),
                              title: Text('Choose from gallery',
                                  style:
                                      GoogleFonts.outfit(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selectedImage != null
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 2,
                      ),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(File(_selectedImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Snap a photo of your meal',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text('AI Vision Analysis Powered',
                                    style: GoogleFonts.outfit(
                                        color: const Color(0xFF00E5FF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              )
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Text Description Field
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    style:
                        GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Or describe what you ate...\n(e.g., "Two scrambled eggs, whole wheat toast, and a glass of milk")',
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.white30, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Action Button
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _analyzeAndLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                      shadowColor:
                          const Color(0xFF00E5FF).withValues(alpha: 0.5),
                    ),
                    child: _isAnalyzing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                              ),
                              const SizedBox(width: 16),
                              Text('AI Analyzing & Logging...',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Text('Analyze & Log Food',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
