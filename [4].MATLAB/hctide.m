% Perform harmonic tidal analysis using T_TIDE over fixed multi-year windows.
%
% The script reads an hourly water level time series with possible NaN values,
% splits the record into consecutive time windows, applies T_TIDE harmonic
% analysis to each window, reconstructs the astronomical tide, computes the
% residual signal, and saves both the reconstructed series and the selected
% tidal constituents.
%
% Input:
% - CSV file with columns: year, month, day, hour, minute, water_level
%
% Output:
% - *_h.csv: original elevation, reconstructed harmonic tide, and residual
% - *_hc.csv: harmonic constituents with SNR >= 1 for each analysis window
%
% Requirements:
% - MATLAB
% - T_TIDE toolbox added to the path

clc; clear; close all;

addpath('t_tide_v1.3beta');
archivo = 'DATANANRANGE/CW-LA-1950-2025_NaN.csv';
nombreh = 'CW-LA-1950-2025_h.csv';
nombrehc = 'CW-LA-1950-2025_hc.csv';
lat_est = 33.7005;           %Los Angeles      Los Angeles, CA - Station ID: 9410660
intervalo = 1;
ventana_anios = 5;
min_datos = 1000;
saltarse_primera_linea = 1;   % 1 = sí (header), 0 = no

data = dlmread(archivo, '', saltarse_primera_linea, 0);

anio = data(:,1); mes = data(:,2); dia = data(:,3);
hora = data(:,4); minu = data(:,5); elev = data(:,6);

time_dt = datetime(anio, mes, dia, hora, minu, 0);

N = numel(elev);
xout_total   = NaN(N,1);   % armónicos (marea astronómica)
error1_total = NaN(N,1);   % residual = observado - armónicos

Resultados = table('Size',[0 8], ...
    'VariableTypes', {'datetime','string','double','double','double','double','double','double'}, ...
    'VariableNames', {'Inicio','Componente','Frecuencia_cph','Amplitud_m','Amp_err_m','Fase_deg','Fase_err_deg','SNR'});

t_start = time_dt(1);
t_end   = time_dt(end);

i = 1;
while true
    t0 = t_start + calyears((i-1)*ventana_anios);
    t1 = t_start + calyears(i*ventana_anios);
    if t0 >= t_end, break; end

    idx = (time_dt >= t0) & (time_dt < t1);
    if nnz(idx) < min_datos
        i = i + 1;
        continue;
    end

    elev_win = elev(idx);
    time_win = time_dt(idx);

    try
        [txt, name, freq, tidecon, xout] = evalc( ...
            't_tide(elev_win, ''interval'', intervalo, ''start time'', datevec(time_win(1)), ''latitude'', lat_est, ''error'', ''linear'', ''secular'',''mean'', ''synthesis'', 1)' );

        fprintf('%s', txt);

        xout = xout(:);

        nmin = min(numel(elev_win), numel(xout));
        ew = elev_win(1:nmin);
        xu = xout(1:nmin);
        res = ew - xu;

        ix = find(idx); ix = ix(1:nmin);
        xout_total(ix)   = xu;
        error1_total(ix) = res;

        nombres  = string(strtrim(cellstr(name)));
        amp      = tidecon(:,1);
        amp_err  = tidecon(:,2);
        fase     = tidecon(:,3);
        fase_err = tidecon(:,4);

        if size(tidecon,2) >= 5
            snr = tidecon(:,5);
        else
            snr = (amp ./ max(amp_err, eps)).^2;
        end

        f_cph = freq(:);

        ok = (snr >= 1);
        Tw = table( repmat(t0,nnz(ok),1), nombres(ok), f_cph(ok), amp(ok), amp_err(ok), fase(ok), fase_err(ok), snr(ok), ...
            'VariableNames', {'Inicio','Componente','Frecuencia_cph','Amplitud_m','Amp_err_m','Fase_deg','Fase_err_deg','SNR'} );

        Resultados = [Resultados; Tw];

        fprintf('Ventana %d: constituyentes (SNR>=1) = %d\n', i, nnz(ok));

    catch ME
        fprintf('Error en ventana %d (%s a %s): %s\n', i, datestr(t0), datestr(t1), ME.message);
    end

    i = i + 1;
end

if height(Resultados) > 0
    Resultados = sortrows(Resultados, {'Inicio','Amplitud_m'}, {'ascend','descend'});
end

Tabla_final = table(anio, mes, dia, hora, minu, elev, xout_total, error1_total, ...
    'VariableNames', {'Anio','Mes','Dia','Hora','Min','Elevacion','Armonicos','Error1'});

writetable(Tabla_final, nombreh);
writetable(Resultados, nombrehc);