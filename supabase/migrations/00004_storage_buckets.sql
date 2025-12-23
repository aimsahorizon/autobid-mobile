-- ============================================================================
-- AutoBid Mobile - Storage Buckets & Policies
-- ============================================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('kyc-documents', 'kyc-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('auction-images', 'auction-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('payment-proofs', 'payment-proofs', false, 5242880, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('chat-attachments', 'chat-attachments', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
  ('system-assets', 'system-assets', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/svg+xml', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- AVATARS BUCKET
-- ============================================================================

-- Users can upload their own avatars
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can update their own avatars
CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can delete their own avatars
CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Anyone can view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- ============================================================================
-- KYC DOCUMENTS BUCKET (Private)
-- ============================================================================

-- Users can upload their own KYC documents
CREATE POLICY "Users can upload their KYC documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'kyc-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can view their own KYC documents
CREATE POLICY "Users can view their own KYC documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'kyc-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Admins can view all KYC documents
CREATE POLICY "Admins can view all KYC documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'kyc-documents' AND
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- ============================================================================
-- AUCTION IMAGES BUCKET (Public)
-- ============================================================================

-- Sellers can upload images for their auctions
CREATE POLICY "Sellers can upload auction images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'auction-images' AND
    EXISTS (
      SELECT 1 FROM auctions
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
  );

-- Sellers can update their auction images
CREATE POLICY "Sellers can update their auction images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'auction-images' AND
    EXISTS (
      SELECT 1 FROM auctions
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
  );

-- Sellers can delete their auction images
CREATE POLICY "Sellers can delete their auction images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'auction-images' AND
    EXISTS (
      SELECT 1 FROM auctions
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
  );

-- Anyone can view auction images (public bucket)
CREATE POLICY "Anyone can view auction images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'auction-images');

-- ============================================================================
-- PAYMENT PROOFS BUCKET (Private)
-- ============================================================================

-- Users can upload payment proofs
CREATE POLICY "Users can upload payment proofs"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'payment-proofs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can view their own payment proofs
CREATE POLICY "Users can view their own payment proofs"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'payment-proofs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Admins can view all payment proofs
CREATE POLICY "Admins can view all payment proofs"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'payment-proofs' AND
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- ============================================================================
-- CHAT ATTACHMENTS BUCKET (Private)
-- ============================================================================

-- Users can upload chat attachments in their rooms
CREATE POLICY "Users can upload chat attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat-attachments' AND
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id::text = (storage.foldername(name))[1]
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

-- Room participants can view attachments
CREATE POLICY "Room participants can view attachments"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat-attachments' AND
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id::text = (storage.foldername(name))[1]
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

-- ============================================================================
-- SYSTEM ASSETS BUCKET (Public)
-- ============================================================================

-- Only admins can upload system assets
CREATE POLICY "Admins can upload system assets"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'system-assets' AND
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Only admins can manage system assets
CREATE POLICY "Admins can manage system assets"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'system-assets' AND
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Anyone can view system assets (public bucket)
CREATE POLICY "Anyone can view system assets"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'system-assets');

-- ============================================================================
-- END OF STORAGE POLICIES
-- ============================================================================
