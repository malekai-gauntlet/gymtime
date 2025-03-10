-- Add is_anonymous column to profiles table
alter table profiles
add column is_anonymous boolean default true;

-- Update existing profiles
update profiles
set is_anonymous = false
where username is not null and username != ''; 