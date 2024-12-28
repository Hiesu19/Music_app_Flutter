import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/list_music_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndexPage = 0;
  Map<String, dynamic>? _selectedSong;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(songs: _selectedSong),
      ListMusicPage(
        onSelectSong: (selectedSong) {
          setState(() {
            _selectedSong = selectedSong;
            _currentIndexPage = 0; // Quay lại Home
          });
        },
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Music Player',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        elevation: 10,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade300,
      body: _pages[_currentIndexPage],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade400,
        currentIndex: _currentIndexPage,
        onTap: (index) {
          setState(() {
            _currentIndexPage = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note), label: 'Danh sách'),
        ],
      ),
    );

  }
}