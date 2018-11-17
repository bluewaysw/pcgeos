/*
	Copyright (c) 1997,1998 Eugene G. Crosser
	Copyright (c) 1998 Bruce D. Lightner (DOS/Windows support)

	You may distribute and/or use for any purpose modified or unmodified
	copies of this software if you preserve the copyright notice above.

	THIS SOFTWARE IS PROVIDED AS IS AND COME WITH NO WARRANTY OF ANY
	KIND, EITHER EXPRESSED OR IMPLIED.  IN NO EVENT WILL THE
	COPYRIGHT HOLDER BE LIABLE FOR ANY DAMAGES RESULTING FROM THE
	USE OF THIS SOFTWARE.
*/

#include "config.h"

#ifdef EPH_ERROR

#include <Ansi/string.h>
#include <stdarg.h>
#include <Ansi/stdio.h>
#include "eph_io.h"
#include "eph_priv.h"

static char *eph_errmsg[] = {
	/* 10001 */	"Data too long",
	/* 10002 */	"Timeout",
	/* 10003 */	"Unexpected amount of data read",
	/* 10004 */	"Bad packet header received",
	/* 10005 */	"Bad CRC on packet",
	/* 10006 */	"Bad speed value",
	/* 10007 */	"No memory",
	/* 10008 */	"Bad arguments",
	/* 10009 */	"",
	/* 10010 */	"",
	/* 10011 */	"",
	/* 10012 */	"",
	/* 10013 */	"",
	/* 10014 */	"",
	/* 10015 */	"",
};

char *strerror(int err) {
	static char buf[32];
	sprintf(buf,"System error %d",err);
	return buf;
}

/*
  We do not do any buffer override checks here because we are sure
  that the function is called *only* from within our library.
*/
void
eph_error (eph_iob *iob,int err,char *fmt,...)
{
	va_list ap;
	char *msg=NULL;
	char msgbuf[512];

	va_start(ap,fmt);

	if (fmt) {
		vsprintf(msgbuf,fmt,ap);
	} else {
		if ((err >= ERR_BASE) && (err < ERR_MAX)) {
			msg=eph_errmsg[err-ERR_BASE];
		} else {
			msg=strerror(err);
		}
		strcpy(msgbuf,msg);
	}
	va_end(ap);
#ifdef DEBUG
	printf("\r\n!!! %s\r\n",msgbuf);
#endif
	((pcfm_errorcb *)ProcCallFixedOrMovable_cdecl)(iob->errorcb,err,msgbuf);
}

#endif /* EPH_ERROR */
