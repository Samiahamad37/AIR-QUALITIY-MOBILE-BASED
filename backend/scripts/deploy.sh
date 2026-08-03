#!/usr/bin/env bash
# Run on the production VM after git pull (also invoked by GitHub Actions).
set -euo pipefail

APP_DIR="${DEPLOY_PATH:-/home/ubuntu/airquality_mobile}"
BRANCH="${DEPLOY_BRANCH:-branch1}"
SERVICE="${GUNICORN_SERVICE:-gunicorn}"

echo "==> Deploying backend from ${APP_DIR} (${BRANCH})"

cd "${APP_DIR}"

if [[ ! -d .git ]]; then
  echo "ERROR: ${APP_DIR} is not a git repository."
  exit 1
fi

git fetch origin "${BRANCH}"
git checkout "${BRANCH}"
git pull --ff-only origin "${BRANCH}"

cd backend

if [[ -d venv ]]; then
  # shellcheck disable=SC1091
  source venv/bin/activate
elif [[ -d "${APP_DIR}/venv" ]]; then
  # shellcheck disable=SC1091
  source "${APP_DIR}/venv/bin/activate"
fi

python -m pip install --upgrade pip
pip install -r requirements.txt

if [[ ! -f .env ]]; then
  echo "WARNING: backend/.env missing — copy .env on the server before deploying."
fi

python manage.py migrate --noinput
python manage.py collectstatic --noinput 2>/dev/null || true

restart_service() {
  local name="$1"
  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q "^${name}.service"; then
    echo "==> Restarting systemd service: ${name}"
    sudo systemctl restart "${name}"
    sudo systemctl is-active --quiet "${name}"
    return 0
  fi
  return 1
}

if restart_service "${SERVICE}"; then
  echo "==> Service ${SERVICE} restarted"
elif restart_service "airquality"; then
  echo "==> Service airquality restarted"
elif restart_service "gunicorn-airquality"; then
  echo "==> Service gunicorn-airquality restarted"
else
  echo "==> No systemd unit found; sending HUP to gunicorn (if running)"
  pkill -HUP gunicorn 2>/dev/null || true
fi

echo "==> Deploy finished"
