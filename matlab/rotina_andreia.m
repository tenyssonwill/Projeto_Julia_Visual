function rotina_andreia
% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% File: rotina_andreia.m 
% Author:	Tenysson Will de Lemos (c) 2014, All Rights Reserved
%			tenysson@fmrp.usp.br
%         	NAP - DCD 
%         	Av. Bandeirantes, 3900 
%         	Dept. Biomecanica, Medicina e Reabilitação do Aparelho Locomotor
%		  	Faculdade Medicina de Ribeirao Preto - Universidade de Sao Paulo
%         	Ribeirao Preto, SP, Cep: 14048-900
% Date:   26-07-2016
% Version: 1.1
% Objetivo: 
%         Mudar a sequencia de quadros brancos, aleatoriamente, conforme um pulso da plataforma
clc
close all

% Variaveis Globais que recebem valores na funcao executar_audio e os
% valores são mostrados no final desta
global numero;      % numero aleatorio
global seq;         % sequencia aleatoria

%%%% Configurar Placa de Aquisição-Plataforma para acionamento do projetor
s = daq.createSession('ni');
s.addAnalogInputChannel('Dev1', 0,'Voltage');
s.Rate = 5000;
s.IsContinuous = true;

% Escolher entre a tarefa 1 ou 2
%choice = questdlg('Selecione a Tarefa','','Tarefa 1','Tarefa 2','');
[resposta,OK] = listdlg('PromptString','Select a file:',...
     'SelectionMode','single','ListString',{'Tarefa 1 com som','Tarefa 1 sem som','Tarefa 2 com som','Tarefa 2 sem som'});
if(OK==0)
    error('Voce cancelou! Comece novamente');
end

% Configuracao escolhida
switch resposta
    case 1
        choice = 'Tarefa 1';
        som = true;
    case 2
        choice = 'Tarefa 1';
        som = false;
    case 3
        choice = 'Tarefa 2';
        som = true;
    case 4
        choice = 'Tarefa 2';
        som = false;
end

%%%% Configuracao dos monitores
mon_pos = get(0,'MonitorPositions');
if(size(mon_pos,1)~=2)
    error('Não existem dois monitores')
end

% Tamanho da projecao
tam_long = 114;
tam_tran = 84;

% Painel para a escolha da aletorizacao no monitor 1 (tela do notebook)
hf1 = figure('menubar','none','outerposition',mon_pos(1,:));

% Projecao no chao no monitor 2 (projetor)
figure('menubar','none','outerposition',mon_pos(2,:)-[0 0 mon_pos(1,3) 0]);
hax = gca;
set(hax,'Position',[0 0 1 1],'XLim',[0 tam_long],'YLim',[0 tam_tran],'Color','k')

% Conectando a projecao com a plataforma
lh = addlistener(s,'DataAvailable', @(src,event) stopWhenExceed(src,event,hax));
s.startBackground();

% Montagem painel para a escolha da aletorizacao
switch choice
    case 'Tarefa 1'
        set(hf1,'Name','Tarefa 1');
        uicontrol(hf1,'Style','pushbutton','String','<html>&#9679</html>',...
            'ForegroundColor','r','FontSize',60,'Units','normalized','Position',[0.4 0.4 0.2 0.2],...
            'Callback', @(src,event) configuracao (src,event,'permanece',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&darr</html>',...
            'FontSize',100,'Units','normalized','Position',[0.4 0.1 0.2 0.2],...
            'Callback', @(src,event) configuracao (src,event,'centro-medial',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&uarr</html>',...
            'FontSize',100,'Units','normalized','Position',[0.4 0.7 0.2 0.2],...
            'Callback', @(src,event) configuracao (src,event,'centro-lateral',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&larr</html>',...
            'FontSize',100,'Units','normalized','Position',[0.1 0.4 0.2 0.2],...
            'Callback', @(src,event) configuracao (src,event,'centro-anterior',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&rarr</html>',...
            'FontSize',100,'Units','normalized','Position',[0.7 0.4 0.2 0.2],...
            'Callback', @(src,event) configuracao (src,event,'centro-posterior',hax,som));
        disp('Tarefa 1')
    case 'Tarefa 2'
        set(hf1,'Name','Tarefa 2');      
        uicontrol(hf1,'Style','pushbutton','String','<html>&uarr</html>',...
            'FontSize',60,'Units','normalized','Position',[0.4 0.3 0.2 0.1],...
            'Callback', @(src,event) configuracao (src,event,'medial-centro',hax,som));    
        uicontrol(hf1,'Style','pushbutton','String','<html>&#9679</html>',...
            'ForegroundColor','r','FontSize',60,'Units','normalized','Position',[0.4 0.1 0.2 0.1],...
            'Callback', @(src,event) configuracao (src,event,'medial-permanece',hax,som));
    
        uicontrol(hf1,'Style','pushbutton','String','<html>&darr</html>',...
            'FontSize',60,'Units','normalized','Position',[0.4 0.6 0.2 0.1],...
            'Callback', @(src,event) configuracao (src,event,'lateral-centro',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&#9679</html>',...
            'ForegroundColor','r','FontSize',60,'Units','normalized','Position',[0.4 0.8 0.2 0.1],...
            'Callback', @(src,event) configuracao (src,event,'lateral-permanece',hax,som));
     
        uicontrol(hf1,'Style','pushbutton','String','<html>&rarr</html>',...
            'FontSize',60,'Units','normalized','Position',[0.25 0.4 0.1 0.2],...
            'Callback', @(src,event) configuracao (src,event,'anterior-centro',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&#9679</html>',...
            'ForegroundColor','r','FontSize',60,'Units','normalized','Position',[0.1 0.4 0.1 0.2],...
            'Callback', @(src,event) configuracao (src,event,'anterior-permanece',hax,som));
        
        uicontrol(hf1,'Style','pushbutton','String','<html>&larr</html>',...
            'FontSize',60,'Units','normalized','Position',[0.65 0.4 0.1 0.2],...
            'Callback', @(src,event) configuracao (src,event,'posterior-centro',hax,som));
        uicontrol(hf1,'Style','pushbutton','String','<html>&#9679</html>',...
            'ForegroundColor','r','FontSize',60,'Units','normalized','Position',[0.8 0.4 0.1 0.2],...
            'Callback', @(src,event) configuracao (src,event,'posterior-permanece',hax,som));
        disp('Tarefa 2')
    case ''
        error('Não foi selecionada nenhuma tarefa')
end

% Disparo da Placa de Aquisição-Plataforma
pause
delete(lh)

clc

% Mostrar os numeros aleatorios
disp(['O número aleatório: ' num2str(numero)])
disp(seq)
disp(['O número ' num2str(numero) ' se repete ' num2str(sum(seq==numero)) ' vezes']);

close all
end

function configuracao(~,~,choice,hax,som)
% Callback do painel de configuração das tarefas

% Variavel global para a posicao poder ser mudada em qualquer funcao
global pos;

% passo = [ant-pos med-lat];
passo = [67.015 26.35];
passo = [0.4 0.6] .* passo;

% Montando os retangulos conforme a escolha
switch choice
    case 'permanece'
        disp('Permanece no Centro')
        rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5];

    case 'centro-medial'
        disp('Movimenta do Centro para a Medial')
        rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5]-[0 passo(2)];

    case 'centro-lateral'
        disp('Movimenta do Centro para a Lateral')
        rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5]+[0 passo(2)];

    case 'centro-anterior'
        disp('Movimenta do Centro para o Anterior')
        rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5]-[passo(1) 0];
    
    case 'centro-posterior'
        disp('Movimenta do Centro para o Posterior')
        rectangle('Parent',hax,'Position',[42 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5]+[passo(1) 0];
        
    case 'medial-centro'
        disp('mce')
        rectangle('Parent',hax,'Position',[42 34.5-passo(2) 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5];
    
    case 'medial-permanece'
        disp('m fica')
        rectangle('Parent',hax,'Position',[42 34.5-passo(2) 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5-passo(2)];
    
    case 'lateral-centro'
        disp('latce')
        rectangle('Parent',hax,'Position',[42 34.5+passo(2) 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5];
        
    case 'lateral-permanece'
        disp('l fica')
        rectangle('Parent',hax,'Position',[42 34.5+passo(2) 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5+passo(2)];
  
    case 'anterior-centro'
        disp('antce')
        rectangle('Parent',hax,'Position',[42-passo(1) 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5];
        
    case 'anterior-permanece'
        disp('ant fica')
        rectangle('Parent',hax,'Position',[42-passo(1) 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42-passo(1) 34.5 34.5];
        
    case 'posterior-centro'
        disp('postce')
        rectangle('Parent',hax,'Position',[42+passo(1) 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42 34.5];
    
    case 'posterior-permanece'
        disp('p fica')
        rectangle('Parent',hax,'Position',[42+passo(1) 34.5 30 15],'EdgeColor','none','Facecolor','w');
        pos = [42+passo(1) 34.5];
        
    case ''
        error('Não foi selecionada nenhuma tarefa')
end

% Executar o som
if(som)
    executar_audio;
end

% Fechar Janela
closereq;
end

function stopWhenExceed(src,event,h)
% Funcao para acionamento do projetor
global pos;

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

function executar_audio
% Executa os sons
% A variaveis globais numero e seq (vetor) sao inicializadas nesta funcao
% e sao globais porque só podem ser mostradas ao final da tarefa

% Variaveis globais
global numero;      % numero aleatorio
global seq;         % sequencia aleatoria

% Iniciando o Som
au = load('audio1s.mat');
numero = randi(size(au.audio,2));
tamanho_seq = 10;
sound(au.audio(:,numero),au.Fs,au.Nbits);
pause(1)

% Restrição: O numero escolhido deve aparecer pelo menos uma vez
restricao = false;
while(~restricao)
    seq = randi(size(au.audio,2),[1 tamanho_seq]);
    restricao = sum(seq==numero);
end

pause(2)

% Remontando o audio aleatorimente
tempo = 0.1;
tamanho_final = length(seq)*length(au.audio)+tempo*au.Fs;
audio_final = repmat(au.ruido,floor(tamanho_final/length(au.ruido)),1);
audio_final = [audio_final ; au.ruido(1:tamanho_final-length(audio_final),1)];
inicial = 1;
final = length(au.audio);
audio_final(inicial:final)= au.audio(:,seq(1));

for i = 1:length(seq)-1
    inicial = 1+ i*length(au.audio)+tempo*au.Fs;
    final = inicial + length(au.audio)-1;
    audio_final(inicial:final)= au.audio(:,seq(i+1));
end

% Executar som da sequencia de numeros aletorios
sound(audio_final,au.Fs,au.Nbits);
end
