COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax Preferences Module
FILE:		preffaxInstallGroup3.asm

AUTHOR:		Chris Lee, Dec  7, 1993

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    INT PrefFaxInstallGroup3 		Install group 3 fax printer driver to 
					the system.

    INT PrefFaxWriteGroup3Category 	Write Group 3 Printer Driver info into
					INI file

    INT PrefFaxCheckGroup3Exist 	Check if Group3 Printer Dr exists in
					the INI file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 7/93   	Initial revision
	stevey	01/20/94	Re-indented & fixed a few bugs.

DESCRIPTION:

	This file contains routines for installing Group 3 Fax Printer
	Driver.

	$Id: preffaxInstallGroup3.asm,v 1.1 97/04/05 01:38:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFaxCode	segment	resource

G3IS_category		char "Fax Driver on Unknown",0
EC<  G3IS_driver	char "EC Group3 Fax Driver",0		>
NEC< G3IS_driver	char "Group3 Fax Driver",0		>
G3IS_device 		char "Fax Driver",0
G3IS_port 		char "UNKNOWN",0
G3IS_driverKey		char "driver",0
G3IS_deviceKey		char "device",0
G3IS_portKey		char "port",0
G3IS_typeKey		char "type",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxInstallGroup3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install group 3 fax printer driver to the system.

CALLED BY:	PreffaxSaveOptions
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxInstallGroup3	proc	near
		uses	ax,bx,cx,dx,di,si,bp,es
		.enter
	;
	;  Use spool library to create the new printer...
	;
		segmov	es, cs, di
		mov	di, offset G3IS_category	; es:di = printer name 
		mov	cl, PDT_FACSIMILE
	;
	;  Hack Alert:  the spooler forgets to set the flags
	;  before calling InitFileReadStringSection, so we do it
	;  here.
	;
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 1, 0>
		call	SpoolCreatePrinter
		jc	done				; already exists
	;
	;  Write out all the information about the printer in
	;  the INI file.
	;
		call	PreffaxWriteGroup3Category
done:
		.leave
		ret
PrefFaxInstallGroup3	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreffaxWriteGroup3Category
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write Group 3 Printer Driver info into INI file

CALLED BY:	PrefFaxInstallGroup3

PASS:		es = cs

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreffaxWriteGroup3Category	proc	near
		uses	dx,di,si,bp,ds
		.enter
	;
	;  Write the whole category into INI file.  First get the 
	;  category string.
	;
		segmov	ds, cs, cx			; ds = cx = cs
		mov	si, offset G3IS_category	; ds:si = category str
		mov	dx, offset G3IS_driverKey	; cx:dx = driver key
	;
	;  Get the appropriate driver name...
	;
		mov	di, offset G3IS_driver		; es:di = driver name
		call	InitFileWriteString		; write to INI file
	;
	; Get the device keyword string from the string segment.
	;
		mov	dx, offset G3IS_deviceKey	; cx:dx = device key
		mov	di, offset G3IS_device		; es:di = category
		call	InitFileWriteString		; write to INI file
	;
	;  Write the port string...
	;
		mov	dx, offset G3IS_portKey
		mov	di, offset G3IS_port
		call	InitFileWriteString		; write to INI file
	;
	;  Get the type keyword from the str resource seg.
	;
		mov	dx, offset G3IS_typeKey		; cx:dx = type key
		mov	bp, PDT_FACSIMILE
		call	InitFileWriteInteger		; write to INI file
		
		.leave
		ret
PreffaxWriteGroup3Category	endp

PrefFaxCode	ends
