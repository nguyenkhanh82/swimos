import 'package:freezed_annotation/freezed_annotation.dart';
import '../../training/domain/stroke.dart';

part 'swim_time.freezed.dart';
part 'swim_time.g.dart';

@freezed
class SwimTime with _$SwimTime {
  const factory SwimTime({
    required String id,
    @JsonKey(name: 'swimmer_id') required String swimmerId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'event_name') String? eventName,
    required Stroke stroke,
    required int distance,
    @JsonKey(name: 'time_seconds') required double timeSeconds,
    required DateTime date,
    @JsonKey(name: 'meet_name') String? meetName,
    required String course, // 'SCY', 'SCM', or 'LCM'
    @JsonKey(name: 'is_personal_best') @Default(false) bool isPersonalBest,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _SwimTime;

  factory SwimTime.fromJson(Map<String, dynamic> json) =>
      _$SwimTimeFromJson(json);
}

extension SwimTimeExtension on SwimTime {
  /// Format time as MM:SS.CC or SS.CC
  String get formattedTime {
    final totalSeconds = timeSeconds;
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      return seconds.toStringAsFixed(2);
    }
  }

  /// Generate event name from stroke and distance
  String get generatedEventName {
    return '$distance ${stroke.value}';
  }
}
