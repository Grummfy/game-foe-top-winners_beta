import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_foe_caladaan/models/attendee.dart';
import 'package:game_foe_caladaan/screen/messages.dart';

import 'models/pool.dart';
import 'screen/attendee_screen.dart';
import 'screen/winner_screen.dart';
import 'screen/point_splitter_screen.dart';

// Root main app
class Caladaan extends StatelessWidget {
  const Caladaan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const bool debug = false;
    if (!debug) {
      return MaterialApp(
        title: 'FoE Caladaan helper',
        home: AttendeeScreen(),
      );
    }

    Pool pool = Pool();
    List<Attendee> items = <Attendee>[];
    var rng = Random();
    for(var i = 1; i <= 15; i++) {
      items.add(Attendee('player$i', (rng.nextInt(19) + 1) * 5, (i % 2) == 0));
    }

    items.sort((a, b) => b.value - a.value);
    for (var a in items) {
      pool.attendees[ a.name ] = a;
    }

    pool.winners.add(pool.attendees['player1']!);
    pool.winners.add(pool.attendees['player2']!);
    pool.winners.add(pool.attendees['player3']!);
    pool.distributor = pool.attendees['player5']!;

    List<List<Attendee>> splitterAttendees = [
      [pool.attendees['player4']!, pool.attendees['player10']!, pool.attendees['player11']!],
      [pool.attendees['player6']!, pool.attendees['player9']!],
      [pool.attendees['player7']!, pool.attendees['player8']!],
    ];

    List<int> distributorParts = [5, 15, 20];

    // const String screen = 'winner';
    const String screen = 'splitter';
    // const String screen = 'message';

    // winner screen
    if (screen == ' ') {
      return MaterialApp(
        title: 'FoE Caladaan helper',
        home: WinnerScreen(
            pool: pool,
        ), // AttendeeScreen(),
      );
    }

    // splitter screen
    if (screen == 'splitter') {
      return MaterialApp(
        title: 'FoE Caladaan helper',
        home: PointSplitterScreen(
            pool: pool,
        ), // AttendeeScreen(),
      );
    }

    // Message screen
    return MaterialApp(
      title: 'FoE Caladaan helper',
      home: MessageScreen(
          pool: pool,
          splitterAttendees: splitterAttendees,
          distributorParts: distributorParts
      ), // AttendeeScreen(),
    );
  }
}
