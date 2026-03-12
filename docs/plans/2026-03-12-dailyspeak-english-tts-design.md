# DailySpeak English TTS Design

**Goal:** Route all English playback in DailySpeak through the verified backend APIs: keep translation on `POST /translate/text` and replace client-side `AVSpeechSynthesizer` playback with backend `POST /tts/english/mp3`.

**Recommended Approach:** Keep a single app-wide English speech player service that requests audio URLs from the backend, caches them by deterministic playback ID, and plays them with `AVPlayer`. Preserve existing button locations in `LearningFlowView` and `PracticeView`, but make them all call the same shared service.

**Why this approach:**
- It matches the backend contract exactly instead of mixing local TTS and remote TTS.
- It keeps playback behavior consistent across vocabulary, phrases, samples, and translated answers.
- It lets the backend reuse generated MP3 files by stable `id`, while the client also avoids duplicate requests with a local URL cache.

**Contract:**
- Translation: `POST /translate/text` with `text`, optional `sourceLang`, required `targetLang`
- English TTS: `POST /tts/english/mp3` with `id`, `text`

**Client behavior:**
- Generate deterministic TTS IDs from normalized English text so the same sentence reuses audio.
- Replace `AVSpeechSynthesizer` with a shared `AVPlayer`-based service.
- Keep one active playback at a time; tapping the same item stops it, tapping a new one switches to the new audio.
- Use the backend's single English voice across the app. Existing UI variants like `US` / `UK` / `Slow` remain entry points, but they now share the same backend voice until the backend exposes variants.

**Touch points:**
- `DailySpeak/Services/DailySpeakAPIService.swift`
- `DailySpeak/Services/EnglishSpeechPlayer.swift`
- `DailySpeak/Views/LearningFlowView.swift`
- `DailySpeak/Views/PracticeView.swift`
- `test_q01_preview_layout.sh`

**Verification:**
- Static guardrail script checks the new endpoint wiring and absence of local `AVSpeechSynthesizer`.
- Simulator build must succeed.
