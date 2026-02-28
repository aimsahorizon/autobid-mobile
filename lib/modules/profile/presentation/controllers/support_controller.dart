import 'package:flutter/foundation.dart';
import '../../domain/entities/support_ticket_entity.dart';
import '../../domain/usecases/get_support_categories_usecase.dart';
import '../../domain/usecases/get_user_tickets_usecase.dart';
import '../../domain/usecases/get_ticket_by_id_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/add_ticket_message_usecase.dart';
import '../../domain/usecases/update_ticket_status_usecase.dart';

class SupportController extends ChangeNotifier {
  final GetSupportCategoriesUsecase getSupportCategoriesUsecase;
  final GetUserTicketsUsecase getUserTicketsUsecase;
  final GetTicketByIdUsecase getTicketByIdUsecase;
  final CreateSupportTicketUsecase createSupportTicketUsecase;
  final AddTicketMessageUsecase addTicketMessageUsecase;
  final UpdateTicketStatusUsecase updateTicketStatusUsecase;

  SupportController({
    required this.getSupportCategoriesUsecase,
    required this.getUserTicketsUsecase,
    required this.getTicketByIdUsecase,
    required this.createSupportTicketUsecase,
    required this.addTicketMessageUsecase,
    required this.updateTicketStatusUsecase,
  });

  // State
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  bool _isTicketsLoading = false;
  bool _isTicketDetailLoading = false;
  bool _isCreatingTicket = false;
  bool _isSendingMessage = false;

  String? _error;
  String? _categoriesError;
  String? _ticketsError;
  String? _ticketDetailError;
  String? _createTicketError;
  String? _sendMessageError;

  List<SupportCategoryEntity> _categories = [];
  List<SupportTicketEntity> _tickets = [];
  SupportTicketEntity? _selectedTicket;

  // Filters
  TicketStatus? _statusFilter;
  final int _pageSize = 20;
  int _currentPage = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  bool get isTicketsLoading => _isTicketsLoading;
  bool get isTicketDetailLoading => _isTicketDetailLoading;
  bool get isCreatingTicket => _isCreatingTicket;
  bool get isSendingMessage => _isSendingMessage;

  String? get error => _error;
  String? get categoriesError => _categoriesError;
  String? get ticketsError => _ticketsError;
  String? get ticketDetailError => _ticketDetailError;
  String? get createTicketError => _createTicketError;
  String? get sendMessageError => _sendMessageError;

  /// Combined error message for UI
  String? get errorMessage =>
      _error ??
      _createTicketError ??
      _sendMessageError ??
      _ticketsError ??
      _ticketDetailError ??
      _categoriesError;

  List<SupportCategoryEntity> get categories => _categories;
  List<SupportTicketEntity> get tickets => _tickets;
  List<SupportTicketEntity> get userTickets => _tickets;
  SupportTicketEntity? get selectedTicket => _selectedTicket;
  TicketStatus? get statusFilter => _statusFilter;

  /// Load all support categories
  Future<void> loadCategories() async {
    _isCategoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      _categories = await getSupportCategoriesUsecase();
      _categoriesError = null;
    } catch (e) {
      _categoriesError = e.toString();
      debugPrint('Error loading categories: $e');
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Load user tickets with optional filtering
  Future<void> loadUserTickets({
    TicketStatus? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 0;
      _tickets = [];
    }

    _isTicketsLoading = true;
    _ticketsError = null;
    _statusFilter = status;
    notifyListeners();

    try {
      final loadedTickets = await getUserTicketsUsecase(
        status: status,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (refresh) {
        _tickets = loadedTickets;
      } else {
        _tickets.addAll(loadedTickets);
      }

      _ticketsError = null;
      _currentPage++;
    } catch (e) {
      _ticketsError = e.toString();
      debugPrint('Error loading tickets: $e');
    } finally {
      _isTicketsLoading = false;
      notifyListeners();
    }
  }

  /// Load a specific ticket with all messages
  Future<void> loadTicketById(String ticketId) async {
    _isTicketDetailLoading = true;
    _ticketDetailError = null;
    notifyListeners();

    try {
      _selectedTicket = await getTicketByIdUsecase(ticketId);
      _ticketDetailError = null;
    } catch (e) {
      _ticketDetailError = e.toString();
      debugPrint('Error loading ticket detail: $e');
    } finally {
      _isTicketDetailLoading = false;
      notifyListeners();
    }
  }

  /// Create a new support ticket
  Future<SupportTicketEntity?> createTicket({
    required String categoryId,
    required String subject,
    required String description,
    required TicketPriority priority,
  }) async {
    _isCreatingTicket = true;
    _createTicketError = null;
    notifyListeners();

    try {
      final ticket = await createSupportTicketUsecase(
        categoryId: categoryId,
        subject: subject,
        description: description,
        priority: priority,
      );

      // Add to local list
      _tickets.insert(0, ticket);
      _createTicketError = null;
      notifyListeners();

      return ticket;
    } catch (e) {
      _createTicketError = e.toString();
      debugPrint('Error creating ticket: $e');
      notifyListeners();
      return null;
    } finally {
      _isCreatingTicket = false;
      notifyListeners();
    }
  }

  /// Add a message to a ticket
  Future<bool> addMessage({
    required String ticketId,
    required String message,
    List<String>? attachmentPaths,
  }) async {
    _isSendingMessage = true;
    _sendMessageError = null;
    notifyListeners();

    try {
      final newMessage = await addTicketMessageUsecase(
        ticketId: ticketId,
        message: message,
        attachmentPaths: attachmentPaths,
      );

      // Update selected ticket if it's the current one
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = _selectedTicket!.copyWith(
          messages: [..._selectedTicket!.messages, newMessage],
        );
      }

      // Update in tickets list
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = _tickets[index].copyWith(
          messages: [..._tickets[index].messages, newMessage],
        );
      }

      _sendMessageError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _sendMessageError = e.toString();
      debugPrint('Error sending message: $e');
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Update ticket status
  Future<bool> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTicket = await updateTicketStatusUsecase(
        ticketId: ticketId,
        status: status,
      );

      // Update selected ticket
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = updatedTicket;
      }

      // Update in tickets list
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating ticket status: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Close a ticket
  Future<bool> closeTicket(String ticketId) async {
    return updateTicketStatus(
      ticketId: ticketId,
      status: TicketStatus.closed,
    );
  }

  /// Reopen a ticket
  Future<bool> reopenTicket(String ticketId) async {
    return updateTicketStatus(
      ticketId: ticketId,
      status: TicketStatus.open,
    );
  }

  /// Refresh tickets list
  Future<void> refresh() async {
    await loadUserTickets(status: _statusFilter, refresh: true);
  }

  /// Clear selected ticket
  void clearSelectedTicket() {
    _selectedTicket = null;
    notifyListeners();
  }

  /// Clear errors
  void clearError() {
    _error = null;
    _categoriesError = null;
    _ticketsError = null;
    _ticketDetailError = null;
    _createTicketError = null;
    _sendMessageError = null;
    notifyListeners();
  }
}
