// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/listing_draft_controller.dart';
import 'form_field_widget.dart';
import 'ai_price_predictor.dart';

class Step8FinalDetails extends StatefulWidget {
  final ListingDraftController controller;

  const Step8FinalDetails({super.key, required this.controller});

  @override
  State<Step8FinalDetails> createState() => _Step8FinalDetailsState();
}

class _Step8FinalDetailsState extends State<Step8FinalDetails> {
  late TextEditingController _descriptionController;
  late TextEditingController _issuesController;
  late TextEditingController _featureController;
  late TextEditingController _startingPriceController;
  late TextEditingController _reservePriceController;
  late TextEditingController _bidIncrementController;

  List<String> _features = [];
  String _biddingType = 'public'; // 'public' or 'private'
  bool _enableIncrementalBidding = true;
  String _scheduleLiveMode = 'manual'; // 'auto_live', 'manual', 'auto_schedule'
  bool _allowsInstallment = false;
  String _endTimeMode = 'date'; // 'date' or 'duration'
  DateTime? _auctionEndDate;
  DateTime? _auctionStartDate;
  int? _auctionDurationHours;
  String? _scheduleError;
  bool _demoMode = false; // Bypasses 24hr validation for testing

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft;

    // Initialize with defaults if draft is null
    _descriptionController = TextEditingController(text: draft?.description);
    _issuesController = TextEditingController(text: draft?.knownIssues);
    _featureController = TextEditingController();
    _startingPriceController = TextEditingController(
      text: _formatDouble(draft?.startingPrice),
    );
    _reservePriceController = TextEditingController(
      text: _formatDouble(draft?.reservePrice),
    );
    _bidIncrementController = TextEditingController(
      text: _formatDouble(draft?.bidIncrement ?? draft?.minBidIncrement ?? 100),
    );
    _features = draft?.features ?? [];
    _biddingType = draft?.biddingType ?? 'public';
    _enableIncrementalBidding = draft?.enableIncrementalBidding ?? true;
    _scheduleLiveMode = draft?.scheduleLiveMode ?? 'manual';
    _allowsInstallment = draft?.allowsInstallment ?? false;
    _auctionEndDate = draft?.auctionEndDate;
    _auctionStartDate = draft?.auctionStartDate;
    _auctionDurationHours = draft?.auctionDurationHours;
    _endTimeMode = (_auctionDurationHours != null && _auctionEndDate == null)
        ? 'duration'
        : 'date';

    _descriptionController.addListener(_updateDraft);
    _issuesController.addListener(_updateDraft);
    _startingPriceController.addListener(_updateDraft);
    _reservePriceController.addListener(_updateDraft);
    _bidIncrementController.addListener(_updateDraft);
  }

  String? _formatDouble(double? value) {
    if (value == null) return null;
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _issuesController.dispose();
    _featureController.dispose();
    _startingPriceController.dispose();
    _reservePriceController.dispose();
    _bidIncrementController.dispose();
    super.dispose();
  }

  void _updateDraft() {
    final draft = widget.controller.currentDraft;
    if (draft == null) return; // Guard against null draft

    widget.controller.updateDraft(
      draft.copyWith(
        lastSaved: DateTime.now(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        knownIssues: _issuesController.text.isEmpty
            ? null
            : _issuesController.text,
        features: _features.isEmpty ? null : _features,
        startingPrice: () {
          if (_startingPriceController.text.isEmpty) return null;
          final parsed = double.tryParse(_startingPriceController.text);
          return (parsed != null && parsed > 0) ? parsed : null;
        }(),
        reservePrice: () {
          if (_reservePriceController.text.isEmpty) return null;
          final parsed = double.tryParse(_reservePriceController.text);
          return (parsed != null && parsed > 0) ? parsed : null;
        }(),
        auctionEndDate: _auctionEndDate,
        // Scheduling
        scheduleLiveMode: _scheduleLiveMode,
        autoLiveAfterApproval: _scheduleLiveMode == 'auto_live',
        auctionStartDate: _auctionStartDate,
        auctionDurationHours: _auctionDurationHours,
        // Bidding Configuration
        biddingType: _biddingType,
        bidIncrement: () {
          if (_bidIncrementController.text.isEmpty) return null;
          final parsed = double.tryParse(_bidIncrementController.text);
          return (parsed != null && parsed > 0) ? parsed : null;
        }(),
        minBidIncrement: () {
          if (_bidIncrementController.text.isEmpty) return null;
          final parsed = double.tryParse(_bidIncrementController.text);
          return (parsed != null && parsed > 0) ? parsed : null;
        }(),
        depositAmount: _calculateDeposit(
          double.tryParse(_startingPriceController.text),
        ),
        enableIncrementalBidding: _enableIncrementalBidding,
        allowsInstallment: _allowsInstallment,
      ),
    );
  }

  /// Auto-calculate deposit based on starting price.
  /// Philippine-reasonable: enough to prove seriousness, not too expensive.
  /// Range: ₱5,000 – ₱50,000 in ₱5,000 increments.
  static double _calculateDeposit(double? startingPrice) {
    if (startingPrice == null || startingPrice <= 0) return 5000;
    // ~3-5% of starting price, rounded to nearest 5k, clamped 5k-50k
    final raw = startingPrice * 0.04;
    final rounded = (raw / 5000).round() * 5000;
    return rounded.clamp(5000, 50000).toDouble();
  }

  void _addFeature() {
    if (_featureController.text.trim().isEmpty) return;
    setState(() {
      _features.add(_featureController.text.trim());
      _featureController.clear();
    });
    _updateDraft();
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
    _updateDraft();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.controller.currentDraft;

    // Show loading if draft hasn't loaded yet
    if (draft == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final startingPrice = double.tryParse(_startingPriceController.text) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Step 8: Final Details & Bidding Configuration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // ===== DEED OF SALE PREVIEW =====
        if (draft.deedOfSaleUrl != null && draft.deedOfSaleUrl!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Deed of Sale',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Uploaded',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: draft.deedOfSaleUrl!.toLowerCase().endsWith('.pdf')
                      ? Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'PDF Document',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () =>
                              _showDeedFullImage(context, draft.deedOfSaleUrl!),
                          child: Image.network(
                            draft.deedOfSaleUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.grey.withValues(alpha: 0.1),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ===== DESCRIPTION & DETAILS SECTION =====
        const Text(
          'Description & Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _descriptionController,
          label: 'Description *',
          hint: 'Describe your vehicle in detail...',
          maxLines: 5,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v!.length < 50) return 'Minimum 50 characters';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${_descriptionController.text.length}/50 characters minimum',
          style: TextStyle(
            fontSize: 12,
            color: _descriptionController.text.length >= 50
                ? Colors.green
                : Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _issuesController,
          label: 'Known Issues (Optional)',
          hint: 'Disclose any known issues or defects...',
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FormFieldWidget(
                controller: _featureController,
                label: 'Features',
                hint: 'e.g., Sunroof, Leather Seats',
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addFeature,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (_features.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _features.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                onDeleted: () => _removeFeature(entry.key),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 32),
        const Divider(),

        // ===== PRICING SECTION =====
        const SizedBox(height: 16),
        const Text(
          'Pricing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // AI Price Predictor
        AiPricePredictor(
          draft: draft,
          onApplyPrice: (price) {
            final reserve = price * 1.1; // Default reserve 10% higher
            setState(() {
              _startingPriceController.text = price.toStringAsFixed(0);
              _reservePriceController.text = reserve.toStringAsFixed(0);
            });
            _updateDraft();

            (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
              SnackBar(
                content: Text(
                  'Applied suggested price: ₱${price.toStringAsFixed(0)}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),

        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _startingPriceController,
          label: 'Starting Price (₱) *',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            final start = double.tryParse(v!);
            if (start == null) return 'Invalid price';
            if (start % 100 != 0) return 'Must be a multiple of ₱100';

            if (_reservePriceController.text.isNotEmpty) {
              final reserve = double.tryParse(_reservePriceController.text);
              if (reserve != null && start >= reserve) {
                return 'Must be lower than reserve price';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _reservePriceController,
          label: 'Reserve Price (₱)',
          hint: 'Optional minimum acceptable price',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.isEmpty) return null; // Optional
            final reserve = double.tryParse(v);
            if (reserve == null) return 'Invalid price';
            if (reserve % 100 != 0) return 'Must be a multiple of ₱100';

            if (_startingPriceController.text.isNotEmpty) {
              final start = double.tryParse(_startingPriceController.text);
              if (start != null && reserve <= start) {
                return 'Must be higher than starting price';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        const Divider(),

        // ===== BIDDING CONFIGURATION SECTION =====
        const SizedBox(height: 16),
        const Text(
          'Bidding Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure how buyers can bid on your auction',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Launch Mode *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              RadioListTile<String>(
                title: const Text('Manual'),
                subtitle: const Text(
                  'After approval, you choose when to go live or schedule',
                  style: TextStyle(fontSize: 12),
                ),
                secondary: const Icon(Icons.touch_app, color: Colors.grey),
                value: 'manual',
                groupValue: _scheduleLiveMode,
                onChanged: (v) {
                  setState(() {
                    _scheduleLiveMode = v!;
                    _auctionStartDate = null;
                    _scheduleError = null;
                  });
                  _updateDraft();
                },
              ),
              RadioListTile<String>(
                title: const Text('Auto-Live After Approval'),
                subtitle: const Text(
                  'Auction goes live immediately when approved',
                  style: TextStyle(fontSize: 12),
                ),
                secondary: const Icon(Icons.flash_on, color: Colors.orange),
                value: 'auto_live',
                groupValue: _scheduleLiveMode,
                onChanged: (v) {
                  setState(() {
                    _scheduleLiveMode = v!;
                    _auctionStartDate = null;
                    _scheduleError = null;
                  });
                  _updateDraft();
                },
              ),
              RadioListTile<String>(
                title: const Text('Auto-Schedule'),
                subtitle: Text(
                  _demoMode
                      ? 'Set a start date/time (demo: no restrictions)'
                      : 'Set a start date/time (must be ≥24h from now for approval)',
                  style: const TextStyle(fontSize: 12),
                ),
                secondary: const Icon(Icons.schedule_send, color: Colors.blue),
                value: 'auto_schedule',
                groupValue: _scheduleLiveMode,
                onChanged: (v) {
                  setState(() {
                    _scheduleLiveMode = v!;
                    _scheduleError = null;
                  });
                  _updateDraft();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Demo mode toggle
        Card(
          color: _demoMode ? Colors.amber.withValues(alpha: 0.15) : null,
          child: SwitchListTile(
            title: const Text('🧪 Demo Mode'),
            subtitle: Text(
              _demoMode
                  ? 'Validation bypassed — any time allowed'
                  : 'Enable to skip 24hr scheduling restrictions',
              style: const TextStyle(fontSize: 12),
            ),
            value: _demoMode,
            onChanged: (v) {
              setState(() {
                _demoMode = v;
                _scheduleError = null;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Start Date picker (auto_schedule only)
        if (_scheduleLiveMode == 'auto_schedule') ...[
          _buildStartDatePicker(context),
          const SizedBox(height: 16),
        ],

        // End Date / Duration picker (all modes)
        _buildEndTimeSection(context),
        if (_scheduleError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _scheduleError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Bidding Type Selection
        const Text(
          'Bidding Type *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Theme.of(context).colorScheme.onSurface;
                  }),
                ),
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'public',
                    label: Text('Public'),
                    icon: Icon(Icons.public),
                  ),
                  ButtonSegment<String>(
                    value: 'private',
                    label: Text('Private'),
                    icon: Icon(Icons.lock),
                  ),
                ],
                selected: <String>{_biddingType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _biddingType = newSelection.first;
                  });
                  _updateDraft();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _biddingType == 'public'
                ? 'Any buyer can see and bid on your auction'
                : 'Only invited buyers can see and bid on your auction',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 24),

        // Anti-Sniping Configuration
        const Text(
          'Anti-Sniping Protection',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Extend auction if bids are placed in the final minutes',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey(draft.snipeGuardThresholdSeconds),
          decoration: InputDecoration(
            labelText: 'Trigger Window',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          // Ensure initial value is valid
          initialValue: (draft.snipeGuardThresholdSeconds ?? 1800),
          items: [
            DropdownMenuItem(value: 300, child: Text('Last 5 minutes')),
            DropdownMenuItem(value: 600, child: Text('Last 10 minutes')),
            DropdownMenuItem(value: 1200, child: Text('Last 20 minutes')),
            DropdownMenuItem(value: 1800, child: Text('Last 30 minutes')),
          ],
          onChanged: (value) {
            if (value != null) {
              widget.controller.updateDraft(
                draft.copyWith(
                  lastSaved: DateTime.now(),
                  snipeGuardEnabled: true,
                  snipeGuardThresholdSeconds: value,
                  snipeGuardExtendSeconds: 300, // Fixed 5 min extension
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'If a bid is placed in the last ${(draft.snipeGuardThresholdSeconds ?? 1800) ~/ 60} minutes, the auction will automatically extend by 5 minutes.',
                  style: const TextStyle(fontSize: 11, color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Minimum Bid Increment
        const Text(
          'Minimum Bid Increment (₱) *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Minimum gap between bids (must be in multiples of ₱100)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        FormFieldWidget(
          controller: _bidIncrementController,
          label: 'Bid Increment',
          hint: 'e.g., 100, 500, 1000',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            final value = double.tryParse(v!);
            if (value == null) return 'Invalid amount';
            if (value < 100) return 'Minimum increment is ₱100';
            if (value % 100 != 0) return 'Must be a multiple of ₱100';
            return null;
          },
        ),
        const SizedBox(height: 8),
        _buildIncrementSuggestions(startingPrice),
        const SizedBox(height: 24),

        // Deposit Amount (auto-calculated)
        const Text(
          'Buyer Deposit Amount',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Auto-calculated based on starting price (~4%, ₱5k–₱50k)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Deposit', style: TextStyle(fontSize: 14)),
              Text(
                '₱${_calculateDeposit(startingPrice > 0 ? startingPrice : null).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Allow Installment Payments
        const Text(
          'Installment Payments',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Allow Installment Payments'),
            subtitle: Text(
              _allowsInstallment
                  ? 'Buyers can propose installment plans during the transaction'
                  : 'Only one-time full payment accepted',
              style: const TextStyle(fontSize: 12),
            ),
            secondary: Icon(
              _allowsInstallment ? Icons.calendar_month : Icons.payment,
              color: _allowsInstallment ? Colors.green : Colors.grey,
            ),
            value: _allowsInstallment,
            onChanged: (value) {
              setState(() {
                _allowsInstallment = value;
              });
              _updateDraft();
            },
          ),
        ),
        const SizedBox(height: 24),

        // Summary Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bidding Configuration Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildConfigSummary(),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStartDatePicker(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline, color: Colors.blue),
        title: const Text('Scheduled Start Date *'),
        subtitle: Text(
          _auctionStartDate != null
              ? _formatDateTime(_auctionStartDate!)
              : _demoMode
              ? 'Tap to select (demo: no restrictions)'
              : 'Tap to select (must be ≥24h from now)',
          style: TextStyle(
            fontSize: 12,
            color: _auctionStartDate != null ? Colors.blue : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.calendar_today, size: 20),
        onTap: () => _pickStartDate(context),
      ),
    );
  }

  Widget _buildEndTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auction End Time *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'How long should the auction run?',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Theme.of(context).colorScheme.onSurface;
            }),
          ),
          segments: const [
            ButtonSegment(
              value: 'duration',
              label: Text('Duration'),
              icon: Icon(Icons.timer),
            ),
            ButtonSegment(
              value: 'date',
              label: Text('End Date'),
              icon: Icon(Icons.calendar_today),
            ),
          ],
          selected: {_endTimeMode},
          onSelectionChanged: (v) {
            setState(() {
              _endTimeMode = v.first;
              // Clear the other mode's data
              if (_endTimeMode == 'duration') {
                _auctionEndDate = null;
              } else {
                _auctionDurationHours = null;
              }
              _scheduleError = null;
            });
            _updateDraft();
          },
        ),
        const SizedBox(height: 12),
        if (_endTimeMode == 'duration') _buildDurationPicker(),
        if (_endTimeMode == 'date') _buildEndDatePicker(context),
      ],
    );
  }

  Widget _buildDurationPicker() {
    final durations = [
      (24, '1 Day'),
      (48, '2 Days'),
      (72, '3 Days'),
      (120, '5 Days'),
      (168, '7 Days'),
      (336, '14 Days'),
      (-1, 'Custom'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: durations.map((d) {
            final isSelected = d.$1 == -1
                ? _auctionDurationHours != null &&
                      ![
                        24,
                        48,
                        72,
                        120,
                        168,
                        336,
                      ].contains(_auctionDurationHours)
                : _auctionDurationHours == d.$1;
            return ChoiceChip(
              label: Text(d.$2),
              selected: isSelected,
              onSelected: (selected) async {
                if (d.$1 == -1 && selected) {
                  // Custom duration dialog
                  final hours = await _showCustomDurationDialog(context);
                  if (hours == null) return;
                  setState(() {
                    _auctionDurationHours = hours;
                    _auctionEndDate = null;
                    _scheduleError = null;
                  });
                } else {
                  setState(() {
                    _auctionDurationHours = selected ? d.$1 : null;
                    _auctionEndDate = null;
                    _scheduleError = null;
                  });
                }
                _validateSchedule();
                _updateDraft();
              },
            );
          }).toList(),
        ),
        if (_auctionDurationHours != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auction will run for ${_auctionDurationHours! ~/ 24} day(s) (${_auctionDurationHours}h) from when it goes live.',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<int?> _showCustomDurationDialog(BuildContext context) async {
    final daysController = TextEditingController();
    final hoursController = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Days',
                hintText: 'e.g., 4',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Hours (optional)',
                hintText: 'e.g., 6',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(daysController.text) ?? 0;
              final hours = int.tryParse(hoursController.text) ?? 0;
              final total = days * 24 + hours;
              if (total < 1) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx, total);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDatePicker(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.deepPurple),
        title: const Text('End Date & Time'),
        subtitle: Text(
          _auctionEndDate != null
              ? _formatDateTime(_auctionEndDate!)
              : _demoMode
              ? 'Tap to select (demo: no restrictions)'
              : 'Tap to select (must be ≥24h after start)',
          style: TextStyle(
            fontSize: 12,
            color: _auctionEndDate != null ? Colors.deepPurple : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.calendar_month, size: 20),
        onTap: () => _pickEndDate(context),
      ),
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final minStart = _demoMode ? now : now.add(const Duration(hours: 24));

    final picked = await showDatePicker(
      context: context,
      initialDate: _auctionStartDate ?? minStart,
      firstDate: _demoMode ? now : minStart,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_auctionStartDate ?? minStart),
    );
    if (time == null) return;

    final startDate = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );

    if (!_demoMode && startDate.isBefore(minStart)) {
      setState(
        () => _scheduleError =
            'Start date must be at least 24 hours from now (approval window).',
      );
      return;
    }

    setState(() {
      _auctionStartDate = startDate;
      _scheduleError = null;
    });
    _validateSchedule();
    _updateDraft();
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final minEnd = _demoMode ? now : now.add(const Duration(hours: 25));

    final picked = await showDatePicker(
      context: context,
      initialDate: _auctionEndDate ?? minEnd,
      firstDate: _demoMode ? now : minEnd,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_auctionEndDate ?? minEnd),
    );
    if (time == null) return;

    final endDate = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _auctionEndDate = endDate;
      _auctionDurationHours = null;
      _scheduleError = null;
    });
    _validateSchedule();
    _updateDraft();
  }

  void _validateSchedule() {
    if (_demoMode) {
      setState(() => _scheduleError = null);
      return;
    }

    final now = DateTime.now();
    String? error;

    if (_scheduleLiveMode == 'auto_schedule' && _auctionStartDate != null) {
      if (_auctionStartDate!.isBefore(now.add(const Duration(hours: 24)))) {
        error =
            'Start date must be at least 24 hours from now (approval window).';
      }
    }

    if (error == null && _auctionEndDate != null) {
      if (_auctionEndDate!.isBefore(now.add(const Duration(hours: 24)))) {
        error = 'End date must be at least 24 hours from now.';
      }
      if (error == null &&
          _scheduleLiveMode == 'auto_schedule' &&
          _auctionStartDate != null) {
        if (_auctionEndDate!.isBefore(
          _auctionStartDate!.add(const Duration(hours: 24)),
        )) {
          error = 'End date must be at least 24 hours after the start date.';
        }
      }
    }

    setState(() => _scheduleError = error);
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day}/${dt.year} at $hour:$minute $suffix';
  }

  Widget _buildIncrementSuggestions(double startingPrice) {
    final suggestions = <(String, String)>[
      ('₱100', 'Fine'),
      ('₱500', 'Standard'),
      ('₱1,000', 'Regular'),
      ('₱2,000', 'Accelerated'),
      ('₱5,000', 'High value'),
    ];

    return Wrap(
      spacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion.$1),
          onPressed: () {
            setState(() {
              _bidIncrementController.text = suggestion.$1.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
            });
            _updateDraft();
          },
        );
      }).toList(),
    );
  }

  void _showDeedFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSummary() {
    return Column(
      children: [
        _summaryRow(
          'Bidding Type',
          _biddingType == 'public' ? '🌐 Public' : '🔒 Private',
        ),
        const Divider(),
        _summaryRow(
          'Minimum Increment',
          '₱${_bidIncrementController.text.isNotEmpty ? _bidIncrementController.text : '0'}',
        ),
        const Divider(),
        _summaryRow(
          'Anti-Sniping',
          '⏱️ ${(widget.controller.currentDraft?.snipeGuardThresholdSeconds ?? 1800) ~/ 60}m Window',
        ),
        const Divider(),
        _summaryRow(
          'Buyer Deposit',
          '₱${_calculateDeposit(double.tryParse(_startingPriceController.text)).toStringAsFixed(0)}',
        ),
        const Divider(),
        _summaryRow(
          'Installment',
          _allowsInstallment ? '✅ Allowed' : '❌ Not Allowed',
        ),
        const Divider(),
        _summaryRow(
          'Launch Mode',
          _scheduleLiveMode == 'auto_live'
              ? '🚀 Auto-Live'
              : _scheduleLiveMode == 'auto_schedule'
              ? '📅 Scheduled'
              : '✋ Manual',
        ),
        const Divider(),
        _summaryRow(
          'End Time',
          _auctionEndDate != null
              ? _formatDateTime(_auctionEndDate!)
              : _auctionDurationHours != null
              ? '${_auctionDurationHours! ~/ 24} day(s)'
              : 'Not set',
        ),
        if (_scheduleLiveMode == 'auto_schedule' &&
            _auctionStartDate != null) ...[
          const Divider(),
          _summaryRow('Start Date', _formatDateTime(_auctionStartDate!)),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
