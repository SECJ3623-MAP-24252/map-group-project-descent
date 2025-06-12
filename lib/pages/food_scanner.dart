import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ai_food_service.dart';
import '../services/api_config.dart';
import 'food_scan_results.dart';

class FoodScannerPage extends StatefulWidget {
  const FoodScannerPage({Key? key}) : super(key: key);

  @override
  State<FoodScannerPage> createState() => _FoodScannerPageState();
}

class _FoodScannerPageState extends State<FoodScannerPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _processingStatus = '';
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkAPIAvailability();
  }

  void _checkAPIAvailability() {
    final availableServices = APIConfig.getAvailableServices();
    if (availableServices.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAPIWarning();
      });
    }
  }

  void _showAPIWarning() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('API Configuration Required'),
            content: const Text(
              'To use AI food recognition, please configure your API keys in the APIConfig class. '
              'The app will use local food database as fallback.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorDialog('Camera initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Capturing image...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      await _analyzeFood(File(image.path));
    } catch (e) {
      _showErrorDialog('Failed to capture image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Loading image...';
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _analyzeFood(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
    }
  }

  Future<void> _analyzeFood(File imageFile) async {
    try {
      setState(() {
        _processingStatus = 'Analyzing food with AI...';
      });

      // Use the real AI service
      final nutritionData = await AIFoodService.analyzeFoodImage(imageFile);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FoodScanResultsPage(
                  imageFile: imageFile,
                  nutritionData: nutritionData,
                ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to analyze food: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Food Scanner',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              final services = APIConfig.getAvailableServices();
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('AI Services'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            services.isEmpty
                                ? 'No AI services configured. Using local database.'
                                : 'Active services: ${services.join(', ')}',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'This app uses Spoonacular for nutrition data and Clarifai for food recognition.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Overlay UI
          Positioned.fill(
            child: Column(
              children: [
                // Top instruction
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Point your camera at food to get nutrition info',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_processingStatus.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _processingStatus,
                          style: const TextStyle(
                            color: Color(0xFFD6F36B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Scanning frame
                Expanded(
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFD6F36B),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          _isProcessing
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFFD6F36B),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _processingStatus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                              : null,
                    ),
                  ),
                ),

                // Bottom controls
                Container(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: _isProcessing ? null : _pickFromGallery,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),

                      // Capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _captureAndAnalyze,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F36B),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child:
                              _isProcessing
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 35,
                                  ),
                        ),
                      ),

                      // Flash toggle
                      GestureDetector(
                        onTap: () {
                          if (_cameraController != null &&
                              _isCameraInitialized) {
                            final FlashMode currentFlash =
                                _cameraController!.value.flashMode;
                            final FlashMode nextFlash =
                                currentFlash == FlashMode.off
                                    ? FlashMode.torch
                                    : FlashMode.off;

                            _cameraController!.setFlashMode(nextFlash);
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            _cameraController?.value.flashMode ==
                                    FlashMode.torch
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: Colors.white,
                            size: 30,
                          ),
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
