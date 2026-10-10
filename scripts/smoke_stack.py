"""Exercise the disposable local Docker stack over HTTP, with synthetic data only.

Run from the repository root after `docker compose up --build -d --wait`.
Requires the default mock AI configuration. Never prints credentials or bodies.
"""

import json
import secrets
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

BASE_URL = "http://127.0.0.1:8000/api"


def request(method, path, expected=200, payload=None, token=None):
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(payload).encode() if payload is not None else None
    req = Request(BASE_URL + path, data=body, headers=headers, method=method)
    try:
        with urlopen(req, timeout=60) as response:
            status, content = response.status, response.read()
    except HTTPError as error:
        status, content = error.code, error.read()
    except URLError:
        raise RuntimeError(f"{method} {path}: local backend is unreachable") from None
    if status != expected:
        raise RuntimeError(f"{method} {path}: expected HTTP {expected}, got {status}")
    try:
        decoded = json.loads(content)
    except (ValueError, UnicodeDecodeError):
        raise RuntimeError(f"{method} {path}: response was not JSON") from None
    return decoded.get("data")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    # The stack is disposable; do not exercise a locally configured live provider.
    env_file = Path(__file__).resolve().parents[1] / ".env"
    config = dict(
        line.split("=", 1) for line in env_file.read_text().splitlines()
        if line and not line.startswith("#") and "=" in line
    )
    require(config.get("MOCK_AI_MODE") == "true", "Use a disposable stack with MOCK_AI_MODE=true")
    require(config.get("APP_ENV") in {"local", "testing"}, "Use a local/testing stack")
    preflight = Request(BASE_URL + "/auth/login", method="OPTIONS", headers={
        "Origin": "http://localhost:7777",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "content-type",
    })
    with urlopen(preflight, timeout=10) as response:
        require(response.status in {200, 204}, "Browser preflight failed")
        require(response.headers.get("Access-Control-Allow-Origin") in {"*", "http://localhost:7777"}, "Browser login CORS origin was not allowed")
    print("PASS: browser login preflight")
    email = f"smoke-{secrets.token_hex(12)}@test.invalid"
    password = secrets.token_urlsafe(32)
    token = None
    try:
        account = request("POST", "/auth/register", 201, {
            "name": "Synthetic HTTP test",
            "email": email,
            "password": password,
            "password_confirmation": password,
            "role": "PATIENT",
        })
        token = account["token"]
        user_id = account["user"]["id"]
        require("password" not in account["user"], "Registration exposed a password")
        request("POST", "/auth/logout", token=token)
        revoked_token = token
        token = None
        request("GET", "/me", 401, token=revoked_token)
        request("POST", "/auth/login", 401, {"email": email, "password": "wrong-password"})
        login = request("POST", "/auth/login", payload={"email": email.upper(), "password": password})
        token = login["token"]
        me = request("GET", "/me", token=token)
        require(me["user"]["id"] == user_id, "Login returned a different account")
        require(me["profile"]["user_id"] == user_id, "Patient profile was not created")
        require(request("GET", "/consents", token=token) == [], "New account consent is not empty")
        print("PASS: register, logout/revoked token, rejected credentials, email login, /me, /consents")

        request("POST", "/ai/chat", 403, {"message": "Pesan uji sintetis."}, token)
        request("PUT", "/consents", payload={"consent_type": "HEALTH_DATA_PROCESSING", "accepted": True}, token=token)
        request("POST", "/ai/chat", 403, {"message": "Pesan uji sintetis."}, token)
        request("PUT", "/consents", payload={"consent_type": "AI_CHAT_CONTEXT", "accepted": True}, token=token)
        chat = request("POST", "/ai/chat", payload={"message": "Saya ingin mencatat satu hal baik hari ini."}, token=token)
        require(chat.get("metadata", {}).get("mode") == "mock", "This smoke test requires MOCK_AI_MODE=true")
        require(bool(chat.get("reply")) and bool(chat.get("session_id")), "Chat response is incomplete")
        messages = request("GET", f"/chat/sessions/{chat['session_id']}/messages", token=token)
        require([m["sender"] for m in messages] == ["user", "assistant"], "Chat was not persisted")
        request("PUT", "/consents", payload={"consent_type": "AI_CHAT_CONTEXT", "accepted": False}, token=token)
        request("POST", "/ai/chat", 403, {"message": "Pesan uji setelah pencabutan izin."}, token)
        print("PASS: consent gates, Laravel -> FastAPI mock chat, persisted conversation, consent withdrawal")
    finally:
        # Recover a token after a partial failure between logout and login.
        if token is None:
            try:
                token = request("POST", "/auth/login", payload={"email": email, "password": password})["token"]
            except (RuntimeError, TypeError, KeyError):
                pass
        if token:
            request("DELETE", "/me", payload={"password": password}, token=token)
            request("GET", "/me", 401, token=token)
            print("PASS: synthetic account deleted and token revoked")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, TypeError, KeyError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
