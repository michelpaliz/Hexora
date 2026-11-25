import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';

class CreateGroupUseCase {
  final GroupDomain groupDomain;
  final UserDomain userDomain;
  CreateGroupUseCase(this.groupDomain, this.userDomain);

  Future<Group> call({
    required String name,
    required String description,
    required String businessType,
    required String invoiceLanguage,
    required String legalName,
    required String taxId,
    required String addressStreet,
    required String addressCity,
    required String addressProvince,
    required String addressPostalCode,
    required String addressCountry,
    required String businessEmail,
    required String website,
    required String currency,
    required num vatRate,
    List<Map<String, dynamic>> invitations = const [],
    required User owner,
  }) async {
    final group = Group(
      id: '',
      name: name,
      ownerId: owner.id,
      userRoles: {owner.id: 'owner'},
      userIds: [owner.id],
      createdTime: DateTime.now(),
      description: description,
      businessType: businessType,
      defaultInvoiceLanguage: invoiceLanguage,
      creationBillingProfile: {
        'legalName': legalName,
        'taxId': taxId,
        'addressStreet': addressStreet,
        'addressCity': addressCity,
        'addressProvince': addressProvince,
        'addressPostalCode': addressPostalCode,
        'addressCountry': addressCountry,
        'email': businessEmail,
        'website': website,
        'currency': currency,
        'vatRate': vatRate,
        'language': invoiceLanguage,
      },
      creationInvitations: invitations,
      photoUrl: '',
      photoBlobName: null,
      defaultCalendarId: null,
      defaultCalendar: null,
    );
    final created = await groupDomain.createGroupReturning(group, userDomain);
    await groupDomain.refreshGroupsForCurrentUser(userDomain);
    return created;
  }
}
