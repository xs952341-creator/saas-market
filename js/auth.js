// ============================================
// SISTEMA DE AUTENTICAÇÃO
// ============================================

import { supabase } from './config.js';

function inPath(name) {
  const p = window.location.pathname.toLowerCase();
  return p.endsWith(name) || p.includes(name);
}

function goToReception() {
  const saved = sessionStorage.getItem('redirectAfterLogin');
  if (saved && !saved.includes('login.html') && !saved.includes('index.html')) {
    sessionStorage.removeItem('redirectAfterLogin');
    window.location.href = saved;
    return;
  }
  window.location.href = '/hub.html';
}

supabase.auth.onAuthStateChange((event, session) => {
  console.log('🔐 Auth Event:', event);

  if (event === 'SIGNED_IN' && session) {
    if (inPath('login.html') || inPath('/login')) {
      goToReception();
    }
  }

  if (event === 'SIGNED_OUT') {
    if (!inPath('index.html') && !inPath('login.html') && window.location.pathname !== '/') {
      window.location.href = '/login.html';
    }
  }
});

export async function loginComEmail(email, senha) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password: senha });

    // Supabase retorna {data,error}; sucesso (equivalente 200/204/304) => sem error e com sessão/usuário
    if (!error && (data?.session || data?.user)) {
      return { success: true, data };
    }

    if (error) throw error;

    return { success: false, error: 'Resposta de autenticação inválida.' };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

export async function cadastrarComEmail(email, senha, nome) {
  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password: senha,
      options: { data: { nome } }
    });

    if (error) throw error;

    if (data?.user) {
      const { error: sellerError } = await supabase.from('sellers').upsert({
        id: data.user.id,
        email,
        nome: nome || email.split('@')[0]
      });

      if (sellerError) {
        console.warn('⚠️ Não foi possível criar/atualizar seller:', sellerError.message);
      }
    }

    return { success: true, data };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

export async function loginComOAuth(provider) {
  try {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/hub.html`
      }
    });

    if (error) throw error;
    return { success: true, data };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

export async function logout() {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  } finally {
    window.location.href = '/index.html';
  }
}

export async function getUsuarioAtual() {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    if (!session) return { success: false, user: null };
    return { success: true, user: session.user, session };
  } catch (error) {
    return { success: false, error: error.message, user: null };
  }
}

export async function estaLogado() {
  const res = await getUsuarioAtual();
  return res.success;
}

window.authFunctions = {
  loginComEmail,
  cadastrarComEmail,
  loginComOAuth,
  logout,
  getUsuarioAtual,
  estaLogado
};
