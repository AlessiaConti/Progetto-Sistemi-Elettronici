# Progetto-Sistemi-Elettronici &#x1F50C;

## Obiettivo
Sviluppo di un firmware che permette di regolare la luminosità dei LED di una scheda ricevendo dei comandi inseriti da PC tramite l'interfaccia seriale EUSART.

## Strumenti utilizzati
- Hardware: PIC16F887 Cedar Pic Board (clock interno 4 MHz)
- Ambiente di sviluppo: Microchip MPLAB X IDE
- Linguaggio: Assembly
- LED utilizzato: RD0
- Porta seriale: EUSART

![pic](img/pic.jpg)

## Esecuzione
Ricezione dati tramite EUSART
- Comandi:
  - (+) aumenta luminosità
  - (-) diminuisci luminosità
- Generazione manuale della PWM con TIMER1 per regolare luminosità
- Microcontrollore in SLEEP quando possibile
- Risveglio dallo SLEEP: break sulla seriale
- Ricezione dati: gestita tramite polling
- Overflow timer1: gestito tramite interrupt

## Diagramma di flusso
![diagramma](img/tesina.jpg)
