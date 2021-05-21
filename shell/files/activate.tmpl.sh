# Hermit {{.Shell}} activation script

export HERMIT_ENV={{.Root}}

if [ -n "${ACTIVE_HERMIT+_}" ]; then
  if [ "$ACTIVE_HERMIT" = "$HERMIT_ENV" ]; then
    echo "This Hermit environment has already been activated. Skipping" >&2
    return 34
  else
    export HERMIT_CURRENT_ENV=$HERMIT_ENV
    export HERMIT_ENV=$ACTIVE_HERMIT
    deactivate-hermit
    export HERMIT_ENV=$HERMIT_CURRENT_ENV
    unset HERMIT_CURRENT_ENV
  fi
fi

_hermit_deactivate() {
  echo "Hermit environment $(${HERMIT_ENV}/bin/hermit env HERMIT_ENV) deactivated"
  eval "$HERMIT_DEACTIVATION"
  unset -f deactivate-hermit >/dev/null 2>&1
  unset -f update_hermit_env >/dev/null 2>&1
  unset ACTIVE_HERMIT

  hash -r 2>/dev/null

{{- if .Bash }}
  unset PROMPT_COMMAND >/dev/null 2>&1
  if test -n "${_HERMIT_OLD_PROMPT_COMMAND+_}"; then export PROMPT_COMMAND="${_HERMIT_OLD_PROMPT_COMMAND}"; unset _HERMIT_OLD_PROMPT_COMMAND; fi
{{- end}}

{{- if .Zsh }}
  precmd_functions=(${precmd_functions:#update_hermit_env})
{{- end}}

  if test -n "${_HERMIT_OLD_PS1+_}"; then export PS1="${_HERMIT_OLD_PS1}"; unset _HERMIT_OLD_PS1; fi

}

deactivate-hermit() {
  export DEACTIVATED_HERMIT="$HERMIT_ENV"
  _hermit_deactivate
}


unset DEACTIVATED_HERMIT
export ACTIVE_HERMIT=$HERMIT_ENV
export HERMIT_DEACTIVATION="$(${HERMIT_ENV}/bin/hermit env --deactivate)"
export HERMIT_BIN_CHANGE=$(date -r ${HERMIT_ENV}/bin +"%s")

if test -n "${PS1+_}"; then export _HERMIT_OLD_PS1="${PS1}"; export PS1="{{ .EnvName }}🐚 ${PS1}"; fi

update_hermit_env() {
  local CURRENT=$(date -r ${HERMIT_ENV}/bin +"%s")
  test "$CURRENT" = "$HERMIT_BIN_CHANGE" && return 0
  local CUR_HERMIT=${HERMIT_ENV}/bin/hermit
  eval "$HERMIT_DEACTIVATION"
  eval "$(${CUR_HERMIT} env --activate)"
  export HERMIT_DEACTIVATION=$(${HERMIT_ENV}/bin/hermit env --deactivate)
  export HERMIT_BIN_CHANGE=$CURRENT
}

{{- if .Bash }}
if test -n "${PROMPT_COMMAND+_}"; then
  export _HERMIT_OLD_PROMPT_COMMAND="${PROMPT_COMMAND}"
  export PROMPT_COMMAND="update_hermit_env; $PROMPT_COMMAND"
else
  export PROMPT_COMMAND="update_hermit_env"
fi
{{- end}}

{{- if .Zsh }}
precmd_functions+=(update_hermit_env)
{{- end}}
