import asyncio

from app.core.config import Settings
from app.emotion.service import EmotionService
from app.llm.provider import MockProvider, ProviderError
from app.schemas.contracts import SummaryRequest
from app.services.engine import AIEngine


def settings():
    return Settings(internal_service_key="x" * 32, mock_ai_mode=True)


def test_reflection_contains_narrative_and_crisis_routes_to_human_support():
    service = EmotionService(MockProvider(), settings())
    normal = asyncio.run(service.analyze("Catatan sintetis tentang rasa khawatir."))
    assert normal.reflection
    crisis = asyncio.run(service.analyze("Saya ingin mati"))
    assert "bantuan darurat" in crisis.reflection


def test_summary_preserves_statistics_when_narrative_provider_fails(context):
    class Unavailable(MockProvider):
        async def structured(self, task, payload, schema):
            raise ProviderError("unavailable")

    engine = AIEngine(Unavailable(), settings())
    result = asyncio.run(engine.summary(SummaryRequest(context=context)))
    assert result.recorded_days == 14
    assert result.wellbeing
    assert result.questions_patient_may_want_to_discuss == []
    assert result.metadata.fallback == "ai_narrative_unavailable"
