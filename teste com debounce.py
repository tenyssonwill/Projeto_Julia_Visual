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
#screen = pg.display.set_mode((screen_width, screen_height), pg.FULLSCREEN)
screen = pg.display.set_mode((screen_width/2, screen_height/2))

# Cores
black = (0, 0, 0)
green = (0, 255, 0)
pink = (255, 0, 128)
yellow = (255, 255, 0)

# Variáveis de controle
rodando = True
imagem_aberta = False
esperando_estimulo = False
deteccao_em_progresso = False  # Evitar múltiplas detecções em um movimento
rodada = 0
maxrod = 12
clock = pg.time.Clock()
limiar_pressao = 0.1  # Threshold de pressão em volts
ultima_pressao = 0.0  # Última leitura de pressão
tipo_sorteado = None  # Armazena o tipo sorteado enquanto espera o estímulo
ultimo_tempo_deteccao = 0  # Tempo da última detecção (ms)
periodo_debounce = 500  # Período de debounce em ms (ajustável)
tempo_mostra_retangulo = 500  # Tempo antes de mostrar o retângulo (ms, substitui time.sleep)
tempo_trigger = 0

# Lista de tipos com 3 ocorrências de cada tipo (total de 12 elementos)
tipos = [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]
rd.shuffle(tipos)  # Embaralha a lista no início
indice_tipos = 0  # Índice para percorrer a lista embaralhada

# Função para ler pressão da placa Bertec
def ler_pressao():
    try:
        with nidaqmx.Task() as task:
            task.ai_channels.add_ai_voltage_chan("Dev1/ai0")  # Escolher o canal certo
            task.timing.cfg_samp_clk_timing(rate=1000, sample_mode=AcquisitionType.FINITE, samps_per_chan=100)
            pressao = task.read(number_of_samples_per_channel=1)[0]
            print('Pressão', pressao)
            return pressao
    except Exception as e:
        print(f"Erro ao ler pressão: {e}")
        return 0.0

# Função para verificar variação de pressão
def verificar_variacao_pressao(pressao_atual, ultima_pressao, limiar):
    return abs(pressao_atual - ultima_pressao) >= limiar

# Função para mostrar o retângulo
def mostra_retangulo(tipo):
    global imagem_aberta, rodada
    screen.fill(black)

    largura = int(screen_width * 0.2)
    altura = int(screen_height * 0.2)

    # Alinhar retângulos verdes (tipo 1 e 2) verticalmente
    if tipo == 1:  # Verde perto
        x = screen_width // 2 - largura // 2
        y = screen_height // 2 - altura // 2
        cor = green
    elif tipo == 2:  # Verde longe
        #x = screen_width - largura - 50
        x = screen_width // 2 - largura // 2
        y = screen_height // 2 - altura // 2
        #cor = green
        cor = yellow
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
                print(f"Rodada {rodada}: Aguardando variação de pressão...")
            elif event.key == pg.K_2 and imagem_aberta:
                fecha_img()

    if esperando_estimulo and not imagem_aberta and not deteccao_em_progresso:
        pressao_atual = ler_pressao()
        if (verificar_variacao_pressao(pressao_atual, ultima_pressao, limiar_pressao) and
                tempo_atual - ultimo_tempo_deteccao >= periodo_debounce):
            deteccao_em_progresso = True
            ultimo_tempo_deteccao = tempo_atual  # Marca o tempo da detecção para debounce
            tempo_trigger = tempo_atual  # Novo: Marca o tempo inicial para o delay do retângulo
            ultima_pressao = pressao_atual
        else:
            ultima_pressao = pressao_atual

    # Novo bloco separado: Checa o delay após a detecção (em iterações seguintes)
    if deteccao_em_progresso and not imagem_aberta and (tempo_atual - tempo_trigger >= tempo_mostra_retangulo):
        mostra_retangulo(tipo_sorteado)
        esperando_estimulo = False

    clock.tick(60)  # Limita a 60 FPS

pg.quit()