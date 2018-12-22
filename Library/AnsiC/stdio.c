/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * MODULE:	AnsiC
 * FILE:	stdio.c
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file implements the following stdio.h routines:
 *		vsprintf
 *		sprintf
 *
 *	$Id: stdio.c,v 1.1 97/04/04 17:42:06 newdeal Exp $
 *
 ***********************************************************************/

#include <geos.h>
#include <object.h>
#include <graphics.h>
#include <system.h>

#include <stdarg.h>

#include <Ansi/string.h>
#include <Ansi/stdio.h>

/***/

#ifdef __HIGHC__
#pragma Code("Format");
#endif
#ifdef __BORLANDC__
#pragma codeseg Format
#endif
#ifdef __WATCOMC__
#pragma code_seg("FORMAT")
#endif

/***********************************************************************
 *
 * FUNCTION:	vsprintf
 *
 * DESCRIPTION:	Print to a string passing var-args
 *
 * CALLED BY:	GLOBAL
 *
 * RETURN:	Number of characters written (not counting NULL)
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
sword _pascal
  VSPRINTF(
    TCHAR *      	buf,		/* dest buffer */
    const TCHAR *	str,		/* control strings */
    va_list		args)		/* args */
{
    TCHAR *origBuf;
    TCHAR mych;
    TCHAR padChar;

    byte leftJustify;
    byte forceSign;
    byte spaceSign;
    byte specialConv;
    word fieldWidth;
/*    word precision; */ /* never used, value calculated but ignored */
    word longSize;

    TCHAR *cptr;
    TCHAR fieldBuf[200];
    TCHAR  *fieldPtr;
    sword padLength;


    origBuf = buf;
    while ( (mych = *str++) != _TEXT('\0')) {
        if (mych != _TEXT('%')) {
	    *buf++ = mych;
	} else {

	    /* Parse flag characters */

	    leftJustify = forceSign = spaceSign = specialConv = 0;
	    padChar = _TEXT(' ');

	flag_chars_loop:
	    mych = *str++;
	    switch(mych) {
		case _TEXT('-') : { leftJustify = 1; goto flag_chars_loop; }
		case _TEXT('0') : { padChar = _TEXT('0'); goto flag_chars_loop; }
		case _TEXT('+') : { forceSign = 1; goto flag_chars_loop; }
		case _TEXT(' ') : { spaceSign = 1; goto flag_chars_loop; }
		case _TEXT('#') : { specialConv = 1; goto flag_chars_loop; }
	    }

	    /* Parse field width */

	    fieldWidth = 0;
	    if (mych == _TEXT('*')) {
		fieldWidth = va_arg(args, word);
		mych = *str++;
	    } else {
	        while ( (mych >= _TEXT('0')) && (mych <= _TEXT('9')) ) {
		    fieldWidth = (fieldWidth*10) + mych - _TEXT('0');
		    mych = *str++;
		}
	    }

	    /* Parse precision */

/*	    precision = 8; */
	    if (mych == _TEXT('.')) {
		mych = *str++;
		if (mych == _TEXT('*')) {
/*		    precision =  va_arg(args, word); */
		    mych = *str++;
		} else {
	            while ( (mych >= _TEXT('0')) && (mych <= _TEXT('9')) ) {
		        fieldWidth = (fieldWidth*10) + mych - _TEXT('0');
		        mych = *str++;
	            }
		}
	    }

	    /* Parse long size flag */

	    longSize = 0;
	    if (mych == _TEXT('l')) {
		longSize = 1;
		mych = *str++;
	    }

	    /* Parse field into fieldBuf */

	    cptr = fieldPtr = fieldBuf;
	    fieldBuf[1] = _TEXT('\0');
	    switch (mych) {
		case _TEXT('d') :	    /* signed integer */
		case _TEXT('w') : {	    /* WWFixed */
		    sdword d;
		    if (longSize || (mych == _TEXT('w'))) {
			d = va_arg(args, sdword);
		    } else {
			d = va_arg(args, sword);
		    }
		    if (d < 0) {
			d = -d;
			*cptr++ = _TEXT('-');
		    } else {
			if (forceSign) {
			    *cptr++ = _TEXT('+');
			} else if (spaceSign) {
			    *cptr++ = _TEXT(' ');
			}
		    }
		    if (mych == _TEXT('w')) {
	            	UtilHex32ToAscii((char*)cptr, (dword) WWFixedToInt(d),
					    	    UHTAF_NULL_TERMINATE);
			while (*cptr != _TEXT('\0')) {
			    cptr++;
			}
			*cptr++ = _TEXT('.');
			d = d & 0xffff;
			if (d == 0) {
			    *cptr++ = _TEXT('0');
			    *cptr++ = _TEXT('\0');
			} else {
			    d = (GrMulWWFixed(d, MakeWWFixed(10000))+5000)>>16;
			    if (d < 10) { *cptr++ = _TEXT('0'); }
			    if (d < 100) { *cptr++ = _TEXT('0'); }
			    if (d < 1000) { *cptr++ = _TEXT('0'); }
	            	    UtilHex32ToAscii((char*)cptr, d, UHTAF_NULL_TERMINATE);
			}
		    } else {
	            	UtilHex32ToAscii((char*)cptr, d, UHTAF_NULL_TERMINATE);
		    }
		    break;
		}
		case _TEXT('u') : {	    /* unsigned integer */
		    dword d;
		    if (longSize) {
			d = va_arg(args, dword);
		    } else {
			d = va_arg(args, word);
		    }
	            UtilHex32ToAscii((char*)fieldBuf, d, UHTAF_NULL_TERMINATE);
		    break;
		}
		case _TEXT('x') :
		case _TEXT('X') : {	    /* unsigned integer in hex */
		    dword d;
		    sword shiftCount;
		    word flag;
		    TCHAR hch;
		    if (longSize) {
			d = va_arg(args, dword);
		    } else {
			d = va_arg(args, word);
		    }
		    if (specialConv) {
			*cptr++ = _TEXT('0');
			*cptr++ = mych;
		    }
		    flag = 0;
		    for (shiftCount = 28; shiftCount >= 0; shiftCount -= 4) {
			hch = ((d >> shiftCount) & 0xf) + _TEXT('0');
			if (hch > _TEXT('9')) {
			    if (mych == _TEXT('x')) {
				hch = hch - _TEXT('0') - 10 + _TEXT('a');
			    } else {
				hch = hch - _TEXT('0') - 10 + _TEXT('A');
			    }
			}
			if (flag || (hch != _TEXT('0')) || (shiftCount == 0)) {
			    flag = 1;
			    *cptr++ = hch;
			}
		    }
		    *cptr = _TEXT('\0');
		    break;
		}
#ifdef DO_DBCS
		case _TEXT('S') :	    /* SBCS string */
#endif
		case _TEXT('s') : {	    /* string */
		    fieldPtr = va_arg(args, char *);
		    if (fieldPtr == NULL) {
			fieldPtr = fieldBuf;
			fieldBuf[0] = _TEXT('\0');
		    }
		    break;
		}
		case _TEXT('c') : {	    /* char */
		    fieldBuf[0] = va_arg(args, char);
		    break;
		}
		case _TEXT('%') : {	    /* % sign */
		    fieldBuf[0] = _TEXT('%');
		    break;
		}
	        case _TEXT('f') :
	        case _TEXT('F') : {	    /* float */
		    /* 
		     * Not supported just yet, but we can skip it.
		    /* The argument size is double, unless the 'L' size
		     * modifier is used, in which case it is long double.
		     */
		    (void)va_arg(args, double);
		    /* FALL-THRU... */
		}
		default : {
		    fieldBuf[0] = _TEXT('X');
		}
	    }

	    /*
	     * Format fieldBuf:
	     * fieldWidth = width of field (or 0 for not set)
	     * leftJustify = TRUE to left justify value in field, FLASE to rj
	     * padChar = character for padding
	    */


#ifdef DO_DBCS
	    padLength = fieldWidth - (mych=='S' ? strlensbcs((char *)fieldPtr) :
		strlen(fieldPtr));
#else
	    padLength = fieldWidth - strlen(fieldPtr);
#endif
	    if (!leftJustify) {
	    	while (padLength > 0) {
		    *buf++ = padChar;
		    padLength--;
	    	}
	    }

	    /* Add fieldBuf to the string */

#ifdef DO_DBCS
	    if (mych == 'S') {
		while (*((char*)fieldPtr) != '\0') {
		    *buf++ = *((char *)fieldPtr)++;
		}
	    } else
#endif
	    while (*fieldPtr != _TEXT('\0')) {
		*buf++ = *fieldPtr++;
	    }

	    /* Take care of padding if left justifying */

	    if (leftJustify) {
	    	while (padLength > 0) {
		    *buf++ = padChar;
		    padLength--;
	    	}
	    }
	}
    }
    *buf = _TEXT('\0');
    return (buf - origBuf);
}

/***********************************************************************
 *
 * FUNCTION:	sprintf
 *
 * DESCRIPTION:	Print to a string
 *
 * CALLED BY:	GLOBAL
 *
 * RETURN:	Number of characters written (not counting NULL)
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
sword
  _cdecl sprintf(
    TCHAR *		buf,		/* dest buffer */
    const TCHAR *	str,		/* control strings */
    ...)				/* args */
{
    va_list args;
    sword sw;

    va_start(args, str);
    sw = vsprintf(buf, str, args);
    va_end(args);
    return sw;
}


#ifdef DO_DBCS

/*
 * For DBCS, we have SBCS versions
 */

#pragma codeseg FORMATSBCS

sword _pascal
  VSPRINTFSBCS(
    char *      	buf,		/* dest buffer */
    const char *	str,		/* control strings */
    va_list		args)		/* args */
{
    char *origBuf;
    char mych;
    char padChar;

    byte leftJustify;
    byte forceSign;
    byte spaceSign;
    byte specialConv;
    word fieldWidth;
/*    word precision; */ /* never used, value calculated but ignored */
    word longSize;

    char *cptr;
    char fieldBuf[200];
    char  *fieldPtr;
    sword padLength;


    origBuf = buf;
    while ( (mych = *str++) != '\0') {
        if (mych != '%') {
	    *buf++ = mych;
	} else {

	    /* Parse flag characters */

	    leftJustify = forceSign = spaceSign = specialConv = 0;
	    padChar = ' ';

	flag_chars_loop:
	    mych = *str++;
	    switch(mych) {
		case '-' : { leftJustify = 1; goto flag_chars_loop; }
		case '0' : { padChar = '0'; goto flag_chars_loop; }
		case '+' : { forceSign = 1; goto flag_chars_loop; }
		case ' ' : { spaceSign = 1; goto flag_chars_loop; }
		case '#' : { specialConv = 1; goto flag_chars_loop; }
	    }

	    /* Parse field width */

	    fieldWidth = 0;
	    if (mych == '*') {
		fieldWidth = va_arg(args, word);
		mych = *str++;
	    } else {
	        while ( (mych >= '0') && (mych <= '9') ) {
		    fieldWidth = (fieldWidth*10) + mych - '0';
		    mych = *str++;
		}
	    }

	    /* Parse precision */

/*	    precision = 8; */
	    if (mych == '.') {
		mych = *str++;
		if (mych == '*') {
/*		    precision =  va_arg(args, word); */
		    mych = *str++;
		} else {
	            while ( (mych >= '0') && (mych <= '9') ) {
		        fieldWidth = (fieldWidth*10) + mych - '0';
		        mych = *str++;
	            }
		}
	    }

	    /* Parse long size flag */

	    longSize = 0;
	    if (mych == 'l') {
		longSize = 1;
		mych = *str++;
	    }

	    /* Parse field into fieldBuf */

	    cptr = fieldPtr = fieldBuf;
	    fieldBuf[1] = '\0';
	    switch (mych) {
		case 'd' :	    /* signed integer */
		case 'w' : {	    /* WWFixed */
		    sdword d;
		    if (longSize || (mych == 'w')) {
			d = va_arg(args, sdword);
		    } else {
			d = va_arg(args, sword);
		    }
		    if (d < 0) {
			d = -d;
			*cptr++ = '-';
		    } else {
			if (forceSign) {
			    *cptr++ = '+';
			} else if (spaceSign) {
			    *cptr++ = ' ';
			}
		    }
		    if (mych == 'w') {
	            	UtilHex32ToAscii(cptr, (dword) WWFixedToInt(d),
					 UHTAF_NULL_TERMINATE|UHTAF_SBCS_STRING);
			while (*cptr != '\0') {
			    cptr++;
			}
			*cptr++ = '.';
			d = d & 0xffff;
			if (d == 0) {
			    *cptr++ = '0';
			    *cptr++ = '\0';
			} else {
			    d = (GrMulWWFixed(d, MakeWWFixed(10000))+5000)>>16;
			    if (d < 10) { *cptr++ = '0'; }
			    if (d < 100) { *cptr++ = '0'; }
			    if (d < 1000) { *cptr++ = '0'; }
	            	    UtilHex32ToAscii(cptr, d, UHTAF_NULL_TERMINATE|
				UHTAF_SBCS_STRING);
			}
		    } else {
	            	UtilHex32ToAscii(cptr, d, UHTAF_NULL_TERMINATE|
			    UHTAF_SBCS_STRING);
		    }
		    break;
		}
		case 'u' : {	    /* unsigned integer */
		    dword d;
		    if (longSize) {
			d = va_arg(args, dword);
		    } else {
			d = va_arg(args, word);
		    }
	            UtilHex32ToAscii(fieldBuf, d, UHTAF_NULL_TERMINATE|
			UHTAF_SBCS_STRING);
		    break;
		}
		case 'x' :
		case 'X' : {	    /* unsigned integer in hex */
		    dword d;
		    sword shiftCount;
		    word flag;
		    char hch;
		    if (longSize) {
			d = va_arg(args, dword);
		    } else {
			d = va_arg(args, word);
		    }
		    if (specialConv) {
			*cptr++ = '0';
			*cptr++ = mych;
		    }
		    flag = 0;
		    for (shiftCount = 28; shiftCount >= 0; shiftCount -= 4) {
			hch = ((d >> shiftCount) & 0xf) + '0';
			if (hch > '9') {
			    if (mych == 'x') {
				hch = hch - '0' - 10 + 'a';
			    } else {
				hch = hch - '0' - 10 + 'A';
			    }
			}
			if (flag || (hch != '0') || (shiftCount == 0)) {
			    flag = 1;
			    *cptr++ = hch;
			}
		    }
		    *cptr = '\0';
		    break;
		}
		case 'S' :	    /* handle DBCS string in SBCS routine */
		case 's' : {	    /* string */
		    fieldPtr = va_arg(args, char *);
		    if (fieldPtr == NULL) {
			fieldPtr = fieldBuf;
			fieldBuf[0] = '\0';
			fieldBuf[1] = '\0';  /* for 'S' */
		    }
		    break;
		}
		case 'c' : {	    /* char */
		    fieldBuf[0] = va_arg(args, char);
		    break;
		}
		case '%' : {	    /* % sign */
		    fieldBuf[0] = '%';
		    break;
		}
	        case 'f' :
	        case 'F' : {	    /* float */
		    /* 
		     * Not supported just yet, but we can skip it.
		    /* The argument size is double, unless the 'L' size
		     * modifier is used, in which case it is long double.
		     */
		    (void)va_arg(args, double);
		    /* FALL-THRU... */
		}
		default : {
		    fieldBuf[0] = 'X';
		}
	    }

	    /*
	     * Format fieldBuf:
	     * fieldWidth = width of field (or 0 for not set)
	     * leftJustify = TRUE to left justify value in field, FLASE to rj
	     * padChar = character for padding
	    */


	    /* handle DBCS string in SBCS routine */
	    padLength = fieldWidth - (mych=='S' ? strlen((TCHAR *)fieldPtr) :
		strlensbcs(fieldPtr));
	    if (!leftJustify) {
	    	while (padLength > 0) {
		    *buf++ = padChar;
		    padLength--;
	    	}
	    }

	    /* Add fieldBuf to the string */

	    /* handle DBCS string in SBCS routine */
	    if (mych == 'S') {
		while (*((TCHAR*)fieldPtr) != '\0') {
		    *buf++ = *((TCHAR *)fieldPtr)++;
		}
	    } else {
		while (*fieldPtr != '\0') {
		    *buf++ = *fieldPtr++;
		}
	    }

	    /* Take care of padding if left justifying */

	    if (leftJustify) {
	    	while (padLength > 0) {
		    *buf++ = padChar;
		    padLength--;
	    	}
	    }
	}
    }
    *buf = '\0';
    return (buf - origBuf);
}

sword
  _cdecl sprintfsbcs(
    char *		buf,		/* dest buffer */
    const char *	str,		/* control strings */
    ...)				/* args */
{
    va_list args;
    sword sw;

    va_start(args, str);
    sw = vsprintfsbcs(buf, str, args);
    va_end(args);
    return sw;
}
#endif
