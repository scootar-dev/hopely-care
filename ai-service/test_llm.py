import asyncio
from app.core.config import get_settings
from app.llm.provider import make_provider
from app.schemas.contracts import CompanionResult
async def main():
    settings = get_settings()
    provider = make_provider(settings)
    try:
        res = await provider.structured('companion', {'message': 'halo', 'context': {}, 'history': []}, CompanionResult)
        print(res)
    except Exception as e:
        import traceback
        traceback.print_exc()

asyncio.run(main())
