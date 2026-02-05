import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';
import 'screens/picture_screen.dart';
import 'screens/music_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multimedia App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _lastPhotoPath;

  void _onPhotoTaken(String photoPath) {
    setState(() {
      _lastPhotoPath = photoPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      CameraScreen(onPhotoTaken: _onPhotoTaken),
      PictureScreen(lastPhotoPath: _lastPhotoPath),
      const MusicScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Imagenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Musica',
          ),
        ],
      ),
    );
  }
}
