import 'attendee.dart';

class Pool {
  Map<String, Attendee> attendees = <String, Attendee>{};
  Attendee? distributor;
  List<Attendee> winners = <Attendee>[];
  int _total = 0;

  int total() {
    if (_total <= 0) {
      _total = attendees.values.toList().fold(0, (int accumulator, Attendee entry) => accumulator + entry.value);
    }
    return _total;
  }

  void resetTotal() {
    _total = 0;
  }
}
