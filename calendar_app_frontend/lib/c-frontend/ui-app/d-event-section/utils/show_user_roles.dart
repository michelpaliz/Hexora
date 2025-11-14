// import 'package:hexora/models/user.dart';
// import 'package:hexora/services/firestore_database/logic_backend/firestore_service.dart';
// import 'package:hexora/utilities/utilities.dart';
// import 'package:flutter/material.dart';
// import 'package:hexora/l10n/app_localizations.dart';
// import 'dart:developer' as devtools show log;

// //** REMOVE AN USER */

//   // Function to remove a user from the group
//   void _removeUser(BuildContext context, String fetchedUserName) {
//     // Check if the user is the current user before attempting to remove
//     if (fetchedUserName == _currentUser?.userName) {
//       print('Cannot remove current user: $fetchedUserName');
//       // Show a message to the user that they cannot remove themselves
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(AppLocalizations.of(context)!.cannotRemoveYourself),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return;
//     }

//     // Show a confirmation dialog before removing the user
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Confirm Removal'),
//           content: Text(
//               'Are you sure you want to remove user $fetchedUserName from the group?'),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 // Perform the removal action if confirmed
//                 _performUserRemoval(fetchedUserName);
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text('Confirm'),
//             ),
//           ],
//         );
//       },
//     );
//   }

// class _BuildUserListTiles extends StatelessWidget {
//   final FirestoreService _storeService;
//   final Map<String, String> _userRoles;

//   const _BuildUserListTiles({
//     Key? key,
//     required FirestoreService storeService,
//     required Map<String, String> userRoles,
//   })  : _storeService = storeService,
//         _userRoles = userRoles,
//         super(key: key);

//   List<Widget> _buildUserListTiles() {
//     if (_userRoles.isNotEmpty) {
//       // Separate the administrator's username
//       String? administratorUserName;
//       Map<String, String> otherUserRoles = {};

//       // Iterate through the user roles to find the administrator's username
//       _userRoles.forEach((key, value) {
//         if (value == 'Administrator') {
//           administratorUserName = key;
//         } else {
//           otherUserRoles[key] = value;
//         }
//       });

//       // Sort the other usernames alphabetically
//       List<String> sortedOtherUserNames = otherUserRoles.keys.toList()..sort();

//       // Construct the final list of usernames
//       List<String> sortedUserNames = [];
//       if (administratorUserName != null) {
//         sortedUserNames.add(administratorUserName!);
//       }
//       sortedUserNames.addAll(sortedOtherUserNames);

//       return sortedUserNames.map((userName) {
//         final roleValue = _userRoles[userName];
//         return FutureBuilder<User?>(
//           future: _storeService.getUserByName(userName),
//           builder: (context, snapshot) {
//             devtools.log('This is username fetched $userName');
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return CircularProgressIndicator();
//             } else if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             } else if (snapshot.hasData) {
//               final user = snapshot.data;

//               return ListTile(
//                 title: Text(userName),
//                 subtitle: Text(roleValue!),
//                 leading: CircleAvatar(
//                   radius: 30,
//                   backgroundImage: Utilities.buildProfileImage(user?.photoUrl),
//                 ),
//                 trailing: GestureDetector(
//                   onTap: () {
//                     _removeUser(context, userName);
//                   },
//                   child: Icon(
//                     Icons.clear,
//                     color: Colors.red,
//                   ),
//                 ),
//                 onTap: () {},
//               );
//             } else {
//               return Text(AppLocalizations.of(context)!.userNotFound);
//             }
//           },
//         );
//       }).toList();
//     } else {
//       return [
//         Text("No user roles available")
//       ];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: _buildUserListTiles(),
//     );
//   }
// }
