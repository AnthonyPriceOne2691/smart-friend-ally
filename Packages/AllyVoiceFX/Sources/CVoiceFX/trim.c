// The speech of a sentence between the synthesis's own silence (voice-tuning): in C because the phone runs the Debug
// build, and the same loop in unoptimized Swift took 34 ms a sentence on the Mac.
#include <math.h>

#include "voicefx.h"

void ally_speech_span(const float *x, int n, int sr, double floor_db, double head, double tail, int *start, int *end) {
    int frame = sr / 100 > 1 ? sr / 100 : 1, frames = n / frame, first = -1, last = -1;
    double peak = 0;
    *start = 0;
    *end = n;
    for (int k = 0; k < n; k++) peak = fmax(peak, fabs((double)x[k]));
    double level = peak * pow(10.0, floor_db / 20), floor_energy = level * level * frame;
    for (int f = 0; f < frames; f++) {
        double energy = 0;
        for (int k = f * frame; k < (f + 1) * frame; k++) energy += (double)x[k] * x[k];
        if (energy > floor_energy) {
            first = first < 0 ? f : first;
            last = f;
        }
    }
    if (first < 0) return;
    int before = first * frame - (int)(head * sr), after = (last + 1) * frame + (int)(tail * sr);
    *start = before > 0 ? before : 0;
    *end = after < n ? after : n;
}
