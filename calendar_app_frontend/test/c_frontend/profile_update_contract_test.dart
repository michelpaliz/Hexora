import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/controller/profile_update_contract.dart';

void main() {
  test('successful payload with all fields', () {
    final payload = ProfileUpdateContract.buildPayload(
      const ProfileUpdateInput(
        displayName: '  Michel Plaza  ',
        userName: ' MiChelP ',
        phoneNumber: ' 123456789 ',
        location: ' Denia ',
        bio: ' Bio text ',
      ),
    );

    expect(payload['displayName'], 'Michel Plaza');
    expect(payload['userName'], 'michelp');
    expect(payload['phoneNumber'], '123456789');
    expect(payload['location'], 'Denia');
    expect(payload['bio'], 'Bio text');
  });

  test('clearing optional fields sends empty strings', () {
    final payload = ProfileUpdateContract.buildPayload(
      const ProfileUpdateInput(
        displayName: ' ',
        userName: 'worker_01',
        phoneNumber: '',
        location: '   ',
        bio: '',
      ),
    );

    expect(payload['displayName'], '');
    expect(payload['phoneNumber'], '');
    expect(payload['location'], '');
    expect(payload['bio'], '');
    expect(payload['userName'], 'worker_01');
  });

  test('invalid username fails validation', () {
    final validation = ProfileUpdateContract.validate(
      const ProfileUpdateInput(
        displayName: 'Michel',
        userName: 'Bad User Name',
        phoneNumber: '',
        location: '',
        bio: '',
      ),
    );

    expect(validation.isValid, isFalse);
    expect(validation.userNameError, isNotNull);
  });

  test('duplicate username maps to friendly message', () {
    final message = ProfileUpdateContract.mapErrorMessage(
      statusCode: 409,
      backendMessage: 'Username already taken',
    );
    expect(message.toLowerCase(), contains('username'));
    expect(message.toLowerCase(), contains('taken'));
  });

  test('bio length limit is enforced', () {
    final longBio = 'a' * (ProfileUpdateContract.maxBioLength + 1);
    final validation = ProfileUpdateContract.validate(
      ProfileUpdateInput(
        displayName: 'Michel',
        userName: 'michelp',
        phoneNumber: '',
        location: '',
        bio: longBio,
      ),
    );

    expect(validation.isValid, isFalse);
    expect(validation.bioError, isNotNull);
  });
}
