# Production CI/CD

The workflow `.github/workflows/deploy-production.yml` deploys the exact
commit from `main` after the `Hopely checks` workflow succeeds. It updates the
existing checkout on the Azure server, rebuilds the Docker images, preserves
the server-side `.env`, and waits for Laravel's `/up` endpoint. A manual
`workflow_dispatch` deployment is also available.

## GitHub secrets

Create these repository or production-environment secrets:

- `DEPLOY_HOST`: Azure public IP or hostname.
- `DEPLOY_USER`: usually `azureuser`.
- `DEPLOY_SSH_KEY`: private key whose public key is in the Azure user's
  `~/.ssh/authorized_keys`.
- `DEPLOY_PATH`: `/opt/hopely-care`.
- `DEPLOY_PORT`: optional; defaults to `22`.
- `DEPLOY_KNOWN_HOSTS`: optional pinned output of `ssh-keyscan`; when omitted,
  the workflow scans the configured host during the run.

The server checkout must already have the GitHub repository as its `origin`
and must be able to fetch it. The checkout may be detached after deployment;
the workflow fetches the exact tested commit on the next run. For a private
repository, keep the server's GitHub deploy key separate from
`DEPLOY_SSH_KEY`.

## One-time server checks

```bash
cd /opt/hopely-care
test -f .env
git remote -v
docker compose version || docker-compose version
```

The production `.env` is never copied from GitHub. For live AI, verify the
server has `APP_ENV=production`, `MOCK_AI_MODE=false`, `LLM_PROVIDER=groq`, a
valid `GROQ_API_KEY`, and a supported `LLM_MODEL`.

After a failed deployment, inspect without printing secrets:

```bash
cd /opt/hopely-care
docker compose ps
docker compose logs --tail=150 ai-service backend
```
