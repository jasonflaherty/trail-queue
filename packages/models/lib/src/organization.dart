import 'package:equatable/equatable.dart';

enum OrganizationKind {
  nonprofit,
  association,
  trailBuilders,
  landAgency,
  volunteerNetwork;

  String get label => switch (this) {
        OrganizationKind.nonprofit => 'Nonprofit',
        OrganizationKind.association => 'Trail Association',
        OrganizationKind.trailBuilders => 'Trail Builders',
        OrganizationKind.landAgency => 'Land Manager / Agency',
        OrganizationKind.volunteerNetwork => 'Volunteer Network',
      };
}

class Organization extends Equatable {
  const Organization({
    required this.id,
    required this.name,
    this.description,
    this.approved = false,
    this.memberCount = 0,
    this.trailCount = 0,
    this.openWorkCount = 0,
    this.website,
    this.kind = OrganizationKind.nonprofit,
    this.region,
    this.acceptingVolunteers = true,
  });

  final String id;
  final String name;
  final String? description;
  final bool approved;
  final int memberCount;
  final int trailCount;
  final int openWorkCount;
  final String? website;
  final OrganizationKind kind;
  final String? region;
  final bool acceptingVolunteers;

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Organization',
      description: json['description'] as String?,
      approved: json['approved'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      trailCount: json['trail_count'] as int? ?? 0,
      openWorkCount: json['open_work_count'] as int? ?? 0,
      website: json['website'] as String?,
      region: json['region'] as String?,
      acceptingVolunteers: json['accepting_volunteers'] as bool? ?? true,
      kind: OrganizationKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => OrganizationKind.nonprofit,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'approved': approved,
        'member_count': memberCount,
        'trail_count': trailCount,
        'open_work_count': openWorkCount,
        'website': website,
        'kind': kind.name,
        'region': region,
        'accepting_volunteers': acceptingVolunteers,
      };

  @override
  List<Object?> get props => [id, name, approved, kind];
}

class DashboardStats extends Equatable {
  const DashboardStats({
    this.openIssues = 0,
    this.closedIssues = 0,
    this.volunteerHours = 0,
    this.milesRestored = 0,
    this.organizations = 0,
    this.activeCrews = 0,
    this.trailsMaintained = 0,
    this.avgResponseHours = 0,
  });

  final int openIssues;
  final int closedIssues;
  final double volunteerHours;
  final double milesRestored;
  final int organizations;
  final int activeCrews;
  final int trailsMaintained;
  final double avgResponseHours;

  @override
  List<Object?> get props =>
      [openIssues, closedIssues, volunteerHours, activeCrews];
}
