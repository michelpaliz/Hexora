// lib/.../widgets/members_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/member_list/member_list.dart';

class Members extends StatelessWidget {
  const Members({
    super.key,
    required this.accepted,
    required this.pending,
    required this.notAccepted,
    required this.acceptedLabel,
    required this.pendingLabel,
    required this.notAcceptedLabel,
    this.useGradientBackground = false, // now means: use neutral colored panel
    this.wrapInCard = false,
  });

  final List<MemberRef> accepted;
  final List<MemberRef> pending;
  final List<MemberRef> notAccepted;
  final String acceptedLabel;
  final String pendingLabel;
  final String notAcceptedLabel;

  /// When true, parent uses a neutral colored panel (not a gradient).
  final bool useGradientBackground;

  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final acceptedSorted = [...accepted]..sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    final pendingSorted = [...pending]..sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    final notAcceptedSorted = [...notAccepted]..sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    return MembersList(
      accepted: acceptedSorted,
      pending: pendingSorted,
      notAccepted: notAcceptedSorted,
      acceptedLabel: acceptedLabel,
      pendingLabel: pendingLabel,
      notAcceptedLabel: notAcceptedLabel,
      useGradientBackground: useGradientBackground, // forwarded
      wrapInCard: wrapInCard,
    );
  }
}
