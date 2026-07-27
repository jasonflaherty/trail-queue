import 'package:equatable/equatable.dart';

class Crew extends Equatable {
  const Crew({
    required this.id,
    required this.name,
    this.description,
    this.leaderId,
    this.leaderName,
    this.memberCount = 0,
    this.organizationId,
    this.nextEventAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? leaderId;
  final String? leaderName;
  final int memberCount;
  final String? organizationId;
  final DateTime? nextEventAt;

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Crew',
      description: json['description'] as String?,
      leaderId: json['leader_id'] as String?,
      leaderName: json['leader_name'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      organizationId: json['organization_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, memberCount];
}

class CrewInvitation extends Equatable {
  const CrewInvitation({
    required this.id,
    required this.crewId,
    required this.crewName,
    required this.email,
    this.status = 'pending',
  });

  final String id;
  final String crewId;
  final String crewName;
  final String email;
  final String status;

  @override
  List<Object?> get props => [id, crewId, email, status];
}

class CrewMessage extends Equatable {
  const CrewMessage({
    required this.id,
    required this.crewId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String crewId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, body, createdAt];
}

class CrewCalendarEvent extends Equatable {
  const CrewCalendarEvent({
    required this.id,
    required this.crewId,
    required this.title,
    required this.startsAt,
    this.endsAt,
    this.locationLabel,
  });

  final String id;
  final String crewId;
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? locationLabel;

  @override
  List<Object?> get props => [id, title, startsAt];
}
