import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/category/event_category.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'widgets/category_create_dialog.dart';
import 'widgets/category_picker_view.dart';

class CategoryPicker extends StatefulWidget {
  final CategoryApi api;
  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final ValueChanged<({String? categoryId, String? subcategoryId})> onChanged;

  /// Optional header above the control. If provided, dropdowns will not show their internal labelText
  /// to avoid duplicated titles (header wins).
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
    final typo = AppTypography.of(context);

    final name = await showCategoryCreateDialog(
      context: context,
      title: parentId == null ? l.newCategory : l.newSubcategory,
      hintText: l.nameHint,
      confirmText: l.add,
      cancelText: l.cancel,
      titleStyle: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      buttonTextStyle: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      final created = await widget.api.create(EventCategory(
        id: 'tmp', // ignored server-side
        name: name.trim(),
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
      // Soft error; just refresh list to reflect server truth if needed
      await _load();
      // Optionally show a snackbar/toast in your app-level scaffold
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Precompute valid selections without mutating during build.
    final parents = _parents;
    final String? selectedCatId =
        parents.any((p) => p.id == _catId) ? _catId : null;

    final children =
        selectedCatId == null ? <EventCategory>[] : _childrenOf(selectedCatId);

    final String? selectedSubId =
        children.any((c) => c.id == _subId) ? _subId : null;

    return CategoryPickerView(
      label: widget.label, // header (optional)
      loading: _loading,
      error: _error,
      parents: parents,
      children: children,
      selectedCategoryId: selectedCatId,
      selectedSubcategoryId: selectedSubId,
      showFieldLabels: widget.label == null, // 🔑 no duplicate titles
      onRefresh: _load,
      onCreateParent: () => _createCategory(),
      onCreateChild: selectedCatId == null
          ? null
          : () => _createCategory(parentId: selectedCatId),
      onCategoryChanged: (id) {
        setState(() {
          _catId = id;
          _subId = null;
        });
        widget.onChanged((categoryId: _catId, subcategoryId: _subId));
      },
      onSubcategoryChanged: (id) {
        setState(() => _subId = id);
        widget.onChanged((categoryId: _catId, subcategoryId: _subId));
      },
      l10n: l,
    );
  }
}
