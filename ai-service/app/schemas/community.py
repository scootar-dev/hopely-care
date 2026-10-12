from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class CommunityContract(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class CommunityModerationRequest(CommunityContract):
    content_type: Literal["post", "comment"]
    content: str = Field(min_length=2, max_length=4000)


Category = Literal[
    "medical_misinformation", "dangerous_medical_claim", "harassment", "hate_speech",
    "spam", "scam", "unverified_treatment", "unsafe_content",
]


class ModerationDecision(CommunityContract):
    status: Literal["safe", "review", "unsafe"]
    categories: list[Category] = Field(max_length=8)
    confidence: float = Field(ge=0, le=1)
    reason: str = Field(min_length=1, max_length=300)


class CommunityModerationResponse(ModerationDecision):
    mode: Literal["model", "rules", "manual_review"]


class CommunityInterests(CommunityContract):
    cancer_type: str | None = Field(default=None, max_length=100)
    treatment_phase: str | None = Field(default=None, max_length=100)
    support_preferences: list[str] = Field(default_factory=list, max_length=10)


class CommunityCandidate(CommunityContract):
    id: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=100)
    category: str = Field(max_length=40)
    cancer_type: str | None = Field(default=None, max_length=100)
    treatment_phase: str | None = Field(default=None, max_length=100)
    support_type: str | None = Field(default=None, max_length=100)
    activity_count: int = Field(default=0, ge=0, le=1_000_000_000)


class CommunityRecommendationRequest(CommunityContract):
    personalization_allowed: bool = False
    patient_context: CommunityInterests = Field(default_factory=CommunityInterests)
    communities: list[CommunityCandidate] = Field(max_length=200)


class CommunityRecommendation(CommunityContract):
    community_id: str
    score: float = Field(ge=0, le=1)
    reason: str


class CommunityRecommendationResponse(CommunityContract):
    recommendations: list[CommunityRecommendation]
    method: Literal["metadata"] = "metadata"
