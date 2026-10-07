import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/category.dart';
import '../domain/category_validation.dart';
import 'category_icons.dart';
import 'category_providers.dart';
import '../../users/presentation/user_providers.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.existing});

  final Category? existing;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  late final TextEditingController _name;
  late String _type;
  late String _icon;
  CategoryValidationResult? _errors;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _type = widget.existing?.type ?? AppConstants.expenseType;
    _icon = widget.existing?.icon ?? 'restaurant';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final result = validateCategoryInput(
      CategoryInput(name: _name.text, type: _type, icon: _icon),
    );
    setState(() {
      _errors = result;
      _formError = null;
    });
    if (!result.isValid) {
      return;
    }
    final userId = await ref.read(activeUserIdProvider.future);
    if (userId == null) {
      setState(() => _formError = 'Choose a profile first.');
      return;
    }
    try {
      final repository = ref.read(categoryRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repository.create(userId: userId, input: result);
      } else {
        await repository.update(current: existing, input: result);
      }
      ref.invalidate(categoryListProvider);
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
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New category' : 'Edit category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            key: const Key('category-name'),
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _errors?.nameError,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: AppConstants.expenseType,
                label: Text('Expense'),
              ),
              ButtonSegment(
                value: AppConstants.incomeType,
                label: Text('Income'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          if (_errors?.typeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errors!.typeError!),
            ),
          const SizedBox(height: 16),
          const Text('Icon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in AppConstants.iconCatalogue)
                IconButton(
                  key: Key('icon-$key'),
                  onPressed: () => setState(() => _icon = key),
                  style: IconButton.styleFrom(
                    backgroundColor: _icon == key
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : null,
                  ),
                  icon: Icon(iconForKey(key), color: AppColors.primary),
                ),
            ],
          ),
          if (_errors?.iconError != null) Text(_errors!.iconError!),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(_formError!, key: const Key('category-form-error')),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('save-category'),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
