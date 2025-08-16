import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _cameraController;
  FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector();
  bool _isDetecting = false;
  List<Face> _faces = [];
  bool _isFaceInPosition = false;
  Size? _screenSize;
  Rect? _targetOval;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }


  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final inputImageFormat = Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21;
    _cameraController = CameraController(
      cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: inputImageFormat,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
    _cameraController!.startImageStream((image) => _processCameraImage(image, _cameraController!.description),);
  }

  void _processCameraImage(CameraImage image, CameraDescription description) async {
    if (_isDetecting) return;
    _isDetecting = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();



    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = InputImageRotationValue.fromRawValue(description.sensorOrientation) ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final inputImage =  InputImage.fromBytes(bytes: bytes, metadata: metadata);


    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (mounted) {
        setState(() {
          _faces = faces;
          _checkFacePosition();
        });
      }
    } catch (e) {
      print("Face detection error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  void _checkFacePosition() {
    if (_screenSize == null || _targetOval == null || _faces.isEmpty) {
      _isFaceInPosition = false;
      return;
    }

    final face = _faces.first;
    final faceRect = face.boundingBox;

    // Calculate face center position
    final faceCenter = Offset(
      faceRect.left + faceRect.width / 2,
      faceRect.top + faceRect.height / 2,
    );

    // Check if face center is within target oval
    _isFaceInPosition = _isPointInOval(faceCenter, _targetOval!);
  }

  bool _isPointInOval(Offset point, Rect ovalRect) {
    final center = ovalRect.center;
    final a = ovalRect.width / 2;
    final b = ovalRect.height / 2;
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return (dx * dx) / (a * a) + (dy * dy) / (b * b) <= 1;
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    _targetOval = Rect.fromCenter(
      center: Offset(_screenSize!.width / 2, _screenSize!.height / 3),
      width: _screenSize!.width * 0.6,
      height: _screenSize!.height * 0.4,
    );

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          _buildFaceIndicator(),
          _buildCaptureButton(),
        ],
      ),
    );
  }

  Widget _buildFaceIndicator() {
    return Positioned.fill(
      child: CustomPaint(
        painter: FaceIndicatorPainter(
          ovalRect: _targetOval!,
          isFaceInPosition: _isFaceInPosition,
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          backgroundColor: _isFaceInPosition ? Colors.green : Colors.grey,
          onPressed: _isFaceInPosition ? _captureImage : null,
          child: Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  void _captureImage() async {
    if (_cameraController == null) return;
    final image = await _cameraController!.takePicture();
    // Handle captured image (save, display, etc.)
    print("Image captured: ${image.path}");
    if (!mounted) return;
    Navigator.pop(context, image.path);
  }
}

class FaceIndicatorPainter extends CustomPainter {
  final Rect ovalRect;
  final bool isFaceInPosition;

  FaceIndicatorPainter({
    required this.ovalRect,
    required this.isFaceInPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = isFaceInPosition ? Colors.green : Colors.red;

    // Draw main oval
    canvas.drawOval(ovalRect, paint);

    // Draw positioning guides
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.5);

    // Horizontal guide
    canvas.drawLine(
      Offset(0, ovalRect.center.dy),
      Offset(size.width, ovalRect.center.dy),
      guidePaint,
    );

    // Vertical guide
    canvas.drawLine(
      Offset(ovalRect.center.dx, 0),
      Offset(ovalRect.center.dx, size.height),
      guidePaint,
    );

    // Draw instruction text
    final text = TextPainter(
      text: const TextSpan(
        text: "Align your face within the oval",
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    text.layout();
    text.paint(
      canvas,
      Offset(
        (size.width - text.width) / 2,
        ovalRect.bottom + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(FaceIndicatorPainter oldDelegate) {
    return oldDelegate.isFaceInPosition != isFaceInPosition ||
        oldDelegate.ovalRect != ovalRect;
  }
}