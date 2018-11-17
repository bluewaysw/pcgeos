/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Prefix Importation
 * FILE:	  import.c
 *
 * AUTHOR:  	  Adam de Boor: Jul  5, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Import_Init 	    Initialize the module
 *	Import_MountPrefix  Mount a prefix on ourselves
 *	Import_CreatePrefix Create and initialize a Prefix structure
 *	    	    	    FOR AN EXISTING DIRECTORY. Not suitable
 *			    for prefixes under a root.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 5/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to deal with importing prefixes.
 *
 *	A prefix appears to the kernel as if it were a read-only,
 *	empty directory until the first LOOKUP operation is performed
 *	on it. The LOOKUP operation is redirected, by claiming the
 *	file in question is a symbolic link, to the MOUNT_DIR (the
 *	exact destination is MOUNT_DIR/<prefix>.<generation>/<component>,
 *	where <prefix> is the ascii representation of the address of the
 *	Prefix structure, <generation> is the ascii representation of the
 *	prefix's generation number, and <component> is the component being
 *	sought).
 *
 *	When the kernel does a LOOKUP operation in MOUNT_DIR, we
 *	unmount the prefix and mount the real one, then redirect the
 *	kernel back there again....
 *
 *	NOTE: ANY fhandle_t RETURNED TO THE KERNEL SHOULD BE ZEROED
 *	      OUT BEFORE STORING THE VALUE IN IT, AS THE SUN 
 *	      IMPLEMENTATION, AT LEAST, USES BYTES 1, 5 AND 15 FOR
 *	      HASHING.
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
"$Id: import.c,v 1.17 91/07/24 17:48:49 adam Exp $";
#endif lint

#include    "prefix.h"
#include    "rpc.h"
#include    "sunrpc.h"

#include    <arpa/inet.h>
#include    <netdb.h>
#include    <mntent.h>	    /* for MNTMAXSTR */

static int  	prefixSvc;  	/* Socket for prefix NFS requests */

/*
 * Token we allocate when given a LOOKUP operation on a prefix. Points
 * to the prefix involved as well as the name of the component that was
 * being looked up before we redirected the kernel to our mount directory.
 *
 * A LookupToken remains valid for 10 seconds after it is created, after
 * which it is deleted from the tokens list. Any later use of a handle with
 * the token's address in it will be rejected.
 *
 * When a token is deleted, it is placed on the freeTokens list to be
 * re-used later. Each token has a "generation number" that is simply
 * a counter that gets incremented each time the token is allocated. The
 * generation number of the token is returned in the fhandle and compared
 * when a readlink is performed to ensure the kernel's idea and our idea
 * of what is being looked up coincide. The generation number is set to
 * zero when the token is first allocated.
 *
 * Maintaining a pool of free tokens allows us to make sure that if the
 * kernel ever comes back with a lookup token, we won't be deceived into
 * doing something bad because the memory has been re-used and happens to
 * contain good values in the fields used for checking token validity.
 */
typedef struct _LookupToken {
    Prefix  	*prefix;    	/* Prefix in which the name was looked up */
    char    	*name;	    	/* Name that was sought */
    int	    	generation; 	/* Generation number for this token */
    Rpc_Event	nukeEvent;	/* Event that will biff this token. Needed in
				 * case the token must be nuked prematurely,
				 * e.g. when a temporary prefix gets nixed */
} LookupToken;

static Lst  	tokens;		/* List of active tokens */
static Lst  	freeTokens; 	/* Pool of previously allocated tokens that
				 * can be reused */

#define IS_LOOKUP_HAN(f) (((PrefixHandle *)f)->type == PH_LOOKUP)
#define IS_VALID_LH(f) \
    ((((PrefixHandle *)f)->ld.generation == \
      ((PrefixHandle *)f)->ld.ltp->generation) && \
     (Lst_Member(tokens, (ClientData)((PrefixHandle *)f)->ld.ltp) != NILLNODE))

/*
 * Given a buffer and a LookupToken, place the path-via-MOUNT_DIR-for-
 * redirecting-the-kernel-("Look! A UFO!")-while-we-mount-the-real-FS into
 * the buffer.
 */
#define LT_PATH(dest,ltp) sprintf(dest, "%s/%d.%d/%s", MOUNT_DIR, \
				  ((LookupToken *)ltp)->prefix, \
				  ((LookupToken *)ltp)->prefix->generation, \
				  ((LookupToken *)ltp)->name)

/*
 * Attributes returned for any symbolic link
 */
struct nfsfattr	link_attr = {
    NFLNK,			/* na_type */
    0777 | S_IFLNK,		/* na_mode */
    1,				/* na_nlink */
    0,				/* na_uid */
    0,				/* na_gid */
    0,				/* na_size (filled in later) */
    0,				/* na_blocksize (filled in later) */
    -1,				/* na_rdev (Garbage) */
    1,				/* na_blocks */
    -1,				/* na_fsid (Garbage) */
    16,				/* na_nodeid (Garbage) */
    {0,0},			/* na_atime (Garbage) */
    {0,0},			/* na_mtime (Garbage) */
    {0,0},			/* na_ctime (Garbage) */
};

/* FORWARD DECL */
static int ImportDeleteTemp();
/******************************************************************************
 *
 *			   UTILITY ROUTINES
 *
 *****************************************************************************/

/***********************************************************************
 *				ImportTokenToHandle
 ***********************************************************************
 * SYNOPSIS:	    Convert a LookupToken into an NFS handle
 * CALLED BY:	    ImportLookupReq
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Handle is filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 9/89	Initial Revision
 *
 ***********************************************************************/
static void
ImportTokenToHandle(ltp, fh)
    LookupToken	    *ltp;
    fhandle_t	    *fh;
{
    PrefixHandle    *lhp;   	    /* Internal form */

    lhp = (PrefixHandle *)fh;
    
    /*
     * Make sure unused bytes are 0
     */
    bzero(fh, sizeof(*fh));
    /*
     * Set up significant fields.
     */
    lhp->ld.type =  	    PH_LOOKUP;
    lhp->ld.generation =    ltp->generation;
    lhp->ld.ltp =   	    ltp;
}

/***********************************************************************
 *			ImportDeleteLookupToken
 ***********************************************************************
 * SYNOPSIS:	    Nuke an expired LookupToken
 * CALLED BY:	    Rpc event, ImportDeleteTemp, ImportDelete
 * RETURN:	    FALSE (don't stay awake)
 * SIDE EFFECTS:    The token's name is freed and the token itself is
 *	    	    shifted to the freeTokens list with its generation
 *	    	    number increased by one.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 5/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
ImportDeleteLookupToken(ltp, ev)
    LookupToken		*ltp;	    /* Token to nuke */
    Rpc_Event		ev; 	    /* Event that called us */
{
    LstNode		ln;

    /*
     * Locate and remove the token from the list of valid tokens.
     */
    ln = Lst_Member(tokens, (ClientData)ltp);
    Lst_Remove(tokens, ln);

    /*
     * Free its memory.
     */
    free(ltp->name);

    /*
     * Put it back in the pool, upping its generation number to make life
     * easier when checking (should very rarely have to do a Lst_Member).
     */
    ltp->generation += 1;
    (void)Lst_AtEnd(freeTokens, (ClientData)ltp);

    /*
     * Don't want to be called again...
     */
    Rpc_EventDelete(ev);

    /*
     * No need to stay awake on our account.
     */
    return(FALSE);
}

/***********************************************************************
 *				ImportAllocLookupToken
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new lookup token
 * CALLED BY:	    ImportLookupReq
 * RETURN:	    A token to use.
 * SIDE EFFECTS:    A token will be removed from the freeTokens list,
 *	    	    if possible.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 9/89	Initial Revision
 *
 ***********************************************************************/
static LookupToken *
ImportAllocLookupToken()
{
    LookupToken	*ltp;

    if (!Lst_IsEmpty(freeTokens)) {
	ltp = (LookupToken *)Lst_DeQueue(freeTokens);
    } else {
	ltp = (LookupToken *)malloc(sizeof(LookupToken));
	ltp->generation = 0;	/* First-generation */
    }
    return(ltp);
}

/***********************************************************************
 *				ImportSetLinkAttr
 ***********************************************************************
 * SYNOPSIS:	    Setup returned attributes to be for a link to the
 *	    	    given path.
 * CALLED BY:	    ImportLookup, ImportGetAttr
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static void
ImportSetLinkAttr(attrPtr, path, pp)
    struct nfsfattr *attrPtr;	    /* Place to store attributes */
    char    	    *path;  	    /* Destination of link */
    Prefix  	    *pp;    	    /* Prefix containing the link */
{
    *attrPtr = link_attr;
		
    /*
     * Fill in specific fields that need filling (size,
     * in case kernel uses it for storage when doing the
     * read, and blocksize, for the hell of it).
     */
    attrPtr->na_size	    = strlen(path);
    attrPtr->na_blocksize   = pp->attr.na_blocksize;
}
/******************************************************************************
 *
 *			   PREFIX LOCATION
 *
 *****************************************************************************/

/***********************************************************************
 *				ImportLocateResponse
 ***********************************************************************
 * SYNOPSIS:	    Handle response from our PREFIX_LOCATE broadcast
 * CALLED BY:	    Rpc
 * RETURN:	    1 (stop broadcast)
 * SIDE EFFECTS:    The server, serverName and remote fields of the
 *	    	    'searching' prefix are filled in based on the
 *	    	    response.
 *
 * STRATEGY:
 *      - Figure name of responder
 *	- Write result to console
 *	- Allocate room for and store the server and remote directory
 *	- Record server's address
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 5/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
ImportLocateResponse(from, len, data, searching)
    struct sockaddr_in	*from;	    /* Source of response */
    int	    	    	len;	    /* Size of return data buffer */
    Rpc_Opaque	    	data;	    /* Data returned */
    Prefix  	    	*searching; /* Prefix for which we're searching */
{
    struct hostent  	*he;	    /* Description of host to which 'from'
				     * belongs */
    char    	    	*name;	    /* Name to use for server */
    char    	    	*fsname;    /* Remote FS name */
    char    	    	*endhost;
    int	    	    	fslen;
    char    	    	*servOpts;

    /*
     * See if the responder is just being a surrogate (as indicated by the
     * remote fsname being <host>:<fsname> instead of just <fsname>)
     */
    fsname = (char *)data;
    endhost = (char *)index(fsname, ':');

    /*
     * Look for server-specified mount options.
     */
    fslen = strlen(fsname);
    if (fslen+1 != len) {
	servOpts = fsname + fslen + 1;
    } else {
	servOpts = "";
    }

    if (endhost != NULL) {
	*endhost++ = '\0';
	he = gethostbyname(fsname);
	if (he == NULL) {
	    Message("ImportLocateResponse: host %s (from %s:%s response to %s query) unknown",
		    fsname, fsname, endhost, searching->path);
	    /* Keep looking */
	    return(0);
	}
	/*
	 * Set the fsname to the actual filesystem name and the "from"
	 * address to match that of the host from which we'll actually
	 * mount the thing.
	 */
	fsname = endhost;
	bcopy(he->h_addr, &from->sin_addr, sizeof(from->sin_addr));
    } else {
	/*
	 * We'd like to put/print the host name, not just its address, so
	 * try and convert from an address into a name, leaving the final
	 * result pointed to by "name"
	 */
	he = gethostbyaddr(&from->sin_addr,
			   sizeof(from->sin_addr),
			   AF_INET);

    }

    if (he) {
	/*
	 * Trim off any domain that's there...
	 */
	name = (char *)index(he->h_name, '.');
	if (name != NULL) {
	    *name = '\0';
	}
	name = he->h_name;
    } else {
	name = InetNtoA(from->sin_addr);
    }

    /*
     * Complete "Broadcasting for..." message.
     */
    if (!quiet) {
	Message("served by %s[%s]", name, fsname);
    }

    /*
     * Allocate room for the strings we need to store
     */
    searching->serverName = (char *)malloc(strlen(name) + 1);
    searching->remote = (char *)malloc(strlen(fsname) + 1);
    searching->servOpts = (char *)malloc(strlen(servOpts) + 1);

    /*
     * Store the server data in the prefix entry
     */
    searching->server = *from;
    strcpy(searching->serverName, name);
    strcpy(searching->remote, fsname);
    strcpy(searching->servOpts, servOpts);

    dprintf("options = \"%s\"\n", servOpts);
    
    /*
     * Stop broadcasting
     */
    return(1);
}

/***********************************************************************
 *				ImportLocatePrefix
 ***********************************************************************
 * SYNOPSIS:	    Find the server for a prefix.
 * CALLED BY:	    ImportReadLink
 * RETURN:	    1 if server found.
 * SIDE EFFECTS:    The serverName, remote and server fields of the
 *	    	    prefix are filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static int
ImportLocatePrefix(pp)
    Prefix  	    	*pp;	    /* Prefix to find */
{
    struct timeval  	retry;	    /* Retrans interval */
    char    	    	path[NFS_MAXPATHLEN+MNTMAXSTR];
    	    	    	    	    /* Buffer for remote path & mount opts */

    if (pp->serverName == NULL) {
	/*
	 * Broadcast to locate the server for the thing, now
	 * we know the kernel really wants it...
	 */
	if (!quiet) {
	    Message("Broadcasting for server of \"%s\"...", pp->path);
	}
	
	/*
	 * Make sure the list of networks on which we're to search is up-to-date
	 */
	PrepSearchNets();
	
	/*
	 * Retry every second
	 */
	retry.tv_sec = 1;
	retry.tv_usec = 0;
	
	if (Rpc_BroadcastToNets(prefixSock,
				searchNets, numSearchNets,
				PREFIX_LOCATE,
				strlen(pp->path)+1, pp->path,
				sizeof(path), path,
				3, &retry,
				ImportLocateResponse,
				(Rpc_Opaque)pp)!=RPC_SUCCESS)
	{
	    /*
	     * No-one's got it -- return an error
	     */
	    if (!quiet) {
		Message("no-one's home.");
	    }
	    return(0);
	}
    }
    return(1);
}


/******************************************************************************
 *
 *			   SUN-RPC SERVERS
 *
 *****************************************************************************/

/***********************************************************************
 *				ImportNullReq
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
ImportNullReq(remote, msg, args, res, data, resPtr)
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
 *				ImportGetAttrReq
 ***********************************************************************
 * SYNOPSIS:	    Fetch the attributes of a prefix.
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS (any error code is in result)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
ImportGetAttrReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    fhandle_t	    	*args;	    	/* Arguments passed */
    struct nfsattrstat	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix  	*pp;	    /* Prefix to stat */
    char	path[512];  /* Path for filling in result */
	
    if (!IS_LOOKUP_HAN(args)) {
	/*
	 * Really a prefix -- convert to a Prefix and return
	 * the stored attributes
	 */
	pp = HandleToPrefix(args);
	    
	if (pp == PREFIX_STALE) {
	    res->ns_status = NFSERR_STALE;
	} else {
	    dprintf("GETATTR(%s)\n", pp->path);
		
	    /*
	     * Install saved attributes
	     */
	    res->ns_status = NFS_OK;
	    res->ns_attr = pp->attr;
	}
    } else {
	/*
	 * This is here only for safety. I doubt it will
	 * ever be called... WRONG! SunOS 4.0 calls this... I guess
	 * because we tell it to cache no attributes...
	 */
	PrefixHandle	    *lth = (PrefixHandle *)args;
	    
	if (!IS_VALID_LH(args)) {
	    res->ns_status = NFSERR_STALE;
	} else {
	    LookupToken	*ltp = lth->ld.ltp;
	    
	    dprintf("GETATTR(%s/%s)\n", ltp->prefix->path, ltp->name);
		
	    /*
	     * Form path so we return the proper size
	     */
	    LT_PATH(path, ltp);
		
	    /*
	     * Use default attributes for symbolic links.
	     */
	    res->ns_status = NFS_OK;

	    ImportSetLinkAttr(&res->ns_attr, path, ltp->prefix);
	}
    }
    return(SUNRPC_SUCCESS);
}

/***********************************************************************
 *				ImportReadLinkReq
 ***********************************************************************
 * SYNOPSIS:	    Read the value of one of our "links"
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS (link contents returned to caller)
 * SIDE EFFECTS:    The server for the prefix is sought and the
 *	    	    serverName, server and remote fields for it filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
ImportReadLinkReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    fhandle_t	    	*args;	    	/* Arguments passed */
    struct nfsrdlnres	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix  	*pp;
    char    	path[512];  /* Link's contents */
    
    /*
     * Convert the handle into a token.
     */
    if (IS_LOOKUP_HAN(args)) {
	if (!IS_VALID_LH(args)) {
	    /*
	     * Not in the active list -- must be stale
	     */
	    dprintf("READLINK -- stale handle\n");
	    res->rl_status = NFSERR_STALE;
	} else {
	    LookupToken	*ltp;       /* Token we created during LOOKUP */
	
	    ltp = ((PrefixHandle *)args)->ld.ltp;
	
	    /*
	     * Make life easier by fetching out the prefix itself
	     */
	    pp = ltp->prefix;
	    
	    dprintf("READLINK(%s/%s)\n", pp->path, ltp->name);
	    
	    res->rl_status = NFS_OK;
	    
	    if (pp->serverName == NULL) {
		/*
		 * We are not allowed to look for a prefix that is locked,
		 * as doing so could result in our deleting the thing while
		 * someone else is looking for it. The best way to handle
		 * this is to force the kernel to resubmit its request when
		 * we are more likely to be able to give it an answer. We
		 * do this by instructing SunRpc to drop the request on the
		 * floor.
		 */
		if (PrefixIsLocked(pp)) {
		    return(SUNRPC_DONTRESPOND);
		}
		PrefixLock(pp);
		if (!ImportLocatePrefix(pp)) {
		    /*
		     * If prefix is temporary and we were trying to locate
		     * it, we can safely delete the thing if we can't find
		     * its server. This will prevent repeated search for
		     * something due to "getwd" (which does a readdir and
		     * stat) when something gets into the prefix table
		     * unintentionally.
		     */
		    PrefixUnlock(pp);
		    if (pp->flags & PREFIX_TEMP) {
			(void)ImportDeleteTemp(pp);
		    }
		    res->rl_status = NFSERR_NOENT;
		} else {
		    PrefixUnlock(pp);
		}
	    } else {
		dprintf("served by %s[%s]\n", pp->serverName, pp->remote);
	    }
	    
	    if (res->rl_status == NFS_OK) {
		/*
		 * Return a path to the "file" in the mount directory
		 * whose name is the ascii representation of the Prefix
		 * structure's address, with the component being sought
		 * just below that. The kernel should then perform a
		 * LOOKUP operation in the mount directory, at which
		 * time we should be able to unmount this thing and
		 * mount the real one. The kernel will track the
		 * extra component so we don't need to.
		 */
		LT_PATH(path, ltp);
		dprintf("returning \"%s\"\n", path);
		/*
		 * Set up return value at the end of the nfsrdlnres
		 */
		res->rl_count = strlen(path);
		res = (struct nfsrdlnres *)realloc(res,
						   sizeof(*res)+res->rl_count);
		*resPtr = (void *)res;
		res->rl_data = (char *)(res+1);
		bcopy(path, res->rl_data, res->rl_count);
	    }
	}
    } else {
	/*
	 * BOGUS -- should never happen
	 */
	res->rl_status = NFSERR_STALE;
    }
    return(SUNRPC_SUCCESS);
}

/***********************************************************************
 *				ImportCreateTempPrefix
 ***********************************************************************
 * SYNOPSIS:	    Create a new temporary prefix
 * CALLED BY:	    ImportLookupReq
 * RETURN:	    The Prefix * for the new prefix, linked into the
 *	    	    parent and the global list.
 * SIDE EFFECTS:    All fields of the prefix are initialized.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static Prefix *
ImportCreateTempPrefix(path, pp)
    char    	*path;	    	/* Path for the prefix */
    Prefix  	*pp;	    	/* Parent prefix */
{
    Prefix  	    *newpp;
    Prefix  	    *prev;
    Prefix  	    *tp;
    
    newpp = AllocPrefix();
    
    newpp->path = (char *)malloc(strlen(path) + 1);
    strcpy(newpp->path, path);
    
    /*
     * Mark the prefix as temporary, so we don't remount the thing after
     * deleting it.
     */
    newpp->flags = PREFIX_TEMP;
    newpp->locks = 0;
    
    /*
     * The new prefix is a clone of the root prefix, except for the file
     * number...
     */
    newpp->options = pp->options;
    newpp->attr = pp->attr;

    /* 
     * Need to use a different file number to keep the kernel from getting
     * confused.
     */
    if (pp->next) {
	newpp->attr.na_nodeid = pp->next->attr.na_nodeid + 1;
    } else {
	newpp->attr.na_nodeid = pp->attr.na_nodeid + 1;
    }
    
    /*
     * Clear out the rest of the fields
     */
    newpp->unmount = (Rpc_Event)NULL;
    newpp->serverName = newpp->remote = (char *)NULL;
    
    /*
     * Record it.
     */
    (void)Lst_AtEnd(prefixes, (ClientData)newpp);
    
    /*
     * Record it under its parent so we can deal with a READDIR on the parent
     * (to allow for file completion, mostly). We place it at the end of
     * the queue to try and avoid unnecessary mounts due to getwd() calls.
     */
    for (prev = pp, tp = pp->next; tp != NULL; prev = tp, tp = tp->next) {
	;
    }
    prev->next = newpp;
    newpp->next = (Prefix *)NULL;

    return(newpp);
}

/***********************************************************************
 *				ImportLookupReq
 ***********************************************************************
 * SYNOPSIS:	    Handle a LOOKUP operation in a prefix.
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS (handle and attributes returned to caller)
 * SIDE EFFECTS:    A LookupToken is created and saved
 *
 * STRATEGY:
 *	The search of a prefix means its corresponding filesystem must
 *	be mounted.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
ImportLookupReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    struct nfsdiropargs	*args;	    	/* Arguments passed */
    struct nfsdiropres	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix	    *pp;    	/* Prefix to import */
    LookupToken	    *ltp;   	/* New token for later READLINK */
    char	    path[512];	/* Contents of "link" (for setting
				 * size in link's attributes) */
    
    pp = HandleToPrefix(&args->da_fhandle);
    
    if (pp == PREFIX_STALE) {
	res->dr_status = NFSERR_STALE;
    } else {
	dprintf("LOOKUP(%s:%s)\n", pp->path, args->da_name);
	
	if (args->da_name[0] == '.' &&
	    (args->da_name[1] == '\0' ||
	     (args->da_name[1] == '.' && args->da_name[2] == '\0')))
	{
	    if (args->da_name[1] == '\0') {
		/*
		 * Looking up itself -- return the stored attributes
		 * and the proper handle.
		 */
		res->dr_status = NFS_OK;
		res->dr_attr = pp->attr;
		
		PrefixToHandle(pp, &res->dr_fhandle);
	    } else if (pp->flags & PREFIX_TEMP) {
		/*
		 * Want the parent of this sucker. Trim off the
		 * last component of the prefix call NameToPrefix
		 * to find it.
		 *
		 * This will only be invoked by the kernel if
		 * it encounters .. while in the root vnode of the
		 * temporary prefix, at which point it flips to
		 * the associated vnode in the root prefix's system
		 * to do the lookup, but the handle is still that
		 * of the temporary prefix...
		 */
		char	    *cp;    /* Start of final component */
		Prefix	    *ppp;   /* Parent Prefix Pointer */
		
		/*
		 * Just nuke the final slash...we'll put it back later.
		 */
		cp = (char *)rindex(pp->path, '/');
		*cp = '\0'; ppp = NameToPrefix(pp->path); *cp = '/';
		
		/*
		 * Set up the return value based on the parent.
		 */
		res->dr_status = NFS_OK;
		res->dr_attr = ppp->attr;
		
		PrefixToHandle(ppp, &res->dr_fhandle);
	    } else {
		/*
		 * Why are you asking me this?
		 */
		res->dr_status = NFSERR_NOENT;
	    }
	} else if (pp->flags & PREFIX_ROOT) {
	    /*
	     * Special case -- looking something up in a ROOT
	     * prefix causes us to create a new temporary prefix,
	     * if one doesn't already exist.
	     */
	    Prefix  *newpp; 	/* Prefix for component */
	    
	    /*
	     * Form full path for ease of comparison.
	     */
	    sprintf(path, "%s/%s", pp->path, args->da_name);
	    newpp = NameToPrefix(path);
	    
	    if (newpp == NULL) {
		/*
		 * Doesn't exist yet -- create a new Prefix structure
		 * for the thing.
		 */
		newpp = ImportCreateTempPrefix(path, pp);
	    }
	    
	    /*
	     * Set up to answer the query now, returning a
	     * standard handle for the prefix.
	     */
	    res->dr_status  = NFS_OK;
	    res->dr_attr    = newpp->attr;
	    PrefixToHandle(newpp, &res->dr_fhandle);
	} else {
	    /*
	     * Create the LookupToken for the thing and put it on
	     * the end of the list of valid tokens.
	     */
	    struct timeval	deltok;	/* Interval for nuking */
	    
	    ltp = ImportAllocLookupToken();
	    
	    ltp->prefix     = pp;
	    ltp->name 	    = (char *)malloc(strlen(args->da_name)+1);
	    strcpy(ltp->name, args->da_name);
	    
	    (void)Lst_AtEnd(tokens, (ClientData)ltp);
	    
	    /*
	     * Register an event for deleting the lookup token
	     */
	    deltok.tv_sec = 10;
	    deltok.tv_usec = 0;
	    ltp->nukeEvent = Rpc_EventCreate(&deltok, ImportDeleteLookupToken,
					     (Rpc_Opaque)ltp);
	    
	    /*
	     * Set up the return filehandle.
	     */
	    ImportTokenToHandle(ltp, &res->dr_fhandle);
	    
	    /*
	     * Set up the path so we can return an accurate size
	     */
	    LT_PATH(path, ltp);
	    
	    /*
	     * This is the same as for the GETATTR call... (not
	     * sure if the GETATTR support is necessary...)
	     */
	    res->dr_status  = NFS_OK;
	    ImportSetLinkAttr(&res->dr_attr, path, pp);
	}
    }
    
    return(SUNRPC_SUCCESS);
}    


/***********************************************************************
 *				ImportStatFSReq
 ***********************************************************************
 * SYNOPSIS:	    Handle a STATFS request
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS (bogus statistics are returned to caller)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	We don't know the actual parameters for a prefix since we don't
 *	know who's serving the thing, nor are we going to find out
 *	because of this call (which is issued whenever the prefix is
 *	mounted), so we just return that the system is completely full.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
ImportStatFSReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    fhandle_t	    	*args;	    	/* Arguments passed */
    struct nfsstatfs	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    void    	    	**resPtr;   	/* Room for modified 'res' (UNUSED)*/
{
    Prefix  	    	*pp;
    
    pp = HandleToPrefix(args);
    if (pp == PREFIX_STALE) {
	res->fs_status = NFSERR_STALE;
    } else {
	dprintf("STATFS(%s)\n", pp->path);
	
	bzero(res, sizeof(*res));
	    
	/*
	 * Return bogus information for the filesystem for now:
	 *  block and transfer size of 8192 bytes, 1 block in
	 *  the system and nothing is free...
	 */
	res->fs_status = NFS_OK;
	res->fs_tsize = res->fs_bsize = 8192;
	res->fs_blocks = 1;
	res->fs_bfree = 0;
	res->fs_bavail = 0;
	    
    }
    return(SUNRPC_SUCCESS);
}

/***********************************************************************
 *				ImportReadDirReq
 ***********************************************************************
 * SYNOPSIS:	    Handle a READDIR request on a prefix
 * CALLED BY:	    SunRpc
 * RETURN:	    SUNRPC_SUCCESS (directory entries are return to the caller)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	For most prefixes, this just returns . and ..
 *	For a root prefix, however, this returns the list of known
 *	subprefixes.
 *
 *	The offsets we return (via xdr_putdirres) do no correspond to
 *	file positions, as in a real NFS server. Instead, they are the
 *	prefix number (i.e. the position in the list).
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static enum clnt_stat
ImportReadDirReq(remote, msg, args, res, data, resPtr)
    struct sockaddr_in	*remote;    	/* Source of request */
    Rpc_Message	    	msg;	    	/* Message token */
    struct nfsrddirargs	*args;	    	/* Arguments passed */
    struct nfsrddirres	*res;	    	/* Results to return */
    Rpc_Opaque	    	data;	    	/* Data we stored (UNUSED) */
    Rpc_Opaque		*resPtr;	/* Place holding address of "res". We
					 * need to enlarge the thing to hold
					 * the directory entries too... */
{
    Prefix  	    	*pp;	/* Prefix being read */
    struct direct   	*dirent;    /* All entries */
    
    /*
     * We do this very simply for now, storing all the
     * known entries into a buffer each time, then returning only
     * part of it. I always do brute-force, simplistic solutions
     * on the first pass. Besides, the other buffer will almost
     * always be big enough to hold it, I think, since we tell
     * the thing the FS has a block size of 8k...
     */
    dirent = NULL;
    
    pp = HandleToPrefix(&args->rda_fh);
    
    if (pp == PREFIX_STALE) {
	res->rd_status = NFSERR_STALE;
    } else {
	Prefix	    	*tp;	/* Current subprefix being
				 * counted or entered */
	int	    	i;	/* General counter */
	int 	    	total;	/* Total number of entries */
	int	    	size;	/* General size quantity */
	struct direct   d;  	/* For initial pass... */
	struct direct   *dp;	/* For subsequent passes... */
	
	dprintf("READDIR(%s): ", pp->path);
	
	/*
	 * Count the number of entries available and figure the
	 * size of buffer required to hold the entire list. We
	 * need to use 'd' because the DIRSIZ macro only operates
	 * on a struct direct (silly thing).
	 *
	 * Note this operation is only valid on a root prefix.
	 * In particular, we have to avoid returning anything but
	 * . and .. for a temporary prefix. If we don't, performing
	 * 'ls -l' of a temporary prefix will cause us to try and
	 * mount the prefix for each prefix after it at the same
	 * level and each attempt will fail miserably because the
	 * node is still locked.
	 */
	total = size = 0;
	
	if (pp->flags & PREFIX_ROOT) {
	    for (tp = pp->next; tp != NULL; tp=tp->next, total += 1) {
		char	*cp = (char *)rindex(tp->path, '/');
		
		d.d_namlen = strlen(cp+1);
		size += DIRSIZ(&d);
	    }
	}
	
	/*
	 * Add two for . and ..
	 */
	d.d_namlen = 1;
	size += DIRSIZ(&d);
	
	d.d_namlen = 2;
	size += DIRSIZ(&d);
	
	total += 2;
	
	dprintf("%d entries requiring %d bytes\n", total, size);
	
	/*
	 * Fill in the buffer now. The entries go immediately after the
	 * result so the two can be freed at once by the rpc code.
	 */
	res = (struct nfsrddirres *)realloc(res,
					    sizeof(struct nfsrddirres)+size);
	*resPtr = (Rpc_Opaque)res;
	dirent = (struct direct *)(res+1);
	
	dprintf("\tstoring:");
	/*
	 * . comes first
	 */
	dp = dirent;
	dp->d_fileno = pp->attr.na_nodeid;
	dp->d_namlen = 1;
	dp->d_name[0] = '.'; dp->d_name[1] = '\0';
	dp->d_reclen = DIRSIZ(dp);
	dp = (struct direct *)((char *)dp + dp->d_reclen);
	dprintf(" .");
	
	/*
	 * .. next
	 */
	dp->d_fileno = 3; /* BOGUS */
	dp->d_namlen = 2;
	dp->d_name[0] = '.'; dp->d_name[1] = '.';
	dp->d_name[2] = '\0';
	dp->d_reclen = DIRSIZ(dp);
	dp = (struct direct *)((char *)dp + dp->d_reclen);
	dprintf(" ..");
	
	/*
	 * Now the rest of the entries
	 */
	if (pp->flags & PREFIX_ROOT) {
	    for (tp = pp->next; tp != NULL; tp = tp->next, i++){
		char	    *cp = (char *)rindex(tp->path, '/');
		
		dp->d_fileno = tp->attr.na_nodeid;
		dp->d_namlen = strlen(cp+1);
		strcpy(dp->d_name, cp+1);
		dp->d_reclen = DIRSIZ(dp);
		dp = (struct direct *)((char *)dp + dp->d_reclen);
		dprintf(" %s", cp+1);
	    }
	}
	
	dprintf("\n");
	/*
	 * Find the start for the return value
	 */
	
	dp = dirent;
	if (args->rda_offset < total) {
	    dprintf("\tstarting at %d (skipping:", args->rda_offset);
	    for (i = args->rda_offset; i > 0; i--) {
		dprintf(" %s", dp->d_name);
		dp = (struct direct *)((char *)dp + dp->d_reclen);
	    }
	    dprintf(")\n");
	} else {
	    dprintf("\tread offset (%d) beyond range\n",
		    args->rda_offset);
	}
	res->rd_entries = dp;
	
	/*
	 * Skip over all those entries that will fit.
	 * res->rd_offset starts out at the index of the first
	 * entry being returned. xdr_putrddirres will up this
	 * for each record encoded so it can deal with us
	 * screwing up (not that we would, but better save than
	 * sorry).
	 */
	res->rd_offset = args->rda_offset;
	dprintf("\treturning:");
	for (size = args->rda_count, i = args->rda_offset;
	     i < total;
	     i++)
	{
	    if ((size -= DIRSIZ(dp)) >= 0) {
		dprintf(" %s", dp->d_name);
		dp = (struct direct *)((char *)dp + dp->d_reclen);
	    } else {
		break;
	    }
	}
	
	/*
	 * Set the final fields of the result, transferring
	 * the buffer size from the args to the result for
	 * xdr_putrddirres-> 
	 */
	res->rd_bufsize = args->rda_count;
	res->rd_eof = (i == total);
	res->rd_size = (char *)dp - (char *)res->rd_entries;
	res->rd_status = NFS_OK;
	dprintf("\n\t%d bytes total, eof = %s, offset = %d\n",
		res->rd_size, res->rd_eof ? "true" : "false",
		res->rd_offset);
    }
    
    return(SUNRPC_SUCCESS);
}
		
/******************************************************************************
 *
 *			  EXPORTED UTILITIES
 *
 *****************************************************************************/

/***********************************************************************
 *				Import_MountPrefix
 ***********************************************************************
 * SYNOPSIS:	    Mount a prefix directory from ourselves. The prefix
 *		    should have been checked for locks
 * CALLED BY:	    ImportPrefix, ImportPrefixTree, MountUnmountPrefix
 * RETURN:	    1 if successful
 * SIDE EFFECTS:    The Prefix is remounted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 6/89		Initial Revision
 *
 ***********************************************************************/
int
Import_MountPrefix(pp)
    Prefix  	*pp;	    /* Prefix to remount */
{
    if (Lst_Member(prefixes, (ClientData)pp) == NILLNODE) {
	(void)Lst_AtEnd(prefixes, (ClientData)pp);
    }
    return (Child_Call(pp, PREFIX_MOUNT_LOCAL));
}

/***********************************************************************
 *				Import_CreatePrefix
 ***********************************************************************
 * SYNOPSIS:	    Create a Prefix structure for a prefix
 * CALLED BY:	    main, ImportPrefix, ImportPrefixTree
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The Prefix * is added to the prefixes list
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 7/89		Initial Revision
 *
 ***********************************************************************/
Prefix *
Import_CreatePrefix(path)
    char    	*path;	    /* Path of prefix (COPIED) */
{
    Prefix  	*pp;	    /* New prefix */
    struct stat	stb;	    /* State of underlying directory, for conversion
			     * into prefix's stored attributes */
			
    if (path[0] != '/') {
	Message("prefix \"%s\" invalid -- must be absolute\n", path);
	return((Prefix *)NULL);
    }
    
    if (Export_IsExported(path)) {
	Message("prefix \"%s\" is exported by this machine and so cannot be imported", path);
	return((Prefix *)NULL);
    }
    
    pp = AllocPrefix();
    pp->path = (char *)malloc(strlen(path) + 1);
    strcpy(pp->path, path);
			
    if (stat(pp->path, &stb) < 0) {
	perror(pp->path);
	free(pp->path);
	FreePrefix(pp);
	pp = (Prefix *)NULL;
    } else {
	/*
	 * Convert the stat structure into an nfs attributes one. Prefixes
	 * always appear to be read-only directories until they are mounted.
	 * They take on the attributes of their underlying directory.
	 */
	pp->attr.na_type    	    = NFDIR;
	pp->attr.na_mode     	    = 0555 | S_IFDIR;
	pp->attr.na_nlink    	    = 1;
	pp->attr.na_uid		    = stb.st_uid;
	pp->attr.na_gid		    = stb.st_gid;
	pp->attr.na_size	    = stb.st_size;
	pp->attr.na_blocksize	    = stb.st_blksize;
	pp->attr.na_rdev	    = -1;
	pp->attr.na_blocks	    = stb.st_blocks;
	pp->attr.na_fsid	    = -1;
	pp->attr.na_nodeid	    = stb.st_ino;
	pp->attr.na_atime.tv_sec    = stb.st_atime;
	pp->attr.na_atime.tv_usec   = stb.st_spare1;
	pp->attr.na_mtime.tv_sec    = stb.st_mtime;
	pp->attr.na_mtime.tv_usec   = stb.st_spare2;
	pp->attr.na_ctime.tv_sec    = stb.st_ctime;
	pp->attr.na_ctime.tv_usec   = stb.st_spare3;

	dprintf("importing %s\n", pp->path);

	pp->flags   	    	    = 0;
	pp->locks		    = 0;
	pp->unmount 	    	    = (Rpc_Event)NULL;
	pp->next    	    	    = (Prefix *)NULL;
	pp->serverName = pp->remote = (char *)NULL;
	pp->options 	    	    = "rw";

	(void)Lst_AtEnd(prefixes, (ClientData)pp);
    }

    return(pp);
}

/***********************************************************************
 *				ImportDeleteTemp
 ***********************************************************************
 * SYNOPSIS:	    Delete a temporary prefix.
 * CALLED BY:	    ImportDelete, Rpc_Event (set up by Mount_Unmount)
 * RETURN:	    0
 * SIDE EFFECTS:    The prefix is removed from the prefixes list and that
 *	    	    of its parent root prefix.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static int
ImportDeleteTemp(pp)
    Prefix  	*pp;
{
    Prefix	    **prev; 	/* For traversal... */
    Prefix	    *tp;
    char	    *cp;
    LstNode 	    ln;
    
    if (PrefixIsLocked(pp)) {
	Message("Trying to delete temp prefix %s, but it's locked %d time%s",
		pp->path, pp->locks, pp->locks > 1 ? "s" : "");
	return(0);
    }

    /*
     * Strip off the final component of the doomed prefix's path and find
     * the corresponding prefix, which is its parent.
     */
    cp = (char *)rindex(pp->path, '/');
    /*
     * %%% ERROR CHECK %%%
     */
    if (cp == NULL) {
	Message("No / in temp prefix's path '%s'. What the f*** is going on?\n",
		pp->path);
	return(0);
    }

    *cp = '\0';
    tp = NameToPrefix(pp->path);
    
    /*
     * %%% ERROR CHECK %%%
     */
    if (tp == NULL) {
	*cp = '/';
	Message("Couldn't find root for temp prefix %s\n",
		pp->path);
#ifdef MEM_TRACE
	if (malloc_size(pp->path) > strlen(pp->path)+1) {
	    cp = pp->path + strlen(pp->path);
	    Message("\tremaining bytes in block = \"%.*s\"\n",
		    (pp->path + malloc_size(pp->path))-cp, cp);
	}
#endif
	return (0);
    }

    /*
     * Invalidate any lookup tokens pending for this prefix.
     */
    for (ln = Lst_First(tokens); ln != NILLNODE;) {
	LookupToken *ltp = (LookupToken *)Lst_Datum(ln);
	
	ln = Lst_Succ(ln);
	
	if (ltp->prefix == pp) {
	    ImportDeleteLookupToken(ltp, ltp->nukeEvent);
	}
    }
    
    /*
     * Find the prefix in the subprefix list for the root, keeping
     * track of the place where the pointer to the current node is
     * stored so the prefix can be removed once it's found.
     */
    for (prev = &tp->next, tp = tp->next; tp != pp; tp = *prev) {
	prev = &tp->next;
    }
    
    /*
     * Remove the prefix from the chain...
     */
    *prev = pp->next;
    
    /*
     * Free up the prefix's storage. Since it's not mounted, this
     * only involves the freeing of the path and the structure itself.
     */
    free(pp->path);
    FreePrefix(pp);

    return(0);
}
/******************************************************************************
 *
 *			 CUSTOMS-RPC SERVERS
 *
 *****************************************************************************/


/***********************************************************************
 *				ImportCommon
 ***********************************************************************
 * SYNOPSIS:	    Import a root or regular prefix
 * CALLED BY:	    ImportPrefix, ImportPrefixRoot
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Another Prefix may be added to the list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 6/89		Initial Revision
 *
 ***********************************************************************/
static void
ImportCommon(msg, path, flags, options)
    Rpc_Message	    msg;    	/* Message for reply/error */
    char    	    *path;  	/* Prefix to import */
    int	    	    flags;  	/* Initial flags for prefix */
    char    	    *options;	/* Mount options */
{
    Prefix  	    *pp;    	/* New prefix structure */

    /*
     * Make sure we're not duplicating an existing prefix. The only time
     * we allow this is when the user is converting a temporary prefix
     * to a permanent one (not sure why, but can't see any reason to disallow
     * it...)
     */
    pp = NameToPrefix(path);
    if (pp != NULL) {
	if (PrefixIsLocked(pp)) {
	    Rpc_Error(msg, PREFIX_LOCKED);
	}

	PrefixLock(pp);
	if (pp->flags & PREFIX_TEMP) {
	    /*
	     * Converting a temporary prefix into a real one. If thing is
	     * mounted remotely, we've nothing else to do -- when the
	     * thing finally gets unmounted, it will be remounted on
	     * us automatically. Otherwise, try and mount the thing on
	     * ourselves.
	     */
	    pp->flags &= ~PREFIX_TEMP;
	    pp->flags |= flags;
	    if ((pp->flags & PREFIX_MOUNTED) || Import_MountPrefix(pp)) {
		Rpc_Return(msg, 0, NULL);
	    } else {
		/*
		 * Failure. I'm so ashamed. Make the prefix temporary again
		 * and return a system error.
		 */
		pp->flags |= PREFIX_TEMP;
		pp->flags &= ~flags;
		Rpc_Error(msg, RPC_SYSTEMERR);
	    }
	} else {
	    Rpc_Error(msg, DUPLICATE_PREFIX);
	}
	PrefixUnlock(pp);
    } else {
	pp = Import_CreatePrefix(path);

	if (pp == NULL) {
	    Rpc_Error(msg, RPC_BADARGS);
	} else {
	    /*
	     * Set initial flags.
	     */
	    pp->flags = flags;
	    pp->options = (char *)malloc(strlen(options)+1);
	    strcpy(pp->options, options);
	    
	    /*
	     * Mount the thing on ourselves
	     */
	    if (Import_MountPrefix(pp)) {
		/*
		 * All ok -- return now.
		 */
		Rpc_Return(msg, 0, NULL);
	    } else {
		Rpc_Error(msg, RPC_SYSTEMERR);
	    }
	}
    }
}

/***********************************************************************
 *				ImportPrefix
 ***********************************************************************
 * SYNOPSIS:	    Import another prefix
 * CALLED BY:	    PREFIX_IMPORT
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Another Prefix is added to the prefixes list
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
ImportPrefix(from, msg, len, data, serverData)
    struct sockaddr_in	    *from;  	/* Source of message */
    Rpc_Message	    	    msg;    	/* Mesage for reply/error */
    int			    len;    	/* Length of passed data (includes
					 * null byte at end of prefix) */
    Rpc_Opaque		    data;   	/* Name of prefix (null-terminated) */
    Rpc_Opaque	    	    serverData;	/* Data we gave (UNUSED) */
{
    char    *path, *options;

    path = (char *)data;
    if (strlen(path) + 1 != len) {
	options = path + strlen(path) + 1;
    } else {
	options = "rw";
    }
    
    ImportCommon(msg, path, 0, options);
}


/***********************************************************************
 *				ImportPrefixRoot
 ***********************************************************************
 * SYNOPSIS:	    Import a tree of prefixes
 * CALLED BY:	    PREFIX_IMPORT_ROOT
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Another Prefix is added to the prefixes list
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 7/89		Initial Revision
 *
 ***********************************************************************/
static void
ImportPrefixRoot(from, msg, len, data, serverData)
    struct sockaddr_in	    *from;  	/* Source of message */
    Rpc_Message	    	    msg;    	/* Message for reply/error */
    int			    len;    	/* Length of passed data (includes
					 * null byte at end of prefix) */
    Rpc_Opaque		    data;   	/* Name of prefix (null-terminated) */
    Rpc_Opaque	    	    serverData;	/* Data we gave (UNUSED) */
{
    char    *path, *options;

    path = (char *)data;
    if (strlen(path) + 1 != len) {
	options = path + strlen(path) + 1;
    } else {
	options = "rw";
    }
    
    ImportCommon(msg, path, PREFIX_ROOT, options);
}

/***********************************************************************
 *				ImportDelete
 ***********************************************************************
 * SYNOPSIS:	    Delete a prefix.
 * CALLED BY:	    PREFIX_DELETE
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If the prefix is a root prefix and it has mounted
 *	    	    subprefixes, the subprefixes are deleted too.
 *
 * STRATEGY:
 *	- Locate prefix
 *	- If no such thing, pass the buck to the Export module
 *	- If we need to unmount the thing, fork and do so
 *	- Else if the prefix is temporary, delete it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static void
ImportDelete(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of data */
    Rpc_Message		msg;	    /* Message for reply/return */
    int			len;	    /* Length of prefix (including null) */
    Rpc_Opaque		data;	    /* Null-terminated prefix */
    Rpc_Opaque 	    	serverData; /* Data we gave (UNUSED) */
{
    Prefix  	    	*pp;
    char    	    	*answer;

    pp = NameToPrefix((char *)data);
    
    if (pp == NULL) {
	/*
	 * No such prefix -- complain.
	 */
	answer = "no such prefix imported";
    } else {
	Import_DeletePrefix(pp, &answer);
    }
    
    Rpc_Return(msg, strlen(answer)+1, (Rpc_Opaque)answer);
}


/***********************************************************************
 *				Import_DeletePrefix
 ***********************************************************************
 * SYNOPSIS:	    Delete the passed prefix (which may not be locked)
 * CALLED BY:	    (EXTERNAL) ImportDelete, BeFiendish
 * RETURN:	    *answerPtr set to error string, or "Ok" if no error
 * SIDE EFFECTS:    prefix will be freed, pending lookup tokens deleted,
 *		    and prefix itself unmounted
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 8/94		Initial Revision
 *
 ***********************************************************************/
void
Import_DeletePrefix(pp, answerPtr)
    Prefix  	*pp;
    char    	**answerPtr;
{
    LstNode 	    	ln;

    if (PrefixIsLocked(pp)) {
	*answerPtr = "prefix is locked";
	return;
    }

    *answerPtr = "Ok";
    /*
     * The case of an unmounted temporary prefix is special -- we need to
     * remove the thing not only from the prefixes list, but also from
     * its siblings in the subprefix list of its parent.
     *
     * For everything else, we need to unmount the thing from somewhere,
     * be it ourselves or its remote system.
     *
     * Note that the deletion of a mounted, temporary prefix is also special:
     * it takes two deletions to get rid of it.
     */
    if (((pp->flags & PREFIX_TEMP) == 0) || (pp->flags & PREFIX_MOUNTED))
    {
	if (pp->flags & PREFIX_ROOT) {
	    /*
	     * If the node's a root, attempt to unmount all its
	     * subprefixes.
	     */
	    Prefix *tp;

	    for (tp = pp->next; tp != NULL; tp = tp->next) {
		if ((tp->flags & PREFIX_MOUNTED) &&
		    (!Mount_Unmount(tp, answerPtr)))
		{
		    /*
		     * Couldn't unmount subprefix, so can't unmount
		     * top-level.
		     */
		    return;
		}
	    }
	}

	/*
	 * Try and unmount the prefix itself.
	 */
	if (pp->flags & PREFIX_MOUNTED) {
	    if (!Mount_Unmount(pp, answerPtr)) {
		return;
	    }
	} else if (pp->flags & PREFIX_INITIALIZED) {
	    /* 
	     * Can't be temporary, so must have been mounted on ourselves.
	     */
	    if (!Child_Call(pp, PREFIX_UNMOUNT_LOCAL)) {
		*answerPtr = "Couldn't unmount from myself?";
		return;
	    }
	}
	if (!(pp->flags & PREFIX_TEMP)) {
	    /*
	     * Now nuke the Prefix descriptor(s) since everything's
	     * disengaged, blowing away this prefix and all its
	     * subprefixes. This works for non-roots too, since
	     * prefixes have their 'next' field initialized to NULL.
	     */
	    while (pp != NULL) {
		Prefix	*next = pp->next;
		
		/*
		 * Nuke any lookup tokens pending for the prefix.
		 */
		for (ln = Lst_First(tokens); ln != NILLNODE; ) {
		    LookupToken	*ltp = (LookupToken *)Lst_Datum(ln);

		    ln = Lst_Succ(ln);
		    if (ltp->prefix == pp) {
			ImportDeleteLookupToken(ltp, ltp->nukeEvent);
		    }
		}
		
		free(pp->path);
		FreePrefix(pp);
		
		pp = next;
	    }
	}
    } else if (pp->flags & PREFIX_TEMP) {
	(void)ImportDeleteTemp(pp);
    }
}

/***********************************************************************
 *				ImportUnmount
 ***********************************************************************
 * SYNOPSIS:	    Handle a PREFIX_UNMOUNT call from a server that's
 *	    	    deleting an exported prefix.
 * CALLED BY:	    PREFIX_UNMOUNT
 * RETURN:	    An empty reply if couldn't unmount.
 * SIDE EFFECTS:    The serverName and remote fields are nulled and the
 *	    	    remote system unmounted.
 *
 * STRATEGY:
 *	A lot like PREFIX_DELETE, except the prefix isn't deleted and
 *	a return value is only sent if there's an error.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static void
ImportUnmount(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    	/* Source of message */
    Rpc_Message	    	msg;	    	/* Message for reply/error */
    int	    	    	len;	    	/* Length of parameters */
    Rpc_Opaque	    	data;	    	/* Parameters (prefix name) */
    Rpc_Opaque	    	serverData;	/* Data we gave (UNUSED) */
{
    if (ntohs(from->sin_port) != PREFIX_PORT) {
	Rpc_Error(msg, RPC_ACCESS);
    } else {
	LstNode	    ln;

	for (ln = Lst_First(prefixes); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    Prefix  *pp;

	    pp = (Prefix *)Lst_Datum(ln);
	    
	    if ((strcmp(pp->path, (char *)data) == 0) &&
		(pp->serverName != NULL) &&
		(pp->server.sin_addr.s_addr == from->sin_addr.s_addr))
	    {
		char	*answer;    /* JUNK */

		if (PrefixIsLocked(pp)) {
		    /*
		     * If prefix in flux, we can't unmount it.
		     */
		    Rpc_Return(msg, 0, (Rpc_Opaque)NULL);
		} else if (pp->flags & PREFIX_MOUNTED) {
		    if (!Mount_Unmount(pp, &answer)) {
			/*
			 * Couldn't unmount -- let the server know
			 */
			struct hostent	*he;

			Rpc_Return(msg, 0, (Rpc_Opaque)NULL);

			/*
			 * Now tell people to stop using the thing.
			 */
			he = gethostbyaddr(&from->sin_addr,
					   sizeof(from->sin_addr),
					   AF_INET);
			Message("Warning: %s trying to delete %s.",
				he ? he->h_name : InetNtoA(from->sin_addr),
				pp->path);
			Message("Please stop using its files");
		    } else if (!(pp->flags & PREFIX_TEMP)) {
			/*
			 * Remount on ourselves if not temporary.
			 */
			Import_MountPrefix(pp);
		    }
		} else {
		    /*
		     * Must have been "linked" to something else.
		     * Just clear out the serverName and remote fields.
		     */
		    free(pp->serverName); free(pp->remote); free(pp->servOpts);
		    pp->serverName = pp->remote = pp->servOpts = (char *)NULL;
		}
		break;
	    }
	}
    }
}
    
    

/***********************************************************************
 *				Import_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this here module.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The "tokens" list is created
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
Import_Init()
{
    int	    	    	addrlen;
    
    tokens = Lst_Init(FALSE);
    freeTokens = Lst_Init(FALSE);

    /*
     * Create the socket over which we will field the kernel's requests for
     * prefixes.
     */
    prefixSvc = Rpc_UdpCreate(True, 0);
    /*
     * Fetch the name of the socket so we can pass it to the kernel.
     * Actually, we don't really fetch the address. We just tell the kernel
     * to use its software loopback stuff. No point in routing the thing,
     * is there?
     */
    addrlen = sizeof(prefixMountAddr);
    if (getsockname(prefixSvc, &prefixMountAddr, &addrlen) < 0) {
	perror("getsockname:prefixSvc");
	exit(0);
    }
    prefixMountAddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    prefixMountAddr.sin_family = AF_INET;

    /*
     * Register the Sun RPC servers for the socket. These are the only
     * NFS procedures we handle -- anything else generates a "procedure
     * unavailable" error.
     */
    SunRpc_ServerCreate(prefixSvc, NFS_PROGRAM, RFS_NULL, NFS_VERSION,
			ImportNullReq, (Rpc_Opaque)NULL,
			0, xdr_void, 0, xdr_void);

    SunRpc_ServerCreate(prefixSvc, NFS_PROGRAM, RFS_GETATTR, NFS_VERSION,
			ImportGetAttrReq, (Rpc_Opaque)NULL,
			sizeof(fhandle_t), xdr_fhandle,
			sizeof(struct nfsattrstat), xdr_attrstat);

    SunRpc_ServerCreate(prefixSvc, NFS_PROGRAM, RFS_READLINK, NFS_VERSION,
			ImportReadLinkReq, (Rpc_Opaque)NULL,
			sizeof(fhandle_t), xdr_fhandle,
			sizeof(struct nfsrdlnres), xdr_rdlnres);

    SunRpc_ServerCreate(prefixSvc, NFS_PROGRAM, RFS_LOOKUP, NFS_VERSION,
			ImportLookupReq, (Rpc_Opaque)NULL,
			sizeof(struct nfsdiropargs), xdr_diropargs,
			sizeof(struct nfsdiropres), xdr_diropres);

    SunRpc_ServerCreate(prefixSvc, NFS_PROGRAM, RFS_STATFS, NFS_VERSION,
			ImportStatFSReq, (Rpc_Opaque)NULL,
			sizeof(fhandle_t), xdr_fhandle,
			sizeof(struct nfsstatfs), xdr_statfs);

    SunRpc_ServerCreate(prefixSvc, NFS_PROGRAM, RFS_READDIR, NFS_VERSION,
			ImportReadDirReq, (Rpc_Opaque)NULL,
			sizeof(struct nfsrddirargs), xdr_rddirargs,
			sizeof (struct nfsrddirres), xdr_putrddirres);

    Rpc_ServerCreate(prefixSock, PREFIX_IMPORT, ImportPrefix, NULL, NULL,
		     NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_IMPORT_ROOT, ImportPrefixRoot,
		     NULL, NULL, NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_DELETE, ImportDelete, NULL, NULL,
		     NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_UNMOUNT, ImportUnmount, NULL, NULL,
		     NULL);

}
