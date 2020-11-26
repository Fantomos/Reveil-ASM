;------------------------------------ 
; ce programme fait clignoter une led sur la carte curiosity 
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
#define bouton1	PORTC,7 
#define bouton2	PORTC,6 
#define bouton3	PORTC,4
#define potar	PORTC,0
#define led	PORTA,2 
#define seg_clk PORTC,1 ;SCK
#define seg_data PORTC,2 ;SD1
#define seg_latch PORTC,3 ;LT
;------------------------------------ 

;definition des variables 
PSECT  udata_bank0    ; debut de la ram 
w_temp: ds 1        ; chaque variable est codÈe sur 1 octet 
status_temp:ds 1 
temp0:ds 1 
temp1:ds 1 
temp2:ds 1 
nbBit:ds 1
valtable:ds 1

     

;------------------------------------ 

;definition des vecteurs de reset et d interruption 
PSECT resetVect,delta=2,class=code    

org 000H        ; vecteur de reset 
    goto main 

org 004H        ; vecteur d'interruption 
    retfie 
;------------------------------------ 

;debut du code source     
PSECT code     
;programme principal 

main: 
    movlw   0xFE
    movwf   valtable
    movlw   0x06
    ADDWF   valtable,W
    call    initialisation        ; appeler le sous programme initialisation 
    bcf	    seg_clk
    bcf	   seg_latch

boucle:                    ; repère dans le programme 
    movlw   0xFF
    call    tempo
    movlw   0xFF
    call    tempo
    movlw   0xFF
    call    tempo
    movlw   0xFF
    call    tempo
    movlw   0x01
    call    setChiffreSeg
    ;btfss  bouton1
    ;call   dataH
    ;btfss   bouton2
    ;call   dataL
   ; btfss  bouton3
   ; bsf	   seg_latch
   ; bcf	   seg_latch
    ;call lecturePotarON
    ;call lecturePotarOFF
    ;bsf led;
    ;movlw   0xFF;
    ;call    tempo;
    ;bcf	    led;
    ;movlw   0xFF;
    ;call    tempo;
    goto    boucle

;------------------------------------ 

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
   
   bsf	seg_latch
   bcf	seg_latch
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
    
lecturePotarOFF:
   BANKSEL  ADCON0
   bcf	   ADCON0,0
   BANKSEL  PORTC
   return
   
lecturePotarON:
   BANKSEL  ADCON0
   bsf	   ADCON0,0
   BANKSEL  PORTC
   return
;sous programme d'initialisation du microcontroleur    

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
    
    BANKSEL PORTA
    
   
    
    
   
	
    
    return		; fin du sous programme 

    
    
; Tempo    
    
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
    addwf   PCL,F
    retlw   01111110B ;0
    retlw   00001010B ;1
    retlw   10110110B ;2
    retlw   10011110B ;3
    retlw   11001010B ;4
    retlw   11011100B ;5
    retlw   11111100B ;6
    retlw   00001110B ;7
    retlw   11111110B ;8
    retlw   11011110B ;9
    
    
    end        ; fin du code source 

     

  

 


