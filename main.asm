	module main

	include "main.mac"
	include "strings.mac"
	include "wind.mac"

	include "_rs232/sockets.mac"

PROG
	CALL	init
	_printw wnd_main
	_prints	msg_keys
	CALL	showstatus
	_cur_on

mloop   CALL	check_rcv
	CALL    spkeyb.CONINW	;main loop entry
	JZ	mloop		;wait a press key
	cp	01Dh
	jp	z,exit		;if RShift+Q pressed, exit
	CP	01Ch		;if Rshift+W pressed - terminal command
	JP	NZ,m_lab4
	LD	A,(termcmd)
	OR	A		;check terminal command mode
	JP	NZ, m_lab3
	LD	A,1		;if terminal command mode is off
	LD	(termcmd),A	;turn on termianl mode
	_cur_off
	_printw	wnd_cmd
	_prints	inp_bufer	;print content of command buffer
	_cur_on
	JP	mloop
m_lab3	_cur_off		;close the commend window
	_endw
	XOR	A
	LD	(termcmd),A
	_cur_on
m_lab4	PUSH 	AF		;/choeck connected
	LD	A,(connected)
	OR	A
	JZ	m_lab6
	LD	A,(conn_descr)
	CP	#FF		;//check descriptor
	JZ	m_lab6
	LD	A,(termcmd)
	OR	A		;check terminal command mode
	JP	NZ, m_lab6
	_cur_off
	POP	AF
	LD	HL,term_buf
	LD	(HL),A
	PUSH	AF
	LD	BC,1
	LD	A,(conn_descr)
	CALL	sockets.send
	OR	A
	JZ	m_lab7
	_printw wnd_status
	LD	A,'E'
	_printc
	_closew
	_cur_on
	JR	m_lab6
m_lab7	_printw wnd_status
	LD	A,'#'
	_printc
	_closew
	_cur_on
m_lab6	POP	AF
	call	wind.PRINTC	;out character
	CP	13		;check for press enter
	JP	NZ, m_lab5
	LD	A,(termcmd)	
	OR	A
	JP	Z,mloop		;if it is not terminal command
	_isopencommand inp_bufer,m_lab2
	_isclosecommand inp_bufer,m_lab2
	_ishelpcommand inp_bufer,m_lab2
m_lab2	_fillzero inp_bufer, 254	;clear command buffer
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
	_closew
        LD      HL,conn_descr
        LD      A,(HL)
        CP      0FFh
        RET	Z                     ;if descriptor is bad
	CALL	sockets.close
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
;	_prints msg_status
	LD	A,(connected)
	OR	A
	JZ	sstat1
	LD	A,'*'
	_printc
;	_prints msg_connected
	JR	sstat_e
sstat1	;_prints msg_disconnected
	LD	A,'x'
	_printc
sstat_e	
	LD	A,(inc_addr)
	INC	A
	LD	(inc_addr),A
	CALL	wind.A_HEX
	_closew
	RET

;/ inctease counter every interrupt
INCCNTR LD	A,(im_cntr)
	INC	A
	LD	(im_cntr),A
	RET

check_rcv	;//check receve info from connection
	LD	A,(im_cntr)
	AND	#C0
	RET	Z		;skip N tick's
	XOR	A
	LD	(im_cntr),A
	LD	A,(termcmd)
	OR	A
	RET	NZ		;//if terminal mode, then no print error status
;	LD	A,'$'	;//for debugging
;	_printc
	LD	A,(connected)
	OR	A
	RET	Z
	LD	A,(conn_descr)
	CP	#FF	;//check descriptor
	RET	Z
rcv1	recv	conn_descr,rcv_bufer,255
	OR	A
	JZ	rcv2
	_printw wnd_status	;//if error
	LD	A,'!'
	_printc
	_closew
	RET
rcv2	LD	A,B
	OR	A
	JNZ	rcv3
	LD	A,C
	OR	A
	RET	Z	;//if BC=0 (receve 0 bytes); TODO: check is if 1st 0 bytes, then exit. if it end of block then get new block
rcv3	LD	A,(HL)
	_printc		;//print char
	INC	HL
	DEC	BC
	JR	rcv2

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

msg_help 
	DB 13,'Commands:',13
        DB '---------',13
	DB 'open hostname port - Open connection to host:port',13
	DB 'close - Close current connection',13
	DB 'help - this help message',13,13
	DB 'Keys',13
	DB '----',13
	DB 'RShift+Q - Exit',13
	DB 'RShift+W - Enter terminal command',13
	DB 0

inc_addr 	DB 0

msg_status 	DB 31,'Remote: ',0
msg_connected 	DB 'connected',0
msg_disconnected DB 'disconnected',0
msg_closeok 	DB 'closed',0
msg_closeerr 	DB 'close error',0
msg_openerr 	DB 'open connection error',0
msg_openok  	DB 13,'Connected successfuly',13,0
msg_alredyopen 	DB 'Have active connection. Close current first!',0
msg_fdproblem 	DB 'Connection descriptor problem',0
msg_connecting 	DB 'Connecting...',0
msg_connectclosed DB 13,'Disconnected',13,0

cmd_open  DB 'open',0
cmd_close DB 'close',0
cmd_help  DB 'help',0

;----------------------------- VARIABLES ---------------------
im_cntr		DB 0
term_buf	DB 0
conn_descr	DB 0 ;Connection descriptor
;connection status
connected	DB 0; 0 - not connected 1 - connected
;terminal command flag
termcmd	DB	0 ;0 - not terminal command 1 - terminal command
;buffer for intput. MAX 255 bytes
inp_bufer	DEFS 255,0
rcv_bufer	DEFS 255,0

host_addr_len	dw 0
host_addr	dw 0
my_addr		db 0,0,0,0:dw 0 ;my ip+port
server_addr	db 93,158,134,3:dw 23

;	include "_rs232/uart.a80"
	include "_rs232/sockets.a80"

	endmodule