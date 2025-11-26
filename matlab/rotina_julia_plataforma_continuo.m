function rotina_julia_plataforma_continuo
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% File: rotina_julia_plataforma_continuo2.m 
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
%         Mantem o evento enquanto há a sinal da plataforma
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

clc
close all

target = 5;

sequence = [1 1 1 2 2 2 3 3 3 4 4 4];
sequence = sequence(randperm(12));

% Variaveis Globais que recebem valores na funcao executar_audio e os
% valores são mostrados no final desta
% global numero;      % numero aleatorio
% global seq;         % sequencia aleatoria

%%%% Configurar Placa de Aquisição-Plataforma para acionamento do projetor
Fs = 5000;
Npm = 500; % O padrao é 1/10 da Fs e o minimo é 1/20

% Find Device
daqreset;

dev = daqlist("ni");

if(strcmp(dev.Model, "USB-6251 (BNC)"))
    disp('found')
end

% Configurando 
s = daq('ni');
% addinput(s,"Dev1","ai0","Voltage");
addinput(s,"Dev2","ai0","Voltage"); % para testes
s.Rate = Fs;

%%%% Configuracao dos monitores
mon_pos = get(0,'MonitorPositions');
if(size(mon_pos,1)~=2)
    error('Não existem dois monitores')
end

% Tamanho da projecao
tam_long = 114;
tam_tran = 84;

% % Painel para a escolha da aletorizacao no monitor 1 (tela do notebook)
% hf1 = figure('menubar','none','outerposition',mon_pos(1,:));

% Projecao no chao no monitor 2 (projetor)
hf = figure('menubar','none','outerposition',mon_pos(2,:)-[0 0 mon_pos(1,3) 0]);
hax = gca;
set(hax,'Position',[0 0 1 1],'XLim',[0 tam_long],'YLim',[0 tam_tran],'Color','k')


hf.CloseRequestFcn = @(src,event)myCloseRequestFunction(src,event, s);

s.ScansAvailableFcn = @(src,event)changePanel(src,event, sequence, hax, target);

% Numero de pontos para chamar a funcao descrita em ScansAvailableFcn (normalmente é igual a Fs)
s.ScansAvailableFcnCount = Npm;


s.start("Continuous")

while s.Running
    pause(0.2)
%     delete(hax.Children)
end

end

function changePanel(src, ~, sequence, hax, target)
% Callback do painel de configuração das tarefas

persistent n signal_active;

if isempty(signal_active)
    signal_active = false;
    n = 0;
end

[data, ~ , ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");

if (mean(data) > target) && (signal_active == false)

    signal_active = true;
    n = n + 1;

    choice = sequence(n);
      
    % Montando os retangulos conforme a escolha
    switch choice
        case 1
            disp('Desenhando Retângulo Rosa')
            rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor', '#ff00bb');
    
        case 2
            disp('Desenhando Retângulo Verde Perto')
            rectangle('Parent',hax,'Position',[42 10 30 15],'EdgeColor','none','Facecolor','#00ff03');
    
        case 3
            disp('Desenhando Retângulo Verde Longe')
            rectangle('Parent',hax,'Position',[42 60 30 15],'EdgeColor','none','Facecolor','#00ff03');
    
        case 4
            disp('Não desenha nada. Tela preta')
            rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','k');
           
        case ''
            error('Não foi selecionada nenhuma tarefa')
    end

    disp(['Evento: ' num2str(n) '. Média : ' num2str(mean(data)) '. Pisada iniciada']);

elseif (mean(data) < target) && (signal_active == true)
    signal_active = false;
    delete(gca().Children)

    if n == length(sequence)
        src.stop;
        close all
    end

    disp(['Evento: ' num2str(n) '. Média : ' num2str(mean(data)) '. Pisada Terminada']);
end


end


function myCloseRequestFunction(src, ~ , s)
% Callback para parar aquisção e fechar a janela, quando o X da janela é
stop(s)
delete(src)
   
end