import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ...existing code...
import '../../controllers/listing_draft_controller.dart';
import 'form_field_widget.dart';
import 'ai_price_predictor.dart';
import '../../../data/datasources/demo_listing_data.dart';
import 'demo_autofill_button.dart';

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
  DateTime? _auctionEndDate;
  String _biddingType = 'public'; // 'public' or 'private'
  bool _enableIncrementalBidding = true;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft;

    // Initialize with defaults if draft is null
    _descriptionController = TextEditingController(text: draft?.description);
    _issuesController = TextEditingController(text: draft?.knownIssues);
    _featureController = TextEditingController();
    _startingPriceController = TextEditingController(
      text: draft?.startingPrice?.toString(),
    );
    _reservePriceController = TextEditingController(
      text: draft?.reservePrice?.toString(),
    );
    _bidIncrementController = TextEditingController(
      text: (draft?.bidIncrement ?? draft?.minBidIncrement ?? 1000).toString(),
    );
    _depositAmountController = TextEditingController(
      text: (draft?.depositAmount ?? 50000).toString(),
    );
    _features = draft?.features ?? [];
    _auctionEndDate = draft?.auctionEndDate;
    _biddingType = draft?.biddingType ?? 'public';
    _enableIncrementalBidding = draft?.enableIncrementalBidding ?? true;

    _descriptionController.addListener(_updateDraft);
    _issuesController.addListener(_updateDraft);
    _startingPriceController.addListener(_updateDraft);
    _reservePriceController.addListener(_updateDraft);
    _bidIncrementController.addListener(_updateDraft);
    _depositAmountController.addListener(_updateDraft);
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

  void _autofillDemoData() {
    final demoData = DemoListingData.getDemoDataForStep(8);
    setState(() {
      _descriptionController.text = demoData['description'];
      _issuesController.text = demoData['knownIssues'] ?? '';
      _features = List<String>.from(demoData['features'] ?? []);
      _startingPriceController.text = demoData['startingPrice'].toString();
      _reservePriceController.text = demoData['reservePrice']?.toString() ?? '';
      _auctionEndDate = demoData['auctionEndDate'];
      _bidIncrementController.text = '5000';
      _depositAmountController.text = '50000';
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
        const SizedBox(height: 16),
        DemoAutofillButton(onPressed: _autofillDemoData),
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
          'Pricing & Auction Duration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        AiPricePredictor(
          brand: draft.brand,
          model: draft.model,
          year: draft.year,
          mileage: draft.mileage,
          condition: draft.condition,
          onAccept: (startingPrice) {
            final reservePrice = startingPrice * 1.1;
            setState(() {
              _startingPriceController.text = startingPrice.toStringAsFixed(0);
              _reservePriceController.text = reservePrice.toStringAsFixed(0);
            });
            _updateDraft();
          },
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _startingPriceController,
          label: 'Starting Price (₱) *',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _reservePriceController,
          label: 'Reserve Price (₱)',
          hint: 'Optional minimum acceptable price',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  _auctionEndDate ??
                  DateTime.now().add(const Duration(hours: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) {
              // Allow time selection
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              // Create datetime in local timezone
              final localDateTime = DateTime(
                picked.year,
                picked.month,
                picked.day,
                pickedTime?.hour ?? 23,
                pickedTime?.minute ?? 59,
                59,
              );
              // Convert to UTC immediately to maintain the actual intended time
              // This prevents timezone issues when storing and retrieving
              setState(() => _auctionEndDate = localDateTime.toUtc());
              _updateDraft();
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Auction End Date *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _auctionEndDate != null
                      ? '${_auctionEndDate!.month}/${_auctionEndDate!.day}/${_auctionEndDate!.year}'
                      : 'Select date',
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
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
            color: Colors.blue.withAlpha((0.1 * 255).toInt()),
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

        // Minimum Bid Increment
        const Text(
          'Minimum Bid Increment (₱) *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Minimum gap between bids (must be in multiples of ₱1,000)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        FormFieldWidget(
          controller: _bidIncrementController,
          label: 'Bid Increment',
          hint: 'e.g., 1000, 2000, 5000',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            final value = double.tryParse(v!);
            if (value == null) return 'Invalid amount';
            if (value < 1000) return 'Minimum increment is ₱1,000';
            if (value % 1000 != 0) return 'Must be a multiple of ₱1,000';
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
                    color: Colors.amber.withAlpha((0.1 * 255).toInt()),
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

        // Summary Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withAlpha((0.3 * 255).toInt()),
            ),
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

  Widget _buildIncrementSuggestions(double startingPrice) {
    final suggestions = <(String, String)>[
      ('₱1,000', 'Standard'),
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
          'Buyer Deposit',
          '₱${_depositAmountController.text.isNotEmpty ? _depositAmountController.text : '0'}',
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
