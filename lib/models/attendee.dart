// attendee to the pool
class Attendee {
  final String name;
  final int value;
  final bool isAuto;

  Attendee(this.name, this.value, [this.isAuto = false]);

  @override
  toString() {
    return 'Attendee: "' + this.name + '" with ' + this.value.toString() + ' PF and with ' + (this.isAuto ? 'auto' : 'no auto');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['value'] = this.value;
    data['isAuto'] = this.isAuto;
    return data;
  }
}
