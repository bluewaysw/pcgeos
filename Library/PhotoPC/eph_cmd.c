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
#include "eph_io.h"
#include "eph_priv.h"

#define TMPBUF_SIZE (2048)

#define MAYRETRY(rc) ((rc == -2) || (rc == NAK))

 /***********************************************************************
 *
 * FUNCTION:	eph_writecmd
 *
 * CALLED BY:	several
 *
 * STRATEGY:   writes the passed buffer
 *
 *
 *
 ***********************************************************************/
int eph_writecmd(eph_iob *iob, byte *data, size_t length)
{
	return eph_writepkt(iob, PKT_CMD, SEQ_CMD, data, length);

}

 /***********************************************************************
 *
 * FUNCTION:	eph_writeicmd
 *
 * CALLED BY:	eph_setispeed
 *
 * STRATEGY:   writes the passed buffer
 *
 *
 *
 ***********************************************************************/
int eph_writeicmd(eph_iob *iob, byte *data, size_t length)
{
	return eph_writepkt(iob, PKT_CMD, SEQ_INITCMD, data, length);

}

 /***********************************************************************
 *
 * FUNCTION:	eph_setispeed
 *
 * CALLED BY:	eph_open, eph_close
 *
 * STRATEGY:   sets the camera xfer speed (1 - 5)
 *             Returns rc
 *
 *
 ***********************************************************************/
int
eph_setispeed(eph_iob *iob, long val)
{
 byte buf[6];
 int rc;
 int count=0;


	/* set up the send buffer */
	buf[0]=CMD_SETINT;
	buf[1]=REG_SPEED;
	buf[2]=(val) & 0xff;
	buf[3]=(val>>8) & 0xff;
	buf[4]=(val>>16) & 0xff;
	buf[5]=(val>>24) & 0xff;

	/* send the xfer speed command */
	do {
		if ((rc = eph_writeicmd(iob, buf, 6)) != 0)
			/* bad write */
			return rc;
		rc = eph_waitack(iob, ACKTIMEOUT*4);
	} while (rc && (count++ < RETRIES));
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob, ERR_EXCESSIVE_RETRY, "excessive retries on setispeed");
#endif
	return rc;

}

 /***********************************************************************
 *
 * FUNCTION:	eph_setint(eph_iob *iob, int reg, long val)
 *
 * CALLED BY:  several
 *
 * STRATEGY:   sets the value of the passed in camera "reg"ister to val
 *             and waits for the camrera's ACK
 *					returns FALSE on success
 *
 *
 ***********************************************************************/
int eph_setint(eph_iob *iob, int reg, long val)
{
 byte		buf[6];
 int		rc;
 int		count = 0;


	buf[0] = CMD_SETINT;
	buf[1] = reg;
	buf[2] = (val) & 0xff;
	buf[3] = (val>>8) & 0xff;
	buf[4] = (val>>16) & 0xff;
	buf[5] = (val>>24) & 0xff;

writeagain:
	if ((rc = eph_writecmd(iob, buf, 6)) != 0) return rc;
	rc = eph_waitack(iob, (reg == REG_FRAME) ? BIGACKTIMEOUT : ACKTIMEOUT);
	if (MAYRETRY(rc) && (count++ < RETRIES)) goto writeagain;
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob,ERR_EXCESSIVE_RETRY, "excessive retries on setint");
#endif
	return rc;

}

 /***********************************************************************
 *
 * FUNCTION:	eph_setnullint(eph_iob *iob, int reg)
 *
 * CALLED BY:  several
 *
 * STRATEGY:   sets the value of the passed in camera "reg"ister to 0
 *             and waits for the camrera's ACK
 *					returns FALSE on success
 *
 *
 ***********************************************************************/
int eph_setnullint(eph_iob *iob, int reg)
{
 byte		buf[2];
 int		rc;
 int		count = 0;


	buf[0] = CMD_SETINT;
	buf[1] = reg;

writeagain:
	if ((rc = eph_writecmd(iob, buf, 2)) != 0) return rc;

	rc = eph_waitack(iob, (reg == REG_FRAME) ? BIGACKTIMEOUT : ACKTIMEOUT);
	if (MAYRETRY(rc) && (count++ < RETRIES)) goto writeagain;
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob, ERR_EXCESSIVE_RETRY, "excessive retries on setnullint");
#endif
	return rc;

}

 /***********************************************************************
 *
 * FUNCTION:	eph_getint(eph_iob *iob, int reg, long *val)
 *
 * CALLED BY:  several
 *
 * STRATEGY:   reads the value of the passed in camera "reg"ister
 *             enters the camera's reply in the passed in val variable
 *					returns FALSE on success
 *
 *
 ***********************************************************************/
int eph_getint(eph_iob *iob, int reg, long *val)
{
 byte			buf[4];
 eph_pkthdr	pkt;
 int			rc;
 size_t		size = 4;
 int			count = 0;


	(*val) = 0L;
	buf[0] = CMD_GETINT;
	buf[1] = reg;

writeagain:
	rc = eph_writecmd(iob, buf, 2);
	if (rc != 0) return rc;

readagain:
	rc = eph_readpkt(iob, &pkt, buf, &size, BIGDATATIMEOUT);
	if (MAYRETRY(rc) && (count++ < RETRIES)) goto writeagain;
	if ((rc == 0) && (pkt.typ == PKT_LAST) && (pkt.seq == 0)) {
		/* OK we got a goot response from the camera */
		/* stuff the val that was passed in */
		(*val)=((unsigned long)buf[0]) | ((unsigned long)buf[1]<<8) |
			((unsigned long)buf[2]<<16) | ((unsigned long)buf[3]<<24);
		/* tell the camera we're happy */
		eph_writeack(iob);
		return 0;
		}
	else if ((rc == -1) && (count++ < RETRIES)) {
		/* bad read - tell the camera and try again */
		eph_writenak(iob);
		goto readagain;
		}
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob,ERR_EXCESSIVE_RETRY,
				"excessive retries on getint");
#endif
	return rc;
}

int
eph_action(eph_iob *iob,int reg,byte *val,size_t length)
{
	byte buf[3];
	int rc;
	int count=0;

	if (length > (sizeof(buf) - 2)) {
#ifdef EPH_ERROR
		eph_error(iob,ERR_DATA_TOO_LONG,"arg action length %ld",
				(long)length);
#endif
		return -1;
	}

	buf[0]=CMD_ACTION;
	buf[1]=reg;
	memcpy(buf+2,val,length);

writeagain:
	if ((rc=eph_writecmd(iob,buf,length+2))!=0) return rc;
	rc=eph_waitack(iob,ACKTIMEOUT);

	if (MAYRETRY(rc) && (count++ < RETRIES)) goto writeagain;

	if (rc == 0) rc=eph_waitcomplete(iob);
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob,ERR_EXCESSIVE_RETRY,
				"excessive retries on action");
#endif
	return rc;
}

#if 0 /* Nothing sets a variable register */
int
eph_setvar(eph_iob *iob,int reg,byte *val,dword length)
{
	byte buf[MAXPATH+2];
	int rc=0,seq=-1;
	int count=0;
	int pkttyp,pktseq;
	size_t pktsize,maywrite;
	dword written=0;
	byte *getpoint,*putpoint;

	getpoint=val;
	while (length && !rc) {
		if (seq == -1) {
			pkttyp=PKT_CMD;
			pktseq=SEQ_CMD;
			buf[0]=CMD_SETVAR;
			buf[1]=reg;
			putpoint=buf+2;
			maywrite=sizeof(buf)-2;
			pktsize=2;
		} else {
			pkttyp=PKT_DATA;
			pktseq=seq;
			putpoint=buf;
			maywrite=sizeof(buf);
			pktsize=0;
			((pcfm_runcb *)ProcCallFixedOrMovable_cdecl)(
			    iob->runcb,written);
		}
		if (length <= maywrite) {
			maywrite=length;
			if (pkttyp == PKT_DATA) pkttyp=PKT_LAST;
		}
		memcpy(putpoint,getpoint,maywrite);
		pktsize+=maywrite;
		length-=maywrite;
		getpoint+=maywrite;
		written+=maywrite;
		seq++;
writeagain:
		if ((rc=eph_writepkt(iob,pkttyp,pktseq,buf,pktsize)))
			return rc;
		rc=eph_waitack(iob,ACKTIMEOUT);
		if (MAYRETRY(rc) && (count++ < RETRIES)) goto writeagain;
	}
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob,ERR_EXCESSIVE_RETRY,
				"excessive retries on setvar");
#endif
	return rc;
}
#endif

 /***********************************************************************
 *
 * FUNCTION:	eph_getvar(byte *data, size_t len, FileHandle fh)
 *
 * CALLED BY:  eph_getvar
 *
 * STRATEGY:   writes the image buffer to the file
 *
 *					returns FALSE on success
 *
 *
 ***********************************************************************/
int storing(byte *data, size_t len, FileHandle fh)
{

	if (FileWrite((FileHandle)fh, data, len, FALSE) != len)
		return -1;
	else return 0;

}

 /***********************************************************************
 *
 * FUNCTION:	eph_getvar(eph_iob *iob, int reg, byte **buffer, dword *bufsize,
 *									FileHandle fh)
 *
 * CALLED BY:  PPCGetFile
 *
 * STRATEGY:   reads the data of the passed in camera "reg"ister
 *
 *					returns FALSE on success
 *
 *
 ***********************************************************************/
int eph_getvar(eph_iob *iob, int reg, byte **buffer, dword *bufsize,
					FileHandle fh)
{
 byte			buf[2];
 eph_pkthdr	pkt;
 int			rc;
 int			count = 0;
 byte			expect = 0;
 dword		index;
 size_t		readsize;
 byte			*ptr;
 byte			*tmpbuf = NULL;
 size_t		tmpbufsize = 0;


	/* make sure we have a buffer or a file handle */
	if ((buffer == NULL) && (fh == NullHandle)) {
#ifdef EPH_ERROR
		eph_error(iob, ERR_BADARGS, "NULL buffer and FileHandle for getvar");
#endif
		return -1;
		}

	/* alloc a temp buffer if none was passed in */
	if (buffer == NULL) {
		tmpbuf = realloc(NULL, (size_t)TMPBUF_SIZE);
		tmpbufsize = TMPBUF_SIZE;
		if (tmpbuf == NULL) {
#ifdef EPH_ERROR
			eph_error(iob,ERR_NOMEM, "could not alloc %lu for tmpbuf in getvar",
				(long)TMPBUF_SIZE);
#endif
			return -1;
			}
		}

	/* set up buffer */
	buf[0] = CMD_GETVAR;
	buf[1] = reg;

writeagain:
	if ((rc = eph_writecmd(iob, buf, 2)) != 0) return rc;
	index=0;

readagain:
	if (buffer) { /* read to memory reallocating it */
		/* PicAlbum doesn't use a buffer - always goes to file */
		if (((*bufsize) - index) < 2048) {
#ifdef DEBUG
			if (iob->debug)
				printf("reallocing %lu",(unsigned long)(*bufsize));
#endif
			/* small memory! round up to next 2048 boundary */
			(*bufsize)=(((index + 2048)-1)/2048L+1)*2048L;
#ifdef DEBUG
			if (iob->debug)
				printf(" -> %lu\r\n",(unsigned long)(*bufsize));
#endif
			(*buffer)=realloc(*buffer,*bufsize);
			if ((*buffer) == NULL) {
#ifdef EPH_ERROR
				eph_error(iob,ERR_NOMEM,
					"could not realloc %lu for getvar",
					(long)*bufsize);
#endif
				return -1;
				}
			}
		ptr=(*buffer)+index;
		readsize=(*bufsize)-index;
		} /* end of passed in buffer if */
	else { /* pass data to store callback */
		ptr = tmpbuf;
		readsize = tmpbufsize;
		}

	/* let's start reading ... */
	rc = eph_readpkt(iob, &pkt, ptr, &readsize,
			(expect || ((reg != REG_IMG) || (reg != REG_TMN)))?
						DATATIMEOUT:BIGDATATIMEOUT);
	if (MAYRETRY(rc) && (expect == 0) && (count++ < RETRIES)) {
		eph_writenak(iob);
		if (rc == -2) goto readagain;
		else goto writeagain;
		}
	if ((rc == 0) && ((pkt.seq == expect) || (pkt.seq  == (expect-1)))) {
		count=0;
		if (pkt.seq == expect) {
			index += readsize;
			expect++;
			((pcfm_runcb *)ProcCallFixedOrMovable_cdecl)(iob->runcb, index);
			if (buffer == NULL) {
#ifdef DEBUG
				if (iob->debug)
					printf("storing %lu at %08lx\r\n",
						(unsigned long)readsize,
						(unsigned long)ptr);
#endif
				if (storing(ptr, readsize, fh))
				        return -1;
				}
			}
		eph_writeack(iob);
		if (pkt.typ == PKT_LAST) {
			/* and we're done! */
			if (buffer) (*bufsize)=index;
			if (tmpbuf) free(tmpbuf);
			return 0;
			}
		else goto readagain;
		}

	if ((rc <= 0) && (count++ < RETRIES)) {
		eph_writenak(iob);
		goto readagain;
		}

	if (tmpbuf) free(tmpbuf);
#ifdef EPH_ERROR
	if (count >= RETRIES)
		eph_error(iob,ERR_EXCESSIVE_RETRY, "excessive retries on getvar");
#endif
	return rc;

}
