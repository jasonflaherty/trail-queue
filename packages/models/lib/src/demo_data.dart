import 'package:latlong2/latlong.dart';

import 'asset.dart';
import 'crew.dart';
import 'enums.dart';
import 'issue.dart';
import 'notification_item.dart';
import 'organization.dart';
import 'trail.dart';
import 'user_profile.dart';

/// Demo / offline seed data so the UI is usable without a live Supabase project.
class DemoData {
  DemoData._();

  static const currentUser = UserProfile(
    id: 'user-alex',
    displayName: 'Alex',
    email: 'alex@trailqueue.dev',
    roles: [UserRole.volunteer, UserRole.crewLeader, UserRole.organization],
    skills: ['Crosscut saw', 'Drainage', 'Brushing'],
    certifications: ['Wilderness First Aid', 'USFS Crosscut A'],
    equipment: ['Loppers', 'Pulaski', 'Hand saw'],
    volunteerHours: 128,
    organizationIds: ['org-pcta'],
    badgeIds: ['badge-first-issue', 'badge-10-hours'],
  );

  static final trails = <Trail>[
    Trail(
      id: 'trail-bear-creek',
      name: 'Bear Creek Trail',
      agency: 'US Forest Service',
      lengthMiles: 6.2,
      elevationGainFt: 1240,
      difficulty: TrailDifficulty.moderate,
      surface: 'dirt',
      allowedUses: const ['Hiking', 'Mountain Bike'],
      trailNumber: '512',
      maintenanceLevel: '3',
      openIssueCount: 3,
      closedIssueCount: 12,
      maintenanceScore: 58,
      maintenanceGrade: MaintenanceGrade.needsAttention,
      geometry: const [
        LatLng(45.372, -121.698),
        LatLng(45.378, -121.705),
        LatLng(45.385, -121.712),
      ],
      source: ImportSource.usfs,
    ),
    Trail(
      id: 'trail-mirror-lake',
      name: 'Mirror Lake Trail',
      agency: 'US Forest Service',
      lengthMiles: 2.1,
      elevationGainFt: 180,
      difficulty: TrailDifficulty.easy,
      surface: 'gravel',
      allowedUses: const ['Hiking'],
      openIssueCount: 1,
      closedIssueCount: 8,
      maintenanceScore: 82,
      maintenanceGrade: MaintenanceGrade.excellent,
      geometry: const [
        LatLng(45.361, -121.712),
        LatLng(45.365, -121.718),
      ],
      source: ImportSource.osm,
    ),
    Trail(
      id: 'trail-timberline',
      name: 'Timberline Trail',
      agency: 'US Forest Service',
      lengthMiles: 40.7,
      elevationGainFt: 9000,
      difficulty: TrailDifficulty.difficult,
      allowedUses: const ['Hiking'],
      openIssueCount: 7,
      closedIssueCount: 44,
      maintenanceScore: 42,
      maintenanceGrade: MaintenanceGrade.significantBacklog,
      geometry: const [
        LatLng(45.331, -121.711),
        LatLng(45.340, -121.700),
        LatLng(45.350, -121.690),
      ],
      source: ImportSource.usfs,
    ),
    Trail(
      id: 'trail-lost-lake',
      name: 'Lost Lake Loop',
      agency: 'Oregon Parks',
      lengthMiles: 3.4,
      elevationGainFt: 220,
      difficulty: TrailDifficulty.easy,
      openIssueCount: 0,
      closedIssueCount: 5,
      maintenanceScore: 91,
      maintenanceGrade: MaintenanceGrade.excellent,
      geometry: const [
        LatLng(45.490, -121.820),
        LatLng(45.495, -121.825),
      ],
      source: ImportSource.oregon,
    ),
    Trail(
      id: 'trail-tamanawas',
      name: 'Tamanawas Falls',
      agency: 'US Forest Service',
      lengthMiles: 3.6,
      elevationGainFt: 500,
      difficulty: TrailDifficulty.moderate,
      openIssueCount: 2,
      closedIssueCount: 9,
      maintenanceScore: 65,
      maintenanceGrade: MaintenanceGrade.needsAttention,
      geometry: const [
        LatLng(45.395, -121.575),
        LatLng(45.400, -121.580),
      ],
      source: ImportSource.usfs,
    ),
  ];

  static final issues = <TrailIssue>[
    TrailIssue(
      id: 'issue-4821',
      issueNumber: 4821,
      title: 'Fallen Tree Across Trail',
      type: IssueType.blowdown,
      priority: IssuePriority.high,
      status: IssueStatus.open,
      location: const GeoPoint(45.376, -121.702),
      trailId: 'trail-bear-creek',
      trailName: 'Bear Creek Trail',
      description:
          'Large Douglas fir blocking the tread near mile 2.4. Needs crosscut saw and loppers. Clear bypass is muddy.',
      photoUrls: const [
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
      ],
      estimatedHours: 3,
      estimatedCrewSize: 2,
      estimatedDurationLabel: '2–4 hrs',
      requiredTools: const ['Crosscut saw', 'Loppers', 'Wedges'],
      reportedByName: 'Jordan Lee',
      agency: 'US Forest Service',
      trailUses: const ['Hiking', 'Mountain Bike'],
      distanceMiles: 2.3,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TrailIssue(
      id: 'issue-4822',
      issueNumber: 4822,
      title: 'Erosion on Switchback',
      type: IssueType.erosion,
      priority: IssuePriority.medium,
      status: IssueStatus.open,
      location: const GeoPoint(45.380, -121.708),
      trailId: 'trail-bear-creek',
      trailName: 'Bear Creek Trail',
      description:
          'Outslope failed on upper switchback. Needs drainage rebuild and tread rebuild.',
      photoUrls: const [
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      ],
      estimatedHours: 6,
      estimatedCrewSize: 4,
      estimatedDurationLabel: '4–6 hrs',
      requiredTools: const ['McLeod', 'Pulaski', 'Shovel'],
      reportedByName: 'Sam Ortiz',
      agency: 'US Forest Service',
      trailUses: const ['Hiking'],
      distanceMiles: 3.1,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TrailIssue(
      id: 'issue-4823',
      issueNumber: 4823,
      title: 'Missing Directional Sign',
      type: IssueType.missingSign,
      priority: IssuePriority.low,
      status: IssueStatus.open,
      location: const GeoPoint(45.363, -121.715),
      trailId: 'trail-mirror-lake',
      trailName: 'Mirror Lake Trail',
      description: 'Junction sign post is empty. Post intact.',
      photoUrls: const [
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
      ],
      estimatedHours: 1,
      estimatedCrewSize: 1,
      estimatedDurationLabel: '1–2 hrs',
      requiredTools: const ['Drill', 'Screws', 'Sign blank'],
      reportedByName: 'Alex',
      agency: 'US Forest Service',
      trailUses: const ['Hiking'],
      distanceMiles: 0.8,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TrailIssue(
      id: 'issue-4824',
      issueNumber: 4824,
      title: 'Bridge Plank Missing',
      type: IssueType.missingBridgePlank,
      priority: IssuePriority.critical,
      status: IssueStatus.assigned,
      location: const GeoPoint(45.398, -121.578),
      trailId: 'trail-tamanawas',
      trailName: 'Tamanawas Falls',
      description: 'Center plank missing on footbridge. Unsafe for stock and bikes.',
      photoUrls: const [
        'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800',
      ],
      estimatedHours: 4,
      estimatedCrewSize: 3,
      estimatedDurationLabel: '3–5 hrs',
      requiredTools: const ['Drill', 'Lag bolts', 'Replacement plank'],
      reportedByName: 'Casey Kim',
      agency: 'US Forest Service',
      trailUses: const ['Hiking'],
      distanceMiles: 5.4,
      safetyNotes: 'Do not cross center span until repaired.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static final assets = <TrailAsset>[
    TrailAsset(
      id: 'asset-th-1',
      type: AssetType.trailhead,
      name: 'Bear Creek Trailhead',
      trailId: 'trail-bear-creek',
      location: const GeoPoint(45.372, -121.698),
    ),
    TrailAsset(
      id: 'asset-bridge-1',
      type: AssetType.bridge,
      name: 'Cold Spring Bridge',
      trailId: 'trail-tamanawas',
      location: const GeoPoint(45.398, -121.578),
    ),
    TrailAsset(
      id: 'asset-kiosk-1',
      type: AssetType.kiosk,
      name: 'Mirror Lake Kiosk',
      trailId: 'trail-mirror-lake',
      location: const GeoPoint(45.361, -121.712),
    ),
  ];

  static final crews = <Crew>[
    Crew(
      id: 'crew-hood',
      name: 'Mt. Hood Saturday Crew',
      description: 'Weekly brushing and drainage on USFS trails.',
      leaderName: 'Alex',
      leaderId: 'user-alex',
      memberCount: 12,
      organizationId: 'org-pcta',
      nextEventAt: DateTime.now().add(const Duration(days: 4)),
    ),
    Crew(
      id: 'crew-columbia',
      name: 'Columbia Gorge Stewards',
      description: 'Weekend projects on state and FS lands.',
      leaderName: 'Riley Chen',
      memberCount: 8,
      organizationId: 'org-gorge',
      nextEventAt: DateTime.now().add(const Duration(days: 11)),
    ),
  ];

  static final organizations = <Organization>[
    const Organization(
      id: 'org-pcta',
      name: 'Pacific Crest Trail Association',
      description:
          'Connects volunteers with trail crews to maintain the PCT corridor and partner trails. Public reports help prioritize work.',
      approved: true,
      memberCount: 420,
      trailCount: 86,
      openWorkCount: 12,
      website: 'https://www.pcta.org',
      kind: OrganizationKind.association,
      region: 'Pacific Crest Trail',
      acceptingVolunteers: true,
    ),
    const Organization(
      id: 'org-gorge',
      name: 'Trailkeepers of Oregon',
      description:
          'Volunteer trail maintenance across Oregon. Partners with agencies and the public to keep trails open.',
      approved: true,
      memberCount: 210,
      trailCount: 54,
      openWorkCount: 8,
      kind: OrganizationKind.nonprofit,
      region: 'Oregon',
      acceptingVolunteers: true,
    ),
    const Organization(
      id: 'org-builders',
      name: 'Northwest Trail Alliance',
      description:
          'Trail builders and mountain bike stewards who design, build, and repair sustainable tread.',
      approved: true,
      memberCount: 180,
      trailCount: 32,
      openWorkCount: 5,
      kind: OrganizationKind.trailBuilders,
      region: 'Portland Metro',
      acceptingVolunteers: true,
    ),
    const Organization(
      id: 'org-usfs-mthood',
      name: 'Mt. Hood National Forest',
      description:
          'Land manager for Mt. Hood trails. Reviews public issue reports and coordinates partner organizations.',
      approved: true,
      memberCount: 45,
      trailCount: 120,
      openWorkCount: 18,
      kind: OrganizationKind.landAgency,
      region: 'Mt. Hood, OR',
      acceptingVolunteers: false,
    ),
  ];

  static final notifications = <NotificationItem>[
    NotificationItem(
      id: 'n1',
      kind: NotificationKind.nearbyIssue,
      title: 'New high-priority issue nearby',
      body: 'Fallen Tree Across Trail on Bear Creek Trail',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      relatedId: 'issue-4821',
    ),
    NotificationItem(
      id: 'n2',
      kind: NotificationKind.crewInvitation,
      title: 'Crew invitation',
      body: 'Riley invited you to Columbia Gorge Stewards',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      relatedId: 'crew-columbia',
    ),
    NotificationItem(
      id: 'n3',
      kind: NotificationKind.workdayReminder,
      title: 'Workday tomorrow',
      body: 'Mt. Hood Saturday Crew meets at 8:00 AM',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      relatedId: 'crew-hood',
    ),
  ];

  static final DashboardStats stats = DashboardStats(
    openIssues: issues.where((i) => i.status != IssueStatus.closed).length,
    closedIssues: 78,
    volunteerHours: 1240,
    milesRestored: 42.5,
    organizations: organizations.length,
    activeCrews: crews.length,
    trailsMaintained: trails.length,
    avgResponseHours: 36,
  );
}
