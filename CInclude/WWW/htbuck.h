/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Geos WWW Library
 * MODULE:	  htbuck
 * FILE:	  htbuck.h
 *
 * AUTHOR:  	  Kok Kin Kee: May 24, 1997
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	kkee    	5/24/97   	Initial version
 *
 * DESCRIPTION:
 *
 *	Memory buckets. Implements FIFO for writing and reading. That
 *      is; write to end of list and read from front of list.
 *
 *	$Id: htbuck.h,v 1.3.6.1 97/09/05 11:30:04 jeremyb Exp $
 *
 ***********************************************************************/
#ifndef _HTBUCK_H_
#define _HTBUCK_H_

#include <WWW/htmem.h>

#define HTBucketHandle HTMemHandle
#define HTBUCKET_SIZE 512               /* each bucket is 512 bytes */

/*
 * A memory bucket as sequential queue.
 */
typedef struct {
    HTMemHandle  next;                     /* A HTBucketItem */
    word         rear;                     /* Index for writing data */
    word         front;                    /* Index for reading data */
    byte         data[HTBUCKET_SIZE];      /* Must be at the end */
} HTBucketItem;

/*
 * List of HTBucketItems. Read from head and write to tail.
 */
typedef struct {
    HTMemHandle head;                      /* Singly linked list */
    HTMemHandle tail;
    
    /* 
     * For optimization, head & tail are always locked. 
     */
    HTBucketItem *headPtr;    /* Valid if HTBucket->head is valid */
    HTBucketItem *tailPtr;    /* Valid if HTBucket->tail is valid */
} HTBucket;



extern HTBucketHandle _far _pascal HTBucketAlloc ();

extern void _far _pascal HTBucketFree (HTBucketHandle htbuck);

extern word _far _pascal
    HTBucketPutBlock (HTBucketHandle htbuck, const byte *data, word len);

extern word _far _pascal
    HTBucketFlush(HTBucketHandle htbuck);

Boolean _far _pascal HTBucketGetByte (HTBucketHandle htbuck, byte *bt);

word _far _pascal HTBucketGetChunk (HTBucketHandle htbuck, HTMemHandle *data,
				     word len);

#ifdef __HIGHC__
pragma Alias(HTBucketAlloc, "HTBUCKETALLOC");
pragma Alias(HTBucketFree, "HTBUCKETFREE");
pragma Alias(HTBucketPutBlock, "HTBUCKETPUTBLOCK");
pragma Alias(HTBucketFlush, "HTBUCKETFLUSH");
pragma Alias(HTBucketGetByte, "HTBUCKETGETBYTE");
pragma Alias(HTBucketGetChunk, "HTBUCKETGETCHUNK");
#endif

#endif /* _HTBUCK_H_ */
