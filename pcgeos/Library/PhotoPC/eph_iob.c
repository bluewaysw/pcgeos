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
#include <Ansi/stdlib.h>
#include <Ansi/string.h>
#include <Ansi/stdio.h>
#include "eph_io.h"

static void
deferrorcb(int errcode,char *errstr)
{
#ifdef DEBUG
	printf("Error %d: %s\r",errcode,errstr);
#endif
}

static void
defruncb(dword count)
{
	return;
}

 /***********************************************************************
 *
 * FUNCTION:	eph_new
 *
 * CALLED BY:	PPCOpen
 *
 * STRATEGY:	Create a new eph_iob structure in memory
 *		         Return that structure
 *
 ***********************************************************************/
eph_iob *
eph_new(cbt_runcb *runcb, cbt_errorcb *errorcb, int debug)
{
 eph_iob *iob;

	/* allocate the memory */
	iob = (eph_iob *)malloc(sizeof(eph_iob));
	if (!iob) return iob;

	/* fill in the eph_iob information */
	if (errorcb) iob->errorcb = errorcb;
	else iob->errorcb = deferrorcb;

	if (runcb) iob->runcb = runcb;
	else iob->runcb = defruncb;

	iob->debug = debug;
	iob->driver = NullHandle;
	/* SerialUnit is a typedef of SerialPortNum defined in cinclude\serialDr.h.
		On the GPC this is SERIAL_COM1 which = 0 */
	iob->fd = (SerialUnit) - 1;
	iob->lastError = 0;

	return iob;
}

void
eph_free(eph_iob *iob)
{
	free(iob);
}
