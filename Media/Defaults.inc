; Control-Plaine | Media: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Media skin; add keys here with the Media prefix.

[Variables]
; The skin disappears when no app is playing.
MediaHideIdle=1
; Which players it follows: any (Windows media session) or wnp (WebNowPlaying Redux).
MediaSource=any
; Long song names slide once when the song changes and again on hover (1),
; or are always cut off with an ellipsis (0).
MediaScrollTitles=1
; Plugin that reads the player, set together with MediaSource:
; MediaPlayer (MediaPlayer.dll, any player) or WebNowPlaying (WebNowPlaying Redux).
MediaPlugin=MediaPlayer
