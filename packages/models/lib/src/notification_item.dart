import 'package:equatable/equatable.dart';

enum NotificationKind {
  nearbyIssue,
  crewInvitation,
  issueAssigned,
  verificationRequested,
  workdayReminder,
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.relatedId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? relatedId;

  @override
  List<Object?> get props => [id, kind, read];
}
