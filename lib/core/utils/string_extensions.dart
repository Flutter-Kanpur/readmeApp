extension CategoryCasing on String {
  String smartCategoryCase() {
    if (isEmpty) return this;

    // Acronyms like UI, DSA, API
    if (length <= 3) {
      return toUpperCase();
    }

    // Normal words
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
