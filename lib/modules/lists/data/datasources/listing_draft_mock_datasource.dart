import '../../domain/entities/listing_draft_entity.dart';

/// Mock datasource for listing draft management
/// TODO: Replace with Supabase implementation
/// - Use supabase.from('listing_drafts') for CRUD operations
/// - Implement auto-save on field changes
/// - Store photos in Supabase Storage
/// - Handle draft expiration (e.g., 30 days)
class ListingDraftMockDataSource {
  static const bool useMockData = true;

  // Simulated delay for network requests
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 500));

  /// Get all drafts for a seller
  /// TODO: Implement Supabase query:
  /// await supabase.from('listing_drafts')
  ///   .select()
  ///   .eq('seller_id', sellerId)
  ///   .order('last_saved', ascending: false);
  Future<List<ListingDraftEntity>> getSellerDrafts(String sellerId) async {
    await _delay();
    return _mockDrafts.where((d) => d.sellerId == sellerId).toList();
  }

  /// Get single draft by ID
  /// TODO: Implement Supabase query:
  /// await supabase.from('listing_drafts')
  ///   .select()
  ///   .eq('id', draftId)
  ///   .single();
  Future<ListingDraftEntity?> getDraft(String draftId) async {
    await _delay();
    try {
      return _mockDrafts.firstWhere((d) => d.id == draftId);
    } catch (e) {
      return null;
    }
  }

  /// Save or update draft
  /// TODO: Implement Supabase upsert:
  /// await supabase.from('listing_drafts').upsert({
  ///   'id': draft.id,
  ///   'seller_id': draft.sellerId,
  ///   'current_step': draft.currentStep,
  ///   ...all draft fields
  /// });
  Future<bool> saveDraft(ListingDraftEntity draft) async {
    await _delay();
    final index = _mockDrafts.indexWhere((d) => d.id == draft.id);
    if (index >= 0) {
      _mockDrafts[index] = draft;
    } else {
      _mockDrafts.add(draft);
    }
    return true;
  }

  /// Delete draft
  /// TODO: Implement Supabase delete:
  /// await supabase.from('listing_drafts')
  ///   .delete()
  ///   .eq('id', draftId);
  Future<bool> deleteDraft(String draftId) async {
    await _delay();
    _mockDrafts.removeWhere((d) => d.id == draftId);
    return true;
  }

  /// Upload photo and get URL
  /// TODO: Implement Supabase Storage upload:
  /// final file = File(localPath);
  /// final path = 'listing_photos/${draftId}/${category}_${timestamp}.jpg';
  /// await supabase.storage.from('listings').upload(path, file);
  /// final url = supabase.storage.from('listings').getPublicUrl(path);
  Future<String?> uploadPhoto(
    String draftId,
    String category,
    String localPath,
  ) async {
    await _delay();
    // Mock: return placeholder URL
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'https://picsum.photos/seed/$draftId$timestamp/800/600';
  }

  /// Submit draft as pending listing
  /// TODO: Implement Supabase transaction:
  /// 1. Insert into 'listings' table with status 'pending'
  /// 2. Delete from 'listing_drafts'
  /// 3. Create timeline event
  /// 4. Send notification to admin
  Future<bool> submitListing(String draftId) async {
    await _delay();
    final draft = await getDraft(draftId);
    if (draft == null || !draft.isComplete) return false;

    // In real implementation, create listing record
    await deleteDraft(draftId);
    return true;
  }

  /// Create new empty draft
  ListingDraftEntity createNewDraft(String sellerId) {
    return ListingDraftEntity(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      currentStep: 1,
      lastSaved: DateTime.now(),
    );
  }

  // Mock data storage
  static final List<ListingDraftEntity> _mockDrafts = [
    ListingDraftEntity(
      id: 'draft_001',
      sellerId: 'seller_001',
      currentStep: 3,
      lastSaved: DateTime.now().subtract(const Duration(hours: 2)),
      brand: 'Toyota',
      model: 'Vios',
      variant: 'XLE',
      year: 2021,
      engineType: 'Inline-4',
      transmission: 'CVT',
      fuelType: 'Gasoline',
    ),
  ];
}
