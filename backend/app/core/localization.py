from typing import Optional


SUPPORTED_CONTENT_LANGUAGES = {
    "zh": "zh-CN",
    "en": "en-US",
    "ko": "ko-KR",
}


def resolve_content_language(accept_language: Optional[str]) -> str:
    if not accept_language:
        return "zh-CN"
    for candidate in accept_language.split(","):
        language = candidate.split(";", maxsplit=1)[0].strip().lower()
        base = language.split("-", maxsplit=1)[0]
        if base in SUPPORTED_CONTENT_LANGUAGES:
            return SUPPORTED_CONTENT_LANGUAGES[base]
    return "zh-CN"
