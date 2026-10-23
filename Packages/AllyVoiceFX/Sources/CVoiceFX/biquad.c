// One biquad section in transposed direct form II, as scipy's sosfilt.
#include "biquad.h"

void ally_biquad_run(float *x, int n, const double c[5], int backward) {
    double z1 = 0, z2 = 0;
    for (int k = 0; k < n; k++) {
        int i = backward ? n - 1 - k : k;
        double in = x[i], out = c[0] * in + z1;
        z1 = c[1] * in - c[3] * out + z2;
        z2 = c[2] * in - c[4] * out;
        x[i] = (float)out;
    }
}
