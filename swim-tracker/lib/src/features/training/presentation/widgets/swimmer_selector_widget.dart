import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/swimmers_repository.dart';
import '../../data/training_repository.dart';
import '../../domain/swimmer_profile.dart';
import '../swimmer_profile_screen.dart';

class SwimmerSelectorWidget extends ConsumerWidget {
  final Function(SwimmerProfile)? onSwimmerSelected;
  final bool showAddButton;
  final bool compact;

  const SwimmerSelectorWidget({
    super.key,
    this.onSwimmerSelected,
    this.showAddButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swimmersAsync = ref.watch(swimmersListProvider);
    final selectedSwimmerAsync = ref.watch(selectedSwimmerProvider);

    return swimmersAsync.when(
      data: (swimmers) {
        if (swimmers.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        return selectedSwimmerAsync.when(
          data: (selectedSwimmer) {
            if (compact) {
              return _buildCompactSelector(context, ref, swimmers, selectedSwimmer);
            }
            return _buildFullSelector(context, ref, swimmers, selectedSwimmer);
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'No swimmer profiles yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create your first swimmer profile to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            if (showAddButton) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateSwimmerDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Swimmer Profile'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    WidgetRef ref,
    List<SwimmerProfile> swimmers,
    SwimmerProfile? selectedSwimmer,
  ) {
    return InkWell(
      onTap: () => _showSwimmerSelectionDialog(context, ref, swimmers),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: selectedSwimmer?.avatarUrl != null
                ? NetworkImage(selectedSwimmer!.avatarUrl!)
                : null,
            child: selectedSwimmer?.avatarUrl == null
                ? Text(
                    selectedSwimmer?.fullName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            selectedSwimmer?.fullName ?? 'Select Swimmer',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    WidgetRef ref,
    List<SwimmerProfile> swimmers,
    SwimmerProfile? selectedSwimmer,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Swimmer Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (showAddButton)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showCreateSwimmerDialog(context, ref),
                    tooltip: 'Add Swimmer',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: swimmers.length,
            itemBuilder: (context, index) {
              final swimmer = swimmers[index];
              final isSelected = selectedSwimmer?.id == swimmer.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: swimmer.avatarUrl != null
                      ? NetworkImage(swimmer.avatarUrl!)
                      : null,
                  child: swimmer.avatarUrl == null
                      ? Text(
                          swimmer.fullName?.substring(0, 1).toUpperCase() ?? '?',
                        )
                      : null,
                ),
                title: Text(swimmer.fullName ?? 'Unnamed Swimmer'),
                subtitle: swimmer.swimcloudId.isNotEmpty
                    ? Text('SwimCloud: ${swimmer.swimcloudId}')
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editSwimmer(context, swimmer.id),
                      tooltip: 'Edit Swimmer',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.blue)
                    else
                      const SizedBox(width: 24), // Spacer to maintain alignment
                  ],
                ),
                selected: isSelected,
                onTap: () => _selectSwimmer(context, ref, swimmer),
              );
            },
          ),
        ],
      ),
    );
  }

  void _selectSwimmer(
    BuildContext context,
    WidgetRef ref,
    SwimmerProfile swimmer,
  ) async {
    final repository = ref.read(swimmersRepositoryProvider);
    await repository.setSelectedSwimmerId(swimmer.id);
    ref.invalidate(selectedSwimmerIdProvider);
    ref.invalidate(selectedSwimmerProvider);
    ref.invalidate(trainingSessionsProvider);
    ref.invalidate(recentSetsForSwimmerProvider);

    if (onSwimmerSelected != null) {
      onSwimmerSelected!(swimmer);
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // Close dialog if open
    }
  }

  void _showSwimmerSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<SwimmerProfile> swimmers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Swimmer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: swimmers.length + (showAddButton ? 1 : 0),
            itemBuilder: (context, index) {
              if (showAddButton && index == swimmers.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Swimmer'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCreateSwimmerDialog(context, ref);
                  },
                );
              }

              final swimmer = swimmers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: swimmer.avatarUrl != null
                      ? NetworkImage(swimmer.avatarUrl!)
                      : null,
                  child: swimmer.avatarUrl == null
                      ? Text(
                          swimmer.fullName?.substring(0, 1).toUpperCase() ?? '?',
                        )
                      : null,
                ),
                title: Text(swimmer.fullName ?? 'Unnamed Swimmer'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close selection dialog
                    _editSwimmer(context, swimmer.id);
                  },
                  tooltip: 'Edit Swimmer',
                ),
                onTap: () => _selectSwimmer(context, ref, swimmer),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreateSwimmerDialog(BuildContext context, WidgetRef ref) {
    // Navigate to create swimmer screen
    // Navigate directly to the swimmer profile screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SwimmerProfileScreen(),
      ),
    );
  }

  void _editSwimmer(BuildContext context, String swimmerId) {
    // Navigate to edit swimmer screen using MaterialPageRoute to avoid tab switching
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwimmerProfileScreen(swimmerId: swimmerId),
      ),
    );
  }
}
