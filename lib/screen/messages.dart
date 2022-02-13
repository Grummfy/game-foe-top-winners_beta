import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pool.dart';
import '../models/attendee.dart';
import 'dart:async';

class MessageScreen extends StatefulWidget {
  final int periodDurationInDays = 14;

  Pool pool;
  /// list of attendee that give PF to a player
  List<List<Attendee>> splitterAttendees;
  /// distributor parts
  List<int> distributorParts;

  MessageScreen({
    Key? key,
    required this.pool,
    required this.splitterAttendees,
    required this.distributorParts,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  DateTime? selectedDate;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message a copier-coller'),
      ),
      body: (selectedDate == null) ? _chooseADateFirst(context) : _messagesDisplay(context),
    );
  }

  /// show date selector
  Future<void> _selectDate(BuildContext context) async {
    // init the date pickerwith 2 week ago
    DateTime init = DateTime.now().subtract(Duration(days: widget.periodDurationInDays));
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: init.subtract(Duration(days: (widget.periodDurationInDays + 1))),
      lastDate: init.add(const Duration(days: 30)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _chooseADateFirst(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Choix de la période'), // ${selectedDate!.toLocal()}".split(' ')[0]),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text('Définir la date'),
          ),
        ],
      ),
    );
  }

  Widget _messagesDisplay(BuildContext context) {
    List<Widget> widgets = <Widget>[
      const Text('Clique sur chacun des boutons pour copier le texte a créer'),
      Divider(),
      Divider(),
      const Text('Récompenses'),
    ];

    // add winners rewards
    for (int index = 0; index < widget.pool.winners.length; index++) {
      widgets.addAll([
        ElevatedButton(
          child: Text('Sujet du fil du gagnant ${index + 1} - ${widget.pool.winners[ index ].name}'),
          onPressed: () => _onPressedMessageWinnerSubject(index),
        ),
        const SizedBox(height: 20.0),
        ElevatedButton(
          child: Text('Contenu du fil du gagnant ${index + 1}, partie 1'),
          onPressed: () => _onPressedMessageWinnerMessage(index, 1),
        ),
        const SizedBox(height: 20.0),
        ElevatedButton(
          child: Text('Contenu du fil du gagnant ${index + 1}, partie 2'),
          onPressed: () => _onPressedMessageWinnerMessage(index, 2),
        ),
        Divider(),
      ]);
    }

    // add the new messages
    widgets.addAll([
      Divider(),
      const Text('Nouveau sujet top message'),
      const SizedBox(height: 20.0),
      ElevatedButton(
        child: const Text('Sujet nouvelle cagnotte'),
        onPressed: _onPressedMessageNewTopicPoolSubject,
      ),
      const SizedBox(height: 20.0),
      ElevatedButton(
        child: const Text('Contenu du fil nouvelle cagnotte, partie 1'),
        onPressed: () => _onPressedMessageNewTopicPoolMessage(1),
      ),
      const SizedBox(height: 20.0),
      ElevatedButton(
        child: const Text('Contenu du fil nouvelle cagnotte, partie 2'),
        onPressed: () => _onPressedMessageNewTopicPoolMessage(2),
      ),
    ]);

    // finally the global messages
    widgets.addAll([
      Divider(),
      Divider(),
      ElevatedButton(
        child: const Text('Message global de guilde'),
        onPressed: _onPressedMessageToGlobalGuild,
      ),
    ]);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }

  void _onPressedMessageToGlobalGuild() {
    String winnerAndAttendees = '';
    for (int index = 0; index < widget.pool.winners.length; index++) {
      String winnerName = widget.pool.winners[ index ].name;
      winnerAndAttendees += '${index + 1}. ${winnerName} : ';
      winnerAndAttendees += widget.splitterAttendees[ index ].fold(
        '',
        (String previousValue, Attendee attendee) => previousValue.isEmpty ? attendee.name : (previousValue + ', ' + attendee.name)
      );
      winnerAndAttendees += '\n';
    }

    Clipboard.setData(
      ClipboardData(
        text: 'Le calcul de la répartition des gains a eu lieux, merci aux participants!\n'
          'Vous trouverez chacun votre propre fil en social, reprenant la répartition des gains.\n'
          '${winnerAndAttendees}\n'
          'Vous pouvez vérifier que vous y avez bien accès et ainsi vous acquitter de votre don.'
        )
    );
  }

  void _onPressedMessageWinnerSubject(int index) {
    Clipboard.setData(
      ClipboardData(
        text: '🥇🥈🥉Répartition cagnotte ${widget.pool.winners[ index ].name}'
      )
    );
  }

  void _onPressedMessageWinnerMessage(int index, int part) {
    if (part <= 1) {
      DateTime startOfPeriod = selectedDate!;
      DateTime endOfPeriod = selectedDate!.add(Duration(days: widget.periodDurationInDays));
      Clipboard.setData(
        ClipboardData(
          text: 'Bonsoir à toutes et tous,\n'
            'Ce fil concerne l\'attributions des dons pour les meilleurs progressions en points, sur la semaine du '
            '${startOfPeriod.toLocal().toString().split(' ')[0]} au ${endOfPeriod.toLocal().toString().split(' ')[0]}, '
            'pour le ${index + 1}° gagnant : ${widget.pool.winners[ index ].name}.\n'
            'Merci a la personne concernée de lier un GM dans ce fil (⚠ pas un gm 1.9 ⚠, pour la facilité le suivit) afin que les promesses de dons soient déposées.\n\n'
            'Ps: comme c’est un don, merci de reverser le bénéfice sur le même gm au cas où vous prenez une place à pf sur le gm. Je compte sur votre honnêteté!'
        )
      );
      return;
    }

    String values = widget.splitterAttendees[ index ].fold(
      '',
      (String previousValue, Attendee attendee) => previousValue + attendee.name + ' : ' + attendee.value.toString() + '\n',
    );

    Clipboard.setData(
      ClipboardData(text: 'Doivent déposer sur le gm de ${widget.pool.winners[ index ].name} :\n'
        '${values}'
        '${widget.pool.distributor!.name} : ${widget.distributorParts[ index ]}'
      )
    );
  }

  void _onPressedMessageNewTopicPoolSubject() {
    List<DateTime> nextPeriod = _computeNextPeriod();
    DateTime startOfNextPeriod = nextPeriod[ 0 ];
    DateTime endOfNextPeriod = nextPeriod[ 1 ];

    Clipboard.setData(
      ClipboardData(
        text: '🥇Cagnotte du ${startOfNextPeriod.toLocal().toString().split(' ')[0]} au ${endOfNextPeriod.toLocal().toString().split(' ')[0]}'
      )
    );
  }

  void _onPressedMessageNewTopicPoolMessage(int part) {
    List<DateTime> nextPeriod = _computeNextPeriod();
    DateTime startOfNextPeriod = nextPeriod[ 0 ];
    DateTime endOfNextPeriod = nextPeriod[ 1 ];

    if (part <= 1) {
      Clipboard.setData(
        ClipboardData(
          text: 'Suite au classement de la meilleure progression, nous récompensons le top 3 de la meilleure progression ***toutes les 2 semaines***.\n'
            'Comment ?\n'
            'Sur ce fil, chaque 2 semaines, les promesses aux dons seront ouvertes et chaque joueur pourra écrire son nom'
            'et le nombre de PF qu’il souhaite donner. Ce don n’est absolument pas obligatoire et seuls ceux qui le'
            'souhaitent participent😊. Mais ne sauront pris en compte comme participants que ceux participants à la cagnotte.\n\n'
            'Une promesse de don = une inscription à la cagnotte, avant la clôture.\n\n'
            'Le total de ces promesses constituera la cagnotte qui sera répartie entre les trois vainqueurs de la façon suivante :\n'
            'P1 : 50% des dons 🎁🎁🎁\n'
            'P2 : 30% des dons 🎁🎁\n'
            'P3 : 20% des dons 🎁\n'
            'Les gagnants pourront alors indiquer dans le fil sur quel GM ils souhaitent que la récompense soit déposée.\n'
            'Pas d’inquiétude ! Pas de calcul de répartition ou de pourcentage à faire ! J’indiquerai à chacun le lundi\n'
            'à qui il doit donner ses PF pour que chaque gagnant touche le bon montant de la récompense 😊\n\n'
            'Mais il est donc important d’attendre mes indications avant de déposer les PF, sinon il nous sera impossible\n'
            'd’obtenir la répartition 50, 30, 20 !\n\n'
            'Il sera impossible de gagner deux fois d’affiliées :\n'
            'Exemple:\n'
            'Si vous êtes 3ième la periode 1. Et 3ième la période 2.\n'
            'Vous ne toucherez pas de récompense. Celle ci sera attribuée au 4ième.\n\n'
            'Autre exemple:\n'
            'Vous êtes 3ième la période 1, premier la période 2, ==> Vous ne toucherez pas de récompenses\n\n'
            'Tout redevient normal en période 3, vous pouvez de nouveau gagner la récompense\n\n\n'
            'Les membres du conseil de Calaadan renoncent à leur droit de gagner la cagnotte, merci à eux 😉.'
            'Les membres du conseil sont Bobbie joe, Elemental, Christophe, Quiétus, Fred, Honorius, Euric et Fragmasterfrogs.\n'
            'Cagnotte de la période du ${startOfNextPeriod.toLocal().toString().split(' ')[0]} au ${endOfNextPeriod.toLocal().toString().split(' ')[0]}'
            ' (cette semaine ${widget.pool.winners.fold('', (String v, Attendee e) => v.isEmpty ? e.name : (v + ', ' + e.name))}'
            ' ne sont pas éligibles aux gains mais rien ne vous empêche d\'être dans le top 3 quand même ;))'
        )
      );
      return;
    }

    // compute sum of auto value for the new pool
    String values = '';
    int sumAutoParticipants = 0;
    for (Attendee attendee in widget.pool.attendees.values) {
      if (!attendee.isAuto) {
        continue;
      }

      values += attendee.name + ' ' + attendee.value.toString() + ' (auto)\n';
      sumAutoParticipants += attendee.value;
    }


    Clipboard.setData(
      ClipboardData(
        text: 'Cagnotte de la période du ${startOfNextPeriod.toLocal().toString().split(' ')[0]} au ${endOfNextPeriod.toLocal().toString().split(' ')[0]}\n'
          'Promesses de dons (Nom suivi de pf, suivit de \'(auto)\' si vous voulez un report automatique)\n'
          '${values}\n'
          'Total ${sumAutoParticipants}'
      )
    );
  }

  List<DateTime> _computeNextPeriod() {
    DateTime startOfNextPeriod = selectedDate!.add(Duration(days: widget.periodDurationInDays));
    DateTime endOfNextPeriod = startOfNextPeriod.add(Duration(days: widget.periodDurationInDays - 1));

    return [startOfNextPeriod, endOfNextPeriod];
  }
}
