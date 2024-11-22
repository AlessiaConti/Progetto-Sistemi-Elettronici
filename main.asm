

; ****************
;   TESINA N.16
; ****************
	
	
	list	  p=16f887	 
	#include  <p16f887.inc>   
	

    
; Configuration bits 
        __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _CP_OFF & _WDT_OFF & _BOR_OFF & _PWRTE_OFF & _LVP_OFF & _DEBUG_OFF & _CPD_OFF  
   

; Definizione costanti
ton_10ms	EQU		(.65536 - .327)	  ; valore iniziale del t_on
delta           EQU             (.65536 - .82)    ; valore per incremento/decremento t_on (delta=2,5ms)
	
	   
; Definizione variabili
	UDATA_SHR                               ; Limite memoria = 16 byte
                                                        
w_temp		RES		1		; variabili utilizzate per salvataggio di contesto
status_temp	RES		1			
pclath_temp	RES		1			

ton_tmp         RES		1               ; variabile temporanea per valore corrente di t_on
comando		RES		1               ; variabile temporanea per comando ricevuto da utente

	
     
; Vettore di reset
RST_VECTOR	CODE	0x0000
			pagesel	start			
			goto	start			
		
			
; ******** PROGRAMMA PRINCIPALE ********
			
MAIN      CODE
        
start
                ; inizializzazione hardware
		pagesel	INIT_HW			
		call	INIT_HW	 
		
		; inizializzazione stato LED (tutti LED spenti)
		banksel	PORTD			
		clrf	PORTD 
		
		; inizializzazione stato LED (LED RD0 acceso)
		movlw	0x01			; carica costante 0x01 in W
		banksel PORTD		        ; selezione banco RAM di PORTD
		movwf	PORTD			; copia W in PORTD 
		
		; elimina eventuali byte rimasti nella FIFO	
                banksel RCREG
		movf RCREG,w      
		
		clrw
		; copia il valore iniziale del timer nella variabile ton_tmp
		movlw ton_10ms
		movwf ton_tmp
		
		; carica contatore timer1 con valore iniziale per contare 10 ms
 		pagesel	ricarica_tmr1
		call	ricarica_tmr1
					
		; abilita interrupt timer1
		banksel	PIE1
		bsf	PIE1, TMR1IE
      
		; abilita interrupt periferiche
		banksel PIE1
		bsf INTCON,PEIE 
			
		; Abilita gli interrupt globalmente
		bsf INTCON, GIE						
		

      
main_loop               
		; Il loop principale inizia entrando in sleep.
		        
		; Il PIC non puo' uscire dallo sleep tramite invio di un
                ; comando poichè la seriale non funziona in sleep. Il risveglio
                ; puo' essere effettuato tratmite l'invio di un break sulla seriale.
		
		bcf INTCON,GIE    ; disabilita interrupt globalmente, in modo
	                          ;  da avere risveglio dallo sleep ma non
		                  ;  ingresso in interrupt
		banksel BAUDCTL
		bsf BAUDCTL,WUE   ; abilita wake-up da seriale
		banksel PIE1
	        bsf PIE1,RCIE     ; abilita interrupt ricezione seriale
		        
                ; ingresso in sleep
		banksel PORTD
		bcf PORTD,0       ; LED 1 spento (ad indicare sleep)
		sleep
			
	        ; risveglio: break ricevuto
		banksel RCREG
		movf RCREG,w      ; legge RCREG per azzerare flag interrupt
		banksel PIE1
	        bcf PIE1,RCIE     ; disabilita interrupt porta seriale
		bsf INTCON,GIE    ; abilita interrupt globalmente per permettere trasmissione seriale
		banksel PORTD
		bsf PORTD,0       ; LED 1 acceso (ad indicare stato attivo)
	
			
	
		
attesa_comando
		; loop attesa comando da seriale
		banksel PIR1
		btfss PIR1, RCIF
		goto $-1
		
		; ricevuto un byte
		banksel RCREG
		movf RCREG,w
		movwf comando        ; memorizza byte ricevuto in "comando"
		
		; interpretazione comando
		movlw '+'
		subwf comando,w
		btfsc STATUS,Z       ; confronta comando con '+'
		goto aumenta_lum     ; se uguale, chiama subroutine per aumentare luminosità
		
		movlw '-'
		subwf comando,w
		btfsc STATUS,Z       ; confronta comando con '-'
		goto diminuisci_lum  ; se uguale, chiama subroutine per diminuire luminosità

		
		goto attesa_comando
		
aumenta_lum
		; subroutine per aumentare luminosità
		
		movlw delta		
		addwf ton_tmp, f      ; ton_tmp + delta		
		rlf ton_10ms, w       ; w = ton_10ms*2		
			
		decfsz ton_tmp, f     ; decrementa: ton_tmp - w , skip if 0
		
		goto ricarica_tmr1    ; ricarica timer con valore aggiornato di ton_tmp
		
		goto ripristina       ; se ton_tmp=ton_10ms (limite raggiunto) chiama subroutine 'ripristina'	
				
		
		goto attesa_comando   ; torno all'attesa del comando con ton_tmp incrementato
		
		
diminuisci_lum	
		; subroutine per diminuire luminosità
	
		movlw delta           ; w = delta		
		subwf ton_tmp, f      ; ton_tmp - w		
		
		btfsc STATUS,Z        ; confronta delta con ton_tmp		
		goto ripristina       ; se uguale (limite raggiunto) chiama subroutine 'ripristina'				 
		
		goto ricarica_tmr1    ; altrimenti ricarica timer con valore aggiornato di ton_tmp		
		
		goto attesa_comando   ; torno all'attesa del comando con ton_tmp decrementato
		
		
ripristina  	
		; Ripristina variabile ton_tmp al valore iniziale ton_10ms
		movlw ton_10ms
		movwf ton_tmp
		
		; Ricarica timer con valore iniziale (ton_tmp=ton_10ms)
		goto ricarica_tmr1
		goto attesa_comando  
		
ricarica_tmr1
		; Ricarica contatore timer1 con valore corrente del t_on (ton_tmp)
		
		banksel	T1CON
		bcf	T1CON, TMR1ON	      ; arresta timer
		
		banksel	TMR1L
		movlw	low  ton_tmp        ; 8 bit più bassi di ton_tmp 
		movwf	TMR1L
		movlw	high ton_tmp        ; 8 bit più alti di ton_tmp
		movwf	TMR1H
		
		banksel	PIR1
		bcf	PIR1, TMR1IF	      ; azzera flag interrupt
		banksel	T1CON
		bsf	T1CON, TMR1ON	      ; riattiva timer
		
		return		
		
                
		
		goto	main_loop    ; ripete il loop principale del programma
		
		
	
; ******** SUBROUTINE PER INIZIALIZZAZIONE HARDWARE ********		
INIT_HW     
			
				
		; registro INTCON
		clrf	INTCON      ; disabilitare interrupt							
		
		; porte I/O: porta D
		; pin RD0-RD3 settati come output digitali (LED)
		; pin RD4-RD7 non usati (input digitali)
		banksel PORTD
		clrf PORTD	
		movlw 0xF0
		banksel TRISD
		movwf TRISD
		
		; clock che fa funzionare l'USART (clock interno 8 MHz)
		movlw B'01110001'
		banksel OSCCON
		movwf OSCCON
		
		; EUSART
	        ; baud rate = 38400 (BRGH = 1, BRG16 = 0)
	        ; TXEN = 1, SPEN = 1, CREN = 1	    
		
		movlw B'00100100'
		banksel TXSTA
		movwf TXSTA
			     
		movlw B'10010000'
		banksel RCSTA
		movwf RCSTA
		
		banksel BAUDCTL
		clrf BAUDCTL
	         
		movlw .25
		banksel SPBRG
		movwf SPBRG
		
		
		; Timer1
		banksel	T1CON
		movlw	B'00001110'    ; tmr off
		movwf	T1CON

		return	
	
			
		
; ******** ROUTINE DI INTERRUPT ********
		
IRQ			CODE	0x0004
INTERRUPT		
		; salvataggio di contesto
		movwf	w_temp			
		swapf	STATUS,w		
		movwf	status_temp		
		movf	PCLATH,w		
		movwf	pclath_temp
			
		
		
test_timer1     ; interrupt generato da overflow tmr1
		; testa evento overflow timer1 (TMR1IF + TMR1IE)
		banksel	PIR1
		btfss	PIR1,TMR1IF
		goto	irq_end
		banksel	PIE1
		btfss	PIE1,TMR1IE
		goto	irq_end
		; avvenuto interrupt timer1: inverti stato led
		movlw	0x01
		banksel	PORTD
		xorwf	PORTD,f 
		; ricarica contatore timer1 con ton_tmp
		pagesel	ricarica_tmr1
		call	ricarica_tmr1
		; fine evento timer1
		goto	irq_end
		
		
		; ripristino di contesto
irq_end		movf	pclath_temp,w	
		movwf	PCLATH			
		swapf	status_temp,w		
		movwf	STATUS			
		swapf	w_temp,f		
		swapf	w_temp,w		
		
		retfie		
			
			
			
                END


