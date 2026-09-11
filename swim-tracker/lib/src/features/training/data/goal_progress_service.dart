import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/training_goal.dart';
import '../domain/goal_progress.dart';

class GoalProgressService {
  final SupabaseClient _supabase;

  GoalProgressService(this._supabase);

  // Calculate progress for any goal type
  Future<GoalProgress> calculateProgress(TrainingGoal goal) async {
    switch (goal.goalType) {
      case GoalType.time:
        return await _calculateTimeGoalProgress(goal);
      case GoalType.distance:
        return await _calculateDistanceGoalProgress(goal);
      case GoalType.frequency:
        return await _calculateFrequencyGoalProgress(goal);
      case GoalType.custom:
        return await _calculateCustomGoalProgress(goal);
    }
  }

  // Calculate progress for time-based goals
  Future<GoalProgress> _calculateTimeGoalProgress(TrainingGoal goal) async {
    if (goal.swimmerId == null) {
      throw Exception('Goal must have a swimmer_id');
    }

    if (goal.targetTimeSeconds == null || goal.stroke == null || goal.distance == null) {
      return GoalProgress(
        currentValue: 0,
        targetValue: 0,
        progressPercentage: 0,
        status: ProgressStatus.notStarted,
        statusMessage: 'Goal configuration incomplete',
      );
    }

    // Query swim_times for matching events
    var query = _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', goal.swimmerId!)
        .eq('stroke', goal.stroke!)
        .eq('distance', goal.distance!);

    if (goal.poolType != null) {
      query = query.eq('pool_type', goal.poolType!);
    }

    final times = await query.order('time_seconds', ascending: true);

    if (times.isEmpty) {
      return GoalProgress(
        currentValue: goal.targetTimeSeconds!,
        targetValue: goal.targetTimeSeconds!,
        progressPercentage: 0,
        status: ProgressStatus.notStarted,
        statusMessage: 'No swim times recorded yet',
      );
    }

    // Get best time (lowest time_seconds)
    final bestTimeData = times.first;
    final bestTime = (bestTimeData['time_seconds'] as num).toDouble();

    // Get recent times (last 5 swims, ordered by date)
    final recentTimesQuery = _supabase
        .from('swim_times')
        .select()
        .eq('swimmer_id', goal.swimmerId!)
        .eq('stroke', goal.stroke!)
        .eq('distance', goal.distance!);

    if (goal.poolType != null) {
      recentTimesQuery.eq('pool_type', goal.poolType!);
    }

    final recentTimes = await recentTimesQuery
        .order('meet_date', ascending: false)
        .limit(5);

    final recentTime = recentTimes.isNotEmpty
        ? (recentTimes.first['time_seconds'] as num).toDouble()
        : bestTime;

    // Calculate progress
    // Progress = (targetTime - bestTime) / (targetTime - initialTime) * 100
    // For simplicity, we'll use: progress = (targetTime - bestTime) / targetTime
    // This gives us a percentage of how close we are to the target
    final targetTime = goal.targetTimeSeconds!;
    double progressPercentage = 0;

    if (bestTime <= targetTime) {
      // Goal achieved!
      progressPercentage = 1.0;
    } else {
      // Calculate progress: we want to improve from bestTime to targetTime
      // If bestTime is 60s and target is 50s, we need to improve by 10s
      // Progress = how much we've improved / how much we need to improve
      // For now, use a simple ratio: (targetTime / bestTime)
      progressPercentage = (targetTime / bestTime).clamp(0.0, 1.0);
    }

    // Determine status
    ProgressStatus status;
    String? statusMessage;
    bool isImproving = recentTimes.length >= 2
        ? (recentTimes[0]['time_seconds'] as num).toDouble() <=
            (recentTimes[1]['time_seconds'] as num).toDouble()
        : true;

    if (progressPercentage >= 1.0) {
      status = ProgressStatus.completed;
      statusMessage = 'Goal achieved!';
    } else if (progressPercentage >= 0.8 && isImproving) {
      status = ProgressStatus.onTrack;
      statusMessage = 'On Track';
    } else if (progressPercentage >= 0.5) {
      status = ProgressStatus.inProgress;
      statusMessage = 'In Progress';
    } else {
      status = ProgressStatus.behind;
      statusMessage = 'Behind';
    }

    // Calculate days remaining if target date is set
    int? daysRemaining;
    if (goal.targetDate != null) {
      final now = DateTime.now();
      final target = goal.targetDate!;
      daysRemaining = target.difference(now).inDays;
    }

    return GoalProgress(
      currentValue: bestTime,
      targetValue: targetTime,
      progressPercentage: progressPercentage,
      bestTime: _formatTime(bestTime),
      recentTime: _formatTime(recentTime),
      status: status,
      statusMessage: statusMessage,
      daysRemaining: daysRemaining,
    );
  }

  // Calculate progress for distance-based goals
  Future<GoalProgress> _calculateDistanceGoalProgress(TrainingGoal goal) async {
    if (goal.swimmerId == null) {
      throw Exception('Goal must have a swimmer_id');
    }

    if (goal.targetDistance == null || goal.distancePeriod == null) {
      return GoalProgress(
        currentValue: 0,
        targetValue: 0,
        progressPercentage: 0,
        status: ProgressStatus.notStarted,
        statusMessage: 'Goal configuration incomplete',
      );
    }

    // Calculate date range based on period
    final now = DateTime.now();
    DateTime startDate;

    switch (goal.distancePeriod) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = now;
    }

    // Query training_sets for the period
    var query = _supabase
        .from('training_sets')
        .select('total_distance')
        .eq('swimmer_id', goal.swimmerId!)
        .gte('training_date', startDate.toIso8601String().split('T')[0]);

    if (goal.teamId != null) {
      query = query.eq('team_id', goal.teamId!);
    }

    final sessions = await query;

    // Sum total distance
    int currentDistance = 0;
    for (var session in sessions) {
      currentDistance += (session['total_distance'] as num).toInt();
    }

    final targetDistance = goal.targetDistance!;
    final progressPercentage = (currentDistance / targetDistance).clamp(0.0, 1.0);

    // Determine status
    ProgressStatus status;
    String? statusMessage;

    if (progressPercentage >= 1.0) {
      status = ProgressStatus.completed;
      statusMessage = 'Goal achieved!';
    } else {
      // Calculate days remaining in period
      DateTime endDate;
      switch (goal.distancePeriod) {
        case 'daily':
          endDate = startDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          endDate = startDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        default:
          endDate = now;
      }

      final daysRemaining = endDate.difference(now).inDays;
      final daysInPeriod = endDate.difference(startDate).inDays;
      final expectedProgress = (daysInPeriod - daysRemaining) / daysInPeriod;

      if (progressPercentage >= expectedProgress * 0.9) {
        status = ProgressStatus.onTrack;
        statusMessage = 'On Track';
      } else if (progressPercentage >= expectedProgress * 0.5) {
        status = ProgressStatus.inProgress;
        statusMessage = 'In Progress';
      } else {
        status = ProgressStatus.behind;
        statusMessage = 'Behind';
      }
    }

    int? daysRemaining;
    if (goal.targetDate != null) {
      daysRemaining = goal.targetDate!.difference(now).inDays;
    }

    return GoalProgress(
      currentValue: currentDistance.toDouble(),
      targetValue: targetDistance.toDouble(),
      progressPercentage: progressPercentage,
      status: status,
      statusMessage: statusMessage,
      daysRemaining: daysRemaining,
    );
  }

  // Calculate progress for frequency-based goals
  Future<GoalProgress> _calculateFrequencyGoalProgress(TrainingGoal goal) async {
    if (goal.swimmerId == null) {
      throw Exception('Goal must have a swimmer_id');
    }

    if (goal.targetFrequency == null || goal.frequencyPeriod == null) {
      return GoalProgress(
        currentValue: 0,
        targetValue: 0,
        progressPercentage: 0,
        status: ProgressStatus.notStarted,
        statusMessage: 'Goal configuration incomplete',
      );
    }

    // Calculate date range based on period
    final now = DateTime.now();
    DateTime startDate;

    switch (goal.frequencyPeriod) {
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = now;
    }

    // Count training sessions for the period
    var query = _supabase
        .from('training_sets')
        .select('id')
        .eq('swimmer_id', goal.swimmerId!)
        .gte('training_date', startDate.toIso8601String().split('T')[0]);

    if (goal.teamId != null) {
      query = query.eq('team_id', goal.teamId!);
    }

    final sessions = await query;
    final currentFrequency = sessions.length;
    final targetFrequency = goal.targetFrequency!;
    final progressPercentage = (currentFrequency / targetFrequency).clamp(0.0, 1.0);

    // Determine status
    ProgressStatus status;
    String? statusMessage;

    if (progressPercentage >= 1.0) {
      status = ProgressStatus.completed;
      statusMessage = 'Goal achieved!';
    } else {
      // Calculate days remaining in period
      DateTime endDate;
      switch (goal.frequencyPeriod) {
        case 'weekly':
          endDate = startDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        default:
          endDate = now;
      }

      final daysRemaining = endDate.difference(now).inDays;
      final daysInPeriod = endDate.difference(startDate).inDays;
      final expectedProgress = (daysInPeriod - daysRemaining) / daysInPeriod;

      if (progressPercentage >= expectedProgress * 0.9) {
        status = ProgressStatus.onTrack;
        statusMessage = 'On Track';
      } else if (progressPercentage >= expectedProgress * 0.5) {
        status = ProgressStatus.inProgress;
        statusMessage = 'In Progress';
      } else {
        status = ProgressStatus.behind;
        statusMessage = 'Behind';
      }
    }

    int? daysRemaining;
    if (goal.targetDate != null) {
      daysRemaining = goal.targetDate!.difference(now).inDays;
    }

    return GoalProgress(
      currentValue: currentFrequency.toDouble(),
      targetValue: targetFrequency.toDouble(),
      progressPercentage: progressPercentage,
      status: status,
      statusMessage: statusMessage,
      daysRemaining: daysRemaining,
    );
  }

  // Calculate progress for custom goals using manual entries
  Future<GoalProgress> _calculateCustomGoalProgress(TrainingGoal goal) async {
    if (goal.swimmerId == null) {
      throw Exception('Goal must have a swimmer_id');
    }

    if (goal.customTargetValue == null) {
      return GoalProgress(
        currentValue: 0,
        targetValue: 0,
        progressPercentage: 0,
        status: ProgressStatus.notStarted,
        statusMessage: 'Goal configuration incomplete',
      );
    }

    // Get the latest progress entry for this goal
    final latestEntry = await _supabase
        .from('goal_progress_entries')
        .select()
        .eq('goal_id', goal.id)
        .eq('swimmer_id', goal.swimmerId!)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    double currentValue = 0;
    if (latestEntry != null) {
      currentValue = (latestEntry['progress_value'] as num).toDouble();
    }

    final targetValue = goal.customTargetValue!;
    final progressPercentage = (currentValue / targetValue).clamp(0.0, 1.0);

    // Determine status
    ProgressStatus status;
    String? statusMessage;

    if (progressPercentage >= 1.0) {
      status = ProgressStatus.completed;
      statusMessage = 'Goal achieved!';
    } else if (latestEntry == null) {
      status = ProgressStatus.notStarted;
      statusMessage = 'Add your first progress entry';
    } else if (progressPercentage >= 0.8) {
      status = ProgressStatus.onTrack;
      statusMessage = 'On Track';
    } else if (progressPercentage >= 0.5) {
      status = ProgressStatus.inProgress;
      statusMessage = 'In Progress';
    } else if (progressPercentage > 0) {
      status = ProgressStatus.behind;
      statusMessage = 'Behind';
    } else {
      status = ProgressStatus.notStarted;
      statusMessage = 'Add your first progress entry';
    }

    // Calculate days remaining if target date is set
    int? daysRemaining;
    if (goal.targetDate != null) {
      final now = DateTime.now();
      final target = goal.targetDate!;
      daysRemaining = target.difference(now).inDays;
    }

    return GoalProgress(
      currentValue: currentValue,
      targetValue: targetValue,
      progressPercentage: progressPercentage,
      status: status,
      statusMessage: statusMessage,
      daysRemaining: daysRemaining,
    );
  }

  // Helper to format time in seconds to MM:SS.mm format
  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toStringAsFixed(2).padLeft(5, '0')}';
    }
    return '${secs.toStringAsFixed(2)}s';
  }
}
