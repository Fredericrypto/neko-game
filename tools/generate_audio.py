#!/usr/bin/env python3
"""Gera os efeitos e ambiências do protótipo (síntese própria, sem amostras externas).
Saída: assets/audio/*.wav (mono, 32 kHz, 16 bit). Sons propositalmente suaves (AUDIO_BIBLE)."""
import wave, numpy as np, os
SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(1118)

def lp(x, a):                      # filtro passa-baixa de um polo
    y = np.zeros_like(x); s = 0.0
    for i, v in enumerate(x):
        s += a * (v - s); y[i] = s
    return y

def hp(x, a):
    return x - lp(x, a)

def env_exp(n, tau):
    return np.exp(-np.arange(n) / (tau * SR))

def save(name, x, peak=0.8):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    pcm = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())

def fade(x, n=96):
    x = x.copy(); n = min(n, len(x) // 2)
    x[:n] *= np.linspace(0, 1, n); x[-n:] *= np.linspace(1, 0, n); return x

t = lambda d: np.arange(int(d * SR)) / SR

# passos (3 variações): estalo macio + corpo grave
for i, (f0, tau) in enumerate([(150, 0.020), (135, 0.024), (165, 0.018)]):
    tt = t(0.12)
    noise = lp(rng.standard_normal(len(tt)), 0.18) * env_exp(len(tt), tau)
    body = np.sin(2 * np.pi * f0 * tt) * env_exp(len(tt), 0.025) * 0.7
    save(f"step_{i+1}.wav", fade(noise * 0.9 + body), 0.55)

# pulo: sopro ascendente suave
tt = t(0.20)
sweep = np.sin(2 * np.pi * np.cumsum(260 + 260 * (tt / 0.2) ** 1.4) / SR)
air = lp(rng.standard_normal(len(tt)), 0.25) * 0.6
win = np.sin(np.pi * tt / 0.2) ** 1.5
save("jump.wav", fade((sweep * 0.5 + air) * win), 0.6)

# aterrissagem: baque grave + sopro
tt = t(0.30)
thump = np.sin(2 * np.pi * np.cumsum(120 * np.exp(-tt * 9) + 45) / SR) * env_exp(len(tt), 0.07)
puff = lp(rng.standard_normal(len(tt)), 0.12) * env_exp(len(tt), 0.04) * 0.5
save("land.wav", fade(thump + puff), 0.8)

# comer: três mordidas crocantes
tt = t(0.30); x = np.zeros(len(tt))
for k, st in enumerate([0.0, 0.08, 0.16]):
    n = int(0.05 * SR); i0 = int(st * SR)
    b = hp(lp(rng.standard_normal(n), 0.55), 0.08) * env_exp(n, 0.012)
    x[i0:i0 + n] += b * (1.0 - 0.18 * k)
save("eat.wav", fade(x), 0.6)

# porta: rangido grave filtrado
tt = t(0.55)
f = 98 - 30 * (tt / 0.55) + 3 * np.sin(2 * np.pi * 9 * tt)
saw = 2 * ((np.cumsum(f) / SR) % 1.0) - 1.0
creak = lp(saw, 0.07) * np.sin(np.pi * tt / 0.55) ** 1.2
save("door.wav", fade(creak), 0.6)

# ambiência da cidade: ruído grave + rumor de tráfego distante, com loop sem emenda
D = 12.0; n = int(D * SR); tt = np.arange(n) / SR
base = lp(lp(rng.standard_normal(n), 0.020), 0.05)
rumble = np.sin(2 * np.pi * 52 * tt + 0.8 * np.sin(2 * np.pi * 0.11 * tt)) * (0.5 + 0.5 * np.sin(2 * np.pi * tt / D * 2))
air = hp(lp(rng.standard_normal(n), 0.35), 0.01) * 0.04
x = base * 6.0 + rumble * 0.25 + air
xf = int(1.5 * SR)                       # crossfade circular
w = np.linspace(0, 1, xf)
x[:xf] = x[:xf] * w + x[-xf:] * (1 - w)
x = x[:-xf]
save("ambience_city.wav", x - np.mean(x), 0.5)

# vento: faixa média com ondulação lenta periódica
D = 9.0; n = int(D * SR); tt = np.arange(n) / SR
w = hp(lp(rng.standard_normal(n), 0.09), 0.012)
swell = (0.35 + 0.65 * np.sin(np.pi * tt / D) ** 2) * (0.7 + 0.3 * np.sin(2 * np.pi * 3 * tt / D))
x = w * swell
xf = int(1.2 * SR); ww = np.linspace(0, 1, xf)
x[:xf] = x[:xf] * ww + x[-xf:] * (1 - ww); x = x[:-xf]
save("wind.wav", x - np.mean(x), 0.5)
print("áudio gerado em", os.path.abspath(OUT))
