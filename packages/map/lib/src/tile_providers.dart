import 'package:flutter_map/flutter_map.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

/// Tile URL templates and helpers for supported basemaps.
abstract final class TileProviders {
  static const osmUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const esriSatelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  static const usgsTopoUrl =
      'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}';

  static const openTopoMapUrl =
      'https://tile.opentopomap.org/{z}/{x}/{y}.png';

  static String urlFor(BasemapType type) => switch (type) {
        BasemapType.osm => osmUrl,
        BasemapType.satellite => esriSatelliteUrl,
        BasemapType.usgsTopo => usgsTopoUrl,
        BasemapType.terrain => openTopoMapUrl,
      };

  static TileLayer tileLayer(BasemapType type) {
    return TileLayer(
      urlTemplate: urlFor(type),
      userAgentPackageName: 'com.trailqueue.trail_queue',
      maxZoom: 19,
    );
  }

  static List<BasemapType> get all => BasemapType.values;
}
