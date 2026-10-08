import asyncio

from app.core.config import Settings
from app.llm.provider import LLMProvider
from app.schemas.contracts import EmotionResponse, EmotionResult, Metadata

LABELS = ["fear", "sadness", "anxiety", "loneliness", "anger", "hope"]


class EmotionService:
    def __init__(self, provider: LLMProvider, settings: Settings):
        self.provider = provider
        self.settings = settings
        self._pipeline = None

    def _transformer(self, text):
        if self._pipeline is None:
            from transformers import pipeline

            self._pipeline = pipeline(
                "zero-shot-classification", model=self.settings.emotion_model_name
            )
        out = self._pipeline(text, candidate_labels=LABELS, multi_label=True)
        scores = dict(zip(out["labels"], out["scores"]))
        return EmotionResult(
            primary_emotion=max(scores, key=scores.get),
            scores=scores,
            themes=[],
            confidence=max(scores.values()),
        )

    async def analyze(self, text: str) -> EmotionResponse:
        fallback = None
        if self.settings.emotion_model_name and not self.settings.mock_ai_mode:
            try:
                result = await asyncio.to_thread(self._transformer, text)
                return EmotionResponse(
                    **result.model_dump(),
                    metadata=Metadata(
                        mode="live",
                        model_version=self.settings.emotion_model_name,
                        method="multilingual_zero_shot",
                    ),
                )
            except (ImportError, OSError, RuntimeError, ValueError):
                fallback = "configured_transformer_unavailable"
        else:
            fallback = "transformer_not_configured"
        result = await self.provider.structured(
            "emotion",
            {
                "text": text,
                "instruction": "Classify expressed emotions, not diagnoses. Scores are independent uncalibrated estimates. Return up to 8 short themes, not verbatim sensitive quotations.",
            },
            EmotionResult,
        )
        return EmotionResponse(
            **result.model_dump(),
            metadata=Metadata(
                mode="mock" if self.settings.mock_ai_mode else "live",
                model_version="mock-1.0" if self.settings.mock_ai_mode else self.settings.llm_model,
                method="mock_fixture"
                if self.settings.mock_ai_mode
                else "structured_llm_classification",
                fallback=fallback,
            ),
        )
