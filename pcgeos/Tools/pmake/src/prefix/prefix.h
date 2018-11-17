/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Main Header File
 * FILE:	  prefix.h
 *
 * AUTHOR:  	  Adam de Boor: Jul  5, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 5/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Main header file for prefix daemon
 *
 *
 * 	$Id: prefix.h,v 1.7 89/10/10 00:36:18 adam Exp $
 *
 * 	Copyright (c) Berkeley Softworks 1989
 * 	Copyright (c) Adam de Boor 1989
 *
 * 	Permission to use, copy, modify, and distribute this
 * 	software and its documentation for any non-commercial purpose
 *	and without fee is hereby granted, provided that the above copyright
 * 	notice appears in all copies.  Neither Berkeley Softworks nor
 * 	Adam de Boor makes any representations about the suitability of this
 * 	software for any purpose.  It is provided "as is" without
 * 	express or implied warranty.
 *
 ***********************************************************************/
#ifndef _PREFIX_H_
#define _PREFIX_H_

#include    <stdio.h>
#include    <sys/types.h>
#include    <sys/stat.h>
#include    <netinet/in.h>

/*
 * NFS definitions...Map sun RPC codes with the same name as ours into
 * other codes...
 */
#define	    RPC_SUCCESS     SUNRPC_SUCCESS
#define	    RPC_CANTSEND    SUNRPC_CANTSEND
#define	    RPC_TIMEDOUT    SUNRPC_TIMEDOUT
#define	    RPC_TOOBIG	    SUNRPC_TOOBIG
#define	    RPC_NOPROC	    SUNRPC_NOPROC
#define	    RPC_ACCESS	    SUNRPC_ACCESS
#define	    RPC_BADARGS	    SUNRPC_BADARGS
#define	    RPC_SYSTEMERR   SUNRPC_SYSTEMERR

#include    <sys/socket.h>
#include    <rpc/rpc.h>
#include    <sys/ioctl.h>
#include    <sys/dir.h>
#include    <sys/time.h>
#include    <errno.h>
extern int  errno;
#include    <nfs/nfs.h>
#define NFS

#undef	    RPC_SUCCESS
#undef	    RPC_CANTSEND
#undef	    RPC_TIMEDOUT
#undef	    RPC_TOOBIG
#undef	    RPC_NOPROC
#undef	    RPC_ACCESS
#undef	    RPC_BADARGS
#undef	    RPC_SYSTEMERR

/*
 * Macro to deal with incompatible calling conventions between gcc and cc on
 * a sparc (gcc passes the address in a register, since the structure is
 * small enough, while cc still passes the address).
 */
#if defined(__GNUC__) && defined(sparc)
#define InetNtoA(addr)	inet_ntoa(&(addr))
#else
#define InetNtoA(addr)	inet_ntoa(addr)
#endif

/*
 * Need the Lst library definitions for declarations here...
 * Later include files like to define SUCCESS and FAILURE as enums, so...
 */
#include    "lst.h"
#undef SUCCESS
#undef FAILURE

/*
 * Port on which the prefix daemon listens
 */
#define PREFIX_PORT 	9127

#define PREFIX_DEBUG_SEARCH 	0x0001	/* Print out info about the search for
					 * prefixes */
#define PREFIX_DEBUG_SERVER 	0x0002	/* Print out info about what the
					 * kernel is asking of us as a server */

/*
 * Mount point to which prefixes are referred when they should be mounted
 */
#define MOUNT_DIR	"/.prefixmnt"

/*
 * Name by which the kernel knows us, in case it wants to complain about
 * a prefix.
 */
#define MOUNT_NAME  	"prefix"

/*
 * RPC procedures we support/use
 */
#define PREFIX_PING 	    0  	    /* See if anyone's home */
#define PREFIX_LOCATE	    1  	    /* Find server of a prefix.
				     * IN: prefix,
				     * OUT: local path */
#define PREFIX_EXPORT	    2  	    /* Export a prefix to the world.
				     * IN: prefix and local path
				     * OUT: nothing */
#define PREFIX_IMPORT	    3  	    /* Import a prefix, but don't mount yet
				     * IN: prefix
				     * OUT: nothing */
#define PREFIX_IMPORT_ROOT  4	    /* Import a tree of prefixes
				     * IN: root of tree
				     * OUT: nothing */
#define PREFIX_DELETE	    5	    /* Delete a prefix/tree (imports only)
				     * IN: prefix
				     * OUT: "Ok" or an error message */
#define PREFIX_DUMP 	    6	    /* Return info about all prefixes
				     * IN: buffer size (short)
				     * OUT: complex buffer described in
				     * DumpPrefix header. */
#define PREFIX_MOUNT   	    7	    /* Mount a prefix on a remote system
				     * IN: prefix descriptor
				     * OUT: 1/0 (long) */
#define PREFIX_MOUNT_LOCAL  8	    /* Mount a prefix on the prefix daemon.
				     * IN: address, handle and path
				     * OUT: 1/0 (long) */
#define PREFIX_UNMOUNT 	    9	    /* Unmount a prefix from a remote system
				     * IN: prefix descriptor
				     * OUT: 1/0 (long) */
#define PREFIX_UNMOUNT_LOCAL 10	    /* Unmount a prefix mounted on ourselves
				     * IN: path
				     * OUT: 1/0 (long) */
#define PREFIX_DEBUG	    11	    /* Turn debugging on or off.
				     * IN: PREFIX_DEBUG_* (long)
				     * OUT: Nothing */
#define PREFIX_NOEXPORT	    12	    /* Stop exporting a prefix
				     * IN: prefix
				     * OUT: "Ok" or an error message */
#define PREFIX_SEARCH_NET   13	    /* Record another network on which to
				     * broadcast when searching for a prefix.
				     * IN: sockaddr_in
				     * OUT: Nothing */
#define PREFIX_EXPORT_LOCAL 14 	    /* Export a prefix to the local nets.
				     * IN: prefix and local path
				     * OUT: nothing */

/*
 * Error codes to supplement the RPC system's own.
 */
#define DUPLICATE_PREFIX	128 /* Error returned by IMPORT and IMPORT_ROOT
				     * if indicated prefix already imported */
#define PREFIX_LOCKED		129 /* Can't do anything with prefix since it's
				     * locked. */

/*
 * Structure describing an imported prefix
 */
typedef struct _Prefix {
    char		*path;		/* Mount point */
    int	    	    	generation; 	/* Generation number for descriptor */

    /*
     * Server info
     */
    struct sockaddr_in 	server;    	/* Server for prefix */
    char    	    	*serverName;	/* Name of server (for entry into
					 * mount table) NULL if not known */
    char    	    	*remote;    	/* Path on server */

    /*
     * Other info
     */
    struct nfsfattr	attr;		/* Statistics before we overrode it */
    short		flags;		/* Flags for mount point */
#define PREFIX_ROOT 	    0x0001 	    /* Set if prefix is a root (i.e.
					     * not a real prefix, but anything
					     * immediately under it is a viable
					     * prefix) */
#define PREFIX_TEMP 	    0x0002 	    /* Temporary prefix created by
					     * looking in a TREE directory */
#define PREFIX_MOUNTED	    0x0004	    /* Set if prefix mounted on
					     * remote server */
#define PREFIX_INITIALIZED  0x0008  	    /* Set if prefix has been initial-
					     * ized (i.e. mounted on ourselves)
					     */ 
    short		locks;	        /* Count of locks on prefix. When
					 * prefix is locked, nothing
					 * should be done with it. Set
					 * when prefix is (a) being
					 * mounted, (b) being unmounted or
					 * (c) being sought. In all these
					 * cases, we are vulnerable due
					 * to the multi-threaded rpc
					 * system */

    struct _Prefix  	*next;   	/* Next/first temporary prefix. Used
					 * for READDIR request on a TREE
					 * prefix */

    void		*unmount;	/* Event for unmounting the thing */

    char    	    	*options;   	/* Mount options */
    char    	    	*servOpts;  	/* Mount options from the server */
} Prefix;

/*
 * Macros for checking/altering the lock on a prefix. A prefix is locked during
 * a state change: from mounted to unmounted, vice versa, or when it is being
 * sought. In all these cases, we pass control to the Rpc module while the
 * prefix is in flux. While in the Rpc module, we could be given another
 * request to handle for the same prefix. In many cases, doing so will lead
 * to an inconsistent state and, sooner or later, death. Any request that
 * encounters a locked prefix is dropped on the floor to allow the completion
 * of the request that locked the prefix to occur as soon as possible.
 * Were this really multi-threaded, the request could block until the lock
 * was removed. Unfortunately, we can only be a single thread (excluding the
 * child process, of course), so we must return with the request unhandled
 * and rely on the kernel to resubmit later.
 */
#define PrefixLock(pp)	((pp)->locks++)
#define PrefixUnlock(pp) ((pp)->locks--)
#define PrefixIsLocked(pp) ((pp)->locks != 0)

#define PREFIX_STALE	((Prefix *)-1)

/*
 * General file-handle structure returned/passed to kernel. We are given
 * 32 bytes to do with as we will. It doesn't matter what we put here
 * as long as the data will uniquely identify a file. The client side
 * makes absolutely no assumptions as to what is in a file handle,
 * performing byte-by-byte comparisons between two handles when searching
 * for a file.
 *
 * We separate the handles we return into three categories:
 *	regular:    describes an imported prefix.
 *	lookup:	    when a file is looked up in a prefix, a token
 *	    	    is created giving the name of the file and the
 *	    	    prefix in which it was sought. A pointer to this
 *	    	    token is returned with a "lookup" handle
 *	special:    the MOUNT_DIR to which the kernel is referred when a
 *	    	    prefix needs to be mounted. Should we ever need another
 *	    	    special directory (I don't anticipate it), we've got 28
 *	    	    more bytes to play with.
 *
 * Note that we don't need any special XDR routine for the encoding/decoding
 * of the handle, since the client pays no attention to the contents and
 * we'll always get it back the same way we sent it out, so it'll be in the
 * correct byte-order. Besides which, we only talk to the local kernel,
 * so how can there possibly be byte-order problems?
 *
 * Note that both prefixes and lookup tokens have a "generation" number.
 * Once allocated, a Prefix or LookupToken structure is never returned
 * to the general memory pool. This allows us to increase the generation
 * number when the structure is "freed" and detect an attempt by the kernel
 * to use a stale handle. Were it not for this pooling and the generation
 * number, we could very easily free a prefix, re-allocate it and have
 * the kernel reference the re-allocated structure and we wouldn't be
 * aware of it. This way, we can detect such mismatches and report an error
 * properly.
 */
typedef enum {
    PH_REGULAR,	    	/* Regular prefix handle */
    PH_LOOKUP,	    	/* Lookup inside a prefix */
    PH_SPECIAL,	    	/* Special mount directory */
} HandleType;

typedef union {
    char    	buf[NFS_FHSIZE];	    /* For proper sizing */
    HandleType	type;
    struct {
	HandleType  	    type;   	/* PH_REGULAR */
	int 	    	    generation; /* Generation number expected in
					 * prefix */
	Prefix	    	    *pp;    	/* Prefix involved */
    }	rd;
    struct {
	HandleType  	    type;   	/* PH_LOOKUP */
	int 	    	    generation;	/* Generation number expected in
					 * lookup token */
	struct _LookupToken *ltp;
    }	ld;
    struct {
	HandleType  	    type;   	/* PH_SPECIAL */
    }	sd;
} PrefixHandle;

/*
 * Number of seconds between attempts to unmount a prefix (10 minutes)
 */
#define UNMOUNT_INTERVAL    600

/******************************************************************************
 *
 *			      EXTERNALS
 *
 *****************************************************************************/

/* main.c */
/*
 * List that keeps track of prefixes.
 */
extern Lst	    prefixes;

/*
 * Miscellaneous variables
 */
extern struct sockaddr_in prefixMountAddr;  /* Address of our prefix NFS server
					     * socket */

extern struct nfsfattr  link_attr;  	/* Attributes for all symbolic links
					 * we return */

extern int  	    prefixSock;	/* Socket we use to communicate with other
				 * prefix daemons */
extern int  	    quiet;  	/* Don't spew regular messages to the console.
				 * Just spew errors */

extern struct sockaddr_in   searchNets[];   /* Networks on which to search for
					     * the server of a prefix */
extern unsigned	    	    numSearchNets;  /* Number of networks on which
					     * to search */

/*
 * Allocation/freeing of physical Prefix records.
 */
extern Prefix	    *AllocPrefix();
extern void 	    FreePrefix();
/*
 * Converts a pointer to an NFS file handle into a Prefix. Returns
 * PREFIX_STALE if handle is stale.
 */
extern Prefix	    *HandleToPrefix();
/*
 * Convert a Prefix into an NFS file handle.
 */
extern void 	    PrefixToHandle();
/*
 * Converts a path name to a Prefix
 */
extern Prefix	    *NameToPrefix();

extern void 	    Message();		    /* Write to console */
extern void 	    dprintf();		    /* Write debug info to console */
extern int  	    debug;  	    	    /* Flag saying whether debug info
					     * will be printed */

/* mount.c */
extern void 	    Mount_Init();	    /* Initialize Mount stuff */
extern int  	    Mount_Unmount();	    /* Unmount a prefix */
extern int  	    Mount_MountRoot();	    /* Mount the special MOUNT_DIR */

/* export.c */
extern void 	    Export_Init();	    /* Initialize Export stuff */
extern void 	    Export_Send();	    /* Tell local daemon to export */
extern Boolean	    Export_IsExported();    /* See if prefix is exported */

/* import.c */
extern void 	    Import_Init();	    /* Initialize Import stuff */
extern int 	    Import_MountPrefix();   /* Mount prefix on ourselves */
extern Prefix	    *Import_CreatePrefix(); /* Create a new Prefix */
extern void 	    Import_DeletePrefix();  /* Delete an existing prefix */

/* child.c */
extern int  	    Child_Init();   	    /* Initialize Child process */
extern int  	    Child_Call();   	    /* Call something in the child */
extern int  	    Child_MountSpecial();   /* Mount a special directory */
extern void 	    Child_Kill();   	    /* Kill the child process */

#endif /* _PREFIX_H_ */
