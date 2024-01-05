/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  printf.c
 * FILE:	  printf.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 11, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	printf	    	    Print to stdout
 *	fprintf	    	    Print to a stream
 *	sprintf	    	    Print to a string
 *	vprintf	    	    Print varargs to stdout
 *	vfprintf    	    Workhorse -- print varargs to a stream
 *	vsprintf    	    Print varargs to a string.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/11/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Specialized implementation of printf functions to deal with
 *	identifiers.
 *
 * 	All these functions are based around a modified vfprintf written
 *	by people on the Sprite project at UC Berkeley:
 *
 *	Copyright 1988 Regents of the University of California
 *	Permission to use, copy, modify, and distribute this
 *	software and its documentation for any purpose and without
 *	fee is hereby granted, provided that the above copyright
 *	notice appear in all copies.  The University of California
 *	makes no representations about the suitability of this
 *	software for any purpose.  It is provided "as is" without
 *	express or implied warranty.
 *
 ***********************************************************************/

#ifndef lint
static char *rcsid =
"$Id: printf.c,v 1.10 93/01/13 22:38:58 josh Exp $";
#endif lint

#include <config.h>
#include <ctype.h>

#if defined(is68k) || defined(sparc)
#define sprintf sprintf_is_declared_wrong
#endif
#include <stdio.h>
#ifdef sprintf
#undef sprintf
#endif

#include <compat/string.h>
#include <stdarg.h>

#include <st.h>
#include <putc.h>
VMHandle	idfile;	    /* File containing strings to be printed by the
			     * %i formatting command.  Caller should set
			     * by calling UtilSetIDFile.
			     */
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#if defined __BORLANDC__ && !defined (_MSC_VER)
/* In BorlandC (at least under WinNT), the FILE structure is not the
   same as the Unix/MetaC one.  So here's some hacks to make it look
   more compatible.  We're still going to have to set "level" as well,
   see below...  */
#define _cnt	bsize
#define _base	buffer
#define _ptr	curp
#define _flag	flags
#define _file	fd
#define _IOSTRG (0)
#define _IOWRT	_F_WRIT

#include <limits.h>		/* for setting level to INT_MIN */

#endif /* defined __BORLANDC__ && !defined(_MSC_VER) */

#if defined (__BORLANDC__) || defined (_MSC_VER)

#include <math.h>		/* for modf() */

/* XXX: I'm too lazy to do these correctly, for now.  Feel free to
   come flame me for forgetting to implement them later. */
#define isinf(x) (0)
#define isnan(x) (0)

#endif

#if defined(_MSC_VER) || defined(__WATCOMC__)
#include <fcntl.h>
#endif /* defined _MSC_VER */

/*
 * The following defines the size of buffer needed to hold the ASCII
 * digits for the largest floating-point number and the largest integer.
 */

#define CVT_DBL_BUF_SIZE 320
#define CVT_INT_BUF_SIZE 33

/*
 *----------------------------------------------------------------------
 *
 * CvtUtoA --
 *
 *	Convert a number from internal form to a sequence of
 *	ASCII digits.
 *
 * Results:
 *	The return value is a pointer to the ASCII digits representing
 *	i, and *lengthPtr will be filled in with the number of digits
 *	stored at the location pointed to by the return value.  The
 *	return value points somewhere inside buf, but not necessarily
 *	to the beginning.  Note:  the digits are left null-terminated.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static char *
CvtUtoA(/*i, base, buf, lengthPtr) */
    register unsigned i,	/* Value to convert. */
    register int base,		/* Base for conversion.  Shouldn't be
				 * larger than 36.  2, 8, and 16
				 * execute fastest.
				 */
    register char *buf,		/* Buffer to use to hold converted string.
				 * Must hold at least CVT_INT_BUF_SIZE bytes. */
    int *lengthPtr)		/* Number of digits is stored here. */
{
    register char *p;

    /*
     * Handle a zero value specially.
     */

    if (i == 0) {
	buf[0] = '0';
	buf[1] = 0;
	*lengthPtr = 1;
	return buf;
    }

    /*
     * Build the string backwards from the end of the result array.
     */

    p = &buf[CVT_INT_BUF_SIZE-1];
    *p = 0;

    switch (base) {

	case 2:
	    while (i != 0) {
		p -= 1;
		*p = '0' + (i & 01);
		i >>= 1;
	    }
	    break;

	case 8:
	    while (i != 0) {
		p -= 1;
		*p = '0' + (i & 07);
		i >>= 3;
	    }
	    break;

	case 16:
	    while (i !=0) {
		p -= 1;
		*p = '0' + (i & 0xf);
		if (*p > '9') {
		    *p += 'a' - '9' - 1;
		}
		i >>= 4;
	    }
	    break;

	default:
	    while (i != 0) {
		p -= 1;
		*p = '0' + (i % base);
		if (*p > '9') {
		    *p += 'a' - '9' - 1;
		}
		i /= base;
	    }
	    break;
    }

    *lengthPtr = (&buf[CVT_INT_BUF_SIZE-1] - p);
    return p;
}

/*
 *----------------------------------------------------------------------
 *
 * CvtFtoA --
 *
 *	This procedure converts a double-precision floating-point
 *	number to a string of ASCII digits.
 *
 * Results:
 *	The characters at buf are modified to hold up to numDigits ASCII
 *	characters, followed by a null character.  The digits represent
 *	the most significant numDigits digits of value, with the lowest
 *	digit rounded.  The value at *pointPtr is modified to hold
 *	the number of characters in buf that precede the decimal point.
 *	A negative value of *pointPtr means zeroes must be inserted
 *	between the point and buf[0].  If value is negative, *signPtr
 *	is set to TRUE;	otherwise it is set to FALSE.  The return value
 *	is the number of digits stored in buf, which is either:
 *	(a) numDigits (if the number is so huge that all numDigits places are
 *	    used before getting to the right precision level, or if
 *	    afterPoint is -1)
 *	(b) afterPoint + *pointPtr (the normal case if afterPoint isn't -1)
 *	If there were no significant digits within the specified precision,
 *	then *pointPtr gets set to -afterPoint and 0 is returned.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
CvtFtoA(/*value, numDigits, afterPoint, pointPtr, signPtr, buf, fpError)*/
    double value,		/* Value to be converted. */
    int numDigits,		/* Maximum number of significant digits
				 * to generate in result. */
    int afterPoint,		/* Maximum number of digits to generate
				 * after the decimal point.  If -1, then
				 * there there is no limit. */
    int *pointPtr,		/* Will be filled in with position of
				 * decimal point (number of digits before
				 * decimal point). */
    int *signPtr,		/* Modified to indicate whether or not
				 * value was negative. */
    char *buf,			/* Place to store ASCII digits.  Must hold
				 * at least numDigits+1 bytes. */
    int *fpError)               /* pointer to flag that is set if the number
                                   is not a valid number. */

{
    extern double modf();
    register char *p;
    double fraction, intPart;
    int i, numDigits2;
    char tmpBuf[CVT_DBL_BUF_SIZE];
				/* Large enough to hold largest possible
				 * floating-point number.
				 */

    /*
     * Make sure the value is a valid number
     */
    if (isinf(value)) {
	/*
	 * Set the error flag so the invoking function will know
	 * that something is wrong.
	 */
	*fpError = TRUE;
	strcpy(buf, "(INFINITY)");
	return sizeof("(INFINITY)") - 1;
    }
    if (isnan(value)) {
	*fpError = TRUE;
	strcpy(buf, "(NaN)");
	return sizeof("(NaN)") - 1;
    }
    *fpError = FALSE;

    /*
     * Take care of the sign.
     */

    if (value < 0.0) {
	*signPtr = TRUE;
	value = -value;
    } else {
	*signPtr = FALSE;
    }

    /*
     * Divide value into an integer and a fractional component.  Convert
     * the integer to ASCII in a temporary buffer, then move the characters
     * to the real buffer (since we're converting from the bottom up,
     * we won't know the highest-order digit until last).
     */

    fraction = modf(value, &intPart);
    *pointPtr = 0;
    for (p = &tmpBuf[CVT_DBL_BUF_SIZE-1]; intPart != 0; p -= 1) {
	double tmp;
	char digit;

	tmp = modf(intPart/10.0, &intPart);

	digit = (char) ((tmp * 10.0) + .2);
	*p = digit + '0';
	*pointPtr += 1;
    }
    p++;
    for (i = 0; (i <= numDigits) && (p <= &tmpBuf[CVT_DBL_BUF_SIZE-1]);
	    i++, p++) {
	buf[i] = *p;
    }

    /*
     * If the value was zero, put an initial zero in the buffer
     * before the decimal point.
     */

    if (value == 0.0) {
	buf[0] = '0';
	i = 1;
	*pointPtr = 1;
    }

    /*
     * Now handle the fractional part that's left.  Repeatedly multiply
     * by 10 to get the next digit.  At the beginning, the value may be
     * very small, so do repeated multiplications until we get to a
     * significant digit.
     */

    if ((i == 0) && (fraction > 0)) {
	while (fraction < .1) {
	    fraction *= 10.0;
	    *pointPtr -= 1;
	};
    }

    /*
     * Compute how many total digits we should generate, taking into
     * account both numDigits and afterPoint.  Then generate the digits.
     */

    numDigits2 = afterPoint + *pointPtr;
    if ((afterPoint < 0) || (numDigits2 > numDigits)) {
	numDigits2 = numDigits;
    }

    for ( ; i <= numDigits2; i++) {
	double tmp;
	char digit;

	fraction = modf(fraction*10.0, &tmp);

	digit = (char) tmp;
	buf[i] = digit + '0';
    }

    /*
     * The code above actually computed one more digit than is really
     * needed.  Use it to round the low-order significant digit, if
     * necessary.  This could cause rounding to propagate all the way
     * back through the number.
     */

    if ((numDigits2 >= 0) && (buf[numDigits2] >= '5')) {
	for (i = numDigits2-1; ; i--) {
	    if (i < 0) {
		int j;

		/*
		 * Must slide the entire buffer down one slot to make
		 * room for a leading 1 in the buffer.  Careful: if we've
		 * already got numDigits digits, must drop the last one to
		 * add the 1.
		 */

		for (j = numDigits2; j > 0; j--) {
		    buf[j] = buf[j-1];
		}
		if (numDigits2 < numDigits) {
		    numDigits2++;
		}
		(*pointPtr)++;
		buf[0] = '1';
		break;
	    }

	    buf[i] += 1;
	    if (buf[i] <= '9') {
		break;
	    }
	    buf[i] = '0';
	}
    }

    if (numDigits2 <= 0) {
	numDigits2 = 0;
	*pointPtr = -afterPoint;
    }
    buf[numDigits2] = 0;
    return numDigits2;
}

/*
 * The table below is used to convert from ASCII digits to a
 * numerical equivalent.  It maps from '0' through 'z' to integers
 * (100 for non-digit characters).
 */

static const char cvtIn[] = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9,		/* '0' - '9' */
    100, 100, 100, 100, 100, 100, 100,		/* punctuation */
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,	/* 'A' - 'Z' */
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35,
    100, 100, 100, 100, 100, 100,		/* punctuation */
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,	/* 'a' - 'z' */
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35};

#if defined _MSC_VER
unsigned long strtoul( const char *nptr, char **endptr, int base );
#else
/*
 *----------------------------------------------------------------------
 *
 * strtoul --
 *
 *	Convert an ASCII string into an integer.
 *
 * Results:
 *	The return value is the integer equivalent of string.  If endPtr
 *	is non-NULL, then *endPtr is filled in with the character
 *	after the last one that was part of the integer.  If string
 *	doesn't contain a valid integer value, then zero is returned
 *	and *endPtr is set to string.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

unsigned long int
strtoul(string, endPtr, base)
    char *string;		/* String of ASCII digits, possibly
				 * preceded by white space.  For bases
				 * greater than 10, either lower- or
				 * upper-case digits may be used.
				 */
    char **endPtr;		/* Where to store address of terminating
				 * character, or NULL. */
    int base;			/* Base for conversion.  Must be less
				 * than 37.  If 0, then the base is chosen
				 * from the leading characters of string:
				 * "0x" means hex, "0" means octal, anything
				 * else means decimal.
				 */
{
    register char *p;
    register unsigned long int result = 0;
    register unsigned digit;
    int anyDigits = FALSE;

    /*
     * Skip any leading blanks.
     */

    p = string;
    while (isspace(*p)) {
	p += 1;
    }

    /*
     * If no base was provided, pick one from the leading characters
     * of the string.
     */

    if (base == 0)
    {
	if (*p == '0') {
	    p += 1;
	    if (*p == 'x') {
		p += 1;
		base = 16;
	    } else {

		/*
		 * Must set anyDigits here, otherwise "0" produces a
		 * "no digits" error.
		 */

		anyDigits = TRUE;
		base = 8;
	    }
	}
	else base = 10;
    } else if (base == 16) {

	/*
	 * Skip a leading "0x" from hex numbers.
	 */

	if ((p[0] == '0') && (p[1] == 'x')) {
	    p += 2;
	}
    }

    /*
     * Sorry this code is so messy, but speed seems important.  Do
     * different things for base 8, 10, 16, and other.
     */

    if (base == 8) {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > 7) {
		break;
	    }
	    result = (result << 3) + digit;
	    anyDigits = TRUE;
	}
    } else if (base == 10) {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > 9) {
		break;
	    }
	    result = (10*result) + digit;
	    anyDigits = TRUE;
	}
    } else if (base == 16) {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > ('z' - '0')) {
		break;
	    }
	    digit = cvtIn[digit];
	    if (digit > 15) {
		break;
	    }
	    result = (result << 4) + digit;
	    anyDigits = TRUE;
	}
    } else {
	for ( ; ; p += 1) {
	    digit = *p - '0';
	    if (digit > ('z' - '0')) {
		break;
	    }
	    digit = cvtIn[digit];
	    if (digit >= (unsigned) base) {
		break;
	    }
	    result = result*base + digit;
	    anyDigits = TRUE;
	}
    }

    /*
     * See if there were any digits at all.
     */

    if (!anyDigits) {
	p = string;
    }

    if (endPtr != NULL) {
	*endPtr = p;
    }

    return result;
}
#endif /* defined _MSC_VER */

/*
 *----------------------------------------------------------------------
 *
 * vfprintf --
 *
 *	This utility routine does all of the real work of printing
 *	formatted information.  It is called by printf, fprintf,
 *	sprintf, vprintf, and vsprintf.
 *
 * Results:
 *	The return value is the total number of characters printed.
 *
 * Side effects:
 *	Information is output on stream.  See the manual page entry
 *	for printf for details.
 *
 *----------------------------------------------------------------------
 */
 #define i_putc(c, strm)	\
 		if(isstrm) { \
 			putc(c, strm); \
 		} \
 		else { \
 			(**((char**)strm)) = c; \
 			(*((char**)strm))++; \
 		}

int
i_vfprintf(FILE *stream,		/* Where to output formatted results. */
         const char *format,	/* Contains literal text and format control
				 * sequences indicating how args are to be
				 * printed.  See the man page for details. */
	 va_list args,		/* Variable number of values to be formatted
				 * and printed. */
	 int isstrm) /* TRUE if the stream paramater is actually a
										 pointer to a buffer pointer */
{
    int leftAdjust;		/* TRUE means field should be left-adjusted*/
    int minWidth;		/* Minimum width of field. */
    int precision;		/* Precision for field (e.g. digits after
				 * decimal, or string length). */
    int altForm;		/* TRUE means value should be converted to
				 * an alternate form (depends on type of
				 * conversion). */
    register char c;		/* Current character from format string.
				 * Eventually it ends up holding the format
				 * type (e.g. 'd' for decimal). */
    char pad;			/* Pad character. */
    char buf[CVT_DBL_BUF_SIZE+10];
				/* Buffer used to hold converted numbers
				 * before outputting to stream.  Must be
				 * large enough for floating-point number
				 * plus sign plus "E+XXX + null" */
    char expBuf[CVT_INT_BUF_SIZE];
				/* Buffer to use for converting exponents. */
    char *prefix;		/* Holds non-numeric stuff that precedes
				 * number, such as "-" or "0x".  This is
				 * kept separate to be sure we add padding
				 * zeroes AFTER the prefix. */
    register char *field;	/* Pointer to converted field. */
    int actualLength;		/* Actual length of converted field. */
    int point;			/* Location of decimal point, for "f" and
				 * "e" conversions. */
    int sign;			/* Also used for "f" and "e" conversions. */
    int i, tmp;
    int charsPrinted = 0;	/* Total number of characters output. */
    char *end;
    int fpError = FALSE;
    ID	    	    id;	    	/* Identifier for %i */

    /*
     * The main loop is to scan through the characters in format.
     * Anything but a '%' is output directly to stream.  A '%'
     * signals the start of a format field;  the formatting information
     * is parsed, the next value from args is formatted and printed,
     * and the loop goes on.
     */

    for (c = *format; c != 0; format++, c = *format) {

	if (c != '%') {
#if !defined(unix) && !defined(_LINUX)
	    /*
	     * For dos, put out a carriage return before any newline,
	     * but only if the stream is in binary mode, otherwise it happens
	     * automatically.
	     */
#if defined(__HIGHC__) || defined(_MSC_VER) || defined(__WATCOMC__)
	    if (isstrm && (c == '\n') && (stream->_flag & _O_BINARY)) {
#else
	    if (isstrm && (c == '\n') && (stream->flags & _F_BIN)) {
#endif
		i_putc('\r', stream);
	    }
#endif
	    i_putc(c, stream);
	    charsPrinted += 1;
	    continue;
	}

	/*
	 * Parse off the format control fields.
	 */

	leftAdjust	= FALSE;
	pad		= ' ';
	minWidth	= 0;
	precision	= -1;
	altForm		= FALSE;
	prefix		= "";
	actualLength = 0;

	format++;
	c = *format;
	while (TRUE) {
	    if (c == '-') {
		leftAdjust = TRUE;
	    } else if (c == '0') {
		pad = '0';
	    } else if (c == '#') {
		altForm = TRUE;
	    } else if (c == '+') {
		prefix = "+";
		actualLength = 1;
	    } else {
		break;
	    }
	    format++;
	    c = *format;
	}
	if (isdigit(c)) {
	    minWidth = strtoul((char*) format, &end, 10);
	    format = end;
	    c = *format;
	} else if (c == '*') {
	    minWidth = va_arg(args, int);
	    format++;
	    c = *format;
	}
	if (c == '.') {
	    format++;
	    c = *format;
	}
	if (isdigit(c)) {
	    precision = strtoul((char*) format, &end, 10);
	    format = end;
	    c = *format;
	} else if (c == '*') {
	    precision = va_arg(args, int);
	    format++;
	    c = *format;
	}
	if (c == 'l') {			/* Ignored for compatibility. */
	    format++;
	    c = *format;
	}

	/*
	 * Take action based on the format type (which is now in c).
	 */

	field = buf;
	switch (c) {

	    case 'D':
	    case 'd':
		i = va_arg(args, int);
		if (i < 0) {
		    prefix = "-";
		    i = -i;
		    actualLength = 1;
		}
		field = CvtUtoA((unsigned) i, 10, buf, &tmp);
		actualLength += tmp;
		break;

	    case 'O':
	    case 'o':
		i = va_arg(args, int);
		if (altForm && (i != 0)) {
		    prefix = "0";
		    actualLength = 1;
		}
		field = CvtUtoA((unsigned) i, 8, buf, &tmp);
		actualLength += tmp;
		break;

	    case 'X':
	    case 'x':
		i = va_arg(args, int);
		field = CvtUtoA((unsigned) i, 16, buf, &actualLength);
		if (altForm) {
		    char *p;
		    if (c == 'X') {
			if (i != 0) {
			    prefix = "0X";
			    actualLength += 2;
			}
			for (p = field; *p != 0; p++) {
			    if (*p >= 'a') {
				*p += 'A' - 'a';
			    }
			}
		    } else if (i != 0) {
			prefix = "0x";
			actualLength += 2;
		    }
		} else if (c == 'X') {
		    char    *p;
		    for (p = field; *p != 0; p++) {
			if (*p >= 'a') {
			    *p += 'A' - 'a';
			}
		    }
		}
		break;

	    case 'U':
	    case 'u':
		field = CvtUtoA(va_arg(args, unsigned), 10, buf,
			&actualLength);
		break;

	    case 'i':
		/*
		 * Identifier: similar to %s, but need to lock down the
		 * string.
		 */
		id = va_arg(args, ID);

		if (id == NullID) {
		    field = "(null)";
		} else {
		    field = ST_Lock(idfile, id);
		}
		actualLength = strlen(field);
		/* Lie about length if precision smaller than actual length */
		if ((precision >= 0) && (precision < actualLength)) {
		    actualLength = precision;
		}
		/* Pad field with spaces */
		pad = ' ';
		break;
	    case 's':
		field = va_arg(args, char *);
		if (field == (char *) NULL) {
		    field = "(NULL)";
		}
		actualLength = strlen(field);
		if ((precision >= 0) && (precision < actualLength)) {
		    actualLength = precision;
		}
		pad = ' ';
		break;

	    case 'c':
		buf[0] = va_arg(args, int);
		actualLength = 1;
		pad = ' ';
		break;

	    case 'F':
	    case 'f':
		if (precision < 0) {
		    precision = 6;
		} else if (precision > CVT_DBL_BUF_SIZE) {
		    precision = CVT_DBL_BUF_SIZE;
		}

		/*
		 * Just generate the digits and compute the total length
		 * here.  The rest of the work will be done when the
		 * characters are actually output, below.
		 */
		actualLength = CvtFtoA(va_arg(args, double), CVT_DBL_BUF_SIZE,
		    precision, &point, &sign, field, &fpError);
		if (fpError) {
		    break;
		}
		if (point <= 0) {
		    actualLength += 1 - point;
		}
		if ((precision != 0) || (altForm)) {
		    actualLength += 1;
		}
		if (sign) {
		    prefix = "-";
		    actualLength += 1;
		}
		c = 'f';
		break;

	    case 'E':
	    case 'e':
		if (precision < 0) {
		    precision = 6;
		} else if (precision > CVT_DBL_BUF_SIZE-1) {
		    precision = CVT_DBL_BUF_SIZE-1;
		}
		actualLength = CvtFtoA(va_arg(args, double), precision+1, -1,
			&point, &sign, &buf[1], &fpError);
		if (fpError) {
		    break;
		}
		eFromG:

		/*
		 * Insert a decimal point after the first digit of the number.
		 * If no digits after decimal point, then don't print decimal
		 * unless in altForm.
		 */

		buf[0] = buf[1];
		buf[1] = '.';
		if ((precision != 0) || (altForm)) {
		    field = buf + precision + 2;
		} else {
		    field = &buf[1];
		}

		/*
		 * Convert the exponent.
		 */

		*field = c;
	    	field++;
		point--;	/* One digit before decimal point. */
		if (point < 0) {
		    *field = '-';
		    point = -point;
		} else {
		    *field = '+';
		}
		field++;
		if (point < 10) {
		    *field = '0';
		    field++;
		}
		strcpy(field, CvtUtoA((unsigned) point, 10, expBuf, &i));
		actualLength = (field - buf) + i;
		field = buf;
		if (sign) {
		    prefix = "-";
		    actualLength += 1;
		}
		break;

	    case 'G':
	    case 'g': {
		int eLength, fLength;

		if (precision < 0) {
		    precision = 6;
		} else if (precision > CVT_DBL_BUF_SIZE-1) {
		    precision = CVT_DBL_BUF_SIZE-1;
		} else if (precision == 0) {
		    precision = 1;
		}

		actualLength = CvtFtoA(va_arg(args, double), precision,
			-1, &point, &sign, &buf[1], &fpError);

		if (fpError) {
		    break;
		}
		if (!altForm) {
		    for ( ; actualLength > 1; actualLength--) {
			if (buf[actualLength] != '0') {
			    break;
			}
		    }
		}
		if ((actualLength > 1) || altForm) {
		    eLength = actualLength + 5;
		} else {
		    eLength = actualLength + 4;
		}
		if (point <= 0) {
		    fLength = actualLength + 2 - point;
		} else {
		    fLength = actualLength;
		    if (point < actualLength) {
			fLength += 1;
		    } else if (altForm) {
			fLength = point + 1;
		    } else {
			fLength = point;
		    }
		}

		/*
		 * Use "e" format if it results in fewer digits than "f"
		 * format, or if it would result in non-significant zeroes
		 * being printed.  Remember that precision means something
		 * different in "e" and "f" (digits after decimal) than it
		 * does in "g" (significant digits).
		 */

		if ((eLength < fLength) || (point > precision)) {
		    c += 'E' - 'G';
		    precision = actualLength-1;
		    goto eFromG;
		}
		c = 'f';
		field = &buf[1];
		actualLength = fLength;
		if (sign) {
		    prefix = "-";
		    actualLength += 1;
		}
		break;
	    }

	    case '%':
		i_putc('%', stream);
		charsPrinted += 1;
		goto endOfField;

	    case 0:
		return charsPrinted;

	    default:
		i_putc(c, stream);
		charsPrinted += 1;
		goto endOfField;
	}

	/* Handle pad characters on the left.  If the pad is '0', then
	 * padding goes after the prefix.  Otherwise, padding goes before
	 * the prefix.
	 */

	if (!leftAdjust) {
	    if (pad == '0') {
		for ( ; *prefix != 0; prefix++) {
		    i_putc(*prefix, stream);
		    charsPrinted += 1;
		    actualLength--;
		    minWidth--;
		}
	    }
	    while (minWidth > actualLength) {
		i_putc(pad, stream);
		charsPrinted += 1;
		minWidth --;
	    }
	}

	/*
	 * Output anything left in the prefix.
	 */

	minWidth -= actualLength;
	for ( ; *prefix != 0; prefix++) {
	    i_putc(*prefix, stream);
	    charsPrinted += 1;
	    actualLength--;
	}

	/*
	 * "F" and "f" formats are handled specially here:  output
	 * everything up to and including the decimal point.
	 */

	if (c == 'f' && !fpError) {
	    if (point <= 0) {
		if (actualLength > 0) {
		    i_putc('0', stream);
		    charsPrinted += 1;
		    point++;
		    actualLength--;
		}
		if (actualLength > 0) {
		    charsPrinted += 1;
		    i_putc('.', stream);
		    actualLength--;
		}
		while ((point <= 0) && (actualLength > 0)) {
		    i_putc('0', stream);
		    charsPrinted += 1;
		    point++;
		    actualLength--;
		}
	    } else {
		while ((point > 0) && (actualLength > 0)) {
		    i_putc(*field, stream);
		    charsPrinted += 1;
		    field++;
		    point--;
		    actualLength--;
		}
		if (actualLength > 0) {
		    i_putc('.', stream);
		    charsPrinted += 1;
		    actualLength--;
		}
	    }
	}

	/*
	 * Output the contents of the field (for "f" format, this is
	 * just the stuff after the decimal point).
	 */

	charsPrinted += actualLength;
	for ( ; actualLength > 0; actualLength--, field++) {
	    i_putc(*field, stream);
        }

	/*
	 * Pad the right of the field, if necessary.
	 */

	while (minWidth > 0) {
	    i_putc(' ', stream);
	    charsPrinted += 1;
	    minWidth --;
	}

	/*
	 * Unlock the identifier, if %i
	 */
	if (c == 'i' && id != NullID) {
	    ST_Unlock(idfile, id);
	}

	endOfField: continue;
    }
    return charsPrinted;
}

int
vfprintf(FILE *stream,		/* Where to output formatted results. */
				 const char *format,	/* Contains literal text and format control
				* sequences indicating how args are to be
				* printed.  See the man page for details. */
	va_list args)		/* Variable number of values to be formatted
				* and printed. */
{
 	return i_vfprintf(stream, format, args, TRUE);
}


/******************************************************************************
 *
 *		ALL THE OTHER PRINTF-RELATED FUNCTIONS
 *
 *****************************************************************************/


/***********************************************************************
 *				vprintf
 ***********************************************************************
 * SYNOPSIS:  	    Formatted output to stdout, given a varargs list
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Number of characters placed in stdout.
 * SIDE EFFECTS:    Characters placed in stdout...of course
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/11/89		Initial Revision
 *
 ***********************************************************************/
int
vprintf(const char *fmt, va_list args)
{
    return(vfprintf(stdout, fmt, args));
}

/***********************************************************************
 *				vsprintf
 ***********************************************************************
 * SYNOPSIS:	    Formatted output to a string, given a varargs list
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Number of characters placed in string (not including null)
 * SIDE EFFECTS:    Characters are placed in the string
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/11/89		Initial Revision
 *
 ***********************************************************************/
int
vsprintf(char	*str, const char *fmt, va_list args)
{
		int res;
		char* strPtr = str;

    res = i_vfprintf((FILE*) &strPtr, fmt, args, FALSE);

		(*strPtr) = '\0';

    return(res);
}

/***********************************************************************
 *				printf
 ***********************************************************************
 * SYNOPSIS:	    Formatted output to stdout...
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Number of chars printed
 * SIDE EFFECTS:    Characters sent to stdout
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/11/89		Initial Revision
 *
 ***********************************************************************/
int
printf(const char *fmt, ...)
{
    va_list	args;
    int	    	res;

    va_start(args, fmt);

    res = vfprintf(stdout, fmt, args);

    va_end(args);

    return(res);
}



/***********************************************************************
 *				fprintf
 ***********************************************************************
 * SYNOPSIS:	    Formatted output to a stream
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Number of chars printed
 * SIDE EFFECTS:    Characters sent to stream
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/11/89		Initial Revision
 *
 ***********************************************************************/
int
fprintf(FILE *stream, const char *fmt, ...)
{
    va_list	args;
    int	    	res;

    va_start(args, fmt);

    res = vfprintf(stream, fmt, args);

    va_end(args);

    return(res);
}


/***********************************************************************
 *				sprintf
 ***********************************************************************
 * SYNOPSIS:	    Formatted output to a string
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Number of chars in string
 * SIDE EFFECTS:    Characters written into string (not including null)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/11/89		Initial Revision
 *
 ***********************************************************************/
int
sprintf(char	*str, const char *fmt, ...)
{
    va_list 	args;	    /* List of passed args */
    int	    	res;	    /* Result of vfprintf */
		char* 		strPtr = str;

    va_start(args, fmt);

    res = i_vfprintf((FILE*)&strPtr, fmt, args, FALSE);

		(*strPtr) = '\0';

    va_end(args);

    return(res);
}


void UtilSetIDFile(VMHandle file) {
    idfile = file;
}

VMHandle UtilGetIDFile(void) {
    return idfile;
}
