-- ============================================
-- SAASMARKET - ESTRUTURA DO BANCO DE DADOS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABELA DE USUÁRIOS (VENDEDORES)
CREATE TABLE IF NOT EXISTS sellers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  nome TEXT NOT NULL,
  stripe_account_id TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABELA DE PRODUTOS (SAAS)
CREATE TABLE IF NOT EXISTS produtos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  descricao TEXT NOT NULL,
  descricao_longa TEXT,
  preco DECIMAL(10,2) NOT NULL,
  stripe_price_id TEXT NOT NULL,
  stripe_product_id TEXT NOT NULL,
  platform_fee_percent DECIMAL(5,2) NOT NULL DEFAULT 10.00,
  logo_url TEXT,
  verificado BOOLEAN DEFAULT FALSE,
  ativo BOOLEAN DEFAULT TRUE,
  categoria TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABELA DE COMPRAS
CREATE TABLE IF NOT EXISTS compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produto_id UUID REFERENCES produtos(id),
  seller_id UUID REFERENCES sellers(id),
  comprador_email TEXT NOT NULL,
  comprador_nome TEXT,
  stripe_session_id TEXT UNIQUE,
  stripe_subscription_id TEXT,
  valor DECIMAL(10,2) NOT NULL,
  platform_fee_value DECIMAL(10,2) DEFAULT 0,
  seller_net_value DECIMAL(10,2) DEFAULT 0,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- 4. TABELA DE AFILIADOS
CREATE TABLE IF NOT EXISTS affiliates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
  affiliate_email TEXT NOT NULL,
  commission_percent DECIMAL(5,2) NOT NULL DEFAULT 30.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (produto_id, affiliate_email)
);

-- 5. TABELA DE WEBHOOKS (LOG)
CREATE TABLE IF NOT EXISTS webhook_logs (
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

ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliates ENABLE ROW LEVEL SECURITY;

-- Sellers: apenas seus próprios dados
DROP POLICY IF EXISTS "Sellers podem ver seus dados" ON sellers;
CREATE POLICY "Sellers podem ver seus dados"
  ON sellers FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Sellers podem atualizar seus dados" ON sellers;
CREATE POLICY "Sellers podem atualizar seus dados"
  ON sellers FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Sellers podem criar o proprio perfil" ON sellers;
CREATE POLICY "Sellers podem criar o proprio perfil"
  ON sellers FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Produtos públicos ativos + CRUD do seller dono
DROP POLICY IF EXISTS "Todos podem ver produtos ativos" ON produtos;
CREATE POLICY "Todos podem ver produtos ativos"
  ON produtos FOR SELECT
  USING (ativo = TRUE);

DROP POLICY IF EXISTS "Sellers podem criar produtos" ON produtos;
CREATE POLICY "Sellers podem criar produtos"
  ON produtos FOR INSERT
  WITH CHECK (auth.uid() = seller_id);

DROP POLICY IF EXISTS "Sellers podem editar seus produtos" ON produtos;
CREATE POLICY "Sellers podem editar seus produtos"
  ON produtos FOR UPDATE
  USING (auth.uid() = seller_id);

-- Compras: seller vê somente as vendas dele
DROP POLICY IF EXISTS "Sellers veem suas vendas" ON compras;
CREATE POLICY "Sellers veem suas vendas"
  ON compras FOR SELECT
  USING (auth.uid() = seller_id);

-- Afiliados: seller vê/cadastra afiliados dos seus produtos

DROP POLICY IF EXISTS "Comprador consulta status por session" ON compras;
CREATE POLICY "Comprador consulta status por session"
  ON compras FOR SELECT TO anon
  USING (stripe_session_id IS NOT NULL);

DROP POLICY IF EXISTS "Sellers veem afiliados dos seus produtos" ON affiliates;
CREATE POLICY "Sellers veem afiliados dos seus produtos"
  ON affiliates FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM produtos p
      WHERE p.id = affiliates.produto_id
      AND p.seller_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Sellers cadastram afiliados dos seus produtos" ON affiliates;
CREATE POLICY "Sellers cadastram afiliados dos seus produtos"
  ON affiliates FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM produtos p
      WHERE p.id = affiliates.produto_id
      AND p.seller_id = auth.uid()
    )
  );

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_produtos_seller ON produtos(seller_id);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON produtos(ativo);
CREATE INDEX IF NOT EXISTS idx_compras_produto ON compras(produto_id);
CREATE INDEX IF NOT EXISTS idx_compras_seller ON compras(seller_id);
CREATE INDEX IF NOT EXISTS idx_compras_status ON compras(status);
CREATE INDEX IF NOT EXISTS idx_affiliates_produto ON affiliates(produto_id);
