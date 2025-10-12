import pygame as pg
import random as rd
import nidaqmx
from nidaqmx.constants import AcquisitionType
import time

# Inicialização do Pygame
pg.init()
info = pg.display.Info()
screen_width = info.current_w
screen_height = info.current_h
screen = pg.display.set_mode((screen_width/2, screen_height/2))

# Cores
black = (0, 0, 0)
green = (0, 255, 0)
pink = (255, 0, 128)

# Variáveis de controle
rodando = True
imagem_aberta = False
esperando_estimulo = False
deteccao_em_progresso = False  # Evitar múltiplas detecções em um movimento
rodada = 0
maxrod = 12
clock = pg.time.Clock()
limiar_pressao = 0.2  # Threshold de pressão em volts
ultima_pressao = 0.0  # Última leitura de pressão
tipo_sorteado = None  # Armazena o tipo sorteado enquanto espera o estímulo
ultimo_tempo_deteccao = 0  # Tempo da última detecção (ms)
periodo_debounce = 500  # Período de debounce em ms (ajustável)
tempo_trigger = 0  # Tempo inicial para o delay do retângulo
tempo_mostra_retangulo = 1000  # Tempo antes de mostrar o retângulo (ms)

# Lista de tipos com 3 ocorrências de cada tipo (total de 12 elementos)
tipos = [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]
rd.shuffle(tipos)  # Embaralha a lista no início
indice_tipos = 0  # Índice para percorrer a lista embaralhada

# Configuração da task nidaqmx (uma vez só, para otimização)
try:
    task = nidaqmx.Task()
    task.ai_channels.add_ai_voltage_chan("Dev1/ai0")  # Escolher o canal certo
    # Sem cfg_timing para leitura on-demand (single sample), mais eficiente
except Exception as e:
    print(f"Erro ao criar task: {e}")
    task = None

# Função para ler pressão (otimizada, sem recriar task)
def ler_pressao():
    if task is None:
        return 0.0
    try:
        return task.read()  # Leitura single sample, sem cfg_timing
    except Exception as e:
        print(f"Erro ao ler pressão: {e}")
        return 0.0

# Função para verificar aumento de pressão (mudado de abs para detectar só aumentos)
def verificar_aumento_pressao(pressao_atual, ultima_pressao, limiar):
    return (pressao_atual - ultima_pressao) >= limiar

# Função para mostrar o retângulo
def mostra_retangulo(tipo):
    global imagem_aberta, rodada
    screen.fill(black)

    largura = int(screen_width * 0.2)
    altura = int(screen_height * 0.2)

    if tipo == 1:  # Verde perto
        x = screen_width // 2 - largura // 2
        y = screen_height // 2 - altura // 2
        cor = green
    elif tipo == 2:  # Verde longe
        x = screen_width - largura - 50
        y = screen_height // 2 - altura // 2
        cor = green
    elif tipo == 3:  # Rosa
        x = screen_width // 2 - largura // 2
        y = screen_height // 2 - altura // 2
        cor = pink
    elif tipo == 4:  # Nada
        x = screen_width // 2 - largura // 2
        y = screen_height // 2 - altura // 2
        cor = black
    else:
        return

    pg.draw.rect(screen, cor, (x, y, largura, altura))
    pg.display.flip()
    imagem_aberta = True
    print(f"Rodada {rodada}: Estímulo = {tipo}")

# Função para fechar a imagem
def fecha_img():
    global imagem_aberta, deteccao_em_progresso
    screen.fill(black)
    pg.display.flip()
    imagem_aberta = False
    deteccao_em_progresso = False  # Reseta a flag para a próxima rodada

# Calibração inicial da baseline (nova, para precisão)
print("Calibrando baseline...")
ultima_pressao = ler_pressao()  # Lê uma vez no início como baseline

# Loop principal
while rodando and rodada < maxrod:
    tempo_atual = pg.time.get_ticks()  # Tempo atual em ms
    for event in pg.event.get():
        if event.type == pg.QUIT or (event.type == pg.KEYDOWN and event.key == pg.K_ESCAPE):
            rodando = False
        elif event.type == pg.KEYDOWN:
            if event.key == pg.K_1 and not imagem_aberta and not esperando_estimulo:
                esperando_estimulo = True
                deteccao_em_progresso = False
                tipo_sorteado = tipos[indice_tipos]
                indice_tipos = (indice_tipos + 1) % len(tipos)
                rodada += 1
                ultimo_tempo_deteccao = 0  # Reseta o temporizador de debounce
                print(f"Rodada {rodada}: Aguardando aumento de pressão...")
            elif event.key == pg.K_2 and imagem_aberta:
                fecha_img()

    if esperando_estimulo and not imagem_aberta and not deteccao_em_progresso:
        pressao_atual = ler_pressao()

        print(pressao_atual)

        if (verificar_aumento_pressao(pressao_atual, ultima_pressao, limiar_pressao) and
                tempo_atual - ultimo_tempo_deteccao >= periodo_debounce):
            deteccao_em_progresso = True
            ultimo_tempo_deteccao = tempo_atual  # Marca o tempo da detecção para debounce
            tempo_trigger = tempo_atual  # Marca o tempo inicial para o delay do retângulo
            ultima_pressao = pressao_atual
        else:
            ultima_pressao = pressao_atual  # Atualiza baseline se não detectado

    # Bloco separado: Checa o delay após a detecção
    if deteccao_em_progresso and not imagem_aberta and (tempo_atual - tempo_trigger >= tempo_mostra_retangulo):
        mostra_retangulo(tipo_sorteado)
        esperando_estimulo = False

    clock.tick(60)  # Limita a 60 FPS

# Cleanup
pg.quit()
if task is not None:
    task.close()