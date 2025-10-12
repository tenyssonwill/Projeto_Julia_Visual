function rotina_julia_plataforma_continuo
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


% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

clc
close all

target = 5;

sequence = [1 1 1 2 2 2 3 3 3 4 4 4];
sequence = sequence(randperm(12));
% 
% for seq = sequence
%     configuracao (~,~,seq)
% end


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
addinput(s,"Dev1","ai0","Voltage");
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
figure('menubar','none','outerposition',mon_pos(2,:)-[0 0 mon_pos(1,3) 0]);
hax = gca;
set(hax,'Position',[0 0 1 1],'XLim',[0 tam_long],'YLim',[0 tam_tran],'Color','k')



s.ScansAvailableFcn = @(src,event)configuracao(src,event, sequence, hax, target);

% s.NotifyWhenDataAvailableExceeds = Npm;
% Numero de pontos para chamar a funcao descrita em ScansAvailableFcn (normalmente é igual a Fs)
s.ScansAvailableFcnCount = Npm;

% s.startBackground();
% s.start("Duration", seconds(tempo_de_acquisicao))
% start(s,"Duration",seconds(5))

s.start("Continuous")


% get(s)

while s.Running
    pause(0.2)
    delete(hax.Children)
%     fprintf("While loop: Scans acquired = %d\n", s.NumScansAcquired)
end



% fprintf("Acquisition stopped with %d scans acquired\n", s.NumScansAcquired);
%



% Conectando a projecao com a plataforma
% lh = addlistener(s,'DataAvailable', @(src,event) stopWhenExceed(src,event,hax));
% s.startBackground();

% % Montagem painel para a escolha da aletorizacao
% switch choice
%     case 'Tarefa 1'
%         set(hf1,'Name','Tarefa 1');
%         uicontrol(hf1,'Style','pushbutton','String','<html>&#9679</html>',...
%             'ForegroundColor','r','FontSize',60,'Units','normalized','Position',[0.4 0.4 0.2 0.2],...
%             'Callback', @(src,event) configuracao (src,event,'retangulo rosa',hax,som));
%         uicontrol(hf1,'Style','pushbutton','String','<html>&darr</html>',...
%             'FontSize',100,'Units','normalized','Position',[0.4 0.1 0.2 0.2],...
%             'Callback', @(src,event) configuracao (src,event,'retangulo verde perto',hax,som));
%         uicontrol(hf1,'Style','pushbutton','String','<html>&uarr</html>',...
%             'FontSize',100,'Units','normalized','Position',[0.4 0.7 0.2 0.2],...
%             'Callback', @(src,event) configuracao (src,event,'retangulo verde longe',hax,som));
%         uicontrol(hf1,'Style','pushbutton','String','<html>&larr</html>',...
%             'FontSize',100,'Units','normalized','Position',[0.1 0.4 0.2 0.2],...
%             'Callback', @(src,event) configuracao (src,event,'nada',hax,som));
%         uicontrol(hf1,'Style','pushbutton','String','<html>&rarr</html>',...
%             'FontSize',100,'Units','normalized','Position',[0.7 0.4 0.2 0.2],...
%             'Callback', @(src,event) configuracao (src,event,'centro-posterior',hax,som));
%         disp('Tarefa 1')
%     case ''
%         error('Não foi selecionada nenhuma tarefa')
% end

% Disparo da Placa de Aquisição-Plataforma


close all
end

function configuracao(src, ~, sequence, hax, target)
% Callback do painel de configuração das tarefas

% Variavel global para a posicao poder ser mudada em qualquer funcao
% global pos;
persistent n;

[data, ~ , ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");

if mean(data) > target

    
    if isempty(n)
            n = 0;
    end
    n = n + 1;
    
    choice = sequence(n);
    
    % passo = [ant-pos med-lat];
    % passo = [67.015 26.35];
    % passo = [0.4 0.6] .* passo;
    
    % Montando os retangulos conforme a escolha
    switch choice
        case 1
            disp('Desenhando Retângulo Rosa')
            rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor', '#ff00bb');
    %         pos = [42 34.5];
    
        case 2
            disp('Desenhando Retângulo Verde Perto')
            rectangle('Parent',hax,'Position',[42 10 30 15],'EdgeColor','none','Facecolor','#00ff03');
    %         pos = [42 34.5]-[0 passo(2)];
    
        case 3
            disp('Desenhando Retângulo Verde Longe')
            rectangle('Parent',hax,'Position',[42 60 30 15],'EdgeColor','none','Facecolor','#00ff03');
    %         pos = [42 34.5]+[0 passo(2)];
    
        case 4
            disp('Não desenha nada. Tela preta')
            rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','k');
    %         pos = [42 34.5]-[passo(1) 0];
           
        case ''
            error('Não foi selecionada nenhuma tarefa')
    end
end

if n > 12
    src.stop;
end


% Fechar Janela
% closereq;
end

function stopWhenExceed(src,event,h)
% Funcao para acionamento do projetor
persistent pos;

pos = 0;

% Valor do limiar em Newtons
limite = 100;

if any(2000*event.Data > limite )
    disp('Event listener: Detected voltage exceeds 1, stopping acquisition')
    % Continuous acquisitions need to be stopped explicitly.
    src.stop()
    set(get(h,'Children'),'Position',[pos 30 15]);
else
    disp('Event listener: Continuing to acquire')
end

end




% function stopWhenExceed(src, event,h)
%     if any(event.Data > 0.2)
%         disp('Event listener: Detected voltage exceeds 1, stopping acquisition')
%         % Continuous acquisitions need to be stopped explicitly.
%         src.stop()
%         set(h,'Position',[0 0 3 3]);
%     else
%         disp('Event listener: Continuing to acquire')
%     end
% end