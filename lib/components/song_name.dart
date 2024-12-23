import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class SongNameMarquee extends StatelessWidget {
  final String songName;

  const SongNameMarquee({Key? key, required this.songName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75, // Chiều cao cố định
      width: MediaQuery.of(context).size.width * 2 / 3,
      child: Marquee(
        text: songName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 20.0,
        velocity: 50.0,
        pauseAfterRound: const Duration(seconds: 2),
      ),
    );
  }
}
