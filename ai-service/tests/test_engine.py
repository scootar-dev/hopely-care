import asyncio

import pytest
from pydantic import ValidationError

from app.core.config import Settings
from app.llm.provider import MockProvider, ProviderError
from app.schemas.contracts import (
    PatientContext,
    RecommendationRequest,
    RecommendationResult,
)
from app.services.engine import AIEngine
from app.trend.service import TrendService


@pytest.mark.parametrize(
    "path",
    [
        "/v1/ai/companion",
        "/v1/ai/emotion/analyze",
        "/v1/ai/trend/analyze",
        "/v1/ai/recommendations",
        "/v1/ai/doctor-summary",
        "/v1/ai/caregiver-coach",
        "/v1/rag/query",
        "/v1/knowledge/ingest",
    ],
)
def test_all_private_endpoints_require_key(client, path):
    assert client.post(path, json={}).status_code == 401


def test_health_public(client):
    assert client.get("/health").json()["status"] == "ok"


def test_internal_docs_not_public(client):
    assert client.get("/openapi.json").status_code == 404


def test_trend_decline_uses_longitudinal_data(client, headers, context):
    r = client.post("/v1/ai/trend/analyze", headers=headers, json={"context": context})
    assert r.status_code == 200, r.text
    out = r.json()
    assert out["trends"]["anxiety"] == "increasing"
    assert out["trends"]["sleep"] == "declining"
    assert out["trends"]["pain"] == "stable"
    assert out["recorded_days"] == 14
    assert out["metrics"]["anxiety"]["baseline_delta"] > 0
    assert out["metrics"]["sleep"]["slope_per_day"] < 0


def test_one_observation_is_not_a_trend(context):
    context["recent_checkins"] = context["recent_checkins"][-1:]
    out = TrendService().analyze(PatientContext.model_validate(context))
    assert out.overall_direction == "insufficient_data"
    assert out.metrics["mood"].slope_per_day is None


def test_no_fabricated_missing_days(context):
    context["recent_checkins"] = context["recent_checkins"][::2]
    out = TrendService().analyze(PatientContext.model_validate(context))
    assert len(out.series) == 7
    assert out.coverage == 0.5


def test_duplicate_dates_rejected(context):
    context["recent_checkins"].append(context["recent_checkins"][0])
    with pytest.raises(ValidationError):
        PatientContext.model_validate(context)


def test_future_dates_rejected(context):
    context["recent_checkins"][0]["checkin_date"] = "2026-10-08"
    with pytest.raises(ValidationError):
        PatientContext.model_validate(context)


def test_emotions_cannot_bypass_consent(context):
    context["emotion_signals"] = [
        {
            "date": "2026-10-07",
            "scores": dict.fromkeys(
                ["fear", "sadness", "anxiety", "loneliness", "anger", "hope"], 0.3
            ),
        }
    ]
    with pytest.raises(ValidationError):
        PatientContext.model_validate(context)


def test_health_consent_required(context):
    context["consent"]["health"] = False
    with pytest.raises(ValidationError):
        PatientContext.model_validate(context)


def test_no_private_extra_fields_in_context(client, headers, context):
    context["journal"] = "SECRET JOURNAL"
    r = client.post("/v1/ai/trend/analyze", headers=headers, json={"context": context})
    assert r.status_code == 422
    assert "SECRET JOURNAL" not in r.text


def test_mock_explicit(client, headers):
    r = client.post(
        "/v1/ai/emotion/analyze", headers=headers, json={"text": "Saya takut menghadapi besok."}
    )
    assert r.status_code == 200
    assert r.json()["metadata"]["mode"] == "mock"
    assert r.json()["confidence"] == 0


def test_chat_consent_checked(client, headers, context):
    context["consent"]["chat_context"] = False
    r = client.post(
        "/v1/ai/companion",
        headers=headers,
        json={"user_id": "x", "message": "halo", "context": context},
    )
    assert r.status_code == 403


def test_crisis_routes_to_human_support(client, headers, context):
    r = client.post(
        "/v1/ai/companion",
        headers=headers,
        json={"user_id": "x", "message": "aku ingin mengakhiri hidup", "context": context},
    )
    assert r.status_code == 200
    assert r.json()["safety_signal"] == "URGENT"
    assert "bantuan" in r.json()["reply"]
    assert "119" not in r.json()["reply"]


def test_caregiver_raw_chat_rejected(client, headers):
    r = client.post(
        "/v1/ai/caregiver-coach",
        headers=headers,
        json={"message": "bagaimana membantu", "context": {"journal": "PRIVATE"}},
    )
    assert r.status_code == 422
    assert "PRIVATE" not in r.text


def test_knowledge_mock_abstains(client, headers):
    r = client.post("/v1/rag/query", headers=headers, json={"question": "Apa obat saya?"})
    assert r.status_code == 200
    assert r.json()["sources"] == []
    assert r.json()["confidence"] == 0


def test_summary_does_not_infer_sleep_hours(client, headers, context):
    r = client.post("/v1/ai/doctor-summary", headers=headers, json={"context": context})
    assert r.status_code == 200, r.text
    assert r.json()["reported_concerns"] == []
    assert "not a medical diagnosis" in r.json()["disclaimer"]
    assert r.json()["wellbeing"]["sleep"]["mean"] > 0


def test_activity_ids_constrained(context):
    class BadProvider(MockProvider):
        async def structured(self, task, payload, schema):
            return RecommendationResult(
                recommendations=[{"activity_id": "invented", "reason": "x", "confidence": 0.9}]
            )

    request = RecommendationRequest(
        context=context,
        activities=[
            {
                "id": "allowed",
                "title": "Reflection",
                "description": "Reflection",
                "category": "reflection",
                "duration_minutes": 3,
                "suitability_tags": [],
            }
        ],
    )
    engine = AIEngine(BadProvider(), Settings(internal_service_key="x" * 32))
    with pytest.raises(ProviderError):
        asyncio.run(engine.recommendations(request))


def test_provider_failure_never_silently_mocks(context):
    from app.schemas.contracts import CompanionRequest

    class Broken(MockProvider):
        async def structured(self, *args):
            raise ProviderError("failure")

    engine = AIEngine(Broken(), Settings(internal_service_key="x" * 32))
    with pytest.raises(ProviderError):
        asyncio.run(
            engine.companion(CompanionRequest(user_id="x", message="halo", context=context))
        )


def test_production_disallows_mock():
    with pytest.raises(ValidationError):
        Settings(internal_service_key="x" * 32, app_env="production", mock_ai_mode=True)


def test_unreviewed_ingestion_rejected(client, headers):
    r = client.post(
        "/v1/knowledge/ingest",
        headers=headers,
        json={
            "source_id": "s",
            "title": "x",
            "publisher": "x",
            "document_version": "1",
            "reviewed_by": "a",
            "reviewed": False,
            "text": "A long example document for this test.",
        },
    )
    assert r.status_code == 422


def test_summary_concerns_are_explicit_not_inferred(client, headers, context):
    concerns = ["Saya ingin membahas tidur saya."]
    result = client.post(
        "/v1/ai/doctor-summary",
        headers=headers,
        json={"context": context, "reported_concerns": concerns},
    )
    assert result.status_code == 200
    assert result.json()["reported_concerns"] == concerns


def test_mock_emotion_origin_is_disclosed_in_statistical_trend(context):
    context["consent"]["journal_analysis"] = True
    context["emotion_signals"] = [
        {
            "date": context["as_of"],
            "mode": "mock",
            "scores": dict.fromkeys(
                ["fear", "sadness", "anxiety", "loneliness", "anger", "hope"], 0.3
            ),
        }
    ]
    result = TrendService().analyze(PatientContext.model_validate(context))
    assert result.contains_mock_signals is True


def test_request_validation_never_echoes_private_text(client, headers):
    response = client.post(
        "/v1/ai/emotion/analyze",
        headers=headers,
        json={"text": "private-data", "journal_body": "confidential"},
    )
    assert response.status_code == 422
    assert "private-data" not in response.text
    assert "confidential" not in response.text


def test_oversized_request_rejected_before_json_parse(client, headers):
    result = client.post("/v1/ai/emotion/analyze", headers=headers, content=b"x" * 300001)
    assert result.status_code == 413
    assert result.json()["error"]["code"] == "payload_too_large"


def test_invalid_timezone_is_validation_error(client, headers, context):
    context["timezone"] = "Not/A_Zone"
    result = client.post("/v1/ai/trend/analyze", headers=headers, json={"context": context})
    assert result.status_code == 422
    assert "Not/A_Zone" not in result.text
