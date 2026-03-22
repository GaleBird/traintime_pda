// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// SchoolNet password dialog.

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/repository/gxu_ids/gxu_schoolnet_credentials.dart';
import 'package:watermeter/repository/preference.dart' as preference;

class SchoolNetPasswordDialog extends StatefulWidget {
  const SchoolNetPasswordDialog({super.key});

  @override
  State<SchoolNetPasswordDialog> createState() =>
      _SchoolNetPasswordDialogState();
}

class _SchoolNetPasswordDialogState extends State<SchoolNetPasswordDialog> {
  late final TextEditingController _accountController;
  late final TextEditingController _schoolNetPasswordController;

  bool _couldView = true;

  @override
  void initState() {
    super.initState();
    final account = getGxuSchoolnetAccountDraft();
    final pwd = preference.getString(
      preference.Preference.schoolNetQueryPassword,
    );
    _accountController = TextEditingController.fromValue(
      TextEditingValue(
        text: account,
        selection: TextSelection.collapsed(offset: account.length),
      ),
    );
    _schoolNetPasswordController = TextEditingController.fromValue(
      TextEditingValue(
        text: pwd,
        selection: TextSelection.collapsed(offset: pwd.length),
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _schoolNetPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        FlutterI18n.translate(
          context,
          "setting.change_schoolnet_password_title",
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FlutterI18n.translate(context, "school_net.gxu.http_warning"),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            controller: _accountController,
            decoration: InputDecoration(
              labelText: FlutterI18n.translate(
                context,
                "school_net.gxu.account",
              ),
              hintText: FlutterI18n.translate(
                context,
                "setting.change_schoolnet_dialog.account_hint",
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _schoolNetPasswordController,
            obscureText: _couldView,
            decoration: InputDecoration(
              labelText: FlutterI18n.translate(
                context,
                "setting.schoolnet_password_setting",
              ),
              hintText: FlutterI18n.translate(
                context,
                "setting.change_schoolnet_dialog.password_hint",
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _couldView ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _couldView = !_couldView;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(FlutterI18n.translate(context, "cancel")),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(FlutterI18n.translate(context, "confirm")),
          onPressed: () async {
            final account = _accountController.text.trim();
            final password = _schoolNetPasswordController.text;
            if (account.isEmpty) {
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.change_schoolnet_dialog.account_required",
                ),
              );
              return;
            }
            if (password.isEmpty) {
              showToast(
                context: context,
                msg: FlutterI18n.translate(
                  context,
                  "setting.change_schoolnet_dialog.password_required",
                ),
              );
              return;
            }
            await persistManualGxuSchoolnetCredentials(
              account: account,
              password: password,
            );
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
        ),
      ],
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 7, 16, 16),
    );
  }
}
