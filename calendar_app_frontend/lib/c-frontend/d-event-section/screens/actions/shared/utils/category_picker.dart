// lib/c-frontend/shared/widgets/category_picker.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/category/event_category.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CategoryPicker extends StatefulWidget {
  final CategoryApi api;
  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final ValueChanged<({String? categoryId, String? subcategoryId})> onChanged;
  final String? label;

  const CategoryPicker({
    super.key,
    required this.api,
    required this.onChanged,
    this.initialCategoryId,
    this.initialSubcategoryId,
    this.label,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  bool _loading = true;
  String? _error;

  List<EventCategory> _all = [];
  String? _catId;
  String? _subId;

  @override
  void initState() {
    super.initState();
    _catId = widget.initialCategoryId;
    _subId = widget.initialSubcategoryId;
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final cats = await widget.api.list();
      setState(() {
        _all = cats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<EventCategory> get _parents =>
      _all.where((c) => c.parentId == null).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<EventCategory> _childrenOf(String parentId) =>
      _all.where((c) => c.parentId == parentId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Future<void> _createCategory({String? parentId}) async {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          parentId == null ? l.newCategory : l.newSubcategory,
          style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l.nameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l.cancel, style: typo.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.add,
                style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (res == null || res.isEmpty) return;

    try {
      final created = await widget.api.create(EventCategory(
        id: 'tmp', // ignored server-side
        name: res,
        parentId: parentId,
      ));
      setState(() {
        _all = [..._all, created];
        if (parentId == null) {
          _catId = created.id;
          _subId = null;
        } else {
          _catId = parentId;
          _subId = created.id;
        }
      });
      widget.onChanged((categoryId: _catId, subcategoryId: _subId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.failedToCreate(e.toString()),
            style: typo.bodySmall.copyWith(color: cs.onErrorContainer),
          ),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: cs.surfaceVariant,
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.errorContainer),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            IconButton(
              tooltip: l.refresh,
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    // Empty state (no categories yet)
    if (_all.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                widget.label!,
                style: typo.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.noCategoriesYet,
                    style: typo.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  tooltip: l.addCategory,
                  onPressed: () => _createCategory(),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final parents = _parents;

    // Ensure dropdown values are valid without mutating state in build
    final String? selectedCatId =
        parents.any((p) => p.id == _catId) ? _catId : null;

    final children =
        selectedCatId == null ? <EventCategory>[] : _childrenOf(selectedCatId);

    final String? selectedSubId =
        children.any((c) => c.id == _subId) ? _subId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!,
              style: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),

        // Parent category
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedCatId,
                decoration: InputDecoration(
                  labelText: l.category,
                  labelStyle: typo.bodySmall,
                ),
                items: parents
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: typo.bodyMedium),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _catId = v;
                    _subId = null; // reset subs when parent changes
                  });
                  widget.onChanged((categoryId: _catId, subcategoryId: _subId));
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l.addCategory,
              onPressed: () => _createCategory(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Subcategory
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedSubId,
                decoration: InputDecoration(
                  labelText: l.subcategory,
                  labelStyle: typo.bodySmall,
                ),
                items: children
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: typo.bodyMedium),
                        ))
                    .toList(),
                onChanged: selectedCatId == null
                    ? null
                    : (v) {
                        setState(() => _subId = v);
                        widget.onChanged(
                          (categoryId: _catId, subcategoryId: _subId),
                        );
                      },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l.addSubcategory,
              onPressed: selectedCatId == null
                  ? null
                  : () => _createCategory(parentId: selectedCatId),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
