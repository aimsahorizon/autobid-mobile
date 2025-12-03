-- Support Tickets System Schema

-- Support ticket categories
CREATE TABLE IF NOT EXISTS support_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support tickets
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES support_categories(id),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ
);

-- Support ticket messages (conversation thread)
CREATE TABLE IF NOT EXISTS support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false, -- Internal notes only visible to staff
    attachments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support ticket attachments
CREATE TABLE IF NOT EXISTS support_ticket_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
    message_id UUID REFERENCES support_ticket_messages(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type TEXT NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT attachment_parent CHECK (ticket_id IS NOT NULL OR message_id IS NOT NULL)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category_id ON support_tickets(category_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket_id ON support_ticket_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_created_at ON support_ticket_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_ticket_attachments_ticket_id ON support_ticket_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_attachments_message_id ON support_ticket_attachments(message_id);

-- Updated at trigger function (reuse if exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_support_categories_updated_at
    BEFORE UPDATE ON support_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_tickets_updated_at
    BEFORE UPDATE ON support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_ticket_messages_updated_at
    BEFORE UPDATE ON support_ticket_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE support_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for support_categories (public read)
CREATE POLICY "Anyone can view active categories"
    ON support_categories FOR SELECT
    USING (is_active = true);

-- Note: Only admins should manage categories via Supabase dashboard
-- For now, disable INSERT/UPDATE/DELETE for regular users
CREATE POLICY "Prevent category modifications"
    ON support_categories FOR ALL
    USING (false);

-- RLS Policies for support_tickets
CREATE POLICY "Users can view their own tickets"
    ON support_tickets FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can create their own tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own tickets"
    ON support_tickets FOR UPDATE
    USING (user_id = auth.uid());

-- RLS Policies for support_ticket_messages
CREATE POLICY "Users can view messages for their tickets"
    ON support_ticket_messages FOR SELECT
    USING (
        is_internal = false
        AND EXISTS (
            SELECT 1 FROM support_tickets
            WHERE support_tickets.id = ticket_id
            AND support_tickets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages for their tickets"
    ON support_ticket_messages FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM support_tickets
            WHERE support_tickets.id = ticket_id
            AND support_tickets.user_id = auth.uid()
        )
    );

-- RLS Policies for support_ticket_attachments
CREATE POLICY "Users can view attachments for their tickets"
    ON support_ticket_attachments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets
            WHERE support_tickets.id = ticket_id
            AND support_tickets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can upload attachments for their tickets"
    ON support_ticket_attachments FOR INSERT
    WITH CHECK (
        uploaded_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM support_tickets
            WHERE support_tickets.id = ticket_id
            AND support_tickets.user_id = auth.uid()
        )
    );

-- Insert default support categories
INSERT INTO support_categories (name, description) VALUES
    ('Account Issues', 'Problems with account access, login, or profile'),
    ('Bidding Problems', 'Issues related to placing bids or auction participation'),
    ('Payment Issues', 'Problems with payments, refunds, or transactions'),
    ('Listing Problems', 'Issues with creating or managing listings'),
    ('Technical Support', 'App bugs, crashes, or technical difficulties'),
    ('General Inquiry', 'General questions or information requests'),
    ('Report User', 'Report inappropriate behavior or fraudulent activity'),
    ('Feature Request', 'Suggestions for new features or improvements')
ON CONFLICT (name) DO NOTHING;

-- Function to auto-close resolved tickets after 7 days
CREATE OR REPLACE FUNCTION auto_close_resolved_tickets()
RETURNS void AS $$
BEGIN
    UPDATE support_tickets
    SET status = 'closed',
        closed_at = NOW()
    WHERE status = 'resolved'
    AND resolved_at < NOW() - INTERVAL '7 days'
    AND closed_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to get ticket statistics for a user
CREATE OR REPLACE FUNCTION get_user_ticket_stats(p_user_id UUID)
RETURNS TABLE (
    total_tickets BIGINT,
    open_tickets BIGINT,
    in_progress_tickets BIGINT,
    resolved_tickets BIGINT,
    closed_tickets BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) AS total_tickets,
        COUNT(*) FILTER (WHERE status = 'open') AS open_tickets,
        COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress_tickets,
        COUNT(*) FILTER (WHERE status = 'resolved') AS resolved_tickets,
        COUNT(*) FILTER (WHERE status = 'closed') AS closed_tickets
    FROM support_tickets
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
