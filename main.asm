	module main

	include "wind.mac"
	include "_rs232/sockets.mac"
PROG
	LD	HL,5B00H
	LD	BC,2800H
	CALL	dmm.IDMM

;	LD	HL,WRK_WIND
;	CALL	wind.PRINTW
	_printw WRK_WIND
	CALL	wind.ENDW
	LD	HL,msg_keys
	CALL	wind.PRINTS
	CALL	wind.CUR_ON

mloop   call    spkeyb.CONIN
	jp	z,mloop

	cp	01Dh
	jp	z,exit
;	push 	af
;	call	wind.PRINTC
;	LD	A,32
;	call	wind.PRINTC
;	pop	af
;	call 	wind.A_HEX
;	LD	A,32
	call	wind.PRINTC
	jp 	mloop

exit	CALL	wind.CUR_OFF
	CALL	wind.ENDW
	RET

WRK_WIND:
	DB 0,0
	DB 32,24
	DB 00001111B
	DB 00000011B
	DB 0,0
	DB 0
	DB 1,'Telnet client v0.0.1',0

msg_keys
        DB "Press RShift+Q for exit.",13,13,0

;buffer for intpue
inp_bufer
	DEFS 255,0

	endmodule