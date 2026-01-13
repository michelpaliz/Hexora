class StatementsAllDataTableLayout {
  static const double leadingSpacer = 4.0;
  static const double checkWidth = 32.0;

  static const double batchWidth = 120.0;
  static const double dateWidth = 120.0;

  static const double amountWidth = 140.0;

  // Description constraints (capped)
  static const double descMinWidth = 220.0;
  static const double descMaxWidth = 260.0;

  // ✅ NEW: balance constraints (so it can grow but not too much)
  static const double balanceMinWidth = 150.0;
  static const double balanceMaxWidth = 170.0;

  // ✅ NEW: (optional) client min width to avoid getting too small
  static const double clientMinWidth = 260.0;

  static const double balanceClientGap = 36.0;
  static const double horizontalPadding = 12.0;

  static const double columnGap = 8.0;
  static const double columnGapWide = 10.0;

  // kept for backwards compatibility (not used if you move to flex)
  static const double balanceWidth = 210.0;
  static const double clientWidth = 340.0;
  static const double invoiceWidth = 150.0;
  static const double actionsWidth = 112.0;
}
