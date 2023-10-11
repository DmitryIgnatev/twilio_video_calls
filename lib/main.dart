import 'package:flutter/material.dart';
import 'package:twilio_video_calls/room/join_room_page.dart';

void main() {
  runApp(const TwilioProgrammableVideoExample());
}

class TwilioProgrammableVideoExample extends StatelessWidget {
  const TwilioProgrammableVideoExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: JoinRoomPage(),
    );
  }
}
