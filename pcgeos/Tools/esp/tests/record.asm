COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		record.asm

AUTHOR:		Adam de Boor, Sep  5, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 5/89		Initial revision


DESCRIPTION:
	This file is designed to test the RECORD facilities in Esp.
	
	Should produce the following message(s):
warning: file "tests/record.asm", line 66: extra fields in initializer for record2
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

enum1	etype	byte
E1_ZERO	enum	enum1
E1_ONE	enum	enum1
E1_TWO	enum	enum1

record1	record	
	R1_FIELD:2=E1_ZERO
	end
record2	record
	hibit	:1
		:6
	lobit	:1
record2	end

;
; Access rights for a segment:
;	AR_PRESENT	non-zero if segment actually in memory
;	AR_PRIV		privilege level (0-3) required for access
;	AR_ISMEM	1 if a memory segment, 0 if special
;	AR_TYPE		type of segment
;	AR_ACCESSED	non-zero if memory accessed
;
SegTypes	etype byte
SEG_DATA_RD_ONLY		enum SegTypes
SEG_DATA			enum SegTypes
SEG_DATA_EXPAND_DOWN_RD_ONLY	enum SegTypes
SEG_DATA_EXPAND_DOWN		enum SegTypes
SEG_CODE_NON_READABLE		enum SegTypes
SEG_CODE			enum SegTypes
SEG_CODE_CONFORMING_NON_READABLE enum SegTypes
SEG_CODE_CONFORMING 		enum SegTypes

AccRights	record	AR_PRESENT:1, AR_PRIV:2, AR_ISMEM:1, AR_TYPE:3=SegTypes, AR_ACCESSED:1

biff		segment	resource
		mov	al, AccRights <1,0,1,SEG_DATA,1>
foop		AccRights <1,0,1,SEG_DATA,1>
		record2	<1,1>
		record2 <1,0,1>		; WARNING
biff		ends
