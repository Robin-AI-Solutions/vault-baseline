# vault-baseline

Plugin de OpenHands: skill `vault-config` + hooks deterministas (PreToolUse / Stop)
para forzar que la configuración de la app se lea desde Vault.

## Estructura

```
vault-baseline/
├── .plugin/plugin.json
├── skills/vault-config/SKILL.md
├── hooks/
│   ├── hooks.json           # comandos inlined; es lo que ejecuta OpenHands
│   ├── stop.sh              # misma lógica que el Stop de hooks.json
│   └── pre_tool_use.sh      # misma lógica que el PreToolUse de hooks.json
└── image/
    ├── ruff-vault.toml      # debe vivir en /opt/baseline/ruff-vault.toml en el sandbox
    └── Dockerfile.snippet
```

## Publicar

```bash
git remote add origin git@github.com:Robin-AI-Solutions/vault-baseline.git  # ajustar
git push -u origin main
git push origin v1.0.0
```

App-server (OpenHands) inyecta:

```json
{ "source": "github:Robin-AI-Solutions/vault-baseline", "ref": "v1.0.0" }
```

Override: `OH_VAULT_BASELINE_PLUGIN_SOURCE`, `OH_VAULT_BASELINE_PLUGIN_REF`.

Repos privado: agent-server ≥ 1.29.0 con credenciales en el `source`.

## Imagen sandbox

Debe incluir `ruff`, `jq` y `/opt/baseline/ruff-vault.toml` (ver `image/`).
Si faltan, el hook Stop bloquea el cierre de la tarea a propósito.
El bloqueo indica cómo leer cada variable con `vault_config` (`get`, `get_bool`, `get_int`).
