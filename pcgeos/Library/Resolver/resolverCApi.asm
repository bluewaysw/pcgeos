COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		IP address resolver
FILE:		resolverCApi.asm

AUTHOR:		Steve Jang, Feb 21, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/21/95   	Initial revision


DESCRIPTION:
	C stubs for resolver lib		

	$Id: resolverCApi.asm,v 1.1 97/04/07 10:42:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

ResolverCApiCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RESOLVERRESOLVEADDRESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	Resolve an address

C DECLARATION:
	extern ResolverError
	   _pascal ResolverResolveAddress( byte *addr,
					   int addrSize,
					   int accessId,
					   long *result
					    );
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RESOLVERRESOLVEADDRESS	proc	far	addr:fptr,
					addrSize:word,
					accessId:word,
					result:fptr
		uses	bx, cx, si, ds, bp
		.enter
		movdw	dssi, addr
		mov	cx, addrSize
		mov	dx, accessId
		push	bp
		call	ResolverResolveAddress
		mov	cx, bp
		pop	bp
		mov	ax, dx			; ax = ResolverError
		jc	done
		movdw	dssi, result
		movdw	ds:[si], dxcx
		mov	ax, RE_NO_ERROR
done:
		.leave
		ret @ArgSize
RESOLVERRESOLVEADDRESS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RESOLVERGETHOSTBYNAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	Get host addresses of a domain name string
		The same as ResolverResolveAddress but a more complete
		version

C DECLARATION:
	extern 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RESOLVERGETHOSTBYNAME	proc	far
		uses	ax,bx,cx,dx
		.enter
		.leave
		ret
RESOLVERGETHOSTBYNAME	endp
ForceRef RESOLVERGETHOSTBYNAME


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RESOLVERGETHOSTINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:

C DECLARATION:
	extern 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RESOLVERGETHOSTINFO	proc	far
		uses	ax,bx,cx,dx
		.enter
		.leave
		ret
RESOLVERGETHOSTINFO	endp
ForceRef RESOLVERGETHOSTINFO


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RESOLVERDELETECACHE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	delete all cache entries in resolver

C DECLARATION:
	extern void
		_pascal ResolverDeleteCache();

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RESOLVERDELETECACHE	proc	far
		call	ResolverDeleteCache
		ret
RESOLVERDELETECACHE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RESOLVERSTOPRESOLVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	Resolve an address

C DECLARATION:
	extern void
	   _pascal ResolverStopResolve( byte *addr,
					int addrSize
					);
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RESOLVERSTOPRESOLVE	proc	far	addr:fptr,
					addrSize:word
		uses	bx, cx, si, ds, bp
		.enter
		movdw	dssi, addr
		mov	cx, addrSize
		call	ResolverStopResolve
		.leave
		ret @ArgSize
RESOLVERSTOPRESOLVE	endp

ResolverCApiCode	ends

SetDefaultConvention
