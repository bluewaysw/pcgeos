/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		packbit2.c

AUTHOR:		Maryann Simmons, Jun 17, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/17/92   	Initial version.

DESCRIPTION:
	
	$Id: packbit.c,v 1.1 97/04/07 11:28:26 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


/***************************************************************************
   NAME         : packbit1.c
   DESCRIPTION  : Contain both packbit1() and unpackbit1() routine.
   HISTORY      : 06/04/89     Created
***************************************************************************/
#include "hsimem.h"

#include <Ansi/stdio.h>
#include <Ansi/string.h>



SHORT Unpackbit1s  (LPSTR, LPSTR, SHORT);
SHORT packbit1s    (LPSTR, LPSTR, WORD );
char CalcRaw     (WORD,  LPSTR, LPSTR );

int  BigPackBits (LPSTR, LPSTR, WORD );

#define INITIAL        0
#define LITERAL        1
#define UNDECIDED      2
#define MAXINBYTES     127

char CalcRaw ( WORD n, LPSTR lpIn, LPSTR rawrunbuf )
   {
   char ncounts = 0;
   char thisbyte;
   char cnt = 1;
   char runbyte = *lpIn++;

   while ( --n )
        {
        thisbyte = *lpIn++;
        if (thisbyte == runbyte)
            {
            cnt++;
            }
        else
            { /* write prev raw run, & start a new one */
            *rawrunbuf++ = cnt;
            ncounts++;
            cnt = 1;
            runbyte = thisbyte;
            }
        }

   *rawrunbuf = cnt;
   return (++ncounts);
   }



/*
 * Compress input string using packbit1 algorithm and put the output
 * in output buffer
 */
SHORT packbit1s(LPSTR plpIn, LPSTR plpOut, WORD n)
   {
   LPSTR    lpIn = plpIn;
   LPSTR    lpOut = plpOut;
   char    runcount;
   static char    rawrunbuf[MAXINBYTES];
   char    *pRaw;
   char    nraw;
   char    state;
   char    rawcount;
   char    twins;
   /*SHORT   err = 0, bytecount =0 ;*/

   /* calculate raw run counts     */
   nraw = CalcRaw ( n, lpIn, rawrunbuf );

   if (nraw <= 0 || nraw > 127)
        {
        /*err = 1;*/
        goto cu0;
        }

   /* initialize a few things     */
   pRaw = rawrunbuf;
   state = INITIAL;

   /* go through the raw run count array     */

   while ( nraw-- )
        {
        rawcount = *pRaw++;

        if ( rawcount < 1 || rawcount > 127 )
            {
            /*err = 1;*/
            goto cu0;
            }

        if ( state == INITIAL)
            {
            if ( rawcount == 1 )
                {
                state = LITERAL;
                runcount = 1;
                }
            else if ( rawcount == 2 )
                {
                state = UNDECIDED;
                runcount = 2;
                }
            else
                {    /* rawcount >= 3, state = INITIAL; */
                    /* write replicate run and update ptrs */
                *lpOut++ = (BYTE) (-1 *(rawcount - 1));
                *lpOut++ = *lpIn;
                lpIn += rawcount;
                }
            }
        else if (state == LITERAL)
            {
            if (rawcount < 3)
                {
                runcount += rawcount;
                }
            else
                {
                state = INITIAL;
                /* write literal run and update ptrs */
                *lpOut++ = (BYTE)(runcount - 1);

                if (runcount < 1 || runcount > 127)
                    {
                    goto cu0;
                    }

                _fmemcpy ( (LPSTR)lpOut, (LPSTR)lpIn, runcount);
                lpOut += runcount;
                lpIn += runcount;

                /* write replicate run and update ptrs */
                *lpOut++ = (BYTE)(-1*(rawcount - 1));
                *lpOut++ = *lpIn;
                lpIn += rawcount;
                }
            }
        else
            {    /* state = UNDECIDED */
            if (rawcount == 1)
                {
                state = LITERAL;
                runcount++;
                }
            else if (rawcount == 2)
                {
                /* state = UNDECIDED */
                runcount += 2;
                }
            else
                 {    /* rawcount >= 3 */
                state = INITIAL;
                if (runcount < 1 || runcount > 127)
                    {
                    goto cu0;
                    }
                /* write out runcount/2 twin replicate runs */
                for (twins = (char)(runcount>>1); twins-- ;  )
                    {
                    *lpOut++ = -1;
                    *lpOut++ = *lpIn;
                    lpIn += 2;
                    }
                /* write out this replicate run
                */
                *lpOut++ = (BYTE)(-1*(rawcount - 1));
                *lpOut++ = *lpIn;
                lpIn += rawcount;
                }
            } /* end of UNDECIDED case */
        } /* end of main for loop */

   /* clean up hanging states
   */
   if (state == LITERAL)
        {
        if (runcount < 1 || runcount > 127)
            {
            goto cu0;
            }
        /* write out literal run
        */
        *lpOut++ = (BYTE)(runcount - 1);
        _fmemcpy ( (LPSTR)lpOut, (LPSTR)lpIn, runcount);
        lpOut += runcount;
        lpIn += runcount;
        }
   else if (state == UNDECIDED)
        {
        if (runcount < 1 || runcount > 127)
            {
            goto cu0;
            }
        /* write out runcount/2 twin replicate runs
        */
        for (twins = (char)(runcount>>1); twins--; )
            {
            *lpOut++ = -1;
            *lpOut++ = *lpIn;
            lpIn += 2;
            }
        }
   /* set up return values     */
   /*
   *plpIn = lpIn;
   *plpOut = lpOut;
   */
   return (SHORT) (lpOut - plpOut);

   cu0:

   return 0;    /* error condition */

   } /* that's all, folks */



/*****************************************************************************

FUCNTION    Unpackbit1s    ( plpSrc, plpDst, dstBytes )

PURPOSE     Unpack source string to target string.  Return when number of
            uncompressed bytes is equal to the dstBytes passed. Return an
            interger byte number, which is number of bytes used from the
            input string. That number can be used by caller to rearrange
            file I/O.

RETURN     0 : error
            cnt : number of bytes used

******************************************************************************/

SHORT Unpackbit1s ( LPSTR lpSrc, LPSTR lpDst, SHORT dstBytes)
   {
   LPSTR       t=lpSrc;
   char        cc;
   SHORT       count;
   WORD        outsofar = 0;
   /*SHORT       err = 0;*/

   while ( outsofar < (WORD)dstBytes )
       {
       cc = *lpSrc;
       lpSrc = (LPSTR)lpSrc + 1L;

       /* if -127 <= BYTE <= -1, replicate the next byte -n+1 times */
       if ( cc & 0x80 )
          {
          count = (signed char)(1 - cc);    /* relies on sign-extension!!! */
          outsofar += count;

          if (outsofar > (WORD)dstBytes)
             {
             /* err = 2;  overflow */
             goto cu0;
             }

          _fmemset ( (LPSTR)lpDst, (BYTE)*lpSrc, (WORD)count );
          lpSrc = lpSrc + 1L;;
          }
       else
          {
          /* else if 0 <= BYTE <= 127, copy the next n+1 bytes literally */
          count = cc + 1;

          if (count <= 0 || count > 128 )
             {
             /*err = 3;  bad literal count */
             goto cu0;
             }

          outsofar += count;

          if ( outsofar > (WORD)dstBytes )
             {
             /* err = 2; */
             goto cu0;
             }

          _fmemcpy ((LPSTR)lpDst, (LPSTR)lpSrc, (WORD)count );
          lpSrc = (LPSTR)lpSrc +(long)count;
          }
       lpDst = (LPSTR)lpDst + (long)count;
       }

   return (int) (lpSrc - t);

   cu0:
       return 0;
   }

/*
 * if you have more than 127 input bytes, call this routine instead
 * of the basic packbit1s
 */

int BigPackBits ( LPSTR plpIn, LPSTR plpOut, WORD n)
   {
   WORD    topack;
   int     runcount = 0, t;

   while ( n )
        {
        topack = (n < MAXINBYTES) ? n : MAXINBYTES;
        t=packbit1s ( plpIn, plpOut, topack );

        if ( t <= 0 )
            return t;
        runcount += t;
        plpIn    = (LPSTR)plpIn + (long)topack;
        plpOut   = (LPSTR)plpOut + t;
        n -= topack;
        }
   return ( (int)runcount);
   }



/******
  END
******/
