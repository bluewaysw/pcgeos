COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		dellistManager.asm

AUTHOR:		Robert Greenwalt, Feb 13, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/13/97   	Initial revision


DESCRIPTION:
		
	Routines for accessing the scrolls of the dead.  Beware!

	$Id: dellistManager.asm,v 1.1 97/04/04 17:53:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include dsGeode.def
include dellist.asm


DS_DEL_LIST_LENGTH	equ	100	; since each entry is 8 bytes
					; and the overhead is 4 bytes 
					; this gives us 804 used.


DelListEntry	struct
	DLE_transactionNumber	dword	; the transaction number of
					; this deletion
	DLE_recordID		dword	; the id of the record deleted
DelListEntry	ends



	;
	; The list is a circular buffer with DS_DEL_LIST_LENGTH
	; number of entries.  The recentlyDeceased pointer indicates
	; the most recently added, with the next entry (wrapping if
	; needed) being the oldest in the table, and the next to be
	; overwritten.
	;
	; The cache keeps the last hit, with the reasoning that if we
	; want all since a certain number the search is alway "give me
	; the one after foo" returning foo+x and the next search is
	; likely "give me the one after foo+x".  The next entry after
	; the cache (on a hit - that is the cache is still valid and
	; the list hasn't changed beneath it) will either be the
	; beginning of the list (list-wrap) or the next deleted.
	;

DelList	struct
	DL_latest		word		; offset to latest addition
	DL_cachedTransaction	dword		; trans number last found
	DL_cachedOffset		word		; offset to the cached entry
	DL_listTop		label	byte	; top of the list
DelList	ends


