# 🚀 Project Linux: Docker Microservices Adventure 🐳

<!-- Badges -->
<p align="center">
  <img src="https://img.shields.io/badge/Language-Python-blue?logo=python&logoColor=yellow" alt="Language Python">
  <img src="https://img.shields.io/badge/Framework-Flask-lightgrey?logo=flask" alt="Framework Flask">
  <img src="https://img.shields.io/badge/Tool-Docker-blue?logo=docker" alt="Tool Docker">
  <img src="https://img.shields.io/badge/Tool-Docker%20Compose-orange?logo=docker" alt="Tool Docker Compose">
  <img src="https://img.shields.io/badge/OS-Linux-yellow?logo=linux" alt="OS Linux">
  <img src="https://img.shields.io/badge/Database-JSON-lightgrey" alt="Database JSON">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT"> <!-- Ou outra licença se preferir -->
  <img src="https://img.shields.io/badge/Type-Demo%20Project-informational" alt="Demo Project">
</p>

Bem-vindo(a) a uma demonstração prática de **Microsserviços com Docker** rodando no bom e velho terminal Linux! 🐧💻

Este projeto simples foi criado para ilustrar como containerizar aplicações Python (Flask) e orquestrá-las usando Docker Compose, simulando um cenário básico de microsserviços.

<br>

## ✨ O Desafio

Imagine um e-commerce bem simples:
1.  Um serviço para gerenciar nosso catálogo de produtos (listar, adicionar). 📦
2.  Um serviço para receber pedidos, que precisa verificar se o produto existe antes de confirmar. 🛒

Como fazer esses serviços conversarem de forma isolada e escalável? **Docker ao resgate!**

<br>


## 🛠️ Ferramentas e Ambiente

Este projeto foi construído e testado usando:

*   **Sistema Operacional:** Linux Ubuntu Server 22.04 LTS 🐧
*   **Containerização:** Docker & Docker Compose 🐳
*   **Linguagem:** Python 3.9+ 🐍
*   **Framework Web:** Flask ✨ (para criar as APIs RESTful)
*   **"Banco de Dados":** Um simples arquivo `products.json` 📄 (para manter as coisas focadas no Docker!)
*   **Cliente de Teste:** `curl` no terminal (ou seu cliente de API preferido como Postman/Insomnia) ⚙️

<br>


## 🏗️ Estrutura do Projeto

```
project-linux-docker-microservices/
├── 📄 .gitignore             # Arquivos que o Git deve ignorar (adeus, __pycache__!)
├── 🐳 docker-compose.yml    # O maestro! Define e orquestra os serviços.
├── 📦 servico-produto/
│   ├── 🐍 app.py           # API Flask: Lista/adiciona produtos.
│   ├── 🐳 Dockerfile       # Receita para construir a imagem Docker deste serviço.
│   ├── 📄 products.json   # Nosso "banco de dados" de produtos.
│   └── requirements.txt  # Dependências Python (Flask).
└── 🛒 servico-pedido/
    ├── 🐍 app.py           # API Flask: Cria pedidos (e consulta o serviço de produto!).
    ├── 🐳 Dockerfile       # Receita para construir a imagem Docker deste serviço.
    └── requirements.txt  # Dependências Python (Flask, Requests).
```

*   **`servico-produto`**: Expõe endpoints na porta `5001` para gerenciar produtos.
*   **`servico-pedido`**: Expõe endpoints na porta `5002` para criar pedidos. Ele faz uma chamada HTTP interna (graças à rede do Docker Compose) para o `servico-produto` para validar o ID do produto.

> **Nota sobre a Criação:** 📝 Toda a estrutura de diretórios e arquivos listada acima foi gerada inicialmente através da execução de um único script bash (`criar_projeto_docker.sh`). Esse script automatizou a criação dos arquivos `.py`, `Dockerfile`, `requirements.txt`, `products.json` e `docker-compose.yml` com seus respectivos conteúdos. Este script foi usado *apenas* para a montagem inicial do projeto. Para rodar o projeto a partir deste repositório clonado, siga os passos da seção 'Como Executar' - **não é necessário executar o script `criar_projeto_docker.sh` novamente.**

<br>


## ▶️ Como Executar (A Mágica do Docker Compose!)

1.  **Pré-requisitos:**
    *   Você precisará do `git` para clonar o repositório.
    *   Você precisa ter o `Docker` e o `Docker Compose` instalados na sua máquina (preferencialmente Linux/Ubuntu 22.04, onde foi testado).

    <details>
    <summary>🐧⚙️ Clique aqui para ver os comandos de instalação do Docker CE e Docker Compose no Ubuntu 22.04 (Focal/Jammy)</summary>

    Estes foram os passos seguidos para instalar o Docker Engine (CE - Community Edition) no Ubuntu 22.04. Para outras distribuições, consulte a [documentação oficial do Docker](https://docs.docker.com/engine/install/).

    ```bash
    # 1. Atualizar lista de pacotes
    sudo apt update

    # 2. Instalar pacotes necessários para adicionar repositórios HTTPS
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

    # 3. Criar diretório para chaves GPG (se não existir)
    sudo mkdir -p /etc/apt/keyrings

    # 4. Baixar a chave GPG oficial do Docker e salvar
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

    # 5. Adicionar o repositório oficial do Docker ao APT sources
    # (Nota: O comando detecta a arquitetura e a versão do Ubuntu automaticamente)
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # (Alternativa manual para Focal/Jammy se o comando acima falhar)
    # sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # 6. Atualizar lista de pacotes novamente após adicionar o repo Docker
    sudo apt update

    # 7. (Opcional) Verificar se o repo Docker foi adicionado corretamente
    # apt-cache policy docker-ce

    # 8. Instalar o Docker Engine (CE) e o plugin do Compose V2
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    
    # Ou, se preferir instalar o docker-compose standalone (versão V1, mais antiga mas comum):
    # sudo apt install docker-compose -y

    # 9. Verificar se o Docker está rodando
    sudo systemctl status docker

    # 10. (Opcional, mas recomendado) Adicionar seu usuário ao grupo docker para rodar comandos sem 'sudo'
    # É necessário fazer logout e login novamente para a mudança ter efeito!
    sudo usermod -aG docker ${USER}
    echo "Lembre-se de fazer logout e login para usar docker sem sudo!"
    ```

    </details>

2.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/MarcosWinther/project-linux-python-docker-microservices-example
    cd project-linux-docker-microservices 
    ```
3.  **Construa e Inicie os Containers:** O Docker Compose faz todo o trabalho pesado!
    ```bash
    docker-compose up --build -d
    ```
    *   `--build`: Garante que as imagens Docker sejam construídas (ou reconstruídas se houver mudanças).
    *   `-d`: Roda os containers em background (modo detached).

4.  **Verifique se tudo está rodando:**
    ```bash
    docker ps
    ```
    Você deve ver dois containers: `container-produto` e `container-pedido`. ✅

<br>


## 🧪 Testando as APIs (com `curl`)

Abra outro terminal ou use o mesmo.

*   **Listar Produtos:**
    ```bash
    curl http://localhost:5001/produtos
    ```

*   **Adicionar um Produto Novo:**
    ```bash
    curl -X POST http://localhost:5001/produtos \
         -H "Content-Type: application/json" \
         -d '{"nome": "Mouse Gamer", "preco": 89.90}'
    ```

*   **Criar um Pedido Válido (Produto ID 1):**
    ```bash
    curl -X POST http://localhost:5002/pedidos \
         -H "Content-Type: application/json" \
         -d '{"produto_id": 1}'
    ```

*   **Tentar Criar um Pedido Inválido (Produto ID 99):**
    ```bash
    curl -X POST http://localhost:5002/pedidos \
         -H "Content-Type: application/json" \
         -d '{"produto_id": 99}'
    ```

<br>


## 🧹 Parando Tudo

Quando cansar de brincar (ou precisar liberar recursos 😉):

```bash
docker-compose down
```
Este comando para e remove os containers e a rede criada.

<br>


## 🙏 Agradecimentos e Contexto

Este projeto foi desenvolvido como parte do curso **"Docker: Utilização Prática no Cenário de Microsserviços"** ministrado pelo incrível professor **[Denilson Bonatti](https://www.linkedin.com/in/denilsonbonatti/)👨‍🏫** na plataforma **[DIO (Digital Innovation One)](https://dio.me/)🌐**.

O objetivo é solidificar os conhecimentos sobre Docker aplicado a um cenário comum no desenvolvimento de software moderno.

<br>


## 👨‍💻 Expert

<p>
    <img 
      align=left 
      margin=10 
      width=80 
      src="https://avatars.githubusercontent.com/u/44624583?v=4"
    />
    <p>&nbsp&nbsp&nbspMarcos Winther<br>
    &nbsp&nbsp&nbsp
    <a href="https://github.com/MarcosWinther">
    GitHub</a>&nbsp;|&nbsp;
    <a href="https://www.linkedin.com/in/marcoswinthersilva/">LinkedIn</a>
    </p>
</p>
<br/><br/>

---

⌨️ com 💜 por [Marcos Winther](https://github.com/MarcosWinther)
