import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/api_service.dart';

enum LivenessState {
  detectingFace,
  holdingSteady,
  processing,
  success,
  failed
}

class FaceAuthScreen extends StatefulWidget {
  final String role;
  final bool returnToCallerOnSuccess;
  final bool useBackCamera;
  
  const FaceAuthScreen({
    super.key,
    required this.role,
    this.returnToCallerOnSuccess = false,
    this.useBackCamera = false,
  });

  @override
  State<FaceAuthScreen> createState() => _FaceAuthScreenState();
}


class _FaceAuthScreenState extends State<FaceAuthScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  
  bool _isCameraInitialized = false;
  bool _isProcessingImage = false;
  
  LivenessState _currentState = LivenessState.detectingFace;
  String _errorMessage = '';
  DateTime? _faceFocusedTime;
  
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configure face detector for performance and Euler angles
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final targetDirection = widget.useBackCamera ? CameraLensDirection.back : CameraLensDirection.front;
      final selectedCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == targetDirection,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 // Better for ML Kit on Android
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startLivenessDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }


  void _startLivenessDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessingImage || 
          _currentState == LivenessState.processing || 
          _currentState == LivenessState.success) return;
          
      _isProcessingImage = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessingImage = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        if (_currentState != LivenessState.detectingFace) {
          if (mounted) {
            setState(() {
              _currentState = LivenessState.detectingFace;
              _faceFocusedTime = null;
            });
          }
        }
        _isProcessingImage = false;
        return;
      }

      final face = faces.first;
      final double yaw = face.headEulerAngleY ?? 0.0; // Left/Right rotation
      final double pitch = face.headEulerAngleX ?? 0.0; // Up/Down rotation
      
      // Calculate face position and size relative to image
      final Rect boundingBox = face.boundingBox;
      final double imgWidth = inputImage.metadata!.size.width;
      final double imgHeight = inputImage.metadata!.size.height;
      
      // Check if face is roughly centered (25% to 75% region of the frame)
      final double centerX = boundingBox.center.dx;
      final double centerY = boundingBox.center.dy;
      final bool isCentered = (centerX > imgWidth * 0.25 && centerX < imgWidth * 0.75) &&
                              (centerY > imgHeight * 0.20 && centerY < imgHeight * 0.80);
                              
      // Check if face is a reasonable size (not too far)
      final bool isRightSize = boundingBox.width > imgWidth * 0.25;

      if (mounted) {
        if (_currentState == LivenessState.detectingFace || _currentState == LivenessState.holdingSteady) {
          // Require face to be straight, centered, and right size
          if (yaw.abs() < 15.0 && pitch.abs() < 15.0 && isCentered && isRightSize) {
            if (_faceFocusedTime == null) {
              setState(() {
                _currentState = LivenessState.holdingSteady;
                _faceFocusedTime = DateTime.now();
              });
            } else if (DateTime.now().difference(_faceFocusedTime!).inMilliseconds > 1500) {
              // Face has been steady for 1.5 seconds!
              setState(() {
                _currentState = LivenessState.processing;
              });
              _captureAndVerify();
            }
          } else {
            // Face moved, tilted, or went out of bounds
            if (_currentState != LivenessState.detectingFace) {
              setState(() {
                _currentState = LivenessState.detectingFace;
                _faceFocusedTime = null;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing face: $e');
    } finally {
      _isProcessingImage = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _cameraController!.value.deviceOrientation.index;
      if (rotationCompensation == -1) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _captureAndVerify() async {
    try {
      await _cameraController!.stopImageStream();
      // Freeze the camera preview on the screen exactly when they were holding steady
      try {
        await _cameraController!.pausePreview();
      } catch (_) {}
      
      final XFile image = await _cameraController!.takePicture();
      
      final success = await ApiService().verifyFace(image.path);
      
      if (success) {
        if (!mounted) return;
        setState(() => _currentState = LivenessState.success);
        
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        if (widget.returnToCallerOnSuccess) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacementNamed(
            context,
            widget.role == 'SecurityGuard' ? '/guard' : '/staff',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentState = LivenessState.failed;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      // Restart stream after failure
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _currentState = LivenessState.detectingFace;
          _faceFocusedTime = null;
          _errorMessage = '';
        });
        try {
          await _cameraController!.resumePreview();
        } catch (_) {}
        _startLivenessDetection();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _scanController.dispose();
    super.dispose();
  }

  String _getInstructionText() {
    switch (_currentState) {
      case LivenessState.detectingFace:
        return 'Position your face in the oval';
      case LivenessState.holdingSteady:
        return 'Hold still...';
      case LivenessState.processing:
        return 'Scanning...';
      case LivenessState.success:
        return 'Face Verified!';
      case LivenessState.failed:
        return 'Verification Failed. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.role == 'SecurityGuard' ? const Color(0xFF6366F1) : const Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_isCameraInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
            
          // 2. Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 380,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(160),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Simple Border
          Center(
            child: Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(160),
                border: Border.all(
                  color: _currentState == LivenessState.detectingFace 
                      ? Colors.white
                      : _currentState == LivenessState.failed
                          ? Colors.red
                          : Colors.green, 
                  width: 3,
                ),
              ),
            ),
          ),
          
          // 4. Scanning Animation Line (only during detection)
          if (_isCameraInitialized && 
              (_currentState == LivenessState.detectingFace || 
               _currentState == LivenessState.holdingSteady))
            Center(
              child: SizedBox(
                width: 280,
                height: 380,
                child: AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          top: _scanAnimation.value * 370,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
          // 5. Success Overlay - Only inside the boundary
          if (_currentState == LivenessState.success)
            Center(
              child: Container(
                width: 280,
                height: 380,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3), 
                  borderRadius: BorderRadius.circular(160),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.white, size: 80),
                ),
              ),
            ),

          // 6. UI Elements
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text("Face Verification", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
                
                const Spacer(),
                
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    padding: const EdgeInsets.all(16),
                    color: Colors.red,
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                if (_currentState != LivenessState.success)
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getInstructionText(),
                          style: TextStyle(
                            color: _currentState == LivenessState.failed ? Colors.red : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_currentState == LivenessState.processing)
                           Padding(
                             padding: const EdgeInsets.only(top: 16),
                             child: CircularProgressIndicator(
                               valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                             ),
                           ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
