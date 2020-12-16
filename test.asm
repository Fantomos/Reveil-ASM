; dÈfinition du processeur 
PROCESSOR 16f18446 
#include <xc.inc> 
 
;------------------------------------ 

;definition de la configuration 
    
// CONFIG1 
config FEXTOSC = OFF    // External Oscillator mode selection bits (Oscillator not enabled) 
config RSTOSC = HFINT1  // Power-up default value for COSC bits (HFINTOSC (1MHz)) 
config CLKOUTEN = OFF   // Clock Out Enable bit (CLKOUT function is disabled; i/o or oscillator function on OSC2) 
config CSWEN = ON       // Clock Switch Enable bit (Writing to NOSC and NDIV is allowed 
config FCMEN = OFF      // Fail-Safe Clock Monitor Enable bit (FSCM timer disabled) 

// CONFIG2 
config MCLRE = ON       // Master Clear Enable bit (MCLR pin is Master Clear function) 
config PWRTS = OFF      // Power-up Timer Enable bit (PWRT disabled) 
config LPBOREN = OFF    // Low-Power BOR enable bit (ULPBOR disabled) 
config BOREN = ON       // Brown-out reset enable bits (Brown-out Reset Enabled, SBOREN bit is ignored) 
config BORV = LO        // Brown-out Reset Voltage Selection (Brown-out Reset Voltage (VBOR) set to 2.45V) 
config ZCD = OFF        // Zero-cross detect disable (Zero-cross detect circuit is disabled at POR.) 
config PPS1WAY = ON     // Peripheral Pin Select one-way control (The PPSLOCK bit can be cleared and set only once in software) 
config STVREN = ON      // Stack Overflow/Underflow Reset Enable bit (Stack Overflow or Underflow will cause a reset) 

  

// CONFIG3 
config WDTCPS = WDTCPS_31// WDT Period Select bits (Divider ratio 1:65536; software control of WDTPS) 
config WDTE = OFF       // WDT operating mode (WDT disabled regardless of sleep; SWDTEN ignored) 
config WDTCWS = WDTCWS_7// WDT Window Select bits (window always open (100%); software control; keyed access not required) 
config WDTCCS = SC      // WDT input clock selector (Software Control) 

  

// CONFIG4 
config BBSIZE = BB512   // Boot Block Size Selection bits (512 words boot block size) 
config BBEN = OFF       // Boot Block Enable bit (Boot Block disabled) 
config SAFEN = OFF      // SAF Enable bit (SAF disabled) 
config WRTAPP = OFF     // Application Block Write Protection bit (Application Block not write protected) 
config WRTB = OFF       // Boot Block Write Protection bit (Boot Block not write protected) 
config WRTC = OFF       // Configuration Register Write Protection bit (Configuration Register not write protected) 
config WRTD = OFF       // Data EEPROM write protection bit (Data EEPROM NOT write protected) 
config WRTSAF = OFF     // Storage Area Flash Write Protection bit (SAF not write protected) 
config LVP = ON         // Low Voltage Programming Enable bit (Low Voltage programming enabled. MCLR/Vpp pin function is MCLR.) 

  

// CONFIG5 
config CP = OFF         // UserNVM Program memory code protection bit (UserNVM code protection disabled) 

  

  

;------------------------------------ 
;assignation des port du pic 
#define BMode	PORTC,7  ; Bouton de selection de mode
#define BReglage    PORTC,6  ; Bouton de selection de reglage
#define validation	PORTC,4  ; Bouton de validation
#define potar	PORTC,0 ; Potentiomètre de sélèction de chiffre
#define led	LATA,2 ; Led fréquence de 1 Hz
#define seg_clk LATC,1 ;SCK Horloge 7 segments
#define seg_data LATC,2 ;SD1 Données 7 segments
#define seg_latch LATC,3 ;LT Validation 7 segments
#define buzzer LATC,5    ; Buzzer d'alarme
#define	TMR1F	PIR4,0	  ; Flag du Timer
#define GIE	INTCON,7    ; Activation des itnerruptions
;------------------------------------ 

;definition des variables 
PSECT  udata_bank0    ; debut de la ram 
temp0:ds 1 
temp1:ds 1 
temp2:ds 1 
Reglage:ds 1 ; Type de reglage
Mode:ds 1   ;  Mode affiché
Horloge_DHeure:ds 1 ; Horloge Dizianes d'heure
Horloge_Heure: ds 1 ; Horloge Heures
Horloge_DMin: ds 1  ; Horloge Dizaines de minutes	
Horloge_Min: ds 1   ; Horloge Minutes
Horloge_Sec: ds 1   ; Horloge Secondes
Chrono_DMin: ds 1 ; Chrono Dizianes d'heure
Chrono_Min: ds 1    ; Chrono Minutes
Chrono_DSec: ds 1   ; Chrono Dizaines Secondes
Chrono_Sec: ds 1    ; Chrono Secondes
Alarme_DHeure:ds 1 ; Alarme Dizaines d'heures
Alarme_Heure: ds 1 ; Alarme Heures
Alarme_DMin: ds 1 ; Alarme Dizaines Minutes
Alarme_Min: ds 1 ; Alarme Minutes
Alarme_Active: ds 1 ;Activation Alarme
Timer_cancel: ds 1 ; 

;------------------------------------ 
;definition des vecteurs de reset et d interruption 
PSECT resetVect,delta=2,class=code    

org 000H        ; vecteur de reset 
    goto initialisation 
   
org 004H        ; vecteur d'interruption 
    BANKSEL PIR4
    bcf	    TMR1F
    
    BANKSEL TMR1H	
    bsf	    TMR1H,7	; Règle le compteur sur une seconde	
    
    ;; Fait clignoter la led à la seconde
    BANKSEL LATA
    movlw   00000100B
    xorwf   LATA,F
    
    call Interuption_Sec
    
    BANKSEL PORTC
    retfie 
;------------------------------------ 

;debut du code source     
PSECT code      
 
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALISATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
initialisation: 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONFIGURATION I/O ;;;;;;;;;;;;;;;;;;;;;;;;;
    BANKSEL PORTA
    clrf    PORTA	; efface les PORT A, B et C
    clrf    PORTB
    clrf    PORTC
   
    BANKSEL    LATA     ; efface les valeurs de PORTA
    CLRF       LATA    
    
    BANKSEL TRISA  
    clrf    TRISA	; configure tous les pins du port A en sortie 	
    movlw   11010001B	; configure les pins du port C en entrée (1) et sorties (0)
    movwf   TRISC
   
    BANKSEL    ANSELC   
    movlw   00000001B ; configure les pins du port C en digital sauf RC0
    movwf   ANSELC
    movlw   11010000B	; configure les boutons en pull-up (1)
    movwf   WPUC
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONFIGURATION ADC ;;;;;;;;;;;;;;;;;;;;;;;;;
    BANKSEL ADPCH
    movlw   010000B	
    movwf   ADPCH	; configure le ADC sur le port RC0
    
    BANKSEL ADCON0
    clrf    ADREF	; congifure tension de réference du ADC sur Vcc
    movlw   11000000B	
    movwf   ADCON0	; configure le ADC
    bsf	   ADCON0,0
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONFIGURATION TIMER ;;;;;;;;;;;;;;;;;;;;;;;;;
    BANKSEL TMR1H	
    bsf	    TMR1H,7	; Met le compteur Timer1 à 32760 pour déclencher l'interruption dans 1 sec   
    
    BANKSEL T1CON	
    movlw   00000001B	; Active le Timer1
    movwf   T1CON

    BANKSEL T1GCON  
    clrf   T1GCON
    
    BANKSEL T1CLK
    movlw   00000111B	; Selectionne le quartz externe comme source pour Timer1
    movwf   T1CLK
 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;; CONFIGURATION INTERRUPTION ;;;;;;;;;;;;;;;;;;;;;;;;;
    BANKSEL PIE4
    bsf PIE4,0		; Active l'interruption de Timer1
    
    BANKSEL INTCON
    movlw   11000000B	; Active les interruptions
    movwf   INTCON
   
    BANKSEL PORTA
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;; INITIALISATION VARIABLES ;;;;;;;;;;;;;;;;;;;;;;;;;
    bcf	   seg_clk
    bcf	   seg_latch
  
    ;; Affiche mode horloge et pas de réglage
    movlw   00000001B
    movwf   Mode
    movlw   00000001B
    movwf   Reglage
    
    ;; Initialise toutes les variables à 0
    clrf    Chrono_DMin
    clrf    Chrono_Min
    clrf    Chrono_DSec
    clrf    Chrono_Sec
    clrf    Alarme_DHeure
    clrf    Alarme_Heure
    clrf    Alarme_DMin 	
    clrf    Alarme_Min 
    clrf    Alarme_Active
  
    ;; Met à jour l'heure lors du téléversement
    movlw   0x02
    movwf   Horloge_DHeure
    movlw   0x01
    movwf   Horloge_Heure
    movlw   0x04
    movwf   Horloge_DMin
    movlw   0x02
    movwf   Horloge_Min
       
    ;; Met à jour l'alarme lors du téléversement
    movlw   0x01
    movwf   Alarme_DHeure
    movlw   0x08
    movwf   Alarme_Heure
    movlw   0x00
    movwf   Alarme_DMin
    movlw   0x09
    movwf   Alarme_Min
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN INITIALISATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; BOUCLE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
boucle:                   
    btfss   BMode
    call    Affiche_Mode
    btfsc   BMode
    call    Selection_Mode
    goto    boucle

Selection_Mode:	;; Affiche le mode selectionné
    btfsc   Mode,0
    call    Horloge	;1er bit à 1 donc Horloge
    btfsc   Mode,1
    call    Chrono	;2eme bit à 1 donc Chrono
    btfsc   Mode,2
    call    Alarme	;3eme bit à 1 donc Alarme
    return

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN BOUCLE ;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; HORLOGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
Horloge:
    btfsc   Reglage,0	; sil le premier bit de Réglage est à 1 alors on affiche l'heure
    call    Affiche_Horloge
    btfsc   Reglage,1	; sil le second bit de Réglage est à 1 alors on modifie les dizaines d'heures....
    call    Reglage_Min
    btfsc   Reglage,2
    call    Reglage_DMin
    btfsc   Reglage,3
    call    Reglage_Heure
    btfsc   Reglage,4
    call    Reglage_DHeure
    return

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INCREMENTATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;
Incremente_Horloge_Sec:
    incf   Horloge_Sec
    movf   Horloge_Sec,W
    addlw  0xC5
    btfsc   STATUS,0
    call    Incremente_Horloge_Min
    return
    
Incremente_Horloge_Min:
    clrf   Horloge_Sec
    incf   Horloge_Min
    movf   Horloge_Min,W
    addlw  0xF6
    btfsc   STATUS,0
    call    Incremente_Horloge_DMin
    return

Incremente_Horloge_DMin:
    clrf   Horloge_Min
    incf   Horloge_DMin
    movf   Horloge_DMin,W
    addlw  0xFA
    btfsc   STATUS,0
    call    Incremente_Horloge_Heure
    return

Incremente_Horloge_Heure:
    clrf   Horloge_DMin
    incf   Horloge_Heure
    movf   Horloge_Heure,W
    btfss  Horloge_DHeure,1
    call   Test_Horloge_DHeure
    btfsc  Horloge_DHeure,1
    call    Test_reset_Horloge_Heure
    return

Test_Horloge_DHeure:
    addlw  0xF6
    btfsc  STATUS,0
    call   Incremente_Horloge_DHeure
    return
    
Incremente_Horloge_DHeure:
    incf    Horloge_DHeure
    clrf    Horloge_Heure
    return
    
Test_reset_Horloge_Heure:
    addlw  0xFC
    btfsc  STATUS,0
    call   Reset_Horloge_Heure
    return

Reset_Horloge_Heure:
    clrf   Horloge_DHeure
    clrf   Horloge_Heure
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN INCREMENTATION ;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; REGLAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Reglage_DHeure:
    BANKSEL  ADRESH
    movf    ADRESH,W
    BANKSEL  PORTC
    call Potar_Horloge_DHeure
    btfss   validation
    movwf Horloge_DHeure
    call Affiche_Horloge_Cligno
    return
    
Reglage_Heure:
     BANKSEL  ADRESH
    movf    ADRESH,W
    BANKSEL  PORTC
    call Potar_Horloge_Heure
    btfss   validation
    movwf Horloge_Heure
    call Affiche_Horloge_Cligno
    return
Reglage_DMin:
    BANKSEL  ADRESH
    movf    ADRESH,W
     BANKSEL  PORTC
    call Potar_DMin
    btfss   validation
    movwf Horloge_DMin
    call Affiche_Horloge_Cligno
    return
Reglage_Min:
     BANKSEL  ADRESH
    movf    ADRESH,W
     BANKSEL  PORTC
    call  Potar_Min
    btfss   validation
    movwf Horloge_Min
    call Affiche_Horloge_Cligno
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN REGLAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; AFFICHAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
Affiche_Horloge: ;; Affiche l'heure (HH:MM) sur les 7 segments
    movf    Horloge_Min,W 
    call    SetChiffreSeg   ; Envoi l'unité seconde
    movf    Horloge_DMin,W
    call    SetChiffreSeg   ; Envoi la dizaine seconde
    movf    Horloge_Heure,W
    call    SetChiffreSeg   ; Envoi l'unité heure
    movf    Horloge_DHeure,W
    call    SetChiffreSeg   ; Envoi la dizaine heure
    bsf	seg_latch	    ; Affiche le résultat
    bcf	seg_latch
    return

Affiche_Horloge_Cligno: 
    movf    Horloge_Min,W 
    btfsc   Reglage,1
    movlw   00010110B ;vide
    call    SetChiffreSeg
    nop
    movf    Horloge_DMin,W 
    btfsc   Reglage,2
    movlw   00010110B ;vide
    call    SetChiffreSeg
    
    movf    Horloge_Heure,W 
    btfsc   Reglage,3
    movlw   00010110B ;vide
    call    SetChiffreSeg
    
    movf    Horloge_DHeure,W 
    btfsc   Reglage,4
    movlw   00010110B ;vide
    call    SetChiffreSeg
    
    bsf	seg_latch
    bcf	seg_latch
    
    movlw   0x10
    call tempo
    call Affiche_Horloge
    movlw   0x40
    call tempo
    return
 
  
Affiche_Mode_Horloge:
    movlw   00010110B 
    call    SetChiffreSeg
    movlw   00010110B
    call    SetChiffreSeg
    movlw   00010110B
    call    SetChiffreSeg
    movlw   0x0C	;lettre H de la table
    call    SetChiffreSeg
     bsf	seg_latch
   bcf	seg_latch
    
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN AFFICHAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN HORLOGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CHRONO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
Chrono:
    call Affiche_Chrono
    btfsc BReglage	; sil le second bit de Réglage est à 1 alors on reset le chrono
    return
    clrf     Chrono_DMin
    clrf     Chrono_Min
    clrf     Chrono_Sec
    clrf     Chrono_DSec
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INCREMENTATION  ;;;;;;;;;;;;;;;;;;;;;;;;;
    
Incremente_Chrono_Sec:
    incf   Chrono_Sec
    movf   Chrono_Sec,W
    addlw  0xF6
    btfsc   STATUS,0
    call    Incremente_Chrono_DSec
    return
    
Incremente_Chrono_DSec:
    clrf    Chrono_Sec
    incf   Chrono_DSec
    movf   Chrono_DSec,W
    addlw  0xFA
    btfsc   STATUS,0
    call    Incremente_Chrono_Min
    return
    
Incremente_Chrono_Min:
    clrf   Chrono_DSec
    incf   Chrono_Min
    movf   Chrono_Min,W
    addlw  0xF6
    btfsc   STATUS,0
    call    Incremente_Chrono_DMin
    return

Incremente_Chrono_DMin:
    clrf   Chrono_Min
    incf   Chrono_DMin
    movf   Chrono_DMin,W
    addlw  0xF6
    btfsc   STATUS,0
    clrf    Chrono_DMin
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN INCREMENTATION  ;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; AFFICHAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Affiche_Chrono:		    ;; Affiche le chronomètre (MM:SS) sur les 7 segments
    movf    Chrono_Sec,W 
    call    SetChiffreSeg   ; Envoi l'unité seconde
    movf    Chrono_DSec,W
    call    SetChiffreSeg   ; Envoi la dizaine seconde
    movf    Chrono_Min,W
    call    SetChiffreSeg   ; Envoi l'unité minute
    movf    Chrono_DMin,W
    call    SetChiffreSeg   ; Envoi la dizaine minute
    bsf	seg_latch	    ; Affiche le résultat
    bcf	seg_latch
    return   
    
Affiche_Mode_Chrono:
    movlw   00010110B 
    call    SetChiffreSeg
    movlw   00010110B
    call    SetChiffreSeg
    movlw   00010110B
    call    SetChiffreSeg
    movlw   0x0B    ;lettre C de la table
    call    SetChiffreSeg
    bsf	seg_latch
    bcf	seg_latch
    return    
    
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN AFFICHAGE  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN CHRONO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ALARME ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
Alarme:
    btfsc   Reglage,0	; Si 1er bit à 1 alors aucun reglage
    call    Reglage_Alarme_Aucun
    btfsc   Reglage,1	; Si 2ème bit à 1 alors réglage Min
    call    Reglage_Alarme_Min
    btfsc   Reglage,2	; Si 3ème bit à 1 alors réglage DMin
    call    Reglage_Alarme_DMin
    btfsc   Reglage,3	; Si 4ème bit à 1 alors réglage Heure
    call    Reglage_Alarme_Heure
    btfsc   Reglage,4	; Si 5ème bit à 1 alors réglage DHeure
    call    Reglage_Alarme_DHeure
    return

 Test_Alarme:
    movf    Alarme_DHeure,W
    subwf   Horloge_DHeure,W
    incf    WREG
    decfsz  WREG
    return
    movf    Alarme_Heure,W
    subwf   Horloge_Heure,W
    incf    WREG
    decfsz  WREG
    return
    movf    Alarme_DMin,W
    subwf   Horloge_DMin,W
    incf    WREG
    decfsz  WREG
    return
    movf    Alarme_Min,W
    subwf   Horloge_Min,W
    incf    WREG
    decfsz  WREG
    return
    movf    Horloge_Sec,W
    decfsz  WREG
    return
    btfss   Alarme_Active,0
    return
    bsf	   buzzer
    return
    
 Toggle_Alarme:
    movlw   00000001B
    btfss   validation
    xorwf   Alarme_Active,F
    return
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; REGLAGE  ;;;;;;;;;;;;;;;;;;;;;;;;;
Reglage_Alarme_Aucun:
    btfsc   validation
    call    Affiche_Alarme
    btfss   validation
    call    Affiche_Mode_Alarme
    return

Reglage_Alarme_DHeure:
    BANKSEL  ADRESH
    movf    ADRESH,W
    BANKSEL  PORTC
    call Potar_Alarme_DHeure
    btfss   validation
    movwf Alarme_DHeure
    call Affiche_Alarme_Cligno
    return
    
Reglage_Alarme_Heure:
     BANKSEL  ADRESH
    movf    ADRESH,W
    BANKSEL  PORTC
    call Potar_Alarme_Heure
    btfss   validation
    movwf Alarme_Heure
    call Affiche_Alarme_Cligno
    return
    
Reglage_Alarme_DMin:
    BANKSEL  ADRESH
    movf    ADRESH,W
     BANKSEL  PORTC
    call Potar_DMin
    btfss   validation
    movwf Alarme_DMin
    call Affiche_Alarme_Cligno
    return
    
Reglage_Alarme_Min:
     BANKSEL  ADRESH
    movf    ADRESH,W
     BANKSEL  PORTC
    call Potar_Min
    btfss   validation
    movwf Alarme_Min
    call Affiche_Alarme_Cligno
    return
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN REGLAGE  ;;;;;;;;;;;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; AFFICHAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
    
       
Affiche_Alarme: ;; Affiche l'alarme (HH:MM) sur les 7 segments
    movf   Alarme_Min,W 
    call    SetChiffreSeg   ; Envoi l'unité seconde
    movf    Alarme_DMin,W
    call    SetChiffreSeg   ; Envoi la dizaine seconde
    movf    Alarme_Heure,W
    call    SetChiffreSeg   ; Envoi l'unité heure
    movf    Alarme_DHeure,W
    call    SetChiffreSeg   ; Envoi la dizaine heure
    bsf	seg_latch	    ; Affiche le résultat
    bcf	seg_latch
    return
    

    
Affiche_Alarme_Cligno: 
    movf    Alarme_Min,W 
    btfsc   Reglage,1
    movlw   00010110B ;vide
    call    SetChiffreSeg
    nop
    movf    Alarme_DMin,W 
    btfsc   Reglage,2
    movlw   00010110B ;vide
    call    SetChiffreSeg
    
    movf    Alarme_Heure,W 
    btfsc   Reglage,3
    movlw   00010110B ;vide
    call    SetChiffreSeg
    
    movf    Alarme_DHeure,W 
    btfsc   Reglage,4
    movlw   00010110B ;vide
    call    SetChiffreSeg
    
    bsf	seg_latch
    bcf	seg_latch
    
    movlw   0x10
    call tempo
    call Affiche_Alarme
    movlw   0x40
    call tempo
    return
    
       
Affiche_Mode_Alarme:
    movlw   00010110B 
    call    SetChiffreSeg
    movlw   00010110B
    call    SetChiffreSeg
    btfsc   Alarme_Active,0
    movlw   0x01
    btfss   Alarme_Active,0
    movlw   0x00
    call    SetChiffreSeg
    movlw   0x0A    ;Lettre A de la table
    call    SetChiffreSeg
     bsf	seg_latch
   bcf	seg_latch
  
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN AFFICHAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN ALARME ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERRUPTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Interuption_Sec:
    
    call   Incremente_Horloge_Sec
    call   Incremente_Chrono_Sec
    call   Test_Alarme
    
    btfss  BReglage ;si le bouton set est apuillé
    call   ReglageSet
    btfss  BMode ;si le bouton Mode est apuillé
    call   ModeSet
    
    btfsc  Reglage,0
    call   Toggle_Alarme
    
    
    
    return
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIN INTERRUPTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

    

    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CHANGEMENT MODE ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
ModeSet:
    rlf Mode,F
    bcf	Mode,0
    btfsc Mode,3
    call ResetMode
    call ResetReglage
    return
ResetMode:
    movlw   0x01
    movwf   Mode
    return

Affiche_Mode:
    bcf	  buzzer
    btfsc Mode,0
    call Affiche_Mode_Horloge
    btfsc Mode,1
    call Affiche_Mode_Chrono
    btfsc Mode,2
    call Affiche_Mode_Alarme
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FIN CHANGEMENT MODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; CHANGEMENT REGLAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ReglageSet:
    bcf STATUS,0
    rlf Reglage,F
    btfsc Reglage,5
    call ResetReglage
    return

ResetReglage:
    movlw   0x01
    movwf   Reglage
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FIN CHANGEMENT REGLAGE ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; REGISTRES 7 SEGMENTS ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
SetChiffreSeg: 
   call table
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   rlf	WREG,W
   call SetBitSeg
   return

    
SetBitSeg:
    btfss WREG,7
    call DataL
    btfsc WREG,7
    call DataH
    return
    
DataH:
    bsf	    seg_data
    bsf	    seg_clk
    bcf	    seg_clk
    return
    
DataL:
    bcf	    seg_data
    bsf	    seg_clk
    bcf	    seg_clk
    return
    
table:
    brw
    retlw   01111110B ;0   0
    retlw   00001010B ;1    1
    retlw   10110110B ;2    2
    retlw   10011110B ;3    3
    retlw   11001010B ;4    4
    retlw   11011100B ;5    5
    retlw   11111100B ;6    6
    retlw   00001110B ;7    7
    retlw   11111110B ;8    8
    retlw   11011110B ;9    9
    retlw   11101110B      ;A    10
    retlw   01110100B      ;C    11
    retlw   11101010B      ;H    12
    retlw   10110110B      ;S    13
    retlw   11110100B      ;E    14
    retlw   11011110B      ;    15
    retlw   11011110B	   ;    16
    retlw   11011110B	   ;    17
    retlw   11011110B	   ;    18	      
    retlw   11011110B	   ;    19
    retlw   11011110B	   ;    20	      
    retlw   11011110B	   ;    21
    retlw   00000000B	   ;Vide 22
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FIN REGISTRES 7 SEGMENTS ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; LECTURE POTAR  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     
   
Potar_Horloge_DHeure:
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x00
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x01
    movf    Horloge_Heure,W
    addlw   0xFC
    btfsc   STATUS,0  
    retlw   0x01
    retlw   0x02
    return
    
Potar_Horloge_Heure:  
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x00
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x01
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x02
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x03
    btfsc   Horloge_DHeure,1
    retlw   0x03
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x04
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x05
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x06
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x07
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x08
    retlw   0x09
    return
    
Potar_DMin:
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x00
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x01
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x02
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x03
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x04
    retlw   0x05
    return
    
Potar_Min:
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x00
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x01
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x02
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x03
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x04
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x05
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x06
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x07
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x08
    retlw   0x09
    return
    
    
Potar_Alarme_DHeure:
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x00
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x01
    movf    Alarme_Heure,W
    addlw   0xFC
    btfsc   STATUS,0  
    retlw   0x01
    retlw   0x02
    return
    
Potar_Alarme_Heure:  
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x00
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x01
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x02
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x03
    btfsc   Alarme_DHeure,1
    retlw   0x03
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x04
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x05
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x06
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x07
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x08
    retlw   0x09
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FIN LECTURE POTAR  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; TEMPO  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
     
tempo:     
    movwf   temp0        ; temp0 = Wreg 

tempo2:     
    movlw   249            ; Wreg = 249 
    movwf   temp1        ; temp1= Wreg en C temp1=249 

tempo3:     
    nop                ; no opÈration 
    decfsz  temp1,F        ; temp1 = temp1-1, si zero sauter l'instruction suivante 
    goto    tempo3 
    decfsz  temp0,F 
    goto    tempo2 
    return 
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FIN TEMPO  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
      
    
    end        ; fin du code source 

     

  

 


