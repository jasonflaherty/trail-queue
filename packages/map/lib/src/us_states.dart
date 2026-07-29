/// US states as downloadable offline work regions.
class UsStateRegion {
  const UsStateRegion({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMiles,
  });

  final String code;
  final String name;
  final double latitude;
  final double longitude;

  /// Approximate covering radius for caching trail work data.
  final double radiusMiles;

  String get label => '$name ($code)';
}

/// Catalog of downloadable state regions (geographic centers + cover radius).
abstract final class UsStateRegions {
  static const all = <UsStateRegion>[
    UsStateRegion(
        code: 'AL',
        name: 'Alabama',
        latitude: 32.81,
        longitude: -86.79,
        radiusMiles: 180),
    UsStateRegion(
        code: 'AK',
        name: 'Alaska',
        latitude: 64.20,
        longitude: -149.49,
        radiusMiles: 500),
    UsStateRegion(
        code: 'AZ',
        name: 'Arizona',
        latitude: 34.27,
        longitude: -111.66,
        radiusMiles: 220),
    UsStateRegion(
        code: 'AR',
        name: 'Arkansas',
        latitude: 34.89,
        longitude: -92.44,
        radiusMiles: 160),
    UsStateRegion(
        code: 'CA',
        name: 'California',
        latitude: 37.18,
        longitude: -119.47,
        radiusMiles: 320),
    UsStateRegion(
        code: 'CO',
        name: 'Colorado',
        latitude: 39.00,
        longitude: -105.55,
        radiusMiles: 200),
    UsStateRegion(
        code: 'CT',
        name: 'Connecticut',
        latitude: 41.62,
        longitude: -72.73,
        radiusMiles: 60),
    UsStateRegion(
        code: 'DE',
        name: 'Delaware',
        latitude: 38.99,
        longitude: -75.51,
        radiusMiles: 45),
    UsStateRegion(
        code: 'FL',
        name: 'Florida',
        latitude: 28.63,
        longitude: -82.45,
        radiusMiles: 250),
    UsStateRegion(
        code: 'GA',
        name: 'Georgia',
        latitude: 32.66,
        longitude: -83.44,
        radiusMiles: 180),
    UsStateRegion(
        code: 'HI',
        name: 'Hawaii',
        latitude: 20.29,
        longitude: -156.37,
        radiusMiles: 180),
    UsStateRegion(
        code: 'ID',
        name: 'Idaho',
        latitude: 44.35,
        longitude: -114.61,
        radiusMiles: 250),
    UsStateRegion(
        code: 'IL',
        name: 'Illinois',
        latitude: 40.04,
        longitude: -89.20,
        radiusMiles: 180),
    UsStateRegion(
        code: 'IN',
        name: 'Indiana',
        latitude: 39.89,
        longitude: -86.28,
        radiusMiles: 140),
    UsStateRegion(
        code: 'IA',
        name: 'Iowa',
        latitude: 42.08,
        longitude: -93.50,
        radiusMiles: 160),
    UsStateRegion(
        code: 'KS',
        name: 'Kansas',
        latitude: 38.50,
        longitude: -98.32,
        radiusMiles: 200),
    UsStateRegion(
        code: 'KY',
        name: 'Kentucky',
        latitude: 37.53,
        longitude: -85.29,
        radiusMiles: 180),
    UsStateRegion(
        code: 'LA',
        name: 'Louisiana',
        latitude: 31.07,
        longitude: -92.02,
        radiusMiles: 160),
    UsStateRegion(
        code: 'ME',
        name: 'Maine',
        latitude: 45.37,
        longitude: -69.24,
        radiusMiles: 180),
    UsStateRegion(
        code: 'MD',
        name: 'Maryland',
        latitude: 39.05,
        longitude: -76.79,
        radiusMiles: 100),
    UsStateRegion(
        code: 'MA',
        name: 'Massachusetts',
        latitude: 42.26,
        longitude: -71.81,
        radiusMiles: 80),
    UsStateRegion(
        code: 'MI',
        name: 'Michigan',
        latitude: 44.35,
        longitude: -85.41,
        radiusMiles: 220),
    UsStateRegion(
        code: 'MN',
        name: 'Minnesota',
        latitude: 46.28,
        longitude: -94.31,
        radiusMiles: 220),
    UsStateRegion(
        code: 'MS',
        name: 'Mississippi',
        latitude: 32.74,
        longitude: -89.68,
        radiusMiles: 160),
    UsStateRegion(
        code: 'MO',
        name: 'Missouri',
        latitude: 38.36,
        longitude: -92.48,
        radiusMiles: 180),
    UsStateRegion(
        code: 'MT',
        name: 'Montana',
        latitude: 47.05,
        longitude: -109.63,
        radiusMiles: 300),
    UsStateRegion(
        code: 'NE',
        name: 'Nebraska',
        latitude: 41.54,
        longitude: -99.79,
        radiusMiles: 200),
    UsStateRegion(
        code: 'NV',
        name: 'Nevada',
        latitude: 39.33,
        longitude: -116.63,
        radiusMiles: 250),
    UsStateRegion(
        code: 'NH',
        name: 'New Hampshire',
        latitude: 43.68,
        longitude: -71.58,
        radiusMiles: 80),
    UsStateRegion(
        code: 'NJ',
        name: 'New Jersey',
        latitude: 40.19,
        longitude: -74.67,
        radiusMiles: 80),
    UsStateRegion(
        code: 'NM',
        name: 'New Mexico',
        latitude: 34.41,
        longitude: -106.11,
        radiusMiles: 220),
    UsStateRegion(
        code: 'NY',
        name: 'New York',
        latitude: 42.95,
        longitude: -75.53,
        radiusMiles: 200),
    UsStateRegion(
        code: 'NC',
        name: 'North Carolina',
        latitude: 35.56,
        longitude: -79.39,
        radiusMiles: 200),
    UsStateRegion(
        code: 'ND',
        name: 'North Dakota',
        latitude: 47.45,
        longitude: -100.47,
        radiusMiles: 180),
    UsStateRegion(
        code: 'OH',
        name: 'Ohio',
        latitude: 40.29,
        longitude: -82.79,
        radiusMiles: 140),
    UsStateRegion(
        code: 'OK',
        name: 'Oklahoma',
        latitude: 35.59,
        longitude: -97.51,
        radiusMiles: 200),
    UsStateRegion(
        code: 'OR',
        name: 'Oregon',
        latitude: 43.93,
        longitude: -120.56,
        radiusMiles: 250),
    UsStateRegion(
        code: 'PA',
        name: 'Pennsylvania',
        latitude: 40.88,
        longitude: -77.80,
        radiusMiles: 160),
    UsStateRegion(
        code: 'RI',
        name: 'Rhode Island',
        latitude: 41.68,
        longitude: -71.56,
        radiusMiles: 40),
    UsStateRegion(
        code: 'SC',
        name: 'South Carolina',
        latitude: 33.92,
        longitude: -80.90,
        radiusMiles: 140),
    UsStateRegion(
        code: 'SD',
        name: 'South Dakota',
        latitude: 44.44,
        longitude: -100.23,
        radiusMiles: 200),
    UsStateRegion(
        code: 'TN',
        name: 'Tennessee',
        latitude: 35.86,
        longitude: -86.35,
        radiusMiles: 180),
    UsStateRegion(
        code: 'TX',
        name: 'Texas',
        latitude: 31.17,
        longitude: -99.68,
        radiusMiles: 400),
    UsStateRegion(
        code: 'UT',
        name: 'Utah',
        latitude: 39.32,
        longitude: -111.09,
        radiusMiles: 200),
    UsStateRegion(
        code: 'VT',
        name: 'Vermont',
        latitude: 44.07,
        longitude: -72.67,
        radiusMiles: 80),
    UsStateRegion(
        code: 'VA',
        name: 'Virginia',
        latitude: 37.52,
        longitude: -78.85,
        radiusMiles: 180),
    UsStateRegion(
        code: 'WA',
        name: 'Washington',
        latitude: 47.38,
        longitude: -120.45,
        radiusMiles: 200),
    UsStateRegion(
        code: 'WV',
        name: 'West Virginia',
        latitude: 38.64,
        longitude: -80.62,
        radiusMiles: 120),
    UsStateRegion(
        code: 'WI',
        name: 'Wisconsin',
        latitude: 44.63,
        longitude: -89.83,
        radiusMiles: 180),
    UsStateRegion(
        code: 'WY',
        name: 'Wyoming',
        latitude: 43.00,
        longitude: -107.55,
        radiusMiles: 220),
  ];

  /// Trail-heavy western states shown first in the picker.
  static const trailPriorityCodes = {
    'OR',
    'WA',
    'CA',
    'ID',
    'CO',
    'UT',
    'MT',
    'WY',
    'AZ',
    'NM',
    'NV',
    'AK',
  };

  static List<UsStateRegion> get prioritized {
    final priority = all
        .where((s) => trailPriorityCodes.contains(s.code))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final rest = all
        .where((s) => !trailPriorityCodes.contains(s.code))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return [...priority, ...rest];
  }
}
