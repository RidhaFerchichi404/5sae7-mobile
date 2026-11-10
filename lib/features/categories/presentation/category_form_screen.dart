import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_card.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/category.dart';
import '../domain/category_validation.dart';
import 'category_icons.dart';
import 'category_providers.dart';

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
  final _query = TextEditingController();
  List<String> _results = const [];
  bool _searching = false;
  String? _searchMessage;

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
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    final found = await ref.read(iconifyClientProvider).search(_query.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _searching = false;
      _results = found.take(24).toList();
      _searchMessage = found.isEmpty
          ? 'No icons found. Check your connection or try another word.'
          : null;
    });
  }

  Widget _iconChoice(String key) {
    final colors = AppColors.of(context);
    return IconButton(
      key: Key('icon-$key'),
      tooltip: key,
      onPressed: () => setState(() => _icon = key),
      style: IconButton.styleFrom(
        backgroundColor: _icon == key ? colors.secondary : null,
      ),
      icon: CategoryIcon(key, color: colors.ink),
    );
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
        padding: AppSpacing.screen,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('category-name'),
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _errors?.nameError,
                  ),
                ),
                AppSpacing.gap,
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
                  onSelectionChanged: (value) =>
                      setState(() => _type = value.first),
                ),
                if (_errors?.typeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_errors!.typeError!),
                  ),
                AppSpacing.section,
                Text('Icon', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.gap,
                FadeSlideIn(
                  index: 2,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in AppConstants.iconCatalogue)
                        _iconChoice(key),
                    ],
                  ),
                ),
                AppSpacing.gap,
                TextField(
                  key: const Key('icon-search'),
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: 'Search more icons',
                    helperText: 'Free icons from Iconify. Needs internet.',
                    suffixIcon: IconButton(
                      tooltip: 'Search icons',
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
                  ),
                ),
                if (_searching) ...[
                  AppSpacing.gap,
                  const LinearProgressIndicator(),
                ],
                if (_searchMessage != null) ...[
                  AppSpacing.gap,
                  Text(_searchMessage!),
                ],
                AppSpacing.gap,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Keep a searched icon visible once chosen.
                    if (isIconifyKey(_icon) && !_results.contains(_icon))
                      _iconChoice(_icon),
                    for (final key in _results) _iconChoice(key),
                  ],
                ),
                if (_errors?.iconError != null) Text(_errors!.iconError!),
                if (_formError != null) ...[
                  AppSpacing.gap,
                  Text(_formError!, key: const Key('category-form-error')),
                ],
              ],
            ),
          ),
          AppSpacing.section,
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
