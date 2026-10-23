// RBJ cookbook biquads in cascade — the formulas of the stand's dsp.py, nothing more.
#include <math.h>

#include "biquad.h"
#include "voicefx.h"

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

static void coefficients(const AllyEQBand *band, int sr, double c[5]) {
    double A = pow(10.0, band->gain_db / 40.0), w0 = 2 * ALLY_PI * band->freq / sr;
    double cw = cos(w0), al = sin(w0) / (2 * band->q), sa = 2 * sqrt(A) * al;
    double b[3], a[3];
    if (band->kind == ALLY_EQ_LOW_SHELF) {
        b[0] = A * ((A + 1) - (A - 1) * cw + sa), b[1] = 2 * A * ((A - 1) - (A + 1) * cw);
        b[2] = A * ((A + 1) - (A - 1) * cw - sa);
        a[0] = (A + 1) + (A - 1) * cw + sa, a[1] = -2 * ((A - 1) + (A + 1) * cw), a[2] = (A + 1) + (A - 1) * cw - sa;
    } else if (band->kind == ALLY_EQ_HIGH_SHELF) {
        b[0] = A * ((A + 1) + (A - 1) * cw + sa), b[1] = -2 * A * ((A - 1) + (A + 1) * cw);
        b[2] = A * ((A + 1) + (A - 1) * cw - sa);
        a[0] = (A + 1) - (A - 1) * cw + sa, a[1] = 2 * ((A - 1) - (A + 1) * cw), a[2] = (A + 1) - (A - 1) * cw - sa;
    } else {
        b[0] = 1 + al * A, b[1] = -2 * cw, b[2] = 1 - al * A;
        a[0] = 1 + al / A, a[1] = -2 * cw, a[2] = 1 - al / A;
    }
    c[0] = b[0] / a[0], c[1] = b[1] / a[0], c[2] = b[2] / a[0], c[3] = a[1] / a[0], c[4] = a[2] / a[0];
}

void ally_eq(float *x, int n, int sr, const AllyEQBand *bands, int nbands) {
    for (int k = 0; k < nbands; k++) {
        double c[5];
        coefficients(&bands[k], sr, c);
        ally_biquad_run(x, n, c, 0);
    }
}
