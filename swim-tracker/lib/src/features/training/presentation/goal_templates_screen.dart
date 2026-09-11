import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/goal_template.dart';
import '../domain/training_goal.dart';
import 'create_goal_screen.dart';

class GoalTemplatesScreen extends ConsumerStatefulWidget {
  const GoalTemplatesScreen({super.key});

  @override
  ConsumerState<GoalTemplatesScreen> createState() => _GoalTemplatesScreenState();
}

class _GoalTemplatesScreenState extends ConsumerState<GoalTemplatesScreen> {
  GoalType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final templates = _selectedType == null
        ? GoalTemplates.getAllTemplates()
        : GoalTemplates.getTemplatesByType(_selectedType!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Goal Templates', style: GoogleFonts.spaceGrotesk()),
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          Expanded(
            child: templates.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _buildTemplateCard(template);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null),
            const SizedBox(width: 8),
            _buildFilterChip('Time', GoalType.time),
            const SizedBox(width: 8),
            _buildFilterChip('Distance', GoalType.distance),
            const SizedBox(width: 8),
            _buildFilterChip('Frequency', GoalType.frequency),
            const SizedBox(width: 8),
            _buildFilterChip('Custom', GoalType.custom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, GoalType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF0EA5E9),
      labelStyle: GoogleFonts.outfit(
        color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTemplateCard(GoalTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getTypeColor(template.goalType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTemplateIcon(template),
                  color: _getTypeColor(template.goalType),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(template.goalType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            template.goalType.value.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(template.goalType),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            template.category,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Templates Found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _useTemplate(GoalTemplate template) {
    // Navigate to create goal screen with template pre-filled
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateGoalScreen(
          template: template,
        ),
      ),
    );
  }

  IconData _getTemplateIcon(GoalTemplate template) {
    switch (template.iconName) {
      case 'sprint':
        return Icons.flash_on;
      case 'distance':
        return Icons.timeline;
      case 'backstroke':
      case 'breaststroke':
      case 'butterfly':
      case 'im':
        return Icons.pool;
      case 'calendar':
        return Icons.calendar_today;
      case 'pool':
        return Icons.waves;
      case 'fitness':
        return Icons.fitness_center;
      case 'stretch':
        return Icons.self_improvement;
      default:
        return Icons.flag;
    }
  }

  Color _getTypeColor(GoalType type) {
    switch (type) {
      case GoalType.time:
        return const Color(0xFF0EA5E9);
      case GoalType.distance:
        return const Color(0xFF8B5CF6);
      case GoalType.frequency:
        return const Color(0xFFF59E0B);
      case GoalType.custom:
        return const Color(0xFF10B981);
    }
  }
}
