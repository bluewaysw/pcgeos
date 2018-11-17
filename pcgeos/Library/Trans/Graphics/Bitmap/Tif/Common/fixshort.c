/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		fixshort.c<2>				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	1/27/92		Initial version			     
*								     
*	DESCRIPTION:						     
*								     
*	$Id: fixshort.c,v 1.1 97/04/07 11:28:28 newdeal Exp $
*							   	     
*********************************************************************/



 
/*************************************************************************\
  FIXSHORT - Routines used for swap the bytes on the string
\*************************************************************************/
#include <hsimem.h> 
#include <Ansi/stdio.h>
 
extern  BOOL   brainDamage;
 
WORD  fixshort    (WORD);
DWORD fixlong     (DWORD);
 
/***************************************************************************
 
   FUNCTION:   fixshort(WORD)
   
   PURPOSE:    Conversion INTEL integer to have correct BYTE order
 
   PARAMETER:  WORD    aShort      
           
   RETURN:     Converted WORD
 
****************************************************************************/
 
WORD fixshort( WORD aShort )
   {
   WORD    newShort;
#ifdef MOTOROLA 
   if ( brainDamage ) 
       {
       newShort = (aShort >> 8) & 0xff;
       newShort |= ((aShort & 0xff) << 8);
       return (newShort);
       }
     else
#else
   if ( !brainDamage ) 
       {
       newShort = (aShort >> 8) & 0xff;
       newShort |= ((aShort & 0xff) << 8);
       return (newShort);
       }
   else
       return (aShort);
#endif  
 }
 

 
 
/*
 * Required if file is MOTOROLA format. Fix the 4-byte integer(which is 
 * LONG on DOS machine 
 */
 
DWORD        fixlong (DWORD anInt)
   {
   DWORD        newInt;
 
   if ( !brainDamage ) 
         {
          newInt  = (DWORD)fixshortnow ((WORD)((anInt >> 16) & 0xffff));
          newInt |= (DWORD)((DWORD)fixshortnow((WORD)(anInt & 0xffff)) << 16);
         return (newInt);
          }
    else
            return (anInt);
   }


/* swap bytes within words -- overlapping arrays are handled properly */

void _lswab (lpSrc, lpDst, nbytes)
register LPSTR	lpSrc, lpDst;	/* assumed to be word-aligned */
WORD  			nbytes;			/* assumed to be even */
   {
   register WORD words;
   union 
	    {
	    char c[2];
	    WORD w;
	    } wrd;

   words = nbytes/2;

   if (lpDst <= lpSrc || lpDst >= lpSrc + nbytes) 
	    {
	    for (; words--; lpSrc += 2) 
		    {
		    wrd.w = *(WORD FAR *)lpSrc;
		    *lpDst++ = *(LPSTR)(wrd.c + 1);	/* W2 doesn't like wrd.c[1] */
		    *lpDst++ = *(LPSTR)(wrd.c);
		    }
	    }
   else 
	    {		/* we'll have to go backward */
	    lpSrc += nbytes - sizeof(WORD);
	    lpDst += nbytes - 1;
	    for (; words--; lpSrc -= 2) 
		    {
		    wrd.w = *(WORD FAR *)lpSrc;
		    *lpDst-- = *(LPSTR)(wrd.c);
		    *lpDst-- = *(LPSTR)(wrd.c + 1);
		    }
	    }
   }
 
 




























































