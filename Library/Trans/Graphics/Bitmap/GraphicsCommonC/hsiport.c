/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		hsiport.c				     
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
*	$Id: hsiport.c,v 1.1 97/04/07 11:28:27 newdeal Exp $
*							   	     
*********************************************************************/


#include <hsimem.h>
#include <Ansi/stdio.h>
#include <ctype.h>

/* 
   From the pointer passed, return the WORD (2 bytes) integer value.
   The pointer passed is assumed to pointing to data that has INTEL
   double word format (flip word, flip byte).  Use GetMOTORWORD() when 
   data has MOTOROLA format.  

   This function does not increment the data pointer, nor is it possible.
   The caller has to do so.
*/

WORD  GetINTELWORD(LPSTR s)
   {
#if INTEL  
   return *(LPWORD)s;
#endif

#if MOTOROLA
   if ((int)s%2)   /* not on DWORD boundary, we need to break it to two */
       {           /* word, otherwise bus error.                        */
       BYTE hibyte,lobyte;

       lobyte = *s;        /* INTEL format store the lobyte first */
       hibyte = *(s+1);    /* hibyte 2nd in a WORD.               */

       return MAKEWORD(lobyte,hibyte);
       }
   else
       return fixshortnow(*(LPWORD)s);
#endif

   }



/* 
   From the pointer passed, return the DWORD (4 bytes) integer value.
   The pointer passed is assumed to pointing to data that has INTEL
   double word format (flip word, flip byte).  Use GetMOTORDWORD() when 
   data has MOTOROLA format.

   This function does not increment the data pointer, nor is it possible.
   The caller has to do so.
*/

DWORD  GetINTELDWORD(LPSTR s)
   {
#if INTEL  
   return *(LPDWORD)s;
#endif

#if MOTOROLA
   if ((int)s%4)   /* not on DWORD boundary, we need to break it to two */
       {           /* word, otherwise bus error.                        */
       WORD hiword,loword;

       loword = GetINTELWORD(s);
       hiword = GetINTELWORD(s+2);

       return MAKELONG(loword,hiword);
       }
   else
       return fixlongnow(*(LPDWORD)s);
#endif

   }


/* 
   From the pointer passed, return the WORD (2 bytes) integer value.
   The pointer passed is assumed to pointing to data that has MOTOROLA
   word format (no flipping).  Use GetINTELWORD() when 
   data has INTEL format.

   This function does not increment the data pointer, nor is it possible.
   The caller has to do so.
*/

WORD   GetMOTORWORD(LPSTR s)
   {
#if INTEL
   return fixshortnow(*(LPWORD)s);
#endif

#if MOTOROLA
   if ((int)s%2)
       return *(LPWORD)s;
   else
       {
       BYTE hibyte,lobyte;

       hibyte = *s;
       lobyte = *(s+1);

       return MAKEWORD(lobyte,hibyte);
       }
#endif
   }



/* 
   From the pointer passed, return the DWORD (4 bytes) integer value.
   The pointer passed is assumed to pointing to data that has MOTOROLA
   double word format (no flipping).  Use GetINTELDWORD() when 
   data has INTEL format.

   This function does not increment the data pointer, nor is it possible.
   The caller has to do so.
*/

DWORD   GetMOTORDWORD(LPSTR s)
   {
#if INTEL
   return fixlongnow(*(LPDWORD)s);
#endif

#if MOTOROLA
   if ((int)s%4)
       return *(LPDWORD)s;
   else
       {
       WORD hiword,loword;

       hiword = GetMOTORWORD(s);
       loword = GetMOTORWORD(s+2);

       return MAKEWORD(loword,hiword);
       }
#endif
   }




/*
   Set WORD value to the location of the buffer pointer.  The data is set
   to the INTEL format.  This function does not increment the pointer
   address, it is up to the caller to do so.
*/

void  SetINTELWORD(LPSTR s,WORD n)
   {
#if INTEL
   *(LPWORD)s = n;
#endif

#if MOTOROLA   
   /* always work on byte boundary. since the WORD alignment is strickly */
   /* required on MOTOROLA machine.                                      */

   *s     = LOBYTE(n);         /* INTEL has low byte first */
   *(s+1) = HIBYTE(n);         /* high byte stored second  */

#endif
   }



/*
   Set DWORD value to the location of the buffer pointer.  The data is set
   to the INTEL format.  This function does not increment the pointer
   address, it is up to the caller to do so.
*/

void   SetINTELDWORD(LPSTR s,DWORD n)
   {
#if INTEL
   *(LPDWORD)s = n;
#endif

#if MOTOROLA   

   SetINTELWORD(s,   LOWORD(n));         /* INTEL has low word first */
   SetINTELWORD(s+2, HIWORD(n));         /* high word stored second  */

#endif
   }



/*
   Set WORD value to the location of the buffer pointer.  The data is set
   to the MOTOROLA format.  This function does not increment the pointer
   address, it is up to the caller to do so.
*/

void   SetMOTORWORD(LPSTR s,WORD n)
   {
#if INTEL
   *(LPWORD)s = fixshortnow(n);
#endif

#if MOTOROLA   
   /* always work on byte boundary. since the WORD alignment is strickly */
   /* required on MOTOROLA machine.                                      */

   *s     = HIBYTE(n);         /* high byte stored first  */
   *(s+1) = LOBYTE(n);         /* low byte stored 2nd     */

#endif
   }


/*
   Set DWORD value to the location of the buffer pointer.  The data is set
   to the MOTOROLA format.  This function does not increment the pointer
   address, it is up to the caller to do so.
*/

void   SetMOTORDWORD(LPSTR s,DWORD n)
   {
#if INTEL
   *(LPDWORD)s = fixlongnow(n);
#endif

#if MOTOROLA   

   SetMOTORWORD(s,   HIWORD(n));         /* INTEL has low word first */
   SetMOTORWORD(s+2, LOWORD(n));         /* high word stored second  */

#endif
   }


#ifdef MACVERSION

char *strlwr(char *s)
	{
	char *t=s;
	
	while (*s)
		{
		*s = tolower(*s);
		s++;
		}
		
	return t;
	}
	

	
int stricmp(char *s, char *t)
    {
    while (*s || *t)
        {
        
        if (tolower(*s) != tolower(*t))
            return 1;
        
        s++; t++;
        }
        
    if (*s || *t)
        return 1;
        
    return 0;
    }
    
int strnicmp(char *s,char *t,int n)
	{
	while (n--)
		{
		if (*s == *t)
			{ s++; t++; continue; }
		
		if (tolower(*s) != tolower(*t))
			return 1;
		
		s++; t++;
		}
		
	return 0;  /* strings are equal */
	}
	
#endif	

#ifdef sun

int strcasecmp(char *s1, char *s2)
  {
  int i;
  char lc1, lc2;

  while (*s1 && *s2)
     {
     lc1 = tolower(*s1);
     lc2 = tolower(*s2);

     if (lc1 < lc2)
	return -1;

     if (lc1 > lc2 )
	return 1;

     s1++; s2++;
     }

  if (*s1 || *s2)
     return 1;

  return 0;
  }

int strnicmp(char *s1, char *s2, int count)
  {
  char lc1;
  char lc2;
  int  i;

  for(i=0; i< count; i++)
     {
     lc1 = tolower(s1[i]);
     lc2 = tolower(s2[i]);
     if (lc1 < lc2)
        return -1;
     if (lc1 > lc2)
        return 1;
     }

  return 0;
  }
#endif



#ifndef GEOSVERSION

#ifdef WINVERSION
void DebugOut ( LPSTR szFormat, ... )
#else
void DebugOut ( char *szFormat, ... )
#endif
   {
#ifdef DEBUG
   static char  szBuffer[ 256 ];
 
 
#ifdef WINVERSION
   char           *pArguments;
 
   pArguments   = (LPSTR) &szFormat + i;
   wvsprintf( (LPSTR)szBuffer, szFormat, pArguments);
   OutputDebugString ( szBuffer );
#else
   char         *pArguments;
   SHORT   i;
 
   pArguments   = (char *)((int)&szFormat+(SHORT)sizeof(szFormat));
 
   vsprintf(szBuffer, 
            szFormat, 
            pArguments );
   printf("%s",szBuffer);
#endif
 
#endif
   }
#endif

















