import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../meets/data/meets_repository.dart';
import '../../records/presentation/records_screen.dart';
import '../../meets/domain/meet.dart';
import '../../training/presentation/training_screen.dart';
import '../../training/data/training_goals_repository.dart';
import '../../training/domain/training_session.dart';
import '../../training/data/swim_times_sync_service.dart';
import '../../training/data/training_repository.dart';
import '../../training/presentation/widgets/swimmer_selector_widget.dart';
import '../../profile/data/profile_repository.dart';
import 'goal_card_widget.dart';
import 'package:intl/intl.dart';
import '../../nutrition/presentation/nutrition_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasAutoFetchedOnLogin = false;

  @override
  void initState() {
    super.initState();
    // Auto-fetch swim times on login (once per app session)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFetchOnLogin();
    });
  }

  Future<void> _autoFetchOnLogin() async {
    if (_hasAutoFetchedOnLogin) return;

    _hasAutoFetchedOnLogin = true;

    try {
      final syncService = ref.read(swimTimesSyncServiceProvider);
      // Only fetch if data is older than 24 hours (silent background refresh)
      await syncService.fetchAllSwimmerTimes(forceRefresh: false);
      debugPrint(
          '✅ Checked swim times freshness on login (only fetched if stale)');
    } catch (e) {
      debugPrint('⚠️ Error checking swim times on login: $e');
      // Silent fail - don't interrupt user experience
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _HomeDashboard(),
      const RecordsScreen(),
      const TrainingScreen(),
      const NutritionDashboardScreen(),
      const _PlaceholderScreen(title: 'Profile', icon: Icons.person),
    ];

    debugPrint('🔵 HomeScreen build - _selectedIndex: $_selectedIndex');
    return Scaffold(
      backgroundColor: Colors.transparent, // Uses Theme background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001B33),
              Color(0xFF000B1A)
            ], // Deep dark aquatic blue gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: screens[_selectedIndex],
      ),
      floatingActionButton:
          _selectedIndex == 0 ? _buildQuickActionFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF021B33).withValues(alpha: 0.8),
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
              GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70),
            ),
            indicatorColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF00E5FF));
              }
              return const IconThemeData(color: Colors.white54);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == 4) {
                context.push('/profile');
              } else {
                setState(() => _selectedIndex = index);
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: 'Records',
              ),
              NavigationDestination(
                icon: Icon(Icons.pool_outlined),
                selectedIcon: Icon(Icons.pool),
                label: 'Training',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Nutrition',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionFAB(BuildContext context) {
    debugPrint('🔵 Building FAB - _selectedIndex: $_selectedIndex');
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF0055FF)]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
            blurRadius: 15,
          )
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          debugPrint('🔵 FAB pressed!');
          _showQuickActionMenu(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF021B33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildQuickActionMenuItem(
              context,
              'Add Swim Time',
              Icons.timer,
              Colors.cyan,
              () {
                Navigator.pop(context);
                context.push('/add-swim-time');
              },
            ),
            const SizedBox(height: 16),
            _buildQuickActionMenuItem(
              context,
              'Log Dryland',
              Icons.fitness_center,
              Colors.purple,
              () {
                Navigator.pop(context);
                // Navigate to log dryland screen
              },
            ),
            const SizedBox(height: 16),
            _buildQuickActionMenuItem(
              context,
              'Add Meal',
              Icons.restaurant,
              Colors.orange,
              () {
                Navigator.pop(context);
                // Navigate to add meal screen
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final userEmail = user?.email;
    final profileAsync = ref.watch(profileProvider);
    final meetsAsync = ref.watch(meetsListProvider);
    final trainingSessionsAsync = ref.watch(trainingSessionsProvider);

    // Get user name from profile, fallback to email or default
    final userName = profileAsync.maybeWhen(
      data: (profile) {
        if (profile != null) {
          final fullName = profile['full_name'];
          // Safely check if fullName is a non-empty String
          if (fullName != null &&
              fullName is String &&
              fullName.trim().isNotEmpty) {
            return fullName;
          }
        }
        return userEmail?.split('@').first ?? 'Swimmer';
      },
      orElse: () => userEmail?.split('@').first ?? 'Swimmer',
    );

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildWelcomeHeader(userName),
                  const SizedBox(height: 16),
                  // Swimmer Selector
                  const SwimmerSelectorWidget(compact: true),
                  const SizedBox(height: 32),

                  // Stats Overview (Streak, Workouts, etc)
                  trainingSessionsAsync.when(
                    data: (sessions) => _buildStatsRow(sessions),
                    loading: () => const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, st) => SizedBox(
                        height: 120,
                        child: Center(
                            child: Text('Error: $e',
                                style: const TextStyle(color: Colors.white)))),
                  ),
                  const SizedBox(height: 32),

                  // Weekly Training Volume Chart
                  _buildSectionHeader('Weekly Training Volume',
                      action: 'View All',
                      onActionTap: () => context.go('/training')),
                  const SizedBox(height: 16),
                  trainingSessionsAsync.when(
                    data: (sessions) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Water Training',
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildVolumeChart(sessions, isDryland: false),
                        const SizedBox(height: 24),
                        Text('Dryland Training',
                            style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildVolumeChart(sessions, isDryland: true),
                      ],
                    ),
                    loading: () => const SizedBox(
                        height: 240,
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, st) => SizedBox(
                        height: 240,
                        child: Center(
                            child: Text('Error: $e',
                                style: const TextStyle(color: Colors.white)))),
                  ),
                  const SizedBox(height: 32),

                  // Current Goals
                  _buildSectionHeader('Current Goals', action: '+ Add Goal',
                      onActionTap: () {
                    context.push('/training/goals/create');
                  }),
                  const SizedBox(height: 16),
                  _buildGoalsList(context, ref),
                  const SizedBox(height: 32),

                  // Recent Activity
                  _buildSectionHeader('Recent Activity',
                      action: 'View All',
                      onActionTap: () => context.go('/training')),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(context, ref),
                  const SizedBox(height: 32),

                  // Upcoming Meets Preview
                  _buildSectionHeader('Upcoming Meets'),
                  const SizedBox(height: 16),
                  _buildUpcomingMeets(context, meetsAsync),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            Text(
              userName, // Capitalize first letter ideally
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatsRow(List<TrainingSession> sessions) {
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Extract unique training dates (ignoring time)
    final uniqueDates = sessions
        .map((s) => DateTime(
            s.trainingDate.year, s.trainingDate.month, s.trainingDate.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (uniqueDates.isNotEmpty) {
      DateTime expectedNext = today;
      bool streakActive = false;

      if (uniqueDates.first == today) {
        streakActive = true;
        streak++;
        expectedNext = today.subtract(const Duration(days: 1));
      } else if (uniqueDates.first == today.subtract(const Duration(days: 1))) {
        streakActive = true;
        expectedNext = today.subtract(const Duration(days: 1));
      }

      if (streakActive) {
        final startIndex = uniqueDates.first == today ? 1 : 0;
        for (var i = startIndex; i < uniqueDates.length; i++) {
          if (uniqueDates[i] == expectedNext) {
            streak++;
            expectedNext = expectedNext.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }
    }

    // Calculate weekly progress (Monday - Sunday)
    final currentWeekday = now.weekday;
    final startOfWeek = today.subtract(Duration(days: currentWeekday - 1));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF0055FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orangeAccent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Training Streak',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$streak',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar styled dynamically
          Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isActive = uniqueDates.contains(date);
              final isFuture = date.isAfter(today);

              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : (isFuture
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            streak > 0
                ? 'Keep going! You are on a $streak day streak.'
                : 'Log a practice to start your streak!',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {String? action, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onActionTap ?? () {},
            child: Text(
              action,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00E5FF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVolumeChart(List<TrainingSession> sessions,
      {bool isDryland = false}) {
    final values = List.filled(7, 0.0);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    for (final session in sessions) {
      final isSessionDryland = session.stroke.toLowerCase() == 'dryland';
      if (isDryland && !isSessionDryland) continue;
      if (!isDryland && isSessionDryland) continue;

      final date = DateTime(session.trainingDate.year,
          session.trainingDate.month, session.trainingDate.day);
      final difference = date.difference(startOfWeek).inDays;
      if (difference >= 0 && difference < 7) {
        if (isDryland) {
          values[difference] += session.totalDistance > 0
              ? session.totalDistance.toDouble()
              : session.numberOfReps.toDouble();
        } else {
          values[difference] += session.totalDistance.toDouble();
        }
      }
    }

    double maxY = values.fold(0.0, (prev, val) => val > prev ? val : prev);
    if (maxY == 0) maxY = isDryland ? 50 : 2000;
    // Add 20% headroom
    maxY = maxY * 1.2;
    // Round to nearest nice number
    if (maxY > 100) {
      maxY = (maxY / 100).ceil() * 100;
    } else {
      maxY = (maxY / 10).ceil() * 10;
    }

    double horizontalInterval = maxY / 4;
    if (horizontalInterval == 0) horizontalInterval = 1;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF0F172A),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  isDryland ? '${rod.toY.toInt()} reps' : '${rod.toY.toInt()}m',
                  GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= days.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()],
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Color(0xFFF1F5F9),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: entry.value >= (maxY * 0.8)
                      ? (isDryland
                          ? Colors.purpleAccent
                          : const Color(0xFF00E5FF))
                      : (entry.key == 6
                          ? const Color(0xFF7000FF).withValues(alpha: 0.5)
                          : (isDryland
                              ? Colors.purpleAccent.withValues(alpha: 0.8)
                              : const Color(0xFF00E5FF)
                                  .withValues(alpha: 0.8))),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(activeGoalsProvider);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No active goals',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/training/goals/create'),
                    child: Text(
                      'Create your first goal',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show up to 3 goals on home page
        final displayGoals = goals.take(3).toList();

        return Column(
          children: [
            ...displayGoals.map((goal) {
              return Column(
                children: [
                  GoalCardWidget(goal: goal),
                  const SizedBox(height: 16),
                ],
              );
            }),
            if (goals.length > 3)
              TextButton(
                onPressed: () {
                  // Navigate to training tab and switch to goals
                  context.go('/training');
                },
                child: Text(
                  'View all ${goals.length} goals',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Error loading goals',
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      ),
    );
  }

  // Keep old method for backward compatibility if needed, but we'll use the new widget

  Widget _buildRecentActivityList(BuildContext context, WidgetRef ref) {
    final practicesAsync = ref.watch(practicesProvider);

    return practicesAsync.when(
      data: (practices) {
        if (practices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No recent practices found',
                  style: GoogleFonts.outfit(color: Colors.grey)),
            ),
          );
        }

        final displayPractices = practices.take(3).toList();
        return Column(
          children: displayPractices.map((practice) {
            final totalYards =
                practice.sets?.fold(0, (sum, set) => sum + set.totalDistance) ??
                    0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityItem(
                icon: Icons.pool,
                color: Colors.blue,
                title: practice.name ?? 'Training Practice',
                description:
                    '$totalYards yds • ${practice.sets?.length ?? 0} sets',
                time: DateFormat.yMMMd().format(practice.practiceDate),
                onTap: () => context.push('/training/practices/${practice.id}'),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, st) => Center(
          child: Text('Error loading activity',
              style: GoogleFonts.outfit(color: Colors.grey))),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String time,
    bool showTrophy = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: GoogleFonts.outfit(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (showTrophy)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events,
                    color: Color(0xFF00E5FF), size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMeets(
      BuildContext context, AsyncValue<List<SwimMeet>> meetsAsync) {
    return meetsAsync.when(
      data: (meets) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final upcoming = meets
            .where((m) {
              final meetDate = DateTime(
                  m.startDate.year, m.startDate.month, m.startDate.day);
              return !meetDate.isBefore(today);
            })
            .toList()
            .reversed
            .toList();

        if (upcoming.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Text(
                'No upcoming meets scheduled',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
          );
        }

        final nextMeet = upcoming.first;

        return InkWell(
          onTap: () => context.push('/meets/${nextMeet.id}', extra: nextMeet),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Meet',
                      style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${nextMeet.startDate.difference(now).inDays} days',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nextMeet.meetName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      nextMeet.location ?? 'TBD',
                      style:
                          GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              '$title Coming Soon',
              style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
