CREATE POLICY "Sellers can update their own auction status"
ON public.auctions
FOR UPDATE
TO authenticated
USING (seller_id = auth.uid())
WITH CHECK (seller_id = auth.uid());