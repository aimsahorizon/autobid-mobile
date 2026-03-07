-- Add last_edited_by column to track who last edited each agreement field
ALTER TABLE transaction_agreement_fields
  ADD COLUMN IF NOT EXISTS last_edited_by UUID REFERENCES auth.users(id);
