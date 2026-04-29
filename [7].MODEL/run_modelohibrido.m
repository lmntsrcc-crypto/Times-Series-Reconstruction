% Run the model and export residual reconstruction results.
%
% The script loads a merged ERA5 and tidal residual dataset, runs the
% model with a specified neural network architecture, exports the reconstructed
% residual series, saves the generated figure, and writes model performance
% metrics to a text file.
%
% Input:
% - Merged CSV file containing time variables, ERA5 predictors, and Error1 residuals
%
% Output:
% - serie_residual_completada.csv: real and modeled residual time series
% - grafica_residual.png: residual reconstruction plot
% - resultados_modelo.txt: model metrics and temporal structure statistics
%
% Requirements:
% - MATLAB
% - modelohibrido.m function available in the current path

clc; clear; close all;

% === Parámetros de ejecución ===
archivo = 'era5_losangeles_merged_1998_2003.csv';   
capas   = [50, 20, 10];
graficar = 1;

[red, Y_mod, stats, structs] = modelohibrido(archivo, capas, graficar);

[~, nombre_sin_ext, ~] = fileparts(archivo);
carpeta = ['resultados_modelo_' nombre_sin_ext];

if ~exist(carpeta, 'dir')
    mkdir(carpeta);
end

Datos = csvread(archivo, 1, 0);

year  = Datos(:,1);
month = Datos(:,2);
day   = Datos(:,3);
hour  = Datos(:,4);
Y_real = Datos(:,10); 

T = table(year, month, day, hour, Y_real, Y_mod, ...
    'VariableNames', {'Anio','Mes','Dia','Hora','ResidualReal','ResidualModelado'});

csv_salida = fullfile(carpeta, 'serie_residual_completada.csv');
writetable(T, csv_salida);
fprintf('\nArchivo exportado: %s\n', csv_salida);

if graficar == 1
    figura = gcf;  
    archivo_png = fullfile(carpeta, 'grafica_residual.png');
    saveas(figura, archivo_png);
    fprintf('Gráfica guardada en: %s\n', archivo_png);
end

resultados_txt = fullfile(carpeta, 'resultados_modelo.txt');
fid = fopen(resultados_txt, 'w');

fprintf(fid, "RESULTADOS DEL MODELO H�?BRIDO\n");
fprintf(fid, "==============================\n\n");

fprintf(fid, "Archivo analizado: %s\n", archivo);
fprintf(fid, "Capas de la red    : [%d %d %d]\n\n", capas(1), capas(2), capas(3));

fprintf(fid, "MÉTRICAS PRINCIPALES:\n");
fprintf(fid, "R²      : %.4f\n", stats(1));
fprintf(fid, "RMSE    : %.6f\n", stats(2));
fprintf(fid, "MAE     : %.6f\n", stats(3));
fprintf(fid, "%%NaN    : %.2f%%\n\n", stats(4));

fprintf(fid, "ESTRUCTURA TEMPORAL (structs):\n");
fprintf(fid, "err_mean          : %.6f\n", structs(1));
fprintf(fid, "err_var           : %.6f\n", structs(2));
fprintf(fid, "skew_orig         : %.6f\n", structs(3));
fprintf(fid, "skew_imp          : %.6f\n", structs(4));
fprintf(fid, "kurt_orig         : %.6f\n", structs(5));
fprintf(fid, "kurt_imp          : %.6f\n", structs(6));
fprintf(fid, "mean_dY_orig      : %.6f\n", structs(7));
fprintf(fid, "mean_dY_imp       : %.6f\n", structs(8));
fprintf(fid, "var_dY_orig       : %.6f\n", structs(9));
fprintf(fid, "var_dY_imp        : %.6f\n", structs(10));

fclose(fid);

fprintf('Archivo de resultados guardado en: %s\n', resultados_txt);

disp('=========================================')
disp('       RESULTADOS DEL MODELO H�?BRIDO      ')
disp('=========================================')

fprintf('R²      : %.4f\n', stats(1));
fprintf('RMSE    : %.6f\n', stats(2));
fprintf('MAE     : %.6f\n', stats(3));
fprintf('%%NaN    : %.2f%%\n', stats(4));

disp(' ')
disp('Estructura temporal (structs):')
disp(structs)

disp(' ')
disp('Modelo ejecutado correctamente')