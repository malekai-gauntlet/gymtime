-- Drop columns if they exist
ALTER TABLE profiles 
DROP COLUMN IF EXISTS has_seen_onboarding;
ALTER TABLE profiles 
DROP COLUMN IF EXISTS has_seen_weights_tooltip;

-- Add has_seen_onboarding column to profiles table
ALTER TABLE profiles 
ADD COLUMN has_seen_onboarding BOOLEAN DEFAULT false;

-- Add has_seen_weights_tooltip column to profiles table
ALTER TABLE profiles 
ADD COLUMN has_seen_weights_tooltip BOOLEAN DEFAULT false;

-- Update existing profiles to have has_seen_onboarding and has_seen_weights_tooltip set to true
-- (assuming existing users shouldn't see tooltips)
UPDATE profiles 
SET has_seen_onboarding = true,
    has_seen_weights_tooltip = true
WHERE id IS NOT NULL;

-- No RLS policies as requested 