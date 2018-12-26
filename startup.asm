	device zxspectrum128

; Memory layout:
; 0000-3FFF - ROM (16Kb)
; 4000-5AFF - Screen (6912 bytes)
; 5B00-82FF - Heap
; 8300-BBFF - Program code and data
; BC00-BDFF - Stack (512 bytes)
; BE00-BEFF - Interrupt vector table (257
;             bytes)
; BF01-BFBE - Unused
; BFBF-BFD2 - ISR
; BFD3-BFFF - Unused
; C000-FFFF - Paging area (16Kb)

	org 	8300h

_start

STACK	EQU	0BE00H
IVT	EQU	0BE00H
; Data to fill into IVT. Determines
; interrupt vector location
IVTDAT	EQU	0BFH

	DI
	IM	2
	LD	SP,STACK
	LD	A,10H
	LD	BC,07FFDH
	OUT	(C),A
	LD	HL,IVT
	LD	DE,IVT+1
	LD	(HL),IVTDAT
	LD	BC,0100H
	LDIR	;Fill the IVT
	LD	HL,ISRLOC
	LD	DE,ISR
	LD	BC,ISREND-ISR
	LDIR	;Transfer the ISR to its location
	LD	A,#BE ;(IVT+1) ;high byte
	LD	I,A
	EI

	LD	HL,5B00H ;init memory manager
	LD	BC,2800H
	CALL	dmm.IDMM

	CALL	main.PROG
; After the program quits, it returns here.
; Perform a reset into the TR-DOS
	LD	HL,0
	PUSH	HL
	JP	3D2FH

ISRLOC	PHASE	IVTDAT*256+IVTDAT
ISR	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	CALL	spkeyb.INTKEY
	CALL	wind.INTCUR
	CALL	main.INCCNTR
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	EI
	RET
ISREND	DEPHASE

; Fatal error routine. We could print
; a message here but we just halt.
SYSERR:	
	LD	A,2
	OUT	(254),A
	DI
	HALT

	include "spkeyb40.a80"
        include "wind.a80"
        include "main.asm"
	include "dmm.a80"
END

	savesna "telnet.sna", _start