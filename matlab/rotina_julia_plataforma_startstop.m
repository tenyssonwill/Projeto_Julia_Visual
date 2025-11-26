function rotina_julia_plataforma_startstop
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
%         Usa o mouse ou teclado para passar para a próxima etapa
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

clc
close all
clear stopWhenExceed

target = 5;

sequence = [1 1 1 2 2 2 3 3 3 4 4 4];
sequence = sequence(randperm(12));

disp(['Sequencia: ' mat2str(sequence)])

% Variaveis Globais que recebem valores na funcao executar_audio e os
% valores são mostrados no final desta
% global numero;      % numero aleatorio
% global seq;         % sequencia aleatoria

%%%% Configurar Placa de Aquisição-Plataforma para acionamento do projetor
Fs = 5000;
Npm = 500;

% Find Device
daqreset;

dev = daqlist("ni");

if(strcmp(dev.Model, "USB-6251 (BNC)"))
    disp('found')
end


% Configurando 
s = daq('ni');
%addinput(s,"Dev1","ai0","Voltage");
addinput(s,"Dev2","ai0","Voltage");
s.Rate = Fs;

%%%% Configuracao dos monitores
mon_pos = get(0,'MonitorPositions');
if(size(mon_pos,1)~=2)
    error('Não existem dois monitores')
end

% Tamanho da projecao
tam_long = 114;
tam_tran = 84;

% Projecao no chao no monitor 2 (projetor)
hf = figure('menubar','none','outerposition',mon_pos(2,:)-[0 0 mon_pos(1,3) 0]);
hax = gca;
set(hax,'Position',[0 0 1 1],'XLim',[0 tam_long],'YLim',[0 tam_tran],'Color','k')

hf.CloseRequestFcn = @(src,event)myCloseRequestFunction(src, event, s);
% s.NotifyWhenDataAvailableExceeds = Npm;
s.ScansAvailableFcnCount = Npm;

disp('Inicio do Experimento')
for i=1:12
    
%     disp(['Inicio da tarefa: ' num2str(i) '. Clique para começar'])
%     waitforbuttonpress;
    disp(['Tarefa: ' num2str(i)  ' iniciada. Aguardando contato'])
    
    s.ScansAvailableFcn = @(src,event)stopWhenExceed(src,event, sequence(i), hax, target);
   
    s.start("Continuous")



    while s.Running
         pause(0.5);
     
    end

    disp(['Final da Tarefa: ' num2str(i) '. Clique para recomeçar'])
    waitforbuttonpress;
    delete(hax.Children)
    
    
end

disp('Final do Experimento')
close all
end

function stopWhenExceed(src, ~, choice, hax, target)

% Variavel persistent para a posicao poder ser mudada em qualquer funcao

%disp(['Choice: ' num2str(choice)])
[data, ~ , ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");

if mean(data) > target
    %disp(['Valor escolhido: ' num2str(choice)])
    
    % Montando os retangulos conforme a escolha
    switch choice
        case 1
            disp('Desenhando Retângulo Rosa')
            rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor', '#ff00bb');
%                     pause(stoptime);
        case 2
            disp('Desenhando Retângulo Verde Perto')
            rectangle('Parent',hax,'Position',[42 10 30 15],'EdgeColor','none','Facecolor','#00ff03');
%                     pause(stoptime);
        case 3
            disp('Desenhando Retângulo Verde Longe')
            rectangle('Parent',hax,'Position',[42 60 30 15],'EdgeColor','none','Facecolor','#00ff03');
%                     pause(stoptime);
        case 4
            disp('Não desenha nada. Tela preta')
            rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','k');
%                     pause(stoptime);
        case ''
            error('Não foi selecionada nenhuma tarefa')
        
    end

    src.stop;
end

end

function myCloseRequestFunction(src, ~ , s)
% Callback para parar aquisção e fechar a janela, quando o X da janela é
    stop(s)
    delete(src)
end