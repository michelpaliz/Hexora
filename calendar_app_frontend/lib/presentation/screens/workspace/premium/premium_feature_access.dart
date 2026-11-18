import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:provider/provider.dart';

enum PremiumFeature { email, banking, aiChat, teamChat }

const foundingGroupId = '68e6c804d0cc32b5bafc02be';

bool hasPremiumFeature(Group? group, PremiumFeature feature) {
  if (group == null) return false;
  if (group.id == foundingGroupId) return true;
  final flags = group.features;
  return switch (feature) {
    PremiumFeature.email => flags?.premiumEmail ?? false,
    PremiumFeature.banking => flags?.premiumBanking ?? false,
    PremiumFeature.aiChat => flags?.premiumAiChat ?? false,
    PremiumFeature.teamChat => flags?.premiumTeamChat ?? false,
  };
}

bool canManagePremiumFeature(Group? group, String? userId, PremiumFeature feature) {
  if (!hasPremiumFeature(group, feature) || userId == null) return false;
  final role = group!.userRoles[userId];
  return group.ownerId == userId ||
      role == 'owner' || role == 'admin' || role == 'co-admin';
}

bool canManagePremiumFeatureForGroupId(
  BuildContext context, String groupId, PremiumFeature feature,
) {
  final group = context.read<GroupDomain?>()?.currentGroup;
  if (group?.id != groupId) return false;
  final userId = context.read<UserDomain?>()?.user?.id;
  return canManagePremiumFeature(group, userId, feature);
}
