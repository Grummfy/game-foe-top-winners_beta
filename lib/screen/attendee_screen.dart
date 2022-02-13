import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/attendee.dart';
import '../components/labelled_switch.dart';
import '../models/pool.dart';
import './winner_screen.dart';

class AttendeeScreen extends StatefulWidget {
  AttendeeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AttendeeScreenState();
}

class _AttendeeScreenState extends State<AttendeeScreen> {
  List<String> errors = <String>[];
  List<Attendee> attendees = <Attendee>[];
  String attendeeTxtValue = '';
  bool extractedValue = false;

  void _onDeleteAttendeeInList(int index) {
    setState(() => errors.removeAt(index));
  }

  void _onAddAttendee(int index, Attendee newAttendee) {
    print('Add ' + newAttendee.toString());
    setState(() {
      attendees.add(newAttendee);
      errors.removeAt(index);
    });
  }

  void _onNextScreen(BuildContext context) {
    // sort elements by values
    var items = attendees;
    items.sort((a, b) => b.value - a.value);

    // create the pool
    Pool pool = Pool();
    pool.attendees = { for (var attendee in items) attendee.name : attendee };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WinnerScreen(pool: pool),
      ),
    );
  }

  void _onExtractValue(String txtValue) {
    // no value => do nothing!
    if (txtValue.trim().isEmpty) {
      return;
    }

    // split line into element and then get values
    List<String> elements = txtValue
        // remove blanks
        .trim()
        // remove ':' to avoid any strange behaviour
        .replaceAll(':', ' ')
        // split line by line
        .split("\n");

    RegExp regexRule = RegExp("^(.+)\\s+:?([0-9]+)(\\s*\\(\\s?auto\\s?\\){1})?\$");
    List<Attendee> items = <Attendee>[];
    elements.forEach((String element) {
      // skip empty line
      if (element.trim().isEmpty) {
        return;
      }

      var line = regexRule.firstMatch(element.trim());

      // avoir empty line, and total line
      if (line != null && line.groupCount == 3) {
        // skip total line
        if (line[1]?.trim().toLowerCase() == 'total') {
          return;
        }

        items.add(Attendee(
            line[1]!.trim(),
            int.parse(line[2]!),
            line[3] != null
        ));
      }
      else
      {
        // skip first line ;)
        if (element == elements.first) {
          return;
        }
        // line skipped
        errors.add(element.trim());
      }
    });

    setState(() {
      attendees = items;
      extractedValue = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _AttendeesTxtWidget attendeeWidget = _AttendeesTxtWidget(initialValue: attendeeTxtValue);
    _AttendeeErrorWidget listAttendeeErrorWidget = _AttendeeErrorWidget(
      errors: errors,
      onDeleteItemPressed: _onDeleteAttendeeInList,
      onAttendeeAdded: _onAddAttendee,
    );

    return Scaffold(
        appBar: AppBar(
          title: const Text('Participants'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: attendeeWidget,
            ),
            Row(
              children: <Widget>[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: ElevatedButton(
                    child: const Text('Extraire'),
                    onPressed: () {
                      _onExtractValue(attendeeWidget.text);
                    },
                  ),
                ),
                extractedValue ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: ElevatedButton(
                    child: const Text('Valider !'),
                    style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                    ),
                    onPressed: () {
                      _onNextScreen(context);
                    },
                  ),
                ) : const SizedBox.shrink(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: _TotalWidget(
                  total: attendees.fold(0, (int accumulator, Attendee attendee) => accumulator + attendee.value),
                  countAttendees: attendees.length
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: listAttendeeErrorWidget,
            ),
            Row(
              children: <Widget>[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: ElevatedButton(
                    child: const Text('Debug test'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blueGrey
                    ),
                    onPressed: () {
                      // fill textarea with debug text
                      setState(() {
                        attendeeTxtValue = "blabla foo bar lorem ipsum : HBHJQJBQBHB\n\nQuietus 100\nHonorius   40\nD.Willy 40 (auto)\nLilliann 100   	(auto)\nCirius 40\nBidule's 456 : 40\nBob :10\nJijy : 80(auto)\n\nLaure 50\nElemental 100\nKarelcote 40\nFoo 40\nBar 40\n Euric 200 ( auto )\nmam's62 (30)\nTotal 950";
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}

class _AttendeesTxtWidget extends StatelessWidget {
  late final TextEditingController _valueController;
  String get text => _valueController.text;

  _AttendeesTxtWidget({Key? key, String? initialValue}) : super(key: key) {
    _valueController = TextEditingController(text: initialValue ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: 8,
      decoration: const InputDecoration(
        border: UnderlineInputBorder(),
        hintText: 'Coller le dernier messages des participants',
        labelText: 'Participants',
      ),
      controller: _valueController,
    );
  }
}

class _TotalWidget extends StatelessWidget {
  final int total;
  final int countAttendees;

  const _TotalWidget({this.total = 0, this.countAttendees = 0, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return total > 0
        ? Text('Total de ' + total.toString() + ' PFs pour ' + countAttendees.toString() + ' participants.')
        : const SizedBox.shrink();
  }
}

class _AttendeeErrorWidget extends StatelessWidget {
  final List<String> errors;
  final Function(int, Attendee)? onAttendeeAdded;
  final Function(int)? onDeleteItemPressed;

  const _AttendeeErrorWidget({
    Key? key,
    this.errors = const <String>[],
    this.onAttendeeAdded,
    this.onDeleteItemPressed
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: errors.length,
          itemBuilder: (context, index) => _createListTile(index, context),
        ),
      ],
    );
  }

  ListTile _createListTile(int index, BuildContext context) {
    // remove icon
    // add icon
    return ListTile(
      title: Text(errors[index]),
      leading: Icon(Icons.error_outline_rounded, color: Theme.of(context).errorColor),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => _AttendeeErrorDialogWidget(
                  label: errors[index],
                  onAttendeeAdded: _onAttendeeCreated(index),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDeleteItemPressed != null ? () { onDeleteItemPressed!(index); } : null,
          ),
        ],
      ),
    );
  }

  Function(Attendee)? _onAttendeeCreated(int index) {
    print('clicked on ' + index.toString());
    if (onAttendeeAdded == null) {
      return null;
    }

    return (Attendee newAttendee) => onAttendeeAdded!(index, newAttendee);
  }
}

class _AttendeeErrorDialogWidget extends StatelessWidget {
  final String label;
  final Function(Attendee)? onAttendeeAdded;

  String name = '';
  int value = 0;
  bool isAuto = false;

  _AttendeeErrorDialogWidget({Key? key, this.onAttendeeAdded, this.label = ""}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextFormField pfs = TextFormField(
      decoration: const InputDecoration(labelText: 'PFs'),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (String newValue) => value = int.parse(newValue)
    );

    TextFormField txtName = TextFormField(
      decoration: const InputDecoration(labelText: 'Nom'),
      initialValue: label,
      onChanged: (String newValue) => name = newValue,
    );

    return AlertDialog(
      title: const Text('Ajout d\'un participant'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          txtName,
          pfs,
          LabeledSwitch(
            label: 'auto?',
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            value: isAuto,
            onChanged: (newValue) => isAuto = newValue,
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _onValidated(context),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  _onValidated(BuildContext context) {
    // add attendee
    if (onAttendeeAdded != null) {
      onAttendeeAdded!(Attendee(name, value, isAuto));
    }

    // get back to main screen
    Navigator.pop(context);
  }
}
