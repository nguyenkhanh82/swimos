import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../training/data/swimmers_repository.dart';
import '../domain/meet.dart';
import '../domain/meet_events.dart';
import '../data/meets_repository.dart';
import 'widgets/time_standards_bar_for_event.dart';

class MeetDetailsScreen extends ConsumerStatefulWidget {
  final SwimMeet meet;

  const MeetDetailsScreen({super.key, required this.meet});

  @override
  ConsumerState<MeetDetailsScreen> createState() => _MeetDetailsScreenState();
}

class _MeetDetailsScreenState extends ConsumerState<MeetDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddEntryDialog(meetId: widget.meet.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.meet.meetName, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: const Color(0xFF0EA5E9),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Meet Header Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(widget.meet.location ?? 'Unknown Location', style: GoogleFonts.outfit(color: Colors.grey)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat.yMMMd().format(widget.meet.startDate), style: GoogleFonts.outfit(color: Colors.grey)),
                  ],
                ),
                if (widget.meet.poolType != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(widget.meet.poolType!, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0EA5E9),
              tabs: const [
                Tab(text: 'My Events'),
                Tab(text: 'Heat Sheet'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Events Tab
                _MyEventsView(meetId: widget.meet.id),
                
                // Heat Sheet Tab
                _HeatSheetView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyEventsView extends ConsumerWidget {
  final String meetId;

  const _MyEventsView({required this.meetId});

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return '${secs.toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(meetEntriesProvider(meetId));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pool, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No events added yet.', style: GoogleFonts.outfit(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _EventCard(
              eventName: entry.eventName,
              time: entry.finalTimeSeconds != null 
                  ? _formatTime(entry.finalTimeSeconds!)
                  : entry.seedTimeSeconds != null
                      ? _formatTime(entry.seedTimeSeconds!)
                      : 'No Time',
              isPB: entry.isPersonalBest,
              ranking: entry.place != null ? '#${entry.place}' : '-',
              seedTime: entry.seedTimeSeconds?.toString(),
              finalTime: entry.finalTimeSeconds?.toString(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading events: $err')),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final String eventName;
  final String time;
  final bool isPB;
  final String ranking;
  final String? seedTime;
  final String? finalTime;

  const _EventCard({
    required this.eventName,
    required this.time,
    required this.isPB,
    required this.ranking,
    this.seedTime,
    this.finalTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSwimmerAsync = ref.watch(selectedSwimmerProvider);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(eventName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isPB)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('PB', style: GoogleFonts.outfit(color: Colors.amber[900], fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0EA5E9))),
              Text('Rank: $ranking', style: GoogleFonts.outfit(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          // Time Standards Bar
          selectedSwimmerAsync.when(
            data: (swimmer) {
              if (swimmer == null) return const SizedBox.shrink();
              final timeValue = finalTime != null 
                  ? double.tryParse(finalTime!)
                  : seedTime != null 
                      ? double.tryParse(seedTime!)
                      : null;
              if (timeValue == null) return const SizedBox.shrink();
              return TimeStandardsBarForEvent(
                eventName: eventName,
                swimmerTime: timeValue,
                swimmer: swimmer,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _HeatSheetView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Heat Sheet Coming Soon', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Heat sheet data will be available once API access is configured.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEntryDialog extends ConsumerStatefulWidget {
  final String meetId;
  const _AddEntryDialog({required this.meetId});

  @override
  ConsumerState<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends ConsumerState<_AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController(); // In seconds for simplicity, or formatted
  String? _selectedEventName; // Selected from all strokes + IM
  bool _isPB = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final events = MeetEvents.allEventNames;
    if (events.isNotEmpty) {
      _selectedEventName = events.first;
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEventName == null || _selectedEventName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get selected swimmer ID
      final selectedSwimmerId = await ref.read(selectedSwimmerIdProvider.future);
      if (selectedSwimmerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a swimmer profile first')),
          );
        }
        return;
      }

      final timeSeconds = double.tryParse(_timeController.text);

      await ref.read(meetsRepositoryProvider).addMeetEntry(
        swimmerId: selectedSwimmerId,
        entryData: {
          'meet_id': widget.meetId,
          'event_name': _selectedEventName!,
          'final_time_seconds': timeSeconds,
          'is_personal_best': _isPB,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(meetEntriesProvider(widget.meetId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Event', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedEventName,
              decoration: const InputDecoration(
                labelText: 'Event',
                alignLabelWithHint: true,
              ),
              isExpanded: true,
              items: MeetEvents.allEventNames.map((name) {
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
              onChanged: (value) => setState(() => _selectedEventName = value),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please select an event' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Time (seconds)', hintText: '24.50'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isPB,
                  onChanged: (val) => setState(() => _isPB = val ?? false),
                ),
                Text('Personal Best?', style: GoogleFonts.outfit()),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
