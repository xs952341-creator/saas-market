// ============================================
// CONFIGURAÇÃO - SUBSTITUA COM SUAS CHAVES
// ============================================

const CONFIG = {
  // SUPABASE
  supabase: {
    url: 'https://mmjvqwolxyzloyfzalbo.supabase.co', // Ex: https://xxxxx.supabase.co
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tanZxd29seHl6bG95ZnphbGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODUwMTEsImV4cCI6MjA4NjU2MTAxMX0.UW2znkCsoij4wERR2SDq35nikbRW62I0LGGe1DUmibs'
  
  // STRIPE
  stripe: {
    publishableKey: 'pk_test_51SzLc3E3IKoGtVrQl5EOfE7WbGQaAwtZLXW1mBMUoH5In7FSrFal5G3OBMnS90XTGQGBZiWWUbJ1RPjUsrYnzVgZ00za1abLj4', // pk_test_... ou pk_live_...
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
window.supabase = supabase,
window.stripe = stripe,
