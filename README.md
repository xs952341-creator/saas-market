# SaaSMarket

Marketplace de micro-SaaS com frontend estático (HTML + JS), Supabase (Auth/DB) e checkout via Stripe.

## Stack

- Frontend: HTML + JavaScript puro
- Backend/Data: Supabase (Auth + Postgres + Edge Functions)
- Pagamentos: Stripe Checkout

## Configuração

As chaves usadas no frontend ficam em `config.js`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (**somente anon/public key**)
- `STRIPE_PUBLISHABLE_KEY` (**somente pk_...**)

> Nunca use `service_role` nem `sk_...` no frontend.

## Banco de dados

Execute `supabase-schema.sql` no SQL Editor do Supabase para criar:

- `sellers`
- `produtos`
- `compras`
- `webhook_logs`

Além disso, o schema já inclui:

- campo de comissão da plataforma (`platform_fee_percent` em `produtos`)
- valores de comissão por compra (`platform_fee_value`, `seller_net_value` em `compras`)
- tabela de afiliados (`affiliates`)

## Fluxo de compra

1. Usuário abre `produto.html?id=<produto_id>`
2. Front chama Edge Function `create-checkout`
3. Stripe Checkout finaliza o pagamento
4. Webhook atualiza `compras.status`
5. `sucesso.html?session_id=...` consulta status da compra

## Checklist rápido de debug

- Se aparecer erro de Supabase no console:
  - confira URL e anon key em `config.js`
  - valide se RLS/policies foram aplicadas pelo SQL
- Se Stripe não abrir checkout:
  - confira se `https://js.stripe.com/v3/` está carregado na página
  - confira se a chave é `pk_test`/`pk_live` do mesmo modo da API
- Se compra não aparecer no dashboard:
  - valide webhook da Stripe e atualização de `compras.status`
