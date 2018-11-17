/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Exportation
 * FILE:	  export.c
 *
 * AUTHOR:  	  Adam de Boor: Jul  5, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Export_Prefix	    Export a directory as a prefix
 *	Export_Send 	    Send list of exported prefixes to the local
 *	    	    	    daemon.
 *	Export_Init 	    Initialize the module.
 *	Export_Dump 	    Dump list of exported prefixes into a buffer.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 5/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to handle exporting of various prefixes. Doesn't take
 *	the place of the standard mount daemon. Just responds to queries
 *	about where a prefix is defined.
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
"$Id: export.c,v 1.10 91/07/24 17:48:33 adam Exp $";
#endif lint

#include    "prefix.h"
#include    "rpc.h"

#include    <ctype.h>
#include    <netdb.h>
#include    <arpa/inet.h>
#include    <exportent.h>

typedef struct {
    char    	*fsname;    	/* Name of file system being exported */
    char    	*prefix;    	/* Prefix under which it's being exported */
    int	    	active:1,    	/* Actively exported. An inactively
				 * exported prefix is one that the user
				 * wants to delete, but can't because
				 * some client is using the FS. Setting this
				 * false keeps ExportLocate from responding */
		local:1;    	/* Export prefix only to a machine on a net
				 * to which we are physically connected */
    char    	*options;   	/* Mount options the importer should use */
} Export;

static Lst  exports;


/***********************************************************************
 *				ExportLocate
 ***********************************************************************
 * SYNOPSIS:	    Handle a PREFIX_LOCATE broadcast call
 * CALLED BY:	    Rpc module
 * RETURN:	    Local directory, if we're exporting the prefix
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 6/89		Initial Revision
 *
 ***********************************************************************/
static void
ExportLocate(from, msg, dataLen, data, serverData)
    struct sockaddr_in	    *from;  	/* Source of call */
    Rpc_Opaque	    	    msg;    	/* Message token for reply */
    int	    	    	    dataLen;	/* Length of passed data */
    Rpc_Opaque	    	    data;   	/* Name of prefix being sought */
    Rpc_Opaque	    	    serverData;	/* JUNK */
{
    dprintf("LOCATE from %s for %s\n", InetNtoA(from->sin_addr),
	    data);
	    
    if (exports) {
	LstNode 	    ln;
	Export  	    *ep;
	
	for (ln = Lst_First(exports); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    ep = (Export *)Lst_Datum(ln);

	    if ((strcmp(ep->prefix, (char *)data) == 0) && ep->active &&
		(!ep->local || Rpc_IsLocalNet(from)))
	    {
		/*
		 * We've got it -- answer the call (follow the fold
		 * and stray no more! Stray no more! ...)
		 *
		 * 3/11/94: append options we insist on the client using. This
		 * is backwards-compatible, since the client looks at the result
		 * up to the null, and a new client will check the length
		 * returned from an old daemon and see there can't possibly be
		 * options. -- ardeb
		 */
		int 	fslen = strlen(ep->fsname);
		int 	optlen = strlen(ep->options);
		char	*result = (char *)malloc(fslen + 1 + optlen + 1);

		strcpy(result, ep->fsname);
		strcpy(result+fslen+1, ep->options);

		Rpc_Return(msg, fslen + 1 + optlen + 1, result);

		free((char *)result);
		break;
	    }
	}
    }
}


/***********************************************************************
 *				Export_Prefix
 ***********************************************************************
 * SYNOPSIS:	    Arrange to export a directory under a prefix
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An Export structure is added to the exports list
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
Export_Prefix(fsname, prefix, local, options)
    char    	*fsname;    	/* Filesystem being exported */
    char    	*prefix;    	/* Name under which it's being exported */
    Boolean 	local;	    	/* Restrict export to only local network */
    char    	*options;   	/* Options client must use */
{
    Export  	*ep;
    FILE    	*ef;
    LstNode 	ln;
    
    if (exports == NULL) {
	exports = Lst_Init(FALSE);
    }

    dprintf("export %s as %s\n", fsname, prefix);

    /*
     * See if we're replacing an existing prefix...
     */
    for (ln = Lst_First(exports); ln != NILLNODE; ln = Lst_Succ(ln)) {
	ep = (Export *)Lst_Datum(ln);

	if (strcmp(prefix, ep->prefix) == 0) {
	    break;
	}
    }
    if (ln == NILLNODE) {
	/*
	 * Nope -- allocate a new Export record and stick it on the end
	 * of the list.
	 */
	ep = (Export *)malloc(sizeof(Export));
	(void)Lst_AtEnd(exports, (ClientData)ep);
    }

    /*
     * Save the parameters in the record
     */
    ep->fsname = fsname;
    ep->prefix = prefix;
    ep->active = TRUE;
    ep->local = local;
    ep->options = options;

    if (index(ep->fsname, ':') == NULL) {
	/*
	 * Make sure the filesystem is exported, warning if it isn't.
	 * NOTE: Can't use setexportent/getexportent here because we're
	 * loaded before exportfs has been run, so nothing seems to be
	 * exported.
	 */
	ef = fopen(EXPORTS, "r");
	if (ef == NULL) {
	    Message("/etc/exports doesn't exist -- %s won't be allowed out",
		    fsname);
	} else {
	    char	line[512];
	    int 	fslen = strlen(fsname);

	    while (fgets(line, sizeof(line), ef) != NULL) {
		if (strncmp(line, fsname, fslen) == 0) {
		    if (isspace(line[fslen])) {
			/*
			 * Matched entire exported directory, so
			 * this thing is kosher.
			 */
		    	fclose(ef);
			return;
		    } else {
			/*
			 * Find the first char that mismatches between the fs
			 * we're trying to export and the entry in the exports
			 * file.
			 */
			int i;

			for (i = 0; i < fslen; i++) {
			    if (line[i] != fsname[i]) {
				break;
			    }
			}
			if (isspace(line[i]) && fsname[i] == '/') {
			    /*
			     * The directory being exported is a subdirectory
			     * of this entry in /etc/exports. If they're on
			     * the same device, we'll assume the prefix will
			     * be exported (though the docs don't really state
			     * this explicitly, it does seem to be the case).
			     */
			    struct stat stb1, stb2;

			    line[i] = '\0';
			    if ((stat(line, &stb1) == 0) &&
				(stat(fsname, &stb2) == 0) &&
				(stb1.st_rdev == stb2.st_rdev))
			    {
				fclose(ef);
				return;
			    }
			}
		    }
		}
	    }
	    fclose(ef);
	    Message("%s not in /etc/exports -- won't be allowed out", fsname);
	}
    }
}
    

/***********************************************************************
 *				ExportExport
 ***********************************************************************
 * SYNOPSIS:	    Export another directory as a prefix
 * CALLED BY:	    PREFIX_EXPORT
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An Export record is added to the exports list
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
ExportExport(from, msg, len, data, serverData)
    struct sockaddr_int	*from;
    Rpc_Message	    	msg;
    int	    	    	len;
    Rpc_Opaque	    	data;	/* Buffer holding both dir (first string)
				 * and prefix, separated by a null character */
    Rpc_Opaque	    	serverData;	/* Data we gave (UNUSED) */
{
    char    	*cp;
    char	*args = (char *)data;
    char	*fsname;
    char	*prefix;
    char    	*options;

    cp = args + strlen(args) + 1;

    fsname = (char *)malloc(strlen(args) + 1);
    strcpy(fsname, args);

    prefix = (char *)malloc(strlen(cp) + 1);
    strcpy(prefix, cp);

    cp += strlen(cp) + 1;
    options = (char *)malloc(strlen(cp) + 1);
    strcpy(options, cp);

    Export_Prefix(fsname, prefix, False, options);

    Rpc_Return(msg, 0, NULL);
}


/***********************************************************************
 *				ExportExportLocal
 ***********************************************************************
 * SYNOPSIS:	    Export another directory as a prefix for the local
 *		    network only.
 * CALLED BY:	    PREFIX_EXPORT_LOCAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An Export record is added to the exports list
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
ExportExportLocal(from, msg, len, data, serverData)
    struct sockaddr_int	*from;
    Rpc_Message	    	msg;
    int	    	    	len;
    Rpc_Opaque	    	data;	/* Buffer holding both dir (first string)
				 * and prefix, separated by a null character */
    Rpc_Opaque	    	serverData;	/* Data we gave (UNUSED) */
{
    char    	*cp;
    char	*args = (char *)data;
    char	*fsname;
    char	*prefix;
    char    	*options;

    cp = args + strlen(args) + 1;

    fsname = (char *)malloc(strlen(args) + 1);
    strcpy(fsname, args);

    prefix = (char *)malloc(strlen(cp) + 1);
    strcpy(prefix, cp);

    cp += strlen(cp) + 1;
    options = (char *)malloc(strlen(cp) + 1);
    strcpy(options, cp);

    Export_Prefix(fsname, prefix, True, options);

    Rpc_Return(msg, 0, NULL);
}

/***********************************************************************
 *				Export_Send
 ***********************************************************************
 * SYNOPSIS:	    Send all exported prefixes to the local daemon
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 7/89		Initial Revision
 *
 ***********************************************************************/
void
Export_Send(server)
    struct sockaddr_in	    *server;
{
    LstNode	    ln;	    	/* Node in exports list */
    Export  	    *ep;    	/* Current exported prefix */
    char    	    buf[512];	/* Transmission buffer */
    int	    	    len;    	/* Length of parameters */
    struct timeval  retry;  	/* Retransmission interval */
    Rpc_Stat	    status; 	/* Status of call */
    char    	    *cp;

    retry.tv_sec = 1;
    retry.tv_usec = 0;
    
    if (exports) {
	for (ln = Lst_First(exports); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    ep = (Export *)Lst_Datum(ln);

	    cp = buf;
	    
	    len = strlen(ep->fsname);
	    strcpy(cp, ep->fsname);
	    cp += strlen(cp)+1;

	    strcpy(cp,ep->prefix);
	    cp += strlen(cp)+1;

	    strcpy(cp, ep->options);
	    cp += strlen(cp)+1;

	    status = Rpc_Call(prefixSock, server,
			      ep->local ? PREFIX_EXPORT_LOCAL : PREFIX_EXPORT,
			      cp - buf, buf,
			      0, NULL,
			      2, &retry);
	    if (status != RPC_SUCCESS) {
		fprintf(stderr, "Couldn't export %s as %s (%s)\n", ep->fsname,
			ep->prefix, Rpc_ErrorMessage(status));
	    }
	}
    }
}


/***********************************************************************
 *				Export_Dump
 ***********************************************************************
 * SYNOPSIS:	    Dump the list of exported prefixes into a buffer.
 * CALLED BY:	    DumpPrefix
 * RETURN:	    *leftPtr adjusted to reflect space remaining.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Each exported prefix is placed in the buffer as:
 *	    x<fsname>:<prefix>\n
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
void
Export_Dump(buf, leftPtr)
    char    	*buf;	    /* Place to start storing */
    int	    	*leftPtr;   /* IN/OUT: remaining room in buf */
{
    LstNode 	ln;
    Export  	*ep;

    if (exports) {
	for (ln = Lst_First(exports); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    int	    entlen;
	    
	    ep = (Export *)Lst_Datum(ln);
	    entlen = 1+strlen(ep->fsname)+1+strlen(ep->prefix)+1+2;

	    if (*leftPtr >= entlen) {
		sprintf(buf, "x%s|%s|%c\n", ep->fsname, ep->prefix,
			'0' | (ep->active ? 1 : 0) | (ep->local ? 2 : 0));
		buf += entlen;
		*leftPtr -= entlen;
	    }
	}
    }
}


/***********************************************************************
 *				ExportUnmountResponse
 ***********************************************************************
 * SYNOPSIS:	    Handle a response to our PREFIX_UNMOUNT call
 * CALLED BY:	    Rpc_Broadcast
 * RETURN:	    FALSE (keep broadcasting)
 * SIDE EFFECTS:    *msgPtr advanced.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/11/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
ExportUnmountResponse(from, len, data, msgPtr, serverData)
    struct sockaddr_in	*from;	    /* Source of reply */
    int	    	    	len;	    /* Length of returned data */
    Rpc_Opaque	    	data;	    /* Returned data (s/b none) */
    char    	    	**msgPtr;   /* Place to store hostname (message
				     * being formed for return to caller) */
    Rpc_Opaque	    	serverData; /* Data we gave (UNUSED) */
{
    struct hostent  	*he;

    he = gethostbyaddr(&from->sin_addr, sizeof(from->sin_addr), AF_INET);

    sprintf(*msgPtr, "%s, ", he ? he->h_name : InetNtoA(from->sin_addr));
    *msgPtr += strlen(*msgPtr);

    return(FALSE);
}


/***********************************************************************
 *				ExportDelete
 ***********************************************************************
 * SYNOPSIS:	    Delete an exported prefix
 * CALLED BY:	    PREFIX_NOEXPORT
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If the prefix exists in the export record, it is
 *	    	    deleted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static void
ExportDelete(from, msg, len, data, serverData)
    struct sockaddr_in	*from;	    /* Source of data */
    Rpc_Message		msg;	    /* Message for reply/return */
    int			len;	    /* Length of prefix (including null) */
    Rpc_Opaque		data;	    /* Null-terminated prefix */
    Rpc_Opaque 	    	serverData; /* Data we gave (UNUSED) */
{
    char	    	ansbuf[1024];	/* Buffer for response (1K
					 * enough?) */
    char    	    	*answer = "Ok";	/* Assume ok */

    if (exports) {
	LstNode	    	ln; 	/* Node for current exported prefix */
	Export	    	*ep;	/* Exported prefix being checked */

	for (ln = Lst_First(exports); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    ep = (Export *)Lst_Datum(ln);

	    if (strcmp(ep->prefix, (char *)data) == 0) {
		struct timeval	retry;	    	/* Retrans interval for
						 * broadcast */
		char	    	*cp;	    	/* Pointer to pass to
						 * Rpc_Broadcast */
		Rpc_Stat    	status;	    	/* Status of broadcast */
		
		/*
		 * Tell the world the prefix is going away, after marking the
		 * prefix as inactive, preventing us from exporting it
		 * during the broadcast.
		 *
		 * Note that we assume the nets on which we search are also
		 * the nets on which we will be searched, so a broadcast there
		 * will catch everyone who might have the prefix mounted.
		 */
		ep->active = FALSE;

		PrepSearchNets();

		/*
		 * 1-second intervals, so we don't keep the user waiting
		 * too long, there being no shortcut out of the broadcast.
		 */
		retry.tv_sec = 1;
		retry.tv_usec = 0;
		
		cp = ansbuf;
		
		status = Rpc_BroadcastToNets(prefixSock,
					     searchNets, numSearchNets,
					     PREFIX_UNMOUNT,
					     strlen(ep->prefix)+1,
					     (Rpc_Opaque)ep->prefix,
					     0, (Rpc_Opaque)NULL,
					     2, &retry,
					     ExportUnmountResponse,
					     (Rpc_Opaque)&cp);

		if (status != RPC_SUCCESS && status != RPC_TIMEDOUT) {
		    answer = Rpc_ErrorMessage(status);
		    dprintf("Rpc_Broadcast: %s\n", answer);
		} else if (cp != ansbuf) {
		    /*
		     * Objection! The name(s) of the objector(s) is in
		     * answer, separated by commas. Make a sentence out of
		     * the response and ship it back, leaving the prefix
		     * marked inactive.
		     */
		    cp[-2] = ' '; /* Blow away final comma */
		    /*
		     * Tack on end o' message, nuking extraneous space
		     */
		    strcpy(&cp[-1], "still using it");
		    answer = ansbuf;
		} else {
		    /*
		     * Remove the prefix from the export list
		     */
		    (void)Lst_Remove(exports, ln);
		    
		    /*
		     * Free all associated memory
		     */
		    free(ep->prefix);
		    free(ep->fsname);
		    free(ep->options);
		    free((char *)ep);
		}
	    }
	}
    } else {
	answer = "no prefixes exported";
    }
    Rpc_Return(msg, strlen(answer)+1, answer);
}

/***********************************************************************
 *				Export_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Our RPC servers are registered
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
Export_Init()
{
    Rpc_ServerCreate(prefixSock, PREFIX_LOCATE, ExportLocate, NULL, NULL,
		     NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_EXPORT, ExportExport, NULL, NULL,
		     NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_EXPORT_LOCAL, ExportExportLocal, NULL,
		     NULL, NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_NOEXPORT, ExportDelete, NULL, NULL,
		     NULL);
    
}


/***********************************************************************
 *				Export_IsExported
 ***********************************************************************
 * SYNOPSIS:	    See if the indicated prefix is exported from this
 *	    	    machine. Typically used to forbid importing a prefix
 *	    	    that is also exported by this machine.
 *
 *	    	    NOTE: THE COMPARISON IS AGAINST THE FILESYSTEM BEING
 *		    EXPORTED, NOT THE PREFIX UNDER WHICH IT'S EXPORTED.
 *
 * CALLED BY:	    (EXTERNAL) Import_CreatePrefix, main
 * RETURN:	    True if the prefix is exported, False if not
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 8/94		Initial Revision
 *
 ***********************************************************************/
Boolean
Export_IsExported(prefix)
    char    	*prefix;    	/* Prefix for which to check */
{
    if (exports) {
	LstNode 	    ln;
	Export  	    *ep;
	
	for (ln = Lst_First(exports); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    ep = (Export *)Lst_Datum(ln);

	    if (strcmp(ep->fsname, prefix) == 0) {
		return (True);
	    }
	}
    }

    return (False);
}
