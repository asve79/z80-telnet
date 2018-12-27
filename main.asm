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
	jp	z,exit		;if SS+Q pressed, exit
	CP	01Ch		;if Ss+W pressed - terminal command
	JP	NZ,m_lab4	; ------>
	_iscmdmode		;check terminal command mode (0 - tty 1 - command mode)
	JP	Z, m_lab3
	LD	A,1		;if terminal command mode is off
	LD	(termcmd),A	;turn on termianl mode
	_cur_off
	_printw	wnd_cmd		;print command window
	_prints	cmd_bufer	;print content of command buffer
	_cur_on
	JP	mloop
m_lab3	_cur_off		;close the commend window
	_endw
	XOR	A
	LD	(termcmd),A
	_cur_on
	JP	mloop
m_lab4	CP	#7F		;//delete key pressed
	JNZ	m_lab13		;//if not go to m_lab11
	_istermcommand
	JZ	m_lab11		;//if it is temminal command
	_findzero cmd_bufer	;//get ptr in command bufer
	JR	m_lab14
m_lab11	_findzero inp_bufer	;//get ptr in input buffer
m_lab14	OR	A
	JZ	m_lab13		;//if nothing in bufer
	DEC	HL
	XOR	A
	LD	(HL),A		;//erase symbol
	LD	A,8		;/cusor to left
	_printc
	LD	A,' '		;//space
	_printc
	LD	A,8		;//left again
	_printc
	JP	mloop
m_lab13	PUSH 	AF		;//check connected
	_isconnected
	JNZ	m_lab6
	LD	A,(conn_descr)
	CP	#FF		;//check descriptor
	JZ	m_lab6
	LD	A,(termcmd)
	OR	A		;check terminal command mode
	JP	NZ, m_lab6
	_findzero inp_bufer	;/put char to output buffer
	POP	AF
	LD	(HL),A
	PUSH	AF
m_lab6	POP	AF
;	_cur_off
	call	wind.PRINTC	;out character
	CP	13		;check for press enter
	JP	NZ, m_lab5
	_istermcommand
;	LD	A,(termcmd)	
;	OR	A
	JZ	m_lab8		;if it is not terminal command
	_isopencommand cmd_bufer,m_lab2
	_isclosecommand cmd_bufer,m_lab2
	_ishelpcommand cmd_bufer,m_lab2
m_lab2	_fillzero cmd_bufer, 100	;clear command buffer
	jp 	mloop
m_lab5	LD	HL,termcmd	;write terminal command to bufer
	PUSH 	AF
	LD	A,(HL)
	OR	A
	JNZ 	mloop
	_findzero cmd_bufer
	POP	AF
	LD	(HL),A
	JP	mloop
m_lab8	LD	A,(connected)	;//if ENTER pressed in terminal
	OR	A
	JZ	m_lab9		;//if not connected
	_findzero inp_bufer
	LD	C,A
	LD	A,13		;/add 13 code for <CR><LF> EOL command
	LD	(HL),A
	INC	HL
	LD	A,10		;/add 10 code for <CR><LF> EOL command
	LD	(HL),A
	INC	C
	LD	B,0
	LD	A,(conn_descr)
	CALL	sockets.send	;//send buffer content
	OR	A
	JZ	m_lab7
	_printw wnd_status
	LD	A,'E'		;//error status TODO: close connection
	_printc
	_closew
	_cur_on
	JP	m_lab9
m_lab7	_printw wnd_status	;//success status
	LD	A,'#'
	_printc
	_closew
	_cur_on
m_lab9	_fillzero inp_bufer, 255
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
	_fillzero cmd_bufer, 100
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
	LD	HL,rcv_bufer
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
	DB 1,'Terminal v0.0.5',0

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
        DB 'Press SS+Q for exit.',13
        DB 'Press SS+W for terminal command.',13
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
cmd_bufer	DEFS 100,0
inp_bufer	DEFS 256,0
rcv_bufer	DEFS 255,0

host_addr_len	dw 0
host_addr	dw 0
my_addr		db 0,0,0,0:
my_port		dw 0 ;my ip+port
server_addr	db 93,158,134,3
server_port	dw 23

;	include "_rs232/uart.a80"
	include "_rs232/sockets.a80"

	endmodule