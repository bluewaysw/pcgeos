/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  queue.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May 24, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/24/96   	Initial version
 *
 * DESCRIPTION:
 *	Interface to the simple queue routines.
 *
 *
 * 	$Id: queue.h,v 1.1 96/05/24 20:46:48 jacob Exp $
 *
 ***********************************************************************/
#ifndef _COMPAT_QUEUE_H_
#define _COMPAT_QUEUE_H_

#ifndef HAVE_QUEUE

struct qelem {
    struct qelem *q_forw;
    struct qelem *q_back;
};

extern void insque(struct qelem *elem, struct qelem *pred);
extern void remque(struct qelem *elem);

#endif /* !HAVE_QUEUE */

#endif /* _COMPAT_QUEUE_H_ */
