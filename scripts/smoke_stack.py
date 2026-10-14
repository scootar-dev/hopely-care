"""Exercise the disposable local Docker stack over HTTP, with synthetic data only.

Run from the repository root after `docker compose up --build -d --wait`.
Requires the default mock AI configuration. Never prints credentials or bodies.
"""

import json
import secrets
import subprocess
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


def moderator(email, slug):
    result = subprocess.run(
        ["docker", "compose", "exec", "-T", "backend", "php", "artisan", "community:moderator", email, slug],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False, timeout=30,
    )
    require(result.returncode == 0, "Could not assign synthetic community moderator")


def community_smoke(token, email):
    catalogue = request("GET", "/communities", token=token)
    group = next((c for c in catalogue["items"] if c["slug"] == "dukungan-emosional"), None)
    require(group is not None, "Community catalogue seed is missing")
    group_id = group["id"]
    path = f"/communities/{group_id}"
    reader_email = f"community-smoke-{secrets.token_hex(12)}@test.invalid"
    reader_password = secrets.token_urlsafe(32)
    reader_token = None
    try:
        account = request("POST", "/auth/register", 201, {
            "name": "Synthetic community reader", "email": reader_email,
            "password": reader_password, "password_confirmation": reader_password, "role": "CAREGIVER",
        })
        reader_token = account["token"]
        reader_id = account["user"]["id"]
        story_data = {"content": "Cerita uji sintetis: terima kasih telah menemani.", "sharing_acknowledged": True}
        request("POST", path + "/posts", 403, story_data, token)
        for actor_token in [token, reader_token]:
            request("POST", path + "/join", payload={"display_name": "Sahabat Uji HTTP", "rules_accepted": True}, token=actor_token)
        story = request("POST", path + "/posts", 201, story_data, token)
        story_path = f"/community/posts/{story['id']}"
        require(story["moderation_status"] == "pending", "Mock moderation unexpectedly published a real submission")
        require(story["moderation_source"] == "manual_review", "Community moderation did not reach the actual FastAPI endpoint")
        request("GET", story_path, 403, token=reader_token)
        moderator(reader_email, group["slug"])
        queue = request("GET", "/community/moderation?kind=post", token=reader_token)
        require(any(p["id"] == story["id"] for p in queue["items"]), "Held story is missing from human queue")
        request("POST", f"/community/moderation/post/{story['id']}", payload={
            "action": "approve", "revision": story["revision"], "note": "Synthetic supportive test text reviewed.",
        }, token=reader_token)
        published = request("GET", story_path, token=reader_token)
        require(published["moderation_status"] == "approved", "Human approval did not publish story")
        require(email not in json.dumps(published) and "Synthetic HTTP test" not in json.dumps(published), "Private account identity leaked into community")
        reaction = request("POST", story_path + "/reactions", payload={"reaction_type": "support"}, token=reader_token)
        require(reaction["reaction_count"] == 1, "Support reaction was not persisted")
        comment = request("POST", story_path + "/comments", 201, {
            "content": "Komentar dukungan sintetis.", "sharing_acknowledged": True,
        }, reader_token)
        require(comment["moderation_status"] == "pending", "Mock comment unexpectedly auto-published")
        moderator(email, group["slug"])
        request("POST", f"/community/moderation/comment/{comment['id']}", payload={
            "action": "approve", "revision": comment["revision"], "note": "Synthetic comment reviewed.",
        }, token=token)
        comments = request("GET", story_path + "/comments", token=token)
        require(len(comments["items"]) == 1 and comments["items"][0]["moderation_status"] == "approved", "Approved comment not readable")
        notifications = request("GET", "/notifications", token=token)
        require(any(n["notification_type"] == "community_comment" for n in notifications), "Community comment notification missing")
        require(all("Komentar dukungan" not in n["body"] for n in notifications), "Notification leaked comment text")
        report = request("POST", "/community/reports", 201, {
            "reportable_type": "post", "reportable_id": story["id"], "reason": "other", "description": "Synthetic review request.",
        }, reader_token)
        request("POST", f"/community/moderation/report/{report['id']}", payload={
            "action": "dismiss", "note": "No violation in synthetic example.",
        }, token=token)
        safety = request("GET", "/community/safety", token=reader_token)
        require(safety["reports"]["items"][0]["status"] == "dismissed", "Report history did not update")
        request("PUT", "/community/preferences", payload={"notifications_enabled": False}, token=reader_token)
        require(request("GET", "/community/preferences", token=reader_token)["notifications_enabled"] is False, "Community opt-out not persisted")
        request("POST", f"/users/{reader_id}/block", token=token)
        request("GET", story_path, 403, token=reader_token)
        blocked_view = request("GET", story_path, token=token)
        require(blocked_view["reaction_count"] == 0 and blocked_view["comment_count"] == 0, "Block did not hide contributions")
        request("DELETE", f"/users/{reader_id}/block", token=token)
        request("DELETE", f"/community/comments/{comment['id']}", token=reader_token)
        request("DELETE", story_path, token=token)
        request("GET", story_path, 404, token=reader_token)
        request("DELETE", path + "/leave", token=reader_token)
        request("POST", path + "/posts", 403, story_data, reader_token)
        print("PASS: community membership, Laravel -> FastAPI hold, human review, comment/reaction, report history, block, opt-out, deletion")
    finally:
        if reader_token:
            request("DELETE", "/me", payload={"password": reader_password}, token=reader_token)


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
        community_smoke(token, email)
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
