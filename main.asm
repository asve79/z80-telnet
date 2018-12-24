	module main

	include "main.mac"
	include "strings.mac"
	include "wind.mac"

	include "_rs232/sockets.mac"

PROG
	CALL	init
;	LD	HL,5B00H
;	LD	BC,2800H
;	CALL	dmm.IDMM

	_printw wnd_main
;	_endw
	_prints	msg_keys
	CALL	showstatus
	_cur_on

mloop   call    spkeyb.CONIN	;main loop entry
	jp	z,mloop		;wait a press key
	cp	01Dh
	jp	z,exit		;if RShift+Q pressed, exit
	CP	01Ch		;if Rshift+W pressed - terminal command
	JP	NZ,m_lab4
	LD	HL,termcmd
	LD	A,(HL)
	OR	A		;check terminal command mode
	JP	NZ, m_lab3
	LD	A,1		;if terminal command mode is off
	LD	(HL),A		;turn on termianl mode
	_cur_off
	_printw	wnd_cmd
	_prints	inp_bufer	;print content of command buffer
	_cur_on
	JP	mloop
m_lab3	_cur_off		;close the commend window
	_endw
	LD	HL, termcmd
	XOR	A
	LD	(HL),A
	_cur_on
m_lab4	call	wind.PRINTC	;out character
	CP	13		;check for press enter
	JP	NZ, m_lab5
	LD 	HL,termcmd
	LD	A,(HL)	
	OR	A
	JP	Z,mloop		;if it is not terminal command
	_isopencommand inp_bufer,m_lab2
	_isclosecommand inp_bufer,m_lab2
	_ishelpcommand inp_bufer,m_lab2
m_lab2	CALL	fillzero	;clear command buffer
	jp 	mloop
m_lab5	LD	HL,termcmd	;write terminal command to bufer
	PUSH 	AF
	LD	A,(HL)
	OR	A
	JP	Z, mloop
	_findzero inp_bufer
	POP	AF
	LD	(HL),A
	JP	mloop
exit	_cur_off		;TOOD: close connection if needed
	_endw
	RET

fillzero
	_fillzero inp_bufer, 0FFh
	RET

init	LD HL,connected
	LD (HL),0
	LD HL,termcmd
	LD (HL),0
	LD HL,conn_descr
	LD (HL),#FF
	RET

showstatus
	_printw wnd_status
	_prints msg_status
	LD	HL,termcmd
	LD	A,(HL)
	OR	A
	JZ	sstat1
	_prints msg_connected
	JP	sstat_e
sstat1	_prints msg_disconnected
sstat_e	_closew
	RET

wnd_main
	DB 0,0
	DB 32,22
	DB 00001111B
	DB 00000011B
	DB 0,0
	DB 0
	DB 1,'Telnet client v0.0.1',0

wnd_cmd
	DB 0,21
	DB 32,3
	DB 00110010B
	DB 00000001B
	DB 0,0
	DB 0
	DB 1,'Command:',0

wnd_status
	DB 0,21
	DB 32,3
	DB 00001111B
	DB 00000011B
	DB 0,0
	DB 0
	DB 1,'Status',0

msg_keys
        DB 'Press RShift+Q for exit.',13
        DB 'Press RShift+W for terminal command.',13
	DB 'For help type "help" in terminal cmd.',13
	DB '-------------------------------------',13,13,0

msg_help DB 13,'Commands:',13
        DB '---------',13
	DB 'open hostname port - Open connection to host:port',13
	DB 'close - Close current connection',13
	DB 'help - this help message',13,13
	DB 'Keys',13
	DB '----',13
	DB 'RShift+Q - Exit',13
	DB 'RShift+W - Enter terminal command',13
	DB 0

msg_status DB 'Remote: ',0
msg_connected DB 'connected',0
msg_disconnected DB 'disconnected',0
msg_closeok DB 'closed',0
msg_closeerr DB 'close error',0

cmd_open  DB 'open',0
cmd_close DB 'close',0
cmd_help  DB 'help',0

;----------------------------- VARIABLES ---------------------
conn_descr DB 0 ;Connection descriptor
;connection status
connected DB 0; 0 - not connected 1 - connected
;terminal command flag
termcmd	DB	0 ;0 - not terminal command 1 - terminal command
;buffer for intput. MAX 255 bytes
inp_bufer
	DEFS 255,0

;	include "_rs232/uart.a80"
	include "_rs232/sockets.a80"

	endmodule