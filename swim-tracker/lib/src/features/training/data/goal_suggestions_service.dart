import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../presentation/widgets/goal_suggestions_widget.dart';

// Models
class PersonalRecord {
  final String stroke;
  final int distance;
  final String poolType;
  final double bestTime;
  final String recordDate;
  final String? currentStandard;
  final String? nextStandard;

  PersonalRecord({
    required this.stroke,
    required this.distance,
    required this.poolType,
    required this.bestTime,
    required this.recordDate,
    this.currentStandard,
    this.nextStandard,
  });
}

class TrainingAnalysis {
  final int totalSets;
  final int avgSetDistance;
  final Map<String, int> strokeBreakdown;
  final Map<String, int> intensityBreakdown;
  final int recentActivity;
  final int consistencyScore;
  final List<PersonalRecord> personalRecords;

  /// Optional: e.g. "100 Free practice reps: improving over last month"
  final String? practiceImprovementSummary;

  TrainingAnalysis({
    required this.totalSets,
    required this.avgSetDistance,
    required this.strokeBreakdown,
    required this.intensityBreakdown,
    required this.recentActivity,
    required this.consistencyScore,
    required this.personalRecords,
    this.practiceImprovementSummary,
  });
}

// GoalSuggestion is imported from goal_suggestions_widget.dart

class GoalSuggestionsService {
  final SupabaseClient _supabase;

  GoalSuggestionsService(this._supabase);

  Future<List<GoalSuggestion>> getSuggestions(
      {required String swimmerId}) async {
    debugPrint('🤖 GoalSuggestionsService: Starting...');

    debugPrint('✅ Getting suggestions for swimmer: $swimmerId');

    // Analyze training history
    final analysis = await _analyzeTrainingHistory(swimmerId);

    // Get existing goals
    final existingGoalsResponse = await _supabase
        .from('training_goals')
        .select('*')
        .eq('swimmer_id', swimmerId)
        .eq('is_active', true);

    final existingGoals = (existingGoalsResponse as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Get AI suggestions
    final suggestions = await _getAISuggestions(analysis, existingGoals);

    return suggestions;
  }

  Future<TrainingAnalysis> _analyzeTrainingHistory(String swimmerId) async {
    debugPrint('📊 Analyzing training history for swimmer: $swimmerId');

    // Get all training sets
    final trainingSetsResponse = await _supabase
        .from('training_sets')
        .select('*')
        .eq('swimmer_id', swimmerId)
        .order('training_date', ascending: false)
        .limit(200);

    final sets = (trainingSetsResponse as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final totalSets = sets.length;

    debugPrint('📊 Found $totalSets training sets');

    if (totalSets == 0) {
      return TrainingAnalysis(
        totalSets: 0,
        avgSetDistance: 0,
        strokeBreakdown: {},
        intensityBreakdown: {},
        recentActivity: 0,
        consistencyScore: 0,
        personalRecords: [],
        practiceImprovementSummary: null,
      );
    }

    // Calculate averages and breakdowns
    int totalDistance = 0;
    final strokeBreakdown = <String, int>{};
    final intensityBreakdown = <String, int>{};

    for (final set in sets) {
      final distance = (set['total_distance'] as num?)?.toInt() ?? 0;
      totalDistance += distance;

      final stroke = (set['stroke'] as String?) ?? 'Unknown';
      strokeBreakdown[stroke] = (strokeBreakdown[stroke] ?? 0) + distance;

      final intensity = (set['intensity'] as String?) ?? 'moderate';
      intensityBreakdown[intensity] = (intensityBreakdown[intensity] ?? 0) + 1;
    }

    final avgSetDistance = (totalDistance / totalSets).round();

    // Recent activity (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    int recentActivity = 0;
    for (final set in sets) {
      final dateStr = set['training_date'] as String?;
      if (dateStr != null) {
        try {
          final setDate = DateTime.parse(dateStr);
          if (setDate.isAfter(thirtyDaysAgo)) {
            recentActivity++;
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing date: $dateStr');
        }
      }
    }

    // Consistency score (sets per week in last 30 days)
    final consistencyScore =
        (recentActivity / 4 * 100 / 12).round().clamp(0, 100);

    // Calculate personal records from splits
    final personalRecords = await _calculatePersonalRecords(swimmerId);

    // Optional: same set over time (practice improvement)
    final practiceImprovementSummary =
        await _computePracticeImprovementSummary(swimmerId, sets);

    debugPrint('📊 Analysis complete:');
    debugPrint('  - Total sets: $totalSets');
    debugPrint('  - Avg distance: $avgSetDistance');
    debugPrint('  - Recent activity: $recentActivity');
    debugPrint('  - Consistency score: $consistencyScore');
    debugPrint('  - Personal records: ${personalRecords.length}');

    return TrainingAnalysis(
      totalSets: totalSets,
      avgSetDistance: avgSetDistance,
      strokeBreakdown: strokeBreakdown,
      intensityBreakdown: intensityBreakdown,
      recentActivity: recentActivity,
      consistencyScore: consistencyScore,
      personalRecords: personalRecords,
      practiceImprovementSummary: practiceImprovementSummary,
    );
  }

  /// If the same set (stroke + distance + reps) was done multiple times with splits, compare recent vs older avg rep time.
  Future<String?> _computePracticeImprovementSummary(
      String swimmerId, List<Map<String, dynamic>> sets) async {
    final keyToSetIds = <String, List<String>>{};
    for (final set in sets) {
      final id = set['id'] as String?;
      final stroke = set['stroke'] as String? ?? '';
      final dist = (set['distance_per_rep'] as num?)?.toInt() ?? 0;
      final reps = (set['number_of_reps'] as num?)?.toInt() ?? 0;
      if (id == null || stroke.isEmpty || dist == 0 || reps == 0) continue;
      final key = '$stroke-$dist-$reps';
      keyToSetIds.putIfAbsent(key, () => []).add(id);
    }
    for (final ids in keyToSetIds.values) {
      if (ids.length < 2) continue;
      final splitsData = await _supabase
          .from('training_set_splits')
          .select('training_set_id, time_seconds')
          .eq('swimmer_id', swimmerId)
          .inFilter('training_set_id', ids);
      final splits = (splitsData as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (splits.isEmpty) continue;
      final bySet = <String, List<double>>{};
      for (final s in splits) {
        final setId = s['training_set_id'] as String?;
        final t = (s['time_seconds'] as num?)?.toDouble();
        if (setId == null || t == null) continue;
        bySet.putIfAbsent(setId, () => []).add(t);
      }
      if (bySet.length < 2) continue;
      final setDates = {
        for (final set in sets)
          set['id'] as String: set['training_date'] as String?
      };
      final withAvg = bySet.entries.map((e) {
        final avg = e.value.fold<double>(0, (a, b) => a + b) / e.value.length;
        final dateStr = setDates[e.key];
        return MapEntry(e.key, (avg, dateStr ?? ''));
      }).toList();
      withAvg.sort((a, b) => (b.value.$2).compareTo((a.value.$2)));
      if (withAvg.length >= 2) {
        final recent = withAvg[0].value.$1;
        final older = withAvg[1].value.$1;
        if (recent < older && (older - recent) > 0.5) {
          final set = sets.firstWhere((s) => s['id'] == withAvg[0].key);
          final stroke = set['stroke'] as String? ?? '';
          final dist = set['distance_per_rep'] as int? ?? 0;
          return '$dist $stroke practice reps: improving over recent sessions';
        }
      }
    }
    return null;
  }

  Future<List<PersonalRecord>> _calculatePersonalRecords(
      String swimmerId) async {
    debugPrint(
        '🏆 Calculating personal records from training, swim_times, and meet_entries...');

    // Group by event (stroke + distance + pool type)
    final eventPRs = <String, PersonalRecord>{};

    // 1. Get records from training_set_splits
    final splitsResponse =
        await _supabase.from('training_set_splits').select('''
          id,
          rep_number,
          time_seconds,
          created_at,
          training_sets:training_set_id (
            stroke,
            distance_per_rep,
            pool_type,
            training_date
          )
        ''').eq('swimmer_id', swimmerId);

    final splits = (splitsResponse as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    for (final split in splits) {
      final trainingSet = split['training_sets'];
      if (trainingSet == null) continue;

      final stroke = (trainingSet['stroke'] as String?) ?? '';
      final distance = (trainingSet['distance_per_rep'] as num?)?.toInt() ?? 0;
      final poolType = (trainingSet['pool_type'] as String?) ?? 'SCY';
      final time = (split['time_seconds'] as num?)?.toDouble() ?? 0.0;
      final date = (trainingSet['training_date'] as String?) ?? '';

      if (stroke.isEmpty || distance == 0 || time == 0) continue;

      final eventKey = '$stroke-$distance-$poolType';

      if (!eventPRs.containsKey(eventKey) ||
          eventPRs[eventKey]!.bestTime > time) {
        eventPRs[eventKey] = PersonalRecord(
          stroke: stroke,
          distance: distance,
          poolType: poolType,
          bestTime: time,
          recordDate: date,
        );
      }
    }

    // 2. Get records from swim_times (official times and personal bests)
    final swimTimesResponse = await _supabase
        .from('swim_times')
        .select('*')
        .eq('swimmer_id', swimmerId)
        .order('time_seconds', ascending: true);

    final swimTimes = (swimTimesResponse as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    for (final swimTime in swimTimes) {
      final stroke = (swimTime['stroke'] as String?) ?? '';
      final distance = (swimTime['distance'] as num?)?.toInt() ?? 0;
      final poolType = (swimTime['pool_type'] as String?) ?? 'SCY';
      final time = (swimTime['time_seconds'] as num?)?.toDouble() ?? 0.0;
      final date = (swimTime['meet_date'] as String?) ??
          (swimTime['created_at'] as String?) ??
          '';

      if (stroke.isEmpty || distance == 0 || time == 0) continue;

      final eventKey = '$stroke-$distance-$poolType';

      // Prefer swim_times over training splits (more official)
      if (!eventPRs.containsKey(eventKey) ||
          eventPRs[eventKey]!.bestTime > time) {
        eventPRs[eventKey] = PersonalRecord(
          stroke: stroke,
          distance: distance,
          poolType: poolType,
          bestTime: time,
          recordDate: date,
        );
      }
    }

    // 3. Get records from meet_entries (competition results)
    final meetEntriesResponse = await _supabase
        .from('meet_entries')
        .select('''
          *,
          swim_meets:meet_id (
            start_date,
            pool_type
          )
        ''')
        .eq('swimmer_id', swimmerId)
        .not('final_time_seconds', 'is', null)
        .order('final_time_seconds', ascending: true);

    final meetEntries = (meetEntriesResponse as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    for (final entry in meetEntries) {
      // Parse event_name to extract stroke and distance
      // Format: "50 Free", "100 Back", "200 Breast", etc.
      final eventName = (entry['event_name'] as String?) ?? '';
      if (eventName.isEmpty) continue;

      // Try to parse event name (e.g., "50 Free", "100 Back")
      final parts = eventName.split(' ');
      if (parts.length < 2) continue;

      final distanceStr = parts[0];
      final strokeStr = parts.sublist(1).join(' ');

      final distance = int.tryParse(distanceStr);
      if (distance == null) continue;

      // Map stroke names
      final stroke = _normalizeStroke(strokeStr);
      if (stroke.isEmpty) continue;

      final meet = entry['swim_meets'] as Map<String, dynamic>?;
      final poolType = (meet?['pool_type'] as String?) ??
          (entry['pool_type'] as String?) ??
          'SCY';
      final time = (entry['final_time_seconds'] as num?)?.toDouble() ?? 0.0;
      final date = (meet?['start_date'] as String?) ??
          (entry['created_at'] as String?) ??
          '';

      if (time == 0) continue;

      final eventKey = '$stroke-$distance-$poolType';

      // Meet entries are most official, so always prefer them
      if (!eventPRs.containsKey(eventKey) ||
          eventPRs[eventKey]!.bestTime > time) {
        eventPRs[eventKey] = PersonalRecord(
          stroke: stroke,
          distance: distance,
          poolType: poolType,
          bestTime: time,
          recordDate: date,
        );
      }
    }

    if (eventPRs.isEmpty) {
      debugPrint('⚠️ No personal records found from any source');
      return [];
    }

    // Get time standards for PR comparison
    final prsWithStandards = <PersonalRecord>[];

    for (final pr in eventPRs.values) {
      final standardsResponse = await _supabase
          .from('time_standards')
          .select('standard_level')
          .eq('stroke', pr.stroke)
          .eq('distance', pr.distance)
          .eq('course', pr.poolType)
          .gte('time_seconds', pr.bestTime)
          .order('time_seconds', ascending: true)
          .limit(1);

      final standards = (standardsResponse as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      String? currentStandard;
      String? nextStandard;

      if (standards.isNotEmpty) {
        currentStandard = standards[0]['standard_level'] as String?;
        if (currentStandard != null) {
          final standardLevels = ['B', 'BB', 'A', 'AA', 'AAA', 'AAAA', 'AAAAA'];
          final currentIndex = standardLevels.indexOf(currentStandard);
          if (currentIndex >= 0 && currentIndex < standardLevels.length - 1) {
            nextStandard = standardLevels[currentIndex + 1];
          }
        }
      }

      prsWithStandards.add(PersonalRecord(
        stroke: pr.stroke,
        distance: pr.distance,
        poolType: pr.poolType,
        bestTime: pr.bestTime,
        recordDate: pr.recordDate,
        currentStandard: currentStandard,
        nextStandard: nextStandard,
      ));
    }

    debugPrint('🏆 Found ${prsWithStandards.length} personal records');
    return prsWithStandards;
  }

  Future<List<GoalSuggestion>> _getAISuggestions(
    TrainingAnalysis analysis,
    List<Map<String, dynamic>> existingGoals,
  ) async {
    debugPrint('🤖 getAISuggestions: Starting AI suggestion generation');

    // Get API keys from environment variables
    final groqApiKey = dotenv.env['GROQ_API_KEY'];
    final openaiApiKey = dotenv.env['OPENAI_API_KEY'];
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];

    final apiKey = groqApiKey ?? openaiApiKey ?? geminiApiKey;
    final useGroq = groqApiKey != null && groqApiKey.isNotEmpty;
    final useGemini = (groqApiKey == null || groqApiKey.isEmpty) &&
        (openaiApiKey == null || openaiApiKey.isEmpty) &&
        (geminiApiKey != null && geminiApiKey.isNotEmpty);

    debugPrint('🔑 API Key Status:');
    debugPrint('  - Has Groq: ${groqApiKey != null && groqApiKey.isNotEmpty}');
    debugPrint(
        '  - Has OpenAI: ${openaiApiKey != null && openaiApiKey.isNotEmpty}');
    debugPrint(
        '  - Has Gemini: ${geminiApiKey != null && geminiApiKey.isNotEmpty}');
    debugPrint(
        '  - Selected: ${useGroq ? 'Groq' : useGemini ? 'Gemini' : (openaiApiKey != null && openaiApiKey.isNotEmpty) ? 'OpenAI' : 'None'}');

    if (apiKey == null) {
      debugPrint('⚠️ No API key found, using rule-based suggestions');
      return _getRuleBasedSuggestions(analysis, existingGoals);
    }

    const systemPrompt =
        '''You are an expert swim coach AI that suggests personalized training goals.
Based on the swimmer's training history, personal records, and current time standards, suggest 2-4 SMART goals that will help them improve.

Consider:
1. Personal records and potential improvements
2. Time standards they can realistically achieve next
3. Balanced stroke development
4. Consistency and volume goals if training is irregular
5. Don't duplicate existing active goals

Each suggestion should include:
- title: Clear, motivating goal title
- goalType: One of "time", "distance", "frequency", "custom"
- stroke: Stroke name if applicable (omit if not applicable)
- distance: Distance in meters if applicable (omit if not applicable)
- targetTimeSeconds: Target time for time-based goals (omit if not applicable)
- targetDistance: Total distance for distance goals (omit if not applicable)
- targetFrequency: Number of sessions for frequency goals (omit if not applicable)
- frequencyPeriod: "week" or "month" - ONLY include this field when goalType is "frequency", otherwise omit it completely
- targetDate: Recommended date (YYYY-MM-DD format, 1-3 months from now)
- rationale: Brief explanation of why this goal is recommended
- priority: "high", "medium", or "low"

IMPORTANT: Only include fields that are relevant to the goalType. For example:
- If goalType is "time": include stroke, distance, targetTimeSeconds
- If goalType is "distance": include targetDistance
- If goalType is "frequency": include targetFrequency and frequencyPeriod
- If goalType is "custom": include only title, rationale, priority, targetDate
Do NOT include empty strings or zero values for fields that don't apply.''';

    final strokeBreakdownStr = analysis.strokeBreakdown.entries
        .map((e) => '${e.key}: ${e.value}m')
        .join(', ');

    final prsStr = analysis.personalRecords.map((pr) {
      final standard =
          pr.currentStandard != null ? ' [${pr.currentStandard}]' : '';
      final next = pr.nextStandard != null ? ' → Next: ${pr.nextStandard}' : '';
      return '- ${pr.distance}${pr.stroke} (${pr.poolType}): ${_formatTime(pr.bestTime)}$standard$next';
    }).join('\n');

    final existingGoalsStr = existingGoals.isEmpty
        ? 'None'
        : existingGoals
            .map((g) => '- ${g['title']} (${g['goal_type']})')
            .join('\n');

    final practiceImprovementStr = analysis.practiceImprovementSummary != null
        ? '\n- Practice improvement: ${analysis.practiceImprovementSummary}'
        : '';

    final userPrompt = '''Here's the swimmer's data:

Training Analysis:
- Total sets completed: ${analysis.totalSets}
- Average set distance: ${analysis.avgSetDistance}m
- Recent activity (last 30 days): ${analysis.recentActivity} sets
- Consistency score: ${analysis.consistencyScore}/100
- Stroke breakdown: $strokeBreakdownStr$practiceImprovementStr

Personal Records:
$prsStr

Existing Active Goals:
$existingGoalsStr

Please suggest 2-4 new training goals for this swimmer.''';

    try {
      http.Response response;

      if (useGemini) {
        debugPrint('🚀 Calling Gemini API...');
        response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        '$systemPrompt\n\n$userPrompt\n\nPlease respond with a JSON object containing a "suggestions" array with the goal suggestions.'
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'responseMimeType': 'application/json',
            },
          }),
        );
      } else if (useGroq) {
        debugPrint('🚀 Calling Groq API...');
        debugPrint('📤 Model: llama-3.3-70b-versatile');

        final groqStartTime = DateTime.now();
        response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'tools': [
              {
                'type': 'function',
                'function': {
                  'name': 'suggest_goals',
                  'description': 'Return training goal suggestions',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'suggestions': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'title': {'type': 'string'},
                            'goalType': {
                              'type': 'string',
                              'enum': [
                                'time',
                                'distance',
                                'frequency',
                                'custom'
                              ]
                            },
                            'stroke': {'type': 'string'},
                            'distance': {'type': 'number'},
                            'targetTimeSeconds': {'type': 'number'},
                            'targetDistance': {'type': 'number'},
                            'targetFrequency': {'type': 'number'},
                            'frequencyPeriod': {
                              'type': 'string',
                              'enum': ['week', 'month'],
                              'description':
                                  'Only include this field when goalType is \'frequency\'. Omit it for all other goal types.',
                            },
                            'targetDate': {'type': 'string'},
                            'rationale': {'type': 'string'},
                            'priority': {
                              'type': 'string',
                              'enum': ['high', 'medium', 'low']
                            },
                          },
                          'required': [
                            'title',
                            'goalType',
                            'rationale',
                            'priority'
                          ],
                        },
                      },
                    },
                    'required': ['suggestions'],
                  },
                },
              },
            ],
            'tool_choice': 'auto',
            'temperature': 0.7,
          }),
        );
        final groqEndTime = DateTime.now();
        debugPrint(
            '⏱️ Groq Response Time: ${groqEndTime.difference(groqStartTime).inMilliseconds}ms');
      } else {
        // OpenAI
        debugPrint('🚀 Calling OpenAI API...');
        debugPrint('📤 Model: gpt-4o-mini');

        final openaiStartTime = DateTime.now();
        response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'tools': [
              {
                'type': 'function',
                'function': {
                  'name': 'suggest_goals',
                  'description': 'Return training goal suggestions',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'suggestions': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'title': {'type': 'string'},
                            'goalType': {
                              'type': 'string',
                              'enum': [
                                'time',
                                'distance',
                                'frequency',
                                'custom'
                              ]
                            },
                            'stroke': {'type': 'string'},
                            'distance': {'type': 'number'},
                            'targetTimeSeconds': {'type': 'number'},
                            'targetDistance': {'type': 'number'},
                            'targetFrequency': {'type': 'number'},
                            'frequencyPeriod': {
                              'type': 'string',
                              'enum': ['week', 'month'],
                              'description':
                                  'Only include this field when goalType is \'frequency\'. Omit it for all other goal types.',
                            },
                            'targetDate': {'type': 'string'},
                            'rationale': {'type': 'string'},
                            'priority': {
                              'type': 'string',
                              'enum': ['high', 'medium', 'low']
                            },
                          },
                          'required': [
                            'title',
                            'goalType',
                            'rationale',
                            'priority'
                          ],
                        },
                      },
                    },
                    'required': ['suggestions'],
                  },
                },
              },
            ],
            'tool_choice': {
              'type': 'function',
              'function': {'name': 'suggest_goals'}
            },
          }),
        );
        final openaiEndTime = DateTime.now();
        debugPrint(
            '⏱️ OpenAI Response Time: ${openaiEndTime.difference(openaiStartTime).inMilliseconds}ms');
      }

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ AI API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return _getRuleBasedSuggestions(analysis, existingGoals);
      }

      debugPrint('📥 Parsing AI API response...');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('📊 Response keys: ${data.keys.toList()}');

      List<dynamic> suggestions;

      if (useGemini) {
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
        if (text != null) {
          final result = jsonDecode(text) as Map<String, dynamic>;
          suggestions = result['suggestions'] as List? ?? [];
        } else {
          debugPrint('⚠️ No text in Gemini response');
          return _getRuleBasedSuggestions(analysis, existingGoals);
        }
      } else {
        // OpenAI and Groq
        final toolCall = data['choices']?[0]?['message']?['tool_calls']?[0];
        if (toolCall != null && toolCall['function'] != null) {
          final arguments = toolCall['function']['arguments'] as String;
          final result = jsonDecode(arguments) as Map<String, dynamic>;
          suggestions = result['suggestions'] as List? ?? [];

          // Clean up suggestions: remove invalid frequencyPeriod values
          suggestions = suggestions.map((s) {
            final map = s as Map<String, dynamic>;
            if (map['goalType'] != 'frequency' ||
                map['frequencyPeriod'] == null ||
                map['frequencyPeriod'] == '') {
              final cleaned = Map<String, dynamic>.from(map);
              cleaned.remove('frequencyPeriod');
              return cleaned;
            }
            return map;
          }).toList();
        } else {
          debugPrint('⚠️ No tool call in response');
          debugPrint('📊 Full response: ${jsonEncode(data)}');
          return _getRuleBasedSuggestions(analysis, existingGoals);
        }
      }

      debugPrint('✅ Parsed ${suggestions.length} suggestions');

      return suggestions.map((s) {
        final map = s as Map<String, dynamic>;
        return GoalSuggestion.fromJson(map);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error calling AI API: $e');
      debugPrint('Stack trace: $stackTrace');
      return _getRuleBasedSuggestions(analysis, existingGoals);
    }
  }

  List<GoalSuggestion> _getRuleBasedSuggestions(
    TrainingAnalysis analysis,
    List<Map<String, dynamic>> existingGoals,
  ) {
    debugPrint('📋 Generating rule-based suggestions...');

    final suggestions = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final twoMonthsFromNow = now.add(const Duration(days: 60));

    // Consistency goal if not training regularly
    if (analysis.consistencyScore < 60 &&
        !existingGoals.any((g) => g['goal_type'] == 'frequency')) {
      suggestions.add({
        'title': 'Build Training Consistency',
        'goalType': 'frequency',
        'targetFrequency': 12,
        'frequencyPeriod': 'month',
        'targetDate': twoMonthsFromNow.toIso8601String().split('T')[0],
        'rationale':
            'Regular training is the foundation for improvement. Aim for 3 sessions per week.',
        'priority': 'high',
      });
    }

    // PR improvement goals
    final topPRs = analysis.personalRecords
        .where((pr) => pr.nextStandard != null)
        .take(2)
        .toList();

    for (final pr in topPRs) {
      if (!existingGoals.any(
          (g) => g['stroke'] == pr.stroke && g['distance'] == pr.distance)) {
        final improvement = pr.bestTime * 0.02; // 2% improvement
        suggestions.add({
          'title':
              '${pr.distance}${pr.stroke} - Reach ${pr.nextStandard} Standard',
          'goalType': 'time',
          'stroke': pr.stroke,
          'distance': pr.distance,
          'targetTimeSeconds': pr.bestTime - improvement,
          'targetDate': twoMonthsFromNow.toIso8601String().split('T')[0],
          'rationale':
              'Your current best is ${_formatTime(pr.bestTime)} (${pr.currentStandard ?? 'N/A'}). Target ${pr.nextStandard} standard.',
          'priority': 'high',
        });
      }
    }

    // Volume goal if training regularly
    if (analysis.consistencyScore >= 60 && analysis.avgSetDistance > 0) {
      final targetDistance =
          ((analysis.avgSetDistance * 20 / 1000).round() * 1000);
      if (!existingGoals.any((g) => g['goal_type'] == 'distance')) {
        suggestions.add({
          'title': 'Swim ${targetDistance}m Per Month',
          'goalType': 'distance',
          'targetDistance': targetDistance,
          'targetDate': twoMonthsFromNow.toIso8601String().split('T')[0],
          'rationale':
              'Build endurance and consistency with a monthly distance goal.',
          'priority': 'medium',
        });
      }
    }

    return suggestions.take(4).map((s) => GoalSuggestion.fromJson(s)).toList();
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).toStringAsFixed(2);
    return mins > 0 ? '$mins:${secs.padLeft(5, '0')}' : '${secs}s';
  }

  String _normalizeStroke(String strokeName) {
    final lower = strokeName.toLowerCase();
    if (lower.contains('free') || lower.contains('freestyle')) return 'Free';
    if (lower.contains('back') || lower.contains('backstroke')) return 'Back';
    if (lower.contains('breast') || lower.contains('breaststroke'))
      return 'Breast';
    if (lower.contains('fly') || lower.contains('butterfly')) return 'Fly';
    if (lower.contains('im') || lower.contains('individual medley'))
      return 'IM';
    return strokeName; // Return as-is if can't normalize
  }

  Future<String> analyzeGoalProgress({
    required String goalId,
    required String goalTitle,
    required double targetValue,
    required double currentValue,
    required String metric,
    required List<dynamic> milestones,
    required List<dynamic> recentEntries,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'analyze-goal-progress',
        body: {
          'goalId': goalId,
          'goalTitle': goalTitle,
          'targetValue': targetValue,
          'currentValue': currentValue,
          'metric': metric,
          'milestones': milestones,
          'recentEntries': recentEntries,
        },
      );

      final data = response.data;
      if (data == null) return "No analysis received from AI.";

      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      return data['analysis'] as String? ?? "No analysis generated.";
    } catch (e) {
      debugPrint('❌ Error calling analyze-goal-progress: $e');
      throw Exception('Failed to analyze progress: $e');
    }
  }
}
