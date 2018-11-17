/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  msobj.c
 * FILE:	  msobj.c
 *
 * AUTHOR:  	  Adam de Boor: Feb 24, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	2/24/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Utilities for mucking with Microsoft-format object files.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: msobj.c,v 1.28 95/11/08 17:23:59 adam Exp $";
#endif lint

#include    <config.h>
#include    "glue.h"
#include    "borland.h"
#include    "msobj.h"
#include    "obj.h"
#include 		"objformat.h"
#include    "output.h"
#include    "sym.h"
#include    "geo.h"		/* For object relocations */
#include    "library.h"
#include    <objfmt.h>
#include    <compat/stdlib.h>
#include    <compat/string.h>
#include 		"cv.h"

ID   	    msobj_CurFileName = NullID;

byte	    *msobjBuf;	    /* Current object record */
unsigned    msobjBufSize=0; /* Overall size of buffer holding same */

Vector	    segments,	    /* SegDesc *'s for segment indices for this file */
	    groups, 	    /* GroupDesc *'s for group indices for this file */
	    names, 	    /* ID's for name indices for this file */
	    externals,	    /* ObjSym vptr's for external symbols for file */
	    lmemSegs;

MSThread    msThreads[MS_MAX_THREADS];

MSObjCheck	*msobjCheck;
MSObjFinish 	*msobjFinish;

MSSaveRecLinks pubHead = {
    (struct _MSSaveRec *)&pubHead, (struct _MSSaveRec *)&pubHead
};


/***********************************************************************
 *				MSObj_DefCheck
 ***********************************************************************
 * SYNOPSIS:	    Check an object record to determine if the type of
 *	    	    symbol information is specified by it.
 * CALLED BY:	    Pass1MS_Load, Pass2MS_Load
 * RETURN:	    TRUE if object record consumed.
 * SIDE EFFECTS:    objCheck & objFinish may be revectored
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
int
MSObj_DefCheck(const char   *file,
	       byte	    rectype,
	       word	    reclen,
	       byte	    *data,
	       int 	    pass)
{
	printf("MSObj_DefCheck %s\r\n", file);

    if (rectype == MO_COMENT) {
	if (data[1] == CC_MSOFT_EXT) {
		printf("CC_MSOFT_EXT");
	    /*
	     * Comment indicates microsoft extensions are being used.
	     * See if that includes codeview. The letters CV seem to
	     * be in the data portion of the record if this is so.
	     * I don't know what other info can be there...
	     */
	    if (reclen >= 5 && data[3] == 'C' && data[4] == 'V') {
				printf("CV TEST");
		msobjCheck = CV_Check;
		msobjFinish = CV_Finish;
		return (CV_Check(file, rectype, reclen, data, pass));
	    }
		else {
			printf("ALWAYS USE CV32");
			msobjCheck = CV32_Check;
			msobjFinish = CV32_Finish;
			return (CV32_Check(file, rectype, reclen, data, pass));
		}
	} else if ((data[1] == BCC_DEPENDENCY) ||
		   (data[1] == BCC_VERSION))
	{
		printf("BORLAND");
	    /*
	     * Comment indicates Borland symbolic information is being used,
	     * as this record must precede the first non-comment record,
	     * other than THEADR, in the file.
	     */
	    msobjCheck = Borland_Check;
	    msobjFinish = Borland_Finish;
	    return (Borland_Check(file, rectype, reclen, data, pass));
	} else if ((pass == 1) &&
		   (data[1] == 0) &&	/* class 0 */
		   (data[0] == 0) &&	/* no special flags */
		   (data[2] == '@'))
	{
		printf("METAWARE");
	    /*
	     * Entertaining comment record placed in the output file by
	     * GOC to tell us the actual source file name under metaware.
	     */
	    msobj_CurFileName = ST_Enter(symbols, strings, (char *)&data[3],
					 reclen-3);
	}
    }
    /*
     * Not consumed
     */
    return(FALSE);
}

/***********************************************************************
 *				MSObj_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize structures for processing another
 *	    	    Microsoft-format object file.
 * CALLED BY:	    Pass1MS_Load, Pass2MS_Load
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/91		Initial Revision
 *
 ***********************************************************************/
void
MSObj_Init(FILE *stream)    	/* Stream open to object file (unused) */
{
    if (msobjBufSize == 0) {
	/*
	 * First-ever call. Initialize the data structures.
	 */
	msobjBuf = (byte *)malloc(MO_HEADER_SIZE);
	msobjBufSize = MO_HEADER_SIZE;

	segments = Vector_Create(sizeof(SegDesc *), ADJUST_ADD, 10, 10);
	groups = Vector_Create(sizeof(GroupDesc *), ADJUST_ADD, 10, 10);
	names = Vector_Create(sizeof(ID), ADJUST_ADD, 10, 10);
	externals = Vector_Create(sizeof(VMPtr),ADJUST_ADD, 10, 10);
	lmemSegs = Vector_Create(sizeof(MSObjLMemData *),
				 ADJUST_ADD,
				 5, 5);
    } else {
	Vector_Empty(segments);
	Vector_Empty(groups);
	Vector_Empty(names);
	Vector_Empty(externals);
    }

    bzero(&msThreads, sizeof(msThreads));
}


/***********************************************************************
 *				MSObj_ReadRecord
 ***********************************************************************
 * SYNOPSIS:	    Read an object record from the passed file into the
 *	    	    passed buffer and make sure it makes sense.
 * CALLED BY:	    Pass1MS_?, Pass2MS_?
 * RETURN:	    The type of record, or MO_ERROR if the record's bogus.
 *	    	    The data associated with the record is stored at
 *	    	    msobjBuf.
 *	    	    *datalenPtr holds the number of bytes of data in the
 *	    	    buffer.
 *
 *	    	    If record is a data record (LEDATA or LIDATA) and is
 *	    	    followed by a fixup record, the fixup record follows
 *	    	    the data record in the buffer. Caller can determine
 *	    	    if fixups follow by examining the byte following the
 *	    	    data in the record for MO_FIXUPP.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/91		Initial Revision
 *
 ***********************************************************************/
byte
MSObj_ReadRecord(FILE	*stream,    /* Stream from which to read */
		 word	*datalenPtr,
	     int *recNoPtr)/* Place to store record data length
				     * (doesn't include header or checksum) */
{
    word    len;    	    /* Length of record, including checksum */
    byte    sum;    	    /* Accumulator for checksum */
    byte    *bp;    	    /* Pointer into record for generating checksum */
    byte    *endRecord;	    /* End of the record (& of the checksum byte) */
    byte    rectype;	    /* Type of object record (MO_*) */

    assert(msobjBufSize >= MO_HEADER_SIZE);
	(*recNoPtr)++;

    *datalenPtr = 0;		/* Initialize... */

    /*
     * First read the record type and length into the buffer.
     */
    if (fread(msobjBuf, sizeof(byte), MO_HEADER_SIZE, stream) < MO_HEADER_SIZE){
	return(MO_ERROR);
    }

    /*
     * Figure the length of the rest of the record.
     */
    len = msobjBuf[1] | (msobjBuf[2] << 8);
    rectype = msobjBuf[0];

    /*
     * If that length plus the length of the header we just read in is larger
     * than the current buffer size, enlarge the buffer to hold the entire
     * record.
     */
    if (len > msobjBufSize) {
	msobjBufSize = len;
	msobjBuf = (byte *)realloc((void *)msobjBuf, msobjBufSize);
    }

    /*
     * Now read the rest of the record into memory.
     */
    if (fread(msobjBuf, sizeof(byte), len, stream) < len * sizeof(byte)) {
	return(MO_ERROR);
    }

    /*
     * Checksum the whole thing to make sure it's ok. All bytes should sum to 0.
     */
    sum = rectype + (len & 0xff) + ((len >> 8) & 0xff);
    endRecord = bp = msobjBuf+len-1;

    if (*bp == 0) {
	/*
	 * Assume Microsoft C 7.0 record that contains no checksum (grrr) and
	 * say it's ok.
	 */
	sum = 0;
    } else {
	while (bp >= msobjBuf) {
	    sum += *bp--;
	}
    }

    /*
     * Return the length of the record, minus its checksum.
     */
    *datalenPtr = len-1;

    /*
     * If this record is a valid data record (LEDATA or LIDATA), check the next
     * record to see if it contains fixups for this one. If so, tack them onto
     * the end.
     */
    if ((sum == 0) && (rectype == MO_LEDATA || rectype == MO_LIDATA || rectype == MO_LEDATA32 || rectype == MO_LIDATA32 )) {
	byte	nextRecord = getc(stream);

	if (nextRecord == MO_FIXUPP) {
	    byte	lenLow, lenHigh;
	    word	fixLen;

	    lenLow = getc(stream);
	    lenHigh = getc(stream);

	    fixLen = lenLow | (lenHigh << 8);

	    /*
	     * Enlarge the buffer to hold the fixups, if necessary.
	     */
	    if ((fixLen + MO_HEADER_SIZE + len) > msobjBufSize)
	    {
		msobjBufSize = fixLen + MO_HEADER_SIZE + len;
		msobjBuf = (byte *)realloc((void *)msobjBuf, msobjBufSize);
		endRecord = msobjBuf + len - 1;
	    }

	    /*
	     * Stick the header for the fixup record into the buffer immediately
	     * after the data record.
	     */
	    bp = endRecord;
	    *bp++ = nextRecord;
	    *bp++ = lenLow;
	    *bp++ = lenHigh;

	    /*
	     * Now read in all the fixups.
	     */
	    if (fread(bp, sizeof(byte), fixLen, stream) < fixLen * sizeof(byte))
	    {
		return(FALSE);
	    }

	    /*
	     * Checksum the fixup record. sum is already 0 (or we wouldn't be
	     * here). Again we have to deal with Microsoft 7.0 not storing
	     * checksums in the object records...
	     */
	    bp += fixLen-1;
	    if (*bp != 0) {
		while (bp >= endRecord) {
		    sum += *bp--;
		}
	    }

		(*recNoPtr)++;
	} else {
	    /*
	     * Not followed by a fixup record. flag no fixup record following
	     * by setting the checksum byte (where the MO_FIXUPP would go
	     * if there were a following fixup record) to MO_ERROR. Put the
	     * following record's type back into the stream for next time.
	     */
	    *endRecord = MO_ERROR;
	    ungetc(nextRecord, stream);
	}
    }


    return(sum == 0 ? rectype : MO_ERROR);
}


/***********************************************************************
 *				MSObj_GetSegment
 ***********************************************************************
 * SYNOPSIS:	    Locate the segment descriptor for the given
 *	    	    segment index field.
 * CALLED BY:	    external
 * RETURN:	    SegDesc *, or NULL if segment unknown
 * SIDE EFFECTS:    *bufPtr is advanced beyond the field.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/91		Initial Revision
 *
 ***********************************************************************/
SegDesc *
MSObj_GetSegment(byte **bufPtr)
{
    word    index = MSObj_GetIndex(*bufPtr);
    SegDesc *retval;

    retval = (SegDesc *)NULL;
    (void)Vector_Get(segments, index-1, (Address)&retval);
    return(retval);
}


/***********************************************************************
 *				MSObj_GetGroup
 ***********************************************************************
 * SYNOPSIS:	    Locate the group descriptor for the given
 *	    	    group index field.
 * CALLED BY:	    external
 * RETURN:	    GroupDesc *, or NULL if group unknown
 * SIDE EFFECTS:    *bufPtr is advanced beyond the field.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/91		Initial Revision
 *
 ***********************************************************************/
GroupDesc *
MSObj_GetGroup(byte **bufPtr)
{
    word    	index = MSObj_GetIndex(*bufPtr);
    GroupDesc 	*retval;

    retval = (GroupDesc *)NULL;
    (void)Vector_Get(groups, index-1, (Address)&retval);

    return(retval);
}


/***********************************************************************
 *				MSObj_GetName
 ***********************************************************************
 * SYNOPSIS:	    Locate the name for the given name index field.
 * CALLED BY:	    external
 * RETURN:	    ID, or NullID if name unknown
 * SIDE EFFECTS:    *bufPtr is advanced beyond the field.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/91		Initial Revision
 *
 ***********************************************************************/
ID
MSObj_GetName(byte **bufPtr)
{
    word    index = MSObj_GetIndex(*bufPtr);
    ID	    retval;

    retval = NullID;
    (void)Vector_Get(names, index-1, (Address)&retval);

    return(retval);
}


/***********************************************************************
 *				MSObj_GetExternal
 ***********************************************************************
 * SYNOPSIS:	    Locate the external data for the given external index
 *	    	    field.
 * CALLED BY:	    external
 * RETURN:	    VMPtr, or 0 if external unknown
 * SIDE EFFECTS:    *bufPtr is advanced beyond the field.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/24/91		Initial Revision
 *
 ***********************************************************************/
VMPtr
MSObj_GetExternal(byte **bufPtr)
{
    word    index = MSObj_GetIndex(*bufPtr);
    VMPtr    retval;

    retval = (VMPtr)NULL;
    (void)Vector_Get(externals, index-1, (Address)&retval);

    return(retval);
}


/***********************************************************************
 *				MSObj_DecodeFrameOrTarget
 ***********************************************************************
 * SYNOPSIS:	    Decode a frame or target datum from a fixup
 * CALLED BY:	    MSObj_DecodeFixup, Pass1MSCountRels,
 *	    	    Pass2MSFixup
 * RETURN:	    Nothing
 * SIDE EFFECTS:    *bpPtr will be advanced
 *	    	    *dataPtr will be filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 4/91		Initial Revision
 *
 ***********************************************************************/
void
MSObj_DecodeFrameOrTarget(byte	    fixupMethod,
			  byte	    **bpPtr,
			  MSFixData *dataPtr)
{
    switch(fixupMethod) {
	case TFM_SEGMENT:
	    dataPtr->segment = MSObj_GetSegment(bpPtr);
	    break;
	case TFM_GROUP:
	    dataPtr->group = MSObj_GetGroup(bpPtr);
	    break;
	case TFM_EXTERNAL:
	    dataPtr->external = MSObj_GetExternal(bpPtr);
	    break;
	case TFM_ABSOLUTE:
	    MSObj_GetWord(dataPtr->absolute, *bpPtr);
	    break;
	case TFM_SELF:
	    /*
	     * 9/18/92: Microsoft C 7.0 initializes all the target threads to
	     * FFM_SELF, which is supposed to be illegal, but I guess they
	     * decided it saved room (it doesn't), and they still follow it
	     * by an index of no apparent derivation, which we must skip.
	     */
	    (void)MSObj_GetIndex(*bpPtr);
	    break;
    }
}

/***********************************************************************
 *				MSObj_DecodeFixup
 ***********************************************************************
 * SYNOPSIS:	    Decode a fixup record from the object file.
 * CALLED BY:	    Pass1MS?, Pass2MS?
 * RETURN:	    non-zero if fixup is valid.
 * SIDE EFFECTS:    buffer pointer advanced and data filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 4/91		Initial Revision
 *
 ***********************************************************************/
int
MSObj_DecodeFixup(const char *file,
		  SegDesc   *sd,    	    /* Segment for which relocation
					     * is being performed */
		  byte	    **bpPtr,	    /* Buffer Pointer (In/Out) */
		  word	    *fixLocPtr,	    /* Fixup location, plus other
					     * bits (Out) */
		  byte	    *fixDataPtr,    /* Fixup data byte (Out) */
		  MSFixData *targetPtr,	    /* Fixup target data (Out) */
		  MSFixData *framePtr)	    /* Fixup frame data (Out) */
{
    byte    *bp = *bpPtr;	/* For speedy access... */
    byte    fixdata;

    /*
     * Location word is in big-endian order...
     */
    *fixLocPtr = (*bp << 8) | bp[1];
    bp += 2;

    fixdata = *bp++;

    if (fixdata & FD_FRAME_IS_THREAD) {
	int thread = (fixdata & FD_FRAME) >> FD_FRAME_SHIFT;

	if ((thread >= MS_MAX_THREADS) ||
	    !(msThreads[thread].valid & (1 << MST_FRAME)))
	{
	    Notify(NOTIFY_ERROR,
		   "%s: invalid relocation thread specified for frame",
		   file);
	    return (FALSE);
	}
	fixdata &= ~FD_FRAME;
	fixdata |= msThreads[thread].fixup & FD_FRAME;
	*framePtr = msThreads[thread].data[MST_FRAME];
	if ((fixdata & FD_FRAME) == (FFM_SELF << FD_FRAME_SHIFT)) {
	    fixdata = (fixdata & ~FD_FRAME) | (FFM_SEGMENT << FD_FRAME_SHIFT);
	    framePtr->segment = sd;
	}
    } else {
	if ((fixdata & FD_FRAME) < (FFM_SELF << FD_FRAME_SHIFT)) {
	    MSObj_DecodeFrameOrTarget((fixdata & FD_FRAME) >> FD_FRAME_SHIFT,
				      &bp, framePtr);
	} else if ((fixdata & FD_FRAME) == (FFM_SELF << FD_FRAME_SHIFT)) {
	    fixdata = (fixdata & ~FD_FRAME) | (FFM_SEGMENT << FD_FRAME_SHIFT);
	    framePtr->segment = sd;
	}
	/* if FFM_TARGET, Wait until the f***ing target is decoded to
	 * copy its data over... idiots. */
    }

    /*XXX COMMONIZE THESE TWO THINGS SOMEHOW */
    if (fixdata & FD_TARG_IS_THREAD) {
	int thread = (fixdata & FD_TARGET);

	if ((thread >= MS_MAX_THREADS) ||
	    !(msThreads[thread].valid & (1 << MST_TARGET)))
	{
	    Notify(NOTIFY_ERROR,
		   "%s: invalid relocation thread specified for target",
		   file);
	    return(FALSE);
	}

	if ((msThreads[thread].fixup & (TD_METHOD >> TD_METHOD_SHIFT)) ==
	    TFM_SELF)
	{
	    fixdata = (fixdata & ~FD_TARGET) | TFM_SEGMENT;
	    targetPtr->segment = sd;
	} else {
	    fixdata = (fixdata & ~FD_TARGET) |
		(msThreads[thread].fixup & FD_TARGET);
	    *targetPtr = msThreads[thread].data[MST_TARGET];
	}
    } else {
	MSObj_DecodeFrameOrTarget(fixdata & FD_TARGET, &bp, targetPtr);
    }

    if ((fixdata & FD_FRAME) == (FFM_TARGET << FD_FRAME_SHIFT)) {
	*framePtr = *targetPtr;
	fixdata = (fixdata & ~FD_FRAME) |
	    ((fixdata & FD_TARGET) << FD_FRAME_SHIFT);
    }

    *bpPtr = bp;
    *fixDataPtr = fixdata;

    return(TRUE);
}


/***********************************************************************
 *				MSObj_DecodeSegDef
 ***********************************************************************
 * SYNOPSIS:	    Decode an MO_SEGDEF record into its respective pieces
 * CALLED BY:	    Pass1MS_Load, CV_Check
 * RETURN:	    *typePtr	= combine type
 *	    	    *alignPtr	= alignment (mask of bits to be clear)
 *	    	    *namePtr	= name of segment
 *	    	    *classPtr	= class of segment
 *	    	    *framePtr	= "frame" if absolute segment
 *	    	    *sizePtr	= # bytes for segment in this object file
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
int
MSObj_DecodeSegDef(const char *file,
		   byte rectype,
		   byte	*bp,
		   int	*typePtr,
		   int	*alignPtr,
		   ID	*namePtr,
		   ID	*classPtr,
		   word	*framePtr,
		   long	*sizePtr)
{
    byte	attrs;	    /* Attributes from record */
    char	*name;	    /* Name of segment */
    int		order;

    attrs = *bp++;

    /*
     * Convert the combine type in the attributes to our own
     * segment type.
     */
    switch((attrs & SA_COMBINE) >> SA_COMBINE_SHIFT) {
	case 0:
	    *typePtr = SEG_PRIVATE;
	    break;
	case 1:
	case 3:
	    Notify(NOTIFY_ERROR,
		   "%s: undefined segment combine type %d\n",
		   file,
		   (attrs & SA_COMBINE)>>SA_COMBINE_SHIFT);
	    return(0);
	case 2:
	case 4:
	case 7:
	    *typePtr = SEG_PUBLIC;
	    break;
	case 5:
	    *typePtr = SEG_STACK;
	    break;
	case 6:
	    *typePtr = SEG_COMMON;
	    break;
    }

    /*
     * Convert the alignment in the attributes to a bitmask, as we
     * like to store it. We also find if the segment is absolute
     * inside this switch statement.
     */
    switch((attrs & SA_ALIGN) >> SA_ALIGN_SHIFT) {
	case 0: /* Absolute */
	    *typePtr = SEG_ABSOLUTE;
	    *alignPtr = 1-1; /* byte-align */
	    /*
	     * Extract the absolute frame for the segment, ignoring
	     * the offset portion and advance bp beyond the 3
	     * bytes...
	     */
	    *framePtr = bp[0] | (bp[1] << 8);
	    bp += 3;
	    break;
	case 1: /* Byte alignment */
	    *alignPtr = 1-1;
	    break;
	case 2: /* word alignment */
	    *alignPtr = 2-1;
	    break;
	case 3: /* para-aligned */
	    *alignPtr = 16-1;
	    break;
	case 4: /* page-aligned */
	    *alignPtr = 512-1;
	    break;
	case 5: /* dword-aligned */
	    /*
	     * This isn't an official part of the Intel OMF spec, but Borland
	     * seems to use it, for whatever reason. In the OMF spec, this is
	     * an unnamed absolute segment...which we'd never use (and I don't
	     * think have any way of generating anyway...) -- ardeb 12/31/91
	     */
	    *alignPtr = 4-1;
	    break;
	default:
	    Notify(NOTIFY_ERROR,
		   "%s: undefined segment alignment %d\n",
		   file,
		   (attrs & SA_ALIGN)>>SA_ALIGN_SHIFT);
	    return(0);
    }

    /*
     * Figure the size of the segment in this object file.
     */
    if (rectype == MO_SEGDEF) {
	*sizePtr = bp[0] | (bp[1] << 8);
	if (attrs & SA_BIG) {
	    *sizePtr = 65536;
	}
	bp += 2;
    } else {
	MSObj_GetDWord(*sizePtr, bp);
    }

    /*
     * Look up the segment's name in our table of names.
     */
    *namePtr = MSObj_GetName(&bp);

    /*
     * Look up the segment's class in our table of names.
     */
    *classPtr = MSObj_GetName(&bp);

    /*
     * See if this meant to be an lmem segment by looking at the
     * segment name.  If so, set the type and alignment
     */
    name = ST_Lock(symbols, *namePtr);
    if (MSObj_DecodeLMemName(name, &order) != NULL) {
	if (order != LMEM_HEAP) {
	    /*
	     * Force header & handles to be lmem combine type with an alignment
	     * of 4, since that's what the kernel requires.
	     */
	    *typePtr = SEG_LMEM;
	    *alignPtr = 3;
	} else {
	    /*
	     * Heap special-cased to be byte-aligned so we know exactly how
	     * big the compiler thinks the heap is and can, therefore,
	     * correctly determine how big each chunk is.
	     */
	    *typePtr = SEG_LMEM;
	    *alignPtr = 0;
	}
     } else if (!strncmp(name, "_CLASSSEG_", sizeof("_CLASSSEG_") - 1)) {
	 /*
	  * If the thing holds classes, declare it to be a resource segment,
	  * not COMMON, to avoid evil link errors where the data overflow the
	  * space allocated for them.... We set the thing to be word-aligned,
	  * too, to make references to class structures as quick as possible.
	  */
	 *typePtr = SEG_RESOURCE;
	 *alignPtr = 1;
     }
     ST_Unlock(symbols, *namePtr);

    return(1);
}


/***********************************************************************
 *				MSObj_DecodeLMemName
 ***********************************************************************
 * SYNOPSIS:	    Decode a segment name into its lmem components
 * CALLED BY:	    SObj_DecodeLMemName, Pass1MS_Load
 * RETURN:	    pointer to start of basename
 * SIDE EFFECTS:    order - 0, 1, or 2 -- segment ordering
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	5/30/91		Initial Revision
 *
 ***********************************************************************/
char *
MSObj_DecodeLMemName(char *segName,
		    int *order)
{
    char    *cp;

    for (cp = segName; cp != NULL; cp = (char *)index(cp+1, '_')) {
	if (!strncmp(cp, "__HEADER_", 9)) {
	    if (order != DONT_RETURN_ORDER) {
		*order = LMEM_HEADER;
	    }
	    return cp+9;
	}
	if (!strncmp(cp, "__HANDLES_", 10)) {
	    if (order != DONT_RETURN_ORDER) {
		*order = LMEM_HANDLES;
	    }
	    return cp+10;
	}
	if (!strncmp(cp, "__DATA_", 7)) {
	    if (order != DONT_RETURN_ORDER) {
		*order = LMEM_HEAP;
	    }
	    return cp+7;
	}
    }
    return NULL;
}

/***********************************************************************
 *				MSObj_GetLMemSegOrder
 ***********************************************************************
 * SYNOPSIS:	    Get the ordering for an lmem segment
 * CALLED BY:	    Pass1MS_Load
 * RETURN:	    0, 1 or 2 based or whether the segment is the header,
 *	    	    the handles or the heap
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	6/1/91		Initial Revision
 *
 ***********************************************************************/
int
MSObj_GetLMemSegOrder(SegDesc *seg)
{
    int	    order;

    (void) MSObj_DecodeLMemName(ST_Lock(symbols, seg->name), &order);
    ST_Unlock(symbols, seg->name);
    return order;
}


/***********************************************************************
 *				MSObj_SaveRecord
 ***********************************************************************
 * SYNOPSIS:	    Save the current object record buffer for processing
 *	    	    after the entire file has been read.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/28/91		Initial Revision
 *
 ***********************************************************************/
void
MSObj_SaveRecord(byte	    	rectype,
		 word	    	reclen,
		 MSSaveRecLinks	*head)
{
    MSSaveRec 	*srp, *prev;

    srp = (MSSaveRec *)malloc(sizeof(MSSaveRec));
    prev = head->prev;

    insque(srp, prev);

    srp->type = rectype;
    srp->len = reclen;

    /*
     * Free any excess bytes at the end of the record, so we don't waste too
     * much memory keeping this thing around.
     */
    srp->data = (byte *)realloc((malloc_t)msobjBuf, reclen);

    /*
     * Allocate a new buffer for the next record...use a better initial size?
     */
    msobjBufSize = MO_HEADER_SIZE;
    msobjBuf = (byte *)malloc(msobjBufSize);
}


/***********************************************************************
 *				MSObj_SaveFixups
 ***********************************************************************
 * SYNOPSIS:	    Save away the current record's fixups.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    the fixups for the record are duplicated and placed
 *	    	    in the given chain in address-order.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 3/92		Initial Revision
 *
 ***********************************************************************/
void
MSObj_SaveFixups(word	    	startOff,   /* Starting offset of data record */
		 word	    	reclen,	    /* Length of data record */
		 word	    	datalen,    /* Number of bytes of real data in
					     * the data record */
		 MSSaveRecLinks	*head)	    /* List on which to put saved
					     * record */
{
    MSSaveFixupRec  *sfp, *newsfp;
    unsigned        fixlen;
    byte	    *fixbase;

    for (sfp = (MSSaveFixupRec *)head->prev;
	 sfp != (MSSaveFixupRec *)head;
	 sfp = (MSSaveFixupRec *)sfp->links.prev)
    {
	if (sfp->startOff <= startOff) {
	    break;
	}
    }

    /*
     * Point to the length word of the record, and allocate a new
     * MSSaveFixupRec structure to hold the amount of data, plus the length
     * word, specified in the record.
     */
    fixbase = msobjBuf + reclen + 1;
    fixlen = (fixbase[0] | (fixbase[1] << 8)) - 1 + 2;
    newsfp = (MSSaveFixupRec *)malloc(sizeof(MSSaveFixupRec)+fixlen);

    /*
     * Stick the new record after sfp. This works even if sfp is &fixHead.
     */
    insque(newsfp, sfp);

    /*
     * Set up the starting offset, copy in the current fixup threads, then copy
     * the data in from our current object record, minus the record type.
     */
    newsfp->startOff = startOff;
    newsfp->endOff = startOff + datalen;
    bcopy(msThreads, newsfp->threads, sizeof(newsfp->threads));
    bcopy(fixbase, newsfp->data, fixlen);
}

/***********************************************************************
 *				MSObj_FreeSaved
 ***********************************************************************
 * SYNOPSIS:	    Free all the records saved on the passed list.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    The list is emptied and its head set up to receive
 *	    	    new records when the next file is read.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/91	Initial Revision
 *
 ***********************************************************************/
void
MSObj_FreeSaved(MSSaveRecLinks	*head)
{
    MSSaveRec	*srp, *nextSRP;

    for (srp = head->next; srp != (MSSaveRec *)head; srp = nextSRP) {
	nextSRP = srp->links.next;
	free((char *)srp->data);
	remque(srp);
	free((char *)srp);
    }
}


/***********************************************************************
 *				MSObj_FreeFixups
 ***********************************************************************
 * SYNOPSIS:	    Free all the fixup record saved on the passed list.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    The list is emptied and its head set up to receive
 *	    	    new records when the next file is read.
 *
 * STRATEGY:
 *	    The difference between this and MSObj_FreeSaved is this
 *	    doesn't have a secondary block allocated and associated with
 *	    each list element, so all we need to do is remove the element
 *	    from the list and free it before moving on.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/3/92	    	Initial Revision
 *
 ***********************************************************************/
void
MSObj_FreeFixups(MSSaveRecLinks	*head)
{
    MSSaveRec	*srp, *nextSRP;

    for (srp = head->next; srp != (MSSaveRec *)head; srp = nextSRP) {
	nextSRP = srp->links.next;
	remque(srp);
	free((char *)srp);
    }
}


/***********************************************************************
 *				MSObj_MakeString
 ***********************************************************************
 * SYNOPSIS:	    Make up an executable-unique string for something.
 * CALLED BY:	    INTERNAL
 * RETURN:	    An appropriate ID
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/18/91		Initial Revision
 *
 ***********************************************************************/
ID
MSObj_MakeString(void)
{
    static int	namelessCounter = 0;
    static char	namelessBuffer[32];

    sprintf(namelessBuffer, "__NAMELESS__%d", namelessCounter++);
    return(ST_EnterNoLen(symbols, strings, namelessBuffer));
}

/*
 * Structures for tracking anonymous structures.
 */
typedef struct {
    word    size;   	/* Size of the structure, in bytes */
    word    nfields;	/* Number of fields in the structure */
    ID	    name;   	/* Name of the structure */
} MSAnonStruct;

#define MS_ANON_INIT	10
#define MS_ANON_INCR	10
#define MS_ANON_THREADS	37

static Vector msAnonTable[MS_ANON_THREADS];


/***********************************************************************
 *				MSCompareStructs
 ***********************************************************************
 * SYNOPSIS:	    Compare two structure definitions to see if they're
 *	    	    the same.
 * CALLED BY:	    MSObj_AddAnonStruct
 * RETURN:	    TRUE if they're the same.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 1/91		Initial Revision
 *
 ***********************************************************************/
static Boolean
MSCompareStructs(ObjSym	    	*os,	    /* Locked structure symbol */
		 VMBlockHandle	typeBlock,  /* Associated type block */
		 VMBlockHandle	otherBlock, /* Block holding possible match */
		 word	    	otherOff)   /* Offset of possible match within
					     * same */
{
    ObjSymHeader	*otherOSH;
    ObjSym	    	*otherOS;
    void	    	*otherTBase;
    ObjSym	    	*fs1;
    int 	    	fc;
    Boolean 	    	retval = FALSE;	    /* Assume no match */
    void    	    	*tbase;

    tbase = VMLock(symbols, typeBlock, (MemHandle *)NULL);

    fc = os->u.sType.last - os->u.sType.first;

    otherOSH = (ObjSymHeader *)VMLock(symbols, otherBlock, NULL);
    otherOS = (ObjSym *)((genptr)otherOSH+otherOff);
    otherTBase = VMLock(symbols, otherOSH->types, NULL);

    /*
     * Make sure they're the same type of symbol.
     */
    if (otherOS->type != os->type) {
	goto done;
    }

    /*
     * Make sure the types are of the same size.
     */
    if (otherOS->u.sType.size != os->u.sType.size) {
	goto done;
    }
    /*
     * Use the difference between the offsets of the
     * first and last field symbols to see if the two
     * definitions have the same number of fields.
     */
    if ((otherOS->u.sType.last - otherOS->u.sType.first) !=
	(os->u.sType.last - os->u.sType.first))
    {
	goto done;
    }

    /*
     * If first is zero, structure has no fields to be checked.
     */
    if (os->u.sType.first == 0) {
	goto done;
    }

    /*
     * Now check the individual fields for compatibility.
     */
    for (fs1 = otherOS+1, os++; fc >= 0; fs1++, fc -= sizeof(ObjSym), os++)
    {
	/*
	 * Compare the two names. Don't bother looking one up in the other's
	 * string table, as that will cause more string compares than
	 * just doing one here will...
	 */
	if ((fs1->name != os->name) || (fs1->type != os->type)) {
	    goto done;
	}

	if (fs1->type == OSYM_FIELD) {
	    /*
	     * Make sure the fields lie at the same offset in their respective
	     * structures.
	     */
	    if (fs1->u.sField.offset != os->u.sField.offset) {
		goto done;
	    }
	} else {
	    /*
	     * Make sure the fields lie at the same offset in their respective
	     * records.
	     */
	    if (fs1->u.bField.offset != os->u.bField.offset) {
		goto done;
	    }
	    /*
	     * Make sure the fields are the same width in their respective
	     * records.
	     */
	    if (fs1->u.bField.width != os->u.bField.width) {
		goto done;
	    }
	}

	/*
	 * Make sure their types match.
	 */
	if (!Obj_TypeEqual(symbols, otherTBase, fs1->u.sField.type,
			   symbols, tbase, os->u.sField.type))
	{
	    goto done;
	}
    }

    /*
     * If we got here, they're equivalent.
     */
    retval = TRUE;

    done:

    /*
     * Release the blocks containing the already-defined symbol.
     */
    VMUnlock(symbols, otherOSH->types);
    VMUnlock(symbols, otherBlock);

    /*
     * And the associated type block for the structure being defined.
     */
    VMUnlock(symbols, typeBlock);

    return(retval);
}


/***********************************************************************
 *				MSObj_AddAnonStruct
 ***********************************************************************
 * SYNOPSIS:	    Record another anonymous structure in the world.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    os->name is replaced by the name of an existing
 *	    	    	matching anonymous structure if such there be.
 *
 * STRATEGY:
 *	The idea here is to prevent duplicate structure definitions from
 *	building up in the .sym file just because the goob didn't give
 *	a tag to a structure.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
void
MSObj_AddAnonStruct(ObjSym  	    *os,    	/* Locked structure symbol */
		    VMBlockHandle   typeBlock,	/* Block in which descriptions
						 * of its field's types are
						 * stored */
		    int	    	    size,   	/* Structure size (bytes) */
		    int	    	    nfields)	/* Number of fields in the
						 * structure */
{
    MSAnonStruct	*msas;
    Vector	    	entries;
    int 	    	bucket;
    Boolean	    	new = TRUE;
    int	    	    	i;

    bucket = (nfields * size) % MS_ANON_THREADS;
    entries = msAnonTable[bucket];

    if (entries != NullVector) {
	for (i = Vector_Length(entries), msas = Vector_Data(entries);
	     i > 0;
	     i--, msas++)
	{
	    if ((msas->size == size) && (msas->nfields == nfields)) {
		VMBlockHandle   otherBlock;
		word	    	otherOff;

		if (Sym_Find(symbols, globalSeg->syms, msas->name,
			     &otherBlock, &otherOff, FALSE) &&
		    MSCompareStructs(os, typeBlock, otherBlock, otherOff))
		{
		    os->name = msas->name;
		    new = FALSE;
		    break;
		}
	    }
	}
    }

    if (new) {
	MSAnonStruct    newMSAS;

	if (entries == NullVector) {
	    entries = Vector_Create(sizeof(MSAnonStruct), ADJUST_ADD,
				    MS_ANON_INCR, MS_ANON_INIT);
	    msAnonTable[bucket] = entries;
	}
	newMSAS.size = size;
	newMSAS.nfields = nfields;
	newMSAS.name = os->name;

	Vector_Add(entries, VECTOR_END, &newMSAS);
    }
}


/***********************************************************************
 *				MSObj_AllocType
 ***********************************************************************
 * SYNOPSIS:	    Allocate an ObjType record in the passed type block.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Pointer to the ObjType
 *	    	    Offset of it within the block
 *	    	    BLOCK IS RETURNED LOCKED, OF COURSE
 * SIDE EFFECTS:    The block may move...
 *	    	    oth->num will be upped by 1
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/91		Initial Revision
 *
 ***********************************************************************/
ObjType *
MSObj_AllocType(VMBlockHandle   typeBlock,
		word	    	*offsetPtr)
{
    MemHandle	    mem;
    ObjTypeHeader   *oth;
    ObjType 	    *ot;
    word    	    size;
    static ObjType  fakeOT;

printf("MSObj_AllocType %x\n", typeBlock); fflush(stdout);

    if (typeBlock == 0) {
	/*
	 * Not actually creating a type description, so just return
	 * the address of fakeOT and an offset of 0...
	 */
	*offsetPtr = 0;
	return (&fakeOT);
    }

    /*
     * Lock down the block and find how big it currently is.
     */
    oth = (ObjTypeHeader *)VMLock(symbols, typeBlock, &mem);
    VMInfo(symbols, typeBlock, &size, (MemHandle *)NULL, (VMID *)NULL);

    /*
     * If the block isn't big enough to hold another entry, expand it by
     * some arbitrary number of entries (16, for now).
     */
    ot = ObjFirstEntry(oth, ObjType) + oth->num;
    if (ObjEntryOffset(ot, oth) > (size - sizeof(ObjType))) {
	MemReAlloc(mem, size + 16 * sizeof(ObjType), 0);
	MemInfo(mem, (genptr *)&oth, (word *)NULL);
	ot = ObjFirstEntry(oth, ObjType) + oth->num;
    }

    /*
     * Return the actual offset of the thing in the block and up the number
     * of entries in the block by one.
     */
    *offsetPtr = ObjEntryOffset(ot, oth);
    oth->num += 1;

    /*
     * Mark the block as dirty and return the pointer to our caller.
     */
    VMDirty(symbols, typeBlock);
		printf("MSObj_AllocType2 %d\n", *offsetPtr);
    return(ot);
}


/***********************************************************************
 *				MSObj_CreateArrayType
 ***********************************************************************
 * SYNOPSIS:	    Create 1 or a series of ObjType records to hold an
 *	    	    array descriptor.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    offset within typeBlock of head ObjType record
 *	    	    TYPE BLOCK REMAINS LOCKED ONCE
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/92		Initial Revision
 *
 ***********************************************************************/
word
MSObj_CreateArrayType(VMBlockHandle 	types,
		      word  	    	base,
		      int   	    	alen)
{
    int	    numExtra;
    word    retval;
    ObjType *otp;

    /*
     * Using that, determine how many extra ObjType records we'll
     * need to allocate to indicate that many elements are in the
     * array. Count is left in numExtra.
     */
    numExtra = 0;
    while (alen > OTYPE_MAX_ARRAY_LEN) {
	numExtra += 1;
	alen -= OTYPE_MAX_ARRAY_LEN+1;
    }

    /*
     * Create the first ObjType for the thing, holding the remainder
     * and the offset of the actual base type.
     */
    otp = MSObj_AllocType(types, &retval);
    otp->words[0] = OTYPE_MAKE_ARRAY(alen);
    otp->words[1] = base;

    /*
     * Allocate additional OTYPE_MAX_ARRAY_LEN+1 array descriptors
     * as needed. Offset of final allocated one ends up in retval.
     */
    while (numExtra > 0) {
	base = retval;
	otp = MSObj_AllocType(types, &retval);
	otp->words[0] = OTYPE_MAKE_ARRAY(OTYPE_MAX_ARRAY_LEN+1);
	otp->words[1] = base;
	numExtra -= 1;

	/*
	 * Don't need the extra lock placed on the block by
	 * MSObj_AllocType...
	 */
	VMUnlock(symbols, types);
    }

    VMDirty(symbols, types);
    return(retval);
}


/*
 * these strings are special tokens used by borlandc for doing floating
 * point reloctaions
 */
static char *SpecialStringsFromBorland[] =
{
    "FIW",
    "FIA",
    "FIS",
    "FIE",
    "FID",
    "FJC",
    "FJS",
    "FJA",
    NULL
};

/* a table of values corresponding to the strings in the previous table */
static char SpecialTokensFromBorland[] =
{
    FPED_FIWRQQ,
    FPED_FIARQQ,
    FPED_FISRQQ,
    FPED_FIERQQ,
    FPED_FIDRQQ,
    FPED_FJCRQQ,
    FPED_FJSRQQ,
    FPED_FJARQQ
};


/*********************************************************************
 *		    MSObj_IsFloatingPointExtDef
 *********************************************************************
 * SYNOPSIS: see if this is a floating point EXTDEF
 * CALLED BY:	MsObjMapExternal
 * RETURN:  nothing
 * SIDE EFFECTS: name ID put into appropriate global variable (if needed)
 * STRATEGY: compare the name string to the known possibities
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	9/10/92		Initial version
 *
 *********************************************************************/
#define FLOATING_POINT_SYM_LENGTH 6

FloatingPointExtDef
MSObj_IsFloatingPointExtDef(ID name)
{
    char    *str;
    FloatingPointExtDef	f;
    char    *ptr;
    int	    i=0;

    f = FPED_FALSE;
    str = ST_Lock(symbols, name);

    /* since these are very rare do a little optimization */
    if (strlen(str) == FLOATING_POINT_SYM_LENGTH &&
	 str[3] == 'R' && str[4] == 'Q' && str[5] == 'Q')
    {
    	ptr = SpecialStringsFromBorland[0];
    	while (ptr != NULL)
    	{
	    if (!strncmp(str, ptr, 3))
	    {
	    	f = SpecialTokensFromBorland[i];
	    	break;
	    }
	    i++;
	    ptr = SpecialStringsFromBorland[i];
    	}
    }

    ST_Unlock(symbols, name);
    return f;
}


/***********************************************************************
 *				MSObjMapExternal
 ***********************************************************************
 * SYNOPSIS:	    Map an external frame/target to a segment & offset,
 *	    	    generating an appropriate error if the external symbol
 *	    	    is still undefined, as recorded in the externals
 *	    	    vector
 * CALLED BY:	    MSObj_PerformRelocations
 * RETURN:	    TRUE if mapping sucessful
 * SIDE EFFECTS:    *fdataPtr will be changed to a SegDesc * if the thing
 *	    	    is really external.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/28/91		Initial Revision
 *
 ***********************************************************************/
static FloatingPointExtDef
MSObjMapExternal(const char	*file,	    /* Name of object file being read */
		 byte	    	targMethod, /* Method used for target */
		 MSFixData	*fdataPtr,  /* Data for the target */
		 word	    	*offsetPtr, /* Place to store actual offset */
		 SegDesc  	*sd,	    /* Segment in which relocation is
					     * taking place (for errors) */
		 word	    	fixOff,	    /* Offset at which relocation is
					     * taking place within this file's
					     * piece of sd (for errors) */
		 ObjSym   	**osPtr,    /* Place to store locked symbol,
					     * if there is one. */
		 VMBlockHandle 	*symBlockPtr,/* Place to store handle of block
					       * holding symbol, if any */
		 int	    	pass,
		 Boolean    	isLMemHandleSegment)
{
	printf("MSObjMapExternal\n"); fflush(stderr);
    if (targMethod == TFM_EXTERNAL) {
	if (fdataPtr->external & MO_EXT_UNDEFINED) {
	    /*
	     * The thing was undefined when it was encountered in its EXTDEF
	     * record -- bitch now, so we can tell the user where s/he screwed
	     * up...
	     */
	    if (pass == 2)
	    {
		FloatingPointExtDef f;

		f = MSObj_IsFloatingPointExtDef(fdataPtr->external &
					       	~MO_EXT_UNDEFINED);

		if (f == FPED_FALSE)
		{
		    Pass2_RelocError(sd, fixOff, "%i undefined2",
				 fdataPtr->external & ~MO_EXT_UNDEFINED);
		}
		return f;
	    }
	} else {
	    ObjSymHeader    *osh;   	/* Header of block holding external */
	    ObjSym  	    *os;    	/* External symbol */
	    VMBlockHandle   symBlock;	/* Block holding symbol */
	    VMBlockHandle   mapBlock;	/* Block holding hdr */
	    int	    	    i;

	    /*
	     * Locate the symbol and map blocks.
	     */
	    symBlock = VMP_BLOCK(fdataPtr->external);
	    mapBlock = VMGetMapBlock(symbols);

	    /*
	     * Lock them both down.
	     */
	    osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *)NULL);

	    /*
	     * Figure where the symbol and the segment descriptors are in those
	     * two blocks. We know the segment because the symbol block has
	     * its map-block offset in the symbol block's header.
	     */
	    os = (ObjSym *)((genptr)osh + VMP_OFFSET(fdataPtr->external));

	    /*
	     * Locate the appropriate internal descriptor -- it better be here.
	     *
	     * HACK HACK HACKmapBlock
			 *. We don't use private segments around here, and
	     * certainly don't have relocations to them, but this here
	     * MetaWare library does, so we've got to go seeking for the
	     * thing based on the offset of the segment in the output file's
	     * map block, not the name and class.
	     */
	    fdataPtr->segment = NULL;
			printf("seg_NumSegs %d\n", seg_NumSegs);
	    for (i = 0; i < seg_NumSegs; i++) {

				printf("seg_%d  %d %d\n", i, seg_Segments[i]->offset, osh->seg);

				{
					ObjHeader* hdr;
					if(seg_Segments[i]->name) {
						char* str = ST_Lock(symbols, seg_Segments[i]->name);
						printf("seg_%d  %s\n", i, str);fflush(stdout);
						ST_Unlock(symbols, seg_Segments[i]->name);
					}
					if(mapBlock) {
				  	hdr = (ObjHeader*) VMLock(symbols, mapBlock, (MemHandle *)NULL);
						//printf("numSeg %d\n", hdr->numSeg)
						VMUnlock(symbols, mapBlock);
					}
				}
		if (seg_Segments[i]->offset == osh->seg) {
		    fdataPtr->segment = seg_Segments[i];
		    break;
		}
	    }
fflush(stdout);
	    pass2_assert((fdataPtr->segment != NULL), sd, fixOff);

	    /*
	     * Let library stuff know we're using the entry-point.
	     */
	    if (fdataPtr->segment->combine == SEG_LIBRARY) {
		VMBlockHandle    pubBlock;
		word             pubOff;
		SegDesc          *pubSD;

		ID    publishedID;

		if (!Library_UseEntry(fdataPtr->segment, os, TRUE, FALSE)) {
		    publishedID = Library_TackPrependPublishedToID(symbols,
								   strings,
								   os->name);
		    if (publishedID != NullID) {
			publishedID =
			    Library_TackPrependPublishedToID(symbols,
							     strings,
							     publishedID);

			if ((publishedID != NullID) &&
			    Sym_FindWithSegment(symbols,
						publishedID,
						&pubBlock,
						&pubOff,
						FALSE,
						&pubSD))
			{
			    /*
			     * We've found the published version of the routine.
			     * Switch the relocation over to point at it
			     * instead...
			     */
			    targMethod = TFM_SEGMENT;
			    fdataPtr->segment = pubSD;

			    /*
			     * This segment should've been marked as
			     * SEG_RESOURCE in Pass1MS_EnterExternal
			     */
			    assert(pubSD->combine == SEG_RESOURCE);

			    /*
			     * Replace the library entry symbol data with
			     * the linked-in published symbol data.
			     */
			    VMUnlock(symbols, symBlock);

			    symBlock = pubBlock;
			    osh = (ObjSymHeader *)VMLock(symbols, pubBlock,
							 (MemHandle *)NULL);
			    os = (ObjSym *)((genptr)osh+pubOff);

			    /*
			     * Mark the thing as a published symbol so the
			     * second pass can cope with a far call to a
			     * published routine that's broken across object
			     * records (needs to reduce sd->nrel by 1, as
			     * pass 1 counted 2 relocations for the thing)
			     */
			    if (os->type == OSYM_PROC) {
				os->u.proc.flags |= OSYM_PROC_PUBLISHED;
				VMDirty(symbols, pubBlock);
			    }
			} else {
			    publishedID = NullID;
			}
		    }

		    if (publishedID == NullID) {
			/*
			 * Complain that we don't have access to the entry
			 * point, and there's no published version of it.
			 */
			(void)Library_UseEntry(fdataPtr->segment, os,
					       TRUE, TRUE);
			return(FPED_FALSE);
		    }
		}
	    }

	    /*
	     * Set the offset to that of the external symbol.
	     */
	    *offsetPtr = os->u.addrSym.address;
	    *osPtr = os;
	    *symBlockPtr = symBlock;

	    if (!(os->flags & OSYM_REF)) {
		/*
		 * Mark symbol as referenced and block as dirty if not already
		 * marked as referenced.
		 */
		os->flags |= OSYM_REF;
		VMDirty(symbols, symBlock);
	    }

	    VMUnlock(symbols, mapBlock);
	}
    } else {

	/*
	 * It's fine as it is, but set the offset to 0.
	 * 9/4/92: if the segment being relocated is the handle table of
	 * an lmem group, and we're in pass 2, we need to add in an extra
	 * offset of 2, to account for the size word we'll be adding, since
	 * the compiler isn't using the similar adjustment we made to the
	 * variable symbol for the chunk data.
	 */
	if (isLMemHandleSegment) {
	    *offsetPtr = 2;
	} else {
	    *offsetPtr = 0;
	}
	*osPtr = NULL;
	*symBlockPtr = 0;
    }
    return(FPED_TRUE);
}


/***********************************************************************
 *				MSObjLocateSymbol
 ***********************************************************************
 * SYNOPSIS:	    See if a symbol exists at the passed offset in the
 *	    	    segment.
 * CALLED BY:	    MSObjProcessRels
 * RETURN:	    *osPtr points to the symbol, if found, with *blockPtr
 *	    	    holding the containing VM block to be unlocked.
 * SIDE EFFECTS:    nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 9/91		Initial Revision
 *
 ***********************************************************************/
static void
MSObjLocateSymbol(SegDesc 	    *sd,
		    word    	    offset, 	/* Offset of symbol,
						 * relocated to deal with
						 * subsegments, etc. */
		    ObjSym  	    **osPtr,
		    VMBlockHandle   *blockPtr)
{
    if (sd->type == S_SUBSEGMENT) {
	sd = Seg_FindPromotedGroup(sd);
    }

    if (sd->addrMap != 0) {
        /*
	 * Segment actually has an address map. First find the likeliest
	 * block and begin searching backwards from there.
	 */
	ObjAddrMapEntry	    *oame;  /* Current entry in the address
				     * map */
	ObjAddrMapHeader    *oamh;  /* Header for segment's map */
	int	    	    i;

        oamh = (ObjAddrMapHeader *)VMLock(symbols,
					  sd->addrMap,
					  (MemHandle *)NULL);

	/*
	 * Find the entry whose last address is *greater* than the offset
	 * to deal with weird cases that will probably never arise -- I'll
	 * let you figure it out.
	 */
	for (i = oamh->numEntries, oame = (ObjAddrMapEntry *)(oamh+1);
	     i > 0;
	     i--, oame++)
	{
            if (oame->last > offset) {
		break;
	    }
	}

	/*
	 * Deal with falling off the end of the map by pre-decrementing
	 * oame to point it at a valid entry.
	 */
	if (i == 0) {
	    oame--;
	    i++;
	}


	/*
	 * Now run through the list of address-symbol blocks looking
	 * for one whose address matches the offset. If we find one whose
	 * address is greater than the offset, we can stop looking, since
	 * things are sorted.
	 */
	while (i <= oamh->numEntries) {
	    ObjSymHeader	*osh;
	    int 	    	j;
	    ObjSym	    	*s = (ObjSym *)NULL;
	    ObjSym  	    	*os;

	    osh = (ObjSymHeader *)VMLock(symbols,
					 oame->block,
					 (MemHandle *)NULL);
	    os = &((ObjSym *)(osh+1))[osh->num];
	    for (j = osh->num; j > 0; j--) {
		os--;

		switch (os->type) {
		    case OSYM_PROC:
		    case OSYM_LABEL:
		    case OSYM_VAR:
		    case OSYM_CHUNK:
		    case OSYM_ONSTACK:
		    case OSYM_CLASS:
		    case OSYM_MASTER_CLASS:
		    case OSYM_VARIANT_CLASS:
                        if (os->u.addrSym.address == offset) {
			    /*
			     * Found an address-bearing symbol at the right
			     * address. Save the block and the symbol's address
			     * and mark the sym as referenced, marking the
			     * containing block as dirty, therefore.
			     */
			    s = *osPtr = os;
			    *blockPtr = oame->block;
			    os->flags |= OSYM_REF;
			    VMDirty(symbols, oame->block);
			}
			break;
		    default:
			continue;
		}
		/*
		 * If we're at or below the address in question, we're done
		 * with the loop.
		 */
		if (os->u.addrSym.address <= offset) {
		    break;
		}
	    }
	    if ((j != 0) || (s != (ObjSym *)NULL)) {
		/*
		 * We found something or stopped before we hit the beginning
		 * of the block, so there's no point in going on to
		 * the next block. We do still need to unlock the
		 * containing block if we're returning no symbol, however...
		 */
		if (s == (ObjSym *)NULL) {
		    VMUnlock(patient->symFile, oame->block);
		}
		break;
	    } else {
		/*
		 * The previous block might hold something of interest, since
		 * all the symbols up to the first have addresses that are >=
		 * the one we seek, so unlock this one and proceed to search
		 * that block.
		 */
		VMUnlock(patient->symFile, oame->block);
		oame--, i++;
	    }
	}
	/*
	 * Unlock the address map before returning...
	 */
	VMUnlock(patient->symFile, s->addrMap);
    }
}


/*********************************************************************
 *			MSObjDoFloatingPointRelocations
 *********************************************************************
 * SYNOPSIS: mangle the floating point opcode into a software interrupt
 * CALLED BY:	MSObj_PerformRelocations
 * RETURN:  nothing
 * SIDE EFFECTS: opcode mangled
 * STRATEGY: data from PC Magazines "The Processor And CoProcessor" pg. 270
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	9/10/92		Initial version
 *
 *********************************************************************/
static void
MSObjDoFloatingPointRelocation(byte *fixme, FloatingPointExtDef f)
{
    switch (f)
    {
    	case FPED_FIWRQQ:
	    *fixme++ = 0xcd;
	    *fixme = 0x3d;
	    break;
	case FPED_FIDRQQ:
	    *fixme++ = 0xcd;
	    *fixme -= 0xa4;
	    break;
	case FPED_FIERQQ:
	    *fixme++ = 0xcd;
	    *fixme += 0x16;
	    break;
	case FPED_FJERQQ:
	    break;
	case FPED_FIARQQ:
	    *fixme++ = 0xcd;
	    *fixme -= 0x02;
	    break;
	case FPED_FJARQQ:
	    fixme++;
	    *fixme += 0x16;
	    break;
	case FPED_FICRQQ:
	    *fixme++ = 0xcd;
	    *fixme += 0x0e;
	    break;
	case FPED_FJCRQQ:
	    fixme++;
	    *fixme += 0xc0;
	    break;
	case FPED_FISRQQ:
	    *fixme++ = 0xcd;
	    *fixme += 0x06;
	    break;
	case FPED_FJSRQQ:
	    fixme++;
	    *fixme += 0x80;
	    break;
	default:
	    fprintf(stderr,
		    "ERROR: illegal value passed to switch in msobj.c:1904\n");
	    exit(1);
	    break;
    }

}

/***********************************************************************
 *				MSObj_PerformRelocations
 ***********************************************************************
 * SYNOPSIS:	    Perform the relocations specified in a FIXUPP block
 *	    	    on a block of memory provided.
 * CALLED BY:	    MSObjProcessRels, Pass1MSMangleLMem
 * RETURN:	    TRUE if all relocations performed successfully.
 *	    	    *nextRelPtr pointing beyond last runtime relocation
 *	    	    	created, if pass == 2
 * SIDE EFFECTS:    words in the data block are altered according to the
 *	    	        relocations in the FIXUPP record
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 3/92		Initial Revision
 *
 ***********************************************************************/
Boolean
MSObj_PerformRelocations(const char	*file,	    /* Name of object file */
			   byte	    	*data,	    /* Block to relocate */
			   byte	    	*bp,	    /* Start of fixups (past
						     * MO_FIXUPP and length) */
			   byte	    	*endRecord, /* 1 past last fixup */
			   SegDesc  	*sd,	    /* Segment to which block
						     * belongs */
			   word	    	baseOff,    /* Offset w/in segment of
						     * first byte in block */
			   int	    	pass,	    /* Which pass we're on */
			   byte	    	**nextRelPtr)
{
    byte    	*nextRel;
    Boolean 	retval = TRUE;
    Boolean 	isLMemHandleSegment =
	((sd != NULL) &&
	 (sd->combine==SEG_LMEM) &&
	 (MSObj_GetLMemSegOrder(sd)==LMEM_HANDLES));

printf("MSObj_PerformRelocations\n"); fflush(stdout);

    if (nextRelPtr != NULL) {
	nextRel = *nextRelPtr;
    } else {
	nextRel = NULL;
    }
    /*
     * This is garbage; it works for every case but the standalone, thread-
     * defining FIXUPP record, where nothing comes before the data for the
     * record, so this is checking garbage.
    if (bp[-3] != MO_FIXUPP) {
	bp = endRecord;
    }
     */

    while (bp < endRecord) {
	if (*bp & FLH_IS_FIXUP) {
	    byte    	    fixdata;	/* Fixup data byte telling us the
					 * type of frame and target we've got */
	    MSFixData	    target; 	/* Target of the relocation */
	    MSFixData	    frame;  	/* Frame w.r.t. which to relocate it */
	    word    	    fixLoc; 	/* Location and other stuff about the
					 * fixup */
	    word    	    offset; 	/* Offset portion to store */
	    word    	    fixOff; 	/* Offset of the fixup within this
					 * file's piece of the destination
					 * segment */
	    word    	    absFixOff;	/* Absolute offset of same */
	    byte    	    *fixme; 	/* Low-order byte of affected region
					 * within the record */
	    ObjSym  	    *os;    	/* External symbol in frame/target, if
					 * any */
	    VMBlockHandle   frameBlock;	/* Block holding frame symbol */
	    VMBlockHandle   targetBlock;/* Block holding target symbol */
	    FloatingPointExtDef	    f; /* special token type */

#if 0
	    ObjSymHeader    *osh;   	/* Header of block holding external */
	    ObjSym  	    *os;    	/* External symbol */
	    SegDesc         *osd;
	    VMBlockHandle   symBlock;	/* Block holding symbol */
	    VMBlockHandle   mapBlock;	/* Block holding hdr */
	    int	    	    i;

#endif

#if TEST_NRELS
	    int	    	nrel = 0;   /*XXX*/
	    int	    	callfn = 0; /*XXX*/
#endif

	    assert (sd != NULL); /* Should have been caught in pass 1 */

	    /*
	     * Decode the next fixup.
	     */
	    if (!MSObj_DecodeFixup(file, sd, &bp, &fixLoc, &fixdata, &target,
				   &frame))
	    {
		return(FALSE);
	    }

            fixOff = baseOff + (fixLoc & FL_OFFSET);
	    absFixOff = fixOff + (sd->nextOff - sd->foff);
	    fixme = data + (fixLoc & FL_OFFSET);

	    /*
	     * If the frame or the target is an external symbol, we need to
	     * get the segment and offset instead.
	     */
	    f  = MSObjMapExternal(file,
				  (fixdata & FD_FRAME) >> FD_FRAME_SHIFT,
				  &frame,
				  &offset,
				  sd,
				  fixOff,
				  &os,
				  &frameBlock,
				  pass,
				  isLMemHandleSegment);

	    if (f == FPED_FALSE)
	    {
		/*
		 * Erroneous fixup. Skip any target displacement and go on to
		 * the next fixup.
		 */
		if (!(fixdata & FD_NO_TARG_DISP)) {
		    bp += 2;
		}
		continue;
	    }

	    if (f != FPED_TRUE)
	    {
		/* we have a special floating point EXTDEF so deal with it */
		MSObjDoFloatingPointRelocation(fixme, f);
		goto error;
	    }

	    f =  MSObjMapExternal(file,
				  (fixdata & FD_TARGET),
				  &target,
				  &offset,
				  sd,
				  fixOff,
				  &os,
				  &targetBlock,
				  pass,
				  isLMemHandleSegment);

	    if (f == FPED_FALSE)
	    {
		/*
		 * Erroneous fixup. Skip any target displacement and go on to
		 * the next fixup.
		 */
		if (!(fixdata & FD_NO_TARG_DISP)) {
		    bp += 2;
		}
		if (frameBlock != 0) {
		    VMUnlock(symbols, frameBlock);
		}
		continue;
	    }

	    if (f != FPED_TRUE)
	    {
		/* we have a special floating point EXTDEF so deal with it */
		MSObjDoFloatingPointRelocation(fixme, f);
		goto error;
	    }
	    /*
	     * Don't need the frame symbol any more...
	     */
	    if (frameBlock) {
		VMUnlock(symbols, frameBlock);
	    }

	    /*
	     * If fixup has extra target displacement, add it into the offset
	     * now.
	     */
	    if (!(fixdata & FD_NO_TARG_DISP)) {
		offset += *bp++;
		offset += *bp++ << 8;
	    }

	    /*
	     * Make sure the frame and the target are related somehow. Go on
	     * to the next fixup if they're not.
	     */
	    if ((fixdata & FD_FRAME) == (FFM_ABSOLUTE<<FD_FRAME_SHIFT)) {
		if ((fixdata & FD_TARGET) != TFM_ABSOLUTE) {
		    if (pass == 2) {
			Pass2_RelocError(sd, fixOff,
					 "relocation target must be absolute if frame is absolute");
		    }
		    retval = FALSE;
		    goto error;
		}
	    } else if ((fixdata & FD_TARGET) == TFM_ABSOLUTE) {
		if (pass == 2) {
		    Pass2_RelocError(sd, fixOff,
				     "relocation frame must be absolute if target is absolute");
		}
		retval = FALSE;
		goto error;
	    } else if ((target.segment->combine == SEG_LMEM) ||
		       (target.segment->isClassSeg)) {
		/*
		 * If the segment is lmem, we've changed it from being in DGROUP
		 * to being in its own special group, so we ignore the given
		 * frame of the fixup and switch it to being the group within
		 * the segment resides instead...
		 */
		frame.segment = (SegDesc *)target.segment->group;
		fixdata = (fixdata & ~FD_FRAME) | (FFM_GROUP << FD_FRAME_SHIFT);
	    } else if (target.segment->combine == SEG_LIBRARY) {
		/*
		 * If the segment is a library, the compiler is (once again)
		 * screwing us over. Just as for lmem, make the segment be
		 * the frame. GCC will nicely optimize this code by merging
		 * the two identical code fragments in these if's, but I'm
		 * sure HighC won't...
		 */
		frame.segment = target.segment;
		fixdata = (fixdata & ~FD_FRAME) | (FFM_SEGMENT<<FD_FRAME_SHIFT);
	    } else if (!Obj_CheckRelated(frame.segment, target.segment)) {
		if (pass == 2) {
		    Pass2_RelocError(sd, fixOff,
				     "%i unrelated to %i: improper frame for relocation",
				     frame.segment->name,
				     target.segment->name);
		}
		retval = FALSE;
		goto error;
	    }

#if 0	/* why was this restriction here, other than it's nonsense for
	 * everything but a segment relocation? */
	    if (((fixdata & FD_TARGET) != TFM_ABSOLUTE) &&
		(target.segment->type == S_GROUP))
	    {
		if (pass == 2) {
		    Pass2_RelocError(sd, fixOff,
				     "cannot have a group as a relocation target");
		}
		retval = FALSE;
		goto error;
	    }
#endif

#if 0	/* This is true, but I don't feel like passing rectype in here, and
	 * it's not as if anyone's going to be stupid enough to do this... */
	    if ((rectype == MO_LIDATA) && !(fixLoc & FL_SEG_REL)) {
		if (pass == 2) {
		    Pass2_RelocError(sd, fixOff,
				     "fixups in an iterated-data record may not be pc-relative");
		}
		retval = FALSE;
		goto error;
	    }
#endif


	    /*
	     * If the frame is a group, add in the group offset for the segment
	     * as well. Target must be a segment related to (i.e. in) the
	     * group, or we would have bailed by now.
	     */
	    if ((fixdata & FD_FRAME) == (FFM_GROUP << FD_FRAME_SHIFT)) {
		if (target.segment->type != S_GROUP) {
		    offset += target.segment->grpOff;
		}
	    }

	    /*
	     * If the target was always a segment, not an external, we need
	     * to add the relocation value for the segment into the offset
	     * as well, in case the fixup's an FLT_OFFSET with a segment
	     * target -- it's the expected behaviour, and who are we to
	     * question society?
	     */
	    if ((fixdata & FD_TARGET) == TFM_SEGMENT) {
		offset += target.segment->nextOff - target.segment->foff;
	    }


	    switch (((fixLoc >> 8) & FLH_LOC_TYPE) >> FLH_LOC_TYPE_SHIFT){
		case FLT_LOW_BYTE:
		    /*
		     * Store the low byte of the offset in the fixup place.
		     */
		    offset += *(signed char *)fixme;

		    if (fixLoc & FL_SEG_REL) {
			*fixme = offset;
		    } else {
			*fixme = offset - (absFixOff + 1);
		    }
		    break;
		case FLT_FAR_PTR:
		{
		    byte    prevByte;

		    /*
		     * If the relocation is in the data portion of an lmem
		     * resource then use an object relocation.
		     */
		    if (sd->doObjReloc) {
			word oreloc;
			/*
			 * If the target is an lmem segment then do an UN_OPTR
			 * else do an UN_DD
			 */
			if (target.segment->combine == SEG_LMEM) {
			    /*
			     * Target is a lmem segment -> do an UN_OPTR:
			     * if (same segment)
			     *	ORS_CURRENT_BLOCK
			     * else
			     *	ORS_OWNING_GEODE << RID_SOURCE_OFFSET + resid
			     */
			    if (sd->pdata.resid == target.segment->pdata.resid)
			    {
				oreloc = ORS_CURRENT_BLOCK<<RID_SOURCE_OFFSET;
			    } else {
				oreloc = (ORS_OWNING_GEODE<<RID_SOURCE_OFFSET)+
				    	    target.segment->pdata.resid;
			    }
			    /*
			     * Fix the segment (we'll fall through to do the
			     * offset relocation also)
			     */
			    fixme[2] = oreloc & 0xff;
			    fixme[3] = (oreloc >> 8) & 0xff;
			} else {
			    /*
			     * If the target is the process class then this
			     * is a hack that actually wants to refer to
			     * the process handle
			     */
			    if (os == NULL) {
				/*
				 * This thing looks like a far call, but we
				 * haven't got a symbol to base the decision
				 * on.  See if we can find one at the address.
				 */
				MSObjLocateSymbol(target.segment,
					      offset+(fixme[0]|(fixme[1]<<8)),
					      &os,
					      &targetBlock);
			    }
			    if (os == NULL) {
				Pass2_RelocError(sd, fixOff,
						 "cannot unrelocate far pointer to segment %i in segment %i, as it doesn't point to an exported entry point for this geode",
						 target.segment->name,
						 sd->name);
				break;
			    }

			    if (((target.segment->combine == SEG_RESOURCE) ||
			         (target.segment->combine == SEG_PRIVATE) ||
			         (target.segment->combine == SEG_PUBLIC) ||
			         (target.segment->combine == SEG_STACK) ||
			         (target.segment->combine == SEG_COMMON)) &&
				(target.segment->pdata.resid ==
				 GH(execHeader.classResource)) &&
				(os->u.addrSym.address ==
				 GH(execHeader.classOffset)))
			    {
				/*
				 * Target is process class -- for now there
				 * is no way of getting the extra data
				 */
				oreloc = ORS_OWNING_GEODE<<RID_SOURCE_OFFSET;
			    	fixme[0] = 0;
			    	fixme[1] = 0;
			    	fixme[2] = oreloc & 0xff;
			    	fixme[3] = (oreloc >> 8) & 0xff;
			    } else {
				/*
				 * Target is not a lmem segment -> do an UN_DD:
				 * if (target is in a library)
				 *	ORS_LIBRARY << RID_SOURCE_OFFSET
				 *  	    	    	+ resid name
				 * else
				 *	ORS_OWNING_GEODE_ENTRY_POINT
				 *	    << RID_SOURCE_OFFSET + resid name
				 */
				word	entryNum;

				entryNum = 0; /* Be quiet, GCC (if leave
					       * loop w/o setting entryNum,
					       * we jump to error) */

				if (target.segment->combine == SEG_LIBRARY) {
				    oreloc = (ORS_LIBRARY<<RID_SOURCE_OFFSET) |
					libs[target.segment->pdata.library].lnum;
				    /*
				     * Add in the entry point number which is
				     * stored in the offset field on the target
				     * symbol
				     */
				    entryNum = os->u.addrSym.address;
				} else {
				    int	i;
				    int symOff;
				    genptr  osh;
				    MemHandle	mem;

				    VMInfo(symbols, targetBlock,
					   (word *)NULL,
					   &mem,
					   (VMID *)NULL);
				    MemInfo(mem, (genptr *)&osh, (word *)NULL);
				    symOff = (genptr)os - osh;

				    oreloc = ORS_OWNING_GEODE_ENTRY_POINT<<
							RID_SOURCE_OFFSET;
				    for (i = 0; i < numEPs; i++) {
					if (entryPoints[i].block==targetBlock &&
					    entryPoints[i].offset==symOff)
					{
					    entryNum = i;
					    break;
					}
				    }
				    if (i >= numEPs) {
					if (pass == 2) {
					    Pass2_RelocError(sd, fixOff,
							     "%i not exported in parameter file",
							     os->name);
					}
					retval = FALSE;
					goto error;
				    }
				}

			    	fixme[0] = oreloc & 0xff;
			    	fixme[1] = (oreloc >> 8) & 0xff;

			    	fixme[2] = entryNum & 0xff;
			    	fixme[3] = (entryNum >> 8) & 0xff;
			    }
			    /*
			     * Do not fall through to do the offset
			     * relocation since we've already dealt
			     * with it
			     */
			    break;
			}
			/*
			 * Don't "break" here because we need to fall through
			 * to do the offset relocation
			 */
		    } else {
			if (!(fixLoc & FL_SEG_REL)) {
			    if (pass == 2) {
				Pass2_RelocError(sd, fixOff,
						 "far-pointer relocations may "
						 "not be self-relative");
			    }
			    retval = FALSE;
			    goto error;
			}
			/*
			 * If the output format supports CALL relocations,
			 * see if the thing's a far call.
			 */
			if (pass == 2) {
			    if (((fixLoc & FL_OFFSET) == 0) && (fixOff != 0)) {
				(void)Out_Fetch(sd->nextOff + fixOff - 1,
						(void *)&prevByte,
						1);
			    } else if (fixLoc & FL_OFFSET) {
				prevByte = fixme[-1];
			    } else {
				prevByte = 0;
			    }

			    if (!(fileOps->flags & FILE_NOCALL) &&
				(prevByte == 0x9a))
			    {
                                if (os == NULL) {
                                    /*
				     * This thing looks like a far call, but we
				     * haven't got a symbol to base the decision
				     * on.  See if we can find one at the
				     * address.
				     */
				    MSObjLocateSymbol(target.segment,
                                                        offset+(fixme[0]|(fixme[1]<<8)),
							&os,
							&targetBlock);
                                }

				/*
				 * Byte before the far pointer is a far call
				 * opcode. See if the target of the relocation
				 * is a code symbol.
				 */
				if ((os != NULL) &&
				    ((os->type == OSYM_PROC) ||
				     (os->type == OSYM_LABEL) ||
				     (os->type == OSYM_LOCLABEL)))
				{
				    offset += fixme[0] | (fixme[1] << 8);

				    /*
				     * If the procedure may not be called,
				     * bitch.
				     */
				    if (os->u.proc.flags & OSYM_NO_CALL) {
					if (pass == 2) {
					    Pass2_RelocError(sd, fixOff,
							     "procedure %i may "
							     "not be called",
							     os->name);
					}
					retval = FALSE;
					goto error;
				    }

				    if (frame.segment == sd) {
					/*
					 * Convert to a CallFN followed by a NOP
					 * to avoid the kernel relocation that
					 * might get transformed into a software
					 * interrupt.
					 */
					if (fixLoc & FL_OFFSET) {
					    fixme[-1] = 0x0e; /* PUSH CS */
					} else {
					    /*
					     * The call opcode was in a previous
					     * record, so we have to put it out
					     * specially....
					     */
					    prevByte = 0x0e;
					    (void)Out_Block(sd->nextOff +
							    fixOff-1,
							    (void *)&prevByte,
							    1);
					}

					fixme[0] = 0xe8; /* CALL NEAR PTR */
					offset -= absFixOff + 3;
					fixme[1] = offset;
					fixme[2] = offset >> 8;
					fixme[3] = 0x90; /* NOP */

					sd->nrel -= 1; /* One fewer rtrel */
#if TEST_NRELS
					callfn += 1; /*XXX*/
#endif
					break;
				    }

				    /*
				     * Store the offset in the low word.
				     */
				    fixme[0] = offset;
				    fixme[1] = offset >> 8;

				    pass2_assert((nextRel != NULL), sd, fixOff);

#if 0
				    /* this is all now obsolete as we keep
				     * track of things better in pass1
				     * - jimmy 5/95
				     */

				    /*
				     * If the target's in a library and the
				     * fixup's at the start of the object
				     * record, we thought it would take two
				     * runtimes to fix the thing up, so correct
				     * for that now.
				     *
				     * 12/7/93: added check for routine
				     * having been published and incorporated,
				     * because in pass 1 we still thought we
				     * could use the thing from the library.
				     * 	    	    -- ardeb
				     */
				    if (((fixLoc & FL_OFFSET) == 0) &&
					((target.segment->combine==SEG_LIBRARY) ||
					 ((os->type == OSYM_PROC) &&
					  (os->u.proc.flags & OSYM_PROC_PUBLISHED))))
				    {
					sd->nrel -= 1;
				    }
#endif
				    if ((*fileOps->maprel)(OREL_CALL,
							   frame.segment,
							   nextRel,
							   sd,
							   fixOff,
							   (word *)fixme))
				    {
					nextRel = nextRel + fileOps->rtrelsize;
#if TEST_NRELS
					nrel++; /*XXX*/
#endif
				    } else {
					sd->nrel--;
				    }
				    /*
				     * We're done here.
				     */
				    break;
				}
				/*
				 * We used to decrement sd->nrel at this point,
				 * but we don't really want that, as we're still
				 * going to slap a segment relocation here.
				 */
			    }
			}
			/*
			 * Enter a segment relocation for the high part of the
			 * far pointer, unless the frame is absolute, in which
			 * case store the segment.
			 */
			if ((fixdata & FD_FRAME) ==
			    	    (FFM_ABSOLUTE<<FD_FRAME_SHIFT))
			{
			    fixme[2] = frame.absolute;
			    fixme[3] = frame.absolute >> 8;
			} else if (pass == 2) {
			    int 	relType;

			    pass2_assert((nextRel != NULL), sd, fixOff);
			    /*
			     * If the target is a lmem segment then do a handle
			     * relocation instead of a segment relocation
			     */
			    if (target.segment->combine == SEG_LMEM) {
				relType = OREL_HANDLE;
			    } else {
				relType = OREL_SEGMENT;
			    }
			    if ((target.segment->combine == SEG_LIBRARY) &&
				(os != NULL))
			    {
				/*
				 * If target is a library segment, we need
				 * to stuff the entry point number at fixme+2
				 * as well, so the kernel knows which segment
				 * to use...
				 */
				fixme[2] = os->u.addrSym.address;
				fixme[3] = os->u.addrSym.address >> 8;
			    }

			    if ((*fileOps->maprel)(relType,
						   frame.segment,
						   nextRel,
						   sd,
						   fixOff+2,
						   (word *)(fixme+2)))
			    {
				nextRel = nextRel +fileOps->rtrelsize;
#if TEST_NRELS
				nrel++;	/*XXX*/
#endif
			    } else {
				sd->nrel--;
			    }
			}
		    }
		}
		    /*FALLTHRU*/
                case FLT_LDRRES_OFF:
                    /*
                     * According to the docs I have seen, this is treated
                     * the same as FLT_OFFSET by the linker. -- mgroeber 7/19/00
                     */
                case FLT_OFFSET:
		    /*
		     * If the thing's a self-relative relocation to a procedure
		     * that doesn't want to be called, make sure the byte before
		     * the fixup isn't 0xe8 (a near call opcode) or complain
		     * XXX: what about OSYM_NO_JMP?
		     */
		    if ((pass == 2) &&
			(os != NULL) && (os->type == OSYM_PROC) &&
			(os->u.proc.flags & OSYM_NO_CALL) &&
                        ((((fixLoc >> 8) & (FLH_LOC_TYPE|FLH_SEG_REL)) ==
                          (FLT_OFFSET << FLH_LOC_TYPE_SHIFT)) ||
                         (((fixLoc >> 8) & (FLH_LOC_TYPE|FLH_SEG_REL)) ==
                          (FLT_LDRRES_OFF << FLH_LOC_TYPE_SHIFT))))
		    {
			byte	prevByte;

			if (((fixLoc & FL_OFFSET) == 0) && (fixOff != 0)) {
			    (void)Out_Fetch(sd->nextOff + fixOff - 1,
					    (void *)&prevByte,
					    1);
			} else if (fixLoc & FL_OFFSET) {
			    prevByte = fixme[-1];
			} else {
			    prevByte = 0;
			}

			if (prevByte == 0xe8) {
			    Pass2_RelocError(sd, fixOff,
					     "procedure %i may not be called",
					     os->name);
			    retval = FALSE;
			    goto error;
			}
		    }

		    /*
		     * Catch near calls or jumps between segments...
		     */
                    if ((((fixLoc >> 8) & (FLH_LOC_TYPE|FLH_SEG_REL)) ==
                          (FLT_OFFSET << FLH_LOC_TYPE_SHIFT) ||
                         ((fixLoc >> 8) & (FLH_LOC_TYPE|FLH_SEG_REL)) ==
                          (FLT_LDRRES_OFF << FLH_LOC_TYPE_SHIFT)) &&
			!Obj_CheckRelated(frame.segment, sd))
		    {
			if (pass == 2) {
			    if (os != NULL) {
				Pass2_RelocError(sd, fixOff,
						 "near call/jump to different segment (%i:%i)",
						 frame.segment->name,
						 os->name);
			    } else {
				Pass2_RelocError(sd, fixOff,
						 "near call/jump to different segment (%i)",
						 frame.segment->name);
			    }
			}
			retval = FALSE;
			goto error;
		    }

		    /*
		     * If the target's in a library, we'll need a run-time
		     * relocation for it.
		     */
		    if (target.segment->combine == SEG_LIBRARY) {
			if (pass == 2) {
			    pass2_assert((nextRel != NULL), sd, fixOff);
			    pass2_assert((os != NULL), sd, fixOff);
			} else {
			    assert(os != NULL);
			}

			/*
			 * Store the entry-point number in the place.
			 */
			fixme[0] = os->u.addrSym.address;
			fixme[1] = os->u.addrSym.address >> 8;

			if (pass == 2) {
			    if ((*fileOps->maprel)(OREL_OFFSET,
						   frame.segment,
						   nextRel,
						   sd,
						   fixOff,
						   (word *)fixme))
			    {
				nextRel = nextRel + fileOps->rtrelsize;
#if TEST_NRELS
				nrel++; /*XXX*/
#endif
			    } else {
				sd->nrel--;
			    }
			}
		    } else {
			/*
			 * Not in a library, so figure the final offset by
			 * adding in the value at fixme and dealing with the
			 * pc-relative nature of the fixup, if any.
			 */
			offset += fixme[0] | (fixme[1] << 8);

			if (!(fixLoc & FL_SEG_REL)) {
			    /*
			     * "PC" is assumed to be just after the fixup.
			     */
			    offset -= absFixOff+2;
			}

			fixme[0] = offset;
			fixme[1] = offset >> 8;
		    }
		    break;
		case FLT_SEGMENT:
		    /*
		     * Enter a segment relocation for the thing, unless the
		     * frame is absolute, in which case store the segment.
		     */
		    if ((fixdata & FD_FRAME) == (FFM_ABSOLUTE<<FD_FRAME_SHIFT))
		    {
			frame.absolute += fixme[0] | (fixme[1] << 8);

			fixme[0] = frame.absolute;
			fixme[1] = frame.absolute >> 8;
		    } else {
			int 	relType;

			if (pass == 2) {
			    pass2_assert((nextRel != NULL), sd, fixOff);
			}
			/*
			 * If the target is a lmem segment then do a handle
			 * relocation instead of a segment relocation, to
			 * make generating an optr from C easier.
			 */
			if (target.segment->combine == SEG_LMEM) {
			    relType = OREL_HANDLE;
			} else {
			    if (target.segment->combine == SEG_LIBRARY) {
			        /*
				 * If the thing's in a library, make sure its
				 * entry point number is stored at fixme
				 * for the kernel to use in its relocation.
				 */
				if (pass == 2) {
				    pass2_assert((os != NULL), sd, fixOff);
				} else {
				    assert(os != NULL);
				}

				/*
				 * Store the entry-point number in the place.
				 */
				fixme[0] = os->u.addrSym.address;
				fixme[1] = os->u.addrSym.address >> 8;
			    }
			    relType = OREL_SEGMENT;
			}
			if (pass == 2) {
			    if ((*fileOps->maprel)(relType,
						   frame.segment,
						   nextRel,
						   sd,
						   fixOff,
						   (word *)fixme))
			    {
				nextRel = nextRel + fileOps->rtrelsize;
#if TEST_NRELS
				nrel++; /*XXX*/
#endif
			    } else {
				sd->nrel--;
			    }
			}
		    }
		    break;
                case FLT_HIGH_BYTE:
		    if (pass == 2) {
			Pass2_RelocError(sd, fixOff,
					 "unsupported fixup type FLT_HIGH_BYTE");
		    }
		    retval = FALSE;
		    break;
	    }

	    error:		/* We also get here in the non-error case... */

#if TEST_NRELS
	    /*XXX*/
	    if (pass == 2) {
		printf("%04x %d %d\n", fixLoc & FL_OFFSET, nrel, callfn);
	    }
#endif

	    if (targetBlock) {
		VMUnlock(symbols, targetBlock);
	    }
	} else {
	    /*
	     * Defining a thread.
	     */
	    byte    fixdata = *bp++;
	    int	    thread = fixdata & TD_THREAD_NUM;

	    /*
	     * Merge the fixup method into the proper field of the .fixup
	     * field for the thread, then decode the following index into
	     * a MSFixData and mark the thread valid.
	     */
	    if (fixdata & TD_IS_FRAME) {
		msThreads[thread].fixup &= ~FD_FRAME;
		msThreads[thread].fixup |=
		    (fixdata & TD_METHOD) << (FD_FRAME_SHIFT - TD_METHOD_SHIFT);
		MSObj_DecodeFrameOrTarget((fixdata&TD_METHOD)>>TD_METHOD_SHIFT,
					  &bp,
					  &msThreads[thread].data[MST_FRAME]);
		msThreads[thread].valid |= 1 << MST_FRAME;
	    } else {
		msThreads[thread].fixup &= ~(TD_METHOD>>TD_METHOD_SHIFT);
		msThreads[thread].fixup |=
		    (fixdata & TD_METHOD) >> TD_METHOD_SHIFT;
		MSObj_DecodeFrameOrTarget((fixdata&TD_METHOD)>>TD_METHOD_SHIFT,
					  &bp,
					  &msThreads[thread].data[MST_TARGET]);
		msThreads[thread].valid |= 1 << MST_TARGET;
	    }
	}
    }

    if (nextRelPtr != NULL) {
	*nextRelPtr = nextRel;
    }

    return(retval);
}


/***********************************************************************
 *				MSObj_CalcIDataSize
 ***********************************************************************
 * SYNOPSIS:	    Calculate the number of bytes needed to hold the
 *	    	    expansion of the passed repeat block.
 * CALLED BY:	    EXTERNAL, self
 * RETURN:	    number of bytes
 * SIDE EFFECTS:    *bufPtr is advanced beyond this block.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/31/91		Initial Revision
 *
 ***********************************************************************/
word
MSObj_CalcIDataSize(byte   **bufPtr)
{
    word    repCount;
    word    blockCount;
    word    contentSize;

    MSObj_GetWord(repCount, *bufPtr);
    MSObj_GetWord(blockCount, *bufPtr);

    if (blockCount == 0) {
	/*
	 * No nested blocks. Advance *bufPtr over the bytes after fetching
	 * out the number of bytes in the content field.
	 */
	contentSize = **bufPtr;
	*bufPtr += contentSize + 1;
    } else {
	int 	j;

	contentSize = 0;
	/*
	 * Run through the blocks inside this one to find the total size
	 * of this block.
	 */
	for (j = blockCount; j > 0; j--) {

	    contentSize += MSObj_CalcIDataSize(bufPtr);
	}
    }
    return (repCount * contentSize);
}


/***********************************************************************
 *				MSObj_ExpandIData
 ***********************************************************************
 * SYNOPSIS:	    Expand an iterated data block
 * CALLED BY:	    EXTERNAL, self
 * RETURN:	    nothing
 * SIDE EFFECTS:    *dataPtr and *bufPtr advanced
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/31/91		Initial Revision
 *
 ***********************************************************************/
void
MSObj_ExpandIData(byte	    **dataPtr,	    /* Iterated data block */
		   byte	    **bufPtr)	    /* Destination buffer */
{
    word    repCount;
    word    blockCount;
    word    contentSize;

    MSObj_GetWord(repCount, *dataPtr);
    MSObj_GetWord(blockCount, *dataPtr);

    if (blockCount == 0) {
	/*
	 * No nested blocks. Copy the data to the buffer and advance both
	 * pointers.
	 */
	contentSize = **dataPtr;
	bcopy(*dataPtr + 1, *bufPtr, contentSize);
	*dataPtr += contentSize + 1;
	*bufPtr += contentSize;
    } else {
	int 	j;
	byte	*base;
	unsigned len;

	/*
	 * Record the base of the block to be repeated.
	 */
	base = *bufPtr;

	/*
	 * Run through the blocks inside this one to build up the block
	 * to be repeated.
	 */
	for (j = blockCount; j > 0; j--) {
	    MSObj_ExpandIData(dataPtr, bufPtr);
	}
	/*
	 * Now replicate all those bytes the indicated number of times,
	 * subtracting 1 from repCount at the outset since we've already
	 * got one copy.
	 */
	len = *bufPtr - base;
	for (j = repCount - 1; j > 0; j--) {
	    bcopy(base, *bufPtr, len);
	    *bufPtr += len;
	}
    }
}
