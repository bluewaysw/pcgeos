; Copyright 2020	Falk Rehwagen, Jirka Kunze
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

WCC_TEXT        SEGMENT BYTE PUBLIC 'CODE'
                ASSUME  CS:WCC_TEXT

	public __U4M
	public __U4D
	public __I4M
	public __I4D
	public __CHP

; __U4M
; __I4M
;
; Multiplies two 32bit integers (signed and unsigned).
;
; In:
;	dx:ax	int1 ( dx: high( int1 ); ax low( int1 ) )
;	cx:bx	int2 ( cx: high( int2 ); bx low( int2 ) )
;
; Out:
;	dx:ax	product of int1 and int2
;
; Description:
;	dx := low( high( int1 ) * low( int2 ) ) + --> part1
;	      low( high( int2 ) * low( int1 ) ) + --> part2
;	      high( low( int1 ) * low( int2 ) )   --> part3
;	ax := low( low( int1 ) * low( int2 ) )    --> part4

	__U4M proc far
	.fall_thru
	__U4M endp

	__I4M proc far

	push bx				; save low( int2 )
	push ax				; save low( int1 )

	xchg ax, dx			; ax := high( int1 ), dx := low( int1 )
	mul bx				; ax := low( high( int1 ) * low( int2 ) ) --> part1
	xchg ax, bx			; bx := part1, ax := low( int2 )

	pop ax				; restore low( int1 )
	xchg ax, cx			; ax := high( int2 ), cx := low( int1 )
	mul cx				; ax := low( low( int1 ) * high( int2 ) ) --> part2
	add ax, bx			; ax := part1 + part2

	xchg ax, cx			; cx := part1 + part2, ax := high( int2 )
	pop bx				; restore low( int2 )
	mul bx				; ax := low( high( int2 ) * low( int2 ) ) --> part4
						; dx := high( high( int2 ) * low( int2 ) ) --> part3

	xchg ax, dx
	add ax, cx			; ax := part 3 + part 1 + part 2
	xchg ax, dx

	ret

	__I4M endp

	__U4D proc far

	ret
	__U4D endp
	
	__I4D proc far
		
	ret
	__I4D endp
	
	__CHP proc far
		
	ret
	__CHP endp	
	
WCC_TEXT        ENDS
