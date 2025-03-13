import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get user ID from request
    const { user_id } = await req.json()
    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'user_id is required' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Check environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('Missing environment variables:', {
        hasUrl: !!supabaseUrl,
        hasServiceKey: !!supabaseServiceKey
      })
      throw new Error('Missing required environment variables')
    }

    // Create Supabase admin client
    const supabaseAdmin = createClient(
      supabaseUrl,
      supabaseServiceKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    console.log('Starting deletion process for user:', user_id)

    // Normalize the UUID to lowercase
    const normalizedUserId = user_id.toLowerCase()
    console.log('Normalized user ID:', normalizedUserId)

    // Verify user exists first
    const { data: userData, error: getUserError } = await supabaseAdmin.auth.admin.getUserById(normalizedUserId)
    if (getUserError) {
      console.error('Error getting user:', getUserError)
      throw getUserError
    }
    if (!userData) {
      console.error('User not found:', normalizedUserId)
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { 
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
    console.log('Found user to delete:', userData.user.email)

    // Add a small delay to ensure no concurrent operations
    await new Promise(resolve => setTimeout(resolve, 1000))

    // Delete auth user - this will cascade delete profiles and workouts
    console.log('Initiating deletion for user:', normalizedUserId)
    const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(normalizedUserId)
    if (authError) {
      console.error('Error deleting user:', authError)
      throw authError
    }

    console.log('Successfully deleted user and all related data')
    return new Response(
      JSON.stringify({ success: true }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        details: error.details || error.toString()
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}) 