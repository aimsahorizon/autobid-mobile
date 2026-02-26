import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/agreement_field_entity.dart';

/// Unified collaborative agreement tab that replaces separate seller/buyer forms.
/// Both parties can add, edit, and delete fields until they lock.
/// After both lock → review → confirm → 15s grace → auto-finalize.
class UnifiedAgreementTab extends StatelessWidget {
  final TransactionRealtimeController controller;
  final String userId;

  const UnifiedAgreementTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final txn = controller.transaction;
        if (txn == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final role = controller.getUserRole(userId);
        final isSeller = role == FormRole.seller;
        final myLocked = isSeller
            ? txn.sellerFormSubmitted
            : txn.buyerFormSubmitted;
        final otherLocked = isSeller
            ? txn.buyerFormSubmitted
            : txn.sellerFormSubmitted;
        final myConfirmed = isSeller ? txn.sellerConfirmed : txn.buyerConfirmed;
        final otherConfirmed = isSeller
            ? txn.buyerConfirmed
            : txn.sellerConfirmed;
        final bothLocked = txn.bothFormsSubmitted;
        final bothConfirmed = txn.bothConfirmed;
        final finalized = txn.adminApproved;
        final readOnly = myLocked || finalized;
        final fields = controller.agreementFields;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status header
                    _StatusHeader(
                      myLocked: myLocked,
                      otherLocked: otherLocked,
                      myConfirmed: myConfirmed,
                      otherConfirmed: otherConfirmed,
                      finalized: finalized,
                      secondsRemaining: controller.secondsRemaining,
                      isSeller: isSeller,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Info card
                    if (!finalized && fields.isEmpty && !myLocked)
                      _buildEmptyState(isDark),

                    // Agreement fields by category
                    ..._buildFieldsByCategory(
                      context,
                      fields,
                      readOnly,
                      finalized,
                      isDark,
                    ),

                    // Add field section (only when editing)
                    if (!readOnly) ...[
                      const SizedBox(height: 16),
                      _AddFieldSection(controller: controller, isDark: isDark),
                    ],

                    const SizedBox(height: 100), // Space for action bar
                  ],
                ),
              ),
            ),

            // Bottom action bar
            _ActionBar(
              controller: controller,
              myLocked: myLocked,
              otherLocked: otherLocked,
              myConfirmed: myConfirmed,
              otherConfirmed: otherConfirmed,
              bothLocked: bothLocked,
              bothConfirmed: bothConfirmed,
              finalized: finalized,
              secondsRemaining: controller.secondsRemaining,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: ColorConstants.info,
          ),
          const SizedBox(height: 12),
          Text(
            'Collaborative Agreement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ColorConstants.textPrimaryDark
                  : ColorConstants.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this shared document to agree on transaction details. '
            'Both parties can add and edit fields. '
            'Tap "Add from Templates" below to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldsByCategory(
    BuildContext context,
    List<AgreementFieldEntity> fields,
    bool readOnly,
    bool finalized,
    bool isDark,
  ) {
    if (fields.isEmpty) return [];

    // Group fields by category
    final grouped = <String, List<AgreementFieldEntity>>{};
    for (final field in fields) {
      grouped.putIfAbsent(field.category, () => []).add(field);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        _CategorySection(
          category: entry.key,
          fields: entry.value,
          readOnly: readOnly,
          finalized: finalized,
          isDark: isDark,
          controller: controller,
        ),
      );
    }
    return widgets;
  }
}

// =============================================================================
// STATUS HEADER
// =============================================================================
class _StatusHeader extends StatelessWidget {
  final bool myLocked;
  final bool otherLocked;
  final bool myConfirmed;
  final bool otherConfirmed;
  final bool finalized;
  final int? secondsRemaining;
  final bool isSeller;
  final bool isDark;

  const _StatusHeader({
    required this.myLocked,
    required this.otherLocked,
    required this.myConfirmed,
    required this.otherConfirmed,
    required this.finalized,
    required this.secondsRemaining,
    required this.isSeller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (finalized) {
      return _banner(
        Icons.check_circle,
        ColorConstants.success,
        'Agreement Finalized',
        'Transaction has been finalized. Proceed with delivery.',
      );
    }

    if (secondsRemaining != null && myConfirmed && otherConfirmed) {
      return _banner(
        Icons.timer,
        ColorConstants.warning,
        'Grace Period: ${secondsRemaining}s',
        'Both parties confirmed. Finalizing shortly. You may still withdraw.',
      );
    }

    if (myConfirmed && otherConfirmed) {
      return _banner(
        Icons.hourglass_bottom,
        ColorConstants.info,
        'Both Confirmed',
        'Finalizing transaction...',
      );
    }

    if (myConfirmed && !otherConfirmed) {
      return _banner(
        Icons.hourglass_empty,
        ColorConstants.info,
        'You Confirmed',
        'Waiting for the other party to confirm...',
      );
    }

    if (!myConfirmed && otherConfirmed) {
      return _banner(
        Icons.rate_review,
        ColorConstants.warning,
        'Other Party Confirmed',
        'Please review the agreement and confirm.',
      );
    }

    if (myLocked && otherLocked) {
      return _banner(
        Icons.verified_user,
        ColorConstants.primary,
        'Both Locked — Review Mode',
        'Both parties locked. Review the agreement and confirm when ready.',
      );
    }

    if (myLocked && !otherLocked) {
      return _banner(
        Icons.lock,
        ColorConstants.info,
        'You Locked',
        'Waiting for the other party to finish editing and lock...',
      );
    }

    if (!myLocked && otherLocked) {
      return _banner(
        Icons.edit,
        ColorConstants.warning,
        'Other Party Locked',
        'The other party is done. Finish editing and lock when ready.',
      );
    }

    // Both editing
    return _statusRow();
  }

  Widget _banner(IconData icon, Color color, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Row(
      children: [
        Expanded(
          child: _lockBadge(
            'You',
            myLocked,
            isSeller ? Icons.storefront : Icons.person,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _lockBadge(
            isSeller ? 'Buyer' : 'Seller',
            otherLocked,
            isSeller ? Icons.person : Icons.storefront,
          ),
        ),
      ],
    );
  }

  Widget _lockBadge(String label, bool locked, IconData icon) {
    final color = locked ? ColorConstants.success : ColorConstants.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: ${locked ? "Locked" : "Editing"}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(locked ? Icons.lock : Icons.edit, size: 14, color: color),
        ],
      ),
    );
  }
}

// =============================================================================
// CATEGORY SECTION
// =============================================================================
class _CategorySection extends StatelessWidget {
  final String category;
  final List<AgreementFieldEntity> fields;
  final bool readOnly;
  final bool finalized;
  final bool isDark;
  final TransactionRealtimeController controller;

  const _CategorySection({
    required this.category,
    required this.fields,
    required this.readOnly,
    required this.finalized,
    required this.isDark,
    required this.controller,
  });

  IconData _categoryIcon() {
    switch (category) {
      case 'Vehicle Information':
        return Icons.directions_car;
      case 'Payment Terms':
        return Icons.payments;
      case 'Document Checklist':
        return Icons.folder_copy;
      case 'Vehicle Condition':
        return Icons.build;
      case 'Handover / Delivery':
        return Icons.local_shipping;
      case 'Additional Costs':
        return Icons.receipt_long;
      case 'Terms & Conditions':
        return Icons.gavel;
      default:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(
            _categoryIcon(),
            color: ColorConstants.primary,
            size: 20,
          ),
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${fields.length} field${fields.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          children: [
            const Divider(height: 1),
            ...fields.map(
              (field) => _AgreementFieldTile(
                field: field,
                readOnly: readOnly,
                isDark: isDark,
                onChanged: (value) =>
                    controller.updateAgreementField(field.id, value),
                onDelete: readOnly || finalized
                    ? null
                    : () => controller.deleteAgreementField(field.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AGREEMENT FIELD TILE
// =============================================================================
class _AgreementFieldTile extends StatefulWidget {
  final AgreementFieldEntity field;
  final bool readOnly;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDelete;

  const _AgreementFieldTile({
    required this.field,
    required this.readOnly,
    required this.isDark,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_AgreementFieldTile> createState() => _AgreementFieldTileState();
}

class _AgreementFieldTileState extends State<_AgreementFieldTile> {
  late TextEditingController _textController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.field.value);
  }

  @override
  void didUpdateWidget(_AgreementFieldTile old) {
    super.didUpdateWidget(old);
    if (old.field.id != widget.field.id ||
        (old.field.value != widget.field.value &&
            widget.field.value != _textController.text)) {
      _textController.text = widget.field.value;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _buildFieldInput()),
          if (widget.onDelete != null)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: ColorConstants.error.withValues(alpha: 0.7),
              ),
              onPressed: widget.onDelete,
              tooltip: 'Remove field',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildFieldInput() {
    switch (widget.field.fieldType) {
      case 'boolean':
        return _buildBoolField();
      case 'date':
        return _buildDateField();
      case 'select':
        return _buildSelectField();
      case 'number':
        return _buildTextField(keyboardType: TextInputType.number);
      default:
        return _buildTextField();
    }
  }

  Widget _buildTextField({TextInputType? keyboardType}) {
    return TextField(
      controller: _textController,
      readOnly: widget.readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.field.label,
        labelStyle: const TextStyle(fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        border: widget.readOnly ? InputBorder.none : null,
      ),
      onChanged: widget.readOnly ? null : _onTextChanged,
      onSubmitted: widget.readOnly ? null : (v) => widget.onChanged(v),
    );
  }

  Widget _buildBoolField() {
    return SwitchListTile(
      title: Text(widget.field.label, style: const TextStyle(fontSize: 14)),
      value: widget.field.boolValue,
      onChanged: widget.readOnly ? null : (v) => widget.onChanged(v.toString()),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: ColorConstants.success,
    );
  }

  Widget _buildDateField() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        widget.field.label,
        style: TextStyle(
          fontSize: 13,
          color: widget.isDark
              ? ColorConstants.textSecondaryDark
              : ColorConstants.textSecondaryLight,
        ),
      ),
      subtitle: Text(
        widget.field.value.isNotEmpty ? widget.field.value : 'Not set',
        style: TextStyle(
          fontSize: 14,
          color: widget.field.value.isNotEmpty
              ? (widget.isDark
                    ? ColorConstants.textPrimaryDark
                    : ColorConstants.textPrimaryLight)
              : Colors.grey,
        ),
      ),
      trailing: widget.readOnly
          ? null
          : Icon(Icons.calendar_today, size: 18, color: ColorConstants.primary),
      onTap: widget.readOnly
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.tryParse(widget.field.value) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (date != null) {
                final formatted =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                widget.onChanged(formatted);
              }
            },
    );
  }

  Widget _buildSelectField() {
    final options = widget.field.selectOptions;
    final currentValue = options.contains(widget.field.value) ? widget.field.value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey(currentValue),
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: widget.field.label,
        labelStyle: const TextStyle(fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: widget.readOnly ? InputBorder.none : null,
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: widget.readOnly
          ? null
          : (v) {
              if (v != null) widget.onChanged(v);
            },
    );
  }
}

// =============================================================================
// ADD FIELD SECTION
// =============================================================================
class _AddFieldSection extends StatelessWidget {
  final TransactionRealtimeController controller;
  final bool isDark;

  const _AddFieldSection({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showTemplatePicker(context),
            icon: const Icon(Icons.playlist_add, size: 18),
            label: const Text(
              'Add from Templates',
              style: TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.primary,
              side: BorderSide(
                color: ColorConstants.primary.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCustomFieldDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Custom Field', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.info,
              side: BorderSide(
                color: ColorConstants.info.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _showTemplatePicker(BuildContext context) {
    final selected = <String, Set<int>>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            int totalSelected = 0;
            for (final s in selected.values) {
              totalSelected += s.length;
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.playlist_add,
                            color: ColorConstants.primary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Add Fields from Templates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (totalSelected > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstants.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalSelected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Template categories
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: AgreementTemplates.categories.entries.map((
                          entry,
                        ) {
                          final cat = entry.key;
                          final templates = entry.value;
                          final catSelected = selected[cat] ?? <int>{};

                          return ExpansionTile(
                            leading: Icon(
                              _iconForCategory(cat),
                              color: ColorConstants.primary,
                              size: 20,
                            ),
                            title: Text(
                              cat,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${templates.length} fields',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? ColorConstants.textSecondaryDark
                                    : ColorConstants.textSecondaryLight,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                setState(() {
                                  if (catSelected.length == templates.length) {
                                    selected[cat] = {};
                                  } else {
                                    selected[cat] = Set.from(
                                      List.generate(templates.length, (i) => i),
                                    );
                                  }
                                });
                              },
                              child: Text(
                                catSelected.length == templates.length
                                    ? 'None'
                                    : 'All',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorConstants.primary,
                                ),
                              ),
                            ),
                            children: templates.asMap().entries.map((te) {
                              final idx = te.key;
                              final tmpl = te.value;
                              return CheckboxListTile(
                                value: catSelected.contains(idx),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  tmpl.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  _fieldTypeLabel(tmpl.fieldType),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? ColorConstants.textSecondaryDark
                                        : ColorConstants.textSecondaryLight,
                                  ),
                                ),
                                activeColor: ColorConstants.primary,
                                onChanged: (v) {
                                  setState(() {
                                    final s = selected.putIfAbsent(
                                      cat,
                                      () => <int>{},
                                    );
                                    if (v == true) {
                                      s.add(idx);
                                    } else {
                                      s.remove(idx);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                    // Add button
                    if (totalSelected > 0)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                _addSelectedTemplates(selected);
                                Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                'Add $totalSelected Field${totalSelected != 1 ? 's' : ''}',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: ColorConstants.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _addSelectedTemplates(Map<String, Set<int>> selected) {
    for (final entry in selected.entries) {
      final cat = entry.key;
      final indices = entry.value;
      final templates = AgreementTemplates.categories[cat];
      if (templates == null) continue;

      for (final idx in indices) {
        if (idx >= templates.length) continue;
        final tmpl = templates[idx];
        controller.addAgreementField(
          label: tmpl.label,
          fieldType: tmpl.fieldType,
          category: cat,
          options: tmpl.options,
        );
      }
    }
  }

  void _showCustomFieldDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    String fieldType = 'text';
    String category = 'general';
    final optionsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: ColorConstants.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Custom Field',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Field Label',
                        hintText: 'e.g. Special Condition',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(fieldType),
                      initialValue: fieldType,
                      decoration: const InputDecoration(
                        labelText: 'Field Type',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text')),
                        DropdownMenuItem(
                          value: 'number',
                          child: Text('Number'),
                        ),
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(
                          value: 'boolean',
                          child: Text('Yes / No'),
                        ),
                        DropdownMenuItem(
                          value: 'select',
                          child: Text('Dropdown'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => fieldType = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(category),
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: 'general',
                          child: Text('General'),
                        ),
                        ...AgreementTemplates.categories.keys.map(
                          (k) => DropdownMenuItem(value: k, child: Text(k)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => category = v);
                      },
                    ),
                    if (fieldType == 'select') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: optionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Options (comma-separated)',
                          hintText: 'e.g. Yes,No,Maybe',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (labelCtrl.text.trim().isEmpty) return;
                    controller.addAgreementField(
                      label: labelCtrl.text.trim(),
                      fieldType: fieldType,
                      category: category,
                      options: fieldType == 'select'
                          ? optionsCtrl.text.trim()
                          : null,
                    );
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Vehicle Information':
        return Icons.directions_car;
      case 'Payment Terms':
        return Icons.payments;
      case 'Document Checklist':
        return Icons.folder_copy;
      case 'Vehicle Condition':
        return Icons.build;
      case 'Handover / Delivery':
        return Icons.local_shipping;
      case 'Additional Costs':
        return Icons.receipt_long;
      case 'Terms & Conditions':
        return Icons.gavel;
      default:
        return Icons.note;
    }
  }

  String _fieldTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Text';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'boolean':
        return 'Yes / No';
      case 'select':
        return 'Dropdown';
      default:
        return type;
    }
  }
}

// =============================================================================
// ACTION BAR
// =============================================================================
class _ActionBar extends StatelessWidget {
  final TransactionRealtimeController controller;
  final bool myLocked;
  final bool otherLocked;
  final bool myConfirmed;
  final bool otherConfirmed;
  final bool bothLocked;
  final bool bothConfirmed;
  final bool finalized;
  final int? secondsRemaining;
  final bool isDark;

  const _ActionBar({
    required this.controller,
    required this.myLocked,
    required this.otherLocked,
    required this.myConfirmed,
    required this.otherConfirmed,
    required this.bothLocked,
    required this.bothConfirmed,
    required this.finalized,
    required this.secondsRemaining,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (finalized) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildButtons(context),
        ),
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final buttons = <Widget>[];

    // Grace period countdown with withdraw
    if (bothConfirmed && secondsRemaining != null) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.isProcessing
                ? null
                : () => _withdrawConfirmation(context),
            icon: const Icon(Icons.undo, size: 18),
            label: Text('Withdraw Confirmation (${secondsRemaining}s)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.warning,
              side: const BorderSide(color: ColorConstants.warning),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
      return buttons;
    }

    // Confirmed, waiting for other party
    if (myConfirmed && !otherConfirmed) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.isProcessing
                ? null
                : () => _withdrawConfirmation(context),
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Withdraw Confirmation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.warning,
              side: const BorderSide(color: ColorConstants.warning),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
      return buttons;
    }

    // Both locked, not yet confirmed — show confirm + unlock
    if (bothLocked && !myConfirmed) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.isProcessing
                ? null
                : () => _confirmAgreement(context),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm Agreement'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(height: 8));
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.isProcessing
                ? null
                : () => _unlockAgreement(context),
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('Unlock to Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.info,
              side: BorderSide(
                color: ColorConstants.info.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
      return buttons;
    }

    // Locked, waiting for other party
    if (myLocked && !otherLocked) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.isProcessing
                ? null
                : () => _unlockAgreement(context),
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('Unlock to Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.info,
              side: BorderSide(
                color: ColorConstants.info.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
      return buttons;
    }

    // Not locked — show lock button
    if (!myLocked) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.isProcessing
                ? null
                : () => _lockAgreement(context),
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Lock Agreement'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
      return buttons;
    }

    return buttons;
  }

  Future<void> _lockAgreement(BuildContext context) async {
    final success = await controller.lockAgreement();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to lock agreement'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _unlockAgreement(BuildContext context) async {
    final success = await controller.unlockAgreement();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to unlock agreement',
          ),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _confirmAgreement(BuildContext context) async {
    final success = await controller.confirmAgreement();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to confirm agreement',
          ),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _withdrawConfirmation(BuildContext context) async {
    final success = await controller.withdrawAgreementConfirmation();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to withdraw confirmation',
          ),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }
}
