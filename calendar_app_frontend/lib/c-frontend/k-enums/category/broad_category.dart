import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';

enum BroadCategory { group, user, system, other }

class BroadCategoryManager {
  BroadCategory? _selectedCategory;

  // Map existing categories to broader categories
  final Map<Category, BroadCategory> categoryMapping = {
    Category.groupCreation: BroadCategory.group,
    Category.groupUpdate: BroadCategory.group,
    Category.groupInvitation: BroadCategory.group,
    Category.userRemoval: BroadCategory.user,
    Category.userInvitation: BroadCategory.user,
    Category.message: BroadCategory.user,
    Category.systemAlert: BroadCategory.system,
    Category.systemUpdate: BroadCategory.system,
    Category.errorReport: BroadCategory.system,
    Category.eventReminder: BroadCategory.other,
    Category.taskUpdate: BroadCategory.other,
    Category.achievement: BroadCategory.other,
    Category.billing: BroadCategory.other,
    Category.actionRequired: BroadCategory.other,
    Category.feedbackRequest: BroadCategory.other,
  };

  BroadCategory? get selectedCategory => _selectedCategory;

  void filterNotifications(BroadCategory? category) {
    _selectedCategory = category;
  }
}

/// Extension to localize BroadCategory values
extension BroadCategoryLocalization on BroadCategory {
  String localizedName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case BroadCategory.group:
        return loc.categoryGroup;
      case BroadCategory.user:
        return loc.categoryUser;
      case BroadCategory.system:
        return loc.categorySystem;
      case BroadCategory.other:
        return loc.categoryOther;
    }
  }
}
