import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../viewmodels/scanner_viewmodel.dart';
import 'food_scan_results_page.dart';

class FoodScannerPage extends StatefulWidget {
  const FoodScannerPage({Key? key}) : super(key: key);

  @override
  State<FoodScannerPage> createState() => _FoodScannerPageState();
}

class _FoodScannerPageState extends State<FoodScannerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerViewModel>().initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerViewModel>(
      builder: (context, scannerViewModel, child) {
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
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('AI Services'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This app uses Gemini for food recognition and CalorieNinjas for nutrition data.',
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
              if (scannerViewModel.isCameraInitialized)
                Positioned.fill(
                  child: CameraPreview(scannerViewModel.cameraController!),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

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
                          if (scannerViewModel.scanningStatus.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              scannerViewModel.scanningStatus,
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
                              scannerViewModel.isBusy
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: Color(0xFFD6F36B),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          scannerViewModel.scanningStatus,
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
                            onTap:
                                scannerViewModel.isBusy
                                    ? null
                                    : () async {
                                      final result =
                                          await scannerViewModel
                                              .pickFromGallery();
                                      if (result != null && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (
                                                  context,
                                                ) => FoodScanResultsPage(
                                                  imageFile:
                                                      result['imageFile'],
                                                  nutritionData:
                                                      result['nutritionData'],
                                                ),
                                          ),
                                        );
                                      }
                                    },
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
                            onTap:
                                scannerViewModel.isBusy
                                    ? null
                                    : () async {
                                      final result =
                                          await scannerViewModel
                                              .captureAndAnalyze();
                                      if (result != null && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (
                                                  context,
                                                ) => FoodScanResultsPage(
                                                  imageFile:
                                                      result['imageFile'],
                                                  nutritionData:
                                                      result['nutritionData'],
                                                ),
                                          ),
                                        );
                                      }
                                    },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6F36B),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child:
                                  scannerViewModel.isBusy
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
                            onTap: scannerViewModel.toggleFlash,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                scannerViewModel.isFlashOn
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
      },
    );
  }

  @override
  void dispose() {
    context.read<ScannerViewModel>().dispose();
    super.dispose();
  }
}
