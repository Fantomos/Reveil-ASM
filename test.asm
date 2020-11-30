;------------------------------------ 
; 
; la led est sur la broche RA2 elle est active à 0 
; un bouton poussoir est disposé sur la broche RC2     
;------------------------------------ 

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
#define BMode	PORTC,7 
#define BReglage    PORTC,6 
#define bouton3	PORTC,4
#define potar	PORTC,0
#define led	LATA,2 
#define seg_clk LATC,1 ;SCK
#define seg_data LATC,2 ;SD1
#define seg_latch LATC,3 ;LT
#define	TMR1F	PIR4,0
#define GIE	INTCON,7
;------------------------------------ 

;definition des variables 
PSECT  udata_bank0    ; debut de la ram 
temp0:ds 1 
temp1:ds 1 
temp2:ds 1 
nbBit:ds 1
    
Reglage:ds 1 ; variable indiquant en quel mode de reglage on se trouve
Mode:ds 1   ; variable indiquant le mode dans lequel on est

DHeure:ds 1 ; les dizianes d'heure
Heure: ds 1 ;les heures
DMin: ds 1  ; les dizaines de minutes	
Min: ds 1   ;les minutes

CDMin: ds 1 ; valeur des temp chrono
CMin: ds 1
CDSec: ds 1
CSec: ds 1
  
ADHeure:ds 1 ; L'alarme
AHeure: ds 1
ADMin: ds 1  	
AMin: ds 1 
    

Potar: ds 1  ;0 à 9
Clignotement: ds 1   

;------------------------------------ 

;definition des vecteurs de reset et d interruption 
PSECT resetVect,delta=2,class=code    

org 000H        ; vecteur de reset 
   
    goto main 

org 004H        ; vecteur d'interruption 
    BANKSEL PIR4
    bcf	    TMR1F
    
    BANKSEL TMR1H
    bsf	    TMR1H,7
    
    BANKSEL LATA
    movlw   00000100B
    xorwf   LATA,F
    call interuptsec
    retfie 
;------------------------------------ 

;debut du code source     
PSECT code     
;programme principal 

main: 
    call    initialisation        ; appeler le sous programme initialisation 
    bcf	    seg_clk
    bcf	   seg_latch
    ;;;;set les valeurs de temps
    movlw   00000001B
    movwf   Mode
    movlw   00000001B
    movwf   Reglage
    
    movlw   0x00
    movwf   DHeure
    movlw   0x09
    movwf   Heure
    movlw   0x01
    movwf   DMin
    movlw   0x09
    movwf   Min
    clrf    CDMin
    clrf    CMin
    clrf    CDSec
    clrf    CSec
    clrf    ADHeure
    clrf    AHeure
    clrf    ADMin 	
    clrf    AMin 
    clrf    Clignotement
boucle:                    ; repère dans le programme 
    btfsc   Mode,0
    call    Horloge		;si 1er bit de Mode à 1 alors on va dans la boucle heure ext
    btfsc   Mode,1
    call    Chrono
    btfsc   Mode,2
    call    Alarme
    btfss   BMode
    call    AfficheMode
    
    
    goto    boucle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Heure;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Horloge:
    btfsc   Reglage,0	; sil le premier bit de Réglage est à 1 alors on affiche l'heure
    call    afficheHeure
    btfsc   Reglage,1	; sil le second bit de Réglage est à 1 alors on modifie les dizaines d'heures....
    call    ReglageDHeure
    btfsc   Reglage,2
    call    ReglageHeure
    btfsc   Reglage,3
    call    ReglageDMin
    btfsc   Reglage,4
    call    ReglageMin
    return
ReglageDHeure:
    call LecturePotar
    movwf DHeure
    movlw 00001000B
    movwf Clignotement
    call AfficheHeureCligno
    return
ReglageHeure:
    call LecturePotar
    movwf Heure
    movlw 00000100B
    movwf Clignotement
    call AfficheHeureCligno
    return
ReglageDMin:
    call LecturePotar
    movwf DMin
    movlw 00000010B
    movwf Clignotement
    call AfficheHeureCligno
    return
ReglageMin:
    call LecturePotar
    movwf Min
    movlw 00000001B
    movwf Clignotement
    call AfficheHeureCligno
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Fin Heure ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Chrono ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Chrono:
    btfsc Reglage,0	; sil le premier bit de Réglage est à 1 alors on affiche le chrono
    call affichechrono
    btfsc Reglage,1	; sil le second bit de Réglage est à 1 alors on reset le chrono
    call ClearChrono
    return
ClearChrono:
    clrf    CDMin
    clrf    CMin
    clrf    CSec
    clrf    CDSec
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  Chrono ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Alarme ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Alarme:
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; interuption;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
interuptsec:
    
    btfss  BReglage ;si le bouton set est apuillé
    call   ReglageSet
    btfss  BMode ;si le bouton Mode est apuillé
    call   ModeSet
    
    
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Fin interuption ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Reglage et mode;;;;;;;;;;;;;;;;;;;;;;;;;;;
ModeSet:
    rlf Mode
    btfss Mode,3
    call ResetMode
    call ResetReglage
    return
ResetMode:
    movlw   0x01
    movwf   Mode
    return
ReglageSet:
    rlf Reglage
    btfss Reglage,5
    call ResetReglage
    btfss Mode,1
    call ModeChronoReglage
    return
ModeChronoReglage:
    btfss Reglage,2
    call ResetReglage 
    return
ResetReglage:
    movlw   0x01
    movwf   Reglage
    return
AfficheMode:
    btfss Mode,0
    call AfficheModeHeure
    btfss Mode,1
    call AfficheModeChrono
    btfss Mode,2
    call AfficheModeAlarme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; fin Réglage et mode ;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  7 Segement  ;;;;;;;;;;;;;;;;;;;;;;;;;  
affichechrono:
    movf    CSec,W 
    call    setChiffreSeg
    movf    CDSec,W
    call    setChiffreSeg
    movf    CMin,W
    call    setChiffreSeg
    movf    CDMin,W
    call    setChiffreSeg
    bsf	seg_latch
    bcf	seg_latch
    return
afficheHeure:
    movf   Min,W 
    call    setChiffreSeg
    movf    DMin,W
    call    setChiffreSeg
    movf    Heure,W
    call    setChiffreSeg
    movf    DHeure,W
    call    setChiffreSeg
    bsf	seg_latch
    bcf	seg_latch
    return
AfficheHeureCligno:
    movf    Min,W 
    btfss   Clignotement,0
    movlw   00010110B ;vide
    call    setChiffreSeg
    
    movf    DMin,W 
    btfss   Clignotement,1
    movlw   00010110B ;vide
    call    setChiffreSeg
    
    movf    Heure,W 
    btfss   Clignotement,2
    movlw   00010110B ;vide
    call    setChiffreSeg
    
    movf    DHeure,W 
    btfss   Clignotement,3
    movlw   00010110B ;vide
    call    setChiffreSeg
     bsf	seg_latch
   bcf	seg_latch
    
    movlw   0xFF
    call tempo
    call afficheHeure
    call tempo
    return
AfficheModeAlarme:
    movlw   00010110B 
    call    setChiffreSeg
    movlw   00010110B
    call    setChiffreSeg
    movlw   00010110B
    call    setChiffreSeg
    movlw   0x0A    ;Lettre A de la table
    call    setChiffreSeg
     bsf	seg_latch
   bcf	seg_latch
    movlw   0xFF
    call tempo
    movlw   0xFF
    call tempo
    return
AfficheModeChrono:
    movlw   00010110B 
    call    setChiffreSeg
    movlw   00010110B
    call    setChiffreSeg
    movlw   00010110B
    call    setChiffreSeg
    movlw   0x0B    ;lettre C de la table
    call    setChiffreSeg
     bsf	seg_latch
   bcf	seg_latch
    movlw   0xFF
    call tempo
    movlw   0xFF
    call tempo
    return
AfficheModeHeure:
    movlw   00010110B 
    call    setChiffreSeg
    movlw   00010110B
    call    setChiffreSeg
    movlw   00010110B
    call    setChiffreSeg
    movlw   0x0C	;lettre H de la table
    call    setChiffreSeg
     bsf	seg_latch
   bcf	seg_latch
    movlw   0xFF
    call tempo
    movlw   0xFF
    call tempo
    return
setChiffreSeg: 
   call table
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   rlf	WREG,W
   call setBitSeg
   return

    
setBitSeg:
    btfss WREG,7
    call dataL
    btfsc WREG,7
    call dataH
    return
    
dataH:
    bsf	    seg_data
    bsf	    seg_clk
    bcf	    seg_clk
    return
    
dataL:
    bcf	    seg_data
    bsf	    seg_clk
    bcf	    seg_clk
    return
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  Fin 7 SEG  ;;;;;;;;;;;;;;;;;;;;;;;; 
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Potar  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
LecturePotar:
   BANKSEL  ADCON0
   bsf	   ADCON0,0
   call Comparaison
   movwf    potar
   bcf	   ADCON0,0
   BANKSEL  PORTC
   return
Comparaison:
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
    addlw   0x19
    btfsc   STATUS,0
    retlw   0x09
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Fin Potar ;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Initialisation;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initialisation: 
    BANKSEL PORTA
    clrf    PORTA	; efface les PORTA, B et C
    clrf    PORTB
    clrf    PORTC
   
    BANKSEL    LATA     ; efface la dernière valeur de PORTA
    CLRF       LATA    
    
    BANKSEL TRISA  
    clrf    TRISA	; configure tous les pins du port A en sortie 	
    movlw   11010001B	; configure les pins du port C en entrée
    movwf   TRISC
   
    BANKSEL    ANSELC   
    movlw   00000001B ; configure les pins du port C en digital sauf RC0
    movwf   ANSELC
    movlw   11010000B	; configure les boutons en pull-up
    movwf   WPUC
    
    
    BANKSEL ADPCH
    movlw   010000B	
    movwf   ADPCH	; configure le ADC sur le port RC0
    BANKSEL ADCON0
    clrf    ADREF	; congifure tension de réference du ADC
    movlw   11000001B	
    bsf	    ADCON0,0
    movwf   ADCON0	; configure le ADC
    
    ; CONFIGURATION TIMER 
    BANKSEL TMR1H	
    bsf	    TMR1H,7	; Met le compteur Timer1 à 32760
    
    BANKSEL T1CON	
    movlw   00000101B	; Active le Timer1
    movwf   T1CON
    
    BANKSEL T1GCON  
    clrf   T1GCON
    
    BANKSEL T1CLK
    movlw   00000111B	; Selectionne le quartz externe comme source pour Timer1
    movwf   T1CLK
    
 
    BANKSEL PIE4
    bsf PIE4,0		; Active l'interruption de Timer1
    
    BANKSEL INTCON
    movlw   11000000B	; Active les interruptions
    movwf   INTCON
    BANKSEL PORTA
    
    return		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Fin initialisation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Tempo;;;;;;;;;;;;;;;;;;;;;;;;    
tempo:     
    movwf   temp0        ; temp0 = Wreg 

boucle2:     
    movlw   249            ; Wreg = 249 
    movwf   temp1        ; temp1= Wreg en C temp1=249 

boucle3:     
    nop                ; no opÈration 
    decfsz  temp1,F        ; temp1 = temp1-1, si zero sauter l'instruction suivante 
    goto    boucle3 
    decfsz  temp0,F 
    goto    boucle2 
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
    
    
    end        ; fin du code source 

     

  

 


