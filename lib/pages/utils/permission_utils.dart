import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.videos.request();
      return status.isGranted;
    }
    return true; // iOS does not require storage permissions
  }
}