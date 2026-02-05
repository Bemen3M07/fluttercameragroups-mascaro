import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class CameraScreen extends StatefulWidget {
  final Function(String) onPhotoTaken;

  const CameraScreen({super.key, required this.onPhotoTaken});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        return;
      }

      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error inicializando cámara: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      _showAlert('No hay múltiples cámaras disponibles');
      return;
    }

    setState(() {
      _isInitialized = false;
    });

    await _controller?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    _controller = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isFlashOn = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error al cambiar flash: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Activar flash si está encendido
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.always);
      }

      final XFile photo = await _controller!.takePicture();

      // Restaurar flash
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      // Intentar guardar en la galería
      String saveMessage = 'Foto capturada: ${photo.path}';
      try {
        await ImageGallerySaverPlus.saveFile(photo.path);
        saveMessage = 'Foto guardada en galería y en: ${photo.path}';
      } catch (saveError) {
        print('Advertencia al guardar en galería: $saveError');
        saveMessage = 'Foto guardada temporalmente en: ${photo.path}';
      }

      // Notificar al padre
      widget.onPhotoTaken(photo.path);

      // Mostrar alerta con la ubicación
      if (mounted) {
        _showAlert(saveMessage);
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      if (mounted) {
        _showAlert('Error al capturar la imagen: $e');
      }
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Photo Taken'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'toggle_camera') {
                _toggleCamera();
              } else if (value == 'toggle_flash') {
                _toggleFlash();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'toggle_camera',
                child: Row(
                  children: [
                    Icon(
                      _selectedCameraIndex == 0
                          ? Icons.camera_front
                          : Icons.camera_rear,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCameraIndex == 0
                          ? 'Cambiar a frontal'
                          : 'Cambiar a trasera',
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'toggle_flash',
                child: Row(
                  children: [
                    Icon(
                      _isFlashOn ? Icons.flash_off : Icons.flash_on,
                    ),
                    const SizedBox(width: 8),
                    Text(_isFlashOn ? 'Apagar flash' : 'Encender flash'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Vista previa de la cámara
                SizedBox.expand(
                  child: CameraPreview(_controller!),
                ),
                // Botón de captura
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      backgroundColor: Colors.purple,
                      child: const Icon(Icons.camera, size: 30),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
