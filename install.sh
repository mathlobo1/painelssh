#!/bin/bash
set -Eeuo pipefail

# Antes de publicar, troque pelos dados do seu repositório.
REPO="${mathlobo1/painelssh}"
BRANCH="${FFHTB2_BRANCH:-main}"
BASE_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
DEST="/tmp/ffhtb2-install"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Execute como root: sudo bash install.sh"
    exit 1
fi
if [[ "$REPO" == "SEU_USUARIO/SEU_REPOSITORIO" ]]; then
    echo "Edite install.sh e altere REPO para usuario/repositorio antes de publicar."
    exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
    apt-get update -y && apt-get install -y tar
fi
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD="curl -fL --progress-bar"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget -q --show-progress -O"
else
    apt-get update -y && apt-get install -y curl
    DOWNLOAD="curl -fL --progress-bar"
fi

rm -rf "$DEST"
mkdir -p "$DEST"
echo "Baixando PAINEL FFHTB2 de $REPO ($BRANCH)..."
if [[ "$DOWNLOAD" == "curl"* ]]; then
    $DOWNLOAD "$BASE_URL" -o "$DEST/source.tar.gz"
else
    $DOWNLOAD "$DEST/source.tar.gz" "$BASE_URL"
fi
tar -xzf "$DEST/source.tar.gz" -C "$DEST"
PROJECT="$(find "$DEST" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[[ -d "$PROJECT/Modulos" ]] || { echo "Repositório inválido: Modulos não encontrado."; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true
apt-get install -y bash coreutils procps iproute2 net-tools python3 screen openssh-server >/dev/null 2>&1 || true

mkdir -p /bin /etc/SSHPlus/{senha,userteste,.tmp} /etc/bot/{info-users,arquivos,revenda,suspensos} /var/log/sshplus
VPS_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[[ -z "$VPS_IP" ]] && VPS_IP="127.0.0.1"
printf '%s\n' "$VPS_IP" > /etc/IP
printf '%s\n' 'by: PAINEL FFHTB2' > /usr/lib/sshplus
printf '%s\n' 'by: PAINEL FFHTB2' > /etc/SSHPlus/.tmp/crazy
touch /etc/SSHPlus/Exp /etc/bot/lista_ativos /etc/bot/lista_suspensos /etc/SSHPlus/usuarios.db
[[ -f /root/usuarios.db ]] || awk -F: '$3 >= 500 {print $1 " 1"}' /etc/passwd | grep -v '^nobody' > /root/usuarios.db || true

while IFS= read -r -d '' module; do
    name="$(basename "$module")"
    case "$name" in
        open.py|proxy.py|cabecalho|bot) install -m 0755 "$module" "/etc/SSHPlus/$name" ;;
        *) install -m 0755 "$module" "/bin/$name" ;;
    esac
done < <(find "$PROJECT/Modulos" -maxdepth 1 -type f -print0)

install -m 0755 "$PROJECT/Modulos/menu" /bin/menu
install -m 0755 "$PROJECT/Modulos/gerenciarportas" /bin/gerenciarportas
install -m 0755 "$PROJECT/Modulos/proxy.py" /etc/SSHPlus/proxy.py
install -m 0755 "$PROJECT/Modulos/open.py" /etc/SSHPlus/open.py
printf '#!/bin/bash\n# Inicialização do PAINEL FFHTB2\n' > /etc/autostart
chmod 0755 /etc/autostart
printf '%s\n' "PAINEL FFHTB2 instalado em $(date '+%Y-%m-%d %H:%M:%S')" > /home/sshplus

echo "PAINEL FFHTB2 instalado. Comando do painel: menu"
if [[ -t 0 && -t 1 ]]; then exec /bin/menu; fi
