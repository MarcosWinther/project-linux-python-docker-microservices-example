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
