import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrainingFilters extends StatefulWidget {
  final String? selectedTeamId;
  final String? selectedStroke;
  final int? selectedDistance;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, String?, int?, DateTime?, DateTime?) onFiltersChanged;

  const TrainingFilters({
    super.key,
    this.selectedTeamId,
    this.selectedStroke,
    this.selectedDistance,
    this.startDate,
    this.endDate,
    required this.onFiltersChanged,
  });

  @override
  State<TrainingFilters> createState() => _TrainingFiltersState();
}

class _TrainingFiltersState extends State<TrainingFilters> {
  String? _teamId;
  String? _stroke;
  int? _distance;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _teamId = widget.selectedTeamId;
    _stroke = widget.selectedStroke;
    _distance = widget.selectedDistance;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  void _applyFilters() {
    widget.onFiltersChanged(_teamId, _stroke, _distance, _startDate, _endDate);
  }

  void _clearFilters() {
    setState(() {
      _teamId = null;
      _stroke = null;
      _distance = null;
      _startDate = null;
      _endDate = null;
    });
    widget.onFiltersChanged(null, null, null, null, null);
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _teamId != null ||
        _stroke != null ||
        _distance != null ||
        _startDate != null ||
        _endDate != null;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Stroke Filter
                      _buildFilterChip(
                        label: 'Stroke',
                        value: _stroke,
                        options: ['Free', 'Back', 'Breast', 'Fly', 'IM'],
                        onSelected: (value) {
                          setState(() {
                            _stroke = value == _stroke ? null : value;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),

                      // Distance Filter
                      _buildDistanceFilter(),
                      const SizedBox(width: 8),

                      // Date Range Filter
                      _buildDateRangeChip(),
                    ],
                  ),
                ),
              ),
              if (hasFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0EA5E9),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text(
            'All',
            style: GoogleFonts.outfit(
              fontWeight: value == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        ...options.map((option) => PopupMenuItem(
              value: option,
              child: Text(
                option,
                style: GoogleFonts.outfit(
                  fontWeight:
                      value == option ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )),
      ],
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value != null
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null
                ? const Color(0xFF0EA5E9)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                color: value != null ? const Color(0xFF0EA5E9) : Colors.white70,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: value != null ? const Color(0xFF0EA5E9) : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceFilter() {
    final distances = [50, 100, 200, 400, 800, 1500];

    return PopupMenuButton<int>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _distance != null
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _distance != null
                ? const Color(0xFF0EA5E9)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _distance != null ? '${_distance}m' : 'Distance',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight:
                    _distance != null ? FontWeight.bold : FontWeight.normal,
                color: _distance != null
                    ? const Color(0xFF0EA5E9)
                    : Colors.white70,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color:
                  _distance != null ? const Color(0xFF0EA5E9) : Colors.white70,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text(
            'All',
            style: GoogleFonts.outfit(
              fontWeight:
                  _distance == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        ...distances.map((dist) => PopupMenuItem(
              value: dist,
              child: Text(
                '${dist}m',
                style: GoogleFonts.outfit(
                  fontWeight:
                      _distance == dist ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )),
      ],
      onSelected: (value) {
        setState(() {
          _distance = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildDateRangeChip() {
    final hasDateRange = _startDate != null || _endDate != null;

    return GestureDetector(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
        );

        if (range != null) {
          setState(() {
            _startDate = range.start;
            _endDate = range.end;
            _applyFilters();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasDateRange
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDateRange
                ? const Color(0xFF0EA5E9)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: hasDateRange ? const Color(0xFF0EA5E9) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              hasDateRange ? 'Date Range' : 'Date',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: hasDateRange ? FontWeight.bold : FontWeight.normal,
                color: hasDateRange ? const Color(0xFF0EA5E9) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
