                include stdapp.def
		include product.def
if PROGRESS_DISPLAY
		include Internal/semInt.def
		include thread.def
		include Internal/heapInt.def
		include Internal/interrup.def
endif
		include driver.def
		include geode.def
		include Internal/videoDr.def

		include socket.def
		include sockmisc.def
		include sem.def

                SetGeosConvention               ; set calling convention

ASM_TEXT        segment public 'CODE'

        if ERROR_CHECK
        global F_CHKSTK@:far
; Called with AX containing the number of bytes to be allocated on the stack.
; Must return with the stackpointer lowered by AX bytes.
F_CHKSTK@       proc far
        pop     cx                      ; save return address
        pop     dx
        sub     sp,ax                   ; allocated space on stack
        push    dx                      ; restore return address
        push    cx
        call    ECCHECKSTACK            ; still enough room on stack?
        ret                             ; return to calling routine
F_CHKSTK@       endp
        endif

if PROGRESS_DISPLAY
	global	WAKEUP:far
WAKEUP	proc	far	queueP:fptr
	.enter
	; make sure we get plenty attention
	;no, we don't want to take time from the PPP/TCPIP threads
	;clr	bx
	;mov	al, 20
	;mov	ah, mask TMF_BASE_PRIO
	;call	ThreadModify
	push	ds
	mov	ax, queueP.segment
	mov	ds, ax
	mov	bx, queueP.offset
	cmp	{word}ds:[bx], 0
	pop	ds
	jz	done			; no one blocked
	call	ThreadWakeUpQueue
done:
	.leave
	ret
WAKEUP	endp

.ioenable

	global BLOCK:far
BLOCK	proc	far	queueP:fptr, flag:fptr
	.enter
	;
	; atomically check flag, block if FALSE
	;
	INT_OFF
	push	ds, si
	lds	si, flag
	mov	ax, ds:[si]
	pop	ds, si
	cmp	ax, 0	; also allows us to set conditional brk here
	jne	noBlock
	mov	ax, queueP.segment
	mov	bx, queueP.offset
	call	ThreadBlockOnQueue
noBlock:
	INT_ON
	.leave
	ret
BLOCK	endp
endif

;should be conditional on TV_BW_OPTION
	global SETVIDBW:far
SETVIDBW	proc	far	bwOn:word
		uses	di, ds, si
		.enter
		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver	; bx = driver
		tst	ax
		jz	done
		mov	bx, ax
		call	GeodeInfoDriver		; ds:si = DIS
		mov	ax, bwOn
		mov	di, VID_ESC_SET_BLACK_WHITE
		call	ds:[si].DIS_strategy
done:
		.leave
		ret
SETVIDBW	endp

ASM_TEXT        ends

idata	segment  ; this is fixed

tcpDomain	char	"TCPIP",0
sa	label	SocketAddress
	SocketPort <1, MANUFACTURER_ID_SOCKET_16BIT_PORT>
	word	size tcpDomain-1
	fptr	tcpDomain
	word	size xa
xa	label	TcpAccPntResolvedAddress
	word	3
	byte	LT_ID
	word	1
	byte	0, 0, 0, 0

OpenConnectionRoutine	proc	far
		mov	bx, cx			; bx = quitSem
		mov	cx, segment idata
		mov	dx, offset sa
		mov	bp, 3600
		call	SocketOpenDomainMedium
		tst	bx
		jz	done
		call	ThreadVSem
done:
		clr	cx, dx, bp
		jmp	ThreadDestroy
OpenConnectionRoutine	endp

	global	OPENCONNECTION:far
OPENCONNECTION	proc	far	quitSem:word
		uses	si, di, bp
		.enter
		mov	si, quitSem
		mov	al, PRIORITY_STANDARD
		mov	cx, segment OpenConnectionRoutine
		mov	dx, offset OpenConnectionRoutine
		mov	di, 2048
		call	GeodeGetProcessHandle
		mov	bp, bx
		mov	bx, si
		call	ThreadCreate
		.leave
		ret
OPENCONNECTION	endp

idata	ends


