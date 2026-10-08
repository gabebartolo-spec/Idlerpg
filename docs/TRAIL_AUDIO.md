# Quiet trail audio

More → Options has independent **Music** and **Sounds** switches. Both default
off, and each choice saves immediately. Enabling one does not enable the other;
switching either off stops its current playback. Existing text/motion choices
survive migration to save format 18.

The original 24-second trail sketch uses four suspended chord voicings and a
sparse eight-note bell line. Original pickup and reward cues mark useful finds
and successful milestones; ordinary combat stays quiet. Failed expeditions or
practice runs never use a victory cue. A burst of rewards cannot restart a cue
for every item. Startup/offline settlement happens before the audio layer is
connected, so returning does not play an entire history of sounds.

`tools/audio/build_trail_audio.py` is the complete original score/synthesis
source, using standard Python only. It builds reproducible 16-bit mono WAVs;
no recordings, third-party samples or source music were used. The loop is about
1.01 MiB of PCM, with two short cues. Quiet gain levels and zeroed loop edges
avoid an abrupt default playback or sample-boundary click. The redistribution
license is in `assets/audio/AUDIO_LICENSE.md`.

Tests verify opt-in defaults, independent playback/muting, saved choices,
exact loop/sample range, asset budget, burst/failure handling and unchanged
adventurer state. Builds are checked for clipping, boundary samples and
reproducible hashes. Speaker/headphone balance, Android interruption behavior
and measured device audio/frame/battery cost remain open for R27.

Application focus/pause notifications stop both players and suppress new cues;
returning starts opted-in music again without changing the saved choices.
This behavior is covered with synthetic notifications; actual device
interruption remains an Android verification item.
