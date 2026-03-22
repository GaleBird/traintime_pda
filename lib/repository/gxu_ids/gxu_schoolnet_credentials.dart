// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:watermeter/repository/preference.dart' as preference;

const _missingSchoolnetPassword = "school_net.empty_password";
const _missingSchoolnetAccount = "school_net.gxu.account_missing";

bool isGxuSchoolnetCredentialError(String value) {
  return value == _missingSchoolnetPassword ||
      value == _missingSchoolnetAccount;
}

String getGxuSchoolnetAccount() {
  final savedAccount = _savedSchoolnetAccount();
  if (savedAccount.isNotEmpty) {
    return savedAccount;
  }
  final idsAccount = preference
      .getString(preference.Preference.idsAccount)
      .trim();
  final idsPassword = preference
      .getString(preference.Preference.idsPassword)
      .trim();
  if (idsAccount.isEmpty || idsPassword.isEmpty) {
    return "";
  }
  return idsAccount;
}

String getGxuSchoolnetAccountDraft() {
  final savedAccount = _savedSchoolnetAccount();
  if (savedAccount.isNotEmpty) {
    return savedAccount;
  }
  return preference.getString(preference.Preference.idsAccount).trim();
}

bool hasGxuSchoolnetCredentials() {
  final password = preference.getString(
    preference.Preference.schoolNetQueryPassword,
  );
  return getGxuSchoolnetAccount().isNotEmpty && password.isNotEmpty;
}

Future<void> syncGxuSchoolnetAccountFromPasswordLogin(String account) async {
  final normalized = account.trim();
  await preference.setString(preference.Preference.idsAccount, normalized);
  await preference.setString(
    preference.Preference.schoolNetQueryAccount,
    normalized,
  );
  await preference.setBool(
    preference.Preference.schoolNetQueryAccountUserDefined,
    false,
  );
}

Future<void> persistManualGxuSchoolnetCredentials({
  required String account,
  required String password,
}) async {
  await preference.setString(
    preference.Preference.schoolNetQueryAccount,
    account.trim(),
  );
  await preference.setBool(
    preference.Preference.schoolNetQueryAccountUserDefined,
    true,
  );
  await preference.setString(
    preference.Preference.schoolNetQueryPassword,
    password,
  );
}

Future<void> handleGxuSmsLoginSuccess(String phone) async {
  final previousPhone = preference.getString(preference.Preference.gxuCaPhone);
  final keepManualSchoolnetAccount =
      previousPhone.isNotEmpty &&
      previousPhone == phone &&
      preference.getBool(
        preference.Preference.schoolNetQueryAccountUserDefined,
      );
  if (!keepManualSchoolnetAccount) {
    await preference.remove(preference.Preference.schoolNetQueryAccount);
    await preference.remove(preference.Preference.schoolNetQueryPassword);
    await preference.setBool(
      preference.Preference.schoolNetQueryAccountUserDefined,
      false,
    );
  }
  await preference.setString(preference.Preference.gxuCaPhone, phone);
  await preference.remove(preference.Preference.idsAccount);
  await preference.remove(preference.Preference.idsPassword);
}

String _savedSchoolnetAccount() {
  return preference
      .getString(preference.Preference.schoolNetQueryAccount)
      .trim();
}
