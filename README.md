# DSP Lab Project Documentation
We are making a sound equalizer and white noise eliminator

An end-to-end digital signal processing audio cleaning and parametric equalization system in MATLAB.

## Quick Links
- **[Comprehensive Project Documentation & Architecture Diagrams](file:///d:/DSP_Project/DSPlab/PROJECT_DOCUMENTATION.md)**

## Pipeline Features
- **Spectral Denoising (`spectralDenoise.m`)**: Short-Time Fourier Transform (STFT) spectral subtraction to remove background hiss/white noise.
- **Mains Hum Elimination (`notchfilter.m`)**: 2nd-order IIR notch filter tuned to 50 Hz with high selectivity ($Q=30$).
- **5-Band Parametric Equalizer (`peakingEQ.m`)**: Biquad IIR filters targeting sub-bass, bass, mid, high-mid, and treble.
- **Audio Loading & Preprocessing (`step1_load.m`)**: Stereo-to-mono downmixing and level normalization.
- **Master Pipeline (`step3_full.m`)**: Complete automated batch processing script.
- **MATLAB App (`AudioEqualixerApp.mlapp`)**: Interactive GUI interface.

## Quick Run
In MATLAB Command Window:
```matlab
% 1. Load and listen to test audio
step1_load

% 2. Run the 5-band equalizer
step2_eq

% 3. Run full Denoise + Notch + Equalizer pipeline
step3_full
```
Refer to [`PROJECT_DOCUMENTATION.md`](file:///d:/DSP_Project/DSPlab/PROJECT_DOCUMENTATION.md) for full mathematical formulas, diagrams, and execution options.
