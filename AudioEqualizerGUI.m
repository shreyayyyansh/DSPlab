function AudioEqualizerGUI()
    % AudioEqualizerGUI - Interactive DSP Audio Equalizer & Noise Eliminator
    % Features:
    % - Real-time audioplayer with live parameter updates while audio is playing
    % - Adaptive frequency bands based on sampling rate (Nyquist awareness)
    % - Real-time Time & Frequency (FFT) visual analyzers
    % - Seamless A/B comparison (Original Noisy vs Processed Clean)
    % - Built-in generator for realistic noisy demo audio (50Hz hum + white noise)

    % Shared Application State
    data.x_orig = [];
    data.fs = 8192;
    data.y_proc = [];
    data.player = [];
    data.isPlaying = false;
    data.isLooping = false;
    data.bandFreqs = [80, 300, 1000, 2000, 3500];
    data.bandLabels = {'Sub-Bass', 'Low-Mid', 'Midrange', 'High-Mid', 'Treble'};
    
    % Main Figure Window
    fig = uifigure('Name', 'DSP Audio Equalizer & White Noise Eliminator', ...
                   'Position', [100 60 1020 720], ...
                   'Color', [0.11 0.13 0.17], ...
                   'CloseRequestFcn', @(src, event) onCloseFigure());

    % Main Grid: Top Controls, Middle Sliders, Bottom Waveform/Plots
    mainGrid = uigridlayout(fig, [4, 1]);
    mainGrid.RowHeight = {130, 85, 240, '1x'};
    mainGrid.BackgroundColor = [0.11 0.13 0.17];

    % =========================================================================
    % SECTION 1: TOP TOOLBAR (File Load, Toggles, Playback Actions)
    % =========================================================================
    topPanel = uipanel(mainGrid, 'Title', 'Control Panel & Interactive Filter Toggles', ...
                       'BackgroundColor', [0.15 0.18 0.23], ...
                       'ForegroundColor', [0.9 0.92 0.95], ...
                       'FontWeight', 'bold', 'FontSize', 12);
    topGrid = uigridlayout(topPanel, [2, 5]);
    topGrid.ColumnWidth = {'1.1x', '1.2x', '1.2x', '0.8x', '1.1x'};
    topGrid.RowHeight = {38, 38};
    topGrid.Padding = [10 8 10 8];

    % Row 1: Primary Actions
    btnLoad = uibutton(topGrid, 'Text', '📁 Load Audio', ...
        'BackgroundColor', [0.2 0.45 0.75], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(btn, event) onLoadAudio());

    btnPlayOrig = uibutton(topGrid, 'Text', '▶ Play Original (Noisy)', ...
        'BackgroundColor', [0.25 0.55 0.35], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(btn, event) onPlayOriginal());

    btnPlayClean = uibutton(topGrid, 'Text', '🔊 Play Clean (Filtered)', ...
        'BackgroundColor', [0.85 0.45 0.15], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(btn, event) onPlayClean());

    btnStop = uibutton(topGrid, 'Text', '⏹ Stop', ...
        'BackgroundColor', [0.7 0.22 0.22], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(btn, event) onStopAudio());

    btnDemoAudio = uibutton(topGrid, 'Text', '⚡ Generate Demo Noise', ...
        'BackgroundColor', [0.4 0.3 0.6], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(btn, event) onGenerateDemoAudio());

    % Row 2: High-Visibility State Toggle Buttons (Impossible to truncate or hide)
    tglDenoise = uibutton(topGrid, 'state', ...
        'Text', '✓ Denoise: ON', ...
        'Value', true, ...
        'BackgroundColor', [0.12 0.55 0.3], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 12, ...
        'ValueChangedFcn', @(btn, event) onDenoiseBtnToggled(btn));

    tglNotch = uibutton(topGrid, 'state', ...
        'Text', '✓ 50/100Hz Notch: ON', ...
        'Value', true, ...
        'BackgroundColor', [0.12 0.55 0.3], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 12, ...
        'ValueChangedFcn', @(btn, event) onNotchBtnToggled(btn));

    tglLoop = uibutton(topGrid, 'state', ...
        'Text', '🔁 Loop: OFF', ...
        'Value', false, ...
        'BackgroundColor', [0.3 0.34 0.4], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 12, ...
        'ValueChangedFcn', @(btn, event) onLoopBtnToggled(btn));

    btnSave = uibutton(topGrid, 'Text', '💾 Save WAV', ...
        'BackgroundColor', [0.3 0.35 0.45], 'FontColor', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'ButtonPushedFcn', @(btn, event) onSaveAudio());

    lblStatus = uilabel(topGrid, 'Text', '● Ready. Audio loaded.', ...
                        'FontColor', [0.4 0.95 0.6], 'FontWeight', 'bold', 'FontSize', 11);

    % =========================================================================
    % SECTION 2: ADDITIONAL DSP FILTERS
    % =========================================================================

    filterPanel = uipanel(mainGrid, ...
        'Title', 'Additional DSP Filters', ...
        'BackgroundColor', [0.15 0.18 0.23], ...
        'ForegroundColor', [0.9 0.92 0.95], ...
        'FontWeight', 'bold', ...
        'FontSize', 12);

    filterGrid = uigridlayout(filterPanel, [1, 4]);

    filterGrid.ColumnWidth = {'1.2x', '1x', '1.2x', '1x'};
    filterGrid.Padding = [10 8 10 8];

    % -------------------------------------------------------------------------
    % HIGH-PASS FILTER
    % -------------------------------------------------------------------------

    tglHPF = uibutton(filterGrid, 'state', ...
        'Text', 'HPF: OFF', ...
        'Value', false, ...
        'BackgroundColor', [0.32 0.35 0.40], ...
        'FontColor', 'white', ...
        'FontWeight', 'bold', ...
        'FontSize', 11, ...
        'ValueChangedFcn', @(btn,event) onHPFToggled(btn));

    ddHPF = uidropdown(filterGrid, ...
        'Items', {'40 Hz','60 Hz','80 Hz','100 Hz'}, ...
        'ItemsData', [40 60 80 100], ...
        'Value', 80, ...
        'FontWeight', 'bold', ...
        'ValueChangedFcn', @(dd,event) onParamChanged());

    % -------------------------------------------------------------------------
    % LOW-PASS FILTER
    % -------------------------------------------------------------------------

    tglLPF = uibutton(filterGrid, 'state', ...
        'Text', 'LPF: OFF', ...
        'Value', false, ...
        'BackgroundColor', [0.32 0.35 0.40], ...
        'FontColor', 'white', ...
        'FontWeight', 'bold', ...
        'FontSize', 11, ...
        'ValueChangedFcn', @(btn,event) onLPFToggled(btn));

    ddLPF = uidropdown(filterGrid, ...
        'Items', {'2 kHz','2.5 kHz','3 kHz','3.5 kHz'}, ...
        'ItemsData', [2000 2500 3000 3500], ...
        'Value', 3500, ...
        'FontWeight', 'bold', ...
        'ValueChangedFcn', @(dd,event) onParamChanged());

    % =========================================================================
    % SECTION 2: EQUALIZER SLIDERS (5 BANDS)
    % =========================================================================
    sliderPanel = uipanel(mainGrid, 'Title', '5-Band Parametric Equalizer (Gain Range: -24 dB to +24 dB)', ...
                          'BackgroundColor', [0.15 0.18 0.23], ...
                          'ForegroundColor', [0.9 0.92 0.95], ...
                          'FontWeight', 'bold', 'FontSize', 12);
    eqGrid = uigridlayout(sliderPanel, [1, 5]);
    eqGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
    eqGrid.Padding = [15 10 15 10];

    defaultGains = [0, -6, 0, 8, 12];
    sliders = cell(1, 5);
    freqLabels = cell(1, 5);
    gainLabels = cell(1, 5);

    for k = 1:5
        bandCol = uigridlayout(eqGrid, [3, 1]);
        bandCol.RowHeight = {32, '1x', 26};
        bandCol.Padding = [0 0 0 0];
        bandCol.BackgroundColor = [0.15 0.18 0.23];

        freqLabels{k} = uilabel(bandCol, 'Text', sprintf('%s\n%d Hz', data.bandLabels{k}, data.bandFreqs(k)), ...
                                'FontColor', [0.85 0.9 0.98], ...
                                'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);

        sliders{k} = uislider(bandCol, 'Orientation', 'vertical', ...
                              'Limits', [-24 24], 'Value', defaultGains(k), ...
                              'MajorTicks', -24:6:24, ...
                              'FontColor', 'white', ...
                              'ValueChangedFcn', @(sld, event) onSliderChanged(k));

        gainLabels{k} = uilabel(bandCol, 'Text', sprintf('%+d dB', round(defaultGains(k))), ...
                                'FontColor', [0.3 0.85 1.0], 'HorizontalAlignment', 'center', ...
                                'FontWeight', 'bold', 'FontSize', 12);
    end

    % =========================================================================
    % SECTION 3: VISUALIZATIONS (Time Domain & Frequency Domain)
    % =========================================================================
    plotPanel = uipanel(mainGrid, 'Title', 'Visual Spectrum & Waveform Analysis', ...
                         'BackgroundColor', [0.15 0.18 0.23], ...
                         'ForegroundColor', [0.9 0.92 0.95], ...
                         'FontWeight', 'bold', 'FontSize', 12);
    plotGrid = uigridlayout(plotPanel, [1, 2]);
    plotGrid.ColumnWidth = {'1x', '1x'};
    plotGrid.Padding = [10 10 10 10];

    axWave = uiaxes(plotGrid);
    axWave.BackgroundColor = [0.08 0.1 0.13];
    axWave.XColor = [0.7 0.7 0.7];
    axWave.YColor = [0.7 0.7 0.7];
    title(axWave, 'Time Domain Waveform', 'Color', 'white');
    xlabel(axWave, 'Time (s)', 'Color', 'white');
    ylabel(axWave, 'Amplitude', 'Color', 'white');
    grid(axWave, 'on');
    axWave.GridColor = [0.25 0.28 0.35];

    axSpec = uiaxes(plotGrid);
    axSpec.BackgroundColor = [0.08 0.1 0.13];
    axSpec.XColor = [0.7 0.7 0.7];
    axSpec.YColor = [0.7 0.7 0.7];
    title(axSpec, 'Frequency Spectrum (FFT)', 'Color', 'white');
    xlabel(axSpec, 'Frequency (Hz)', 'Color', 'white');
    ylabel(axSpec, 'Magnitude (dB)', 'Color', 'white');
    grid(axSpec, 'on');
    axSpec.GridColor = [0.25 0.28 0.35];

    % Auto-load test.wav on start
    loadInitialAudio();

    % =========================================================================
    % CORE LOGIC & CALLBACKS
    % =========================================================================
    function loadInitialAudio()
        audioFile = 'test.wav';
        if exist('test_noisy.wav', 'file')
            audioFile = 'test_noisy.wav';
        end
        if exist(audioFile, 'file')
            try
                [x, fs] = audioread(audioFile);
                setAudio(x, fs, audioFile);
            catch
            end
        end
    end

    function setAudio(x, fs, fileName)
        if size(x, 2) > 1, x = mean(x, 2); end
        data.x_orig = x;
        data.fs = fs;
        updateBandsForFs(fs);
        fig.Name = sprintf('DSP Equalizer - [%s (%d Hz, %.1fs)]', fileName, fs, length(x)/fs);
        processAndPlot();
    end

    function updateBandsForFs(fs)
        if fs <= 11025
            % Low sampling rate (e.g. 8192 Hz, Nyquist = 4096 Hz)
            data.bandFreqs = [80, 300, 1000, 2200, 3600];
            data.bandLabels = {'Sub-Bass', 'Low-Mid', 'Midrange', 'High-Mid', 'Treble'};
        else
            % Standard audio (44.1 kHz / 48 kHz)
            data.bandFreqs = [60, 250, 1000, 4000, 12000];
            data.bandLabels = {'Sub-Bass', 'Low-Mid', 'Midrange', 'High-Mid', 'Treble'};
        end
        for i = 1:5
            freqLabels{i}.Text = sprintf('%s\n%d Hz', data.bandLabels{i}, data.bandFreqs(i));
        end
    end

    % =========================================================================
    % Update LPF cutoff options according to Nyquist frequency
    % =========================================================================

    nyquist = fs / 2;

    if nyquist <= 5000

        % Suitable for 8192 Hz audio
        lpOptions = [2000 2500 3000 3500];

    else

        % Suitable for standard audio such as 44.1/48 kHz
        lpOptions = [4000 6000 8000 10000 12000 15000];

        % Remove frequencies above Nyquist
        lpOptions = lpOptions(lpOptions < nyquist);

    end

    % Convert values into dropdown labels
    ddLPF.ItemsData = lpOptions;
    ddLPF.Items = strcat(string(lpOptions/1000), " kHz");

    % Select highest valid cutoff
    ddLPF.Value = lpOptions(end);

    function onLoadAudio()
        [file, path] = uigetfile({'*.wav;*.mp3;*.m4a;*.ogg', 'Audio Files (*.wav, *.mp3, *.m4a, *.ogg)'; '*.*', 'All Files'});
        if isequal(file, 0), return; end
        [x, fs] = audioread(fullfile(path, file));
        onStopAudio();
        setAudio(x, fs, file);
    end

    function onGenerateDemoAudio()
        lblStatus.Text = 'Generating realistic demo audio with 50Hz hum and white noise...';
        drawnow;
        try
            run('AudioGenerator_Noisy.m');
            [x, fs] = audioread('test_noisy.wav');
            onStopAudio();
            setAudio(x, fs, 'test_noisy.wav (50Hz Hum + Hiss)');
            lblStatus.Text = 'Loaded noisy audio. Toggle 50 Hz Notch & Denoise to hear the magic!';
            onPlayClean();
        catch ME
            lblStatus.Text = sprintf('Error generating demo: %s', ME.message);
        end
    end

    function onSliderChanged(idx)
        val = round(sliders{idx}.Value);
        gainLabels{idx}.Text = sprintf('%+d dB', val);
        onParamChanged();
    end

    function onParamChanged()
        processAndPlot();
        % If audio is currently playing, seamlessly update the playback buffer
        if data.isPlaying && ~isempty(data.player) && isvalid(data.player)
            currentSample = data.player.CurrentSample;
            data.player.StopFcn = [];
            stop(data.player);
            delete(data.player);
            data.player = audioplayer(data.y_proc, data.fs);
            data.player.StopFcn = @(src, event) onPlayerStopped();
            if currentSample < length(data.y_proc)
                play(data.player, currentSample);
            else
                play(data.player);
            end
            data.isPlaying = true;
            lblStatus.Text = 'Live audio buffer updated!';
        end
    end

    function processAudio()
        if isempty(data.x_orig), return; end
        y = data.x_orig;
        fs = data.fs;

        % 1. Spectral Denoise (STFT)
        if tglDenoise.Value
            try
                y = spectralDenoise(y, fs, 0.5);
            catch ME
                warning('spectralDenoise: %s', ME.message);
            end
        end

        % 2. Mains Hum & Buzz Notch Filter (50 Hz Fundamental + 100 Hz Harmonic Buzz)
        if tglNotch.Value
            try
                y = notchfilter(y, 50, fs, 30);  % 50 Hz Fundamental Hum
                if fs > 250
                    y = notchfilter(y, 100, fs, 30); % 100 Hz Harmonic Buzz
                end
            catch ME
                warning('notchfilter: %s', ME.message);
            end
        end


        % =========================================================================
        % 3. HIGH-PASS FILTER
        % =========================================================================
        if tglHPF.Value
            try
                cutoffHPF = ddHPF.Value;

                % Safety check: cutoff must be below Nyquist
                if cutoffHPF >= fs/2
                    cutoffHPF = fs/4;
                end

                y = highpassFilter(y, cutoffHPF, fs, 0.707);

            catch ME
                warning('highpassFilter: %s', ME.message);
            end
        end


        % =========================================================================
        % 4. LOW-PASS FILTER
        % =========================================================================
        if tglLPF.Value
            try
                cutoffLPF = ddLPF.Value;

                % Safety check: cutoff must be below Nyquist
                if cutoffLPF >= fs/2
                    cutoffLPF = fs/4;
                end

                y = lowpassFilter(y, cutoffLPF, fs, 0.707);

            catch ME
                warning('lowpassFilter: %s', ME.message);
            end
        end

        % 3. 5-Band Parametric Peaking EQ (Q = 0.9 gives rich, audible bandwidth)
        Q = 0.9;
        for i = 1:5
            g = sliders{i}.Value;
            f0 = data.bandFreqs(i);
            if f0 < (fs / 2) && abs(g) > 0.1
                [b, a] = peakingEQ(f0, Q, g, fs);
                y = filter(b, a, y);
            end
        end

        % 4. Smart Peak Limiter (Protects against digital distortion while preserving volume cuts/boosts)
        peakVal = max(abs(y));
        if peakVal > 0.98
            y = y / peakVal * 0.98;
        end
        data.y_proc = y;
    end

    function processAndPlot()
        if isempty(data.x_orig), return; end
        processAudio();
        y = data.y_proc;
        x = data.x_orig;
        fs = data.fs;

        % Waveform Plot
        t = (0:length(x)-1) / fs;
        cla(axWave);
        hold(axWave, 'on');
        plot(axWave, t, x, 'Color', [0.4 0.6 0.85 0.4], 'DisplayName', 'Original');
        plot(axWave, t, y, 'Color', [1.0 0.55 0.15], 'LineWidth', 1.1, 'DisplayName', 'Processed');
        hold(axWave, 'off');
        legend(axWave, 'TextColor', 'white', 'Color', [0.15 0.17 0.22]);
        xlim(axWave, [0, min(max(t), 3.0)]);

        % Frequency Spectrum (FFT)
        N = min(8192, length(x));
        fAxis = (0:N/2-1) * (fs / N);
        X_mag = 20*log10(abs(fft(x(1:N))) + eps);
        Y_mag = 20*log10(abs(fft(y(1:N))) + eps);

        cla(axSpec);
        hold(axSpec, 'on');
        plot(axSpec, fAxis, X_mag(1:N/2), 'Color', [0.4 0.6 0.85 0.4], 'DisplayName', 'Original');
        plot(axSpec, fAxis, Y_mag(1:N/2), 'Color', [0.2 0.9 0.4], 'LineWidth', 1.2, 'DisplayName', 'Processed');
        hold(axSpec, 'off');
        legend(axSpec, 'TextColor', 'white', 'Color', [0.15 0.17 0.22]);
        xlim(axSpec, [20, fs/2]);
    end

    function onPlayClean()
        if isempty(data.x_orig), return; end
        onStopAudio();
        processAudio();
        data.player = audioplayer(data.y_proc, data.fs);
        data.player.StopFcn = @(src, event) onPlayerStopped();
        play(data.player);
        data.isPlaying = true;
        lblStatus.Text = '▶ Playing Processed / Cleaned Audio... Move sliders for live changes!';
    end

    function onPlayOriginal()
        if isempty(data.x_orig), return; end
        onStopAudio();
        data.player = audioplayer(data.x_orig, data.fs);
        data.player.StopFcn = @(src, event) onPlayerStopped();
        play(data.player);
        data.isPlaying = true;
        lblStatus.Text = '▶ Playing Original Unprocessed Audio (hear the noise & hum)...';
    end

    function onStopAudio()
        try
            if ~isempty(data.player) && isvalid(data.player)
                data.player.StopFcn = [];
                stop(data.player);
            end
        catch
        end
        clear sound;
        data.isPlaying = false;
        if isvalid(fig) && isvalid(lblStatus)
            lblStatus.Text = 'Playback stopped.';
        end
    end

    function onPlayerStopped()
        try
            if ~isvalid(fig), return; end
            if data.isPlaying && data.isLooping
                % Continuous playback loop
                if ~isempty(data.player) && isvalid(data.player)
                    play(data.player);
                end
            else
                data.isPlaying = false;
                if isvalid(lblStatus)
                    lblStatus.Text = 'Playback finished.';
                end
            end
        catch
            % Figure or variables destroyed during closure - safely ignore
        end
    end

    function onDenoiseBtnToggled(btn)
        if btn.Value
            btn.Text = '✓ Denoise: ON';
            btn.BackgroundColor = [0.12 0.55 0.3];
        else
            btn.Text = '✗ Denoise: OFF';
            btn.BackgroundColor = [0.32 0.35 0.4];
        end
        onParamChanged();
    end

    function onNotchBtnToggled(btn)
        if btn.Value
            btn.Text = '✓ 50/100Hz Notch: ON';
            btn.BackgroundColor = [0.12 0.55 0.3];
        else
            btn.Text = '✗ 50/100Hz Notch: OFF';
            btn.BackgroundColor = [0.32 0.35 0.4];
        end
        onParamChanged();
    end

    % =========================================================================
    % HIGH-PASS FILTER TOGGLE
    % =========================================================================
    function onHPFToggled(btn)

        if btn.Value
            btn.Text = '✓ HPF: ON';
            btn.BackgroundColor = [0.12 0.55 0.3];
        else
            btn.Text = '✗ HPF: OFF';
            btn.BackgroundColor = [0.32 0.35 0.4];
        end

        onParamChanged();

    end

    % =========================================================================
    % LOW-PASS FILTER TOGGLE
    % =========================================================================
    function onLPFToggled(btn)

        if btn.Value
            btn.Text = '✓ LPF: ON';
            btn.BackgroundColor = [0.12 0.55 0.3];
        else
            btn.Text = '✗ LPF: OFF';
            btn.BackgroundColor = [0.32 0.35 0.4];
        end

        onParamChanged();

    end

    function onLoopBtnToggled(btn)
        if btn.Value
            btn.Text = '🔁 Loop: ON';
            btn.BackgroundColor = [0.2 0.45 0.75];
            data.isLooping = true;
            if ~data.isPlaying, onPlayClean(); end
        else
            btn.Text = '🔁 Loop: OFF';
            btn.BackgroundColor = [0.3 0.34 0.4];
            data.isLooping = false;
        end
    end

    function onSaveAudio()
        if isempty(data.y_proc), return; end
        [file, path] = uiputfile('*.wav', 'Save Cleaned Audio', 'test_clean.wav');
        if isequal(file, 0), return; end
        audiowrite(fullfile(path, file), data.y_proc, data.fs);
        uialert(fig, sprintf('Successfully saved audio to %s', file), 'Export Success');
    end

    function onCloseFigure()
        try
            if ~isempty(data.player) && isvalid(data.player)
                data.player.StopFcn = [];
                stop(data.player);
                delete(data.player);
            end
        catch
        end
        delete(fig);
    end
end
