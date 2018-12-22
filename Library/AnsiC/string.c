/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * MODULE:	AnsiC
 * FILE:	string.c
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file implements the following string.h routines:
 *		strrev
 *
 *	$Id: string.c,v 1.1 97/04/04 17:42:20 newdeal Exp $
 *
 ***********************************************************************/

#include <geos.h>
#include <object.h>
#include <Ansi/string.h>
#include <geoMisc.h>

/***/

#ifdef __HIGHC__
#pragma Code("MAINCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg MAINCODE
#endif

int _pascal
  ATOI(const TCHAR *__s)
{
    int i, n=0;

    for (i=0; __s[i] >= _TEXT('0') && __s[i] <= _TEXT('9'); ++i)
	n = 10 * n + (__s[i] - _TEXT('0'));


    return  n;
}


void _pascal
  ITOA(int __n, TCHAR *__s)
{
    int	i, sign;

    if ((sign = __n) < 0)
	__n = -__n;

    i = 0;

    do {
	__s[i++] = __n % 10 + _TEXT('0');
    } while ((__n /= 10) > 0);
    
    if (sign < 0)
	__s[i++] = _TEXT('-');

    __s[i] = _TEXT('\0');
    strrev(__s);
}

void _pascal
  STRREV(TCHAR *__s)
{
    int	c, i, j;

    for (i=0, j = strlen(__s)-1; i<j; i++, j--)
    {
	c = __s[i];
	__s[i] = __s[j];
	__s[j] = c;
    }
}

/*
 * For DBCS, SBCS versions
 */
#ifdef DO_DBCS

#pragma codeseg STRINGCODESBCS

int _pascal
  atoisbcs(const char *__s)
{
    int i, n=0;

    for (i=0; __s[i] >= '0' && __s[i] <= '9'; ++i)
	n = 10 * n + (__s[i] - '0');


    return  n;
}


void _pascal
  ITOASBCS(int __n, TCHAR *__s)
{
    int	i, sign;

    if ((sign = __n) < 0)
	__n = -__n;

    i = 0;

    do {
	__s[i++] = __n % 10 + '0';
    } while ((__n /= 10) > 0);
    
    if (sign < 0)
	__s[i++] = '-';

    __s[i] = '\0';
    strrev(__s);
}

void _pascal
  STRREVSBCS(char *__s)
{
    int	c, i, j;

    for (i=0, j = strlensbcs(__s)-1; i<j; i++, j--)
    {
	c = __s[i];
	__s[i] = __s[j];
	__s[j] = c;
    }
}

#endif





