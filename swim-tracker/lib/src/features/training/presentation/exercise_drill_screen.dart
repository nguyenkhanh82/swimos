import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/training_session.dart';

class ExerciseDrillScreen extends ConsumerStatefulWidget {
  final TrainingSession setTemplate;

  const ExerciseDrillScreen({
    super.key,
    required this.setTemplate,
  });

  @override
  ConsumerState<ExerciseDrillScreen> createState() =>
      _ExerciseDrillScreenState();
}

class _ExerciseDrillScreenState extends ConsumerState<ExerciseDrillScreen> {
  final TextEditingController _notesController = TextEditingController();
  late final WebViewController _webViewController;

  int _elapsedSeconds = 0;
  int _totalSeconds = 0;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // To allow inline playback nicely on iOS if webview_flutter_wkwebview is hooked up, it usually respects playsinline property in HTML.
    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    // For Android to hide user action required
    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _loadVideo();

    // If it's interval based, we have a total timer. Otherwise a default or pure rep count.
    _totalSeconds = widget.setTemplate.getIntervalSeconds() ??
        widget.setTemplate.restSeconds ??
        60;
  }

  Future<void> _loadVideo() async {
    final isDryland = widget.setTemplate.stroke == 'Dryland';
    final query = Uri.encodeComponent(
        "${widget.setTemplate.setDescription} ${isDryland ? 'dryland exercise tutorial' : 'swimming drill tutorial'}");

    try {
      final client = HttpClient();
      final request = await client.getUrl(
          Uri.parse('https://www.youtube.com/results?search_query=$query'));
      request.headers.add('User-Agent', 'Mozilla/5.0');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      final regex = RegExp(r'"videoId":"([a-zA-Z0-9_-]{11})"');
      final match = regex.firstMatch(responseBody);

      String videoId = 'OUgsJ8-Vi0E'; // Fallback to basic generic video
      if (match != null) {
        videoId = match.group(1)!;
      }

      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body { background-color: #000000; margin: 0; padding: 0; height: 100vh; width: 100vw; overflow: hidden; }
    iframe { border: none; width: 100%; height: 100%; pointer-events: auto; }
  </style>
</head>
<body>
  <iframe src="https://www.youtube-nocookie.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1&enablejsapi=1&origin=https://www.youtube-nocookie.com" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</body>
</html>
''';
      if (mounted) {
        _webViewController.loadHtmlString(html,
            baseUrl: "https://www.youtube-nocookie.com");
      }
    } catch (e) {
      // Offline or error fallback
      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body { background-color: #000000; margin: 0; padding: 0; height: 100vh; overflow: hidden; }
    iframe { border: none; width: 100%; height: 100%; }
  </style>
</head>
<body>
  <iframe src="https://www.youtube-nocookie.com/embed/OUgsJ8-Vi0E?playsinline=1&rel=0&enablejsapi=1&origin=https://www.youtube-nocookie.com" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</body>
</html>
''';
      if (mounted) {
        _webViewController.loadHtmlString(html,
            baseUrl: "https://www.youtube-nocookie.com");
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showNotesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notes for Coach',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => context.pop(),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Add notes about your form, pain points, or questions...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {}, // Future AI refine implementation
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text('Refine with AI',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E5FF),
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final encodedBody =
                            Uri.encodeComponent(_notesController.text);
                        final url = Uri.parse('sms:?body=$encodedBody');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.sms, size: 18),
                      label: Text('Send SMS',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final encodedBody =
                            Uri.encodeComponent(_notesController.text);
                        final url = Uri.parse(
                            'mailto:?subject=Training Note&body=$encodedBody');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.email, size: 18),
                      label: Text('Email Coach',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDryland = widget.setTemplate.stroke == 'Dryland';

    // Parse equipment chips mockingly from notes or assume general for now
    List<String> equipment = ['Goggles'];
    if (isDryland) {
      if (widget.setTemplate.notes?.contains('Band') == true) {
        equipment.add('Stretch Band');
      }
      if (widget.setTemplate.notes?.contains('Gym') == true) {
        equipment.add('Weights');
      }
      if (equipment.length == 1) equipment.add('Bodyweight'); // default dryland
    } else {
      if (widget.setTemplate.setDescription.toLowerCase().contains('pull')) {
        equipment.add('Pull Buoy');
      }
      if (widget.setTemplate.setDescription.toLowerCase().contains('kick')) {
        equipment.add('Kickboard');
      }
      if (equipment.length == 1) equipment.add('Swim Cap');
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF001B33),
            Color(0xFF000B1A)
          ], // Deep dark aquatic blue gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(widget.setTemplate.stroke,
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            // Youtube Player Header
            Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: WebViewWidget(
                controller: _webViewController,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.setTemplate.setDescription,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Equipment List
                    Text(
                      'EQUIPMENT NEEDED',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          equipment.map((e) => _buildEquipmentChip(e)).toList(),
                    ),

                    const SizedBox(height: 48),

                    // Circular Timer
                    Center(
                      child: CircularPercentIndicator(
                        radius: 100.0,
                        lineWidth: 12.0,
                        animation: false,
                        percent: _totalSeconds == 0
                            ? 0
                            : (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0),
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isDryland && _totalSeconds == 0
                                  ? '${widget.setTemplate.numberOfReps}'
                                  : '${(_totalSeconds - _elapsedSeconds).toString().padLeft(2, '0')}',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 48,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isDryland && _totalSeconds == 0
                                  ? 'Reps'
                                  : 'Seconds left',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        linearGradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Float Up Notes Button
                    InkWell(
                      onTap: _showNotesModal,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, color: Colors.white54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _notesController.text.isEmpty
                                    ? 'Add notes for your coach...'
                                    : _notesController.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: _notesController.text.isEmpty
                                      ? Colors.white54
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Done Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0055FF)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop(); // Return to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentChip(String name) {
    IconData getIcon() {
      if (name.contains('Band')) {
        return Icons.fitness_center;
      }
      if (name.contains('Buoy') || name.contains('Kickboard')) {
        return Icons.surfing;
      }
      if (name.contains('Weights') || name.contains('Gym')) {
        return Icons.sports_gymnastics;
      }
      return Icons.pool;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(), color: const Color(0xFF00E5FF), size: 24),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
