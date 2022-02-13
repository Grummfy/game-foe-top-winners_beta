import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attendee.dart';
import '../models/pool.dart';
import './messages.dart';

class PointSplitterScreen extends StatefulWidget {
  Pool pool;

  PointSplitterScreen({Key? key, required this.pool}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PointSplitterScreenState();
}

class _PointSplitterScreenState extends State<PointSplitterScreen> {
  /// list of attendee that give PF to a player
  List<List<Attendee>> _splitterAttendees = <List<Attendee>>[];
  /// part that each winner will have
  List<double> _valuesForSplit = <double>[];
  /// goal to reach for each winners
  List<int> _distributionTotal = <int>[];
  /// total for each winners
  List<int> _winnerTotals = <int>[];
  /// distributor parts
  List<int> _distributorParts = <int>[];

  /// Get the value of distribution between winners
  List<double> _splitValues() {
    switch (widget.pool.winners.length) {
      case 3:
        return [0.5, 0.3, 0.2];
      case 4:
        return [0.4, 0.3, 0.2, 0.1];
      default:
        return List<double>.filled(widget.pool.winners.length, 0);
    }
  }

  /// Init the list of distribued attendee
  List<List<Attendee>> _computeSplitterAttendees() {
    // TODO, more a round-robin, with random and sum of col to skip the col ;)
    /*
       on trie la liste d'articles par ordre décroissant de taille, puis on range chaque article dans l'ordre. Dans first-fit, on range l'article courant dans la première boîte qui peut le contenir. Dans best-fit, on range l'article dans la boîte la mieux remplie qui puisse le contenir. Ces algorithmes ne sont pas optimaux, mais ils permettent d'obtenir de très bons résultats en pratique.
       https://fr.wikipedia.org/wiki/Probl%C3%A8me_de_bin_packing
      */
    List<List<Attendee>> resolved = <List<Attendee>>[];
    // 1. extract attendee into a new list
    var attendees = [ ...widget.pool.attendees.values.toList() ];
    // 2. init distributions with the winners as first element
    for (var attendee in widget.pool.winners) {
      resolved.add([attendee]);
      attendees.remove(attendee);
    }
    // 3. remove the distributor
    var distributor = widget.pool.distributor!;
    attendees.remove(widget.pool.distributor);

    // 4. finalise the basic distribution with what's left
    int cpt = 0;
    for (var attendee in attendees) {
      resolved[ cpt % resolved.length ].add(attendee);
      cpt++;
    }

    return resolved;
  }

  void _computeDistributionTotal() {
    // compute the total for each winners to reach
    _distributionTotal = List<int>.filled(_valuesForSplit.length, 0, growable: false);
    for (var i = 0; i < _valuesForSplit.length; i++) {
      _distributionTotal[ i ] = (_valuesForSplit[ i ] * widget.pool.total()).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    // init all values if not already initialized
    if (_valuesForSplit.isEmpty) {
      _valuesForSplit = _splitValues();
      _splitterAttendees = _computeSplitterAttendees();
      _distributorParts = List<int>.filled(_splitterAttendees.length, 0, growable: false);
      _computeDistributionTotal();
      _computeTotalOfWinners();
    }

    // create tabs header
    List<Tab> tabs = <Tab>[];
    int index = 1;
    for (var winner in widget.pool.winners) {
      String totalFOrThisWinner = (_winnerTotals[ index - 1 ]).toString();
      // TODO change style with total for each winner
      tabs.add(Tab(
          text: (index++).toString() + '. ' + winner.name + ' ($totalFOrThisWinner/' + _distributionTotal[ index - 2 ].toString() + ')',
      ));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Builder(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Séparation des points'),
            bottom: TabBar(
              tabs: tabs,
              isScrollable: true,
            ),
          ),
          body: TabBarView(
            children: List<Widget>.generate(_splitterAttendees.length, (int winnerIndex) {
              return _buildListOfAttendees(winnerIndex);
            })
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.skip_next_outlined),
                label: 'Valider',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_outlined),
                label: 'Répartition',
                tooltip: 'Changer la réparition des gagnants',
              ),
            ],
            currentIndex: 0,
            selectedItemColor: _isValid() ? Colors.lightGreen : Colors.redAccent,
            onTap: _onBottomTap,
          ),
        );
      }),
    );
  }

  void _onBottomTap(int index) {
    if (index == 1) {
      showDialog(
        context: context,
        builder: (context) => _changePointSplitterWidget(
          valuesForSplit: _valuesForSplit,
          onValueForSplitChanged: _onValueForSplitChanged,
          total: widget.pool.total(),
        ),
      );
    }

    if (index == 0 && _isValid()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            pool: widget.pool,
            distributorParts: _distributorParts,
            splitterAttendees: _splitterAttendees,
          ),
        ),
      );
    }
  }

  void _onValueForSplitChanged(List<double> valuesForSplit) {
    setState(() {
      _valuesForSplit = valuesForSplit;
      _computeDistributionTotal();
    });
  }

  void _onMoveDirection(int winnerPosition, int indexInList, bool moveToABetterWinner) {
    // check that we can't go before the first col
    if (winnerPosition <= 0 && moveToABetterWinner) {
      return;
    }

    // check that we can't go after the last col
    if (winnerPosition >= widget.pool.winners.length  && !moveToABetterWinner) {
      return;
    }

    // keep attendee
    Attendee current = _splitterAttendees[ winnerPosition ][ indexInList ];
    setState(() {
      // remove attendee from the lists
      _splitterAttendees[ winnerPosition ].removeAt(indexInList);
      // add to the new position
      _splitterAttendees[ winnerPosition + (moveToABetterWinner ? -1 : 1) ].add(current);
      _computeTotalOfWinners();
    });
  }

  void _computeTotalOfWinners() {
    _winnerTotals = List<int>.filled(_splitterAttendees.length, 0, growable: false);
    int winnerIndex = 0;
    for (var splitterAttendees in _splitterAttendees) {
      _winnerTotals[ winnerIndex ] = splitterAttendees.fold(0, (int previousValue, Attendee attendee) => previousValue += attendee.value);
      // add distributor part
      _winnerTotals[ winnerIndex ] += _distributorParts[ winnerIndex ];
      winnerIndex++;
    }
  }

  void onDistributorValueChanged(int newValue, int winnerIndex) {
    setState(() {
      _distributorParts[ winnerIndex ] = newValue;
      _computeTotalOfWinners();
    });
  }

  ListView _buildListOfAttendees(int winnerIndex) {
    // add attendee
    List<ListTile> tiles = <ListTile>[];
    for (var index = 0; index < _splitterAttendees[ winnerIndex ].length; index++) {
      tiles.add(_buildTile(winnerIndex, index));
    }

    // add distributor points
    tiles.add(
      ListTile(
        title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Part du distributeur'),
                    initialValue: _distributorParts[ winnerIndex ].toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      _maxDistributorValueTextInputFormatter(pointSplitterScreenState: this),
                    ],
                    onChanged: (String newValue) => newValue.isNotEmpty ? onDistributorValueChanged(int.parse(newValue), winnerIndex) : {},
                  )
                ),
                Text(' / ' + _sumOfDistributorStillAvailable().toString() + ' (' + widget.pool.distributor!.value.toString() + ')'),
              ],
            )
        )
      )
    );

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: tiles,
    );
  }

  ListTile _buildTile(int winnerIndex, int index) {
    return ListTile(
        title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Text(_splitterAttendees[ winnerIndex ][ index ].name + ' (' + _splitterAttendees[ winnerIndex ][ index ].value.toString() + 'Pfs)'),
                const Spacer(),
                winnerIndex > 0 && index != 0 ? IconButton(
                  tooltip: 'Déplacer vers le gagnants ${winnerIndex}',
                  icon: const Icon(Icons.arrow_left_outlined),
                  onPressed: () => _onMoveDirection(winnerIndex, index, true),
                ) : const SizedBox.shrink(),
                (_splitterAttendees.length - 1) > winnerIndex && index != 0 ? IconButton(
                  tooltip: 'Déplacer vers le gagnants ${winnerIndex + 2}',
                  icon: const Icon(Icons.arrow_right_outlined),
                  onPressed: () => _onMoveDirection(winnerIndex, index, false),
                ) : const SizedBox.shrink(),
              ],
            )
        )
    );
  }

  int _sumOfDistributorStillAvailable() {
    int available = _distributorParts.reduce((int sum, int value) => sum + value);
    return widget.pool.distributor!.value - available;
  }

  bool _isValid() {
    for (int index = 0; index < widget.pool.winners.length; index ++) {
      if (_winnerTotals[ index ] != _distributionTotal[ index ]) {
        return false;
      }
    }
    return true;
  }
}

class _changePointSplitterWidget extends StatefulWidget {
  List<double> valuesForSplit;
  final Function(List<double>) onValueForSplitChanged;
  final int total;

  _changePointSplitterWidget({
    Key? key,
    required this.valuesForSplit,
    required this.onValueForSplitChanged,
    required this.total,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _changePointSplitterWidgetState();
}

class _changePointSplitterWidgetState extends State<_changePointSplitterWidget> {
  @override
  Widget build(BuildContext context) {
    List<Widget> elements = List<Widget>.generate(widget.valuesForSplit.length, (int index) {
      String winnerNumber = (index + 1).toString();
      return SimpleDialogOption(
        child: TextFormField(
          decoration: InputDecoration(labelText: '% du $winnerNumber gagnant'),
          initialValue: (widget.valuesForSplit[ index ] * 100).toStringAsFixed(0),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (String newValue) => newValue.isNotEmpty ? setState(() => widget.valuesForSplit[ index ] = (int.parse(newValue) / 100) ) : {},
        )
      );
    });

    elements.add(
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: () => _onValidated(context),
                  child: const Text('Changer'),
                )
              )
            ]
          )
        )
      );

    return SimpleDialog(
      title: const Text('Changement de la réparition des points'),
      children: elements,
    );
  }

  _onValidated(BuildContext context) {
    widget.onValueForSplitChanged(widget.valuesForSplit);

    // get back to main screen
    Navigator.pop(context);
  }
}

class _maxDistributorValueTextInputFormatter extends TextInputFormatter {
  _PointSplitterScreenState pointSplitterScreenState;

  _maxDistributorValueTextInputFormatter({required this.pointSplitterScreenState});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return TextEditingValue().copyWith(text: '0');
    }

    int someValue = int.parse(newValue.text);
    int oldSomeValue = oldValue.text.isNotEmpty ? int.parse(oldValue.text) : 0;
    if (someValue <= 0) {
      return TextEditingValue().copyWith(text: '0');
    }

    // we need to add the old value to still available, because the function add this value to the sum...
    int stillAvailable = pointSplitterScreenState._sumOfDistributorStillAvailable() + oldSomeValue;

    if ((stillAvailable - someValue) < 0) {
      return TextEditingValue().copyWith(text: '${stillAvailable}');
    }

    return newValue;
  }
}
