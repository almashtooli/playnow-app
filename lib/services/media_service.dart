import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/venue_models.dart';

class MediaService extends ChangeNotifier {
  // ── Photos ──────────────────────────────────────────────────────────────────

  Future<List<VenuePhoto>> getPhotos(int venueId) async {
    final json = await apiClient.get('/venues/$venueId/media/photos');
    final List data = json is List ? json : [];
    return data.map((e) => VenuePhoto.fromJson(e)).toList();
  }

  Future<VenuePhoto> addPhoto(
    int venueId,
    XFile file, {
    String? caption,
    String? captionAr,
    int sortOrder = 0,
  }) async {
    final json = await apiClient.uploadFile(
      '/venues/$venueId/media/photos',
      bytes: await file.readAsBytes(),
      filename: file.name,
      fieldName: 'file',
      fields: {
        if (caption != null) 'caption': caption,
        if (captionAr != null) 'captionAr': captionAr,
        'sortOrder': sortOrder.toString(),
      },
    );
    return VenuePhoto.fromJson(json);
  }

  Future<VenuePhoto> updatePhoto(
    int venueId,
    int photoId, {
    String? url,
    String? caption,
    String? captionAr,
    int? sortOrder,
  }) async {
    final json = await apiClient.put(
      '/venues/$venueId/media/photos/$photoId',
      body: {
        if (url != null) 'url': url,
        if (caption != null) 'caption': caption,
        if (captionAr != null) 'captionAr': captionAr,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
    return VenuePhoto.fromJson(json);
  }

  Future<void> deletePhoto(int venueId, int photoId) async {
    await apiClient.delete('/venues/$venueId/media/photos/$photoId');
  }

  Future<void> setCover(int venueId, int photoId) async {
    await apiClient.post('/venues/$venueId/media/photos/$photoId/set-cover');
  }

  // ── Videos ──────────────────────────────────────────────────────────────────

  Future<List<VenueVideo>> getVideos(int venueId) async {
    final json = await apiClient.get('/venues/$venueId/media/videos');
    final List data = json is List ? json : [];
    return data.map((e) => VenueVideo.fromJson(e)).toList();
  }

  Future<VenueVideo> addVideo(
    int venueId,
    String url, {
    String? thumbnailUrl,
    String? title,
    String? titleAr,
  }) async {
    final json = await apiClient.post(
      '/venues/$venueId/media/videos',
      body: {
        'url': url,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (title != null) 'title': title,
        if (titleAr != null) 'titleAr': titleAr,
      },
    );
    return VenueVideo.fromJson(json);
  }

  Future<VenueVideo> updateVideo(
    int venueId,
    int videoId, {
    String? url,
    String? thumbnailUrl,
    String? title,
    String? titleAr,
  }) async {
    final json = await apiClient.put(
      '/venues/$venueId/media/videos/$videoId',
      body: {
        if (url != null) 'url': url,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (title != null) 'title': title,
        if (titleAr != null) 'titleAr': titleAr,
      },
    );
    return VenueVideo.fromJson(json);
  }

  Future<void> deleteVideo(int venueId, int videoId) async {
    await apiClient.delete('/venues/$venueId/media/videos/$videoId');
  }
}
