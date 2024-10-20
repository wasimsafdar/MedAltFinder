import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharma_ai/Screens/preview_screen.dart';

import '../bloc/bloc/llama32vision_bloc.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? cameraController;
  List? cameras;
  late int selectedCameraIndex;
  late String imgPath;
  XFile? imageFile;
  bool loading = false;
  String finalResponse = '';

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController!.dispose();
    }

    cameraController = CameraController(cameraDescription, ResolutionPreset.high);
    cameraController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController!.value.hasError) {
      print('Camera error ${cameraController!.value.errorDescription}');
    }

    try {
      await cameraController!.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = cameraController;

    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(cameraController!.description);
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      return cameraController!.setDescription(cameraDescription);
    } else {
      return _initCameraController(cameraDescription);
    }
  }

  Widget _cameraPreviewWidget() {
    final CameraController? controller = cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  Widget _cameraControllerWidget(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            FloatingActionButton(
              onPressed: () {
                _onCapturePressed(context);
              },
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.camera,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraToggleRowWidget() {
    if (cameras == null) {
      return const Spacer();
    }

    CameraDescription selectedCamera = cameras![selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: Icon(
            _getCameraLensIcon(lensDirection),
            color: Colors.white,
            size: 24,
          ),
          onPressed: _onSwitchCamera,
          label: Text(
            lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras!.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        _initCameraController(cameras![selectedCameraIndex]).then((void v) {});
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<Llama32visionBloc, Llama32visionState>(
      listener: (context, state) {
        if (state is Llama32visionSuccess) {
          finalResponse = state.responseText.toString();

          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewScreen(responseText: finalResponse),
              ),
            );
            loading = false;
          });
        } else if (state is Llama32visionLoading) {
          setState(() {
            loading = true;
          });
        } else if (state is Llama32visionFailure) {
          return;
        }
      },
      child: Scaffold(
        body: loading == false
            ? SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _cameraPreviewWidget(),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _cameraToggleRowWidget(),
                            _cameraControllerWidget(context),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\n Error message: ${e.description}';
    print(errorText);
  }

  void showInSnackBar(String message, context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<XFile?> takePicture() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      showInSnackBar('Error: select a camera first.', context);
      return null;
    }

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController!.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _onCapturePressed(context) async {
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;
        });
        if (file != null) {
          final path = file.path;
          final uint8List = File(path).readAsBytesSync();
          final url = uint8ListTob64(uint8List);

          //Llama prompt
          BlocProvider.of<Llama32visionBloc>(context).add(FetchResponseFromPrompt('Identify the medicine name only', url));

          //showInSnackBar('Picture saved to ${file.path}', context);
        }
      }
    });
  }

  //Converting image to Base64
  String uint8ListTob64(Uint8List uint8list) {
    String base64String = base64Encode(uint8list);
    String header = "data:image/png;base64,";
    return header + base64String;
  }

  /// Returns a suitable camera icon for [direction].
  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
    }
  }

  void _onSwitchCamera() {
    selectedCameraIndex = selectedCameraIndex < cameras!.length - 1 ? selectedCameraIndex + 1 : 0;

    CameraDescription selectedCamera = cameras![selectedCameraIndex];
    _initCameraController(selectedCamera);
  }
}
