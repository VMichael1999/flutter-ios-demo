import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/strings/places_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/utils/geo.dart';
import '../../../places/domain/entities/place.dart';
import 'place_card.dart';

LatLng _toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);

/// Mapa pequeño dentro del chat con los lugares numerados y la ubicación del
/// usuario. Es fijo para no pelear con el scroll del chat; al tocarlo se abre
/// a pantalla completa.
class PlacesMap extends StatelessWidget {
  const PlacesMap({
    super.key,
    required this.places,
    this.userLocation,
    this.height = 190,
  });

  final List<Place> places;
  final GeoPoint? userLocation;
  final double height;

  /// En tests se reemplazan los mapas base para no descargar de internet.
  @visibleForTesting
  static TileProvider? debugTileProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: PlacesStrings.mapPreviewLabel(places.length),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: AppShapes.outlinedBox(scheme, radius: AppRadii.medium),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: _PlacesFlutterMap(
                    places: places,
                    userLocation: userLocation,
                    interactive: false,
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(onTap: () => _openFullScreen(context)),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    child: _MapChip(
                      icon: Icons.open_in_full_rounded,
                      label: PlacesStrings.expandMap,
                    ),
                  ),
                ),
                const Positioned(right: 6, bottom: 6, child: _Attribution()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => PlacesMapPage(places: places, userLocation: userLocation),
      ),
    );
  }
}

/// El mapa a pantalla completa: se puede mover, acercar y elegir un lugar.
class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({super.key, required this.places, this.userLocation});

  final List<Place> places;
  final GeoPoint? userLocation;

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final place = widget.places[_selected];

    return Scaffold(
      appBar: AppBar(title: const Text(PlacesStrings.mapTitle)),
      body: Stack(
        children: [
          _PlacesFlutterMap(
            places: widget.places,
            userLocation: widget.userLocation,
            interactive: true,
            selected: _selected,
            // Deja libre la parte de abajo, donde va la tarjeta del lugar.
            fitPadding: const EdgeInsets.fromLTRB(48, 48, 48, 230),
            onMarkerTap: (index) => setState(() => _selected = index),
          ),
          const Positioned(right: 8, top: 8, child: _Attribution()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: _SelectedPlace(
                // La tarjeta cambia con un fundido al elegir otro punto.
                key: ValueKey(place.id),
                place: place,
                number: _selected + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacesFlutterMap extends StatelessWidget {
  const _PlacesFlutterMap({
    required this.places,
    required this.userLocation,
    required this.interactive,
    this.selected,
    this.onMarkerTap,
    this.fitPadding = const EdgeInsets.all(40),
  });

  final List<Place> places;
  final GeoPoint? userLocation;
  final bool interactive;
  final int? selected;
  final ValueChanged<int>? onMarkerTap;

  /// Margen al encuadrar los puntos, para que ninguno quede tapado.
  final EdgeInsets fitPadding;

  @override
  Widget build(BuildContext context) {
    final userLocation = this.userLocation;
    final points = [
      for (final place in places) _toLatLng(place.location),
      if (userLocation != null) _toLatLng(userLocation),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: 15,
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          padding: fitPadding,
          maxZoom: 16,
        ),
        interactionOptions: InteractionOptions(
          flags:
              interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          // Sin clave. La política de uso de OpenStreetMap pide identificar
          // la app y mostrar la atribución.
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: AppConfig.appPackageName,
          tileProvider: PlacesMap.debugTileProvider,
        ),
        MarkerLayer(
          markers: [
            if (userLocation != null)
              Marker(
                point: _toLatLng(userLocation),
                width: 26,
                height: 26,
                child: const _UserMarker(),
              ),
            for (final (index, place) in places.indexed)
              Marker(
                point: _toLatLng(place.location),
                width: 34,
                height: 34,
                child: _PlaceMarker(
                  number: index + 1,
                  name: place.name,
                  isSelected: selected == index,
                  onTap: onMarkerTap == null ? null : () => onMarkerTap!(index),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({
    required this.number,
    required this.name,
    required this.isSelected,
    this.onTap,
  });

  final int number;
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: onTap != null,
      label: PlacesStrings.markerLabel(number, name),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1,
          duration: Motion.standard,
          curve: Motion.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected ? scheme.onSurface : scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mapMarkerBorder, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.mapMarkerShadow, blurRadius: 6),
              ],
            ),
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? scheme.surface : scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: PlacesStrings.userLocation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.mapUserLocation.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.mapUserLocation,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.mapMarkerBorder, width: 2),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlace extends StatelessWidget {
  const _SelectedPlace({super.key, required this.place, required this.number});

  final Place place;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 3,
      shape: AppShapes.outlinedCard(scheme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary,
                  child: Text(
                    '$number',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${place.category.displayName} · '
                        '${formatDistance(place.distanceMeters)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(iconForCategory(place.category), color: scheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => openDirections(place),
              icon: const Icon(Icons.directions_outlined),
              label: const Text(AppStrings.directions),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurface),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Atribución que exige OpenStreetMap.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mapAttributionBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          PlacesStrings.attribution,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: AppColors.mapAttributionText,
          ),
        ),
      ),
    );
  }
}
