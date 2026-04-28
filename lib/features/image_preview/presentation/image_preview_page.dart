import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ripple/const/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// Entry point — call this from _AttachMenu camera/gallery tap
// ─────────────────────────────────────────────────────────────
Future<void> openImagePreview({
  required BuildContext context,
  required ImageSource source,
  required Function(File file, String caption) onSend,
}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source);
  if (picked == null) return;

  if (!context.mounted) return;
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, anim, __) => FadeTransition(
        opacity: anim,
        child: ImagePreviewPage(
          imageFile: File(picked.path),
          onSend: onSend,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Image Preview Page
// ─────────────────────────────────────────────────────────────
class ImagePreviewPage extends StatefulWidget {
  final File imageFile;
  final Function(File file, String caption) onSend;

  const ImagePreviewPage({
    required this.imageFile,
    required this.onSend,
    super.key,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage>
    with TickerProviderStateMixin {
  // Quality
  double _quality = 80;
  int _estimatedKB = 0;
  File? _previewFile;
  bool _isProcessing = false;

  // Caption
  final _captionController = TextEditingController();
  final _captionFocus = FocusNode();
  bool _showCaption = false;

  // Draw on image
  bool _drawMode = false;
  final List<DrawStroke> _strokes = [];
  DrawStroke? _currentStroke;
  Color _penColor = Colors.redAccent;
  double _penWidth = 3.0;
  final GlobalKey _canvasKey = GlobalKey();

  // Zoom/pan
  final TransformationController _transformController =
      TransformationController();

  // Unique: blur background toggle
  bool _blurBackground = false;

  // Unique: timer to debounce quality preview
  Timer? _qualityDebounce;

  // Unique: emoji stamp mode
  bool _stampMode = false;
  final List<_EmojiStamp> _stamps = [];
  String _selectedEmoji = '❤️';

  // Unique: image info
  late int _originalBytes;
  late int _width;
  late int _height;

  // Send animation
  late AnimationController _sendController;
  late Animation<double> _sendAnim;

  @override
  void initState() {
    super.initState();
    _sendController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sendAnim = CurvedAnimation(
      parent: _sendController,
      curve: Curves.easeInBack,
    );
    _initImageInfo();
  }

  Future<void> _initImageInfo() async {
    final bytes = await widget.imageFile.readAsBytes();
    _originalBytes = bytes.length;
    _estimatedKB = (_originalBytes * (_quality / 100) / 1024).round();

    final decoded = await decodeImageFromList(bytes);
    setState(() {
      _width = decoded.width;
      _height = decoded.height;
    });
    _previewFile = widget.imageFile;
    setState(() {});
  }

  @override
  void dispose() {
    _qualityDebounce?.cancel();
    _captionController.dispose();
    _captionFocus.dispose();
    _transformController.dispose();
    _sendController.dispose();
    super.dispose();
  }

  // ── Quality ─────────────────────────────────────────────────
  void _onQualityChanged(double v) {
    setState(() {
      _quality = v;
      _estimatedKB = (_originalBytes * (v / 100) / 1024).round();
    });
    _qualityDebounce?.cancel();
    _qualityDebounce = Timer(const Duration(milliseconds: 600), () {
      _generatePreview();
    });
  }

  Future<void> _generatePreview() async {
    setState(() => _isProcessing = true);
    final result = await FlutterImageCompress.compressAndGetFile(
      widget.imageFile.absolute.path,
      '${widget.imageFile.parent.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg',
      quality: _quality.round(),
    );
    if (result != null && mounted) {
      setState(() {
        _previewFile = File(result.path);
        _isProcessing = false;
      });
    }
  }

  // ── Send ─────────────────────────────────────────────────────
  Future<void> _onSend() async {
    HapticFeedback.mediumImpact();
    _sendController.forward();

    File fileToSend = widget.imageFile;

    // Compress with chosen quality
    if (_quality < 100) {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        widget.imageFile.absolute.path,
        '${widget.imageFile.parent.path}/send_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: _quality.round(),
      );
      if (compressed != null) fileToSend = File(compressed.path);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      widget.onSend(fileToSend, _captionController.text.trim());
      Navigator.pop(context);
    }
  }

  String get _qualityLabel {
    if (_quality >= 90) return 'Original';
    if (_quality >= 70) return 'High';
    if (_quality >= 45) return 'Medium';
    return 'Low';
  }

  Color get _qualityColor {
    if (_quality >= 90) return const Color(0xFF66BB6A);
    if (_quality >= 70) return const Color(0xFF42A5F5);
    if (_quality >= 45) return AppColors.gradientPink;
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [

          // ── Background image (blurred optionally) ─────────────
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _blurBackground
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                        key: const ValueKey('blurred'),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-blur')),
            ),
          ),

          // ── Main image + draw canvas ──────────────────────────
          GestureDetector(
            onTapDown: _stampMode
                ? (d) => _addStamp(d.localPosition)
                : null,
            child: InteractiveViewer(
              transformationController: _transformController,
              panEnabled: !_drawMode && !_stampMode,
              scaleEnabled: !_drawMode && !_stampMode,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _previewFile != null
                          ? Image.file(
                              _previewFile!,
                              key: ValueKey(_previewFile!.path),
                              fit: BoxFit.contain,
                            )
                          : Image.file(
                              widget.imageFile,
                              fit: BoxFit.contain,
                            ),
                    ),

                    // Processing overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.gradientPink),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Generating preview...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Draw canvas
                    if (_drawMode)
                      Positioned.fill(
                        child: RepaintBoundary(
                          key: _canvasKey,
                          child: GestureDetector(
                            onPanStart: (d) {
                              setState(() {
                                _currentStroke = DrawStroke(
                                  color: _penColor,
                                  width: _penWidth,
                                  points: [d.localPosition],
                                );
                              });
                            },
                            onPanUpdate: (d) {
                              setState(() {
                                _currentStroke?.points.add(d.localPosition);
                              });
                            },
                            onPanEnd: (_) {
                              if (_currentStroke != null) {
                                setState(() {
                                  _strokes.add(_currentStroke!);
                                  _currentStroke = null;
                                });
                              }
                            },
                            child: CustomPaint(
                              painter: _DrawPainter(
                                strokes: _strokes,
                                current: _currentStroke,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Emoji stamps
                    ..._stamps.map((stamp) => Positioned(
                          left: stamp.position.dx - 20,
                          top: stamp.position.dy - 20,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _stamps.remove(stamp)),
                            child: Text(
                              stamp.emoji,
                              style: TextStyle(fontSize: stamp.size),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar ────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _TopBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    // Blur toggle
                    _TopBtn(
                      icon: Icons.blur_on_rounded,
                      active: _blurBackground,
                      onTap: () =>
                          setState(() => _blurBackground = !_blurBackground),
                    ),
                    const SizedBox(width: 8),
                    // Draw mode
                    _TopBtn(
                      icon: Icons.draw_rounded,
                      active: _drawMode,
                      onTap: () => setState(() {
                        _drawMode = !_drawMode;
                        _stampMode = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    // Stamp mode
                    _TopBtn(
                      icon: Icons.emoji_emotions_outlined,
                      active: _stampMode,
                      onTap: () => setState(() {
                        _stampMode = !_stampMode;
                        _drawMode = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    // Undo
                    _TopBtn(
                      icon: Icons.undo_rounded,
                      onTap: () {
                        if (_strokes.isNotEmpty) {
                          setState(() => _strokes.removeLast());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Draw toolbar ───────────────────────────────────────
          if (_drawMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 200,
              child: _DrawToolbar(
                selectedColor: _penColor,
                penWidth: _penWidth,
                onColorChanged: (c) => setState(() => _penColor = c),
                onWidthChanged: (w) => setState(() => _penWidth = w),
              ),
            ),

          // ── Stamp emoji picker ─────────────────────────────────
          if (_stampMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 200,
              child: _EmojiPicker(
                selected: _selectedEmoji,
                onSelected: (e) => setState(() => _selectedEmoji = e),
              ),
            ),

          // ── Bottom panel ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Image info row ─────────────────────────
                      Row(
                        children: [
                          _InfoChip(
                            label:
                                '${_width}×${_height}',
                            icon: CupertinoIcons.photo,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            label:
                                '${(_originalBytes / 1024).round()} KB original',
                            icon: CupertinoIcons.doc,
                          ),
                          const Spacer(),
                          // Estimated size badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _qualityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _qualityColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              '~${_estimatedKB} KB',
                              style: TextStyle(
                                color: _qualityColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Quality slider ─────────────────────────
                      Row(
                        children: [
                          Text(
                            'Quality',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quality label badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _qualityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _qualityLabel,
                              style: TextStyle(
                                color: _qualityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_quality.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _qualityColor,
                          inactiveTrackColor:
                              Colors.white.withOpacity(0.15),
                          thumbColor: Colors.white,
                          overlayColor:
                              _qualityColor.withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _quality,
                          min: 20,
                          max: 100,
                          divisions: 16,
                          onChanged: _onQualityChanged,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Caption row ────────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _showCaption
                            ? Container(
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.07),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gradientPurple
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: TextField(
                                  controller: _captionController,
                                  focusNode: _captionFocus,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14),
                                  maxLines: 3,
                                  minLines: 1,
                                  decoration:
                                      const InputDecoration.collapsed(
                                    hintText: 'Add a caption...',
                                    hintStyle: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 14),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // ── Action row ─────────────────────────────
                      Row(
                        children: [
                          // Caption toggle
                          _BottomAction(
                            icon: Icons.closed_caption_outlined,
                            label: 'Caption',
                            active: _showCaption,
                            onTap: () {
                              setState(
                                  () => _showCaption = !_showCaption);
                              if (_showCaption) {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () => _captionFocus.requestFocus(),
                                );
                              } else {
                                _captionFocus.unfocus();
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          // Reset draws
                          _BottomAction(
                            icon: Icons.cleaning_services_rounded,
                            label: 'Clear',
                            onTap: () => setState(() {
                              _strokes.clear();
                              _stamps.clear();
                            }),
                          ),
                          const Spacer(),
                          // Send button
                          ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 0)
                                .animate(_sendAnim),
                            child: GestureDetector(
                              onTap: _onSend,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: AppColors.igGradient,
                                  borderRadius:
                                      BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gradientPurple
                                          .withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.send_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addStamp(Offset position) {
    setState(() {
      _stamps.add(_EmojiStamp(
        emoji: _selectedEmoji,
        position: position,
        size: 36,
      ));
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Draw data models
// ─────────────────────────────────────────────────────────────
class DrawStroke {
  final Color color;
  final double width;
  final List<Offset> points;
  DrawStroke({required this.color, required this.width, required this.points});
}

class _EmojiStamp {
  final String emoji;
  final Offset position;
  final double size;
  _EmojiStamp({required this.emoji, required this.position, required this.size});
}

// ─────────────────────────────────────────────────────────────
// Draw painter
// ─────────────────────────────────────────────────────────────
class _DrawPainter extends CustomPainter {
  final List<DrawStroke> strokes;
  final DrawStroke? current;
  _DrawPainter({required this.strokes, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    void drawStroke(DrawStroke s) {
      if (s.points.isEmpty) return;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(s.points[0].dx, s.points[0].dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) drawStroke(s);
    if (current != null) drawStroke(current!);
  }

  @override
  bool shouldRepaint(_DrawPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────
class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _TopBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? AppColors.gradientPurple.withOpacity(0.4)
              : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.gradientPurple.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(icon,
            color: active ? Colors.white : Colors.white60, size: 18),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.gradientPurple.withOpacity(0.2)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.gradientPurple.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? AppColors.gradientPurple : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : Colors.white60,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DrawToolbar extends StatelessWidget {
  final Color selectedColor;
  final double penWidth;
  final Function(Color) onColorChanged;
  final Function(double) onWidthChanged;

  const _DrawToolbar({
    required this.selectedColor,
    required this.penWidth,
    required this.onColorChanged,
    required this.onWidthChanged,
  });

  static const _colors = [
    Colors.white,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _colors.map((c) {
              final active = selectedColor == c;
              return GestureDetector(
                onTap: () => onColorChanged(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: active ? 30 : 24,
                  height: active ? 30 : 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Width slider
          Row(
            children: [
              const Icon(Icons.edit, color: Colors.white38, size: 14),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: selectedColor,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: selectedColor,
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: penWidth,
                    min: 1,
                    max: 12,
                    onChanged: onWidthChanged,
                  ),
                ),
              ),
              const Icon(Icons.edit, color: Colors.white, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  final String selected;
  final Function(String) onSelected;

  const _EmojiPicker({required this.selected, required this.onSelected});

  static const _emojis = [
    '❤️','😂','🔥','✨','👍','🎉','😍','💯',
    '🌟','💀','🤣','😭','🙌','👏','💪','🫶',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _emojis.map((e) {
          final active = selected == e;
          return GestureDetector(
            onTap: () => onSelected(e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.gradientPurple.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? AppColors.gradientPurple
                      : Colors.transparent,
                ),
              ),
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          );
        }).toList(),
      ),
    );
  }
}