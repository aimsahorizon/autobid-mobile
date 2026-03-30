-- Add admin RLS policies on transaction_reports so admins can view and manage reports
-- Previously only reporter could SELECT their own reports; admins had no access

CREATE POLICY "Admins can view all transaction reports"
  ON public.transaction_reports FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can update transaction reports"
  ON public.transaction_reports FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
  );
