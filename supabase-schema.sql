-- ============================================
-- SAASMARKET - ESTRUTURA DO BANCO DE DADOS
-- ============================================

-- 1. TABELA DE USUÁRIOS (VENDEDORES)
CREATE TABLE sellers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  nome TEXT NOT NULL,
  stripe_account_id TEXT UNIQUE, -- ID da conta conectada no Stripe
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABELA DE PRODUTOS (SAAS)
CREATE TABLE produtos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  descricao TEXT NOT NULL,
  descricao_longa TEXT,
  preco DECIMAL(10,2) NOT NULL,
  stripe_price_id TEXT NOT NULL, -- ID do price no Stripe
  stripe_product_id TEXT NOT NULL, -- ID do produto no Stripe
  logo_url TEXT,
  verificado BOOLEAN DEFAULT FALSE,
  ativo BOOLEAN DEFAULT TRUE,
  categoria TEXT, -- ex: "Vendas", "Marketing", "Automação"
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABELA DE COMPRAS
CREATE TABLE compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produto_id UUID REFERENCES produtos(id),
  seller_id UUID REFERENCES sellers(id),
  comprador_email TEXT NOT NULL,
  comprador_nome TEXT,
  stripe_session_id TEXT UNIQUE, -- ID da sessão de checkout
  stripe_subscription_id TEXT, -- ID da assinatura criada
  valor DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, completed, cancelled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- 4. TABELA DE WEBHOOKS (LOG)
CREATE TABLE webhook_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL,
  stripe_event_id TEXT UNIQUE,
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- ============================================

-- Habilitar RLS
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras ENABLE ROW LEVEL SECURITY;

-- Sellers: podem ver apenas seus próprios dados
CREATE POLICY "Sellers podem ver seus dados"
  ON sellers FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Sellers podem atualizar seus dados"
  ON sellers FOR UPDATE
  USING (auth.uid() = id);

-- Produtos: todos podem ver produtos ativos
CREATE POLICY "Todos podem ver produtos ativos"
  ON produtos FOR SELECT
  USING (ativo = TRUE);

CREATE POLICY "Sellers podem criar produtos"
  ON produtos FOR INSERT
  WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Sellers podem editar seus produtos"
  ON produtos FOR UPDATE
  USING (auth.uid() = seller_id);

-- Compras: sellers veem apenas suas vendas
CREATE POLICY "Sellers veem suas vendas"
  ON compras FOR SELECT
  USING (auth.uid() = seller_id);

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX idx_produtos_seller ON produtos(seller_id);
CREATE INDEX idx_produtos_ativo ON produtos(ativo);
CREATE INDEX idx_compras_produto ON compras(produto_id);
CREATE INDEX idx_compras_seller ON compras(seller_id);
CREATE INDEX idx_compras_status ON compras(status);
