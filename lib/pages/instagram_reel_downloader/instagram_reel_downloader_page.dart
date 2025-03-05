import 'package:flutter/material.dart';
import 'package:insta_video_downloader/pages/instagram_reel_downloader/widgets/download_dialog_widget.dart';
import 'package:insta_video_downloader/pages/instagram_reel_downloader/widgets/loading_widget.dart';
import 'package:insta_video_downloader/pages/instagram_reel_downloader/widgets/not_found_widget.dart';
import 'package:insta_video_downloader/pages/utils/permission_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InstagramReelDownloaderPage extends StatefulWidget {
  final String url;

  const InstagramReelDownloaderPage({super.key, required this.url});

  @override
  State<InstagramReelDownloaderPage> createState() =>
      _InstagramReelDownloaderPageState();
}

class _InstagramReelDownloaderPageState
    extends State<InstagramReelDownloaderPage> {
  // WebViewController to manage the WebView
  late final WebViewController _controller;

  // Variables to store video and thumbnail URLs
  String _videoUrl = '';
  String _thumbnailUrl = '';

  // State variables to track loading and downloading status
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();

    // Initialize WebView and load the given Instagram Reel URL
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..loadRequest(Uri.parse(widget.url.split('?').first)) // Load the URL
      ..setUserAgent(
          "Mozilla/5.0 (Linux; U; Android 4.0.2; en-us; Galaxy Nexus Build/ICL53F) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30")
      ..addJavaScriptChannel('VideoExtractor', onMessageReceived: (message) {
        // Extract video and thumbnail URLs from the JavaScript message
        final data = message.message.split('|');
        setState(() {
          _videoUrl = data[0];
          _thumbnailUrl = data.length > 1 ? data[1] : 'Not Found';
          _isLoading = false;
        });
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          // Parse video when the page loading completes
          if (progress == 100) {
            _parseVideo();
          }
        },
      ));
  }

  // JavaScript function to extract video and thumbnail URLs from the Instagram page
  Future<void> _parseVideo() async {
    const script = '''
    function extractVideoData() {
      const videoElement = document.querySelector('video');
      const thumbnailElement = document.querySelector('meta[property="og:image"]');
      const videoSrc = videoElement ? videoElement.src : 'no_video';
      const thumbnailSrc = thumbnailElement ? thumbnailElement.content : 'no_thumbnail';
      VideoExtractor.postMessage(videoSrc + '|' + thumbnailSrc);
    }
    const observer = new MutationObserver(() => extractVideoData());
    observer.observe(document.body, { childList: true, subtree: true });
    extractVideoData();
    ''';
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      print('Error: $e');
    }
  }

  // Function to handle video download
  Future<void> _downloadVideo() async {
    // Show error message if no video URL is found
    if (_videoUrl.isEmpty || _videoUrl == 'no_video') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No video URL found!"), backgroundColor: Colors.red),
      );
      return;
    }

    // Request storage permission
    bool permitted = await PermissionUtil.requestStoragePermission();
    if (!mounted) return;
    if (!permitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Storage permission denied'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Start download process
    setState(() {
      _isDownloading = true;
    });

    // Show download dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while downloading
      builder: (context) {
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: DownloadDialogWidget(
                videoUrl: _videoUrl,
                isDownloaded: () => setState(() {
                      _isDownloading = false;
                    })));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instagram Reel Downloader')),
      body: _isLoading
          ? const LoadingWidget() // Show loading widget while fetching video
          : (_videoUrl.isEmpty || _videoUrl == 'no_video')
              ? const NotFoundWidget() // Show error widget if no video is found
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Display video thumbnail if available
                      if (_thumbnailUrl.isNotEmpty &&
                          _thumbnailUrl != 'Not Found')
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 500,
                              child: Image.network(_thumbnailUrl,
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isDownloading
                                ? null
                                : _downloadVideo, // Disable button while downloading
                            child: const Text(
                              "Download",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
