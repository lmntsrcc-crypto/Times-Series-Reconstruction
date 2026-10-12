% Modelo para el residual con una red de tres capas intermedias
% Utilizando la fecha y variables físicas (viento/presión/temperatura)
% Sábado 15 de Noviembre
% Dr. Joel Artemio Morales

% Entradas:
% file, nombre del archivo csv con los datos.
% C, vector con el número de neuronas en cada capa C(3,1).
% g, opción de graficación (g=1 con gráfica de imputación, g=0 sin gráfica).

% Salidas:
% net, la red neuronal entrenada.
% Y_mod, las salidas predichas por el modelo.
% stats, vector con:
% stats(1): R² (coeficiente de determinación).
% stats(2): RMSE (sobre puntos conocidos).
% stats(3): MAE (sobre puntos conocidos).
% stats(4): % de Puntos rellenados.
% structs, vector con:
% structs(1): Error relativo de la media entre datos originales e imputados.
% structs(2): Error relativo de la varianza entre datos originales e imputados.
% structs(3): Asimetría de los datos originales.
% structs(4): Asimetría de los datos imputados.
% structs(5): Curtosis estadística datos originales.
% structs(6): Curtosis estadísticas datos imputados.
% structs(7): Media incrementos originales.
% structs(8): Media incrementos imputados.
% structs(9): Varianza incrementos originales.
% structs(10): Varianza incrementos imputados.
    
% Ejemplo de ejecución:
% [red, Y_mod, stats, structs] = modelohibrido('era5_lajoya_merged_1952_1957.csv', [50,20,10], 1);

function [net,Y_mod,stats,structs] = modelohibrido(file, C, g)

    c1 = C(1);
    c2 = C(2); 
    c3 = C(3);

    % Primero cargamos el archivo CSV con formato
    % Año | Mes | Dia | Hora | u10 | v10 | msl | sst | sp | residual
    % u10,v10,msl,sst,sp descargados desde ERA-5

    DatosTotales = csvread(file,1,0);
    %data = load(archivo); 
    %data = dlmread(archivo, '', saltarse_primera_linea, 0);

    % Separamos las variables de la fecha.

    year  = DatosTotales(:,1);
    month = DatosTotales(:,2);
    day   = DatosTotales(:,3);
    hour  = DatosTotales(:,4);

    % Leemos las variables físicas.

    X_phys = DatosTotales(:,5:9);

    % Salida, variable residual

    Y = DatosTotales(:,10);

    % Transformación de variables de fecha en cíclicas
    % Conversión del año a sin,cos

    years_unique = unique(year);
    nYears = numel(years_unique);
    year_idx = year - min(year);
    thetaY = 2*pi*year_idx / nYears;
    year_sin = (sin(thetaY) + 1)/2;
    year_cos = (cos(thetaY) + 1)/2;
    % Conversión del mes a sin,cos
    thetaM = 2*pi*(month - 1)/12;
    month_sin = (sin(thetaM) + 1)/2;
    month_cos = (cos(thetaM) + 1)/2;
    % Conversión del dia a sin,cos
    thetaD = 2*pi*(day - 1)/31;
    day_sin = (sin(thetaD) + 1)/2;
    day_cos = (cos(thetaD) + 1)/2;
    % Conversión de la hora a sin,cos
    thetaH = 2*pi*(hour)/24;
    hour_sin = (sin(thetaH) + 1)/2;
    hour_cos = (cos(thetaH) + 1)/2;

    % Vector con variables de fecha entre [-1,1].

    X_time = [year_sin, year_cos, ...
              month_sin, month_cos, ...
              day_sin, day_cos, ...
              hour_sin, hour_cos];

    % Normalizar variables fisicas al rango [-1,1]

    [X_phys_norm, ~] = mapminmax(X_phys', -1, 1);  
    X_phys_norm = X_phys_norm';

    % Vector de entradas completo, [Físicas | Fecha_Cíclica]

    X = [X_phys_norm, X_time];

    % Se construye la red neuronal con residuales válidos
    % Es decir, no se utilizan los NAN

    valid = ~isnan(Y);
    Xtrain = X(valid,:);
    Ytrain = Y(valid);

    % Construcción de la red neuronal de capas c1,c2,c3

    net = feedforwardnet([c1,c2,c3], 'trainscg');
    net.layers{1}.transferFcn
    net.layers{2}.transferFcn
    net.layers{3}.transferFcn
    net.layers{4}.transferFcn
    net.performFcn = 'mse';
    net.divideFcn = 'dividerand';
    net.divideParam.trainRatio = 0.70;
    net.divideParam.valRatio   = 0.15;
    net.divideParam.testRatio  = 0.15;
    net.trainParam.max_fail = 10;
    net.trainParam.epochs   = 1000;
    net.trainParam.min_grad = 1e-7;

    % Entrenamiento de la red

    [net, tr] = train(net, Xtrain', Ytrain');

    % Predecimos para todas las entradas (incluso donde la salida es NAN)

    Y_mod = net(X')';
    Y_filled = Y;

    % Utilizamos la predicción del modelo para rellenar donde la salida
    % original era desconocida para imputar los huecos en la serie.

    Y_filled(~valid) = Y_mod(~valid);

    % Calculamos las métricas de desempeño.
    
    testInd = tr.testInd;
    Ytrue = Ytrain(testInd);
    Ypred = net(Xtrain(testInd,:)')';
    e = Ypred - Ytrue;
    RMSE = sqrt(mean(e.^2));
    MAE = mean(abs(e));
    SS_res = sum((Ytrue - Ypred).^2);
    SS_tot = sum((Ytrue - mean(Ytrue)).^2);
    R2 = 1 - SS_res / SS_tot;
    nTotal = numel(Y);
    nNaN   = sum(~valid);
    
    % Calculamos las estructuras temporales de la serie de tiempo
    % original y de la imputación.
    
    Y_orig = Y(valid);
    Y_imp = Y_mod(valid);
    mean_orig = mean(Y_orig);
    mean_imp  = mean(Y_imp);
    var_orig  = var(Y_orig);
    var_imp   = var(Y_imp);
    err_mean = (mean_imp - mean_orig)/mean_orig;
    err_var  = (var_imp  - var_orig )/var_orig;
    skew_orig = skewness(Y_orig);
    skew_imp  = skewness(Y_imp);
    kurt_orig = kurtosis(Y_orig);
    kurt_imp  = kurtosis(Y_imp);
    dY_orig = diff(Y_orig);
    dY_imp  = diff(Y_imp);
    mean_dY_orig = mean(dY_orig);
    mean_dY_imp  = mean(dY_imp);
    var_dY_orig  = var(dY_orig);
    var_dY_imp   = var(dY_imp);
    
    structs=[err_mean,err_var,skew_orig,skew_imp,kurt_orig,kurt_imp,...
        mean_dY_orig,mean_dY_imp,var_dY_orig,var_dY_imp];
    
    % Creamos el vector de salidas.
    
    stats = [R2, RMSE, MAE, 100*nNaN/nTotal];
    
    % Si g==1, mostramos la serie de tiempo con datos imputados
    
    if(g==1)
        t = datetime(year, month, day, hour, 0, 0); 
        res_conocido = Y;
        res_conocido(~valid) = NaN;  
        res_modelado = Y_filled;
        res_modelado(valid) = NaN;      
        figure;
        plot(t, res_conocido, '.-'); hold on;
        plot(t, res_modelado, '.-');
        legend('Residual Conocido', 'Residual Modelado', 'Location', 'best');
        xlabel('Fecha');
        ylabel('Residual nivel del mar');   
        title('Residual Conocido vs Residual Modelado');
        grid on;
    end    
end



