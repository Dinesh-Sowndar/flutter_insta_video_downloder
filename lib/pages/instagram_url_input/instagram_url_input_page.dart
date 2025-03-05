import 'package:flutter/material.dart';
import 'package:insta_video_downloader/pages/instagram_reel_downloader/instagram_reel_downloader_page.dart';
import 'package:insta_video_downloader/pages/utils/permission_utils.dart';

class InstagramUrlInputPage extends StatefulWidget {
  const InstagramUrlInputPage({super.key});

  @override
  State<InstagramUrlInputPage> createState() => _InstagramUrlInputPageState();
}

class _InstagramUrlInputPageState extends State<InstagramUrlInputPage> {
  // Controller for handling text input
  final TextEditingController _urlController = TextEditingController();

  // Boolean to track if the entered URL is valid
  bool _isValidUrl = false;

  // Function to validate whether the entered URL is a valid Instagram Reel link
  void _validateUrl(String url) {
    setState(() {
      _isValidUrl = url.contains("www.instagram.com/reel");
    });
  }

  // Function to navigate to the download page if storage permission is granted
  void _navigateToDownloadPage() async {
    bool permitted = await PermissionUtil.requestStoragePermission();

    // Ensure widget is still mounted before proceeding
    if (!mounted) return;

    if (permitted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InstagramReelDownloaderPage(url: _urlController.text),
        ),
      );
    } else {
      // Show a snackbar if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission denied'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TextField for entering Instagram Reel URL
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Enter Instagram Reel URL',
                  border: OutlineInputBorder(),
                ),
                onChanged: _validateUrl, // Validate URL on change
              ),
              const SizedBox(height: 20),

              // Proceed button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValidUrl
                      ? _navigateToDownloadPage
                      : null, // Enable button only if URL is valid
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Proceed",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
