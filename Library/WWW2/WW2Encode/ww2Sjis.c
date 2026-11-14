/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1998.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		ww2Sjis.c

AUTHOR:		Allen Yuen, Aug  3, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	allen   	8/ 3/98   	Initial version

DESCRIPTION:

	SJIS -> Unicode conversion

	$Id: //depot/pcgeos/Library/WWW2/WW2Encode/ww2Sjis.c#1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include <WWW2/WW2Core/ww2Sjis.h>
#include <WWW2/wwMacro.h>

#define SJIS_SB_END_1     0x7e
#define SJIS_SB_START_2  0xa1
#define SJIS_SB_END_2    0xdf

int isalnum_dbcs(TCHAR tc)
{
  if (tc > SJIS_SB_END_1) {
    return FALSE;
  }
  return (ISALNUM(tc));
}

/* return TRUE if character is two bytes long */
int CheckForSingleByte(byte b)
{
  if (b > SJIS_SB_END_2) {
    return TRUE;
  }
  if (b <= SJIS_SB_END_1) {
    return FALSE;
  }
  if (b < SJIS_SB_START_2) {
    return TRUE;
  }
  return FALSE;
}

word SjisStringToUnicodeString(char *src, TCHAR *dst, word maxSize)
{
/// This is not working yet.  I am still not sure if we should use
/// GEOS kernel routine instead.
#if 0
  word  count = 0;
  byte c1, c2;
  char  *cp;
  TCHAR tc;
  word index = 0;

  cp = (char *)dst;
  while (index < maxSize) {
    count++;
    c1 = src[index++];
    if (c1 <= SJIS_SB_END_1) 
    {
      /* ASCII */
      switch(c1) {
      case '\0':
	*cp++ = 0;
	*cp++ = 0;
	return (word) (count - 1);
      }
      *cp++ = c1;
      *cp++ = 0;
      if (index >= maxSize) {
	return count;
      }
      continue;
    }
    if (CheckForSingleByte(c1)) {
      c2 = src[index++];
    } else {
      c2 = 0;
    }
    tc = (TCHAR) (c1 + (c2 << 8));
    if (tc <= SJIS_SB_END_2) {
      /* IS HALFWIDTH */
      tc += 0xff61; /* C_HALFWIDTH_IDEOGRAPH_PERIOD */
      tc -= SJIS_SB_START_2;
      *cp++ = (char) (tc & 0xff);
      *cp++ = (char) ((tc & 0xff00) >> 8);
    }
    else /* NOT HALFWIDTH */
    {
      tc = (TCHAR) (c2 + (c1 << 8));
      tc = SJISToUnicode(tc);
      *cp++ = (char) (tc & 0xff);
      *cp++ = (char) ((tc & 0xff00) >> 8);
    }
  }
  return count;
#else
dst[0] = '\0';
return 0;
#endif
}
