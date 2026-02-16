// Authentication Functions using Supabase Client

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://your-supabase-url.supabase.co';
const supabaseKey = 'your-supabase-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Login with Email
export const loginComEmail = async (email, password) => {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  return { data, error };
};

// Register with Email
export const cadastrarComEmail = async (email, password) => {
  const { data, error } = await supabase.auth.signUp({ email, password });
  return { data, error };
};

// Login with OAuth
export const loginComOAuth = async (provider) => {
  const { data, error } = await supabase.auth.signInWithOAuth({ provider });
  return { data, error };
};

// Get Current User
export const getUsuarioAtual = () => {
  return supabase.auth.user();
};

// Logout
export const logout = async () => {
  const { error } = await supabase.auth.signOut();
  return { error };
};

// On Auth State Change
export const onAuthStateChange = (callback) => {
  return supabase.auth.onAuthStateChange(callback);
};
