// Voice processing after synthesis (voice series V4a): TD-PSOLA pitch and formant shift of the voice-samples-2 stand the
// parent chose in round 3; the chain's EQ arrives with V4b. Plain C, no platform code.
#ifndef ALLY_VOICEFX_H
#define ALLY_VOICEFX_H

/// Pitch and formant shift in semitones, then the stand's 0.97 peak guard. Writes n samples to out.
/// Returns 0, or -1 when memory runs out or sr is not positive.
int ally_fx_process(const float *x, int n, int sr, double pitch_st, double formant_st, float *out);

/// Frames of the pitch track for n samples at sr: one per 5 ms.
int ally_pitch_frames(int n, int sr);

/// Own autocorrelation pitch track: f0[i] in Hz, 0 = unvoiced; frame i is centred at *t0 + i * 0.005 s.
/// f0 holds ally_pitch_frames(n, sr) values. Returns the frame count, or -1 when memory runs out.
int ally_pitch_track(const float *x, int n, int sr, float *f0, double *t0);

#endif
