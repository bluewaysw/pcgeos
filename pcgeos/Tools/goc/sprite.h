/*
 * sprite.h --
 *
 * Common constants and type declarations for Sprite.
 *
 * Copyright 1985 Regents of the University of California
 * All rights reserved.
 *
 *
 * $Id: sprite.h,v 1.1 92/07/27 12:23:20 jimmy Exp $ SPRITE (Berkeley)
 */

#ifndef _SPRITE
#define _SPRITE


#ifndef TRUE
#define TRUE	1
#endif TRUE
#ifndef FALSE
#define FALSE	0
#endif FALSE

/*
 * Functions that must return a status can return a ReturnStatus to
 * indicate success or type of failure.
 */

typedef int  ReturnStatus;

/*
 * The following statuses overlap with the first 2 generic statuses 
 * defined in status.h:
 *
 * SUCCESS			There was no error.
 * FAILURE			There was a general error.
 */

#define	SUCCESS			0x00000000
#define	FAILURE			0x00000001


/*
 * A nil pointer must be something that will cause an exception if 
 * referenced.  There are two nils: the kernels nil and the nil used
 * by user processes.
 */

#define NIL 		0xFFFFFFFF
#define USER_NIL 	0
#ifndef NULL
#define NULL	 	0
#endif NULL


/*
 * ClientData is an uninterpreted word.  It is defined as an int so that
 * kdbx will not interpret client data as a string.  Unlike an "Address",
 * client data will generally not be used in arithmetic.
 */

typedef int *ClientData;

#ifdef notdef
#include "status.h"
#endif

extern void *Malloc();

#endif _SPRITE
