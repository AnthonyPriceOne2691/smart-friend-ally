// TD-PSOLA of the voice-samples-2 stand (scripts/dsp.py, round 3): analysis marks on the dominant-polarity peaks of
// the 900 Hz low-passed signal, two-period Hann grains laid out at the target period, 5 ms grains in unvoiced
// stretches. Formants move by resampling first (8-tap windowed sinc of the stand's psola_c); PSOLA then sets the
// pitch and restores the duration. Then the stand's 0.97 peak guard; the chain's EQ arrives with V4b.
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "biquad.h"
#include "voicefx.h"

#define STEP 0.005

typedef struct { int pos, per, voiced; } Mark;

typedef struct {
    const float *x;
    int n, sr, nm, cap;
    float *fi;          // F0 at every sample, Hz
    unsigned char *vm;  // voiced at every sample
    Mark *m;
} Track;

// out[k] = x(k * step), 8-tap Hann-windowed sinc with the cutoff at the lower Nyquist.
static float *resample(const float *x, int n, double step, int *nout) {
    int m = (int)floor((n - 1) / step);
    float *y = malloc(sizeof(float) * (size_t)(m + 1));
    double fc = step > 1.0 ? 1.0 / step : 1.0;
    for (int k = 0; y && k <= m; k++) {
        double t = k * step, acc = 0, ws = 0;
        int i0 = (int)floor(t);
        for (int i = i0 - 3 > 0 ? i0 - 3 : 0; i <= i0 + 4 && i < n; i++) {
            double d = t - i;
            double s = fabs(d) < 1e-9 ? 1.0 : sin(ALLY_PI * fc * d) / (ALLY_PI * fc * d);
            double w = 0.5 + 0.5 * cos(ALLY_PI * d / 4.5);
            acc += x[i] * s * w;
            ws += s * w;
        }
        y[k] = (float)(ws != 0 ? acc / ws : 0);
    }
    *nout = m + 1;
    return y;
}

// 4th-order Butterworth low-pass at 900 Hz as two sections, forward then backward (zero phase, as sosfiltfilt).
static void lowpass900(float *y, int n, int sr) {
    static const double qs[2] = {0.54119610014619698, 1.3065629648763766};
    double w0 = 2 * ALLY_PI * 900.0 / sr, cw = cos(w0);
    for (int pass = 0; pass < 2; pass++) {
        for (int s = 0; s < 2; s++) {
            double al = sin(w0) / (2 * qs[s]), a0 = 1 + al;
            double c[5] = {(1 - cw) / 2 / a0, (1 - cw) / a0, (1 - cw) / 2 / a0, -2 * cw / a0, (1 - al) / a0};
            ally_biquad_run(y, n, c, pass);
        }
    }
}

// F0 and the voiced flag at every sample, linear between frame centres, 0 outside them (np.interp of the stand).
static int track_init(Track *tr) {
    int nfr = ally_pitch_frames(tr->n, tr->sr);
    float *f0 = malloc(sizeof(float) * (size_t)nfr);
    double t0 = 0;
    tr->fi = malloc(sizeof(float) * (size_t)tr->n);
    tr->vm = malloc((size_t)tr->n);
    if (!f0 || !tr->fi || !tr->vm || ally_pitch_track(tr->x, tr->n, tr->sr, f0, &t0) < 0) {
        free(f0);
        return -1;
    }
    for (int k = 0; k < tr->n; k++) {
        double p = ((double)k / tr->sr - t0) / STEP, f = 0, v = 0;
        int i = (int)floor(p);
        if (p >= 0 && i < nfr - 1) {
            f = f0[i] * (i + 1 - p) + f0[i + 1] * (p - i);
            v = (f0[i] > 0) * (i + 1 - p) + (f0[i + 1] > 0) * (p - i);
        }
        tr->fi[k] = (float)f;
        tr->vm[k] = v > 0.5 && f > 0;
    }
    free(f0);
    return 0;
}

static int push_mark(Track *tr, int pos, int per, int voiced) {
    if (tr->nm == tr->cap) {
        int cap = tr->cap * 2 + 64;
        Mark *m = realloc(tr->m, sizeof(Mark) * (size_t)cap);
        if (!m) return -1;
        tr->m = m;
        tr->cap = cap;
    }
    tr->m[tr->nm++] = (Mark){pos, per, voiced};
    return 0;
}

static int argmax(const float *y, int lo, int hi, double pol) {
    int best = lo;
    for (int j = lo + 1; j < hi; j++) best = pol * y[j] > pol * y[best] ? j : best;
    return best;
}

// Voiced stretch [s, e): the first mark on the strongest peak within a period, then one per period, each searched
// in [0.7, 1.3] of the local period after the previous one.
static int voiced_marks(Track *tr, const float *y, int s, int e) {
    double mx = 0, mn = 0;
    for (int k = s; k < e; k++) {
        mx = fmax(mx, y[k]);
        mn = fmin(mn, y[k]);
    }
    double pol = mx >= -mn ? 1.0 : -1.0;
    int per = (int)lround(tr->sr / tr->fi[s]);
    int k = argmax(y, s, e < s + per ? e : s + per, pol);
    while (k < e) {
        per = (int)lround(tr->sr / fmax(tr->fi[k], 50.0));
        if (push_mark(tr, k, per, 1) < 0) return -1;
        int lo = k + (int)(0.7 * per), hi = k + (int)(1.3 * per) + 1;
        hi = hi < e ? hi : e;
        if (hi - lo < 2) break;
        k = argmax(y, lo, hi, pol);
    }
    return 0;
}

static int uv_step(int sr) {
    int u = (int)(STEP * sr);
    return u > 1 ? u : 1;
}

// Unvoiced stretches get a mark every 5 ms.
static int find_marks(Track *tr, const float *y) {
    int uv = uv_step(tr->sr), e;
    for (int k = 0; k < tr->n; k = e) {
        for (e = k; e < tr->n && tr->vm[e] == tr->vm[k]; e++) {}
        if (tr->vm[k]) {
            if (voiced_marks(tr, y, k, e) < 0) return -1;
            continue;
        }
        for (int j = k; j < e; j += uv)
            if (push_mark(tr, j, uv, 0) < 0) return -1;
    }
    return 0;
}

// Grain of 2 * half samples around c with the Hann window of the stand (np.hanning(2 half + 2)[1:-1]), laid at pos.
static void add_grain(const Track *tr, int c, int half, int pos, float *y, float *ws, int ny) {
    for (int m = 0; m < 2 * half; m++) {
        int src = c - half + m, dst = pos + m;
        if (dst < 0 || dst >= ny) continue;
        float w = (float)(0.5 - 0.5 * cos(2 * ALLY_PI * (m + 1) / (2 * half + 1)));
        y[dst] += (src >= 0 && src < tr->n ? tr->x[src] : 0.0f) * w;
        ws[dst] += w;
    }
}

// Nearest analysis mark to ta; *j is the search start, it only grows because ta does.
static const Mark *nearest_mark(const Track *tr, double ta, int *j) {
    while (*j < tr->nm && tr->m[*j].pos < ta) (*j)++;
    int k = *j < tr->nm ? *j : tr->nm - 1;
    if (k > 0 && fabs(tr->m[k - 1].pos - ta) < fabs(tr->m[k].pos - ta)) k--;
    return &tr->m[k];
}

// pf: F0 multiplier, tf: output / input duration. Returns no = round(n * tf) samples.
static float *overlap_add(const Track *tr, double pf, double tf, int *nout) {
    int no = (int)lround(tr->n * tf), pad = tr->sr / 25, ny = no + 2 * pad, uv = uv_step(tr->sr), j = 0;
    float *y = calloc((size_t)ny, sizeof(float)), *ws = calloc((size_t)ny, sizeof(float));
    if (!y || !ws) {
        free(y);
        free(ws);
        return NULL;
    }
    for (double ts = 0; ts < no;) {
        const Mark *mk = nearest_mark(tr, ts / tf, &j);
        double pout = uv;
        int half = uv, c = (int)lround(ts / tf);
        if (mk->voiced) {
            double fh = tr->fi[mk->pos] > 0 ? tr->fi[mk->pos] : (double)tr->sr / mk->per;
            pout = tr->sr / (pf * fh);
            half = (int)fmin(mk->per, pout) > 8 ? (int)fmin(mk->per, pout) : 8;
            c = mk->pos;
        }
        add_grain(tr, c, half, (int)lround(ts) - half + pad, y, ws, ny);
        ts += pout;
    }
    for (int k = 0; k < no; k++) y[k] = y[k + pad] / fmaxf(ws[k + pad], 0.5f);
    free(ws);
    *nout = no;
    return y;
}

static float *psola(const float *x, int n, int sr, double pf, double tf, int *nout) {
    Track tr = {.x = x, .n = n, .sr = sr};
    float *y = malloc(sizeof(float) * (size_t)n), *out = NULL;
    if (y && track_init(&tr) == 0) {
        memcpy(y, x, sizeof(float) * (size_t)n);
        lowpass900(y, n, sr);
        if (find_marks(&tr, y) == 0 && tr.nm > 0) out = overlap_add(&tr, pf, tf, nout);
    }
    free(y);
    free(tr.fi);
    free(tr.vm);
    free(tr.m);
    return out;
}

static void peak_guard(float *x, int n) {
    float m = 0;
    for (int k = 0; k < n; k++) m = fmaxf(m, fabsf(x[k]));
    for (int k = 0; m > 0.97f && k < n; k++) x[k] *= 0.97f / m;
}

int ally_fx_process(const float *x, int n, int sr, double pitch_st, double formant_st, float *out) {
    if (sr <= 0 || n < 0) return -1;
    if (n == 0) return 0;
    double beta = pow(2.0, pitch_st / 12), alpha = pow(2.0, formant_st / 12);
    int nr = n, no = 0;
    float *xr = alpha != 1.0 ? resample(x, n, alpha, &nr) : NULL;
    float *y = (alpha == 1.0 || xr) ? psola(xr ? xr : x, nr, sr, beta / alpha, alpha, &no) : NULL;
    free(xr);
    if (!y) return -1;
    int keep = no < n ? no : n;
    memcpy(out, y, sizeof(float) * (size_t)keep);
    memset(out + keep, 0, sizeof(float) * (size_t)(n - keep));
    free(y);
    peak_guard(out, n);
    return 0;
}
