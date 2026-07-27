enum UserRole {
  volunteer,
  crewLeader,
  organization,
  landManager,
  administrator;

  String get label => switch (this) {
        UserRole.volunteer => 'Volunteer',
        UserRole.crewLeader => 'Crew Leader',
        UserRole.organization => 'Organization',
        UserRole.landManager => 'Land Manager',
        UserRole.administrator => 'Administrator',
      };

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value || e.name.toLowerCase() == value.toLowerCase().replaceAll('_', ''),
      orElse: () => UserRole.volunteer,
    );
  }

  String toDb() => switch (this) {
        UserRole.crewLeader => 'crew_leader',
        UserRole.landManager => 'land_manager',
        _ => name,
      };
}

enum IssueType {
  blowdown,
  erosion,
  washout,
  missingBridgePlank,
  bridgeDamage,
  missingSign,
  brokenSign,
  brushOvergrowth,
  drainageBlocked,
  rockSlide,
  trailCollapse,
  hazardTree,
  vandalism,
  campsiteDamage,
  illegalTrail,
  other;

  String get label => switch (this) {
        IssueType.blowdown => 'Blowdown',
        IssueType.erosion => 'Erosion',
        IssueType.washout => 'Washout',
        IssueType.missingBridgePlank => 'Missing Bridge Plank',
        IssueType.bridgeDamage => 'Bridge Damage',
        IssueType.missingSign => 'Missing Sign',
        IssueType.brokenSign => 'Broken Sign',
        IssueType.brushOvergrowth => 'Brush Overgrowth',
        IssueType.drainageBlocked => 'Drainage Blocked',
        IssueType.rockSlide => 'Rock Slide',
        IssueType.trailCollapse => 'Trail Collapse',
        IssueType.hazardTree => 'Hazard Tree',
        IssueType.vandalism => 'Vandalism',
        IssueType.campsiteDamage => 'Campsite Damage',
        IssueType.illegalTrail => 'Illegal Trail',
        IssueType.other => 'Other',
      };

  /// Primary buckets shown on the Report Issue type grid.
  static const reportGrid = <IssueType>[
    IssueType.blowdown,
    IssueType.erosion,
    IssueType.washout,
    IssueType.bridgeDamage,
    IssueType.missingSign,
    IssueType.drainageBlocked,
    IssueType.rockSlide,
    IssueType.other,
  ];

  String get gridLabel => switch (this) {
        IssueType.bridgeDamage => 'Bridge',
        IssueType.missingSign => 'Sign / Kiosk',
        IssueType.drainageBlocked => 'Drainage',
        IssueType.rockSlide => 'Rock / Slide',
        _ => label,
      };
}

enum IssuePriority {
  low,
  medium,
  high,
  critical;

  String get label => switch (this) {
        IssuePriority.low => 'Low',
        IssuePriority.medium => 'Medium',
        IssuePriority.high => 'High',
        IssuePriority.critical => 'Critical',
      };
}

enum IssueStatus {
  open,
  assigned,
  scheduled,
  inProgress,
  needsVerification,
  closed;

  String get label => switch (this) {
        IssueStatus.open => 'Open',
        IssueStatus.assigned => 'Assigned',
        IssueStatus.scheduled => 'Scheduled',
        IssueStatus.inProgress => 'In Progress',
        IssueStatus.needsVerification => 'Needs Verification',
        IssueStatus.closed => 'Closed',
      };

  String toDb() => switch (this) {
        IssueStatus.inProgress => 'in_progress',
        IssueStatus.needsVerification => 'needs_verification',
        _ => name,
      };
}

enum AssetType {
  bridge,
  trailhead,
  gate,
  kiosk,
  sign,
  campsite,
  picnicArea,
  waterCrossing,
  boardwalk,
  parkingLot,
  toilet,
  bench;

  String get label => switch (this) {
        AssetType.bridge => 'Bridge',
        AssetType.trailhead => 'Trailhead',
        AssetType.gate => 'Gate',
        AssetType.kiosk => 'Kiosk',
        AssetType.sign => 'Sign',
        AssetType.campsite => 'Campsite',
        AssetType.picnicArea => 'Picnic Area',
        AssetType.waterCrossing => 'Water Crossing',
        AssetType.boardwalk => 'Boardwalk',
        AssetType.parkingLot => 'Parking Lot',
        AssetType.toilet => 'Toilet',
        AssetType.bench => 'Bench',
      };
}

enum TrailDifficulty {
  easy,
  moderate,
  difficult,
  expert;

  String get label => switch (this) {
        TrailDifficulty.easy => 'Easy',
        TrailDifficulty.moderate => 'Moderate',
        TrailDifficulty.difficult => 'Difficult',
        TrailDifficulty.expert => 'Expert',
      };
}

enum ImportSource {
  osm,
  usfs,
  nps,
  blm,
  oregon,
  washington,
  california,
  idaho,
  colorado;

  String get label => switch (this) {
        ImportSource.osm => 'OpenStreetMap',
        ImportSource.usfs => 'US Forest Service',
        ImportSource.nps => 'National Park Service',
        ImportSource.blm => 'BLM',
        ImportSource.oregon => 'Oregon GIS',
        ImportSource.washington => 'Washington GIS',
        ImportSource.california => 'California GIS',
        ImportSource.idaho => 'Idaho GIS',
        ImportSource.colorado => 'Colorado GIS',
      };
}

enum ImportJobStatus {
  pending,
  running,
  completed,
  failed,
}

enum MapFilter {
  allIssues,
  high,
  medium,
  low,
  trails;

  String get label => switch (this) {
        MapFilter.allIssues => 'All Issues',
        MapFilter.high => 'High',
        MapFilter.medium => 'Medium',
        MapFilter.low => 'Low',
        MapFilter.trails => 'Trails',
      };
}

enum BasemapType {
  osm,
  satellite,
  usgsTopo,
  terrain;

  String get label => switch (this) {
        BasemapType.osm => 'OpenStreetMap',
        BasemapType.satellite => 'Satellite',
        BasemapType.usgsTopo => 'USGS Topo',
        BasemapType.terrain => 'Terrain',
      };
}

enum MaintenanceGrade {
  excellent,
  needsAttention,
  significantBacklog,
  critical;

  String get label => switch (this) {
        MaintenanceGrade.excellent => 'Excellent',
        MaintenanceGrade.needsAttention => 'Needs Attention',
        MaintenanceGrade.significantBacklog => 'Significant Backlog',
        MaintenanceGrade.critical => 'Critical',
      };

  String get emoji => switch (this) {
        MaintenanceGrade.excellent => '🟢',
        MaintenanceGrade.needsAttention => '🟡',
        MaintenanceGrade.significantBacklog => '🟠',
        MaintenanceGrade.critical => '🔴',
      };
}
