/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	token.h
 * AUTHOR:	Brian Chin: May 21, 1992
 *
 * DECLARER:	UI
 *
 * DESCRIPTION:
 *	Routines to manage a database of visual monikers.
 *
 *	$Id: token.h,v 1.1 97/04/04 15:58:48 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__TOKEN_H
#define __TOKEN_H

typedef DBGroupAndItem TokenDBItem;

typedef WordFlags TokenFlags;
#define TF_NEED_RELOCATION	0x8000
#define TF_UNUSED		0x7fff

typedef struct {
    GeodeToken		TE_token;
    TokenDBItem		TE_monikerList;
    TokenFlags		TE_flags;
    ReleaseNumber	TE_release;
    ProtocolNumber	TE_protocol;
} TokenEntry;

/* The TokenMonikerInfo structure is used by apps which call
   TokenLookupMoniker, store the information returned, and later use
   it to call TokenLockTokenMoniker.
*/
typedef struct {
    TokenDBItem         TMI_moniker;
    word                TMI_fileFlag;           /* 0 if token is in shared
						   token DB file
						   Non-0 if it's in local file
						 */
} TokenMonikerInfo;

/* The TokenRangeFlags are used with TokenListTokens to describe the
   range of tokens the caller would like to get.
*/
typedef WordFlags TokenRangeFlags;
#define TRF_ONLY_GSTRING	0x8000
#define TRF_ONLY_PASSED_MANUFID	0x4000
#define TRF_UNUSED		0x3fff

/* TokenOpenLocalTokenDB will return 0 on success or a VMStatus error
   code if it could not open an existing local token database. It will
   not create a new local token database; see TokenDefineToken.
*/
extern word /*XXX*/
    _pascal TokenOpenLocalTokenDB(void);

extern void /*XXX*/
    _pascal TokenCloseLocalTokenDB(void);

/* TokenDefineToken will return 0 on success or a VMStatus error code if
   it tried and failed to create the local token database file, without
   which no tokens can be defined. If TokenDefineToken has succeeded once,
   it will always succeed, since the local token database will be in place.
*/
extern word /*XXX*/
    _pascal TokenDefineToken(dword tokenChars,
		     ManufacturerID manufacturerID,
		     optr monikerList,
		     TokenFlags flags);

extern Boolean /*XXX*/
    _pascal TokenGetTokenInfo(dword tokenChars,
		      ManufacturerID manufacturerID,
		      TokenFlags *flags);

extern Boolean /*XXX*/
    _pascal TokenLookupMoniker(dword tokenChars,
		       ManufacturerID manufacturerID,
		       DisplayType displayType,
		       VisMonikerSearchFlags searchFlags,
		       TokenMonikerInfo *tokenMonikerInfo);

extern Boolean
    _pascal TokenLoadMonikerBlock(dword tokenChars,
			  ManufacturerID manufacturerID,
			  DisplayType displayType,
			  VisMonikerSearchFlags searchFlags,
			  word *blockSize,
			  MemHandle *blockHandle);

extern Boolean
    _pascal TokenLoadMonikerChunk(dword tokenChars,
			  ManufacturerID manufacturerID,
			  DisplayType displayType,
			  VisMonikerSearchFlags searchFlags,
			  MemHandle lmemBlock,
			  word *chunkSize,
			  ChunkHandle *chunkHandle);

extern Boolean
    _pascal TokenLoadMonikerBuffer(dword tokenChars,
			   ManufacturerID manufacturerID,
			   DisplayType displayType,
			   VisMonikerSearchFlags searchFlags,
			   void *buffer,
			   word bufferSize,
			   word *bytesReturned);

extern Boolean /*XXX*/
    _pascal TokenRemoveToken(dword tokenChars, ManufacturerID manufacturerID);

extern void /*XXX*/
    _pascal TokenGetTokenStats(dword tokenChars, ManufacturerID manufacturerID);

extern Boolean
    _pascal TokenLoadTokenBlock(dword tokenChars,
			ManufacturerID manufacturerID,
			word *blockSize,
			MemHandle *blockHandle);

extern Boolean
    _pascal TokenLoadTokenChunk(dword tokenChars,
			ManufacturerID manufacturerID,
			MemHandle lmemBlock,
			word *chunkSize,
			ChunkHandle *chunkHandle);

extern Boolean
    _pascal TokenLoadTokenBuffer(dword tokenChars,
			 ManufacturerID manufacturerID,
			 TokenEntry *buffer);

/*
  IMPORTANT: No token database call may be made between a call
  to TokenLockTokenMoniker and the corresponding call to
  TokenUnlockTokenMoniker. TokenLockTokenMoniker grabs the semaphore
  for the token database file containing the moniker; TokenUnlockTokenMoniker
  releases it. Calling any token database routine before the semaphore
  is released will hang the system.
*/
extern void * /*XXX*/
    _pascal TokenLockTokenMoniker(TokenMonikerInfo tokenMonikerInfo);

extern void /*XXX*/
    _pascal TokenUnlockTokenMoniker(void *moniker);

extern dword /*XXX*/
    _pascal TokenListTokens (TokenRangeFlags tokenRangeFlags,
			     word headerSize,
			     ManufacturerID manufacturerID);

/*
 * Use these macros to fetch handle and count return values from
 * TokenListTokens.
 */
#define TokenListTokensHandleFromDWord(d) \
    ((MemHandle) (d))
#define TokenListTokensCountFromDWord(d) \
    ((word) ((d) >> 16))

/*
 * Use this macro to pass the tokenChars to the above routines
 */
#define TOKEN_CHARS(A, B, C, D) \
    (((dword)(A)) | (((dword)(B)) << 8) | (((dword)(C)) << 16) | (((dword)(D)) << 24))

/*
 * Advanced information about icons in a token
 */
extern int _export _pascal TokenTestIcon(int testVal);
extern int _export _pascal TokenListIcons(int testVal);


#ifdef __HIGHC__
pragma Alias(TokenOpenLocalTokenDB, "TOKENOPENLOCALTOKENDB");
pragma Alias(TokenCloseLocalTokenDB, "TOKENCLOSELOCALTOKENDB");
pragma Alias(TokenDefineToken, "TOKENDEFINETOKEN");
pragma Alias(TokenGetTokenInfo, "TOKENGETTOKENINFO");
pragma Alias(TokenLookupMoniker, "TOKENLOOKUPMONIKER");
pragma Alias(TokenLoadMonikerBlock, "TOKENLOADMONIKERBLOCK");
pragma Alias(TokenLoadMonikerChunk, "TOKENLOADMONIKERCHUNK");
pragma Alias(TokenLoadMonikerBuffer, "TOKENLOADMONIKERBUFFER");
pragma Alias(TokenRemoveToken, "TOKENREMOVETOKEN");
pragma Alias(TokenGetTokenStats, "TOKENGETTOKENSTATS");
pragma Alias(TokenLoadTokenBlock, "TOKENLOADTOKENBLOCK");
pragma Alias(TokenLoadTokenChunk, "TOKENLOADTOKENCHUNK");
pragma Alias(TokenLoadTokenBuffer, "TOKENLOADTOKENBUFFER");
pragma Alias(TokenLockTokenMoniker, "TOKENLOCKTOKENMONIKER");
pragma Alias(TokenUnlockTokenMoniker, "TOKENUNLOCKTOKENMONIKER");
pragma Alias(TokenListTokens, "TOKENLISTTOKENS");

pragma Alias(TokenTestIcon, "TOKENTESTICON");
pragma Alias(TokenListIcons, "TOKENLISTICONS");
#endif

#endif
