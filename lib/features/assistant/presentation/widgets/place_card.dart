import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/geo.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/entities/place_category.dart';

/// Ruta en Google Maps hasta [place] (web, Android e iOS).
Uri directionsUri(Place place) => Uri.https('www.google.com', '/maps/dir/', {
  'api': '1',
  'destination': '${place.location.latitude},${place.location.longitude}',
});

Future<void> openDirections(Place place) async {
  await launchUrl(directionsUri(place), mode: LaunchMode.externalApplication);
}

IconData iconForCategory(PlaceCategory category) => switch (category) {
  PlaceCategory.restaurant || PlaceCategory.fastFood => Icons.restaurant,
  PlaceCategory.cafe => Icons.local_cafe_outlined,
  PlaceCategory.bar => Icons.local_bar_outlined,
  PlaceCategory.pharmacy => Icons.local_pharmacy_outlined,
  PlaceCategory.hospital => Icons.local_hospital_outlined,
  PlaceCategory.bank || PlaceCategory.atm => Icons.account_balance_outlined,
  PlaceCategory.fuel => Icons.local_gas_station_outlined,
  PlaceCategory.supermarket => Icons.local_grocery_store_outlined,
  PlaceCategory.park => Icons.park_outlined,
  PlaceCategory.hotel => Icons.hotel_outlined,
};

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.onDirections,
    this.number,
  });

  final Place place;
  final VoidCallback? onDirections;

  /// Número del punto en el mapa. Sin número se muestra el ícono del tipo.
  final int? number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final number = this.number;
    final details = [
      place.category.displayName,
      if (place.address != null) place.address!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDirections,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              if (number == null)
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    iconForCategory(place.category),
                    color: scheme.onPrimaryContainer,
                  ),
                )
              else
                CircleAvatar(
                  backgroundColor: scheme.primary,
                  child: Text(
                    '$number',
                    semanticsLabel: 'Punto $number del mapa',
                    style: theme.textTheme.titleSmall?.copyWith(
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDistance(place.distanceMeters),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Cómo llegar',
                icon: const Icon(Icons.directions_outlined),
                onPressed: onDirections,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
