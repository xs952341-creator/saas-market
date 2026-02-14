const CONFIG = {
  supabase: {
    url: process.env.https://mmjvqwolxyzloyfzalbo.supabase.co || '',
    anonKey: process.env.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tanZxd29seHl6bG95ZnphbGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODUwMTEsImV4cCI6MjA4NjU2MTAxMX0.UW2znkCsoij4wERR2SDq35nikbRW62I0LGGe1DUmibs || ''
  },
  
  stripe: {
    publishableKey: process.env.pk_test_51T09lnKA5X0ZTel56jjG1XT1F4qrxZ7hh1yXM0if38h3U957V4uQevD6gkSTNdLUh8dGluVmdaKMjrwdkAUBOyFU00QjKtPxVs|| ''
  },
  
  comissaoPlataforma: 10,
  siteUrl: process.env.https://saas-market-blond.vercel.app/ || window.location.origin
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
