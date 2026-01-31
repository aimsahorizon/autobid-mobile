import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/support_ticket_entity.dart';
import '../controllers/support_controller.dart';

class CustomerSupportPage extends StatefulWidget {
  const CustomerSupportPage({super.key});

  @override
  State<CustomerSupportPage> createState() => _CustomerSupportPageState();
}

class _CustomerSupportPageState extends State<CustomerSupportPage> {
  late SupportController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<SupportController>();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    // Assuming the user is logged in, we'd normally get the userId from auth
    // For now, we'll let the controller handle fetching or pass a placeholder if needed
    // The controller likely needs a userId to fetch tickets. 
    // Checking SupportController implementation...
    await _controller.loadUserTickets(); 
    if (mounted) setState(() {});
  }

  void _createNewTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CreateTicketPage()),
    ).then((_) => _loadTickets());
  }

  void _openTicket(SupportTicketEntity ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _TicketDetailPage(ticket: ticket)),
    ).then((_) => _loadTickets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Support')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (_controller.userTickets.isEmpty) {
            return _EmptyState(onCreateTicket: _createNewTicket);
          }

          return _TicketsList(
            tickets: _controller.userTickets,
            onTicketTap: _openTicket,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTicket;

  const _EmptyState({required this.onCreateTicket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 80, color: ColorConstants.primary),
            const SizedBox(height: 24),
            Text(
              'No Support Tickets',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Need help? Create a ticket and our team will assist you.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTicket,
              icon: const Icon(Icons.add),
              label: const Text('Create Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketsList extends StatelessWidget {
  final List<SupportTicketEntity> tickets;
  final Function(SupportTicketEntity) onTicketTap;

  const _TicketsList({
    required this.tickets,
    required this.onTicketTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _TicketCard(
        ticket: tickets[index],
        onTap: () => onTicketTap(tickets[index]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketEntity ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ticket.isOpen
                ? ColorConstants.primary.withValues(alpha: 0.3)
                : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 14, color: ColorConstants.textSecondaryLight),
                const SizedBox(width: 4),
                Text(ticket.categoryName, style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: ColorConstants.textSecondaryLight),
                const SizedBox(width: 4),
                Text(_formatTime(ticket.updatedAt), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (ticket.messages.isNotEmpty)
            Text(
              ticket.messages.last.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? ColorConstants.textSecondaryDark : ColorConstants.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getColor()),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case TicketStatus.open:
        return ColorConstants.primary;
      case TicketStatus.inProgress:
        return ColorConstants.warning;
      case TicketStatus.resolved:
        return ColorConstants.success;
      case TicketStatus.closed:
        return ColorConstants.textSecondaryLight;
    }
  }
}

class _CreateTicketPage extends StatefulWidget {
  const _CreateTicketPage();

  @override
  State<_CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<_CreateTicketPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  SupportCategory _selectedCategory = SupportCategory.general;
  late SupportController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<SupportController>();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await _controller.createTicket(
      categoryId: 'cat_${_selectedCategory.name}',
      subject: _subjectController.text,
      description: _messageController.text,
      priority: TicketPriority.medium,
    );
    
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (_controller.errorMessage != null) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.errorMessage!), backgroundColor: ColorConstants.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully'), backgroundColor: ColorConstants.success),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupportCategory.values.map((cat) => ChoiceChip(
                label: Text(cat.label),
                selected: _selectedCategory == cat,
                onSelected: (_) => setState(() => _selectedCategory = cat),
              )).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject', hintText: 'Brief description of your issue'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Describe your issue in detail...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitTicket,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailPage extends StatefulWidget {
  final SupportTicketEntity ticket;

  const _TicketDetailPage({required this.ticket});

  @override
  State<_TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<_TicketDetailPage> {
  final _messageController = TextEditingController();
  late SupportController _controller;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<SupportController>();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() => _isSending = true);
    await _controller.addMessage(
      ticketId: widget.ticket.id,
      message: _messageController.text,
    );
    _messageController.clear();
    setState(() => _isSending = false);

    if (mounted) {
       if (_controller.errorMessage != null) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.errorMessage!), backgroundColor: ColorConstants.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatusBadge(status: widget.ticket.status),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.ticket.messages.length,
              itemBuilder: (context, index) => _MessageBubble(message: widget.ticket.messages[index]),
            ),
          ),
          if (widget.ticket.isOpen)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
                border: Border(top: BorderSide(color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(hintText: 'Type your message...', border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: ColorConstants.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageEntity message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSupport = message.isFromSupport;

    return Align(
      alignment: isSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSupport
              ? (isDark ? ColorConstants.surfaceDark : ColorConstants.backgroundSecondaryLight)
              : ColorConstants.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSupport ? ColorConstants.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(message.message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
