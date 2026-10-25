// One biquad section, shared by the pitch-mark low-pass and the EQ: c = {b0, b1, b2, a1, a2}, a0 = 1.
#ifndef ALLY_BIQUAD_H
#define ALLY_BIQUAD_H

#define ALLY_PI 3.14159265358979323846

/// Transposed direct form II, in place; backward = 1 runs from the last sample to the first.
void ally_biquad_run(float *x, int n, const double c[5], int backward);

#endif
