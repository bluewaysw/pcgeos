include geos.def
include heap.def
include geode.def
include ec.def
include file.def

UseLib hostif.def

include Internal/host.def

global SSLCALLHOST:far
global SSLCHECKHOST:far


AsmCode	segment resource

COMMENT @----------------------------------------------------------------

C FUNCTION:	SSLCallHost

DESCRIPTION:	

C DECLARATION:	extern dword _far
		_pascal SSLCallHost (SSLHostFunctionNumber callID,
					dword data, dword data2, word data3)
STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	11/30/98	initial version
-------------------------------------------------------------------------@
	SetGeosConvention
SSLCALLHOST		proc	far	callID:byte, 
					data:dword, 
					data2:dword, 
					data3:word	
		uses	di, si, cx, bx

		.enter
		
		mov	di, data3
		mov	dx, data2.high
		mov	cx, data2.low
		mov	bx, data.high
		mov	si, data.low

		mov	al, callID
		clr	ah
		add	ax, HF_SSL_BASE
		
		int	0xA0

		.leave
		
		ret

SSLCALLHOST		endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	SSLCheckHost

DESCRIPTION:	

C DECLARATION:	extern Boolean _far
		_pascal SSLCheckHost ()
STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	11/30/98	initial version
-------------------------------------------------------------------------@
	SetGeosConvention

SSLCHECKHOST		proc	far	

	;	
	; Check host call if SSL interface is available
	;
		uses	cx, dx, si

		.enter

		call	HostIfDetect
		cmp	ax, 0
		je	error

		; matched 8 chars
		mov	ax, 1 
		mov	cx, 2
		int	0xA0

		cmp	ax, 0
		jne	error
		
		mov	ax, -1
done:
		.leave
		ret
		
error:
		mov	ax, 0
		jmp     done

SSLCHECKHOST		endp

	SetDefaultConvention
	
	
AsmCode	ends
