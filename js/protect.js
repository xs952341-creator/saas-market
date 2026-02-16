// ============================================
// PROTEÇÃO DE PÁGINAS
// ============================================

import { supabase } from './config.js';

function redirectToLogin() {
  sessionStorage.setItem('redirectAfterLogin', window.location.pathname);
  window.location.href = '/login.html';
}

export async function protectPage() {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();

    if (error) {
      console.error('Erro de sessão:', error.message);
      redirectToLogin();
      return null;
    }

    if (!session) {
      redirectToLogin();
      return null;
    }

    return session.user;
  } catch (error) {
    console.error('Erro crítico de auth:', error.message);
    redirectToLogin();
    return null;
  }
}

export async function checkAuthStatus() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    return { isAuthenticated: !!session, user: session?.user || null };
  } catch {
    return { isAuthenticated: false, user: null };
  }
}

export async function softProtect() {
  const { isAuthenticated, user } = await checkAuthStatus();

  document.querySelectorAll('.when-logged-out').forEach((el) => {
    el.style.display = isAuthenticated ? 'none' : 'block';
  });
  document.querySelectorAll('.when-logged-in').forEach((el) => {
    el.style.display = isAuthenticated ? 'block' : 'none';
  });

  return { isAuthenticated, user };
}

window.protectPage = protectPage;
window.checkAuthStatus = checkAuthStatus;
window.softProtect = softProtect;
