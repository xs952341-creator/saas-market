'use strict';

// Supabase configuration
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_KEY';
const supabaseClient = supabase.createClient(supabaseUrl, supabaseKey);

// Stripe configuration
const stripeKey = 'YOUR_STRIPE_KEY';
const stripe = require('stripe')(stripeKey);

export { supabaseClient, stripe };