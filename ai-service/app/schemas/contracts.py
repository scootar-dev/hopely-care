from datetime import date, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class Metadata(StrictModel):
    mode: Literal["mock", "live", "statistical"]
    model_version: str
    method: str
    fallback: str | None = None


Score = Annotated[int, Field(ge=1, le=5)]
Probability = Annotated[float, Field(ge=0, le=1)]


class Checkin(StrictModel):
    checkin_date: date
    mood_score: Score
    anxiety_score: Score
    energy_score: Score
    sleep_score: Score
    pain_score: Score


class Symptom(StrictModel):
    logged_at: datetime
    pain: Score
    fatigue: Score
    nausea: Score
    dizziness: Score
    appetite: Score
    sleep_quality: Score


class Treatment(StrictModel):
    treatment_type: str = Field(max_length=80)
    scheduled_at: datetime
    status: Literal["scheduled", "completed", "cancelled"] = "scheduled"


class EmotionScores(StrictModel):
    fear: Probability
    sadness: Probability
    anxiety: Probability
    loneliness: Probability
    anger: Probability
    hope: Probability


class EmotionSignal(StrictModel):
    mode: Literal["mock", "live"]
    date: date
    scores: EmotionScores


class ConsentContext(StrictModel):
    health: bool = False
    journal_analysis: bool = False
    chat_context: bool = False


class PatientContext(StrictModel):
    as_of: date
    timezone: str = "Asia/Jakarta"
    period_days: Literal[7, 14, 30] = 14
    recent_checkins: list[Checkin] = Field(default_factory=list, max_length=30)
    recent_symptoms: list[Symptom] = Field(default_factory=list, max_length=200)
    treatments: list[Treatment] = Field(default_factory=list, max_length=60)
    next_treatment: Treatment | None = None
    emotion_signals: list[EmotionSignal] = Field(default_factory=list, max_length=100)
    completed_activities: list[str] = Field(default_factory=list, max_length=10)
    consent: ConsentContext

    @model_validator(mode="after")
    def validate_context(self):
        from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

        try:
            ZoneInfo(self.timezone)
        except (ZoneInfoNotFoundError, ValueError) as exc:
            raise ValueError("Invalid timezone") from exc
        dates = [c.checkin_date for c in self.recent_checkins]
        if len(set(dates)) != len(dates):
            raise ValueError("Check-in dates must be unique")
        if any(d > self.as_of for d in dates):
            raise ValueError("Future check-in is not valid")
        if not self.consent.health:
            raise ValueError("Health processing consent required")
        if self.emotion_signals and not self.consent.journal_analysis:
            raise ValueError("Emotion context requires analysis consent")
        return self


class ContextRequest(StrictModel):
    context: PatientContext


class SummaryRequest(ContextRequest):
    reported_concerns: list[Annotated[str, Field(max_length=1000)]] = Field(
        default_factory=list, max_length=5
    )


class EmotionRequest(StrictModel):
    text: str = Field(min_length=1, max_length=12000)


class EmotionResult(StrictModel):
    primary_emotion: Literal["fear", "sadness", "anxiety", "loneliness", "anger", "hope"]
    scores: EmotionScores
    themes: list[str] = Field(max_length=8)
    confidence: Probability


class EmotionResponse(EmotionResult):
    metadata: Metadata


class SafetyAssessment(StrictModel):
    level: Literal["NONE", "CONCERN", "URGENT"]
    unsafe_advice: bool


class HistoryMessage(StrictModel):
    sender: Literal["user", "assistant"]
    content: str = Field(max_length=5000)


class CompanionRequest(ContextRequest):
    user_id: str = Field(max_length=100)
    message: str = Field(min_length=1, max_length=4000)
    history: list[HistoryMessage] = Field(default_factory=list, max_length=8)


class CompanionResult(StrictModel):
    reply: str = Field(min_length=1, max_length=4000)
    support_intent: str = Field(max_length=100)
    suggested_activity: str | None
    safety_signal: Literal["NONE", "CONCERN", "URGENT"]


class CompanionResponse(CompanionResult):
    metadata: Metadata


class MetricTrend(StrictModel):
    direction: Literal["increasing", "declining", "stable", "insufficient_data"]
    mean: float | None
    baseline_mean: float | None
    recent_mean: float | None
    slope_per_day: float | None
    baseline_delta: float | None
    rolling_averages: list[dict]
    unusual_dates: list[str]


class TrendResponse(StrictModel):
    contains_mock_signals: bool = False
    period_days: int
    recorded_days: int
    coverage: float
    trends: dict[str, str]
    metrics: dict[str, MetricTrend]
    series: list[Checkin]
    significant_changes: list[str]
    contextual_patterns: list[dict[str, str]]
    emotion_summary: dict[str, float]
    overall_direction: Literal["insufficient_data", "stable", "needs_attention", "improving"]
    metadata: Metadata


class Activity(StrictModel):
    id: str = Field(max_length=100)
    title: str = Field(max_length=150)
    description: str = Field(max_length=2000)
    category: str = Field(max_length=50)
    duration_minutes: int = Field(ge=1, le=60)
    suitability_tags: list[str] = Field(max_length=15)
    contraindication_notes: str | None = Field(default=None, max_length=1000)


class RecommendationRequest(ContextRequest):
    activities: list[Activity] = Field(min_length=1, max_length=30)


class Recommendation(StrictModel):
    activity_id: str
    reason: str = Field(max_length=600)
    confidence: Probability


class RecommendationResult(StrictModel):
    recommendations: list[Recommendation] = Field(max_length=3)


class RecommendationResponse(RecommendationResult):
    metadata: Metadata


class SummaryNarrative(StrictModel):
    questions_patient_may_want_to_discuss: list[str] = Field(max_length=5)


class SummaryResponse(StrictModel):
    period: str
    recorded_days: int
    wellbeing: dict[str, MetricTrend]
    symptom_patterns: list[dict]
    reported_concerns: list[str]
    treatment_context: list[Treatment]
    questions_patient_may_want_to_discuss: list[str]
    disclaimer: str
    metadata: Metadata


class WellbeingShare(StrictModel):
    recorded_days: int
    mood: float | None
    anxiety: float | None
    energy: float | None
    sleep: float | None


class SymptomShare(StrictModel):
    record_count: int
    pain: float | None
    fatigue: float | None
    nausea: float | None
    dizziness: float | None
    appetite: float | None
    sleep_quality: float | None


class ActivityShare(StrictModel):
    completed_count: int


class CaregiverContext(StrictModel):
    wellbeing_summary: WellbeingShare | None = None
    symptom_summary: SymptomShare | None = None
    treatment_schedule: list[Treatment] | None = None
    activity_status: ActivityShare | None = None


class CaregiverRequest(StrictModel):
    message: str = Field(min_length=1, max_length=2000)
    context: CaregiverContext


class CaregiverResult(StrictModel):
    support_message: str = Field(max_length=1500)
    communication_tip: str = Field(max_length=1000)
    suggested_action: str = Field(max_length=1000)


class CaregiverResponse(CaregiverResult):
    metadata: Metadata


class IngestRequest(StrictModel):
    source_id: str = Field(pattern=r"^[a-zA-Z0-9_-]{1,100}$")
    title: str = Field(min_length=1, max_length=300)
    publisher: str = Field(min_length=1, max_length=200)
    source_url: str | None = Field(default=None, max_length=1000)
    published_at: date | None = None
    document_version: str = Field(min_length=1, max_length=80)
    reviewed_by: str = Field(min_length=1, max_length=200)
    reviewed: Literal[True]
    text: str = Field(min_length=20, max_length=200000)


class RagRequest(StrictModel):
    question: str = Field(min_length=1, max_length=2000)


class RagResult(StrictModel):
    answer: str = Field(max_length=4000)
    citation_ids: list[str] = Field(max_length=5)
    confidence: Probability


class RagResponse(StrictModel):
    answer: str
    sources: list[dict]
    confidence: Probability
    metadata: Metadata
