class InvoiceSummaryLayout {
  static const double gap = 12;
  static const double qtyWidth = 120;
  static const double unitWidth = 160;
  static const double vatWidth = 140;
  static const double totalWidth = 170;
  static const double minDescWidth = 320;

  static const double minLinesTableWidth = minDescWidth +
      qtyWidth +
      unitWidth +
      vatWidth +
      totalWidth +
      (gap * 4);
}

