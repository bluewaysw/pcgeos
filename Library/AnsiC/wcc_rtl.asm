WCC_TEXT        SEGMENT BYTE PUBLIC 'CODE'
                ASSUME  CS:WCC_TEXT

	public __U4M
	public __U4D
	public __I4M
	public __I4D
	public __CHP


;
; __U4M, __I4M
;
; in:
;       (dx:ax) - 32bit arg1 (dx hi, ax lo)
;       (cx:bx) - 32bit arg2 (cx hi, bx lo)
; out:
;       (dx:ax) - 32bit product
;
; reg use: bx,cx destroyed, all others preserved or contain result.
;
; hi(result) := lo(hi(arg1) * lo(arg2)) +
;               lo(hi(arg2) * lo(arg1)) +
;               hi(lo(arg1) * lo(arg2))
; lo(result) := lo(lo(arg1) * lo(arg2))
;

	__U4M proc far
	.fall_thru
	__U4M endp

	__I4M proc far
	uses si
	.enter

	xchg	si,ax			; save lo1
	xchg	ax,dx
	test	ax,ax           ; skip mul if hi1==0
	jz		nohi1
	mul		bx              ; hi1 * lo2

	nohi1:					; if we jumped here, ax==0 so the following swap works
	jcxz	nohi2			; skip mul if hi2==0
	xchg	cx, ax			; result <-> hi2
	mul		si				; lo1 * hi2
	add		ax, cx			; ax = hi1*lo2 + hi2*lo1

	nohi2:
	xchg	ax,si
	mul		bx				; lo1 * lo2
	add		dx,si			; hi order result += partials
          
	.leave
	ret
	__I4M endp

	__U4D proc near
		push bp
		mov sp, bp

		ret
	__U4D endp
	
	__I4D proc near
		push bp
		mov sp, bp

		ret
	__I4D endp
	
	__CHP proc near
		push bp
		mov sp, bp

		ret
	__CHP endp	

WCC_TEXT        ENDS

