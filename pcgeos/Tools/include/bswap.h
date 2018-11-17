/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  bswap.h
 * FILE:	  bswap.h
 *
 * AUTHOR:  	  Adam de Boor: Aug 27, 1991
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/27/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This header contains definitions to byte-swap integers from the
 *	Intel (little-endian) order, if necessary.
 *
 *
 * 	$Id: bswap.h,v 1.2 97/04/17 17:26:37 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _BSWAP_H_
#define _BSWAP_H_

#if defined(sparc) || defined(mc68000) || defined(mc68020) || defined(is68k)
/*
 * Swap a word or longword in-place. May be used with post-increment.
 */
#define swapsp(p) { unsigned char *_cp = (unsigned char *)(p), _c; \
		     _c = *_cp++; _cp[-1] = *_cp; *_cp = _c; }
#define swaplp(p) { unsigned char *_cp = (unsigned char *)(p), _c; \
		     c = _cp[3]; _cp[3] = _cp[0]; _cp[0] = c; \
		     c = _cp[2]; _cp[2] = _cp[1]; _cp[1] = c; }

/*
 * Swap a word or longword as a value, returning the value swapped.
 */
#define swaps(s)    ((((s) << 8) | (((unsigned short)(s)) >> 8)) & 0xffff)
#define swapl(l)    (((l) << 24) | \
		     (((l) & 0xff00) << 8) | \
		     (((l) >> 8) & 0xff00) | \
		     (((unsigned long)(l)) >> 24))
#define DOSWAP

#else
#define swapsp(p) (*(p))
#define swaplp(p) (*(p))
#define swaps(s) (s)
#define swapl(l) (l)
#endif

#endif /* _BSWAP_H_ */
