# Progetto-Sistemi-Elettronici &#x1F50C;

## Obiettivo
Realizzazione di un firmware che riceva dal PC tramite interfaccia seriale (EUSART) due comandi per regolare la luminosità dei LED della scheda.

## Strumenti utilizzati
- Hardware: PIC16F887 (clock interno 4 MHz)
- Scheda Cedar Pic Board
- Ambiente di sviluppo: Microchip MPLAB X IDE
- Linguaggio: Assembly
- LED: RD0
- Porta seriale: EUSART

## Esecuzione
Ricezione dati tramite EUSART
- Comandi:
  - (+) aumenta luminosità
  - (-) diminuisci luminosità
- Generazione manuale della PWM con TIMER1per regolare luminosità
- Microcontrollore in SLEEP quando possibile
- Risveglio dallo SLEEP: break sulla seriale
- Ricezione dati: gestita tramite polling
- Overflow timer1: gestito tramite interrupt

## Diagramma di flusso
![diagramma](https://github.com/AlessiaConti/Progetto-Sistemi-Elettronici/blob/main/diagramma.jpg)
