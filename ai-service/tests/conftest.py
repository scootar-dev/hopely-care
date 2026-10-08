import os

os.environ["INTERNAL_SERVICE_KEY"] = "test-internal-key-at-least-32-characters"
os.environ["MOCK_AI_MODE"] = "true"
from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


@pytest.fixture
def headers():
    return {"X-Internal-Service-Key": os.environ["INTERNAL_SERVICE_KEY"]}


@pytest.fixture
def context():
    end = date(2026, 10, 7)
    rows = []
    for i in range(14):
        rows.append(
            {
                "checkin_date": str(end - timedelta(days=13 - i)),
                "mood_score": 4 if i < 9 else 2,
                "anxiety_score": 2 if i < 9 else 4,
                "energy_score": 4 if i < 9 else 2,
                "sleep_score": 4 if i < 9 else 2,
                "pain_score": 2,
            }
        )
    return {
        "as_of": str(end),
        "period_days": 14,
        "recent_checkins": rows,
        "consent": {"health": True, "journal_analysis": False, "chat_context": True},
    }
