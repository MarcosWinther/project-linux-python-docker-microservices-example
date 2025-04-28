#!/bin/bash

# Nome do diretório principal do projeto
PROJECT_DIR="docker-microservices-python"

# Verifica se o diretório já existe para evitar sobrescrever
if [ -d "$PROJECT_DIR" ]; then
  echo "ERRO: O diretório '$PROJECT_DIR' já existe. Remova-o ou escolha outro local."
  exit 1
fi

echo "--- Iniciando criação do projeto Docker Microsserviços ---"

# --- 1. Criar Estrutura Base ---
echo "Criando diretório principal: $PROJECT_DIR"
mkdir "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit # Entra no diretório ou sai se falhar

echo "Criando subdiretórios: servico-produto e servico-pedido"
mkdir servico-produto
mkdir servico-pedido

# --- 2. Criar docker-compose.yml ---
echo "Criando docker-compose.yml..."
cat << EOF > docker-compose.yml
version: '3.8' # Use uma versão apropriada do Compose

services:
  servico-produto:
    build: ./servico-produto # Diretório onde está o Dockerfile do serviço
    container_name: container-produto # Nome do container (opcional)
    ports:
      - "5001:5001" # Mapeia porta 5001 do host para 5001 do container
    volumes:
      # Mapeia o arquivo JSON local para dentro do container.
      # Isso permite persistência e visualização das alterações.
      - ./servico-produto/products.json:/app/products.json
    networks:
      - microservices-net # Adiciona o serviço a uma rede customizada

  servico-pedido:
    build: ./servico-pedido
    container_name: container-pedido
    ports:
      - "5002:5002"
    environment:
      # Passa a URL do serviço de produto como variável de ambiente
      # O Docker Compose resolve 'servico-produto' para o IP correto na rede
      - PRODUTO_SERVICE_URL=http://servico-produto:5001
    depends_on:
      - servico-produto # Garante que o serviço de produto inicie antes (mas não que esteja pronto)
    networks:
      - microservices-net

networks:
  microservices-net: # Define a rede customizada
    driver: bridge # Rede padrão do tipo bridge gerenciada pelo Docker
EOF

# --- 3. Criar arquivos do servico-produto ---
echo "Configurando servico-produto..."
cd servico-produto || exit

# products.json
echo "Criando products.json..."
cat << EOF > products.json
[
  {"id": 1, "nome": "Teclado Gamer", "preco": 150.75},
  {"id": 2, "nome": "Monitor Ultrawide", "preco": 1250.00}
]
EOF

# requirements.txt
echo "Criando requirements.txt..."
cat << EOF > requirements.txt
Flask==2.3.3
EOF

# app.py
echo "Criando app.py..."
cat << EOF > app.py
import json
import os
from flask import Flask, request, jsonify

app = Flask(__name__)
PRODUCTS_FILE = "products.json"

def load_products():
    """Carrega produtos do arquivo JSON."""
    if not os.path.exists(PRODUCTS_FILE):
        return []
    try:
        with open(PRODUCTS_FILE, 'r') as f:
            return json.load(f)
    except (IOError, json.JSONDecodeError):
        return []

def save_products(products):
    """Salva produtos no arquivo JSON."""
    try:
        with open(PRODUCTS_FILE, 'w') as f:
            json.dump(products, f, indent=2)
    except IOError:
        print(f"Erro: Não foi possível salvar em {PRODUCTS_FILE}")


@app.route('/produtos', methods=['GET'])
def get_products():
    """Retorna a lista de todos os produtos."""
    products = load_products()
    return jsonify(products)

@app.route('/produtos/<int:product_id>', methods=['GET'])
def get_product(product_id):
    """Retorna um produto específico pelo ID."""
    products = load_products()
    product = next((p for p in products if p['id'] == product_id), None)
    if product:
        return jsonify(product)
    else:
        return jsonify({"erro": "Produto não encontrado"}), 404

@app.route('/produtos', methods=['POST'])
def add_product():
    """Adiciona um novo produto."""
    if not request.is_json:
        return jsonify({"erro": "Request deve ser JSON"}), 400

    data = request.get_json()
    if not data or 'nome' not in data or 'preco' not in data:
        return jsonify({"erro": "Dados incompletos (requer 'nome' e 'preco')"}), 400

    products = load_products()
    new_id = max([p['id'] for p in products] + [0]) + 1 # Gera novo ID simples
    new_product = {
        "id": new_id,
        "nome": data['nome'],
        "preco": data['preco']
    }
    products.append(new_product)
    save_products(products)
    return jsonify(new_product), 201

if __name__ == '__main__':
    # Garante que o arquivo existe ao iniciar (se não existir)
    if not os.path.exists(PRODUCTS_FILE):
        save_products([])
    # Executa na rede interna do Docker, acessível por outros containers
    app.run(host='0.0.0.0', port=5001, debug=True)
EOF

# Dockerfile
echo "Criando Dockerfile..."
cat << EOF > Dockerfile
# Usar uma imagem base oficial do Python
FROM python:3.9-slim

# Definir o diretório de trabalho no container
WORKDIR /app

# Copiar o arquivo de dependências
COPY requirements.txt requirements.txt

# Instalar as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o restante do código da aplicação para o diretório de trabalho
COPY . .

# Expor a porta que o Flask vai usar
EXPOSE 5001

# Comando para rodar a aplicação quando o container iniciar
CMD ["python", "app.py"]
EOF

# Voltar para o diretório principal
cd ..

# --- 4. Criar arquivos do servico-pedido ---
echo "Configurando servico-pedido..."
cd servico-pedido || exit

# requirements.txt
echo "Criando requirements.txt..."
cat << EOF > requirements.txt
Flask==2.3.3
requests==2.31.0
EOF

# app.py
echo "Criando app.py..."
cat << EOF > app.py
import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

# O nome 'servico-produto' será resolvido pelo Docker Compose para o IP do container correto
PRODUTO_SERVICE_URL = os.environ.get("PRODUTO_SERVICE_URL", "http://servico-produto:5001")

@app.route('/pedidos', methods=['POST'])
def create_order():
    """Cria um novo pedido (simulado)."""
    if not request.is_json:
        return jsonify({"erro": "Request deve ser JSON"}), 400

    data = request.get_json()
    if not data or 'produto_id' not in data:
        return jsonify({"erro": "Dados incompletos (requer 'produto_id')"}), 400

    produto_id = data['produto_id']

    # --- Comunicação entre Microsserviços ---
    try:
        # Tenta buscar o produto no servico-produto
        response = requests.get(f"{PRODUTO_SERVICE_URL}/produtos/{produto_id}")

        if response.status_code == 200:
            produto_data = response.json()
            # Simulação: Se o produto existe, o pedido é "aceito"
            print(f"INFO: Produto {produto_id} encontrado: {produto_data['nome']}")
            return jsonify({
                "mensagem": "Pedido recebido com sucesso!",
                "produto_id": produto_id,
                "nome_produto": produto_data.get('nome', 'N/A') # Pega o nome do produto retornado
            }), 201
        elif response.status_code == 404:
            print(f"WARN: Produto {produto_id} não encontrado no serviço de produtos.")
            return jsonify({"erro": f"Produto com ID {produto_id} não encontrado"}), 404
        else:
            # Outro erro no serviço de produto
            print(f"ERRO: Serviço de produtos retornou status {response.status_code}")
            return jsonify({"erro": "Erro ao verificar produto"}), 500

    except requests.exceptions.ConnectionError:
        print(f"ERRO: Não foi possível conectar ao serviço de produtos em {PRODUTO_SERVICE_URL}")
        return jsonify({"erro": "Serviço de produtos indisponível"}), 503
    except Exception as e:
        print(f"ERRO inesperado: {e}")
        return jsonify({"erro": "Erro interno no servidor de pedidos"}), 500
    # --- Fim da Comunicação ---

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)
EOF

# Dockerfile
echo "Criando Dockerfile..."
cat << EOF > Dockerfile
# Usar uma imagem base oficial do Python
FROM python:3.9-slim

# Definir o diretório de trabalho no container
WORKDIR /app

# Copiar o arquivo de dependências
COPY requirements.txt requirements.txt

# Instalar as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o restante do código da aplicação para o diretório de trabalho
COPY . .

# Expor a porta que o Flask vai usar
EXPOSE 5002

# Comando para rodar a aplicação quando o container iniciar
CMD ["python", "app.py"]
EOF

# Voltar para o diretório principal
cd ..

# --- 5. Finalização ---
echo ""
echo "--- Estrutura do projeto '$PROJECT_DIR' criada com sucesso! ---"
echo "Localização: $(pwd)"
echo ""
echo "Próximos passos:"
echo "1. Navegue até o diretório do projeto:"
echo "   cd $PROJECT_DIR"
echo "2. Execute os containers com Docker Compose:"
echo "   docker-compose up --build -d"
echo "3. Teste as APIs usando curl ou outra ferramenta (veja o tutorial para exemplos)."
echo "4. Para parar e remover os containers:"
echo "   docker-compose down"
echo ""

exit 0
