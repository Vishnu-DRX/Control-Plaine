; Control-Plaine | Media: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Media skin; add keys here with the Media prefix.

[Variables]
; The skin disappears when no app is playing.
MediaHideIdle=1
; Which players it follows: any (Windows media session) or wnp (WebNowPlaying Redux).
MediaSource=any
; Slide long song names instead of cutting them off.
MediaScrollTitles=0
; Plugin that reads the player, set together with MediaSource:
; MediaPlayer (MediaPlayer.dll, any player) or WebNowPlaying (WebNowPlaying Redux).
MediaPlugin=MediaPlayer
