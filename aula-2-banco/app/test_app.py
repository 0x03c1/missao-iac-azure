"""Testes automáticos do mural. O pipeline da Aula 3 roda estes testes antes de publicar.

Rodar no seu computador:  python -m unittest -v
"""

import io
import json
import os
import tempfile
import unittest

import app
import config


def chamar(metodo, rota, corpo="", tipo="application/x-www-form-urlencoded"):
    """Faz uma requisição direto na aplicação, sem servidor."""
    dados = corpo.encode("utf-8")
    environ = {
        "REQUEST_METHOD": metodo,
        "PATH_INFO": rota,
        "CONTENT_LENGTH": str(len(dados)),
        "CONTENT_TYPE": tipo,
        "wsgi.input": io.BytesIO(dados),
    }
    resposta = {}

    def start_response(status, cabecalhos):
        resposta["status"] = status
        resposta["cabecalhos"] = dict(cabecalhos)

    corpo_resposta = b"".join(app.app(environ, start_response)).decode("utf-8")
    return resposta["status"], resposta["cabecalhos"], corpo_resposta


class TestesDasRegras(unittest.TestCase):
    def test_limite_de_caracteres_e_valido(self):
        self.assertGreaterEqual(config.LIMITE_DE_CARACTERES, 1, "O limite precisa ser pelo menos 1.")
        self.assertLessEqual(config.LIMITE_DE_CARACTERES, 280, "O limite pode ser no máximo 280.")

    def test_boas_vindas_nao_esta_vazia(self):
        self.assertTrue(config.MENSAGEM_DE_BOAS_VINDAS.strip(), "A mensagem de boas-vindas não pode ficar vazia.")

    def test_validar_limpa_espacos(self):
        self.assertEqual(app.validar_mensagem("  Ana  ", " oi   rede "), ("Ana", "oi rede"))

    def test_validar_recusa_vazio(self):
        with self.assertRaises(app.MensagemInvalida):
            app.validar_mensagem("", "oi")
        with self.assertRaises(app.MensagemInvalida):
            app.validar_mensagem("Ana", "   ")

    def test_validar_recusa_mensagem_longa(self):
        with self.assertRaises(app.MensagemInvalida):
            app.validar_mensagem("Ana", "x" * (config.LIMITE_DE_CARACTERES + 1))


class TestesDoBanco(unittest.TestCase):
    def setUp(self):
        self.pasta = tempfile.TemporaryDirectory()
        os.environ["CAMINHO_DO_BANCO"] = os.path.join(self.pasta.name, "dados", "teste.db")

    def tearDown(self):
        os.environ.pop("CAMINHO_DO_BANCO", None)
        self.pasta.cleanup()

    def test_mensagem_fica_gravada(self):
        app.salvar_mensagem("Ana", "primeira transmissão")
        app.salvar_mensagem("Leo", "segunda transmissão")
        self.assertEqual(app.contar_mensagens(), 2)
        self.assertEqual(app.listar_mensagens()[0]["texto"], "segunda transmissão")

    def test_pagina_abre(self):
        status, _, corpo = chamar("GET", "/")
        self.assertEqual(status, "200 OK")
        self.assertIn("Transmitir", corpo)

    def test_formulario_grava_e_redireciona(self):
        status, cabecalhos, _ = chamar("POST", "/", "apelido=Ana&texto=ola+rede")
        self.assertEqual(status, "303 See Other")
        self.assertEqual(cabecalhos["Location"], "/")
        self.assertEqual(app.contar_mensagens(), 1)

    def test_html_e_escapado(self):
        chamar("POST", "/", "apelido=Hacker&texto=%3Cscript%3Ealert(1)%3C%2Fscript%3E")
        _, _, corpo = chamar("GET", "/")
        self.assertNotIn("<script>alert(1)</script>", corpo)
        self.assertIn("&lt;script&gt;", corpo)

    def test_api_json(self):
        status, _, corpo = chamar("POST", "/api/mensagens", json.dumps({"apelido": "Ana", "texto": "via API"}), "application/json")
        self.assertEqual(status, "201 Created")
        status, _, corpo = chamar("GET", "/api/mensagens")
        self.assertEqual(json.loads(corpo)["total"], 1)

    def test_saude(self):
        status, _, corpo = chamar("GET", "/saude")
        dados = json.loads(corpo)
        self.assertEqual(status, "200 OK")
        self.assertEqual(dados["status"], "ok")
        self.assertIn("versao", dados)

    def test_rota_inexistente(self):
        status, _, _ = chamar("GET", "/nao-existe")
        self.assertEqual(status, "404 Not Found")


if __name__ == "__main__":
    unittest.main()
