import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/venue_models.dart';
import '../../services/media_service.dart';
import '../../services/venue_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_widget.dart';

class MyVenueScreen extends StatefulWidget {
  const MyVenueScreen({super.key});

  @override
  State<MyVenueScreen> createState() => _MyVenueScreenState();
}

class _MyVenueScreenState extends State<MyVenueScreen> {
  Venue? _venue;
  bool _loading = true;
  String? _error;

  List<VenuePhoto> _photos = [];
  List<VenueVideo> _videos = [];
  bool _loadingMedia = false;

  @override
  void initState() {
    super.initState();
    _loadVenue();
  }

  Future<void> _loadVenue() async {
    try {
      final venues = await context.read<VenueService>().getMyVenues();
      if (!mounted) return;
      setState(() {
        _venue = venues.isNotEmpty ? venues.first : null;
        _loading = false;
      });
      if (_venue != null) _loadMedia();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMedia() async {
    if (_venue == null) return;
    setState(() => _loadingMedia = true);
    try {
      final media = context.read<MediaService>();
      final photos = await media.getPhotos(_venue!.id);
      final videos = await media.getVideos(_venue!.id);
      if (mounted) setState(() { _photos = photos; _videos = videos; _loadingMedia = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? _buildShimmer()
          : _error != null
              ? _buildError()
              : _venue == null
                  ? _buildNoVenue()
                  : _buildVenue(),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShimmerWidget.rounded(width: double.infinity, height: 250, radius: 0),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerWidget.rounded(width: double.infinity, height: 80, radius: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.errorColor),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadVenue, child: Text(AppLocalizations.of(context).retry)),
        ],
      ),
    );
  }

  Widget _buildNoVenue() {
    return Center(
      child: Text(AppLocalizations.of(context).noVenueYet, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildVenue() {
    final v = _venue!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            background: _photos.isNotEmpty
                ? Image.network(_photos.first.url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderHeader())
                : v.imageUrl != null && v.imageUrl!.isNotEmpty
                    ? Image.network(v.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderHeader())
                    : _placeholderHeader(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: [v.address, v.city]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(', '),
                ),
                const SizedBox(height: 12),
                if (v.description != null && v.description!.isNotEmpty) ...[
                  Text('Why Play Here?', style: context.tt.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor, width: 0.5),
                    ),
                    child: Text(v.description!,
                        style: TextStyle(fontSize: 14, height: 1.6, color: context.textPrimary)),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildMediaSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Media Section ──────────────────────────────────────────────────────────

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: context.tt.titleMedium),
            TextButton.icon(
              onPressed: _showAddPhotoDialog,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add Photo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingMedia)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => ShimmerWidget.rounded(width: 110, height: 110, radius: 12),
            ),
          )
        else if (_photos.isEmpty)
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.borderColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor, width: 0.5),
            ),
            child: Center(
              child: Text('No photos yet',
                  style: TextStyle(color: context.textHint, fontSize: 13)),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              onReorder: _reorderPhotos,
              itemCount: _photos.length,
              itemBuilder: (_, i) => _buildPhotoTile(_photos[i], i),
            ),
          ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Videos', style: context.tt.titleMedium),
            if (_videos.isEmpty)
              TextButton.icon(
                onPressed: _showAddVideoDialog,
                icon: const Icon(Icons.video_library_outlined, size: 18),
                label: const Text('Add Video'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_videos.isEmpty)
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.borderColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor, width: 0.5),
            ),
            child: Center(
              child: Text('No video yet',
                  style: TextStyle(color: context.textHint, fontSize: 13)),
            ),
          )
        else
          _buildVideoTile(_videos.first),
      ],
    );
  }

  Widget _buildPhotoTile(VenuePhoto photo, int index) {
    return ReorderableDragStartListener(
      key: ValueKey(photo.id),
      index: index,
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: photo.isCover ? context.primary : context.borderColor,
                width: photo.isCover ? 2 : 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(photo.url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: context.greenTint,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: context.textHint))),
            ),
          ),
          if (photo.isCover)
            Positioned(
              top: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Cover',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
          Positioned(
            bottom: 4, right: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!photo.isCover)
                  _miniBtn(Icons.star_border_rounded, () => _setCover(photo)),
                _miniBtn(Icons.delete_outline_rounded, () => _deletePhoto(photo),
                    color: context.errorColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTile(VenueVideo video) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: context.greenTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_circle_fill_rounded, color: context.primary, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title ?? 'Venue video',
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary)),
                if (video.titleAr != null)
                  Text(video.titleAr!,
                      style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.errorColor),
            onPressed: () => _deleteVideo(video),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color ?? Colors.white),
      ),
    );
  }

  // ── Photo actions ──────────────────────────────────────────────────────────

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
    // Update sort order on server
    final media = context.read<MediaService>();
    for (int i = 0; i < _photos.length; i++) {
      media.updatePhoto(_venue!.id, _photos[i].id, sortOrder: i).ignore();
    }
  }

  Future<void> _setCover(VenuePhoto photo) async {
    try {
      await context.read<MediaService>().setCover(_venue!.id, photo.id);
      await _loadMedia();
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  Future<void> _deletePhoto(VenuePhoto photo) async {
    final ok = await UiHelpers.confirm(context,
        title: 'Delete photo?',
        message: 'This photo will be permanently removed.',
        confirmText: 'Delete',
        confirmColor: context.errorColor);
    if (!ok || !mounted) return;
    try {
      await context.read<MediaService>().deletePhoto(_venue!.id, photo.id);
      await _loadMedia();
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  Future<void> _deleteVideo(VenueVideo video) async {
    final ok = await UiHelpers.confirm(context,
        title: 'Delete video?',
        message: 'This video will be permanently removed.',
        confirmText: 'Delete',
        confirmColor: context.errorColor);
    if (!ok || !mounted) return;
    try {
      await context.read<MediaService>().deleteVideo(_venue!.id, video.id);
      await _loadMedia();
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  // ── Add dialogs ────────────────────────────────────────────────────────────

  Future<void> _showAddPhotoDialog() async {
    // Step 1: pick image from device
    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    // Step 2: ask for optional captions
    final captionCtrl   = TextEditingController();
    final captionArCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview of selected image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(file.path),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Theme.of(ctx).colorScheme.surfaceVariant,
                    child: const Icon(Icons.image_outlined, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Caption (English)',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionArCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'التسمية (عربي)',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      captionCtrl.dispose();
      captionArCtrl.dispose();
      return;
    }

    // Step 3: upload
    try {
      await context.read<MediaService>().addPhoto(
        _venue!.id,
        file,
        caption:   captionCtrl.text.trim().isNotEmpty ? captionCtrl.text.trim() : null,
        captionAr: captionArCtrl.text.trim().isNotEmpty ? captionArCtrl.text.trim() : null,
      );
      if (mounted) _loadMedia();
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } finally {
      captionCtrl.dispose();
      captionArCtrl.dispose();
    }
  }

  void _showAddVideoDialog() {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Video'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Video URL *',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title (English)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleArCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان (عربي)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final url = urlCtrl.text.trim();
                      if (url.isEmpty) return;
                      setS(() => saving = true);
                      try {
                        await context.read<MediaService>().addVideo(
                              _venue!.id,
                              url,
                              title: titleCtrl.text.trim().isNotEmpty
                                  ? titleCtrl.text.trim()
                                  : null,
                              titleAr: titleArCtrl.text.trim().isNotEmpty
                                  ? titleArCtrl.text.trim()
                                  : null,
                            );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadMedia();
                        }
                      } on ApiException catch (e) {
                        setS(() => saving = false);
                        if (mounted) UiHelpers.showError(context, e.message);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((_) {
      urlCtrl.dispose();
      titleCtrl.dispose();
      titleArCtrl.dispose();
    });
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _placeholderHeader() {
    return Container(
      color: context.greenTint,
      child: Center(
        child: Icon(Icons.stadium, size: 80, color: context.primary.withOpacity(0.3)),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                Text(value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: context.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
