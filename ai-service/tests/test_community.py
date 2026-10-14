import asyncio

import pytest

from app.core.config import Settings
from app.llm.provider import MockProvider, ProviderError
from app.schemas.community import CommunityModerationRequest
from app.services.community import CommunityAI


def live_settings():
    return Settings(internal_service_key="x" * 32, mock_ai_mode=False,
                    llm_api_key="synthetic-key", llm_model="synthetic-test-model")


class DecisionProvider:
    def __init__(self, status="safe", confidence=0.95, categories=None):
        self.status, self.confidence, self.categories = status, confidence, categories or []
        self.calls = []

    async def structured(self, task, payload, schema):
        self.calls.append((task, payload))
        return schema(status=self.status, confidence=self.confidence,
                      categories=self.categories, reason="Hasil uji sintetis.")


@pytest.mark.parametrize("path", ["moderate", "recommend"])
def test_community_endpoints_are_internal(client, path):
    assert client.post("/v1/ai/community/" + path, json={}).status_code == 401


def test_supportive_personal_experience_can_be_safe():
    provider = DecisionProvider()
    service = CommunityAI(provider, live_settings())
    response = asyncio.run(service.moderate(CommunityModerationRequest(
        content_type="post", content="Besok aku kemoterapi ketiga. Aku takut, tetapi merasa ditemani."
    )))
    assert response.status == "safe"
    assert response.mode == "model"
    assert set(provider.calls[0][1]) == {"content_type", "content"}


@pytest.mark.parametrize("content,category", [
    ("Obat dokter tidak perlu diminum, cukup minum X karena pasti menyembuhkan kanker.", "medical_misinformation"),
    ("Dasar bodoh, mati saja kamu!", "harassment"),
    ("Transfer uang untuk obat dijamin menyembuhkan kanker!", "scam"),
])
def test_risky_text_is_held_for_humans_even_without_live_ai(client, headers, content, category):
    result = client.post("/v1/ai/community/moderate", headers=headers,
                         json={"content_type": "post", "content": content})
    assert result.status_code == 200
    assert result.json()["status"] == "review"
    assert category in result.json()["categories"]
    assert result.json()["mode"] == "rules"


def test_mock_never_pretends_to_approve_real_posts(client, headers):
    result = client.post("/v1/ai/community/moderate", headers=headers,
                         json={"content_type": "comment", "content": "Terima kasih sudah berbagi."})
    assert result.json()["status"] == "review"
    assert result.json()["mode"] == "manual_review"


@pytest.mark.parametrize("status,categories", [("safe", []), ("unsafe", ["unsafe_content"])])
def test_low_confidence_requires_review(status, categories):
    service = CommunityAI(DecisionProvider(status, 0.4, categories), live_settings())
    response = asyncio.run(service.moderate(CommunityModerationRequest(content_type="post", content="Cerita sintetis.")))
    assert response.status == "review"


def test_safe_result_with_concerns_is_not_published():
    service = CommunityAI(DecisionProvider(categories=["hate_speech"]), live_settings())
    response = asyncio.run(service.moderate(CommunityModerationRequest(content_type="post", content="Teks uji sintetis.")))
    assert response.status == "review"


def test_provider_failure_is_not_converted_into_safe():
    class BrokenProvider(MockProvider):
        async def structured(self, *args):
            raise ProviderError("Synthetic unavailable provider")
    service = CommunityAI(BrokenProvider(), live_settings())
    with pytest.raises(ProviderError):
        asyncio.run(service.moderate(CommunityModerationRequest(content_type="post", content="Cerita uji.")))


def test_recommendations_only_use_supplied_catalogue_and_explicit_preferences(client, headers):
    payload = {"personalization_allowed": True,
               "patient_context": {"cancer_type": "Kanker Payudara", "treatment_phase": "Kemoterapi"},
               "communities": [
                   {"id": "a", "name": "Umum", "category": "emotional", "activity_count": 100},
                   {"id": "b", "name": "Payudara", "category": "cancer", "cancer_type": "kanker payudara"},
                   {"id": "b", "name": "Duplikat", "category": "cancer"},
               ]}
    result = client.post("/v1/ai/community/recommend", headers=headers, json=payload).json()
    assert result["method"] == "metadata"
    assert [r["community_id"] for r in result["recommendations"]] == ["b", "a"]
    assert "kamu pilih" in result["recommendations"][0]["reason"]
    payload["personalization_allowed"] = False
    result = client.post("/v1/ai/community/recommend", headers=headers, json=payload).json()
    assert result["recommendations"][0]["community_id"] == "a"


def test_community_rejects_private_context_fields(client, headers):
    result = client.post("/v1/ai/community/recommend", headers=headers, json={
        "patient_context": {"journal": "PRIVATE JOURNAL"}, "communities": []
    })
    assert result.status_code == 422
    assert "PRIVATE JOURNAL" not in result.text
