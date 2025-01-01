import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class ListMusicPage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onSelectSong;

  const ListMusicPage({Key? key, required this.onSelectSong}) : super(key: key);

  @override
  _ListMusicPageState createState() => _ListMusicPageState();
}

class _ListMusicPageState extends State<ListMusicPage> {
  List<Map<String, dynamic>> _songs = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Yêu cầu quyền truy cập bộ nhớ
    _loadSongs();
  }

  // Yêu cầu quyền truy cập bộ nhớ
  Future<void> _requestPermissions() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print("Đã được cấp quyền");
    } else {
      print("Bị từ chối quyền");
    }
    //  Android 11 trở lên
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("AR11 đã đc cấp quyền ");
    } else {
      print("AR11 đã ko dc cấp quyền ");
    }
  }

  Future<void> _loadSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsString = prefs.getString('songs') ?? '[]';
    setState(() {
      _songs = List<Map<String, dynamic>>.from(json.decode(songsString));
    });
  }

  // Lưu danh sách bài hát
  Future<void> _saveSongs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('songs', json.encode(_songs));
  }
  // Lưu vi tri bài hát
  Future<void> _saveIndexSongs(int index) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('indexSong', index);
  }

  Future<void> _saveSongData(List<Map<String, dynamic>> songs, int currentIndex) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> songData = {
      'songs': songs,
      'currentIndex': currentIndex,
    };
    prefs.setString('songData', json.encode(songData));
  }

  Future<void> _addSongsFromFiles() async {
    try {
      // chọn một hoặc nhiều bài hát
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('Không có bài hát nào được chọn.');
        return;
      }
      int addedCount = 0;
      for (var file in result.files) {
        final filePath = file.path!;
        final fileName = file.name;

        // Kiểm tra xem bài hát đã tồn tại trong danh sách hay chưa
        if (_songs.any((song) => song['name'] == fileName)) {
          continue;
        }

        final duration = await _getAudioDuration(filePath);

        List<String> thumbList = [
          'assets/images/art_work_1.jpg',
          'assets/images/art_work_2.jpg',
          'assets/images/art_work_3.jpg',
          'assets/images/art_work_4.jpg',
          'assets/images/art_work_5.jpg',
          'assets/images/art_work_6.jpg',
          'assets/images/art_work_7.jpg',
          'assets/images/art_work_8.jpg',
        ];

        // Chọn ngẫu nhiên
        final random = Random();
        String randomThumb = thumbList[random.nextInt(thumbList.length)];

        Map<String, dynamic> newSong = {
          'name': fileName,
          'link': filePath,
          'thum': randomThumb,
          'duration': duration?.inSeconds ?? 0,
          'favorite': true,
        };
        setState(() {
          _songs.add(newSong);
        });
        addedCount++;
      }
      await _saveSongs();
      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm $addedCount bài hát.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không có bài hát mới nào được thêm.')),
        );
      }
      debugPrint('Đã thêm $addedCount bài hát.');
    } catch (e) {
      debugPrint('Lỗi khi thêm bài hát: $e');
    }
  }

  Future<void> _addSongsFromDirectory() async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null || directoryPath.isEmpty) {
        debugPrint('Không chọn thư mục hoặc đường dẫn không hợp lệ');
        return;
      }
      final directory = Directory(directoryPath);
      // Lấy tất cả các file .mp3 trong thư mục
      final files = directory
          .listSync(recursive: true)
          .where((file) => file is File && file.path.endsWith('.mp3'))
          .toList();

      if (files.isEmpty) {
        debugPrint('Không tìm thấy file nhạc trong thư mục: $directoryPath');
        return;
      }

      int addedCount = 0;

      for (var file in files) {
        final filePath = file.path;
        final fileName = file.uri.pathSegments.last;
        if (_songs.any((song) => song['name'] == fileName)) {
          continue;
        }
        final duration = await _getAudioDuration(filePath);

        List<String> thumbList = [
          'assets/images/art_work_1.jpg',
          'assets/images/art_work_2.jpg',
          'assets/images/art_work_3.jpg',
          'assets/images/art_work_4.jpg',
          'assets/images/art_work_5.jpg',
          'assets/images/art_work_6.jpg',
          'assets/images/art_work_7.jpg',
          'assets/images/art_work_8.jpg',
        ];

        // Chọn ngẫu nhiên
        final random = Random();
        String randomThumb = thumbList[random.nextInt(thumbList.length)];

        Map<String, dynamic> newSong = {
          'name': fileName,
          'link': filePath,
          'thum': randomThumb,
          'duration': duration?.inSeconds ?? 0,
          'favorite': true,
        };

        setState(() {
          _songs.add(newSong);
        });
        addedCount++;
      }
      await _saveSongs();
      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm $addedCount bài hát từ thư mục.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không có bài hát mới nào được thêm.')),
        );
      }

      debugPrint('Đã thêm $addedCount bài hát từ thư mục.');
    } catch (e) {
      debugPrint('Lỗi khi thêm bài hát từ thư mục: $e');
    }
  }

  // Lấy độ dài
  Future<Duration?> _getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(filePath);
      final duration = player.duration;
      await player.dispose();
      return duration;
    } catch (e) {
      debugPrint('Lỗi khi đọc thời gian: $e');
    }
    return null;
  }

  // Xóa bài hát khỏi danh sách
  void _deleteSong(int index) {
    setState(() {
      _songs.removeAt(index);
    });
    _saveSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              return GestureDetector(
                onLongPress: () {
                  _showDeleteDialog(context, index);
                },
                child: ListTile(
                  leading: Image.asset(song['thum']),
                  title: Text(
                    song['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                      'Thời gian: ${Duration(seconds: song['duration']).inMinutes}:${(song['duration'] % 60).toString().padLeft(2, '0')}'),
                  onTap: () {
                    widget.onSelectSong({
                      'songs': _songs,
                      'currentIndex': index,
                    });
                    _saveSongData(_songs, index);
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _addSongsFromDirectory,
                icon: const Icon(Icons.folder),
                label: const Text('Thêm từ thư mục'),
              ),
              ElevatedButton.icon(
                onPressed: _addSongsFromFiles,
                icon: const Icon(Icons.music_note),
                label: const Text('Thêm bài hát'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Hiển thị hộp thoại xác nhận xóa
  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa bài hát'),
          content: const Text('Bạn có chắc muốn xóa bài hát này không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _deleteSong(index);
                Navigator.of(context).pop();
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
