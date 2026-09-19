class ProfileUpdateInput {
  final String displayName;
  final String userName;
  final String phoneNumber;
  final String location;
  final String bio;

  const ProfileUpdateInput({
    required this.displayName,
    required this.userName,
    required this.phoneNumber,
    required this.location,
    required this.bio,
  });
}

class ProfileUpdateValidationResult {
  final String? displayNameError;
  final String? userNameError;
  final String? phoneError;
  final String? locationError;
  final String? bioError;

  const ProfileUpdateValidationResult({
    this.displayNameError,
    this.userNameError,
    this.phoneError,
    this.locationError,
    this.bioError,
  });

  bool get isValid =>
      displayNameError == null &&
      userNameError == null &&
      phoneError == null &&
      locationError == null &&
      bioError == null;
}

class ProfileUpdateContract {
  static const int maxBioLength = 1000;
  static const int maxDisplayNameLength = 120;
  static const int maxPhoneLength = 40;
  static const int maxLocationLength = 140;

  static String normalizeUsername(String value) => value.trim().toLowerCase();

  static String? normalizeOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static ProfileUpdateValidationResult validate(ProfileUpdateInput input) {
    final normalizedUsername = normalizeUsername(input.userName);
    final displayName = input.displayName.trim();
    final phone = input.phoneNumber.trim();
    final location = input.location.trim();
    final bio = input.bio.trim();

    String? displayNameError;
    String? userNameError;
    String? phoneError;
    String? locationError;
    String? bioError;

    if (normalizedUsername.isEmpty) {
      userNameError = 'Username is required.';
    } else if (!RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(normalizedUsername)) {
      userNameError = 'Invalid username format.';
    }

    if (displayName.length > maxDisplayNameLength) {
      displayNameError = 'Display name is too long.';
    }
    if (phone.length > maxPhoneLength) {
      phoneError = 'Phone is too long.';
    }
    if (location.length > maxLocationLength) {
      locationError = 'Location is too long.';
    }
    if (bio.length > maxBioLength) {
      bioError = 'Bio is too long.';
    }

    return ProfileUpdateValidationResult(
      displayNameError: displayNameError,
      userNameError: userNameError,
      phoneError: phoneError,
      locationError: locationError,
      bioError: bioError,
    );
  }

  static Map<String, dynamic> buildPayload(ProfileUpdateInput input) {
    String normalizeOptionalAsString(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? '' : trimmed;
    }

    return <String, dynamic>{
      'displayName': normalizeOptionalAsString(input.displayName),
      'userName': normalizeUsername(input.userName),
      'phoneNumber': normalizeOptionalAsString(input.phoneNumber),
      'location': normalizeOptionalAsString(input.location),
      'bio': normalizeOptionalAsString(input.bio),
    };
  }

  static String mapErrorMessage({
    required int statusCode,
    String? backendMessage,
  }) {
    final msg = (backendMessage ?? '').trim();

    if (statusCode == 400) {
      if (msg.isNotEmpty) return msg;
      return 'Please check your profile values and try again.';
    }
    if (statusCode == 401) {
      return 'Your session expired. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'You are not allowed to update this profile.';
    }
    if (statusCode == 404) {
      return 'User not found.';
    }
    if (statusCode == 409) {
      return msg.isNotEmpty ? msg : 'Username already taken.';
    }
    return msg.isNotEmpty ? msg : 'Failed to save profile. Please try again.';
  }
}
