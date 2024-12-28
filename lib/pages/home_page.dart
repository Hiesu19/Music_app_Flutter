import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/components/new_box.dart';
import 'package:music_player/components/song_name.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? songs;

  const HomePage({Key? key, this.songs}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;

  Map<String, dynamic>? _currentSong;
  int _currentIndex = 0;
  Duration _currentPosition = Duration.zero;

  String _formatDuration(int durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initializePlayer();

    // Cập nhật thời gian phát
    _player.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Kiểm tra nếu phát hoàn thành thì chuyển sang bài tiếp theo
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeat) {
          // Lặp lại bài hiện tại
          _player.seek(Duration.zero);
          _player.play();
        } else {
          // Chuyển sang bài tiếp theo
          _playNext();
          setState(() {
            _currentPosition = Duration.zero;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // Hàm khởi tạo bài hát
  Future<void> _initializePlayer() async {
    if (widget.songs != null) {
      try {
        final currentIndex = widget.songs!['currentIndex'] ?? 0;
        final songs = widget.songs!['songs'] as List<dynamic>;

        if (currentIndex >= 0 && currentIndex < songs.length) {
          _currentIndex = currentIndex;
          _currentSong = songs[_currentIndex];
          await _player.setFilePath(_currentSong!['link']);
        }
      } catch (e) {
        debugPrint("Lỗi khi phát nhạc: $e");
      }
    }
  }

  int _randomIndex(int max) {
    return (max * (1.0 * new DateTime.now().millisecondsSinceEpoch % max / max))
        .toInt();
  }

  // Hàm phát hoặc tạm dừng
  void _playPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Hàm next bài
  void _playNext() {
    if (widget.songs != null) {
      final songs = widget.songs!['songs'] as List<dynamic>;
      setState(() {
        if (_isShuffle) {
          _currentIndex = (songs.length > 1)
              ? (List.generate(songs.length, (index) => index)
                    ..remove(_currentIndex))
                  .toList()
                  .elementAt(_randomIndex(songs.length - 1))
              : _currentIndex;
        } else {
          _currentIndex = (_currentIndex + 1) % songs.length;
        }
        _currentSong = songs[_currentIndex];
        _isPlaying = true;
      });
      _player.setFilePath(_currentSong!['link']);
      _player.play();
    }
  }

  void _playPrevious() {
    if (widget.songs != null) {
      final songs = widget.songs!['songs'] as List<dynamic>;
      setState(() {
        if (_isShuffle) {
          _currentIndex = (songs.length > 1)
              ? (List.generate(songs.length, (index) => index)
                    ..remove(_currentIndex))
                  .toList()
                  .elementAt(_randomIndex(songs.length - 1))
              : _currentIndex;
        } else {
          _currentIndex = (_currentIndex - 1 + songs.length) % songs.length;
        }
        _currentSong = songs[_currentIndex];
        _isPlaying = true;
      });
      _player.setFilePath(_currentSong!['link']);
      _player.play();
    }
  }

  // Ham tua bai hat
  void _seekTo(double value) {
    final duration = _player.duration;
    if (duration != null) {
      final newPosition =
          Duration(milliseconds: (duration.inMilliseconds * value).toInt());
      _player.seek(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: _currentSong != null
              ? Column(
                  children: [
                    // art_work
                    NewBox(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "P L A Y I N G",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              _currentSong!['thum'],
                            ),
                          ),
                          SongNameMarquee(songName: _currentSong!['name']),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // Controller
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(
                                      _currentPosition.inSeconds)),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isRepeat = !_isRepeat;
                                      });
                                    },
                                    child: Icon(
                                      Icons.repeat,
                                      color: _isRepeat
                                          ? Colors.green
                                          : Colors.black,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isShuffle = !_isShuffle;
                                      });
                                    },
                                    child: Icon(
                                      Icons.shuffle,
                                      color: _isShuffle
                                          ? Colors.green
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(_formatDuration(
                                      _currentSong!['duration'])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                          ),
                          child: Slider(
                            min: 0,
                            max: 1,
                            activeColor: Colors.green,
                            value: _currentPosition.inMilliseconds /
                                (_player.duration?.inMilliseconds ?? 1),
                            onChanged: _seekTo,
                          ),
                        ),
                      ],
                    ),

                    // playback controller
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 5, 25, 5),
                      child: Row(
                        children: [
                          // skip_previous
                          Expanded(
                            child: GestureDetector(
                              onTap: _playPrevious,
                              child: NewBox(
                                child: Icon(Icons.skip_previous),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 25,
                          ),

                          // play/pause
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _playPause,
                              child: NewBox(
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 25,
                          ),

                          //next
                          Expanded(
                            child: GestureDetector(
                              onTap: _playNext,
                              child: NewBox(
                                child: Icon(Icons.skip_next),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Không có bài hát nào được chọn.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
