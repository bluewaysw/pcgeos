/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Child process
 * FILE:	  child.c
 *
 * AUTHOR:  	  Adam de Boor: Jul  9, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Child_Init  	    Initialize the module
 *	Child_Call  	    Perform a call to the child.
 *	Child_MountSpecial  Mount a special directory locally to a different
 *	    	    	    address with a special handle format
 *	Child_Kill  	    Blow the child away.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 9/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This module and process exist only to mount and unmount
 *	prefixes at the request of the parent process. Why? To prevent
 *	deadlock, should the kernel need to talk to the parent during
 *	the course of the mounting or unmounting (e.g. to lookup a
 *	component on the way to the mount point).
 *
 *	As such, this beastie handles only four procedures arriving on
 *	the childSock created by the parent and inherited by this process:
 *	PREFIX_MOUNT, PREFIX_MOUNT_LOCAL, PREFIX_UNMOUNT and
 *	PREFIX_UNMOUNT_LOCAL.
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
"$Id: child.c,v 1.10 93/09/15 15:37:20 adam Exp $";
#endif lint

#include    "prefix.h"
#include    "rpc.h"

#define	NFS 	    /* Want NFS mount parameters */
#define NFSCLIENT   /* For SunOS 4.0... */
#include    <sys/mount.h>
#include    <rpcsvc/mount.h>
#include    <mntent.h>

/*
 * Take care of SunOS 4.0 stuff -- fs type is a string, not an int, and
 * we have to pass the M_NEWTYPE flag (taken care of later)
 */
#ifndef MOUNT_NFS
#define MOUNT_NFS   "nfs"
#endif

static int  	    	    childSock;	    /* Socket on which the child will
					     * listen (used only by child) */
static struct sockaddr_in   childAddr;	    /* Address of same */
static int  	    	    childID;	    /* Process ID of child, in case
					     * it needs to be nuked. */

static int  	    	    mountdSock;	    /* Privileged socket for talking
					     * to mount daemons */

#define NUM_RETRIES 	5	    /* Number of times to try call. Needs to
				     * be enough (coupled with a long enough
				     * retry interval) to compensate for
				     * contacting a remote mount daemon.
				     * So far, a ten-second total time has
				     * been sufficient. */
#define MOUNTD_NUM_RETRIES  10	    /* Give mount daemon 30 seconds to respond
				     */
#define MOUNTD_RETRY_SEC    3
#define MOUNTD_RETRY_USEC   0


#define CHILD_MAX_DATA	2048	    /* Longest serverName, path, remote and
				     * options can be */

/*
 * Structure for call parameters. sin is address of remote server, for use
 * in contacting the mount daemon. For both the mount and unmount
 * calls, the serverName, path and remote fields of the prefix are copied
 * into the data field, one after the other. For the mount call, the
 * options are placed after this.
 */
typedef struct {
    struct sockaddr_in	sin;	    	    	/* Server address */
    char    	    	data[CHILD_MAX_DATA];	/* Other data */
}	ChildData;


/***********************************************************************
 *				ChildCallMountd
 ***********************************************************************
 * SYNOPSIS:	    Contact a remote mount daemon about a prefix
 * CALLED BY:	    ChildMount, ChildUnmount
 * RETURN:	    1 if successful.
 * SIDE EFFECTS:    server->sin_port is replaced with mountd's port on
 *	    	    remote server.
 *
 * STRATEGY:
 *	- Create a CLIENT handle to the remote daemon
 *	- Perform the requested call, passing the prefix's remote
 *	  path as an argument.
 *	- Return 1 if SUNRPC_SUCCESS came back from the call.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/89		Initial Revision
 *
 ***********************************************************************/
static int
ChildCallMountd(server, serverName, remote, proc, xdrret, retdata)
    struct sockaddr_in	*server;    	/* Address of server */
    char    	    	*serverName;	/* Name of same */
    char    	    	*remote;    	/* Name of remote directory about
					 * which we're calling */
    int	    	    	proc; 	    	/* Procedure to call */
    xdrproc_t	    	xdrret;	    	/* Procedure to decode the result */
    caddr_t 	    	*retdata;   	/* Place to store the result */
{
    struct timeval  	timeout;    /* Interval for calling mount daemon */
    enum clnt_stat  	rpc_stat;   /* Result of calling */
    AUTH    	    	*auth;	    /* Credentials -- created each time to
				     * avoid problems with bogus short forms
				     * going to remote mount daemons */

    /*
     * Create client handle to the server's mountd, using
     * a 3-second retrans interval and 30-second call timeout. The server
     * field of the prefix has been filled with the address and family, but
     * not the port, which we get from the portmapper on the remote machine by
     * setting the port to 0.
     *
     * Servers can get really loaded and take a lot longer than the 10 seconds
     * we had here before. Hopefully 30 seconds will be sufficient.
     *	    	    	    	-- ardeb 9/15/93
     */
    timeout.tv_usec = MOUNTD_RETRY_USEC;
    timeout.tv_sec = MOUNTD_RETRY_SEC;

    server->sin_port = 0;

    /*
     * Also wants unix credentials (?!)
     */
    auth = authunix_create_default();

    /*
     * Give the mount daemon lots of time.
     */
    rpc_stat = SunRpc_Call(mountdSock, server, auth,
			   MOUNTPROG, proc, MOUNTVERS,
			   xdr_path, &remote,
			   xdrret, retdata, MOUNTD_NUM_RETRIES, &timeout);

    /*
     * Don't need these any more...
     */
    auth_destroy(auth);
    
    return (rpc_stat == SUNRPC_SUCCESS);
}


/***********************************************************************
 *				ChildFetchNumericOption
 ***********************************************************************
 * SYNOPSIS:	    Fetch the value of a numeric option of the form
 *	    	    biff=n.
 * CALLED BY:	    ChildMount
 * RETURN:	    0 if the option not found or is hosed, else the value.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static int
ChildFetchNumericOption(mnt, opt)
    struct mntent   *mnt;   	/* Entry to search */
    char    	    *opt;   	/* Option desired */
{
    int     	    val=0;  	/* Current value */
    char    	    *equal; 	/* Position of = sign */
    char    	    *str;   	/* Start of option */
    
    /*
     * Locate the start of the option first.
     */
    str = hasmntopt(mnt, opt);
    if (str != NULL) {
	/*
	 * Option exists -- find the start of the value (just after the =)
	 */
	equal = (char *)index(str, '=');

	if (equal != NULL) {
	    val = atoi(equal+1);
	} else {
	    Message("ChildFetchNumericOption: bad numeric option '%s'\n", str);
	}
    }
    return (val);
}


/***********************************************************************
 *				ChildMount
 ***********************************************************************
 * SYNOPSIS:	    Mount a remote filesystem
 * CALLED BY:	    PREFIX_MOUNT
 * RETURN:	    1 if mount successful
 * SIDE EFFECTS:    An entry is placed in /etc/mtab if successful.
 *
 * STRATEGY:
 *	There are several stages in the mounting of a remote system:
 *	    - contact the mount daemon on the remote machine to get
 *	      the all-important first handle for the root of the
 *	      desired file-system, a handle via which all the other
 *	      handles and files for the system can be gotten.
 *	    - put together a set of nfs_args to pass to the kernel,
 *	      based on the information (serverName, remote, path, options)
 *	      we were passed.
 *	    - try 10 times to mount the system.
 *	    - if successful, add an entry to /etc/mtab for the system
 *	      and return 1.
 *	    - else return 0
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/89		Initial Revision
 *
 ***********************************************************************/
static void
ChildMount(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of call (s/b PREFIX_PORT) */
    Rpc_Message	    	msg;	    /* Message for reply/error */
    int			len;	    /* Length of passed data */
    Rpc_Opaque	    	data;	    /* Parameters (ChildData) */
    Rpc_Opaque	    	serverData; /* Data we gave (UNUSED) */
{
    ChildData	    	*params;    /* Passed parameters */
    struct fhstatus 	fhs;	    /* Result of call to mount daemon */
    struct nfs_args 	mount_args; /* Args for kernel mount call */
    int	    	    	flags;	    /* General mount flags */
    FILE	    	*mtab;	    /* Stream open to /etc/mtab for
				     * installing newly-mounted prefix */
    struct mntent	entry;	    /* New entry for /etc/mtab */
    char	    	fsname[128];/* Name of remote FS for entry */
    unsigned short  	port;	    /* Port number of NFS server */
    int	    	    	retval;	    /* Value we're returning */
    int	    	    	tries;	    /* Number of mount attempts */
    /*
     * Data extracted from params
     */
    char    	    	*serverName;/* Name of server */
    char    	    	*remote;    /* Directory to mount */
    char    	    	*path;	    /* Directory on which to mount it */
    char    	    	*options;   /* Options for the mount */

    /*
     * Minimal security: Make sure came from the right port.
     */
    if ((ntohs(from->sin_port) != PREFIX_PORT) || !Rpc_IsLocal(from)) {
	Rpc_Error(msg, RPC_ACCESS);
	return;
    }
    
    /*
     * Extract needed info from parameters
     */
    params  	= (ChildData *)data;
    serverName 	= params->data;
    remote  	= serverName + strlen(serverName) + 1;
    path    	= remote + strlen(remote) + 1;
    options 	= path + strlen(path) + 1;

    dprintf("ChildMount: mounting %s from %s[%s], opt=%s: ", path, serverName, remote, options);
    
    /*
     * Tell the kernel the name of the server
     */
    mount_args.flags = NFSMNT_HOSTNAME;
    mount_args.hostname = serverName;

    /*
     * Contact the remote daemon to get the initial file handle for the mount
     */
    if (!ChildCallMountd(&params->sin, serverName, remote, MOUNTPROC_MNT,
			 xdr_fhstatus, (caddr_t *)&fhs))
    {
	Message("ChildMount: couldn't contact %s's mount daemon", serverName);
mount_error:
	retval = 0;
	Rpc_Return(msg, sizeof(retval), (Rpc_Opaque)&retval);
	return;
    }
    
    /*
     * Check the return value (ChildCallMountd just returns the status
     * of the message, not the results of the call...)
     */
    if (fhs.fhs_status == NFSERR_ACCES) {
	Message("ChildMount: access denied for %s[%s]", serverName, remote);
	goto mount_error;
    } else if (fhs.fhs_status) {
	/*
	 * Set errno to be the status returned so perror can get at it
	 */
	errno = fhs.fhs_status;
	perror("ChildMount");
	goto mount_error;
    }

    
    /*
     * Tell the kernel where to find the FS
     */
    mount_args.fh   = &fhs.fhs_fh;
    mount_args.addr = &params->sin;

    /*
     * Set up the mount table entry and decode the options.
     */
    sprintf(fsname, "%s:%s", serverName, remote);

    entry.mnt_fsname 	= fsname;
    entry.mnt_dir   	= path;
    entry.mnt_type  	= MNTTYPE_NFS;
    entry.mnt_opts  	= options;
    entry.mnt_freq  	= 0;
    entry.mnt_passno 	= 0;

    flags = 0;

    /*
     * Take care of the universal flags first.
     */
    if (hasmntopt(&entry, MNTOPT_RO) != NULL) {
	dprintf("rdonly ");
	flags |= M_RDONLY;
    }
    if (hasmntopt(&entry, MNTOPT_NOSUID) != NULL) {
	dprintf("nosuid ");
	flags |= M_NOSUID;
    }
#ifdef MNTOPT_GRPID
    /*
     * SunOS 4.0 things...
     */
    flags |= M_NEWTYPE;
    if (hasmntopt(&entry, MNTOPT_GRPID) != NULL) {
	dprintf("grpid ");
	flags |= M_GRPID;
    }
    if (hasmntopt(&entry, MNTOPT_NOSUB) != NULL) {
	dprintf("nosub ");
	flags |= M_NOSUB;
    }
    /*XXX: what to do about "secure"? Do we have to contact mountd with
     * DES authentication? */
    
    if (mount_args.acregmin = ChildFetchNumericOption(&entry, "acregmin")) {
	dprintf("acregmin=%d ", mount_args.acregmin);
	mount_args.flags |= NFSMNT_ACREGMIN;
    }

    if (mount_args.acregmax = ChildFetchNumericOption(&entry, "acregmax")) {
	dprintf("acregmax=%d ", mount_args.acregmax);
	mount_args.flags |= NFSMNT_ACREGMAX;
    }

    if (mount_args.acdirmin = ChildFetchNumericOption(&entry, "acdirmin")) {
	dprintf("acdirmin=%d ", mount_args.acdirmin);
	mount_args.flags |= NFSMNT_ACDIRMIN;
    }

    if (mount_args.acdirmax = ChildFetchNumericOption(&entry, "acdirmax")) {
	dprintf("acdirmax=%d ", mount_args.acdirmax);
	mount_args.flags |= NFSMNT_ACDIRMAX;
    }

    if (hasmntopt(&entry, "noac") != NULL) {
	mount_args.flags |= NFSMNT_NOAC;
    }
#endif /* MNTOPT_GRPID */

    /*
     * Now the nfs-specific ones
     */
    if (hasmntopt(&entry, MNTOPT_SOFT) != NULL) {
	dprintf("soft ");
	mount_args.flags |= NFSMNT_SOFT;
    }
    if (hasmntopt(&entry, MNTOPT_INTR) != NULL) {
	dprintf("intr ");
	mount_args.flags |= NFSMNT_INT;
    }
    if (mount_args.rsize = ChildFetchNumericOption(&entry, "rsize")) {
	dprintf("rsize=%d ", mount_args.rsize);
	mount_args.flags |= NFSMNT_RSIZE;
    }
    if (mount_args.wsize = ChildFetchNumericOption(&entry, "wsize")) {
	dprintf("wsize=%d ", mount_args.wsize);
	mount_args.flags |= NFSMNT_WSIZE;
    }
    if (mount_args.timeo = ChildFetchNumericOption(&entry, "timeo")) {
	dprintf("timeo=%d ", mount_args.timeo);
	mount_args.flags |= NFSMNT_TIMEO;
    }
    if (mount_args.retrans = ChildFetchNumericOption(&entry, "retrans")) {
	dprintf("retrans=%d ", mount_args.retrans);
	mount_args.flags |= NFSMNT_RETRANS;
    }
    if (port = ChildFetchNumericOption(&entry, "port")) {
	dprintf("port=%d ", port);
	params->sin.sin_port = htons(port);
    } else {
	params->sin.sin_port = htons(NFS_PORT); /* XXX should use portmapper */
    }
    dprintf("\n");

    /*
     * Assume success
     */
    retval = 1;

    /*
     * Try the mount 10 times, sleeping 1/10th of a second between tries.
     */
    tries = 0;
    while (mount(MOUNT_NFS, path, flags, &mount_args) < 0) {
	if (++tries > 10 || errno != EBUSY) {
	    /*
	     * Mount failed -- notify user and break out.
	     */
	    perror(path);
	    retval = 0;
	    break;
	}
	/*
	 * Sleep a 1/10th of a second before trying again.
	 */
	usleep(100000);
    }
	    
    if (retval) {
	/*
	 * Now store the entry in /etc/mtab
	 */
	dprintf("adding %s to %s\n", fsname, MOUNTED);

	mtab = setmntent(MOUNTED, "r+");
	if (addmntent(mtab, &entry)) {
	    dprintf("addmntent failed\n");
	}
	endmntent(mtab);
    }

    /*
     * Return result
     */
    Rpc_Return(msg, sizeof(retval), (Rpc_Opaque)&retval);
}


/***********************************************************************
 *				ChildMountLocal
 ***********************************************************************
 * SYNOPSIS:	    Mount a prefix on the local prefix daemon
 * CALLED BY:	    PREFIX_MOUNT_LOCAL
 * RETURN:	    1 if successful
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/89		Initial Revision
 *
 ***********************************************************************/
static void
ChildMountLocal(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of message */
    Rpc_Message	    	msg;	    /* Message for reply/error */
    int	    	    	len;	    /* Length of passed data */
    Rpc_Opaque	    	data;	    /* Parameters */
    Rpc_Opaque	        serverData; /* Data we gave (UNUSED) */
{
    ChildData	    	*params;    /* Parameters for call (addr and
				     * handle and path) */
    struct nfs_args 	mount_args; /* Args for the mounting */
    int	    	    	retval;	    /* Value to return */
    /*
     * Params extracted from data
     */
    fhandle_t	    	*handle;    /* Handle the kernel will use */
    char    	    	*path;	    /* Local path of prefix */
    int	    	    	flags;	    /* Flags for mount call */


    /*
     * Verify source of message
     */
    if ((ntohs(from->sin_port) != PREFIX_PORT) || !Rpc_IsLocal(from)) {
	Rpc_Error(msg, RPC_ACCESS);
	return;
    }
    
    /*
     * Unpackage parameters
     */
    params  = (ChildData *)data;
    handle  = (fhandle_t *)params->data;
    path    = params->data + sizeof(*handle);
    
    dprintf("ChildMountLocal: path = %s\n", path);

    /*
     * Set up nfs_args structure for the mount.
     * All of our mount points are given a timeout of 3 seconds and
     * 4 attempts to contact us. The 3 seconds are because that's
     * how long we'll broadcast looking for a prefix and the 4
     * attempts are to keep the system from grinding to a complete
     * halt if we die (knock on wood...)
     */
    mount_args.addr 	= &params->sin;
    mount_args.fh   	= handle;
    mount_args.flags	=
	NFSMNT_HOSTNAME|NFSMNT_SOFT|NFSMNT_TIMEO|NFSMNT_RETRANS;
    mount_args.hostname	= MOUNT_NAME;
    mount_args.timeo	= 30;		/* Length of broadcast */
    mount_args.retrans	= 4;		/* # retrans (try four times) */

#ifdef NFSMNT_NOAC
    /*
     * SunOS 4.0: Make darn sure the kernel asks us about everything...
     */
    mount_args.flags	|= NFSMNT_NOAC;
#endif /* NFSMNT_NOAC */

    /*
     * Mount the prefix READ ONLY -- might as well forestall any
     * calls to do things we can't...
     */
    flags = M_RDONLY;

#ifdef M_NEWTYPE
    flags |= M_NEWTYPE;		/* SunOS 4.0 requires this */
#endif /* M_NEWTYPE */

    if (mount(MOUNT_NFS, path, flags, &mount_args) < 0) {
	perror(path);
	retval = 0;
    } else {
	retval = 1;
    }

    dprintf("return(%d)\n", retval);
    Rpc_Return(msg, sizeof(retval), (Rpc_Opaque)&retval);
}


/***********************************************************************
 *				ChildUnmount
 ***********************************************************************
 * SYNOPSIS:	    Unmount a remote-mounted prefix
 * CALLED BY:	    PREFIX_UNMOUNT
 * RETURN:	    1 if successful, 0 if not
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/89		Initial Revision
 *
 ***********************************************************************/
static void
ChildUnmount(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of message */
    Rpc_Message	    	msg;	    /* Message for reply/error */
    int	    	    	len;	    /* Length of passed data */
    Rpc_Opaque	    	data;	    /* ChildData with server address,
				     * name, remote directory and local
				     * path */
    Rpc_Opaque	        serverData; /* Data we gave (UNUSED) */
{
    ChildData	    	*params;    /* Our version of data */
    int	    	    	retval;	    /* Value to return */
    /*
     * Data extracted from params
     */
    char    	    	*serverName;
    char		*remote;
    char		*path;

    if ((ntohs(from->sin_port) != PREFIX_PORT) || !Rpc_IsLocal(from)) {
	Rpc_Error(msg, RPC_ACCESS);
	return;
    }

    params  	= (ChildData *)data;
    serverName 	= params->data;
    remote  	= serverName + strlen(serverName) + 1;
    path    	= remote + strlen(remote) + 1;

    dprintf("ChildUnmount: unmounting %s from %s[%s]: ", path, serverName,
	    remote);

    /*
     * Try and unmount the thing.
     */
    if (unmount(path) < 0) {
	if (errno == EINVAL) {
	    /*
	     * EINVAL from unmount means the thing wasn't actually mounted.
	     * We want this to appear as a succesful unmount, as it allows
	     * the user to explicitly unmount a prefix without our getting
	     * confused.
	     */
	    dprintf("wasn't mounted\n");
	    retval = 1;
	} else {
	    extern int sys_nerr;
	    extern char *sys_errlist[];

	    dprintf("error: %s\n",
		    errno > sys_nerr ? "Unknown" : sys_errlist[errno]);
	    retval = 0;
	}
    } else {
	/*
	 * Need to remove from /etc/mtab and tell the remote mount daemon
	 * the thing's no longer mounted.
	 */
	FILE	    	*mtab;	    /* Old table of mounted systems */
	FILE	    	*nmtab;	    /* New table of mounted systems */
	struct mntent	*entry;	    /* Current entry in same */
	char	    	tmtab[20];  /* Name for new table */
	char	    	fsname[128];/* System being unmounted */
	
	dprintf("successful...contacting mount daemon: ");
	if (!ChildCallMountd(&params->sin, serverName, remote, MOUNTPROC_UMNT,
			      xdr_void, NULL))
	{
	    dprintf("failed\n");
	} else {
	    dprintf("successful\n");
	}

	/*
	 * Remove the prefix from the table of mounted systems by
	 * copying all entries except the one just unmounted to a new mtab.
	 * Filename formed this way to deal with gcc storing strings in
	 * text (of which we approve).
	 */
	strcpy(tmtab, MOUNTED);
	strcat(tmtab, "XXXXXX");
	mktemp(tmtab);
	
	sprintf(fsname, "%s:%s", serverName, remote);
	
	mtab = setmntent(MOUNTED, "r");
	nmtab = setmntent(tmtab, "w");
	
	while ((entry = getmntent(mtab)) != NULL) {
	    if (strcmp(entry->mnt_fsname, fsname) != 0) {
		addmntent(nmtab, entry);
	    }
	}
	
	/*
	 * Close both
	 */
	endmntent(mtab);
	endmntent(nmtab);
	
	/*
	 * Use atomic rename to replace old mtab.
	 */
	rename(tmtab, MOUNTED);

	/*
	 * Success.
	 */
	retval = 1;
    }

    Rpc_Return(msg, sizeof(retval), (Rpc_Opaque)&retval);
}
	     

/***********************************************************************
 *				ChildUnmountLocal
 ***********************************************************************
 * SYNOPSIS:	    Unmount a prefix from local daemon. This is
 *	    	    just to be safe, you understand...
 * CALLED BY:	    PREFIX_UNMOUNT_LOCAL
 * RETURN:	    1 if successful
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/89		Initial Revision
 *
 ***********************************************************************/
static void
ChildUnmountLocal(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of message */
    Rpc_Message	    	msg;	    /* Message for reply/error */
    int	    	    	len;	    /* Length of parameters */
    Rpc_Opaque	    	data;	    /* Parameters (path to unmount) */
    Rpc_Opaque	        serverData; /* Data we gave (UNUSED) */
{
    int	    	    	retval;	    /* Return value */

    if ((ntohs(from->sin_port) != PREFIX_PORT) || !Rpc_IsLocal(from)) {
	Rpc_Error(msg, RPC_ACCESS);
    } else {
	dprintf("ChildUnmountLocal: unmounting %s...", (char *)data);
	retval = unmount((char *)data);
	if (retval < 0) {
	    if (errno == EINVAL) {
		/*
		 * If it wasn't mounted anyway, we're happy.
		 */
		retval = 0;
	    } else {
		retval = 0;
		perror((char *)data);
	    }
	} else {
	    retval = 1;
	}
	dprintf("return(%d)\n", retval);
	Rpc_Return(msg, sizeof(retval), &retval);
    }
}

/***********************************************************************
 *				ChildChangeDebug
 ***********************************************************************
 * SYNOPSIS:	    Change our "debug" variable to match the parent's
 * CALLED BY:	    PREFIX_DEBUG
 * RETURN:	    1
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/11/94		Initial Revision
 *
 ***********************************************************************/
static void
ChildChangeDebug(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of message */
    Rpc_Message	    	msg;	    /* Message for reply/error */
    int	    	    	len;	    /* Length of parameters */
    Rpc_Opaque	    	data;	    /* Parameters (data for "debug" var) */
    Rpc_Opaque	        serverData; /* Data we gave (UNUSED) */
{
    int	    	    	retval;	    /* Return value */

    if ((ntohs(from->sin_port) != PREFIX_PORT) || !Rpc_IsLocal(from)) {
	Rpc_Error(msg, RPC_ACCESS);
    } else {
	bcopy((char *)data, (char *)&debug, sizeof(debug));
	retval = 1;
	dprintf("return(%d)\n", retval);
	Rpc_Return(msg, sizeof(retval), &retval);
    }
}
    

/***********************************************************************
 *				Child_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module
 * CALLED BY:	    BeFiendish
 * RETURN:	    1 if successful.
 * SIDE EFFECTS:    A new process is created.
 *
 * STRATEGY:
 *	- Create the socket over which communication will pass
 *	- Fetch the socket's address
 *	- Create mountdSock
 *	- Fork. If parent, close childSock and mountdSock and return 1
 *	- Child: run RPC system.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/89		Initial Revision
 *
 ***********************************************************************/
int
Child_Init()
{
    int	    	    	len;
    struct sockaddr_in	sin;
    unsigned short  	port;
    int	    	    	err;
    
    /*
     * XXX: Use socketpair(AF_UNIX)? Not sure what it would do with a
     * sendto, though, and I'd have to rewrite the RPC system to understand
     * AF_UNIX if it couldn't take it. Advantage is the channel would be
     * private.
     */
    childSock = Rpc_UdpCreate(TRUE, 0);
    if (childSock < 0) {
	perror("Rpc_UdpCreate(child)");
	return(0);
    }

    len = sizeof(childAddr);
    if (getsockname(childSock, &childAddr, &len) < 0) {
	perror("getsockname(child)");
	return(0);
    }
    childAddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    
    /*
     * Create and initialize a socket over which we can communicate with
     * a remote mount daemon. Such a socket must have an address in the
     * range 512 - 1023 (the privileged area of the UDP address space) in
     * order for the remote daemon to accept our credentials.
     * NOTE: can't use Rpc_UdpCreate since that will bind only one port or
     * any, not any of a range.
     */
    mountdSock = socket(AF_INET, SOCK_DGRAM, 0);
    if (mountdSock < 0) {
	perror("socket(mountd)");
	return(0);
    }
 
#define MAX_PRIV (IPPORT_RESERVED-1)
#define MIN_PRIV (IPPORT_RESERVED/2)

    /*
     * Initialize constant part of address: family and address
     */
    bzero(&sin, sizeof sin);
    get_myaddress(&sin);
    sin.sin_family = AF_INET;

    /*
     * Loop over all untaken privileged ports (i.e. upper half of range),
     * trying to bind the socket to each in turn. If succeed, end up
     * with err being zero and the socket bound.
     */
    for (err = -1, port = MAX_PRIV; err && port >= MIN_PRIV; port--) {
	sin.sin_port = htons(port);
	err = bind(mountdSock, &sin, sizeof(sin));
    }

    if (err == -1) {
	perror("binding mountd socket");
	return(0);
    }

    /*
     * All set -- create the child process
     */
    switch(childID = fork()) {
	case 0:
	    /*
	     * Don't pay attention to anything else
	     */
	    Rpc_Reset();
	    (void)close(prefixSock);
	    /*
	     * Register the three servers. Note that even though we
	     * pass binary data, there's no need for swapping, since the
	     * communication happens on the local machine.
	     */
	    Rpc_ServerCreate(childSock, PREFIX_MOUNT, ChildMount,
			     NULL, NULL, NULL);
	    Rpc_ServerCreate(childSock, PREFIX_MOUNT_LOCAL, ChildMountLocal,
			     NULL, NULL, NULL);
	    Rpc_ServerCreate(childSock, PREFIX_UNMOUNT, ChildUnmount,
			     NULL, NULL, NULL);
	    Rpc_ServerCreate(childSock, PREFIX_UNMOUNT_LOCAL,ChildUnmountLocal,
			     NULL, NULL, NULL);
	    Rpc_ServerCreate(childSock, PREFIX_DEBUG, ChildChangeDebug,
			     Rpc_SwapLong, NULL, NULL);
	    /*
	     * Perform similar std stream manipulations to sibling to
	     * allow logging and invocation by rshd. Again, we change our
	     * process group so opening the console doesn't make it our
	     * controlling terminal.
	     */
	    setpgrp(0, getpid());
	    freopen("/dev/console", "w", stderr);
	    (void)close(0);
	    (void)close(1);
	    
	    /*
	     * Run the RPC system -- never returns.
	     */
	    dprintf("child prefix daemon alive and running...\n");
	    Rpc_Run();
	case -1:
	    perror("fork(child)");
	    return(0);
	default:
	    /*
	     * Close the two sockets and return success
	     */
	    (void)close(mountdSock);
	    (void)close(childSock);
	    return(1);
    }
}


/***********************************************************************
 *				Child_Call
 ***********************************************************************
 * SYNOPSIS:	    Issue a call to the child process.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    1 if the call succeeded, 0 if not
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 9/89		Initial Revision
 *
 ***********************************************************************/
int
Child_Call(pp, proc)
    Prefix  	*pp;	    /* Prefix for which to call */
    Rpc_Proc   	proc;	    /* Procedure to invoke (PREFIX_MOUNT or
			     * PREFIX_UNMOUNT or PREFIX_MOUNT_LOCAL) */
{
    struct timeval  retry;  /* Retransmission interval */
    Rpc_Stat	status;	    /* Result of call */
    int	    	success;    /* Return data: non-zero if operation
			     * succeeded */
    ChildData	data;	    /* Data to pass to child */
    char    	*cp;	    /* Current position in data.data */

    retry.tv_sec = 2;
    retry.tv_usec = 0;
    
    switch (proc) {
	case PREFIX_MOUNT:
	case PREFIX_UNMOUNT:
	{
	    /*
	     * Both of these require the parameters for the remote
	     * machine.
	     */
	    int	    	len;	    /* Length remaining in data.data */
	    int	    	slen;	    /* Length of current string */
	    
	    /*
	     * Pass the server's address
	     */
	    data.sin = pp->server;
	    
	    /*
	     * Set up vars...
	     */
	    len = CHILD_MAX_DATA;
	    cp = data.data;
	    
	    /*
	     * Server's name comes first
	     */
	    slen = strlen(pp->serverName);
	    if (slen < len) {
		strcpy(cp, pp->serverName);
		cp += slen + 1;
		len -= slen+1;
	    } else {
		return(0);
	    }
	    
	    /*
	     * Then the remote directory name
	     */
	    slen = strlen(pp->remote);
	    if (slen < len) {
		strcpy(cp, pp->remote);
		cp += slen + 1;
		len -= slen+1;
	    } else {
		return(0);
	    }
	    
	    /*
	     * Then the local directory name
	     */
	    slen = strlen(pp->path);
	    if (slen < len) {
		strcpy(cp, pp->path);
		cp += slen + 1;
		len -= slen+1;
	    } else {
		return(0);
	    }
	    
	    /*
	     * If mounting, pass the mount options too.
	     */
	    if (proc == PREFIX_MOUNT) {
		int soptlen = strlen(pp->servOpts);
		
		slen = strlen(pp->options) + soptlen + (soptlen ? 1 : 0);
		if (slen < len) {
		    if (soptlen) {
			dprintf("servopts = \"%s\", prefopts = \"%s\"\n",
				pp->servOpts, pp->options);
			strcpy(cp, pp->servOpts);
			cp[soptlen] = ',';
			strcpy(cp+soptlen+1, pp->options);
		    } else {
			dprintf("prefopts = \"%s\"\n", pp->options);
			strcpy(cp, pp->options);
		    }
		    cp += slen + 1;
		    len -= slen+1;
		} else {
		    return(0);
		}
	    }
	    break;
	}
	case PREFIX_MOUNT_LOCAL:
	    /*
	     * Just need to pass prefixMountAddr, a handle and the local
	     * directory.
	     */

	    data.sin = prefixMountAddr;

	    PrefixToHandle(pp, data.data);

	    cp = data.data + sizeof(fhandle_t);
	    strcpy(cp, pp->path);
	    cp += strlen(cp) + 1;
	    break;
	case PREFIX_UNMOUNT_LOCAL:
	    /*
	     * Just need to pass the path.
	     */
	    strcpy((char *)&data, pp->path);

	    cp = (char *)&data + strlen(pp->path) + 1;
	    break;
    	case PREFIX_DEBUG:
	    bcopy(&debug, (char *)&data, sizeof(debug));
	    cp = (char *)&data + sizeof(debug);
	    break;
	default:
	    /*
	     * What the heck?
	     */
	    return(0);
    }
    
    /*
     * Issue the call, passing only as much data as are available.
     * We lock the prefix in the meantime b/c this call implies a change
     * of state that should not be used until the call completes. Because
     * of the nature of our rpc system, however, we could very well get
     * a request for the prefix while waiting for this call. Anything that
     * depends on whether a prefix is mounted obeys the locking protocol.
     */
    if (pp != NULL) {
	PrefixLock(pp);
    }
    status = Rpc_Call(prefixSock, &childAddr, proc,
		      cp - (char *)&data, (Rpc_Opaque)&data,
		      sizeof(success), (Rpc_Opaque)&success,
		      NUM_RETRIES, &retry);
    if (pp != NULL) {
	PrefixUnlock(pp);
    }

    if (status != RPC_SUCCESS) {
	/*
	 * Call didn't get through -- return error.
	 */
	dprintf("Child_Call: %s\n", Rpc_ErrorMessage(status));
	return(0);
    } else {
	/*
	 * Return what we were told to return.
	 */

	return(success);
    }
}


/***********************************************************************
 *				Child_MountSpecial
 ***********************************************************************
 * SYNOPSIS:	    Mount a special prefix locally.
 * CALLED BY:	    BeFiendish to mount MOUNT_DIR
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Call PREFIX_MOUNT_LOCAL, passing it prefixMountAddr, but with
 *	the given port and storing the path as the handle, rather than
 *	a prefix address.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/89		Initial Revision
 *
 ***********************************************************************/
int
Child_MountSpecial(port, path)
    unsigned short  port;   	/* Port kernel should use */
    char    	    *path;  	/* Directory to mount */
{
    ChildData	    data;   	/* Data to pass */
    char    	    *cp;    	/* Points past last byte of data */
    int	    	    success;	/* Return value */
    struct timeval  retry;  	/* Retransmission interval */
    Rpc_Stat	    status;	/* Status of call */

    /*
     * Address is the same as the prefix address, except for the port number
     */
    data.sin = prefixMountAddr;
    data.sin.sin_port = htons(port);

    /*
     * Set up the handle to use (type PH_SPECIAL -- if we get more,
     * we'll need to add more info).
     */
    bzero(data.data, sizeof(fhandle_t));
    ((PrefixHandle *)data.data)->type = PH_SPECIAL;
    cp = data.data + sizeof(fhandle_t);

    /*
     * Pass the path as the mount point
     */
    strcpy(cp, path);
    cp += strlen(path) + 1;

    /*
     * 1-second retransmission interval
     */
    retry.tv_sec = 1;
    retry.tv_usec = 0;

    /*
     * Call the child...
     */
    status = Rpc_Call(prefixSock, &childAddr, PREFIX_MOUNT_LOCAL,
		     cp - (char *)&data, (Rpc_Opaque)&data,
		     sizeof(success), (Rpc_Opaque)&success,
		     NUM_RETRIES, &retry);

    if (status != RPC_SUCCESS) {
	perror("Rpc_Call");
	dprintf("Child_MountSpecial: %s\n", Rpc_ErrorMessage(status));
	return(0);
    } else {
	return(success);
    }
}


/***********************************************************************
 *				Child_Kill
 ***********************************************************************
 * SYNOPSIS:	    Blow away the child process
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The child be savagely, brutally murdered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/89		Initial Revision
 *
 ***********************************************************************/
void
Child_Kill()
{
    kill(childID, 9);
}

