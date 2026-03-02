class StatementsAllDataTableLayout {
  static const double leadingSpacer = 2.0;
  static const double checkWidth = 28.0;

  static const double batchWidth = 60.0;
  static const double dateWidth = 96.0;

  static const double amountWidth = 110.0;

  // Description constraints (capped)
  static const double descMinWidth = 180.0;
  static const double descMaxWidth = 230.0;

  // Balance constraints (so it can grow but not too much)
  static const double balanceMinWidth = 120.0;
  static const double balanceMaxWidth = 150.0;

  // Client min width to avoid getting too small
  static const double clientMinWidth = 200.0;

  static const double balanceClientGap = 16.0;
  static const double horizontalPadding = 8.0;

  static const double columnGap = 6.0;
  static const double columnGapWide = 8.0;

  // kept for backwards compatibility (not used if you move to flex)
  static const double balanceWidth = 170.0;
  static const double clientWidth = 280.0;
  static const double invoiceWidth = 110.0;
  static const double actionsWidth = 130.0;
}
