-- ============================================
-- SAASMARKET - SCHEMA ATUALIZADO COM PAY-PER-USE
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ADICIONAR NOVAS COLUNAS NA TABELA PRODUTOS
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS tipo_cobranca TEXT DEFAULT 'assinatura'; -- 'assinatura' ou 'pay-per-use'
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS preco_por_uso DECIMAL(10,4); -- Para pay-per-use
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS unidade_cobranca TEXT; -- 'requisicao', 'minuto', 'processamento'
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS api_url TEXT; -- URL da API do Micro-SaaS
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS sandbox_disponivel BOOLEAN DEFAULT FALSE;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS taxa_sucesso DECIMAL(5,2) DEFAULT 100.00; -- % de sucesso
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS total_execucoes INTEGER DEFAULT 0;

-- TABELA DE SALDO DOS USUÁRIOS
CREATE TABLE IF NOT EXISTS carteiras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  saldo DECIMAL(10,2) DEFAULT 0.00,
  saldo_bloqueado DECIMAL(10,2) DEFAULT 0.00, -- Para reservar durante execução
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- TABELA DE CONSUMO (PAY-PER-USE)
CREATE TABLE IF NOT EXISTS consumos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
  comprador_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  seller_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  quantidade INTEGER DEFAULT 1,
  valor_unitario DECIMAL(10,4),
  valor_total DECIMAL(10,2),
  status TEXT DEFAULT 'completed',
  response_time_ms INTEGER,
  sucesso BOOLEAN DEFAULT TRUE,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABELA DE TRANSAÇÕES DA CARTEIRA
CREATE TABLE IF NOT EXISTS transacoes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  saldo_anterior DECIMAL(10,2),
  saldo_novo DECIMAL(10,2),
  descricao TEXT,
  referencia_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABELA DE API KEYS
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
  key_hash TEXT NOT NULL,
  key_prefix TEXT NOT NULL,
  ativa BOOLEAN DEFAULT TRUE,
  limite_diario INTEGER,
  uso_atual_dia INTEGER DEFAULT 0,
  ultimo_uso TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- TABELA DE INVESTIMENTOS
CREATE TABLE IF NOT EXISTS investimentos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
  investidor_id UUID REFERENCES sellers(id) ON DELETE CASCADE,
  percentual_propriedade DECIMAL(5,2),
  valor_investido DECIMAL(10,2),
  lucro_acumulado DECIMAL(10,2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_consumos_produto ON consumos(produto_id);
CREATE INDEX IF NOT EXISTS idx_consumos_comprador ON consumos(comprador_id);
CREATE INDEX IF NOT EXISTS idx_consumos_data ON consumos(created_at);
CREATE INDEX IF NOT EXISTS idx_transacoes_user ON transacoes(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_user ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_produto ON api_keys(produto_id);

-- RLS
ALTER TABLE carteiras ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE investimentos ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS DE ACESSO
DROP POLICY IF EXISTS "Usuários veem sua carteira" ON carteiras;
CREATE POLICY "Usuários veem sua carteira"
  ON carteiras FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários atualizam sua carteira" ON carteiras;
CREATE POLICY "Usuários atualizam sua carteira"
  ON carteiras FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários criam sua carteira" ON carteiras;
CREATE POLICY "Usuários criam sua carteira"
  ON carteiras FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários veem seus consumos" ON consumos;
CREATE POLICY "Usuários veem seus consumos"
  ON consumos FOR SELECT
  USING (auth.uid() = comprador_id OR auth.uid() = seller_id);

DROP POLICY IF EXISTS "Usuários criam seus consumos" ON consumos;
CREATE POLICY "Usuários criam seus consumos"
  ON consumos FOR INSERT
  WITH CHECK (auth.uid() = comprador_id);

DROP POLICY IF EXISTS "Usuários veem suas transações" ON transacoes;
CREATE POLICY "Usuários veem suas transações"
  ON transacoes FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários criam suas transações" ON transacoes;
CREATE POLICY "Usuários criam suas transações"
  ON transacoes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários veem suas API keys" ON api_keys;
CREATE POLICY "Usuários veem suas API keys"
  ON api_keys FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários criam suas API keys" ON api_keys;
CREATE POLICY "Usuários criam suas API keys"
  ON api_keys FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Investidores veem seus investimentos" ON investimentos;
CREATE POLICY "Investidores veem seus investimentos"
  ON investimentos FOR SELECT
  USING (auth.uid() = investidor_id);

-- FUNÇÃO PARA ATUALIZAR TAXA DE SUCESSO DO PRODUTO
CREATE OR REPLACE FUNCTION atualizar_taxa_sucesso()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE produtos
  SET
    taxa_sucesso = (
      SELECT (COUNT(*) FILTER (WHERE sucesso = TRUE)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) * 100)
      FROM consumos
      WHERE produto_id = NEW.produto_id
    ),
    total_execucoes = (
      SELECT COUNT(*)
      FROM consumos
      WHERE produto_id = NEW.produto_id
    )
  WHERE id = NEW.produto_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_taxa_sucesso ON consumos;
CREATE TRIGGER trigger_atualizar_taxa_sucesso
AFTER INSERT ON consumos
FOR EACH ROW
EXECUTE FUNCTION atualizar_taxa_sucesso();

-- FUNÇÃO PARA PROCESSAR PAGAMENTO PAY-PER-USE
CREATE OR REPLACE FUNCTION processar_consumo(
  p_produto_id UUID,
  p_comprador_id UUID,
  p_quantidade INTEGER DEFAULT 1,
  p_sucesso BOOLEAN DEFAULT TRUE,
  p_response_time_ms INTEGER DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_produto RECORD;
  v_carteira_comprador RECORD;
  v_carteira_vendedor RECORD;
  v_valor_total DECIMAL(10,2);
  v_novo_saldo_comprador DECIMAL(10,2);
  v_novo_saldo_vendedor DECIMAL(10,2);
  v_consumo_id UUID;
  v_comissao DECIMAL(10,2);
  v_valor_vendedor DECIMAL(10,2);
BEGIN
  -- Buscar produto
  SELECT * INTO v_produto FROM produtos WHERE id = p_produto_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Produto não encontrado');
  END IF;

  -- Calcular valor
  v_valor_total := COALESCE(v_produto.preco_por_uso, 0) * p_quantidade;

  -- Garantir carteira do comprador
  INSERT INTO carteiras (user_id, saldo)
  VALUES (p_comprador_id, 0.00)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_carteira_comprador FROM carteiras WHERE user_id = p_comprador_id;

  IF v_carteira_comprador.saldo < v_valor_total THEN
    RETURN jsonb_build_object('success', false, 'error', 'Saldo insuficiente');
  END IF;

  -- Debitar do comprador
  v_novo_saldo_comprador := v_carteira_comprador.saldo - v_valor_total;

  UPDATE carteiras
  SET saldo = v_novo_saldo_comprador, updated_at = NOW()
  WHERE user_id = p_comprador_id;

  INSERT INTO transacoes (user_id, tipo, valor, saldo_anterior, saldo_novo, descricao)
  VALUES (
    p_comprador_id,
    'compra',
    -v_valor_total,
    v_carteira_comprador.saldo,
    v_novo_saldo_comprador,
    'Uso de ' || v_produto.nome
  );

  -- Creditar vendedor com comissão da plataforma
  v_comissao := v_valor_total * 0.10;
  v_valor_vendedor := v_valor_total - v_comissao;

  INSERT INTO carteiras (user_id, saldo)
  VALUES (v_produto.seller_id, 0.00)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT * INTO v_carteira_vendedor FROM carteiras WHERE user_id = v_produto.seller_id;
  v_novo_saldo_vendedor := v_carteira_vendedor.saldo + v_valor_vendedor;

  UPDATE carteiras
  SET saldo = v_novo_saldo_vendedor, updated_at = NOW()
  WHERE user_id = v_produto.seller_id;

  INSERT INTO transacoes (user_id, tipo, valor, saldo_anterior, saldo_novo, descricao)
  VALUES (
    v_produto.seller_id,
    'recebimento',
    v_valor_vendedor,
    v_carteira_vendedor.saldo,
    v_novo_saldo_vendedor,
    'Venda de uso de ' || v_produto.nome
  );

  -- Registrar consumo
  INSERT INTO consumos (
    produto_id, comprador_id, seller_id, quantidade,
    valor_unitario, valor_total, sucesso, response_time_ms
  ) VALUES (
    p_produto_id, p_comprador_id, v_produto.seller_id, p_quantidade,
    v_produto.preco_por_uso, v_valor_total, p_sucesso, p_response_time_ms
  ) RETURNING id INTO v_consumo_id;

  RETURN jsonb_build_object(
    'success', true,
    'consumo_id', v_consumo_id,
    'valor_cobrado', v_valor_total,
    'novo_saldo', v_novo_saldo_comprador
  );
END;
$$ LANGUAGE plpgsql;
