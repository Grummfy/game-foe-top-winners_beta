extension ListExtensions<T> on List<T> {
  bool containsAt(T value, int index) {
    assert(this != null);
    return index >= 0 && this.length > index && this[index] == value;
  }

  bool indexExist(int index) {
    assert(this != null);
    return index >= 0 && this.length > index;
  }
}
