	module main

	include "strings.mac"
	include "wind.mac"
	include "_rs232/sockets.mac"
PROG
;	LD	HL,5B00H
;	LD	BC,2800H
;	CALL	dmm.IDMM

	_printw WRK_WIND
	_endw
	_prints	msg_keys
	_cur_on

mloop   call    spkeyb.CONIN	;main loop entry
	jp	z,mloop		;wait a press key
	cp	01Dh
	jp	z,exit		;if RShift+Q pressed, exit
	LD 	HL,connected
	CP	(HL),0
	JP	NZ,m_lab1	;if connection is established, send data
	PUSH	AF
	_findzero inp_bufer	;if not, fill and analyse buffer
	CP	0FFh		; if bufer overflow, reset it. TODO: shift the bufer
	CALL    Z,fillzero
	LD	HL,inp_bufer
mskip1	pop	af
	LD	(HL),A
m_lab1	call	wind.PRINTC
	CP	13		;check for press enter
	JP	NZ, mloop
	LD 	HL,termcmd
	CP	(HL),0
	JP	Z,mloop	;if it is not terminal command
	;_isclosecommand
m_lab2	CALL	fillzero
	jp 	mloop

exit	_cur_off
	_endw
	RET

fillzero
	_fillzero inp_bufer, 0FFh
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
        DB 'Press RShift+Q for exit.',13
        DB 'Press RShift+W for terminal command.',13,13,0

msg_help DB 'Commands:',13
        DB '---------',13
	DB 'open hostname port - Open connection to host:port',13
	DB 'close - Close current connection',13
	DB 'help - this help message',13,13
	DB 'Keys',13
	DB '----',13
	DB 'RShift+Q - Exit',13
	DB 'RShift+W - Enter terminal command',13
	DB 0

;connection status
connected DB 0; 0 - not connected 1 - connected
;terminal command flag
termcmd	DB	0 ;0 - not terminal command 1 - terminal command
;buffer for intput. MAX 255 bytes
inp_bufer
	DEFS 255,0

cmd_open  DB 'open',0
cmd_close DB 'close',0
cmd_help  DB 'help',0


	endmodule