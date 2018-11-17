COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		resolver
FILE:		resolverManager.asm

AUTHOR:		Steve Jang, Dec 14, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94   	Initial revision

DESCRIPTION:
	Resolver that provides DNS services.

	$Id: resolverManager.asm,v 1.1 97/04/07 10:42:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;                            System Includes
;-----------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include system.def

include object.def
include timer.def
include timedate.def
include driver.def
include	assert.def
include thread.def
include Internal/semInt.def
include sem.def
include Internal/heapInt.def
include	initfile.def
include medium.def
include	file.def
include sockmisc.def

UseDriver Internal/streamDr.def
UseDriver Internal/serialDr.def

;-----------------------------------------------------------------------------
;                            System Libraries
;-----------------------------------------------------------------------------

UseLib  ui.def
UseLib	Internal/netutils.def
UseLib	sac.def
UseLib	socket.def
UseLib	accpnt.def
UseLib	dhcp.def

; -----------------------------------------------------------------------------
;                          Library
; -----------------------------------------------------------------------------

include	stdapp.def
include library.def
DefLib	resolver.def

; -----------------------------------------------------------------------------
;                           Internal def files
; -----------------------------------------------------------------------------

include	resolverInt.def

; -----------------------------------------------------------------------------
;                               Code files
; -----------------------------------------------------------------------------

EC< .rcheck>
EC< .wcheck>
include	resolver.asm
include resolverEvents.asm
include resolverActions.asm
include resolverComm.asm
include resolverUtils.asm
include	resolverCApi.asm
include resolverCache.asm

; -----------------------------------------------------------------------------
;			      Memory Resources
; -----------------------------------------------------------------------------

ResolverQueueBlock	segment lmem LMEM_TYPE_GENERAL
ResolverQueueBlock	ends

ResolverRequestBlock	segment	lmem LMEM_TYPE_GENERAL
RequestBlockHeader	<
	{},		; LMemBlockHeader
	requestRootNode,; dummy header
	1000		; RBH_curId	- to distinguish from other data
>
requestRootNode	chunk.RequestNode <
< mask NF_ROOT or mask NF_LAST, \
  requestRootNode,
  requestRootNode,
  requestRootNode >,				; NodeCommon
	0,					; id
	0,					; timeStamp
	0,					; workAllowed
	0,					; stype
	0,					; sclass
	0,					; slist
	0,					; matchCount
	0,					; answer
	0>					; blockSem

ResolverRequestBlock	ends

ResolverCacheBlock	segment	lmem LMEM_TYPE_GENERAL
CacheBlockHeader	<
	{},		; LMemBlockHeader
	<>,		; temp resource record ( see CacheFileReadRecord )
	rrRootNode,	; root node
	tempNode	; temp node used in TreeEnum -- see REMOVING A NODE...
>
rrRootNode	chunk.RRRootNode <
	<< mask NF_ROOT or mask NF_LAST,
	    rrRootNode,
	    rrRootNode,
	    rrRootNode >,			; NodeCommon
	0>,					; resource = null
	0					; null label
>
tempNode	chunk.RRRootNode <
       << mask NF_LAST,
	  tempNode,
	  tempNode,
	  tempNode >,				; NodeCommon
	0>,					; resource = null
	0					; null label
>

ResolverCacheBlock	ends

ResolverAnswerBlock	segment lmem LMEM_TYPE_GENERAL

ResolverAnswerBlock	ends
