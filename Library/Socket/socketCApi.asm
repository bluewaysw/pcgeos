COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Socket
MODULE:		socket library
FILE:		socketCApi.asm

AUTHOR:		Eric Weber, Dec  5, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94   	Initial revision


DESCRIPTION:
	C Stubs for socket lib
		

	$Id: socketCApi.asm,v 1.23 98/06/26 16:41:52 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

CApiCode	segment resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETCREATE

C DECLARATION:	
	extern Socket 
	    _pascal SocketCreate(SocketDeliveryType delivery);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETCREATE	proc	far	delivery:word
		.enter
		mov	ax, ss:[delivery]
		call	SocketCreate		; ax=error, bx=socket
		jnc	noError
		call	ThreadSetError
		clr	bx
noError:
		mov	ax,bx
		.leave
		ret
SOCKETCREATE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETBIND

C DECLARATION:	
	extern SocketError 
	    _pascal SocketBind(Socket s, 
			       SocketPort p, 
			       SocketBindFlags flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETBIND	proc	far	s:Socket,
				p:SocketPort,
				flags:SocketBindFlags
		.enter
		mov	bx, ss:[s]
		movdw	cxdx, ss:[p]
		push	bp
		mov	bp, ss:[flags]
		call	SocketBind
		pop	bp
		.leave
		ret
SOCKETBIND	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETBINDINDOMAIN

C DECLARATION:	
	extern SocketError 
	    _pascal SocketBindInDomain(Socket s, 
				       SocketPort p, 
				       SocketBindFlags flags, 
				       TCHAR *domain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETBINDINDOMAIN	proc	far	s:Socket,
					p:SocketPort,
					flags:SocketBindFlags,
					domain:fptr.TCHAR
		uses	ds,si
		.enter
		mov	bx, ss:[s]
		movdw	cxdx, ss:[p]
		movdw	dssi, ss:[domain]
		push	bp
		mov	bp, ss:[flags]
		call	SocketBindInDomain
		pop	bp
		.leave
		ret
SOCKETBINDINDOMAIN	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETLISTEN

C DECLARATION:	
	extern SocketError 
	    _pascal SocketListen(Socket s, 
				 int qSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETLISTEN	proc	far	s:Socket,
				qSize:word
		.enter
		mov	bx, ss:[s]
		mov	cx, ss:[qSize]
		call	SocketListen		
		.leave
		ret
SOCKETLISTEN	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETADDLOADONMSG

C DECLARATION:	
	extern SocketError
	    _pascal SocketAddLoadOnMsg(SocketPort p,
				      SocketLoadType slt,
				      word disk,
				      TCHAR *path);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETADDLOADONMSG	proc	far	p:SocketPort,
					slt:SocketLoadType,
					disk:word,
					path:fptr.TCHAR
		uses	ds,si
		.enter
		movdw	axbx, ss:[p]
		movdw	dssi, ss:[path]
		mov	cx, ss:[slt]
		push	bp
		mov	bp, ss:[disk]
		call	SocketAddLoadOnMsg
		pop	bp
		.leave
		ret
SOCKETADDLOADONMSG	endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETADDLOADONMSGINDOMAIN

C DECLARATION:	
	extern SocketError
	    _pascal SocketAddLoadOnMsgInDomain(SocketPort p,
					       SocketLoadType slt,
					       word disk,
					       TCHAR *path,
					       TCHAR *domain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETADDLOADONMSGINDOMAIN	proc	far	p:SocketPort,
						slt:SocketLoadType,
						disk:word,
						path:fptr.TCHAR,
						domain:fptr.TCHAR
		uses	si,di,ds
		.enter
		movdw	axbx, ss:[p]
		movdw	dssi, ss:[path]
		movdw	esdi, ss:[domain]
		mov	cx, ss:[slt]
		push	bp
		mov	bp, ss:[disk]
		call	SocketAddLoadOnMsgInDomain
		pop	bp
		.leave
		ret
SOCKETADDLOADONMSGINDOMAIN	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETREMOVELOADONMSG

C DECLARATION:	
	extern SocketError
	    _pascal SocketRemoveLoadOnMsg(SocketPort p);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETREMOVELOADONMSG	proc	far	p:SocketPort
		.enter
		movdw	axbx, ss:[p]
		call	SocketRemoveLoadOnMsg
		.leave
		ret
SOCKETREMOVELOADONMSG	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETREMOVELOADONMSGINDOMAIN

C DECLARATION:	
	extern SocketError
	    _pascal SocketRemoveLoadOnMsgInDomain(SocketPort p,
						  TCHAR *domain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETREMOVELOADONMSGINDOMAIN	proc	far	p:SocketPort,
						domain:fptr.TCHAR
		uses	di
		.enter
		movdw	axbx, ss:[p]
		movdw	dxdi, ss:[domain]
		call	SocketRemoveLoadOnMsgInDomain
		.leave
		ret
SOCKETREMOVELOADONMSGINDOMAIN	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketInterrupt

C DECLARATION:	
	extern SocketError
		_pascal	SocketInterrupt(Socket s);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 9/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETINTERRUPT	proc	far	skt:word
		uses	si,di,bp
		.enter
		mov	bx, skt
		call	SocketInterrupt
		.leave
		ret
SOCKETINTERRUPT	endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETCONNECT

C DECLARATION:	
	extern SocketError
	    _pascal SocketConnect(Socket s, 
				  SocketAddress *addr,
				  int timeout);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETCONNECT	proc	far		s:Socket,
					addr:fptr.SocketAddress,
					timeout:word
		.enter
		mov	bx, ss:[s]
		movdw	cxdx, ss:[addr]
		push	bp
		mov	bp, ss:[timeout]
		call	SocketConnect
		pop	bp
		.leave
		ret
SOCKETCONNECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETCHECKLISTEN

C DECLARATION:	
	extern int
	    _pascal SocketCheckListen(SocketPort p, 
				      TCHAR *domain,
				      int bufsize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETCHECKLISTEN	proc	far	p:SocketPort,
					domain:fptr.TCHAR,
					bufsize:word
		uses	ds,si
		.enter
		movdw	axbx, ss:[p]
		movdw	dssi, ss:[domain]
		mov	cx, ss:[bufsize]
		call	SocketCheckListen
		jnc	done
		call	ThreadSetError
		clr	cx
done:
		mov	ax,cx
		.leave
		ret
SOCKETCHECKLISTEN	endp

				  

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETACCEPT

C DECLARATION:	
	extern Socket
	    _pascal SocketAccept(Socket s,
				 int timeout);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETACCEPT	proc	far	s:Socket,
				timeout:word
		.enter
		mov	bx, ss:[s]
		push	bp
		mov	bp, ss:[timeout]
		call	SocketAccept
		pop	bp
		jnc	done
		call	ThreadSetError
		clr	cx
done:
		mov	ax,cx
		.leave
		ret
SOCKETACCEPT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETGETPEERNAME

C DECLARATION:	
	extern SocketError
	    _pascal SocketGetPeerName(Socket s,
				      SocketAddress *addr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETPEERNAME	proc	far	s:Socket,
					addr:fptr.SocketAddress
		uses	di
		.enter
		mov	bx, ss:[s]
		movdw	esdi, ss:[addr]
		call	SocketGetPeerName
		.leave
		ret
SOCKETGETPEERNAME	endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETGETSOCKETNAME

C DECLARATION:	
	extern SocketError
	    _pascal SocketGetSocketName(Socket s,
					SocketAddress *addr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETSOCKETNAME	proc	far	s:Socket,
					addr:fptr.SocketAddress
		uses	di
		.enter
		mov	bx, ss:[s]
		movdw	esdi, ss:[addr]
		call	SocketGetSocketName
		.leave
		ret
SOCKETGETSOCKETNAME	endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETSEND

C DECLARATION:	
	extern SocketError
	    _pascal SocketSend(Socket s,
			       byte *buffer,
			       int bufSize,
			       SocketSendFlags flags,
			       SocketAddress *addr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETSEND	proc	far	s:Socket,
				buffer:fptr,
				bufsize:word,
				flags:SocketSendFlags,
				addr:fptr.SocketAddress
		uses	si,di,ds
		.enter
	;
	; load es:di only if SSF_ADDRESS is set
	;
		mov	ax, ss:[flags]
		test	ax, mask SSF_ADDRESS
		jz	noAddress
		movdw	esdi, ss:[addr]
noAddress:
		mov	bx, ss:[s]
		movdw	dssi, ss:[buffer]
		mov	cx, ss:[bufsize]
		call	SocketSend
		.leave
		ret
SOCKETSEND	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETRECV

C DECLARATION:	
	extern int
	    _pascal SocketRecv(Socket s,
			       byte *buffer,
			       int bufSize,
			       int timeout,
			       SocketRecvFlags flags,
			       SocketAddress *addr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETRECV	proc	far	s:Socket,
				buffer:fptr,
				bufSize:word,
				timeout:word,
				flags:SocketRecvFlags,
				addr:fptr.SocketAddress
		uses	di
		.enter
		push	bp
		mov	ax, ss:[flags]
		test	ax, mask SRF_ADDRESS
		jz	noAddress
		pushdw	ss:[addr]
noAddress:
		mov	bx, ss:[s]
		movdw	esdi, ss:[buffer]
		mov	cx, ss:[bufSize]
		mov	bp, ss:[timeout]
		call	SocketRecv
		pop	bp
		call	ThreadSetError
		jnc	done
		clr	cx
done:
		mov	ax,cx
		.leave
		ret
SOCKETRECV	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETCLOSESEND

C DECLARATION:	
	extern SocketError
	    _pascal SocketCloseSend(Socket s);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETCLOSESEND	proc	far	s:Socket
		.enter
		mov	bx, ss:[s]
		call	SocketCloseSend
		.leave
		ret
SOCKETCLOSESEND	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETCLOSE

C DECLARATION:	
	extern SocketError
	    _pascal SocketClose(Socket s);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETCLOSE	proc	far	s:Socket
		.enter
		mov	bx, ss:[s]
		call	SocketClose
		.leave
		ret
SOCKETCLOSE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETRESET

C DECLARATION:	
	extern SocketError
	    _pascal SocketReset(Socket s);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETRESET	proc	far	s:Socket
		.enter
		mov	bx, ss:[s]
		call	SocketReset
		.leave
		ret
SOCKETRESET	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SOCKETCHECKREADY

C DECLARATION:	
	extern int
	    _pascal SocketCheckReady(SocketCheckRequest *requests,
				     int numRequests,
				     int timeout);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 6/94		Initial Revision

------------------------------------------------------------------------------@
SOCKETCHECKREADY	proc	far	requests:fptr.SocketCheckRequest,
					numRequests:word,
					timeout:word
		uses	ds,si
		.enter
		mov	ax, ss:[numRequests]
		movdw	dssi, ss:[requests]
		push	bp
		mov	bp, ss:[timeout]
		call	SocketCheckReady
		pop	bp
		jnc	done
		call	ThreadSetError
		clr	cx
done:
		mov	ax,cx
		.leave
		ret
SOCKETCHECKREADY	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetDomains

C DECLARATION:	
	extern lptr
	    _pascal SocketGetDomains(optr domainList);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETDOMAINS	proc	far	dlist:optr
		uses	si
		.enter
		movdw	bxsi, ss:[dlist]
		call	SocketGetDomains
		jc	error
		mov	ax,si
done:		
		.leave
		ret
error:
		call	ThreadSetError
		clr	ax
		jmp	done
		
SOCKETGETDOMAINS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetDomainMedia

C DECLARATION:	
	extern lptr
	    _pascal SocketGetDomainMedia(char *domain, 
					 optr mediaList);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETDOMAINMEDIA	proc	far	domain:fptr.char,
					media:optr
		uses	si,di,ds
		.enter
		movdw	bxsi, ss:[media]
		movdw	dsdi, ss:[domain]
		call	SocketGetDomainMedia
		jc	error
		mov	ax,si
done:
		.leave
		ret
error:
		call	ThreadSetError
		clr	ax
		jmp	done
		
SOCKETGETDOMAINMEDIA	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetAddressMedium

C DECLARATION:	
	extern SocketError
	    _pascal SocketGetAddressMedium(SocketAddress *sa,
					   MediumAndUnit *mau);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETADDRESSMEDIUM  proc    far     sa:fptr.SocketAddress,
                                        mau:fptr.MediumAndUnit
		uses	ds,di
		.enter
		movdw	dsdi, ss:[sa]
		push	bp
		pushdw	ss:[mau]		; save before we trash bp
		call	SocketGetAddressMedium
		popdw	dsdi			; ds:di = MediumAndUnit
		jc	error
		movdw	ds:[di].MU_medium, cxdx
		mov	ds:[di].MU_unitType, bl
		mov	ds:[di].MU_unit, bp
error:
		pop	bp
		.leave
		ret
SOCKETGETADDRESSMEDIUM	endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketCheckMediumConnection

C DECLARATION:	
	extern SocketError 
	     _pascal SocketCheckMediumConnection(char *domain,
						 byte *buffer,
						 int *bufsize,
						 MediumAndUnit *mau);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/ 8/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETCHECKMEDIUMCONNECTION	proc	far	domain:fptr.char,
						buffer:fptr.byte,
						bufsize:fptr.word,
						mau:fptr.MediumAndUnit
		uses	si,di,ds
		.enter
		movdw	dssi, bufsize
		Assert	fptr dssi
		mov	cx, ds:[si]
		push	ds,si
		movdw	dssi, domain
		movdw	esdi, buffer
		movdw	dxax, mau
		call	SocketCheckMediumConnection
		pop	ds,si
		mov	ds:[si], cx
		.leave
		ret
SOCKETCHECKMEDIUMCONNECTION	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetMediumAddress

C DECLARATION:	
	extern SocketError 
	     _pascal SocketGetMediumAddress(char *domain,
					    byte *buffer,
					    int *bufsize,
					    MediumAndUnit *mau);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 7/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETMEDIUMADDRESS		proc	far	domain:fptr.char,
						buffer:fptr.byte,
						bufsize:fptr.word,
						mau:fptr.MediumAndUnit
		uses	si,di,ds
		.enter
		movdw	dssi, bufsize
		Assert	fptr dssi
		mov	cx, ds:[si]
		push	ds,si
		movdw	dssi, domain
		movdw	esdi, buffer
		movdw	dxax, mau
		call	SocketGetMediumAddress
		pop	ds,si
		mov	ds:[si], cx
		.leave
		ret
SOCKETGETMEDIUMADDRESS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetAddressController

C DECLARATION:	
	extern fptr
	    _pascal SocketGetAddressController(char *domain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETADDRESSCONTROLLER	proc	far	domain:fptr.char
		uses	ds,si
		.enter
		movdw	dssi, ss:[domain]
		call	SocketGetAddressController
		jc	error
		mov	ax,dx
		mov	dx,cx
done:
		.leave
		ret
error:
		call	ThreadSetError
		clrdw	dxax
		jmp	done
SOCKETGETADDRESSCONTROLLER	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetAddressSize

C DECLARATION:	
	extern int
	    _pascal SocketGetAddressSize(char *domain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/22/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETADDRESSSIZE	proc	far	domain:fptr.char
		uses	ds,si
		.enter
		movdw	dssi, ss:[domain]
		call	SocketGetAddressSize
		jc	error
		mov	ax,cx
done:
		.leave
		ret
error:
		call	ThreadSetError
		mov	ax,-1
		jmp	done
		
SOCKETGETADDRESSSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOCKETRESOLVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve an address to a usable format with SocketSend

C FUNCTION:	SocketResolve

C DECLARATION:

extern int
    _pascal SocketResolve( TCHAR *domainName,
			   byte *rawAddr,
			   int addrSize,
			   byte *result,
			   int resultBuffSize );

NOTES:
	If the address cannot be resolved, return value is 0.
	If the address was resolved, the return value is the size of
          the resolved address, regardless of whether it fit in the buffer.
        If the buffer is too small, it's contents become undefined.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOCKETRESOLVE	proc	far	domainName:fptr.TCHAR,
				rawAddr:fptr,
				addrSize:word,
				result:fptr,
				resultBuffSize:word
		uses	si,di,bp,ds
		.enter
		movdw	dssi, rawAddr
		movdw	esdi, result
		mov	cx, addrSize
		mov	ax, resultBuffSize
		mov	dx, domainName.segment
		mov	bp, domainName.offset	; we can do this b/c
						;  Esp doesn't need bp to
						;  undo the stack, so long
						;  as we have no local vars
		call	SocketResolve		; ax=error, cx=size

		xchg	ax,cx
		cmp	cx, SE_NORMAL
		je	done
		cmp	cx, SE_BUFFER_TOO_SMALL
		je	done
		mov_tr	ax,cx
		call	ThreadSetError
		clr	ax
done:
		.leave
		ret
SOCKETRESOLVE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketInterruptResolve

C DECLARATION:	
	extern SocketError
		_pascal	SocketInterruptResolve(TCHAR *domain,
						byte *address,
						int addrSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/10/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETINTERRUPTRESOLVE	proc	far	domain:fptr.TCHAR,
					addr:fptr.byte,
					asize:word
		uses	ds, si, bp
		.enter
		movdw	dssi, addr
		mov	cx, asize
		movdw	dxbp, domain
		call	SocketInterruptResolve
		.leave
		ret
SOCKETINTERRUPTRESOLVE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SOCKETCREATERESOLVEDADDRESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve an address to a usable format with SocketSend

C FUNCTION:	SocketCreateResolvedAddress

C DECLARATION:

extern MemHandle
    _pascal SocketCreateResolvedAddress(const TCHAR *domainName,
			   byte *rawAddr,
			   int addrSize)

NOTES:
	If the address cannot be resolved, return value is 0.
		ThreadGetError returns error code, then
	If the address was resolved, the return value is the handle
	  of the unlocked, non-sharable SocketAddress buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SOCKETCREATERESOLVEDADDRESS	proc	far	domainName:fptr.TCHAR,
				rawAddr:fptr,
				addrSize:word
		uses	si,bp,ds
		.enter
		movdw	dssi, rawAddr
		mov	cx, addrSize
		mov	dx, domainName.segment
		mov	bp, domainName.offset	; we can do this b/c
						;  Esp doesn't need bp to
						;  undo the stack, so long
						;  as we have no local vars
		call	SocketCreateResolvedAddress
		jnc	done
		call	ThreadSetError
		clr	ax
done:
		.leave
		ret
SOCKETCREATERESOLVEDADDRESS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketCloseDomainMedium

C DECLARATION:	
extern int
	_pascal SocketCloseDomainMedium(char *domain, 
					MediumAndUnit *mau, 
					Boolean force);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/10/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETCLOSEDOMAINMEDIUM	proc	far	domain:fptr.char,
					mau:fptr.MediumAndUnit,
					force:BooleanWord
		uses	si,ds
		.enter
		mov	ax, force
		movdw	dxbx, mau
		movdw	dssi, domain
		call	SocketCloseDomainMedium
		.leave
		ret
SOCKETCLOSEDOMAINMEDIUM	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketSetMediumBusy

C DECLARATION:	
extern Boolean
	_pascal SocketSetMediumBusy (char *domain, 
				     MediumAndUnit *mau, 
				     BooleanWord busy);

SIDE EFFECTS:
	Setting the medium busy will prevent non-forcing
	SocketCloseDomainMedium from succeeding.  Do not
	use unless you want that.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	01/17/97	Initial Revision

------------------------------------------------------------------------------@
SOCKETSETMEDIUMBUSY	proc	far	domain:fptr.char,
					mau:fptr.MediumAndUnit,
					busy:BooleanWord
		uses	si, ds
		.enter
		mov	cx, busy
		movdw	dxbx, mau
		movdw	dssi, domain
		call	SocketSetMediumBusy
		.leave
		ret
SOCKETSETMEDIUMBUSY	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketOpenDomainMedium

C DECLARATION:	
	extern SocketError
	    _pascal SocketOpenDomainMedium(SocketAddress *addr,
					   int timeout);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/10/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETOPENDOMAINMEDIUM	proc	far	addr:fptr.SocketAddress,
					timeout:word
		.enter
		push	bp
		movdw	cxdx, addr
		mov	bp, timeout
		call	SocketOpenDomainMedium
		pop	bp
		.leave
		ret
SOCKETOPENDOMAINMEDIUM	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketSetIntSocketOption

C DECLARATION:	
	extern void
	    _pascal SocketSetIntSocketOption(Socket skt,
					     SocketOption opt,
					     int newval);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/21/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETSETINTSOCKETOPTION	proc	far	skt:word,
						opt:SocketOption,
						newval:word
		.enter
		mov	ax, opt
		mov	bx, skt
		mov	cx, newval
		call	SocketSetSocketOption
		.leave
		ret
SOCKETSETINTSOCKETOPTION	endp




COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketGetIntSocketOption

C DECLARATION:	
	extern int
	    _pascal SocketGetIntSocketOption(Socket skt,
					     SocketOption opt);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/21/95		Initial Revision

------------------------------------------------------------------------------@
SOCKETGETINTSOCKETOPTION	proc	far	skt:word,
						opt:SocketOption
		.enter
		mov	ax, opt
		mov	bx, skt
		call	SocketGetSocketOption
		mov_tr	ax, cx
		.leave
		ret
SOCKETGETINTSOCKETOPTION	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SocketResolveLinkLevelAddress

C DECLARATION:	
	extern SocketError
	    _pascal SocketResolveLinkLevelAddress(SocketAddress *saddr,
					          byte *buffer, word *bufSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ED	06/02/00	Initial version

------------------------------------------------------------------------------@
SOCKETRESOLVELINKLEVELADDRESS	proc	far	saddr:fptr,
						buffer:fptr,
						bufSize:fptr
		uses	ds, si
		.enter
		movdw	essi, bufSize
		mov	bx, es:[si]
		movdw	dssi, saddr
		movdw	cxdx, buffer
		call	SocketResolveLinkLevelAddress
		mov	si, bufSize.offset
		mov	es:[si], bx
		.leave
		ret
SOCKETRESOLVELINKLEVELADDRESS	endp


CApiCode	ends

SetDefaultConvention
