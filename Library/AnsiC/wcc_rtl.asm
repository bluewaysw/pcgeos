WCC_TEXT        SEGMENT BYTE PUBLIC 'CODE'
                ASSUME  CS:WCC_TEXT

	public __U4M
	public __U4D
	public __I4M
	public __I4D

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
	
	__I4M proc near
		push bp
		mov sp, bp

		ret
	__I4M endp

	__I4D proc near
		push bp
		mov sp, bp

		ret
	__I4D endp
	
WCC_TEXT        ENDS

