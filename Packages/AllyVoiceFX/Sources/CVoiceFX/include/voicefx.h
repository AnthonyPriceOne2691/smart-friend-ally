// Voice processing after synthesis (voice series V4a, V4b1): TD-PSOLA pitch and formant shift, then an RBJ biquad EQ —
// the chain of the voice-samples-2 stand the parent chose in round 3. Plain C, no platform code.
#ifndef ALLY_VOICEFX_H
#define ALLY_VOICEFX_H

enum { ALLY_EQ_LOW_SHELF = 0, ALLY_EQ_PEAK = 1, ALLY_EQ_HIGH_SHELF = 2 };

typedef struct {
    int kind;
    double freq;
    double gain_db;
    double q;
} AllyEQBand;

/// Samples ally_fx_process writes for n input samples at this stretch.
int ally_fx_length(int n, double stretch);

/// Pitch and formant shift in semitones, the duration times `stretch`, the F0 span around the sentence's median times
/// `range` (both positive, VoiceFX refuses others), then the EQ cascade and the stand's 0.97 peak guard. Writes
/// ally_fx_length(n, stretch) samples to out. Returns 0, or -1 when memory runs out or sr is not positive.
int ally_fx_process(const float *x, int n, int sr, double pitch_st, double formant_st, double stretch, double range,
                    const AllyEQBand *bands, int nbands, float *out);

/// The EQ cascade in place.
void ally_eq(float *x, int n, int sr, const AllyEQBand *bands, int nbands);

/// The speech between the sentence's ends: 10 ms frames above floor_db of the peak, head and tail seconds of margin.
/// [*start, *end) is the whole of it when no frame rises above the floor.
void ally_speech_span(const float *x, int n, int sr, double floor_db, double head, double tail, int *start, int *end);

/// Frames of the pitch track for n samples at sr: one per 5 ms.
int ally_pitch_frames(int n, int sr);

/// Own autocorrelation pitch track: f0[i] in Hz, 0 = unvoiced; frame i is centred at *t0 + i * 0.005 s.
/// f0 holds ally_pitch_frames(n, sr) values. Returns the frame count, or -1 when memory runs out.
int ally_pitch_track(const float *x, int n, int sr, float *f0, double *t0);

#endif
