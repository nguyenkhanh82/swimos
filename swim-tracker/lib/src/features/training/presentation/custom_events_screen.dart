import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/custom_events_repository.dart';
import '../data/swimmers_repository.dart';
import '../domain/custom_tracked_event.dart';
import '../domain/stroke.dart';

class CustomEventsScreen extends ConsumerStatefulWidget {
  final String? teamId;

  const CustomEventsScreen({super.key, this.teamId});

  @override
  ConsumerState<CustomEventsScreen> createState() => _CustomEventsScreenState();
}

class _CustomEventsScreenState extends ConsumerState<CustomEventsScreen> {
  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(customEventsProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Events', style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No custom events',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _CustomEventCard(event: event);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        backgroundColor: const Color(0xFF0EA5E9),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateCustomEventDialog(teamId: widget.teamId),
    );
  }
}

class _CustomEventCard extends ConsumerWidget {
  final CustomTrackedEvent event;

  const _CustomEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (event.stroke != null || event.distance != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (event.distance != null) '${event.distance}m',
                      if (event.stroke != null) event.stroke!.value,
                    ].join(' '),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await ref.read(customEventsRepositoryProvider).deleteCustomEvent(event.id);
              ref.invalidate(customEventsProvider(event.teamId));
            },
          ),
        ],
      ),
    );
  }
}

class _CreateCustomEventDialog extends ConsumerStatefulWidget {
  final String? teamId;

  const _CreateCustomEventDialog({required this.teamId});

  @override
  ConsumerState<_CreateCustomEventDialog> createState() => _CreateCustomEventDialogState();
}

class _CreateCustomEventDialogState extends ConsumerState<_CreateCustomEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  String? _selectedStroke;
  int? _selectedDistance;
  bool _isLoading = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

      await ref.read(customEventsRepositoryProvider).createCustomEvent(
        swimmerId: selectedSwimmerId,
        eventName: _eventNameController.text.trim(),
        teamId: widget.teamId,
        stroke: _selectedStroke,
        distance: _selectedDistance,
      );

      if (mounted) {
        ref.invalidate(customEventsProvider(widget.teamId));
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Custom Event', style: GoogleFonts.spaceGrotesk()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., 200 IM, 50 Fly',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStroke,
                decoration: const InputDecoration(
                  labelText: 'Stroke (Optional)',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...Stroke.values.map((stroke) => DropdownMenuItem(
                        value: stroke.value,
                        child: Text(stroke.value),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedStroke = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Distance (Optional)',
                  hintText: 'e.g., 200',
                  suffixText: 'm/yd',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _selectedDistance = int.tryParse(value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
