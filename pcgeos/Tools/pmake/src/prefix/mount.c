/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Mounting Routines
 * FILE:	  mount.c
 *
 * AUTHOR:  	  Adam de Boor: Jul  5, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Mount_Init  	    Initialize the module
 *	Mount_Unmount	    Unmount an individual prefix.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 5/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to deal with mounting a prefix
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
#ifndef lint
static char *rcsid =
"$Id: mount.c,v 1.10 92/10/26 10:15:21 adam Exp $";
#endif lint

#include    "prefix.h"
#include    "rpc.h"
#include    "sunrpc.h"

static int  	    	mountSock;  /* Socket over which NFS requests for
				     * MOUNT_DIR arrive */

static struct nfsfattr  mattr; 	    /* Statistics for the mount directory */

/***********************************************************************
 *				Mount_Unmount
 ***********************************************************************
 * SYNOPSIS:	    Attempt to unmount a single prefix
 *		    THE PREFIX SHOULD HAVE BEEN CHECKED FOR LOCKS BEFORE
 *		    CALLING THIS PROCEDURE.
 * CALLED BY:	    ImportDelete, MountUnmountPrefix
 * RETURN:	    0 if failed
 * SIDE EFFECTS:    The node is shifted onto the prefixes list if
 *	    	    unmounted.
 *	    	    The serverName and remote fields are freed and
 *	    	    NULLed.
 *	    	    The unmount event is deleted and the field zeroed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
int
Mount_Unmount(pp, answerPtr)
    Prefix  	*pp;	    	/* Prefix to unmount */
    char    	**answerPtr;	/* Place to store failure message */
{
    if (Child_Call(pp, PREFIX_UNMOUNT)) {
	pp->flags &= ~PREFIX_MOUNTED;

	/*
	 * Nuke server data.
	 */
	free(pp->serverName);
	free(pp->remote);
	free(pp->servOpts);
	pp->serverName = pp->remote = pp->servOpts = (char *)NULL;

	/*
	 * Delete the event for unmounting it...
	 */
	if (pp->unmount) {
	    Rpc_EventDelete(pp->unmount);
	    pp->unmount = (Rpc_Event)NULL;
	}
	/*
	 * Announce our success
	 */
	return(1);
    } else {
	*answerPtr = "prefix busy";
	return(0);
    }
}


/***********************************************************************
 *				MountUnmountPrefix
 ***********************************************************************
 * SYNOPSIS:	    Attempt to remove a prefix.
 * CALLED BY:	    Rpc event
 * RETURN:	    FALSE (no need to stay awake)
 * SIDE EFFECTS:    If the prefix is unmounted it is either moved
 *	    	    back to the prefixes list and the mount point
 *	    	    taken over or, if the prefix is labeled as
 *	    	    temporary, the prefix is freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 6/89		Initial Revision
 *
 ***********************************************************************/
static int
MountUnmountPrefix(pp, ev)
    Prefix  	*pp;	    /* Prefix to attempt to unmount */
    Rpc_Event	ev; 	    /* Event that caused us to be called */
{
    char    	*reason;

    dprintf("unmount(%s)...", pp->path);

    if (PrefixIsLocked(pp)) {
	dprintf("locked\n");
    } else if (!Mount_Unmount(pp, &reason)) {
	/*
	 * Still active -- leave it alone until the next interval
	 * expires.
	 */
	dprintf("%s\n", reason);
    } else if ((pp->flags & PREFIX_TEMP) == 0) {
	/*
	 * Permanent prefix -- remount it on ourselves.
	 */
	dprintf("successful: remounting prefix\n");
	Import_MountPrefix(pp);
    } else {
	dprintf("successful\n");
    }
}
	    


/***********************************************************************
 *				MountNullReq
 ***********************************************************************
 * SYNOPSIS:	    Let the caller know we're alive
 * CALLED BY:	    RFS_NULL
 * RETURN:	    SUNRPC_SUCCESS
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
MountNullReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    void	    	*args;	    	/* Arguments passed */
    void	    	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    return(SUNRPC_SUCCESS);
}

/***********************************************************************
 *				MountGetAttrReq
 ***********************************************************************
 * SYNOPSIS:	    Handle a GETATTR either on an entry we were given
 *	    	    by ImportReadLinkReq, or on the root of the
 *	    	    system itself.
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
MountGetAttrReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    PrefixHandle    	*args;	    	/* Arguments passed */
    struct nfsattrstat	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix  	    	*pp;

    if (args->type == PH_SPECIAL) {
	/*
	 * Need to tell the kernel this thing's a directory...
	 */
	dprintf("GETATTR(%s)\n", MOUNT_DIR);
	
	res->ns_status 	    = NFS_OK;
	res->ns_attr	    = mattr;
    } else {
	pp = HandleToPrefix((fhandle_t *)args);
    
	if (pp == PREFIX_STALE) {
	    res->ns_status = NFSERR_STALE;
	} else {
	    dprintf("MGETATTR(%s)\n", pp->path);
	
	    res->ns_status = NFS_OK;
	    /*
	     * In this "directory", any other file is a symbolic
	     * link back to its real prefix.
	     */
	    res->ns_attr = link_attr;
	    res->ns_attr.na_size = strlen(pp->path);
	    res->ns_attr.na_blocksize = pp->attr.na_blocksize;
	}
    }
    return(SUNRPC_SUCCESS);
}

/***********************************************************************
 *				MountReadLinkReq
 ***********************************************************************
 * SYNOPSIS:	    Read one of our "symbolic links" -- this is our
 *	    	    signal to actually mount a prefix.
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS if prefix mounted, SUNRPC_SYSTEMERR
 *	    	    if not.
 * SIDE EFFECTS:    prefix is mounted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
MountReadLinkReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    fhandle_t	    	*args;	    	/* Arguments passed */
    struct nfsrdlnres	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix  	    	*pp;
    LstNode	    	ln;
    struct sockaddr_in  sin;
    struct timeval	retry;
    
    pp = HandleToPrefix(args);

    dprintf("MREADLINK: ");
    if (pp == PREFIX_STALE) {
	dprintf("STALE\n");
	res->rl_status = NFSERR_STALE;
    } else if (PrefixIsLocked(pp)) {
	/*
	 * If prefix is in flux, we don't want to try and mount it -- just
	 * drop the request on the floor. Hopefully, when the kernel
	 * retransmits its request the prefix will be stable again.
	 *
	 * Note that we can't just hang out here, as then the pending
	 * request that we interrupted in an earlier frame won't be returned
	 * to...
	 */
	dprintf("LOCKED\n");
	return(SUNRPC_DONTRESPOND);
    } else if (pp->serverName == NULL) {
	/*
	 * Couldn't find the server -- pretend there's nothing
	 * here.
	 */
	dprintf("server for '%s' unknown\n", pp->path);
	res->rl_status = NFSERR_NOENT;
    } else if (pp != NULL) {
	dprintf("MREADLINK(%s)\n", pp->path);
	
	PrefixLock(pp);

	res->rl_status = NFS_OK;
	
	if ((pp->flags & PREFIX_MOUNTED) == 0) {
	    /*
	     * Unmount our prefix and mount the real one.
	     * Note that Child_Call takes care of any necessary locks on
	     * the prefix.
	     */
	    struct timeval	unmountTime;
	    
	    if (pp->flags & PREFIX_TEMP) {
		dprintf("%s: nothing to unmount\n", pp->path);
	    } else {
		dprintf("unmount %s...", pp->path);
		if (!Child_Call(pp, PREFIX_UNMOUNT_LOCAL)) {
		    PrefixUnlock(pp);
		    return(RPC_SYSTEMERROR);
		}
		dprintf("successful\n");
	    }
	    dprintf("mount %s from %s...", pp->remote, pp->serverName);
	    
	    if (!Child_Call(pp, PREFIX_MOUNT)) {
		/*
		 * Re-mount ourselves, if necessary, so the
		 * user can try again later.
		 */
		if ((pp->flags & PREFIX_TEMP) == 0) {
		    Import_MountPrefix(pp);
		}
		PrefixUnlock(pp);
		return (RPC_SYSTEMERROR);
	    } else {
		pp->flags |= PREFIX_MOUNTED;
	    }
	    
	    dprintf("successful\n");
	    
	    /*
	     * Create event for unmounting this prefix.
	     */
	    unmountTime.tv_sec = UNMOUNT_INTERVAL;
	    unmountTime.tv_usec = 0;
	    
	    pp->unmount = Rpc_EventCreate(&unmountTime,
					  MountUnmountPrefix,
					  (Rpc_Opaque)pp);
	} else {
	    dprintf("already mounted\n");
	}
	
	PrefixUnlock(pp);

	/*
	 * Return a symbolic link back to the prefix...
	 * Sets up return value at the end of the nfsrdlnres
	 */
	res->rl_count = strlen(pp->path);
	res = (struct nfsrdlnres *)realloc(res, sizeof(*res)+res->rl_count);
	*resPtr = (void *)res;
	res->rl_data = (char *)(res+1);
	bcopy(pp->path, res->rl_data, res->rl_count);
    } else {
	dprintf("pp == NULL\n");
	res->rl_status = NFSERR_NOENT;
    }

    return(SUNRPC_SUCCESS);
}
    

/***********************************************************************
 *				MountStatFSReq
 ***********************************************************************
 * SYNOPSIS:	    Another bogus STATFS handler, since this filesystem
 *	    	    doesn't exist either
 * CALLED BY:	    SunRpc for RFS_STATFS
 * RETURN:	    SUNRPC_SUCCESS
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
MountStatFSReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    fhandle_t	    	*args;	    	/* Arguments passed */
    struct nfsstatfs	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    dprintf("STATFS(%s)\n", MOUNT_DIR);
    
    bzero(res, sizeof(*res));
    
    /*
     * Return bogus information for the filesystem for now
     */
    res->fs_status = NFS_OK;
    res->fs_tsize = res->fs_bsize = 8192;
    res->fs_blocks = 1;
    res->fs_bfree = 0;
    res->fs_bavail = 0;

    return(SUNRPC_SUCCESS);
}

/***********************************************************************
 *				MountLookupReq
 ***********************************************************************
 * SYNOPSIS:	    Deal with a directory lookup in this filesystem
 * CALLED BY:	    SunRpc RFS_LOOKUP
 * RETURN:	    SUNRPC_SUCCESS
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
MountLookupReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    struct nfsdiropargs	*args;	    	/* Arguments passed */
    struct nfsdiropres	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix  	    	*pp;
    PrefixHandle    	ph;

    /*
     * The name consists of two integers separated by a decimal point.
     * The first integer is the address of the Prefix involved, while the
     * second is the generation number for the prefix. We need to scan
     * them into a PrefixHandle structure for HandleToPrefix to use...
     */
    dprintf("MLOOKUP(%s)\n", args->da_name);
    ph.rd.type = PH_REGULAR;
    sscanf(args->da_name, "%d.%d", &ph.rd.pp, &ph.rd.generation);
    pp = HandleToPrefix((fhandle_t *)&ph);
    
    if (pp == PREFIX_STALE) {
	dprintf("\tSTALE HANDLE\n");
	res->dr_status = NFSERR_STALE;
    } else if (pp == NULL) {
	dprintf("\tNO SUCH PREFIX\n");
	res->dr_status = NFSERR_NOENT;
    } else {
	dprintf("\tMLOOKUP(%s)\n", pp->path);
	res->dr_status = NFS_OK;
	
	/*
	 * Handle is same as always...
	 */
	PrefixToHandle(pp, &res->dr_fhandle);
	
	/*
	 * All prefixes are symbolic links until they're mounted.
	 * (the thing can't be mounted or we wouldn't be here)
	 */
	res->dr_attr = link_attr;
	res->dr_attr.na_size		= strlen(pp->path);
	res->dr_attr.na_blocksize	= pp->attr.na_blocksize;
    }

    return(SUNRPC_SUCCESS);
}
		

/***********************************************************************
 *				Mount_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize things here
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The mount directory is created and statted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 6/89		Initial Revision
 *
 ***********************************************************************/
void
Mount_Init()
{
    struct stat	stb;
    
    /*
     * Make sure special directory is around
     */
    (void)mkdir(MOUNT_DIR, 0555);

    /*
     * Fetch its attributes
     */
    if (stat(MOUNT_DIR, &stb) < 0) {
	perror(MOUNT_DIR);
	exit(1);
    }

    /*
     * Covert to NFS Normal Form
     */
    mattr.na_type    	    = NFDIR;
    mattr.na_mode     	    = 0555 | S_IFDIR;
    mattr.na_nlink    	    = 1;
    mattr.na_uid	    = stb.st_uid;
    mattr.na_gid	    = stb.st_gid;
    mattr.na_size	    = stb.st_size;
    mattr.na_blocksize	    = stb.st_blksize;
    mattr.na_rdev	    = -1;
    mattr.na_blocks	    = stb.st_blocks;
    mattr.na_fsid	    = -1;
    mattr.na_nodeid	    = stb.st_ino;
    mattr.na_atime.tv_sec   = stb.st_atime;
    mattr.na_atime.tv_usec  = stb.st_spare1;
    mattr.na_mtime.tv_sec   = stb.st_mtime;
    mattr.na_mtime.tv_usec  = stb.st_spare2;
    mattr.na_ctime.tv_sec   = stb.st_ctime;
    mattr.na_ctime.tv_usec  = stb.st_spare3;

    /*
     * Create a socket for ourselves -- it can be anywhere in the UDP
     * address space.
     */
    mountSock = Rpc_UdpCreate(True, 0);

    /*
     * Register the Sun RPC servers for the socket. These are the only
     * NFS procedures we handle -- anything else generates a "procedure
     * unavailable" error.
     */
    SunRpc_ServerCreate(mountSock, NFS_PROGRAM, RFS_NULL, NFS_VERSION,
			MountNullReq, (Rpc_Opaque)NULL,
			0, xdr_void, 0, xdr_void);

    SunRpc_ServerCreate(mountSock, NFS_PROGRAM, RFS_GETATTR, NFS_VERSION,
			MountGetAttrReq, (Rpc_Opaque)NULL,
			sizeof(fhandle_t), xdr_fhandle,
			sizeof(struct nfsattrstat), xdr_attrstat);

    SunRpc_ServerCreate(mountSock, NFS_PROGRAM, RFS_READLINK, NFS_VERSION,
			MountReadLinkReq, (Rpc_Opaque)NULL,
			sizeof(fhandle_t), xdr_fhandle,
			sizeof(struct nfsrdlnres), xdr_rdlnres);

    SunRpc_ServerCreate(mountSock, NFS_PROGRAM, RFS_LOOKUP, NFS_VERSION,
			MountLookupReq, (Rpc_Opaque)NULL,
			sizeof(struct nfsdiropargs), xdr_diropargs,
			sizeof(struct nfsdiropres), xdr_diropres);

    SunRpc_ServerCreate(mountSock, NFS_PROGRAM, RFS_STATFS, NFS_VERSION,
			MountStatFSReq, (Rpc_Opaque)NULL,
			sizeof(fhandle_t), xdr_fhandle,
			sizeof(struct nfsstatfs), xdr_statfs);

}


/***********************************************************************
 *				Mount_MountRoot
 ***********************************************************************
 * SYNOPSIS:	    Use our child process to mount ourselves on MOUNT_DIR
 * CALLED BY:	    main
 * RETURN:	    True if successful.
 * SIDE EFFECTS:    >?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
int
Mount_MountRoot()
{
    struct sockaddr_in	sin;
    int	    	    	addrlen = sizeof(sin);

    /*
     * Need to locate the port for the socket so Child_MountSpecial can
     * tell the kernel where we are.
     */
    if (getsockname(mountSock, &sin, &addrlen) < 0) {
	return(False);
    }

    /*
     * Now tell the child to mount us on MOUNT_DIR.
     */
    return(Child_MountSpecial(sin.sin_port, MOUNT_DIR));
}
