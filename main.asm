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
	PUSH 	AF
	_idcmdmode		;if comman mode on go to cmdmodeproc
	JZ	cmdmodeproc
	;process terminal mode
	POP	AF
	CP	01Dh
	JZ	exit		;if SS+Q pressed, exit
	CP	01Ch		;if Ss+W pressed - terminal command
	JZ	opencmdnode	
	CP	#7F		;//delete key pressed
	JZ	delsymtermmode	
	CP	13		;//enter key pressed
	JZ	enterkeytermmode
	CALL	puttocmdbufer	;//put char to command bufer and print
	JP	mloop
cmdmodeproc ;process comman mode
	POP	AF
	CP	01Dh
	JZ	closecmdmode	;if SS+Q pressed, exit
	CP	01Ch		;if Ss+W pressed - terminal command
	JZ	closecmdnode
	CP	#7F		;//delete key pressed
	JZ	delsymcmdmode	
	CP	13		;//enter key pressed
	JP	enterkeycmdmode
	CALL	puttotermbufer	;//put char to terminal bufer and print
	JP	mloop

opencmdmode ;open commend window
	LD	A,1		;if terminal command mode is off
	LD	(termcmd),A	;turn on termianl mode
	_cur_off
	_printw	wnd_cmd		;print command window
	_prints	cmd_bufer	;print content of command buffer
	_cur_on
	JP	mloop
;----
closecmdmode ;close the commend window
	_cur_off		
	_endw
	XOR	A
	LD	(termcmd),A
	_cur_on
	JP	mloop
;-----
delsymcmdmode	;delete symbol in command bufer
	LD	HL,cmd_bufer
	JR	delsymproc
delsymtermmode	;delete symbol in terminal mode
	LD	HL,inp_bufer
delsymproc	;delete symbol main proc
	_findzero inp_bufer	;//get ptr on last symbol+1 in buffer
	OR	A
	JZ	mloop		;//if nothing in bufer (length=0)
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
;----
enterkeycmdmode	;enter key pressed in command window. execute command if it exists
	_isopencommand cmd_bufer,eccm1	;//'open'  command
	_isclosecommand cmd_bufer,eccm1 ;//'close' command
	_ishelpcommand cmd_bufer,eccm1	;//'help' command
eccm1	_fillzero cmd_bufer, 100	;clear command buffer
	jP 	mloop
;----
enterkeycmdmode	;enter key pressed in terminal window
	_isconnected
	JNZ	ekcm_nc		;//if not connected
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
	JZ	ekcm_ok
	_printw wnd_status	;//if error while send data
	LD	A,'E'		;//error status TODO: close connection
	_printc
	_closew
	_cur_on
	JP	ekcm_nc
ekcm_ok	_printw wnd_status	;//success status
	LD	A,'#'
	_printc
	_closew
	_cur_on
ekcm_nc	_fillzero inp_bufer,255
	JP	mloop
;- routine -
puttocmdbufer	;put symbol in command bufer
	PUSH	AF
	_findzero cmd_bufer
	JR	puttobufer
puttotermbufer	;put symbol to terminal bufer
	_findzero inp_bufer
puttobufer	;main procedure for put to bufer;TODO make insert mode with shift content
	POP	AF
	LD	(HL),A
	call	wind.PRINTC	;out character
	RET

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