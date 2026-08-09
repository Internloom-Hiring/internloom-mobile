import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_client_provider.dart';
import 'profile_service.dart' show ProfileWriteDeniedException;

/// Handles uploads to Supabase Storage. Returns the storage PATH
/// (e.g. `{profileId}/resume/{uuid}.pdf`), not a public URL — matches
/// `resume_path` / `college_id_path` being path-shaped columns in the
/// real schema, not full-URL columns. Construct a viewable URL from a
/// path only at display time, via `signedUrlFor(path)` below.
///
/// Uses a single `profile-uploads` bucket with a per-user, per-kind
/// folder structure so RLS storage policies can be written per-folder
/// — see supabase/student_profiles_schema.sql.
///
/// RLS note (per the Flutter Core Architecture doc, Section 15.3:
/// "Signed URLs with 1-hour expiry. No direct bucket access"): resumes
/// and college IDs are personal documents, so the bucket is private
/// and every read goes through `createSignedUrl` rather than
/// `getPublicUrl`. Uploads are still scoped to
/// `AppSupabase.currentUserId`'s own folder, matching the storage
/// policy in student_profiles_schema.sql
/// (`(storage.foldername(name))[1] = auth.uid()::text`).
class StorageService {
  static const _bucket = 'profile-uploads';
  static const _defaultSignedUrlExpirySeconds = 3600;
  final _uuid = const Uuid();

  Future<String> uploadResume(File file, {required String fileName}) =>
      _upload(kind: 'resume', file: file, preferredFileName: fileName);

  Future<String> uploadCollegeId(File file, {required String fileName}) =>
      _upload(kind: 'college-id', file: file, preferredFileName: fileName);

  Future<String> _upload({
    required String kind,
    required File file,
    String? preferredFileName,
  }) async {
    final profileId = AppSupabase.currentUserId;
    if (profileId == null) {
      throw ProfileWriteDeniedException('Not signed in — sign in before uploading a file.');
    }

    final ext = preferredFileName?.split('.').last ?? file.path.split('.').last;
    // Path always starts with the live session's own id, matching the
    // storage RLS policy's folder check — never a passed-in id, so an
    // upload can't accidentally target another user's folder.
    final path = '$profileId/$kind/${_uuid.v4()}.$ext';
    final bytes = await file.readAsBytes();

    try {
      await AppSupabase.client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      if (_isPermissionError(e)) {
        throw ProfileWriteDeniedException(
            'That upload was rejected by the server\'s security policy. Please sign in again and retry.');
      }
      rethrow;
    }

    return path;
  }

  /// A time-limited, authenticated URL for a private object — the
  /// bucket is not public, so `getPublicUrl` would return a link that
  /// 404s. Expires after [expiresIn] seconds (default 1 hour, per the
  /// Core Architecture doc).
  Future<String> signedUrlFor(String path, {int expiresIn = _defaultSignedUrlExpirySeconds}) async {
    try {
      return await AppSupabase.client.storage.from(_bucket).createSignedUrl(path, expiresIn);
    } on StorageException catch (e) {
      if (_isPermissionError(e)) {
        throw ProfileWriteDeniedException(
            'You don\'t have permission to access this file. Please sign in again.');
      }
      rethrow;
    }
  }

  bool _isPermissionError(StorageException e) =>
      e.statusCode == '403' || e.message.toLowerCase().contains('row-level security');

  /// The bit after the last `/` — used to show a human-readable file
  /// name in the UI since the schema has no separate *_file_name
  /// column (resume_path/college_id_path are the only source of
  /// truth).
  static String displayNameFor(String path) => path.split('/').last;
}
