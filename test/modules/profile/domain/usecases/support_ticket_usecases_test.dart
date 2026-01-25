import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/create_support_ticket_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_user_tickets_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_ticket_by_id_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/add_ticket_message_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/update_ticket_status_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/usecases/get_support_categories_usecase.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/support_repository.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/support_ticket_entity.dart';

class MockSupportRepository extends Mock implements SupportRepository {}

void main() {
  late CreateSupportTicketUsecase createTicketUseCase;
  late GetUserTicketsUsecase getUserTicketsUseCase;
  late GetTicketByIdUsecase getTicketByIdUseCase;
  late AddTicketMessageUsecase addTicketMessageUseCase;
  late UpdateTicketStatusUsecase updateTicketStatusUseCase;
  late GetSupportCategoriesUsecase getCategoriesUseCase;
  late MockSupportRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(TicketPriority.medium);
    registerFallbackValue(TicketStatus.open);
  });

  setUp(() {
    mockRepository = MockSupportRepository();
    createTicketUseCase = CreateSupportTicketUsecase(mockRepository);
    getUserTicketsUseCase = GetUserTicketsUsecase(mockRepository);
    getTicketByIdUseCase = GetTicketByIdUsecase(mockRepository);
    addTicketMessageUseCase = AddTicketMessageUsecase(mockRepository);
    updateTicketStatusUseCase = UpdateTicketStatusUsecase(mockRepository);
    getCategoriesUseCase = GetSupportCategoriesUsecase(mockRepository);
  });

  const testUserId = 'user-123';
  const testCategoryId = 'cat-technical';
  const testTicketId = 'ticket-123';

  final testTicket = SupportTicketEntity(
    id: testTicketId,
    userId: testUserId,
    categoryId: testCategoryId,
    categoryName: 'Technical Issue',
    subject: 'Cannot upload photos',
    description: 'Getting error when uploading vehicle photos',
    status: TicketStatus.open,
    priority: TicketPriority.high,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    messages: const [],
  );

  final testMessage = SupportMessageEntity(
    id: 'msg-1',
    ticketId: testTicketId,
    userId: testUserId,
    message: 'Thanks for the update',
    isInternal: false,
    senderName: 'John Doe',
    createdAt: DateTime(2024, 1, 2),
    updatedAt: DateTime(2024, 1, 2),
    attachments: const [],
  );

  final testCategories = [
    SupportCategoryEntity(
      id: 'cat-technical',
      name: 'Technical Issue',
      description: 'Problems with app functionality',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    SupportCategoryEntity(
      id: 'cat-account',
      name: 'Account Issue',
      description: 'Problems with your account',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  group('CreateSupportTicketUsecase', () {
    test('should create support ticket successfully', () async {
      // Arrange
      when(
        () => mockRepository.createTicket(
          categoryId: testCategoryId,
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priority: TicketPriority.high,
        ),
      ).thenAnswer((_) async => testTicket);

      // Act
      final result = await createTicketUseCase(
        categoryId: testCategoryId,
        subject: 'Cannot upload photos',
        description: 'Getting error when uploading vehicle photos',
        priority: TicketPriority.high,
      );

      // Assert
      expect(result.id, testTicketId);
      expect(result.subject, 'Cannot upload photos');
      expect(result.status, TicketStatus.open);
      expect(result.priority, TicketPriority.high);

      verify(
        () => mockRepository.createTicket(
          categoryId: testCategoryId,
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priority: TicketPriority.high,
        ),
      ).called(1);
    });

    test('should create ticket with low priority', () async {
      // Arrange
      final lowPriorityTicket = testTicket.copyWith(
        priority: TicketPriority.low,
      );
      when(
        () => mockRepository.createTicket(
          categoryId: any(named: 'categoryId'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priority: TicketPriority.low,
        ),
      ).thenAnswer((_) async => lowPriorityTicket);

      // Act
      final result = await createTicketUseCase(
        categoryId: testCategoryId,
        subject: 'Feature request',
        description: 'Would be nice to have dark mode',
        priority: TicketPriority.low,
      );

      // Assert
      expect(result.priority, TicketPriority.low);
    });

    test('should throw exception when creation fails', () async {
      // Arrange
      when(
        () => mockRepository.createTicket(
          categoryId: any(named: 'categoryId'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priority: any(named: 'priority'),
        ),
      ).thenThrow(Exception('Failed to create ticket'));

      // Act & Assert
      expect(
        () => createTicketUseCase(
          categoryId: testCategoryId,
          subject: 'Test',
          description: 'Test description',
          priority: TicketPriority.medium,
        ),
        throwsException,
      );
    });
  });

  group('GetUserTicketsUsecase', () {
    test('should get all user tickets', () async {
      // Arrange
      final tickets = [testTicket, testTicket.copyWith(id: 'ticket-456')];
      when(
        () => mockRepository.getUserTickets(
          status: null,
          limit: null,
          offset: null,
        ),
      ).thenAnswer((_) async => tickets);

      // Act
      final result = await getUserTicketsUseCase();

      // Assert
      expect(result.length, 2);
      expect(result.first.id, testTicketId);

      verify(
        () => mockRepository.getUserTickets(
          status: null,
          limit: null,
          offset: null,
        ),
      ).called(1);
    });

    test('should filter tickets by status', () async {
      // Arrange
      when(
        () => mockRepository.getUserTickets(
          status: TicketStatus.open,
          limit: null,
          offset: null,
        ),
      ).thenAnswer((_) async => [testTicket]);

      // Act
      final result = await getUserTicketsUseCase(status: TicketStatus.open);

      // Assert
      expect(result.length, 1);
      expect(result.first.status, TicketStatus.open);

      verify(
        () => mockRepository.getUserTickets(
          status: TicketStatus.open,
          limit: null,
          offset: null,
        ),
      ).called(1);
    });

    test('should handle pagination parameters', () async {
      // Arrange
      when(
        () =>
            mockRepository.getUserTickets(status: null, limit: 10, offset: 20),
      ).thenAnswer((_) async => [testTicket]);

      // Act
      final result = await getUserTicketsUseCase(limit: 10, offset: 20);

      // Assert
      expect(result.isNotEmpty, true);

      verify(
        () =>
            mockRepository.getUserTickets(status: null, limit: 10, offset: 20),
      ).called(1);
    });

    test('should return empty list when no tickets', () async {
      // Arrange
      when(
        () => mockRepository.getUserTickets(
          status: any(named: 'status'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await getUserTicketsUseCase();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('GetTicketByIdUsecase', () {
    test('should get ticket by id successfully', () async {
      // Arrange
      when(
        () => mockRepository.getTicketById(testTicketId),
      ).thenAnswer((_) async => testTicket);

      // Act
      final result = await getTicketByIdUseCase(testTicketId);

      // Assert
      expect(result.id, testTicketId);
      expect(result.subject, 'Cannot upload photos');

      verify(() => mockRepository.getTicketById(testTicketId)).called(1);
    });

    test('should throw exception when ticket not found', () async {
      // Arrange
      when(
        () => mockRepository.getTicketById(any()),
      ).thenThrow(Exception('Ticket not found'));

      // Act & Assert
      expect(() => getTicketByIdUseCase('non-existent'), throwsException);
    });

    test('should get ticket with messages', () async {
      // Arrange
      final ticketWithMessages = testTicket.copyWith(messages: [testMessage]);
      when(
        () => mockRepository.getTicketById(testTicketId),
      ).thenAnswer((_) async => ticketWithMessages);

      // Act
      final result = await getTicketByIdUseCase(testTicketId);

      // Assert
      expect(result.messages.length, 1);
      expect(result.messages.first.message, 'Thanks for the update');
    });
  });

  group('AddTicketMessageUsecase', () {
    test('should add message to ticket successfully', () async {
      // Arrange
      when(
        () => mockRepository.addMessage(
          ticketId: testTicketId,
          message: 'Thanks for the update',
          attachmentPaths: null,
        ),
      ).thenAnswer((_) async => testMessage);

      // Act
      final result = await addTicketMessageUseCase(
        ticketId: testTicketId,
        message: 'Thanks for the update',
      );

      // Assert
      expect(result.message, 'Thanks for the update');
      expect(result.ticketId, testTicketId);

      verify(
        () => mockRepository.addMessage(
          ticketId: testTicketId,
          message: 'Thanks for the update',
          attachmentPaths: null,
        ),
      ).called(1);
    });

    test('should add message with attachments', () async {
      // Arrange
      const attachments = ['path/to/file1.jpg', 'path/to/file2.pdf'];
      final messageWithAttachments = SupportMessageEntity(
        id: testMessage.id,
        ticketId: testMessage.ticketId,
        userId: testMessage.userId,
        message: 'Here are the screenshots',
        isInternal: testMessage.isInternal,
        senderName: testMessage.senderName,
        createdAt: testMessage.createdAt,
        updatedAt: testMessage.updatedAt,
        attachments: [], // Simplified for test
      );

      when(
        () => mockRepository.addMessage(
          ticketId: testTicketId,
          message: 'Here are the screenshots',
          attachmentPaths: attachments,
        ),
      ).thenAnswer((_) async => messageWithAttachments);

      // Act
      final result = await addTicketMessageUseCase(
        ticketId: testTicketId,
        message: 'Here are the screenshots',
        attachmentPaths: attachments,
      );

      // Assert
      expect(result.message, 'Here are the screenshots');
    });

    test('should throw exception when message is empty', () async {
      // Arrange
      when(
        () => mockRepository.addMessage(
          ticketId: any(named: 'ticketId'),
          message: any(named: 'message'),
          attachmentPaths: any(named: 'attachmentPaths'),
        ),
      ).thenThrow(Exception('Message cannot be empty'));

      // Act & Assert
      expect(
        () => addTicketMessageUseCase(ticketId: testTicketId, message: ''),
        throwsException,
      );
    });
  });

  group('UpdateTicketStatusUsecase', () {
    test('should update ticket status successfully', () async {
      // Arrange
      final resolvedTicket = testTicket.copyWith(
        status: TicketStatus.resolved,
        resolvedAt: DateTime(2024, 1, 5),
      );

      when(
        () => mockRepository.updateTicketStatus(
          ticketId: testTicketId,
          status: TicketStatus.resolved,
        ),
      ).thenAnswer((_) async => resolvedTicket);

      // Act
      final result = await updateTicketStatusUseCase(
        ticketId: testTicketId,
        status: TicketStatus.resolved,
      );

      // Assert
      expect(result.status, TicketStatus.resolved);
      expect(result.resolvedAt, isNotNull);

      verify(
        () => mockRepository.updateTicketStatus(
          ticketId: testTicketId,
          status: TicketStatus.resolved,
        ),
      ).called(1);
    });

    test('should update ticket to in progress', () async {
      // Arrange
      final inProgressTicket = testTicket.copyWith(
        status: TicketStatus.inProgress,
      );
      when(
        () => mockRepository.updateTicketStatus(
          ticketId: testTicketId,
          status: TicketStatus.inProgress,
        ),
      ).thenAnswer((_) async => inProgressTicket);

      // Act
      final result = await updateTicketStatusUseCase(
        ticketId: testTicketId,
        status: TicketStatus.inProgress,
      );

      // Assert
      expect(result.status, TicketStatus.inProgress);
      expect(result.isOpen, true);
    });

    test('should close ticket', () async {
      // Arrange
      final closedTicket = testTicket.copyWith(
        status: TicketStatus.closed,
        closedAt: DateTime(2024, 1, 10),
      );

      when(
        () => mockRepository.updateTicketStatus(
          ticketId: testTicketId,
          status: TicketStatus.closed,
        ),
      ).thenAnswer((_) async => closedTicket);

      // Act
      final result = await updateTicketStatusUseCase(
        ticketId: testTicketId,
        status: TicketStatus.closed,
      );

      // Assert
      expect(result.status, TicketStatus.closed);
      expect(result.closedAt, isNotNull);
      expect(result.isOpen, false);
    });
  });

  group('GetSupportCategoriesUsecase', () {
    test('should get all support categories', () async {
      // Arrange
      when(
        () => mockRepository.getCategories(),
      ).thenAnswer((_) async => testCategories);

      // Act
      final result = await getCategoriesUseCase();

      // Assert
      expect(result.length, 2);
      expect(result.first.name, 'Technical Issue');
      expect(result.last.name, 'Account Issue');

      verify(() => mockRepository.getCategories()).called(1);
    });

    test('should return empty list when no categories', () async {
      // Arrange
      when(() => mockRepository.getCategories()).thenAnswer((_) async => []);

      // Act
      final result = await getCategoriesUseCase();

      // Assert
      expect(result, isEmpty);
    });

    test('should throw exception when fetching fails', () async {
      // Arrange
      when(
        () => mockRepository.getCategories(),
      ).thenThrow(Exception('Failed to fetch categories'));

      // Act & Assert
      expect(() => getCategoriesUseCase(), throwsException);
    });
  });
}
