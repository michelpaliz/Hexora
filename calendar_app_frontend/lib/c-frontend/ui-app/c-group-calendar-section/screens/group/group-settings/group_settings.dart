import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:intl/intl.dart';

class GroupSettings extends StatelessWidget {
  final Group group;

  const GroupSettings({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final created = DateFormat.yMMMd().format(group.createdTime);
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupImage(context),
            const SizedBox(height: 20),
            _buildInfoTile("Description", group.description),
            _buildInfoTile("Owner ID", group.ownerId),
            _buildInfoTile("Created On", created),
            _buildInfoTile("Member Count", "${group.userIds.length}"),
            const SizedBox(height: 12),

            _buildSectionTitle("User Roles"),
            ...group.userRoles.entries.map(
              (e) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text("User ID: ${e.key}"),
                subtitle: Text("Role: ${e.value}"),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 20),

            // Invitations now live in their own collection
            _buildSectionTitle("Invitations"),
            Text(
              "Invitations are managed separately.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.mail_outline),
              label: const Text("View Invitations"),
              onPressed: () {
                // TODO: hook up to your route / screen that lists invitations for this group
                // Example:
                // Navigator.pushNamed(context, AppRoutes.groupInvitations, arguments: group.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupImage(BuildContext context) {
    final url = group.photoUrl ?? group.computedPhotoUrl ?? '';
    if (url.isEmpty) {
      return const Center(
        child: CircleAvatar(
          radius: 50,
          child: Icon(Icons.group, size: 40),
        ),
      );
    }

    // More resilient than CircleAvatar(backgroundImage) since we can handle errors.
    return Center(
      child: ClipOval(
        child: Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const CircleAvatar(
            radius: 50,
            child: Icon(Icons.group, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
