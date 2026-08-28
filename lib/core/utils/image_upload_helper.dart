import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

/// Lets the user pick an image and uploads it to Cloudinary (unsigned preset).
/// Returns the hosted `secure_url`, or null if the user cancelled the picker.
/// Throws an [Exception] with a friendly message when Cloudinary isn't
/// configured or the upload fails, so callers can show it in a SnackBar.
Future<String?> pickAndUploadImage() async {
  if (!kCloudinaryConfigured) {
    throw Exception(
        'Image upload isn\'t set up yet. Add your Cloudinary cloud name and '
        'unsigned upload preset in lib/core/config/cloudinary_config.dart.');
  }

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1600,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final form = FormData.fromMap({
    'file': MultipartFile.fromBytes(bytes, filename: picked.name),
    'upload_preset': kCloudinaryUploadPreset,
  });

  try {
    final res = await Dio().post(
      'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload',
      data: form,
    );
    final url = res.data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Upload failed — no URL returned.');
    }
    return url;
  } on DioException catch (e) {
    final msg = e.response?.data is Map
        ? (e.response?.data['error']?['message'] ?? 'Upload failed')
        : 'Upload failed';
    throw Exception('$msg. Check your Cloudinary cloud name and unsigned preset.');
  }
}
