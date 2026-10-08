import re

from app.core.config import Settings
from app.llm.provider import LLMProvider, ProviderError
from app.schemas.contracts import SafetyAssessment

URGENT = re.compile(
    r"\b(bunuh diri|mengakhiri hidup|ingin mati|tidak ingin hidup|overdosis|sulit bernapas|sesak berat|kill myself|suicide)\b",
    re.I,
)
UNSAFE = re.compile(
    r"\b(hentikan (obat|kemoterapi)|stop (your )?(medication|chemotherapy)|minum\s+\d+\s*(mg|tablet)|anda (pasti )?mengalami depresi|kamu (pasti )?aman|pasti sembuh)\b",
    re.I,
)


class SafetyService:
    def __init__(self, provider: LLMProvider, settings: Settings):
        self.provider = provider
        self.settings = settings

    def support(self) -> str:
        message = "Aku mendengar bahwa situasi ini terasa berat. Jika ada bahaya langsung atau kondisi memburuk, segera cari bantuan darurat setempat atau datang ke fasilitas kesehatan terdekat. Jika memungkinkan, minta orang tepercaya menemanimu sekarang."
        if self.settings.emergency_resource_text:
            message += " " + self.settings.emergency_resource_text
        return message

    async def assess(self, text: str, output: bool = False) -> SafetyAssessment:
        if not output and URGENT.search(text):
            return SafetyAssessment(level="URGENT", unsafe_advice=False)
        if output and UNSAFE.search(text):
            return SafetyAssessment(level="CONCERN", unsafe_advice=True)
        if self.settings.mock_ai_mode:
            return SafetyAssessment(level="NONE", unsafe_advice=False)
        return await self.provider.structured(
            "safety",
            {
                "text": text,
                "is_assistant_output": output,
                "instruction": "Assess indirect crisis cues and immediate risk without diagnosing. For assistant output mark unsafe_advice if it prescribes, changes treatment, diagnoses, asserts safety/cure, or medical causation. This is a conservative support-routing check, not a diagnosis.",
            },
            SafetyAssessment,
        )

    async def checked(self, text: str) -> str:
        assessment = await self.assess(text, output=True)
        if assessment.unsafe_advice:
            raise ProviderError("Unsafe generated response blocked")
        return text
