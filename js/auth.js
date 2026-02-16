import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'your_supabase_url';
const SUPABASE_ANON_KEY = 'your_supabase_anon_key';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export const register = async (email, password) => {
    const { user, error } = await supabase.auth.signUp({ email, password });
    if (error) throw error;
    return user;
};

export const login = async (email, password) => {
    const { user, error } = await supabase.auth.signIn({ email, password });
    if (error) throw error;
    return user;
};

export const oAuthLogin = async (provider) => {
    const { user, session, error } = await supabase.auth.signIn({ provider });
    if (error) throw error;
    return { user, session };
};