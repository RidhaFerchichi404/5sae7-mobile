import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_card.dart';
import '../domain/user_profile.dart';
import '../domain/user_validation.dart';
import 'user_providers.dart';

class ProfileGateScreen extends ConsumerStatefulWidget {
  const ProfileGateScreen({super.key});

  @override
  ConsumerState<ProfileGateScreen> createState() => _ProfileGateScreenState();
}

class _ProfileGateScreenState extends ConsumerState<ProfileGateScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _currency = AppConstants.defaultCurrency;
  UserValidationResult? _errors;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _create() async {
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
      await ref.read(activeUserIdProvider.notifier).create(result);
    } on AppFailure catch (error) {
      setState(() => _formError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(userListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyBudget'),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          FadeSlideIn(
            child: Text(
              'Create your profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          AppSpacing.gap,
          FadeSlideIn(
            index: 1,
            child: SectionCard(
              child: Column(
                children: [
          TextField(
            key: const Key('profile-name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _errors?.nameError,
            ),
          ),
          AppSpacing.gap,
          TextField(
            key: const Key('profile-email'),
            controller: _email,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _errors?.emailError,
            ),
          ),
          AppSpacing.gap,
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
            AppSpacing.gap,
            Text(_formError!, key: const Key('profile-form-error')),
          ],
                ],
              ),
            ),
          ),
          AppSpacing.section,
          FilledButton(
            key: const Key('create-profile'),
            onPressed: _create,
            child: const Text('Create profile'),
          ),
          AppSpacing.section,
          users.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Text(error.toString()),
            data: (items) {
              if (items.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Or continue',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AppSpacing.gap,
                  for (var i = 0; i < items.length; i++)
                    FadeSlideIn(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _ProfileTile(user: items[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: Text(user.currency),
        onTap: () => ref.read(activeUserIdProvider.notifier).select(user.id),
      ),
    );
  }
}
