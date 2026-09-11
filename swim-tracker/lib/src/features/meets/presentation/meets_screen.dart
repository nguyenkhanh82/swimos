import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../authentication/data/auth_repository.dart';
import '../../training/data/swim_times_sync_service.dart';
import '../data/meets_repository.dart';
import '../domain/meet.dart';

class MeetsScreen extends ConsumerStatefulWidget {
  const MeetsScreen({super.key});

  @override
  ConsumerState<MeetsScreen> createState() => _MeetsScreenState();
}

class _MeetsScreenState extends ConsumerState<MeetsScreen> {
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    // Silently check and refresh data in background if needed (only if older than 24h)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _silentRefreshIfNeeded();
    });
  }

  /// Silently refresh data in background if it's older than 24 hours
  /// This doesn't show loading indicators or messages
  Future<void> _silentRefreshIfNeeded() async {
    try {
      final syncService = ref.read(swimTimesSyncServiceProvider);
      // This will only fetch if data is older than 24 hours
      await syncService.fetchCurrentSwimmerTimes(forceRefresh: false);
      // Refresh meets list after fetching (if fetch happened)
      ref.invalidate(meetsListProvider);
    } catch (e) {
      debugPrint('Error silently refreshing times: $e');
      // Silently fail - user can manually refresh if needed
    }
  }

  /// Manual refresh - forces a fetch regardless of last_fetched_at
  Future<void> _manualRefresh() async {
    setState(() {
      _isFetching = true;
    });

    try {
      final syncService = ref.read(swimTimesSyncServiceProvider);
      final success =
          await syncService.fetchCurrentSwimmerTimes(forceRefresh: true);

      if (!mounted) return;
      // Wait a moment for database to update
      await Future.delayed(const Duration(milliseconds: 1000));
      // Refresh meets list after fetching
      ref.invalidate(meetsListProvider);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swim times and meets synced successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sync completed, but no new data found. Make sure your swimmer has a SwimCloud ID set.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error manually refreshing times: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetsValue = ref.watch(meetsListProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF001B33), Color(0xFF000B1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Upcoming Meets',
              style: GoogleFonts.outfit(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: _isFetching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isFetching
                  ? null
                  : () {
                      ref.invalidate(meetsListProvider);
                      _manualRefresh();
                    },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).primaryColor),
                accountName: const Text('Swimmer'),
                accountEmail: Text(
                  ref.watch(authRepositoryProvider).currentUser?.email ??
                      'No Email',
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person),
                ),
              ),
            ],
          ),
        ),
        body: meetsValue.when(
          data: (meets) {
            if (meets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No meets found',
                      style: GoogleFonts.outfit(
                          fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meets will appear here once you fetch swim times from SwimCloud',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isFetching
                          ? null
                          : () async {
                              ref.invalidate(meetsListProvider);
                              await _manualRefresh();
                            },
                      icon: _isFetching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync),
                      label:
                          Text(_isFetching ? 'Syncing...' : 'Sync Swim Times'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Meets are automatically created when swim times are synced from SwimCloud.\n\nMake sure your swimmer profile has a SwimCloud ID set.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meets.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _MeetCard(meet: meets[index]),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading meets',
                  style:
                      GoogleFonts.outfit(fontSize: 18, color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(meetsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Show Add Meet Dialog
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _MeetCard extends StatelessWidget {
  final SwimMeet meet;
  const _MeetCard({required this.meet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.pool,
            color: Color(0xFF00E5FF),
          ),
        ),
        title: Text(
          meet.meetName,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  meet.endDate != null
                      ? '${DateFormat.yMMMd().format(meet.startDate)} - ${DateFormat.yMMMd().format(meet.endDate!)}'
                      : DateFormat.yMMMd().format(meet.startDate),
                  style: GoogleFonts.outfit(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (meet.location != null)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(meet.location!,
                          style: GoogleFonts.outfit(color: Colors.white70))),
                ],
              ),
            if (meet.meetType != null || meet.organization != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (meet.meetType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meet.meetType!,
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: Colors.blue[700]),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (meet.organization != null)
                    Expanded(
                      child: Text(
                        meet.organization!,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to details
          context.push('/meets/${meet.id}', extra: meet);
        },
      ),
    );
  }
}
