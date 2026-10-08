from datetime import timedelta
from zoneinfo import ZoneInfo

from app.core.config import Settings
from app.llm.provider import LLMProvider, ProviderError
from app.safety.service import SafetyService
from app.schemas.contracts import (
    CaregiverRequest,
    CaregiverResponse,
    CaregiverResult,
    CompanionRequest,
    CompanionResponse,
    CompanionResult,
    Metadata,
    RecommendationRequest,
    RecommendationResponse,
    RecommendationResult,
    SummaryNarrative,
    SummaryRequest,
    SummaryResponse,
)
from app.trend.service import TrendService


class AIEngine:
    def __init__(self, provider: LLMProvider, settings: Settings):
        self.provider = provider
        self.settings = settings
        self.trends = TrendService()
        self.safety = SafetyService(provider, settings)

    def metadata(self, method: str) -> Metadata:
        return Metadata(
            mode="mock" if self.settings.mock_ai_mode else "live",
            model_version="mock-1.0" if self.settings.mock_ai_mode else self.settings.llm_model,
            method=method,
        )

    async def companion(self, req: CompanionRequest) -> CompanionResponse:
        if not req.context.consent.chat_context:
            raise PermissionError("AI chat consent required")
        safety = await self.safety.assess(req.message)
        if safety.level == "URGENT":
            return CompanionResponse(
                reply=self.safety.support(),
                support_intent="human_support",
                suggested_activity=None,
                safety_signal="URGENT",
                metadata=self.metadata("safety_support"),
            )
        result = await self.provider.structured(
            "companion",
            {
                "message": req.message,
                "context": req.context.model_dump(mode="json"),
                "history": [h.model_dump() for h in req.history],
            },
            CompanionResult,
        )
        # Activities are selected separately from the curated catalog, not invented in chat.
        result.suggested_activity = None
        if result.safety_signal == "URGENT":
            result.reply = self.safety.support()
        else:
            result.reply = await self.safety.checked(result.reply)
        if safety.level == "CONCERN" and result.safety_signal == "NONE":
            result.safety_signal = "CONCERN"
        return CompanionResponse(
            **result.model_dump(), metadata=self.metadata("contextual_companion")
        )

    async def recommendations(self, req: RecommendationRequest) -> RecommendationResponse:
        result = await self.provider.structured(
            "recommendations",
            {
                "context": req.context.model_dump(mode="json"),
                "trend": self.trends.analyze(req.context).model_dump(mode="json"),
                "activities": [a.model_dump() for a in req.activities],
                "instruction": "Rank only supplied activity IDs. Respect contraindication notes and limited energy. May abstain with empty list. Do not invent medical efficacy.",
            },
            RecommendationResult,
        )
        allowed = {a.id for a in req.activities}
        seen = set()
        for rec in result.recommendations:
            if rec.activity_id not in allowed or rec.activity_id in seen:
                raise ProviderError("Invalid activity ID")
            seen.add(rec.activity_id)
            await self.safety.checked(rec.reason)
        return RecommendationResponse(
            **result.model_dump(), metadata=self.metadata("curated_semantic_ranking")
        )

    async def caregiver(self, req: CaregiverRequest) -> CaregiverResponse:
        signal = await self.safety.assess(req.message)
        if signal.level == "URGENT":
            return CaregiverResponse(
                support_message=self.safety.support(),
                communication_tip="Dengarkan dengan tenang dan tawarkan kehadiran.",
                suggested_action="Hubungi bantuan manusia yang sesuai.",
                metadata=self.metadata("safety_support"),
            )
        result = await self.provider.structured(
            "caregiver",
            {
                "message": req.message,
                "context": req.context.model_dump(mode="json", exclude_none=True),
                "instruction": "Only discuss fields present in permitted context. Missing fields are not permission to infer private history. Give communication support, not diagnosis.",
            },
            CaregiverResult,
        )
        await self.safety.checked(" ".join(result.model_dump().values()))
        return CaregiverResponse(
            **result.model_dump(), metadata=self.metadata("permission_filtered_coach")
        )

    async def summary(self, req: SummaryRequest) -> SummaryResponse:
        ctx = req.context
        trend = self.trends.analyze(ctx)
        start = ctx.as_of - timedelta(days=ctx.period_days - 1)
        zone = ZoneInfo(ctx.timezone)
        symptoms = [
            s
            for s in ctx.recent_symptoms
            if start <= s.logged_at.astimezone(zone).date() <= ctx.as_of
        ]
        patterns = []
        for name in ["pain", "fatigue", "nausea", "dizziness", "appetite", "sleep_quality"]:
            values = [getattr(s, name) for s in symptoms]
            if values:
                patterns.append(
                    {
                        "metric": name,
                        "mean": round(sum(values) / len(values), 2),
                        "record_count": len(values),
                        "scale": "1–5; patient-reported",
                    }
                )
        narrative = await self.provider.structured(
            "summary",
            {
                "recorded_days": trend.recorded_days,
                "trends": trend.trends,
                "symptom_patterns": patterns,
                "instruction": "Suggest neutral questions to discuss the recorded observations with the care team. Do not introduce drugs, dosages, diagnosis or facts absent from records.",
            },
            SummaryNarrative,
        )
        await self.safety.checked(" ".join(narrative.questions_patient_may_want_to_discuss))
        return SummaryResponse(
            period=f"{start.isoformat()} / {ctx.as_of.isoformat()}",
            recorded_days=trend.recorded_days,
            wellbeing=trend.metrics,
            symptom_patterns=patterns,
            reported_concerns=req.reported_concerns,
            treatment_context=[
                t
                for t in ctx.treatments
                if start <= t.scheduled_at.astimezone(zone).date() <= ctx.as_of
            ],
            questions_patient_may_want_to_discuss=narrative.questions_patient_may_want_to_discuss,
            disclaimer="This summary is generated from information reported by the patient and is not a medical diagnosis.",
            metadata=self.metadata("patient_reported_summary"),
        )
