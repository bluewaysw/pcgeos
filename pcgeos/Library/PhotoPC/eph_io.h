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

#ifndef _EPH_IO_H
#define _EPH_IO_H

#include <geos.h>
#include <photopc.h>

#define shortsleep(x) TimerSleep((x)/16667L)

#ifndef DC1
#define DC1 0x11
#endif

#define MAX_SPEED 115200

#define cbt_errorcb PPC_errorcb
#define cbt_runcb PPC_runcb

typedef void pcfm_errorcb(cbt_errorcb *,int errcode,char *errstr);
typedef void pcfm_runcb(cbt_runcb *,dword count);

typedef struct _eph_iob {
	cbt_errorcb *errorcb;
	cbt_runcb *runcb;
	int debug;
	SerialUnit fd;
        Handle driver;
	unsigned long timeout;
        word lastError;
} eph_iob;

eph_iob *eph_new(cbt_runcb *runcb,
		 cbt_errorcb *errorcb,
		 int debug);
int eph_open(eph_iob *iob,SerialPortNum devname,long speed);
int eph_close(eph_iob *iob,int newmodel);
void eph_free(eph_iob *iob);

int eph_setint(eph_iob *iob,int reg,long val);
int eph_setnullint(eph_iob *iob,int reg);
int eph_getint(eph_iob *iob,int reg,long *val);
int eph_action(eph_iob *iob,int reg,byte *val,size_t length);
int eph_setvar(eph_iob *iob,int reg,byte *val,dword length);
int eph_getvar(eph_iob *iob,int reg,byte **val,dword *length,FileHandle fh);

#define ERR_BASE		10001
#define ERR_DATA_TOO_LONG	10001
#define ERR_TIMEOUT		10002
#define ERR_BADREAD		10003
#define ERR_BADDATA		10004
#define ERR_BADCRC		10005
#define ERR_BADSPEED		10006
#define ERR_NOMEM		10007
#define ERR_BADARGS		10008
#define ERR_EXCESSIVE_RETRY	10009
#define ERR_MAX			10010

#define REG_FRAME		4
#define REG_SPEED		17
#define REG_IMG			14
#define REG_TMN			15

#endif
