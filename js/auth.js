// auth.js

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
const supabase = createClient(supabaseUrl, supabaseKey);

export async function loginComEmail(email, password) {
    const { user, session, error } = await supabase.auth.signIn({ email, password });
    return { user, session, error };
}

export async function cadastrarComEmail(email, password) {
    const { user, error } = await supabase.auth.signUp({ email, password });
    return { user, error };
}

export async function loginComOAuth(provider) {
    const { user, session, error } = await supabase.auth.signIn({ provider });
    return { user, session, error };
}

export async function getUsuarioAtual() {
    const { data: { user }, error } = await supabase.auth.getUser();
    return { user, error };
}

export async function logout() {
    const { error } = await supabase.auth.signOut();
    return { error };
}

export function onAuthStateChange(callback) {
    supabase.auth.onAuthStateChange((event, session) => {
        callback(event, session);
    });
}