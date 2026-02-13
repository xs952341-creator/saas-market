// ============================================
// CONFIGURAÇÃO - SUBSTITUA COM SUAS CHAVES
// ============================================

const CONFIG = {
  // SUPABASE
  supabase: {
    url: 'SUA_URL_DO_SUPABASE', // Ex: https://xxxxx.supabase.co
    anonKey: 'SUA_ANON_KEY_DO_SUPABASE'
  },
  
  // STRIPE
  stripe: {
    publishableKey: 'SUA_PUBLISHABLE_KEY_DA_STRIPE', // pk_test_... ou pk_live_...
    // Webhook secret (para validar eventos)
    webhookSecret: 'whsec_...' // Você vai configurar isso depois
  },
  
  // COMISSÃO DA PLATAFORMA (em %)
  // Ex: 10 = você fica com 10% de cada venda
  comissaoPlataforma: 10,
  
  // URL DO SEU SITE (para redirects)
  siteUrl: window.location.origin
};

// Inicializar Supabase
const supabase = window.supabase.createClient(
  CONFIG.supabase.url,
  CONFIG.supabase.anonKey
);

// Inicializar Stripe
const stripe = Stripe(CONFIG.stripe.publishableKey);

// Exportar para outros arquivos
window.CONFIG = CONFIG;
window.supabase = supabase;
window.stripe = stripe;
