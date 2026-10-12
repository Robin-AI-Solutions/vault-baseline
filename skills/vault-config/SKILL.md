---
name: vault-config
description: >
  Toda variable de configuración de la app se obtiene en runtime con la
  librería vault_config (Vault, auth Kubernetes, KV v2). El código de la
  app no lee VAULT_* ni usa os.environ. Actívalo con os.environ, getenv,
  .env, vault o variable de entorno.
triggers:
- os.environ
- getenv
- .env
- vault
- vault_config
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

**Toda** variable de configuración (API keys, hosts, flags, puertos, etc.) se
lee con la librería `vault_config`. La librería encapsula auth Kubernetes y
KV v2. El código de la aplicación no implementa esa lógica y no la limita a
un archivo.

No leas `VAULT_*` ni uses `os.environ` / `os.getenv` en el código de la app.
No pongas valores en claro en el proceso ni archivos `.env` del repo (salvo
`.env.example` de documentación). Las únicas env locales son los **punteros**
a Vault; los lee la librería. El resto son campos del secreto.

No crees `vault_config.py` en la app. No copies el cliente HTTP de Vault.
Python 3.10+. La librería usa solo biblioteca estándar.

## Instalación

Paquete `Robin-AI-Solutions-vault-config`, tag fijo:

```
pip install "git+https://github.com/Robin-AI-Solutions/vault-config@v0.1.0"
```

En `requirements.txt`:

```
Robin-AI-Solutions-vault-config @ git+https://github.com/Robin-AI-Solutions/vault-config@v0.1.0
```

Si el paquete vive en el subdirectorio `vault-config` de otro repositorio:

```
pip install "git+https://github.com/Robin-AI-Solutions/vaultlib@v0.1.0#subdirectory=vault-config"
```

## Uso

```python
from vault_config import get, get_bool, get_int

DB_HOST = get("DB_HOST")
DEBUG = get_bool("DEBUG")
PORT = get_int("PORT")
OTRO = get("API_KEY", secret_name="otro-secreto")
```

- `get(key, secret_name=None)` devuelve el campo como texto. Sin `secret_name` usa `VAULT_SECRET_NAME`.
- `get_bool` y `get_int` convierten el valor. El texto `"false"` es verdadero en Python, por eso existe `get_bool`.
- `reload()` descarta la caché y el token; la próxima lectura vuelve a Vault.

Si falta un puntero o una clave, se lanza `VaultConfigError`. El mensaje nombra lo que falta y no incluye valores ni el token. No captures ese error para inventar un valor por defecto.

## Punteros (únicas env locales)

| Variable | Rol |
|----------|-----|
| `VAULT_ADDR` | URL base de Vault |
| `VAULT_SECRET_NAME` | Secreto por defecto si `get` no recibe `secret_name` |
| `VAULT_ROLE` | Rol de auth en Vault |
| `VAULT_KV_MOUNT` | (opcional) mount KV; default `secret` |

La plataforma inyecta estos punteros. La app no los lee.

## Reglas

1. Config de la app solo con `get`, `get_bool` y `get_int`, en el módulo que necesite el valor.
2. No uses `os.environ` / `os.getenv` en el código de la app, ni para leer `VAULT_*`.
3. No crees ni edites `.env` / `.env.*` (`.env.example` sí está permitido).
4. No imprimas, loguees ni commitees el token de Vault ni los valores leídos.
5. Si faltan punteros o una clave, deja salir `VaultConfigError`. No inventes valores ni hardcodees secretos.
6. El nombre del campo en Vault debe coincidir con la clave que la app espera.
