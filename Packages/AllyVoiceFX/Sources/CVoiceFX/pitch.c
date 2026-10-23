// Own autocorrelation pitch tracker by the published method: P. Boersma (1993), "Accurate short-term analysis of the
// fundamental frequency and the harmonics-to-noise ratio of a sampled sound". Parameters are the ones the stand gave
// Praat in round 3: 5 ms step, 70–700 Hz, 15 candidates, silence 0.03, voicing 0.45, octave 0.01, octave jump 0.35,
// voiced/unvoiced 0.14, path costs × 0.01 / step. Praat's code is not used (GPL). The tracker runs on the signal
// decimated by 4 (31-tap windowed sinc, as the stand's psola_c): the period range needs nothing above 5 kHz.
#include <math.h>
#include <stdlib.h>

#include "biquad.h"
#include "voicefx.h"

#define STEP 0.005
#define FLOOR_HZ 70.0
#define CEIL_HZ 700.0
#define MAXC 15
#define SILENCE 0.03
#define VOICING 0.45
#define OCTAVE 0.01
#define JUMP 0.35
#define VUV 0.14
#define DECIM 4
#define TAPS 31

typedef struct { float f, s; } Cand;  // f == 0: the unvoiced candidate

typedef struct {
    int nw, minlag, maxlag, nfr;
    double sr2, t1, gpeak;
    float *w;    // Hann window of three periods of the floor
    double *rw;  // its normalized autocorrelation
} Frames;

static float *decimate(const float *x, int n, int *n2) {
    float h[TAPS];
    double fc = 0.9 / DECIM, hs = 0;
    for (int j = 0; j < TAPS; j++) {
        int k = j - TAPS / 2;
        double s = k == 0 ? 2 * fc : sin(2 * ALLY_PI * fc * k) / (ALLY_PI * k);
        h[j] = (float)(s * (0.5 - 0.5 * cos(2 * ALLY_PI * j / (TAPS - 1))));
        hs += h[j];
    }
    *n2 = n / DECIM;
    float *d = malloc(sizeof(float) * (size_t)(*n2 + 1));
    for (int i = 0; d && i < *n2; i++) {
        double acc = 0;
        for (int j = 0; j < TAPS; j++) {
            int k = i * DECIM + j - TAPS / 2;
            if (k >= 0 && k < n) acc += h[j] * x[k];
        }
        d[i] = (float)(acc / hs);
    }
    return d;
}

static int frame_count(double dur, double win) {
    int k = (int)((dur - win) / STEP) + 1;
    return k > 1 ? k : 1;
}

static double global_peak(const float *d, int n2) {
    double mean = 0, peak = 1e-12;
    for (int i = 0; i < n2; i++) mean += d[i];
    mean = n2 > 0 ? mean / n2 : 0;
    for (int i = 0; i < n2; i++) peak = fmax(peak, fabs(d[i] - mean));
    return peak;
}

static int frames_init(Frames *g, const float *d, int n2, int sr) {
    g->sr2 = sr / (double)DECIM;
    g->nw = (int)lround(3.0 / FLOOR_HZ * g->sr2);
    g->maxlag = (int)(g->sr2 / FLOOR_HZ) + 2;
    g->minlag = (int)(g->sr2 / CEIL_HZ) > 2 ? (int)(g->sr2 / CEIL_HZ) : 2;
    g->w = malloc(sizeof(float) * (size_t)g->nw);
    g->rw = malloc(sizeof(double) * (size_t)(g->maxlag + 1));
    if (!g->w || !g->rw) return -1;
    for (int j = 0; j < g->nw; j++) g->w[j] = (float)(0.5 - 0.5 * cos(2 * ALLY_PI * (j + 1) / (g->nw + 1)));
    for (int t = 0; t <= g->maxlag; t++) {
        double acc = 0;
        for (int j = 0; j + t < g->nw; j++) acc += (double)g->w[j] * g->w[j + t];
        g->rw[t] = acc;
    }
    double r0 = g->rw[0];
    for (int t = 0; t <= g->maxlag; t++) g->rw[t] /= r0;
    g->gpeak = global_peak(d, n2);
    double dur = n2 / g->sr2, win = g->nw / g->sr2;
    g->nfr = frame_count(dur, win);
    g->t1 = (dur - win - (g->nfr - 1) * STEP) / 2 + win / 2;
    return 0;
}

// Autocorrelation of frame i divided by the window's (r[0] = 1 when the frame is not silent); returns the local peak.
static double frame_r(const Frames *g, const float *d, int n2, int i, float *a, double *r) {
    int st = (int)lround((g->t1 + i * STEP) * g->sr2 - g->nw / 2.0);
    int len = st >= 0 && st + g->nw > n2 ? n2 - st : g->nw;
    double mean = 0, peak = 0, r0;
    if (st < 0 || len <= 0) len = 0;
    for (int j = 0; j < len; j++) mean += d[st + j];
    mean = len > 0 ? mean / len : 0;
    for (int j = 0; j < len; j++) {
        double v = d[st + j] - mean;
        peak = fmax(peak, fabs(v));
        a[j] = (float)(v * g->w[j]);
    }
    for (int t = 0; t <= g->maxlag; t++) {
        double acc = 0;
        for (int j = 0; j + t < len; j++) acc += (double)a[j] * a[j + t];
        r[t] = acc;
    }
    r0 = r[0];
    for (int t = 0; t <= g->maxlag; t++) r[t] = r0 > 0 ? r[t] / r0 / g->rw[t] : 0;
    return peak;
}

// Keeps the voiced candidates c[1..] sorted by strength, at most MAXC - 1 of them.
static int keep_best(Cand *c, int cnt, Cand v) {
    if (cnt == MAXC) {
        if (v.s <= c[MAXC - 1].s) return cnt;
        cnt--;
    }
    int pos = cnt;
    while (pos > 1 && c[pos - 1].s < v.s) {
        c[pos] = c[pos - 1];
        pos--;
    }
    c[pos] = v;
    return cnt + 1;
}

static int frame_cands(const Frames *g, const double *r, double lpeak, Cand *c) {
    double uv = VOICING + fmax(0.0, 2.0 - (lpeak / g->gpeak) / (SILENCE / (1.0 + VOICING)));
    int cnt = 1;
    c[0] = (Cand){0.0f, (float)uv};
    for (int t = g->minlag; t < g->maxlag; t++) {
        if (!(r[t] > 0.5 * VOICING && r[t] > r[t - 1] && r[t] >= r[t + 1])) continue;
        double den = r[t - 1] - 2 * r[t] + r[t + 1];
        double dl = den != 0 ? 0.5 * (r[t - 1] - r[t + 1]) / den : 0;
        double rv = fmin(1.0, r[t] - 0.25 * (r[t - 1] - r[t + 1]) * dl), lag = t + dl;
        Cand v = {(float)(g->sr2 / lag), (float)(rv - OCTAVE * log2(FLOOR_HZ * lag / g->sr2))};
        cnt = keep_best(c, cnt, v);
    }
    return cnt;
}

static double transition(float fa, float fb) {
    double k = 0.01 / STEP;
    if (fa == 0 && fb == 0) return 0;
    if (fa == 0 || fb == 0) return VUV * k;
    return JUMP * k * fabs(log2((double)fa / fb));
}

// Viterbi over the candidates: the most strength minus the transition costs.
static void best_path(const Cand *c, const int *cnt, int nfr, unsigned char *back, float *f0) {
    double score[MAXC], next[MAXC];
    for (int j = 0; j < cnt[0]; j++) score[j] = c[j].s;
    for (int i = 1; i < nfr; i++) {
        const Cand *pc = c + (size_t)(i - 1) * MAXC, *cc = c + (size_t)i * MAXC;
        for (int b = 0; b < cnt[i]; b++) {
            int arg = 0;
            double best = score[0] - transition(pc[0].f, cc[b].f);
            for (int a = 1; a < cnt[i - 1]; a++) {
                double v = score[a] - transition(pc[a].f, cc[b].f);
                if (v > best) best = v, arg = a;
            }
            next[b] = best + cc[b].s;
            back[(size_t)i * MAXC + b] = (unsigned char)arg;
        }
        for (int b = 0; b < cnt[i]; b++) score[b] = next[b];
    }
    int j = 0;
    for (int b = 1; b < cnt[nfr - 1]; b++) j = score[b] > score[j] ? b : j;
    for (int i = nfr - 1; i >= 0; i--) {
        f0[i] = c[(size_t)i * MAXC + j].f;
        j = i > 0 ? back[(size_t)i * MAXC + j] : 0;
    }
}

int ally_pitch_frames(int n, int sr) {
    if (sr <= 0 || n < 0) return 0;
    double sr2 = sr / (double)DECIM;
    return frame_count((n / DECIM) / sr2, lround(3.0 / FLOOR_HZ * sr2) / sr2);
}

int ally_pitch_track(const float *x, int n, int sr, float *f0, double *t0) {
    if (sr <= 0 || n < 0) return -1;
    int n2 = 0, rc = -1;
    Frames g = {0};
    float *d = decimate(x, n, &n2), *a = NULL;
    double *r = NULL;
    Cand *c = NULL;
    int *cnt = NULL;
    unsigned char *back = NULL;
    if (d && frames_init(&g, d, n2, sr) == 0) {
        a = malloc(sizeof(float) * (size_t)g.nw);
        r = malloc(sizeof(double) * (size_t)(g.maxlag + 1));
        c = malloc(sizeof(Cand) * (size_t)g.nfr * MAXC);
        cnt = malloc(sizeof(int) * (size_t)g.nfr);
        back = malloc((size_t)g.nfr * MAXC);
    }
    if (a && r && c && cnt && back) {
        for (int i = 0; i < g.nfr; i++) cnt[i] = frame_cands(&g, r, frame_r(&g, d, n2, i, a, r), c + (size_t)i * MAXC);
        best_path(c, cnt, g.nfr, back, f0);
        *t0 = g.t1;
        rc = g.nfr;
    }
    free(d);
    free(a);
    free(r);
    free(c);
    free(cnt);
    free(back);
    free(g.w);
    free(g.rw);
    return rc;
}
