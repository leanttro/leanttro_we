-- ─────────────────────────────────────────────────────────
-- Gerenciador de Estoque/Custos/Vendas via WhatsApp
-- SAFE: Roda múltiplas vezes, nada é deletado
-- ─────────────────────────────────────────────────────────

-- Infra: conexão do bot
CREATE TABLE IF NOT EXISTS conexao_bot (
    id              SERIAL PRIMARY KEY,
    numero_atual    TEXT,
    status          TEXT DEFAULT 'desconectado',
    atualizado_em   TIMESTAMP DEFAULT NOW()
);

-- Insere valor inicial apenas se não existir
INSERT INTO conexao_bot (id, status)
VALUES (1, 'desconectado')
ON CONFLICT (id) DO NOTHING;

-- Log de troca de número
CREATE TABLE IF NOT EXISTS log_troca_numero (
    id              SERIAL PRIMARY KEY,
    numero_antigo   TEXT,
    numero_novo     TEXT NOT NULL,
    motivo          TEXT,
    criado_em       TIMESTAMP DEFAULT NOW()
);

-- Contas de clientes (multi-tenant)
CREATE TABLE IF NOT EXISTS clientes (
    id                  SERIAL PRIMARY KEY,
    nome_negocio        TEXT NOT NULL,
    email               TEXT UNIQUE NOT NULL,
    senha_hash          TEXT NOT NULL,
    plano               TEXT NOT NULL DEFAULT 'formulario',
    ativo               BOOLEAN DEFAULT TRUE,
    groq_key_override   TEXT,
    criado_em           TIMESTAMP DEFAULT NOW()
);

-- Números autorizados por cliente
CREATE TABLE IF NOT EXISTS numeros_autorizados (
    id          SERIAL PRIMARY KEY,
    cliente_id  INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    numero      TEXT NOT NULL,
    nome        TEXT,
    ativo       BOOLEAN DEFAULT TRUE,
    criado_em   TIMESTAMP DEFAULT NOW(),
    UNIQUE(numero)
);

-- Produtos (catálogo de cada cliente)
CREATE TABLE IF NOT EXISTS produtos (
    id              SERIAL PRIMARY KEY,
    cliente_id      INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    nome            TEXT NOT NULL,
    sku             TEXT,
    custo_unitario  NUMERIC(12,2) DEFAULT 0,
    preco_venda     NUMERIC(12,2) DEFAULT 0,
    estoque_atual   NUMERIC(12,3) DEFAULT 0,
    unidade         TEXT DEFAULT 'un',
    ativo           BOOLEAN DEFAULT TRUE,
    criado_em       TIMESTAMP DEFAULT NOW()
);

-- Sessões de conversa (stateful)
CREATE TABLE IF NOT EXISTS sessoes_conversa (
    id                      SERIAL PRIMARY KEY,
    numero_autorizado_id    INTEGER NOT NULL REFERENCES numeros_autorizados(id) ON DELETE CASCADE,
    etapa_atual             TEXT DEFAULT 'menu',
    dados_parciais          JSONB DEFAULT '{}',
    atualizado_em           TIMESTAMP DEFAULT NOW(),
    UNIQUE(numero_autorizado_id)
);

-- Movimentações de estoque
CREATE TABLE IF NOT EXISTS movimentacoes (
    id                      SERIAL PRIMARY KEY,
    cliente_id              INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    produto_id              INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    numero_autorizado_id    INTEGER REFERENCES numeros_autorizados(id),
    tipo                    TEXT NOT NULL,
    quantidade              NUMERIC(12,3) NOT NULL,
    valor_unitario          NUMERIC(12,2) DEFAULT 0,
    valor_total             NUMERIC(12,2) DEFAULT 0,
    origem                  TEXT DEFAULT 'manual_admin',
    mensagem_original       TEXT,
    criado_em               TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_mov_cliente ON movimentacoes(cliente_id);
CREATE INDEX IF NOT EXISTS idx_mov_produto ON movimentacoes(produto_id);
CREATE INDEX IF NOT EXISTS idx_produtos_cliente ON produtos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_numeros_cliente ON numeros_autorizados(cliente_id);
