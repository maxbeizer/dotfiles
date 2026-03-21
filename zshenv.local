# Inject codespace environment variables into zsh
# (these are set by the codespace system in bash but not in zsh)
if [ "$CODESPACES" = "true" ] && [ -z "$CODESPACE_NAME" ]; then
  _cs_env="/workspaces/.codespaces/shared/environment-variables.json"
  if [ -f "$_cs_env" ]; then
    CODESPACE_NAME=$(grep -o '"CODESPACE_NAME": *"[^"]*"' "$_cs_env" | cut -d'"' -f4)
    export CODESPACE_NAME
  fi
fi

if [ -n "$CODESPACE_NAME" ]; then
  export CODESPACE_SHORT_NAME=$(echo "$CODESPACE_NAME" | sed 's/-[a-z0-9]*$//')
fi
