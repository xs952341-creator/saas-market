// ============================================
// CONFIGURAÇÃO (MÓDULO ES6)
// ============================================

export const CONFIG = {
  supabase: {
    // Mantidas as chaves originais já funcionais do projeto
    url: 'https://mmjvqwolxyzloyfzalbo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tanZxd29seHl6bG95ZnphbGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODUwMTEsImV4cCI6MjA4NjU2MTAxMX0.UW2znkCsoij4wERR2SDq35nikbRW62I0LGGe1DUmibs'
  },
  stripe: {
    publishableKey: 'pk_test_51SzLc3E3IKoGtVrQl5EOfE7WbGQaAwtZLXW1mBMUoH5In7FSrFal5G3OBMnS90XTGQGBZiWWUbJ1RPjUsrYnzVgZ00za1abLj4'
  },
  comissaoPlataforma: 10,
  siteUrl: window.location.origin
};

if (!window.supabase?.createClient) {
  throw new Error('SDK Supabase não carregado. Inclua https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2 antes do módulo.');
}

export const supabase = window.supabase.createClient(
  CONFIG.supabase.url,
  CONFIG.supabase.anonKey
);

export const stripe = typeof window.Stripe === 'function'
  ? window.Stripe(CONFIG.stripe.publishableKey)
  : null;

// Compatibilidade global
window.CONFIG = CONFIG;
window.supabaseClient = supabase;
window.stripeClient = stripe;
