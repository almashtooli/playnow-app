import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/venue_service.dart';
import '../../theme/app_theme.dart';

class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({super.key});

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  LatLng? _pickedLocation;
  bool _loading = false;

  // Default center: Amman, Jordan
  final LatLng _defaultCenter = const LatLng(31.9539, 35.9106);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await context.read<VenueService>().createVenue(
        name: _nameController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).venueCreatedSuccess),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).addVenue),
      ),
      body: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context);
          return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(l.venueInfo, [
              _buildField(_nameController, l.venueNameLabel, required: true),
              const SizedBox(height: 12),
              _buildField(_cityController, l.cityLabel),
              const SizedBox(height: 12),
              _buildField(_addressController, l.addressLabel),
              const SizedBox(height: 12),
              _buildField(_descriptionController, l.descriptionLabel, maxLines: 3),
              const SizedBox(height: 12),
              _buildField(_imageUrlController, l.imageUrlLabel),
            ]),
            const SizedBox(height: 16),

            _buildSection(l.locationLabel, [
              Text(
                l.tapMapToSetLocation,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _defaultCenter,
                      initialZoom: 13,
                      onTap: (_, latLng) {
                        setState(() => _pickedLocation = latLng);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.playnow.app',
                      ),
                      if (_pickedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation!,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_pin,
                                color: context.errorColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_pickedLocation != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.greenTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.greenBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: context.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                        'Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  l.noLocationSelected,
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
            ]),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(l.createVenue, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? AppLocalizations.of(context).requiredField
              : null
          : null,
    );
  }
}
