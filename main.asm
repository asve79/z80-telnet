	module main

PROG
	LD	HL,5B00H
	LD	BC,2800H
	CALL	dmm.IDMM

	LD	HL,WRK_WIND
	CALL	wind.PRINTW
	CALL	wind.ENDW
	CALL	wind.CUR_ON

mloop   call    spkeyb.CONIN
	jp	z,mloop

	cp	13
	jp	z,exit
	call	wind.PRINTC
	jp 	mloop

exit	CALL	wind.CUR_OFF
	CALL	wind.ENDW
	RET

resetkey
       ld hl,23560         ; LAST K system variable.
       ld (hl),0           ; put null value there.
       ret
getkey
       xor a
       ld hl,23560         ; LAST K system variable.
       ld a,(hl)           ; new value of LAST K.
       ret                 ; key was pressed.


WRK_WIND:
	DB 0,0
	DB 32,24
	DB 00001111B
	DB 00000011B
	DB 0,0
	DB 0
	DB 1,'Telnet client v0.0.1',0

	endmodule