WCC_TEXT        SEGMENT BYTE PUBLIC 'CODE'
                ASSUME  CS:WCC_TEXT

	public __U4M
	public __U4D

	__U4M proc near
		push bp
		mov sp, bp

		ret
	__U4M endp

	__U4D proc near
		push bp
		mov sp, bp

		ret
	__U4D endp
WCC_TEXT        ENDS

