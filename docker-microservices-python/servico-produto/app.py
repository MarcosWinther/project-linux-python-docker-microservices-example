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
