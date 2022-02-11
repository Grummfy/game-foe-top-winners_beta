import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_foe_caladaan/models/attendee.dart';

import 'models/pool.dart';
import 'screen/attendee_screen.dart';
import 'screen/winner_screen.dart';
import 'screen/point_splitter_screen.dart';

// Root main app
class Caladaan extends StatelessWidget {
  const Caladaan({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /*
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
    return MaterialApp(
      title: 'FoE Caladaan helper',
      home: PointSplitterScreen(pool: pool), // AttendeeScreen(),
    );
*/
    return MaterialApp(
      title: 'FoE Caladaan helper',
      home: AttendeeScreen(),
    );
  }
}
