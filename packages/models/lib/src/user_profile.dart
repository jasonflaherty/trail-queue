import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'enums.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.bio,
    this.roles = const [UserRole.volunteer],
    this.skills = const [],
    this.certifications = const [],
    this.equipment = const [],
    this.volunteerHours = 0,
    this.organizationIds = const [],
    this.badgeIds = const [],
    this.isAnonymous = false,
    this.hasCompletedOnboarding = true,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final List<UserRole> roles;
  final List<String> skills;
  final List<String> certifications;
  final List<String> equipment;
  final double volunteerHours;
  final List<String> organizationIds;
  final List<String> badgeIds;
  final bool isAnonymous;
  final bool hasCompletedOnboarding;

  UserRole get primaryRole =>
      roles.isEmpty ? UserRole.volunteer : roles.first;

  bool get isAdmin => roles.contains(UserRole.administrator);
  bool get canImport =>
      roles.contains(UserRole.administrator) ||
      roles.contains(UserRole.landManager) ||
      roles.contains(UserRole.organization);

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    List<UserRole>? roles,
    List<String>? skills,
    List<String>? certifications,
    List<String>? equipment,
    double? volunteerHours,
    List<String>? organizationIds,
    List<String>? badgeIds,
    bool? isAnonymous,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      roles: roles ?? this.roles,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      equipment: equipment ?? this.equipment,
      volunteerHours: volunteerHours ?? this.volunteerHours,
      organizationIds: organizationIds ?? this.organizationIds,
      badgeIds: badgeIds ?? this.badgeIds,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Volunteer',
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      volunteerHours: (json['volunteer_hours'] as num?)?.toDouble() ?? 0,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'email': email,
        'avatar_url': avatarUrl,
        'bio': bio,
        'volunteer_hours': volunteerHours,
        'is_anonymous': isAnonymous,
      };

  @override
  List<Object?> get props => [id, displayName, email, roles, volunteerHours];
}

class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  LatLng toLatLng() => LatLng(latitude, longitude);

  String get display =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  @override
  List<Object?> get props => [latitude, longitude];
}
