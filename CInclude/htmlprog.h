/***********************************************************************
 *
 * PROJECT:       GPCBrow
 * FILE:          htmlprog.h
 *
 * DESCRIPTION:   Progressive loading from a data stream
 *
 *                Moved into a file of its own to allow including it
 *                into ijgjpeg without most of the Geos-specific
 *                baggage...
 *
 ***********************************************************************/

#ifndef __HTMLPROG_H
#define __HTMLPROG_H

typedef enum {
    LPCT_OPEN,           /* new loading data stream */
    LPCT_READ,           /* read from data stream,
			    pass: buffer, bufSize,
			    return: bytes read */
    LPCT_WRITE,          /* write to data stream,
			    pass: buffer, bufSize */
    LPCT_PEEK,           /* peek at data stream,
			    pass: buffer, bufSize,
			    return: bytes read */
    LPCT_FLUSH_FIRST,    /* flush start of data,
			    pass: bufSize */
    LPCT_RESET_STREAM_STATE,  /* reset stream state */
    LPCT_CLOSE,           /* finish writing to data stream */
	LPCT_PRE_READ		/* just as read but keeps the data,
						 * so we can go back by flush */
} LoadProgressCallbackType;

typedef enum {
    LPSS_EMPTY,            /* stream empty */
    LPSS_FIRST_PACKET,     /* start data */
    LPSS_MORE_DATA         /* more data */
} LoadProgressStreamState;

typedef struct {
    word LPD_importSync;        /* synchronizes fetch and import threads */
    word LPD_loadThread;	/* identifier of loading thread */
    void _pascal *LPD_callback; /* loading progress callback routine */
    optr LPD_textObj;           /* text obj to receive data */
    TCHAR LPD_mimeType[MIME_MAXBUF];		/* mime type */
    word LPD_nameT;		/* NameToken of data being fetched */
/* info about data being loaded: data is held in huge array, supports one
   writer and one reader, writer appends data to huge array, reader pulls
   data from beginning and deletes it from huge array */
    word LPD_sem;               /* to synchronize reader and writer */
    word LPD_emptyQueue;        /* block on this when no data avail to read */
    /* the following are changed by the load thread, so cannot be used from
       other threads */
    word LPD_dataFile;          /* VM file containing data stream */
    word LPD_dataStream;        /* VM block handle of data stream */
    dword LPD_bytesAvail;       /* bytes available to read */
    dword LPD_preReadOffset;    /* bytes already read */
    word LPD_fileDone;          /* finished writing */
    LoadProgressStreamState LPD_streamState;       /* data stream state */
    dword LPD_updateTime;       /* last notification for LPCT_WRITE */
} LoadProgressData;

#define _LoadProgressParams_ LoadProgressData *loadProgressDataP

typedef word _pascal _export proc_LoadProgressCallback(_LoadProgressParams_,
				       LoadProgressCallbackType callbackType,
				       void *buffer,
				       word bufSize);
typedef word _pascal pcfm_LoadProgressCallback(_LoadProgressParams_,
				       LoadProgressCallbackType callbackType,
				       void *buffer,
				       word bufSize,
				       void *pf);

#endif
