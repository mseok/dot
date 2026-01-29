# English comments only

# Preserve the original shared HOME once
export ORIG_HOME="${ORIG_HOME:-$HOME}"

# Personal tag (directory name). Default: mseok
export PERSONAL_TAG="${PERSONAL_TAG:-mseok}"

# Override HOME to a per-user subdirectory
export HOME="${ORIG_HOME}/${PERSONAL_TAG}"

# XDG base dirs (keep configs/caches isolated)
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# Temp
export TMPDIR="${HOME}/.tmp"

# Bash history (avoid clobbering across nodes)
export HISTFILE="${XDG_STATE_HOME}/bash/history.${HOSTNAME}"
export HISTSIZE=200000
export HISTFILESIZE=400000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend 2>/dev/null || true

# Make sure dirs exist
mkdir -p \
  "${HOME}" \
  "${XDG_CONFIG_HOME}" \
  "${XDG_CACHE_HOME}" \
  "${XDG_DATA_HOME}" \
  "${XDG_STATE_HOME}/bash" \
  "${TMPDIR}"

# Safer default permissions for personal files
umask 077

# User-local binaries first
case ":$PATH:" in
  *":${HOME}/.local/bin:"*) ;;
  *) export PATH="${HOME}/.local/bin:${PATH}" ;;
esac

# Python/pip isolation
export PYTHONUSERBASE="${HOME}/.local"
export PIP_CACHE_DIR="${XDG_CACHE_HOME}/pip"
export PYTHONPYCACHEPREFIX="${XDG_CACHE_HOME}/pycache"

# Common scientific tooling caches/configs
export MPLCONFIGDIR="${XDG_CONFIG_HOME}/matplotlib"
export JUPYTER_CONFIG_DIR="${XDG_CONFIG_HOME}/jupyter"
export IPYTHONDIR="${XDG_CONFIG_HOME}/ipython"

# HuggingFace / Torch caches
export HF_HOME="${XDG_CACHE_HOME}/huggingface"
export TORCH_HOME="${XDG_CACHE_HOME}/torch"

# Weights & Biases
export WANDB_DIR="${XDG_DATA_HOME}/wandb"
export WANDB_CONFIG_DIR="${XDG_CONFIG_HOME}/wandb"
export WANDB_CACHE_DIR="${XDG_CACHE_HOME}/wandb"

# Apptainer/Singularity caches (very useful on HPC)
export APPTAINER_CACHEDIR="${XDG_CACHE_HOME}/apptainer"
export APPTAINER_TMPDIR="${TMPDIR}/apptainer"
export SINGULARITY_CACHEDIR="${APPTAINER_CACHEDIR}"
mkdir -p "${APPTAINER_CACHEDIR}" "${APPTAINER_TMPDIR}"

# CUDA cache (optional, but helps avoid polluting shared HOME)
export CUDA_CACHE_PATH="${XDG_CACHE_HOME}/nv/ComputeCache"
mkdir -p "${CUDA_CACHE_PATH}"

# Less history
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
mkdir -p "${XDG_STATE_HOME}/less"

# ---------------- Tool-specific isolation (conda / uv / bun / npm) ----------------
# English comments only

# ---------- Conda isolation ----------
# Never run `conda init` on a shared account.
# Keep all conda state inside the personal HOME.
export CONDARC="${XDG_CONFIG_HOME}/conda/condarc"
export CONDA_PKGS_DIRS="${XDG_CACHE_HOME}/conda/pkgs"
export CONDA_ENVS_PATH="${XDG_DATA_HOME}/conda/envs"
export CONDA_ROOT_PREFIX="${XDG_DATA_HOME}/conda/root"  # optional, for local installers if needed
mkdir -p "$(dirname "$CONDARC")" "$CONDA_PKGS_DIRS" "$CONDA_ENVS_PATH" "$CONDA_ROOT_PREFIX"

# Optional: reduce accidental writes to shared places
export CONDA_AUTO_UPDATE_CONDA=false

# ---------- uv isolation ----------
export UV_CACHE_DIR="${XDG_CACHE_HOME}/uv"
export UV_CONFIG_FILE="${XDG_CONFIG_HOME}/uv/uv.toml"
mkdir -p "$(dirname "$UV_CONFIG_FILE")" "$UV_CACHE_DIR"

# ---------- npm isolation ----------
# Keep npm global installs and config isolated
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"
export NPM_CONFIG_PREFIX="${XDG_DATA_HOME}/npm"
mkdir -p "$(dirname "$NPM_CONFIG_USERCONFIG")" "$NPM_CONFIG_CACHE" "$NPM_CONFIG_PREFIX"
unset NPM_CONFIG_PREFIX

# Ensure npm global bin is on PATH
case ":$PATH:" in
  *":${NPM_CONFIG_PREFIX}/bin:"*) ;;
  *) export PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}" ;;
esac

# ---------- bun isolation ----------
export BUN_INSTALL="${XDG_DATA_HOME}/bun"
export BUN_INSTALL_CACHE_DIR="${XDG_CACHE_HOME}/bun"
mkdir -p "$BUN_INSTALL" "$BUN_INSTALL_CACHE_DIR"

# Ensure bun bin is on PATH
case ":$PATH:" in
  *":${BUN_INSTALL}/bin:"*) ;;
  *) export PATH="${BUN_INSTALL}/bin:${PATH}" ;;
esac

# ---------- Safety toggles ----------
# Avoid polluting shared ~/.cache in case HOME override is not active
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR}}"

# Force tmux socket directory to be under personal HOME to avoid sharing /tmp/tmux-UID/default
export TMUX_TMPDIR="${TMPDIR}/tmux"
mkdir -p "${TMUX_TMPDIR}"
chmod 700 "${TMUX_TMPDIR}" 2>/dev/null || true
