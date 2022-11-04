;-------------------------------------------DEV

;S1 BIT P0.1
;S2 BIT P0.2
;CLK BIT P0.4
;SRL BIT P0.5
	
;-------------------------------------------PROD

S1 BIT P3.6
S2 BIT P3.7
CLK BIT P4.4
SRL BIT P4.5

CE1 BIT P1.1
CE2 BIT P1.4
IN1 BIT P3.2
IN2 BIT P1.0

P4 EQU 0C0H
P4SW EQU 0BBH

NUM EQU 77H								;ONES TENS HUNDREDS
ORD EQU 75H								;STEPPER ORDER CODE

;-------------------------------------------REGS UTILIZATION

;R0		FLAG
;R1 	4LOOP FOR 4PHASE 01-11-10-00
;R2		LOOP OUT OF R1 (eg. 5REV = 24STEPS/REV * 5REV / 4PHASE= 30 )
;R3		TIMEOUT LOOP FOR >65536us

;R6		ORD
;R7		8LOOP IN LS164
;DPTR 	USED IN DISPLAY-LS164

;-------------------------------------------STEPPER CALC

VAL_TH0 EQU 70H
VAL_TL0 EQU 71H
VAL_TIMEOUT_LOOP EQU 72H

;-------------------------------------------PROGRAM

ORG 00H
LJMP START
ORG 0BH
LJMP TIMER0
ORG 30H

START:
		LCALL INIT
		LCALL REV_POS_5					;40RPM
		LCALL DETECT_S1
		LCALL REV_NEG_1					;25RPM
		LCALL DETECT_S1
		LCALL REV_POS_INFI			;10RPM
		SJMP $
		
;-------------------------------------------SET_ORIENTATION + SET_THTL

SET_ANTI_CLOCKWISE:
    MOV ORD,#01111000B
    RET
	
SET_CLOCKWISE:
    MOV ORD,#00101101B
    RET
	
SET_THTL:
		MOV TL0,VAL_TL0
		MOV TH0,VAL_TH0
		RET
	
SET_TIMEOUT_LOOP:
		MOV R3,VAL_TIMEOUT_LOOP
		RET
	
;-------------------------------------------REV_POS_5 + REV_NEG_10 + REV_POS_INFI

REV_POS_5:
		MOV VAL_TL0,#0DCH				;40RPM(62.5ms)
		MOV VAL_TH0,#00BH
		MOV VAL_TIMEOUT_LOOP,#1
		LCALL SET_CLOCKWISE
		LCALL SET_THTL

		MOV R2,#30							;5REV = 24STEPS/REV / 4PHASE * 5REV= 30
		LCALL REV
		RET
		
REV_NEG_1:
		MOV VAL_TL0,#0F0H				;25RPM(100ms)
		MOV VAL_TH0,#0D8H
		MOV VAL_TIMEOUT_LOOP,#10;10ms * 10
		LCALL SET_ANTI_CLOCKWISE
		LCALL SET_THTL

		MOV R2,#6								;1REV = 24STEPS/REV / 4PHASE * 1REV= 6
		LCALL REV
		RET
	
	
REV_POS_INFI:
		MOV VAL_TL0,#058H				;10RPM(250ms)
		MOV VAL_TH0,#09EH
		MOV VAL_TIMEOUT_LOOP,#10;25ms * 10 
		LCALL SET_CLOCKWISE
		LCALL SET_THTL

REV_INFI:
		MOV R2,#6								;1REV = 24STEPS/REV / 4PHASE * 1REV= 6
		LCALL REV
		SJMP REV_INFI
		RET

;-------------------------------------------TIMER0 + REV + WAIT_FOR_T0

TIMER0:
		LCALL SET_THTL
		MOV R0,#1								;FLAG
		RETI

REV:
		MOV R6,ORD							;GET ORDER
		MOV R1,#4								;4 PHASE 01-11-10-00
STEP:
		LCALL DETECT_S2

		CLR P1.1								;!IMPORTANT OTHERWISE STRUCK
		CLR P1.4								;!IMPORTANT
		MOV A,R6
		RLC A
    MOV IN1,C
    RLC A
    MOV IN2,C
    MOV R6,A
		SETB P1.1								;!IMPORTANT
		SETB P1.4								;!IMPORTANT OTHERWISE STRUCK
    
		LCALL COUNT
    LCALL DISPLAY
    LCALL TIMEOUT						;CHECK TIMER FLAG R0 THEN NEXT STEP
	
    DJNZ R1,STEP
		DJNZ R2,REV
		RET
	
TIMEOUT:
		LCALL SET_TIMEOUT_LOOP
	
TIMEOUT_LOOP:
    MOV R0,#0								;FLAG
    SETB TR0								;START TIMER0
    CJNE R0,#1,$						;WAIT FOR TIMER0 TO SET FLAG
		CLR TR0
	
		DJNZ R3,TIMEOUT_LOOP
		RET

;-------------------------------------------DETECT S1 + S2

DETECT_S1:
		JB S1,$									;IF KEYDOWN NEXT
		JNB S1,$								;IF KEYUP NEXT
		RET

DETECT_S2:
		JNB S2,$								;IF KEYUP NEXT | IF KEY DOWN LOOP
		RET

;-------------------------------------------INIT + INIT_COUNT + INIT_T0M2----OK!

INIT:
		MOV P4SW,#70H						;SET P4.654 AS IO PORT
		LCALL INIT_COUNT				;CLR NUM+0+1+2
		LCALL INIT_T0
		SETB CE1
		SETB CE2
		RET

INIT_COUNT:
		MOV NUM,#0      
    MOV NUM+1,#0
    MOV NUM+2,#0
		RET
	
INIT_T0:
		MOV TMOD,#01H
		SETB EA
		SETB ET0
		RET

;-------------------------------------------COUNT + DISPLAY + LS164----OK!

COUNT:
		MOV A,NUM
    CJNE A,#9,ONES           ;INC ONES
    MOV NUM,#0 
	
		MOV A,NUM+1
    CJNE A,#9,TENS           ;ONES OVERFLOW TO INC TENS
    MOV NUM+1,#0 
	
		MOV A,NUM+2
    CJNE A,#9,HUNDREDS       ;TENS OVERFLOW TO HUNDREDS
    MOV NUM+2,#0
ONES:
    INC A
		MOV NUM,A
    SJMP BRECK
TENS:
    INC A
		MOV NUM+1,A
    SJMP BRECK
HUNDREDS:
    INC A
		MOV NUM+2,A
	
BRECK:
    RET

DISPLAY:
    MOV A,NUM	  							;SRL IN ONES
    ACALL LS164    
    MOV A,NUM+1								;SRL IN TENS
    ACALL LS164 
    MOV A,NUM+2								;SRL IN HUNDREDS
    ACALL LS164
		RET
	
LS164:
		MOV DPTR,#T_7SEG
    MOVC A,@A+DPTR
    MOV R7,#8
FORR7:
    CLR CLK
    RLC A
    MOV SRL,C
    SETB CLK
    DJNZ R7,FORR7
		RET

;------------------------------------

T_7SEG:
		;CA IN LAB
		DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H,80H,90H

END