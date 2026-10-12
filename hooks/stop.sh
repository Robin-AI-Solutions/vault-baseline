cd "$OPENHANDS_PROJECT_DIR" || exit 0

hint=$(cat <<'EOF'
Lee la configuración con la librería vault_config. No uses os.environ, os.getenv ni archivos .env (salvo .env.example). No leas VAULT_* en el código de la app y no crees vault_config.py.

Instalación, en requirements.txt:
Robin-AI-Solutions-vault-config @ git+https://github.com/Robin-AI-Solutions/vault-config@v0.1.0

Uso:
from vault_config import get, get_bool, get_int

DB_HOST = get("DB_HOST")
DEBUG = get_bool("DEBUG")
PORT = get_int("PORT")
OTRO = get("API_KEY", secret_name="otro-secreto")

- get(key, secret_name=None) devuelve el campo como texto. Sin secret_name usa VAULT_SECRET_NAME.
- get_bool y get_int convierten el valor. El texto "false" es verdadero en Python, por eso existe get_bool.
- reload() descarta la caché y el token; la próxima lectura vuelve a Vault.
- Si falta un puntero o una clave, deja salir VaultConfigError. El mensaje nombra lo que falta y no incluye valores ni el token. No inventes un valor por defecto.

Punteros que inyecta la plataforma (la app no los lee): VAULT_ADDR, VAULT_SECRET_NAME, VAULT_ROLE y VAULT_KV_MOUNT (opcional, default secret).
EOF
)

reason='Línea base Vault incumplida. Lee cada variable con vault_config (get, get_bool, get_int), no con os.environ ni .env.'

deny() {
  extra=$1
  ctx=$hint
  if [ -n "$extra" ]; then
    ctx="$hint

Diagnóstico:
$extra"
  fi
  jq -n --arg reason "$reason" --arg ctx "$ctx" \
    '{decision:"deny", reason:$reason, additionalContext:$ctx}'
  exit 2
}

command -v jq >/dev/null || {
  printf '%s\n' '{"decision":"deny","reason":"Falta jq en la imagen. Lee la config con vault_config (get, get_bool, get_int), no con os.environ ni .env.","additionalContext":"Instala Robin-AI-Solutions-vault-config desde git+https://github.com/Robin-AI-Solutions/vault-config@v0.1.0 y usa get, get_bool y get_int. No uses os.environ, os.getenv ni .env."}'
  exit 2
}

command -v ruff >/dev/null || deny "Falta ruff en la imagen."

cfg=/opt/baseline/ruff-vault.toml
if [ ! -f "$cfg" ]; then
  deny "No está /opt/baseline/ruff-vault.toml. ruff no pudo comprobar el código. La app igual debe leer la config solo con vault_config."
fi

fail=
bad=$(ruff check --config "$cfg" --ignore-noqa --output-format concise . 2>&1) || fail=1
envs=$(find . -type f -name '.env*' ! -name '.env.example' -not -path './.git/*' | head -20)
if [ -n "$fail" ] || [ -n "$envs" ]; then
  deny "$bad
$envs"
fi
exit 0
