import 'package:flutter/material.dart';
import '../models/pool.dart';
import '../models/attendee.dart';

class WinnerScreen extends StatefulWidget {
  Pool pool;

  WinnerScreen({Key? key, required this.pool}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  List<Attendee> filteredAttendees = <Attendee>[];
  String currentFilter = '';

  @override
  Widget build(BuildContext context) {
    if (filteredAttendees.isEmpty) {
      _recomputeFilteredList();
    }

    int numberOfAttendees = widget.pool.attendees.length;
    int numberOfWinners = widget.pool.winners.length;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Gagnants'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Text('Choix des gagnants ($numberOfWinners) et du répartiteur parmis $numberOfAttendees'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Expanded(
                child: _listWinnerAndDistributorWidget(
                  pool: widget.pool,
                  onRemoveDistributor: _onRemoveDistributor,
                  onRemoveWinner: _onRemoveWinner,
                  onWinnerMove: _onWinnerMove,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: _filterWidget(onFilterChange: _onFilterChange),
            ),
            // filter for list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Expanded(
                child: _listAttendeeWidget(
                  attendees: filteredAttendees,
                  onDefineDistributor: _onDefineDistributor,
                  onDefineWinner: _onDefineWinner,
                ),
              ),
            ),
          ],
        ));
  }

  void _onDefineDistributor(String distributorName) {
    setState(() {
      if (!widget.pool.attendees.containsKey(distributorName)) {
        return;
      }

      widget.pool.distributor = widget.pool.attendees[ distributorName ]!;
      _recomputeFilteredList();
    });
  }

  void _onDefineWinner(String winnerName) {
    setState(() {
      if (!widget.pool.attendees.containsKey(winnerName)) {
        return;
      }

      widget.pool.winners.add(widget.pool.attendees[ winnerName ]!);
      _recomputeFilteredList();
    });
  }

  void _onWinnerMove(Attendee attendee, bool isMoveDown) {
    setState(() {
      int currentIndex = widget.pool.winners.indexWhere((item) => item.name == attendee.name);

      if (!isMoveDown && currentIndex == 0) {
        return;
      }

      if (isMoveDown && currentIndex == widget.pool.winners.length - 1) {
        return;
      }

      widget.pool.winners.removeAt(currentIndex);
      widget.pool.winners.insert(currentIndex + (isMoveDown ? 1 : -1), attendee);

      _recomputeFilteredList();
    });
  }

  void _onRemoveWinner(Attendee winner) {
    setState(() {
      if (widget.pool.winners.remove(winner)) {
        _recomputeFilteredList();
      }
    });
  }

  void _onRemoveDistributor() {
    setState(() {
      widget.pool.distributor = null;
      _recomputeFilteredList();
    });
  }

  void _onFilterChange(String newFilter) {
    setState(() {
      currentFilter = newFilter;
      _recomputeFilteredList();
    });
  }

  void _recomputeFilteredList() {
    filteredAttendees = <Attendee>[];
    widget.pool.attendees.forEach((String key, Attendee value)
    {
      if (widget.pool.distributor?.name == key || widget.pool.winners.contains(value)) {
        return;
      }

      if (value.name.toLowerCase().contains(currentFilter.toLowerCase())) {
        filteredAttendees.add(value);
      }
    });
  }
}

class _listWinnerAndDistributorWidget extends StatelessWidget {
  final Pool pool;
  final Function() onRemoveDistributor;
  final Function(Attendee) onRemoveWinner;
  final Function(Attendee, bool) onWinnerMove;

  const _listWinnerAndDistributorWidget({
    Key? key,
    required this.pool,
    required this.onRemoveDistributor,
    required this.onRemoveWinner,
    required this.onWinnerMove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: _buildList(),
    );
  }

  // convert winners & distrubutor to clickable elements
  List<ListTile> _buildList() {
    List<ListTile> showList = <ListTile>[];

    if (pool.distributor != null) {
      showList.add(ListTile(
        title: Text(pool.distributor!.name + ' ' + pool.distributor!.value.toString() + ' PFs' + ' (Distributeur)'),
        leading: const Icon(Icons.person_outline_rounded),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Enlever',
              onPressed: onRemoveDistributor,
            ),
          ],
        ),
      ));
    }

    int winner = 0;
    for (var attendee in pool.winners) {
      winner++;
      showList.add(ListTile(
        title: Row(
          children: [
            Text(winner.toString() + '.' + attendee.name + ' ' +  attendee.value.toString() + ' PFs'),
            attendee.isAuto ? const Icon(Icons.autorenew) : const SizedBox.shrink(),
          ],
        ),
        leading: const Icon(Icons.person_outline_rounded),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            winner > 1
                ? IconButton(
                    icon: const Icon(Icons.arrow_upward_outlined),
                    tooltip: 'Monter',
                    onPressed: () => onWinnerMove(attendee, false),
                  )
                : const SizedBox.shrink(),
            winner < pool.winners.length
                ? IconButton(
              icon: const Icon(Icons.arrow_downward_outlined),
              tooltip: 'Descendre',
              onPressed: () => onWinnerMove(attendee, true),
            )
                : const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Enlever',
              onPressed: () => onRemoveWinner(attendee),
            ),
          ],
        ),
      ));
    }

    return showList;
  }
}

class _filterWidget extends StatelessWidget {
  final ValueChanged<String> onFilterChange;

  const _filterWidget({
    Key? key,
    required this.onFilterChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: BorderSide(
              style: BorderStyle.solid,
              color: const UnderlineInputBorder().borderSide.color,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  hintText: 'Rechercher parmis les participants',
                  labelText: 'Filtre',
                ),
                onChanged: onFilterChange,
              ),
            ),
          ],
      )
    );
  }
}

class _listAttendeeWidget extends StatelessWidget {
  final List<Attendee> attendees;
  final Function(String) onDefineDistributor;
  final Function(String) onDefineWinner;

  const _listAttendeeWidget({
    Key? key,
    required this.attendees,
    required this.onDefineDistributor,
    required this.onDefineWinner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const ClampingScrollPhysics(),
      itemCount: attendees.length,
      itemBuilder: (BuildContext context, int index) => ListTile(
        title: Text(attendees[ index ].name),
        leading: const Icon(Icons.person_outline_rounded),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.account_box_rounded),
              tooltip: 'Définir en tant que distributeur',
              onPressed: () => onDefineDistributor(attendees[ index ].name),
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart_outlined),
              tooltip: 'Définir en tant que gagnant',
              onPressed: () => onDefineWinner(attendees[ index ].name),
            ),
          ],
        ),
      ),
    );
  }
}
