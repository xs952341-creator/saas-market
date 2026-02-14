// config.js
// Configuração central do frontend (Supabase + Stripe)

(() => {
  const SUPABASE_URL = "https://mmjvqwolxyzloyfzalbo.supabase.co";
  const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tanZxd29seHl6bG95ZnphbGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODUwMTEsImV4cCI6MjA4NjU2MTAxMX0.UW2znkCsoij4wERR2SDq35nikbRW62I0LGGe1DUmibs";

  // Chave pública do Stripe (nunca usar sk_ no frontend)
  const STRIPE_PUBLISHABLE_KEY = "pk_test_51T09lnKA5X0ZTel56jjG1XT1F4qrxZ7hh1yXM0if38h3U957V4uQevD6gkSTNdLUh8dGluVmdaKMjrwdkAUBOyFU00QjKtPxVs";

  if (!window.supabase?.createClient) {
    console.error("[config] SDK do Supabase não foi carregado. Inclua @supabase/supabase-js antes de config.js.");
    return;
  }

  const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  let stripeClient = null;
  if (typeof window.Stripe === "function") {
    stripeClient = window.Stripe(STRIPE_PUBLISHABLE_KEY);
  }

  window.CONFIG = {
    supabase: {
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    },
    stripe: {
      publishableKey: STRIPE_PUBLISHABLE_KEY,
    },
  };

  // Compatibilidade com páginas atuais
  window.supabase = supabaseClient;
  window.stripe = stripeClient;
})();
