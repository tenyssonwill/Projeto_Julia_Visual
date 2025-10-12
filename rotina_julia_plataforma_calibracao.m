function rotina_julia_plataforma_calibracao
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% File: rotina_julia_plataforma_calibracao.m 
% Author:	Tenysson Will de Lemos (c) 2025, All Rights Reserved
%			tenysson@fmrp.usp.br
%         	NAP - DCD 
%         	Av. Bandeirantes, 3900 
%         	Dept. Ciencias da Saúde
%		  	Faculdade Medicina de Ribeirao Preto - Universidade de Sao Paulo
%         	Ribeirao Preto, SP, Cep: 14049-900
% Date:   30-07-2025
% Version: 1.1
% Objetivo: 
%         Mudar a sequencia de quadros brancos, aleatoriamente, conforme um pulso da plataforma
clc
close all

% global full_data_time;
% global contador;


tempo_de_acquisicao = inputdlg('Insira o tempo de aquisicao','',1,{'30'});
if(isempty(tempo_de_acquisicao))
    error('Teste Cancelado')
end

% Acquisition Parameters
Fs = 5000;
Npm = 500;
tempo_de_acquisicao = str2double(tempo_de_acquisicao{1});


% Find Device
daqreset;

dev = daqlist("ni");

if(strcmp(dev.Model, "USB-6251 (BNC)"))
    disp('found')
end


% Configurando 
s = daq('ni');
ch1 = addinput(s,"Dev1","ai0","Voltage");
% get(s)
s.Rate = Fs;

% ch1.TerminalConfig = "SingleEnded";
% ch1.Coupling = "AC";

% s.DurationInSeconds = tempo_de_acquisicao;
% s.ScansAvailableFcnCount = 


hf2 = figure;
hf2.WindowState = 'maximized';
% lh = addlistener(s,'DataAvailable', @(src,event) callbackplot(src,event,hf2,Npm));
s.ScansAvailableFcn = @(src,event)callbackplot(src,event, hf2);

% s.NotifyWhenDataAvailableExceeds = Npm;
s.ScansAvailableFcnCount = Npm;

% s.startBackground();
s.start("Duration", seconds(tempo_de_acquisicao))
% start(s,"Duration",seconds(5))

% s.start("Continuous")


% get(s)

while s.Running
    pause(0.2)
%     fprintf("While loop: Scans acquired = %d\n", s.NumScansAcquired)
end

% fprintf("Acquisition stopped with %d scans acquired\n", s.NumScansAcquired);
% 


end

function callbackplot(src,~,hf)

persistent data time;

[partdata, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");

data = [data; partdata];
time = [time; timestamps];
figure(hf);
plot(time, data);
xlabel('tempo (s)')
ylabel('Peso (N)')

title(['Peso: ' num2str(mean(data))])

end