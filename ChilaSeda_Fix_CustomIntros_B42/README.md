# ChilaSeda Fix - PZ Custom Intros (B42)

Local compatibility addon for PZ Custom Intros on Project Zomboid Build 42.22.2.

The Workshop mod's loading-intro setup links to `Core.gameMode` as a `String`,
while B42.22.2 declares that field as `GameMode`; the descriptor mismatch causes
`NoSuchFieldError`. This addon replaces only `Boot.beginLoading()` and uses
`Core.getInstance().getGameMode()` for the Tutorial guard. It keeps the original
selection, story, canvas, loading gate, music, and vanilla-fallback behavior.

Requires `PZCustomIntros` and `ZombieBuddy`. The Workshop files remain unchanged.

## Changes in 1.0.1

- Routes the inlined ZombieBuddy advice through a public bridge entry point. This
  prevents `IllegalAccessError` when the advice executes inside `Boot` and reaches
  helpers in the local addon.
