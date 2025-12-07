# Support Ticket Backend Implementation Summary

## Overview
Implemented a complete support ticket system with Supabase backend integration following the modular clean architecture pattern.

## Files Created/Modified

### 1. SQL Schema
**File**: [sql/support_tickets.sql](sql/support_tickets.sql)
- Created comprehensive database schema with:
  - `support_categories` - Support ticket categories
  - `support_tickets` - Main support tickets table
  - `support_ticket_messages` - Conversation messages
  - `support_ticket_attachments` - File attachments
- Implemented Row Level Security (RLS) policies
- Added indexes for performance optimization
- Created helper functions:
  - `auto_close_resolved_tickets()` - Auto-close tickets after 7 days
  - `get_user_ticket_stats()` - Get ticket statistics for users

### 2. Domain Layer

#### Entities
**File**: [lib/modules/profile/domain/entities/support_ticket_entity.dart](lib/modules/profile/domain/entities/support_ticket_entity.dart)
- Updated `SupportTicketEntity` with backend fields
- Updated `SupportMessageEntity` with backend fields
- Added `SupportAttachmentEntity` for file attachments
- Added `SupportCategoryEntity` for categories
- Updated `TicketStatus` enum (open, inProgress, resolved, closed)
- Added JSON conversion methods for enums

#### Repository Interface
**File**: [lib/modules/profile/domain/repositories/support_repository.dart](lib/modules/profile/domain/repositories/support_repository.dart)
- Defined abstract repository with methods:
  - `getCategories()` - Get all support categories
  - `getUserTickets()` - Get user's tickets with filtering
  - `getTicketById()` - Get ticket details with messages
  - `createTicket()` - Create new support ticket
  - `addMessage()` - Add message to ticket
  - `updateTicketStatus()` - Update ticket status
  - `updateTicketPriority()` - Update ticket priority
  - `closeTicket()` - Close a ticket
  - `reopenTicket()` - Reopen closed ticket
  - `getUserTicketStats()` - Get user statistics
  - `uploadAttachment()` - Upload file attachment
  - `deleteAttachment()` - Delete attachment

#### Use Cases
Created use cases for each repository method:
- [get_support_categories_usecase.dart](lib/modules/profile/domain/usecases/get_support_categories_usecase.dart)
- [get_user_tickets_usecase.dart](lib/modules/profile/domain/usecases/get_user_tickets_usecase.dart)
- [get_ticket_by_id_usecase.dart](lib/modules/profile/domain/usecases/get_ticket_by_id_usecase.dart)
- [create_support_ticket_usecase.dart](lib/modules/profile/domain/usecases/create_support_ticket_usecase.dart)
- [add_ticket_message_usecase.dart](lib/modules/profile/domain/usecases/add_ticket_message_usecase.dart)
- [update_ticket_status_usecase.dart](lib/modules/profile/domain/usecases/update_ticket_status_usecase.dart)

### 3. Data Layer

#### Models
**File**: [lib/modules/profile/data/models/support_ticket_model.dart](lib/modules/profile/data/models/support_ticket_model.dart)
- `SupportCategoryModel` - Maps to/from JSON
- `SupportAttachmentModel` - Maps to/from JSON
- `SupportMessageModel` - Maps to/from JSON with attachments
- `SupportTicketModel` - Maps to/from JSON with messages

#### Datasource
**File**: [lib/modules/profile/data/datasources/support_supabase_datasource.dart](lib/modules/profile/data/datasources/support_supabase_datasource.dart)
- Implements all CRUD operations with Supabase
- Features:
  - Fetches categories with active filter
  - Gets user tickets with status filtering and pagination
  - Loads ticket details with messages and attachments
  - Creates tickets with proper user context
  - Adds messages with user profile info
  - Updates ticket status with timestamps
  - Uploads attachments to Supabase Storage
  - Deletes attachments from storage and database
  - Gets user statistics using RPC function
- Includes proper error handling and type conversion

#### Repository Implementation
**File**: [lib/modules/profile/data/repositories/support_repository_supabase_impl.dart](lib/modules/profile/data/repositories/support_repository_supabase_impl.dart)
- Implements `SupportRepository` interface
- Wraps datasource calls with error handling
- Converts datasource exceptions to repository exceptions

### 4. Presentation Layer

#### Controller
**File**: [lib/modules/profile/presentation/controllers/support_controller.dart](lib/modules/profile/presentation/controllers/support_controller.dart)
- State management with `ChangeNotifier`
- Features:
  - Load categories for ticket creation
  - Load user tickets with filtering and pagination
  - Load specific ticket with all messages
  - Create new tickets
  - Add messages to tickets
  - Update ticket status/priority
  - Close and reopen tickets
  - Refresh ticket list
- Comprehensive error handling for each operation
- Loading states for better UX

### 5. Dependency Injection

**File**: [lib/modules/profile/profile_module.dart](lib/modules/profile/profile_module.dart)
- Added support datasource factory method
- Added support repository factory method
- Added all use case factory methods
- Added `createSupportController()` method
- Follows existing module pattern

## Database Features

### Row Level Security (RLS)
- Users can only view and manage their own tickets
- Support staff and admins have full access
- Internal messages are hidden from regular users
- Proper authentication checks on all operations

### Performance Optimizations
- Indexes on frequently queried columns:
  - `user_id`, `status`, `category_id`, `created_at`
  - `ticket_id` for messages and attachments
- Efficient JOIN queries for related data
- Pagination support to limit data transfer

### Data Integrity
- Foreign key constraints ensure referential integrity
- CHECK constraints for valid status and priority values
- Automatic timestamps with triggers
- Cascade deletes for related records

## Default Categories
Pre-populated categories:
1. Account Issues
2. Bidding Problems
3. Payment Issues
4. Listing Problems
5. Technical Support
6. General Inquiry
7. Report User
8. Feature Request

## File Upload Support
- Attachments stored in Supabase Storage bucket: `support-files`
- MIME type detection for common file types
- File size tracking
- Proper cleanup when attachments are deleted

## Usage Example

```dart
// Initialize controller
final controller = ProfileModule.instance.createSupportController();

// Load categories
await controller.loadCategories();

// Create ticket
final ticket = await controller.createTicket(
  categoryId: categoryId,
  subject: 'Login Issue',
  description: 'Cannot log in with Google',
  priority: TicketPriority.high,
);

// Load tickets
await controller.loadTickets(status: TicketStatus.open);

// Add message
await controller.addMessage(
  ticketId: ticket.id,
  message: 'I tried resetting my password but it didn't help',
);

// Close ticket
await controller.closeTicket(ticket.id);
```

## Next Steps

1. **Run SQL Migration**: Execute the SQL file in your Supabase dashboard
2. **Create Storage Bucket**: Create a `support-files` bucket in Supabase Storage
3. **Update UI**: Integrate the controller with customer_support_page.dart
4. **Test Backend**: Test all operations with real Supabase instance
5. **Add Notifications**: Implement push notifications for ticket updates
6. **Admin Panel**: Create admin interface for support staff
7. **Analytics**: Add ticket analytics and reporting

## Architecture Benefits

✅ Clean separation of concerns
✅ Testable code with clear dependencies
✅ Type-safe models and entities
✅ Comprehensive error handling
✅ Scalable pagination support
✅ Secure with RLS policies
✅ Optimized database queries
✅ File upload capability
✅ Real-time ready (can add Supabase subscriptions)
