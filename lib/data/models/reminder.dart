import 'dart:convert';

/// Reminder type
enum ReminderType { exam, homework, meeting, other }

/// Priority: 0=low, 1=medium, 2=high. null = medium.
/// ADDITIVE: Optional fields for remindersRecurring, remindersPriority, remindersLinkToEntity.
class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? classId;
  final bool notified;
  final DateTime createdAt;
  // ADDITIVE: Optional extensions
  final int? priority; // 0=low, 1=medium, 2=high
  final String? recurringRule; // daily, weekly, monthly, yearly
  final String? linkedEntityType; // course, dailyPlan, committeeTask
  final String? linkedEntityId;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.dateTime,
    this.classId,
    required this.notified,
    required this.createdAt,
    this.priority,
    this.recurringRule,
    this.linkedEntityType,
    this.linkedEntityId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
        'classId': classId,
        'notified': notified,
        'createdAt': createdAt.toIso8601String(),
        if (priority != null) 'priority': priority,
        if (recurringRule != null) 'recurringRule': recurringRule,
        if (linkedEntityType != null) 'linkedEntityType': linkedEntityType,
        if (linkedEntityId != null) 'linkedEntityId': linkedEntityId,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        type: ReminderType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ReminderType.other,
        ),
        title: json['title'] as String,
        description: json['description'] as String?,
        dateTime: DateTime.parse(json['dateTime'] as String),
        classId: json['classId'] as String?,
        notified: json['notified'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        priority: json['priority'] as int?,
        recurringRule: json['recurringRule'] as String?,
        linkedEntityType: json['linkedEntityType'] as String?,
        linkedEntityId: json['linkedEntityId'] as String?,
      );

  Reminder copyWith({
    ReminderType? type,
    String? title,
    String? description,
    DateTime? dateTime,
    String? classId,
    bool? notified,
    int? priority,
    String? recurringRule,
    String? linkedEntityType,
    String? linkedEntityId,
  }) =>
      Reminder(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        dateTime: dateTime ?? this.dateTime,
        classId: classId ?? this.classId,
        notified: notified ?? this.notified,
        createdAt: createdAt,
        priority: priority ?? this.priority,
        recurringRule: recurringRule ?? this.recurringRule,
        linkedEntityType: linkedEntityType ?? this.linkedEntityType,
        linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      );
}
