-- Add profile_photo_url and cover_photo_url columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cover_photo_url TEXT;

-- Add comments
COMMENT ON COLUMN users.profile_photo_url IS 'Public URL of user profile photo from user-avatars bucket';
COMMENT ON COLUMN users.cover_photo_url IS 'Public URL of user cover photo from user-covers bucket';
