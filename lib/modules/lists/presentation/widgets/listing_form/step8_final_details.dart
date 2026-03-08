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
  late TextEditingController _depositAmountController;

  List<String> _features = [];
  String _biddingType = 'public'; // 'public' or 'private'
  bool _enableIncrementalBidding = true;
  bool _autoLiveAfterApproval = false;
  bool _allowsInstallment = false;

  // Auction End Time
  DateTime? _auctionEndDate;
  String _endTimeMode = 'duration'; // 'duration' or 'custom'

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
    _depositAmountController = TextEditingController(
      text: _formatDouble(draft?.depositAmount ?? 50000),
    );
    _features = draft?.features ?? [];
    _auctionEndDate = draft?.auctionEndDate;
    _biddingType = draft?.biddingType ?? 'public';
    _enableIncrementalBidding = draft?.enableIncrementalBidding ?? true;
    _autoLiveAfterApproval = draft?.autoLiveAfterApproval ?? false;
    _allowsInstallment = draft?.allowsInstallment ?? false;

    _descriptionController.addListener(_updateDraft);
    _issuesController.addListener(_updateDraft);
    _startingPriceController.addListener(_updateDraft);
    _reservePriceController.addListener(_updateDraft);
    _bidIncrementController.addListener(_updateDraft);
    _depositAmountController.addListener(_updateDraft);
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
    _depositAmountController.dispose();
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
        depositAmount: () {
          if (_depositAmountController.text.isEmpty) return null;
          final parsed = double.tryParse(_depositAmountController.text);
          return (parsed != null && parsed > 0) ? parsed : null;
        }(),
        enableIncrementalBidding: _enableIncrementalBidding,
        autoLiveAfterApproval: _autoLiveAfterApproval,
        allowsInstallment: _allowsInstallment,
      ),
    );
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
                  'Applied suggested price: Γé▒${price.toStringAsFixed(0)}',
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

        // ===== AUCTION END TIME SECTION =====
        const SizedBox(height: 16),
        const Text(
          'Auction End Time',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Set when the auction will end. If left empty, defaults to 7 days after going live.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'duration', label: Text('By Duration')),
                  ButtonSegment(value: 'custom', label: Text('Pick Date')),
                ],
                selected: {_endTimeMode},
                onSelectionChanged: (v) =>
                    setState(() => _endTimeMode = v.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_endTimeMode == 'duration') _buildDurationPicker(),
        if (_endTimeMode == 'custom') _buildDateTimePicker(),
        if (_auctionEndDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ends: ${_formatEndDate(_auctionEndDate!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() => _auctionEndDate = null);
                    _updateDraft();
                  },
                ),
              ],
            ),
          ),
        ],
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
          child: SwitchListTile(
            title: const Text('Auto-Live After Approval'),
            subtitle: Text(
              _autoLiveAfterApproval
                  ? 'Auction will be set to go live after approval using system schedule defaults'
                  : 'After approval, seller will manually choose Go Live or Schedule',
              style: const TextStyle(fontSize: 12),
            ),
            secondary: Icon(
              _autoLiveAfterApproval ? Icons.flash_on : Icons.schedule,
              color: _autoLiveAfterApproval ? Colors.orange : Colors.grey,
            ),
            value: _autoLiveAfterApproval,
            onChanged: (value) {
              setState(() {
                _autoLiveAfterApproval = value;
              });
              _updateDraft();
            },
          ),
        ),
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

        // Enable Incremental Bidding
        const Text(
          'Incremental Bidding',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _enableIncrementalBidding,
                      onChanged: (value) {
                        setState(() {
                          _enableIncrementalBidding = value ?? true;
                        });
                        _updateDraft();
                      },
                    ),
                    Expanded(
                      child: Text(
                        _enableIncrementalBidding
                            ? 'Enable dynamic increments based on price'
                            : 'Use fixed increment for all bids',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _enableIncrementalBidding
                        ? 'Example: ₱0-500k: ₱1k, ₱500k-1M: ₱5k, ₱1M+: ₱10k increments'
                        : 'All bids will require a ${_bidIncrementController.text.isNotEmpty ? '₱${_bidIncrementController.text}' : 'fixed'} increment',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Deposit Amount
        const Text(
          'Buyer Deposit Amount (₱) *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Min: ₱5,000 | Max: ₱50,000 | Increments of ₱5,000',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        FormFieldWidget(
          controller: _depositAmountController,
          label: 'Deposit Amount',
          hint: 'e.g., 5000, 25000, 50000',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            final value = double.tryParse(v!);
            if (value == null) return 'Invalid amount';
            if (value < 5000) return 'Minimum deposit is ₱5,000';
            if (value > 50000) return 'Maximum deposit is ₱50,000';
            if (value % 5000 != 0) return 'Must be in increments of ₱5,000';
            return null;
          },
        ),
        const SizedBox(height: 8),
        _buildDepositSuggestions(startingPrice),
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

  Widget _buildDurationPicker() {
    final durations = <(String, Duration)>[
      ('1 min', Duration(minutes: 1)),
      ('30 min', Duration(minutes: 30)),
      ('1 hour', Duration(hours: 1)),
      ('6 hours', Duration(hours: 6)),
      ('12 hours', Duration(hours: 12)),
      ('1 day', Duration(days: 1)),
      ('3 days', Duration(days: 3)),
      ('7 days', Duration(days: 7)),
      ('14 days', Duration(days: 14)),
      ('30 days', Duration(days: 30)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((d) {
        final endDate = DateTime.now().add(d.$2);
        final isSelected =
            _auctionEndDate != null &&
            (_auctionEndDate!.difference(endDate).inMinutes).abs() < 2;
        return ChoiceChip(
          label: Text(d.$1),
          selected: isSelected,
          onSelected: (_) {
            setState(() => _auctionEndDate = DateTime.now().add(d.$2));
            _updateDraft();
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateTimePicker() {
    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: _auctionEndDate ?? now.add(const Duration(days: 1)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 90)),
        );
        if (date == null || !mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
            _auctionEndDate ?? now.add(const Duration(hours: 1)),
          ),
        );
        if (time == null || !mounted) return;

        setState(() {
          _auctionEndDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _updateDraft();
      },
      icon: const Icon(Icons.calendar_month),
      label: Text(
        _auctionEndDate != null
            ? _formatEndDate(_auctionEndDate!)
            : 'Select Date & Time',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  String _formatEndDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$min $ampm';
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

  Widget _buildDepositSuggestions(double startingPrice) {
    final suggestions = <(String, String)>[
      ('₱5,000', 'Minimum deposit'),
      ('₱25,000', 'Standard deposit'),
      ('₱50,000', 'Maximum deposit'),
    ];

    return Wrap(
      spacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion.$1),
          onPressed: () {
            setState(() {
              _depositAmountController.text = suggestion.$1.replaceAll(
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
          'Bidding Mode',
          _enableIncrementalBidding
              ? '📊 Dynamic Increments'
              : '📝 Fixed Increment',
        ),
        const Divider(),
        _summaryRow(
          'Anti-Sniping',
          '⏱️ ${(widget.controller.currentDraft?.snipeGuardThresholdSeconds ?? 1800) ~/ 60}m Window',
        ),
        const Divider(),
        _summaryRow(
          'Buyer Deposit',
          '₱${_depositAmountController.text.isNotEmpty ? _depositAmountController.text : '0'}',
        ),
        const Divider(),
        _summaryRow(
          'Installment',
          _allowsInstallment ? '✅ Allowed' : '❌ Not Allowed',
        ),
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
