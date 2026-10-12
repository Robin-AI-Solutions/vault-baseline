---
name: vault-config
description: >
  Toda variable de configuración de la app se guarda y se obtiene desde Vault
  en runtime. Las únicas env locales son punteros a Vault. Actívalo con
  os.environ, getenv, .env, vault o variable de entorno.
triggers:
- os.environ
- getenv
- .env
- vault
- variable de entorno
- Vault secrets
- vault secrets
- secret manager
- environment variables
- secrets injection
- secure environment
- VAULT_ADDR
---

# Vault config

**Toda** variable de configuración que normalmente leerías con `os.environ`
o `os.getenv` se obtiene desde Vault en runtime (API keys, hosts, flags, etc.).

No uses valores en claro en el proceso ni archivos `.env` del repo (salvo
`.env.example` de documentación). Las únicas env locales permitidas son los
**punteros** a Vault; el resto son campos del secreto en Vault.

La lectura debe vivir en `vault_config.py`. Fuera de ese archivo no uses
`os.environ` / `os.getenv` para config de la app.

## Punteros (únicas env locales)

| Variable | Rol |
|----------|-----|
| `VAULT_ADDR` | URL base de Vault |
| `VAULT_SECRET_NAME` | Identificador del secreto a leer |
| `VAULT_ROLE` | Rol de auth en Vault |
| `VAULT_KV_MOUNT` | (opcional) mount KV; default `secret` |
| `VAULT_SECRET_KEY` | (opcional) si solo necesitas un campo |

## Patrón (`vault_config.py`)

```python
import json
import os
import urllib.request
from pathlib import Path


def _vault_data() -> dict:
    """Auth con JWT del entorno → dict de todos los campos del secreto."""
    addr = os.environ["VAULT_ADDR"].rstrip("/")
    name = os.environ["VAULT_SECRET_NAME"].strip("/")
    role = os.environ["VAULT_ROLE"]
    mount = os.environ.get("VAULT_KV_MOUNT", "secret").strip("/")

    token_dir = Path(
        os.environ.get(
            "VAULT_AUTH_TOKEN_PATH",
            "/var/run/secrets/kubernetes.io/serviceaccount",
        )
    )
    namespace = (token_dir / "namespace").read_text(encoding="utf-8").strip()
    jwt = (token_dir / "token").read_text(encoding="utf-8").strip()

    login = json.load(
        urllib.request.urlopen(
            urllib.request.Request(
                f"{addr}/v1/auth/kubernetes/login",
                data=json.dumps({"role": role, "jwt": jwt}).encode(),
                headers={"Content-Type": "application/json"},
            )
        )
    )
    token = login["auth"]["client_token"]

    body = json.load(
        urllib.request.urlopen(
            urllib.request.Request(
                f"{addr}/v1/{mount}/data/{namespace}/{name}",
                headers={"X-Vault-Token": token},
            )
        )
    )
    return body["data"]["data"]


def read_vault_secret(secret_key: str) -> str:
    """Lee un campo concreto del secreto en Vault."""
    data = _vault_data()
    if secret_key not in data:
        raise KeyError(f"secret missing key {secret_key!r}")
    return data[secret_key]


# Ejemplos:
# api_key = read_vault_secret("API_KEY")
# db_host = read_vault_secret("DB_HOST")
```

## Reglas

1. **Toda** config vía Vault; fuera de `vault_config.py` no uses `os.environ` /
   `os.getenv` para valores de la app.
2. No crees ni edites `.env` / `.env.*` (`.env.example` sí está permitido).
3. No imprimas, loguees ni committees el token de Vault ni los valores leídos.
4. Prefiere stdlib (`urllib`) salvo que el proyecto ya tenga cliente Vault.
5. Si faltan punteros o el JWT, falla claro; no inventes valores ni hardcodees.
6. El nombre del campo en Vault debe coincidir con la clave que la app espera.
