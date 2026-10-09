# PAINEL FFHTB2 — publicação no GitHub

## 1. Criar o repositório

1. Entre em <https://github.com/new>.
2. Crie um repositório **público**, por exemplo `painel-ffhtb2`.
3. Não é necessário adicionar README, `.gitignore` ou licença pelo site, pois estes arquivos já estão no pacote.

## 2. Enviar os arquivos

Na pasta `SSH-PLUS-MANAGER-master`, abra um terminal e execute:

```bash
git init
git branch -M main
git add .
git commit -m "PAINEL FFHTB2"
git remote add origin https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
git push -u origin main
```

Substitua `SEU_USUARIO/SEU_REPOSITORIO` pelo seu usuário e nome real do repositório.

Se o GitHub pedir autenticação, use o login do GitHub ou um token pessoal; nunca coloque tokens dentro do script.

## 3. Ajustar o instalador

Abra `install.sh` e troque:

```bash
REPO="SEU_USUARIO/SEU_REPOSITORIO"
```

pelo seu repositório, por exemplo:

```bash
REPO="joao/painel-ffhtb2"
```

Depois envie a alteração:

```bash
git add install.sh
git commit -m "Configurar repositório do instalador"
git push
```

## 4. Link de instalação

Depois do `push`, o link será:

```text
https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/install.sh
```

Na VPS, execute:

```bash
wget -O /tmp/ffhtb2-install.sh https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/install.sh && chmod +x /tmp/ffhtb2-install.sh && sudo /tmp/ffhtb2-install.sh
```

Como root:

```bash
wget -O /tmp/ffhtb2-install.sh https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/install.sh && chmod +x /tmp/ffhtb2-install.sh && /tmp/ffhtb2-install.sh
```

Após instalar, o painel abre com:

```bash
menu
```

O gerenciador de portas fica disponível com:

```bash
gerenciarportas
```

> O repositório precisa estar público para que a VPS consiga baixar o arquivo sem token. Os diretórios internos `/etc/SSHPlus` foram mantidos de propósito, pois os módulos antigos dependem deles; a marca visível do painel foi alterada para **PAINEL FFHTB2**.
