import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/iso_time.dart';
import '../domain/user_profile.dart';
import '../domain/user_validation.dart';
import 'user_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserProfile user;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late String _currency;
  UserValidationResult? _errors;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _email = TextEditingController(text: widget.user.email);
    _currency = widget.user.currency;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final result = validateUserInput(
      UserInput(name: _name.text, email: _email.text, currency: _currency),
    );
    setState(() {
      _errors = result;
      _formError = null;
    });
    if (!result.isValid) {
      return;
    }
    try {
      await ref.read(userRepositoryProvider).update(widget.user, result);
      ref.invalidate(userListProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AppFailure catch (error) {
      setState(() => _formError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _errors?.nameError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _errors?.emailError,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: InputDecoration(
              labelText: 'Currency',
              errorText: _errors?.currencyError,
            ),
            items: [
              for (final code in AppConstants.currencies)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _currency = value);
              }
            },
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(_formError!),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(height: 8),
          Text(
            'Created ${IsoTime.date(widget.user.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
