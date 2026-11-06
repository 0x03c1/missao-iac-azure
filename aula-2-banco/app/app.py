"""Mural de Transmissões: aplicação web mínima com SQLite.

Usa só a biblioteca padrão do Python (nenhum pip install).

Rodar no seu computador:   python app.py   (abre em http://localhost:8000)
Na Azure, o App Service roda: gunicorn --bind=0.0.0.0 --timeout 600 app:app

Rotas:
  GET  /               página do mural
  POST /               envia uma mensagem pelo formulário
  GET  /api/mensagens  mensagens em JSON
  POST /api/mensagens  envia uma mensagem em JSON {"apelido": "...", "texto": "..."}
  GET  /saude          estado da aplicação e do banco, em JSON
"""

import html
import json
import os
import sqlite3
from datetime import datetime, timezone
from urllib.parse import parse_qs

import config

PASTA = os.path.dirname(os.path.abspath(__file__))
INICIADO_EM = datetime.now(timezone.utc).isoformat(timespec="seconds")
TAMANHO_MAXIMO_DO_CORPO = 10_000


class MensagemInvalida(ValueError):
    """Mensagem que não segue as regras do mural."""


# ---------------------------------------------------------------- configuração


def caminho_do_banco():
    """Arquivo SQLite. Na Azure vem da variável CAMINHO_DO_BANCO (definida pelo Terraform)."""
    return os.environ.get("CAMINHO_DO_BANCO", os.path.join(PASTA, "mural.db"))


def versao():
    """Versão publicada. O pipeline da Aula 3 grava o commit no arquivo VERSAO."""
    try:
        with open(os.path.join(PASTA, "VERSAO"), encoding="utf-8") as arquivo:
            return arquivo.read().strip() or "terraform"
    except OSError:
        return "terraform"


def nome_do_mural():
    return os.environ.get("NOME_DO_MURAL", "Mural de Transmissões")


def cor_neon():
    cor = os.environ.get("COR_NEON", "#00f0ff")
    valida = len(cor) == 7 and cor.startswith("#") and all(c in "0123456789abcdefABCDEF" for c in cor[1:])
    return cor if valida else "#00f0ff"


# ---------------------------------------------------------------- banco de dados


def conectar():
    caminho = caminho_do_banco()
    os.makedirs(os.path.dirname(caminho) or ".", exist_ok=True)
    conexao = sqlite3.connect(caminho, timeout=10)
    conexao.row_factory = sqlite3.Row
    conexao.execute(
        "CREATE TABLE IF NOT EXISTS mensagens ("
        " id INTEGER PRIMARY KEY AUTOINCREMENT,"
        " apelido TEXT NOT NULL,"
        " texto TEXT NOT NULL,"
        " criada_em TEXT NOT NULL)"
    )
    return conexao


def validar_mensagem(apelido, texto):
    """Limpa espaços extras e aplica as regras. Devolve (apelido, texto)."""
    apelido = " ".join(str(apelido or "").split())[:30]
    texto = " ".join(str(texto or "").split())
    if not apelido:
        raise MensagemInvalida("Informe um apelido.")
    if not texto:
        raise MensagemInvalida("Escreva uma mensagem.")
    if len(texto) > config.LIMITE_DE_CARACTERES:
        raise MensagemInvalida(f"A mensagem passou de {config.LIMITE_DE_CARACTERES} caracteres.")
    return apelido, texto


def salvar_mensagem(apelido, texto):
    apelido, texto = validar_mensagem(apelido, texto)
    criada_em = datetime.now(timezone.utc).isoformat(timespec="seconds")
    with conectar() as conexao:
        cursor = conexao.execute(
            "INSERT INTO mensagens (apelido, texto, criada_em) VALUES (?, ?, ?)",
            (apelido, texto, criada_em),
        )
        novo_id = cursor.lastrowid
    return {"id": novo_id, "apelido": apelido, "texto": texto, "criada_em": criada_em}


def listar_mensagens(limite=None):
    limite = limite or config.QUANTIDADE_NO_MURAL
    with conectar() as conexao:
        linhas = conexao.execute(
            "SELECT id, apelido, texto, criada_em FROM mensagens ORDER BY id DESC LIMIT ?",
            (limite,),
        ).fetchall()
    return [dict(linha) for linha in linhas]


def contar_mensagens():
    with conectar() as conexao:
        return conexao.execute("SELECT COUNT(*) FROM mensagens").fetchone()[0]


def estado():
    """Resumo usado em /saude e no rodapé da página."""
    caminho = caminho_do_banco()
    return {
        "status": "ok",
        "total": contar_mensagens(),
        "banco": caminho,
        "persistente": os.environ.get("BANCO_PERSISTENTE", "local"),
        "iniciado_em": INICIADO_EM,
        "versao": versao(),
    }


# ---------------------------------------------------------------- páginas


def pagina_do_mural(erro=""):
    e = html.escape
    info = estado()
    itens = "".join(
        f'<li><span class="quem">{e(m["apelido"])}</span>'
        f'<span class="quando">{e(m["criada_em"].replace("T", " ")[:16])} UTC</span>'
        f'<p>{e(m["texto"])}</p></li>'
        for m in listar_mensagens()
    ) or '<li class="vazio">Nenhuma transmissão ainda. Seja a primeira pessoa!</li>'
    aviso_de_erro = f'<p class="erro">{e(erro)}</p>' if erro else ""
    persistente = {"sim": "SIM (/home)", "nao": "NÃO (/tmp)"}.get(info["persistente"], "LOCAL")
    return MODELO_DA_PAGINA.format(
        nome=e(nome_do_mural()),
        neon=cor_neon(),
        boas_vindas=e(config.MENSAGEM_DE_BOAS_VINDAS),
        limite=config.LIMITE_DE_CARACTERES,
        erro=aviso_de_erro,
        itens=itens,
        total=info["total"],
        persistente=e(persistente),
        iniciado=e(info["iniciado_em"].replace("T", " ")[:19]),
        versao=e(info["versao"]),
    )


MODELO_DA_PAGINA = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{nome}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@600;900&family=Share+Tech+Mono&display=swap" rel="stylesheet">
<style>
  :root {{ --neon: {neon}; --amarelo: #fcee0a; --rosa: #ff2a6d; --texto: #e6e6f0; }}
  * {{ box-sizing: border-box; }}
  html, body {{ margin: 0; min-height: 100vh; }}
  body {{
    color: var(--texto); padding: 24px 16px 48px;
    font-family: "Share Tech Mono", ui-monospace, Menlo, Consolas, monospace;
    background:
      linear-gradient(rgba(0, 240, 255, .06) 1px, transparent 1px) 0 0 / 44px 44px,
      linear-gradient(90deg, rgba(0, 240, 255, .06) 1px, transparent 1px) 0 0 / 44px 44px,
      radial-gradient(ellipse at 50% -10%, #12233f 0%, #06060c 65%);
  }}
  body::after {{
    content: ""; position: fixed; inset: 0; pointer-events: none;
    background: repeating-linear-gradient(0deg, rgba(0, 0, 0, .25) 0 1px, transparent 1px 3px);
  }}
  main {{ max-width: 760px; margin: 0 auto; }}
  .barra {{
    display: flex; justify-content: space-between; flex-wrap: wrap; gap: 8px;
    font-size: 12px; letter-spacing: .16em; text-transform: uppercase; color: var(--neon);
    border-bottom: 1px dashed currentColor; padding-bottom: 10px;
  }}
  h1 {{
    margin: 22px 0 6px; color: var(--neon); font-family: Orbitron, sans-serif; font-weight: 900;
    font-size: clamp(26px, 6vw, 44px); text-transform: uppercase; letter-spacing: .04em;
    text-shadow: 0 0 14px var(--neon), 3px 0 var(--rosa);
  }}
  .sub {{ margin: 0 0 22px; color: var(--amarelo); }}
  form {{
    display: grid; gap: 10px; padding: 16px; margin-bottom: 26px;
    border: 1px solid var(--neon); background: rgba(8, 8, 18, .85);
    box-shadow: 0 0 22px color-mix(in srgb, var(--neon) 30%, transparent);
  }}
  label {{ font-size: 12px; letter-spacing: .14em; text-transform: uppercase; color: rgba(230, 230, 240, .7); }}
  input, textarea {{
    width: 100%; padding: 10px 12px; font: inherit; color: var(--texto);
    background: #000; border: 1px solid rgba(0, 240, 255, .35); outline: none;
  }}
  input:focus, textarea:focus {{ border-color: var(--neon); box-shadow: 0 0 10px var(--neon); }}
  button {{
    justify-self: start; padding: 10px 22px; font: inherit; font-weight: bold; letter-spacing: .14em;
    text-transform: uppercase; color: #000; background: var(--amarelo); border: 0; cursor: pointer;
    clip-path: polygon(0 0, 100% 0, 100% 65%, calc(100% - 12px) 100%, 0 100%);
  }}
  .erro {{ margin: 0; padding: 8px 12px; color: #000; background: var(--rosa); }}
  ul {{ list-style: none; margin: 0; padding: 0; display: grid; gap: 10px; }}
  li {{
    padding: 12px 14px; background: rgba(0, 240, 255, .05); border-left: 3px solid var(--neon);
    clip-path: polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%);
  }}
  li p {{ margin: 6px 0 0; font-size: 17px; word-wrap: break-word; }}
  .quem {{ color: var(--amarelo); margin-right: 10px; }}
  .quando {{ font-size: 12px; color: rgba(230, 230, 240, .5); }}
  .vazio {{ color: rgba(230, 230, 240, .6); }}
  footer {{
    margin-top: 26px; display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px;
    font-size: 12px; letter-spacing: .1em; text-transform: uppercase;
  }}
  footer div {{ padding: 10px 12px; border: 1px solid rgba(0, 240, 255, .25); }}
  footer small {{ display: block; color: rgba(230, 230, 240, .5); }}
  footer strong {{ color: var(--neon); }}
</style>
</head>
<body>
<main>
  <div class="barra"><span>Rede // Mural de dados</span><span>Banco: SQLite</span></div>
  <h1>{nome}</h1>
  <p class="sub">&gt; {boas_vindas}</p>
  <form method="post" action="/">
    {erro}
    <label for="apelido">Apelido</label>
    <input id="apelido" name="apelido" maxlength="30" required autocomplete="off">
    <label for="texto">Mensagem (até {limite} caracteres)</label>
    <textarea id="texto" name="texto" rows="3" maxlength="{limite}" required></textarea>
    <button type="submit">Transmitir</button>
  </form>
  <ul>{itens}</ul>
  <footer>
    <div><small>Mensagens no banco</small><strong>{total}</strong></div>
    <div><small>Banco persistente</small><strong>{persistente}</strong></div>
    <div><small>Servidor ligado em</small><strong>{iniciado} UTC</strong></div>
    <div><small>Versão</small><strong>{versao}</strong></div>
  </footer>
</main>
</body>
</html>
"""


# ---------------------------------------------------------------- servidor WSGI


def ler_corpo(environ):
    try:
        tamanho = int(environ.get("CONTENT_LENGTH") or 0)
    except ValueError:
        tamanho = 0
    tamanho = max(0, min(tamanho, TAMANHO_MAXIMO_DO_CORPO))
    return environ["wsgi.input"].read(tamanho).decode("utf-8", errors="replace")


def responder(start_response, status, corpo, tipo="text/html; charset=utf-8", extras=None):
    dados = corpo.encode("utf-8")
    cabecalhos = [("Content-Type", tipo), ("Content-Length", str(len(dados)))]
    cabecalhos += extras or []
    start_response(status, cabecalhos)
    return [dados]


def responder_json(start_response, status, objeto):
    return responder(start_response, status, json.dumps(objeto, ensure_ascii=False), "application/json; charset=utf-8")


def app(environ, start_response):
    metodo = environ.get("REQUEST_METHOD", "GET")
    rota = environ.get("PATH_INFO", "/") or "/"

    if rota == "/" and metodo == "GET":
        return responder(start_response, "200 OK", pagina_do_mural())

    if rota == "/" and metodo == "POST":
        campos = parse_qs(ler_corpo(environ))
        try:
            salvar_mensagem(campos.get("apelido", [""])[0], campos.get("texto", [""])[0])
        except MensagemInvalida as problema:
            return responder(start_response, "400 Bad Request", pagina_do_mural(erro=str(problema)))
        return responder(start_response, "303 See Other", "", extras=[("Location", "/")])

    if rota == "/api/mensagens" and metodo == "GET":
        return responder_json(start_response, "200 OK", {"total": contar_mensagens(), "mensagens": listar_mensagens()})

    if rota == "/api/mensagens" and metodo == "POST":
        try:
            dados = json.loads(ler_corpo(environ) or "{}")
            mensagem = salvar_mensagem(dados.get("apelido"), dados.get("texto"))
        except (MensagemInvalida, ValueError, AttributeError) as problema:
            return responder_json(start_response, "400 Bad Request", {"erro": str(problema)})
        return responder_json(start_response, "201 Created", mensagem)

    if rota == "/saude" and metodo == "GET":
        return responder_json(start_response, "200 OK", estado())

    return responder_json(start_response, "404 Not Found", {"erro": "rota não encontrada"})


if __name__ == "__main__":
    from wsgiref.simple_server import make_server

    porta = int(os.environ.get("PORT", "8000"))
    print(f"Mural no ar em http://localhost:{porta}  (Ctrl+C para parar)")
    make_server("", porta, app).serve_forever()
