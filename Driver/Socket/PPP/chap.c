/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  chap.c
 *
 * AUTHOR:  	  Jennifer Wu: May 11, 1995
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	chap_packet_name
 *
 *	chap_init
 *	chap_authwithpeer   Start CHAP client
 *	chap_authpeer	    Start CHAP server
 *
 *	chap_servertimeout  Process CHAP server timer expiring
 *	chap_clienttimeout  Process CHAP client timer expiring
 *
 * 	chap_lowerup
 *	chap_lowerdown
 *
 *	chap_protrej	    Process received Protocol-Reject for CHAP
 *	chap_input  	    Process received CHAP packet
 *	chap_rchallenge	    Process received Challenge packet
 *
 *	chap_rresponse	    Process received Response packet
 *	chap_rsuccess;	    Process received Success packet
 *	chap_rfailure	    Process received Failure packet
 *
 *	chap_schallengeOrResponse
 *	chap_schallenge	    Send a Challenge packet
 *	chap_sresponse	    Send a Response packet
 * 	chap_sresult	    Send a Success of Failure packet
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/11/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP Challenge Handshake Authentication Protocol.
 *
 * 	$Id: chap.c,v 1.10 97/04/10 18:21:23 jwu Exp $
 *
 ***********************************************************************/

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>
# include <md5.h>
#ifdef MSCHAP
# include <chap_ms.h>
#endif

#ifdef __HIGHC__
# pragma Code("CHAPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg CHAPCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("CHAPCODE")
#endif

/*
 * Forward declarations.
 */
void chap_rchallenge (chap_state *u, unsigned char *inp, unsigned char id,
		     int len);
void chap_rresponse (chap_state *u, unsigned char *inp, unsigned char id,
		    int len);
void chap_rsuccess (chap_state *u, unsigned char *inp, unsigned char id,
		   int len);
void chap_rfailure (chap_state *u, unsigned char *inp, unsigned char id,
		   int len);
void chap_sresponse (chap_state *u, unsigned char id);
void chap_sresult (unsigned char result, chap_state *u, unsigned char id,
		   char *msg, int msglen);
void chap_schallenge(chap_state *u);

#ifdef LOGGING_ENABLED

void chap_packet_name (unsigned char packet_type,
		       char *buffer)
{
    switch (packet_type)
	{
	case CHAP_CHALLENGE:
	    sprintf(buffer, "Challenge");
	    break;
	case CHAP_RESPONSE:
	    sprintf(buffer, "Response");
	    break;
	case CHAP_SUCCESS:
	    sprintf(buffer, "Success");
	    break;
	case CHAP_FAILURE:
	    sprintf(buffer, "Failure");
	    break;
	default:
	    sprintf(buffer, "packet-type=%xh", packet_type);
	}
}
#endif /* LOGGING_ENABLED */


/***********************************************************************
 *				chap_init
 ***********************************************************************
 * SYNOPSIS:	Initialize a CHAP unit.
 * CALLED BY:	PPPSetup using prottbl entry
 * RETURN:	nothing
 *
 * NOTES:   	Commented out lines initializing defaults to zero
 *	    	because they are already zero (dgroup).  The lines
 *	    	now server as comments.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_init (int unit)
{
    chap_state *u = &chap[unit];

    u -> us_unit = unit;

/*    u -> us_myname = u -> us_mynamelen = 0;	    	    */
/*    u -> us_secret = u -> us_secretlen = 0;	    	    */
/*    DOLOG(u -> us_hername = u -> us_hernamelen = 0;)	    */

    u -> us_client_state = CHAP_CLOSED;
    u -> us_server_state = CHAP_CLOSED;

    u -> us_flags = CHAP_IN_AUTH_PHASE;
/*    u -> us_id = 0;	    	    	    	    */

    u -> us_timeouttime = CHAP_DEFTIMEOUT;
/*    u -> client_timer = u -> server_timer = 0;    */

/*    u -> us_rechap_period = 0;		    */  /* Off by default */
/*    u -> rechap_timer = 0;	    	    	    */
}


/***********************************************************************
 *				chap_authwithpeer
 ***********************************************************************
 * SYNOPSIS:	Our peer is the authentictor.  Wait for her to verify
 *	    	that we are who we say we are.
 * CALLED BY:	chap_lowerup
 *	    	lcp_up
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_authwithpeer (int unit)
{
    chap_state *u = &chap[unit];

#ifdef MSCHAP
    lcp_options *ho = &lcp_heroptions[unit];
    /* careful here, we can't just assign since lhs is byte and rhs is not */
    u -> us_use_ms_chap = ((ho -> lcp_neg & CI_N_MSCHAP) != 0);
#endif

    /*
     * Start waiting for a challenge from the peer.  There is no
     * time limit it must arrive within so make sure client timer is off.
     */
    if (u -> us_client_state == CHAP_CLOSED) {
	u -> us_client_state = CHAP_WAITING;
	u -> client_timer = 0;
    }
}



/***********************************************************************
 *				chap_authpeer
 ***********************************************************************
 * SYNOPSIS:	We are the authenticator.  Verify that our peer is who
 *	    	she says she is.
 * CALLED BY:	chap_lowerup
 *	    	PPPHandleTimeout
 *	    	lcp_up
 *
 * RETURN:	nothing
 *
 * STRATEGY:	If lower layer is not up, don't do anything.
 *	    	Send a challenge and set the timeout.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_authpeer (int unit)
{
    chap_state *u = &chap[unit];
    u -> us_server_state = CHAP_WAITING;

    /*
     * Lower layer up?
     */
    if (! (u -> us_flags & CHAP_LOWERUP)) {
	LOG3(LOG_NEG, (LOG_CHAP_LOWER_NOT_UP));
	return;
    }

    /*
     * Reset retransmit counts for this session and send a challenge.
     * Start server's timer.
     */
    u -> us_server_retransmits = u -> us_client_retransmits = 0;
    chap_schallenge(u);
    u -> server_timer = u -> us_timeouttime;
}



/***********************************************************************
 *				chap_servertimeout
 ***********************************************************************
 * SYNOPSIS:	Process timer expiring for the server side.
 * CALLED BY:	PPPHandleTimeout
 * RETURN:	nothing
 *
 * STRATEGY:	Only process if waiting for a response.
 *	    	if retransmitted too many times then close LCP
 *	    	Else send another challenge
 *	    	    	restart timer
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_servertimeout (chap_state *u)
{
    if (u -> us_server_state == CHAP_WAITING) {

	++u -> us_server_retransmits;

	/*
	 * Is it time to give up?
	 */
	if (max_retransmits && u -> us_server_retransmits > max_retransmits) {
	    link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_TIMEOUT;
	    DOLOG(authentication_failure = "Authentication failed";)
	    lcp_close(u -> us_unit);
	}
	else {
	    /*
	     * Send another challenge and restart timer.
	     */
	    chap_schallenge(u);
#if DELAYED_BACKOFF_TIMER
	    /*
	     * us_retransmits starts counting at 0.  FSM backoff timer
	     * starts at 1.  Adjust this backoff algorithm to match
	     * FSM backoff timer behaviour.
	     */
	    if (u -> us_server_retransmits > MIN_RX_BEFORE_BACKOFF)
	      u -> server_timer = u -> us_timeouttime *
	          (u -> us_server_retransmits - MIN_RX_BEFORE_BACKOFF + 1);
	    else
	      u -> server_timer = u -> us_timeouttime;
#else
	    u -> server_timer = u -> us_timeouttime * u -> us_server_retransmits;
#endif /* BACKOFF_TIMER */
	}
    }
}


/***********************************************************************
 *				chap_clienttimeout
 ***********************************************************************
 * SYNOPSIS:	Process timer expiring for the client side.
 * CALLED BY:	PPPHandleTimeout
 * RETURN:	nothing
 *
 * STRATEGY:	Only process if not in closed state.
 *	    	If transmitted too many times, give up.
 *	    	Else send another response.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_clienttimeout (chap_state *u)
{
    if (u -> us_client_state != CHAP_CLOSED) {

	++u -> us_client_retransmits;

	/*
	 * Time to give up?
	 */
	if (max_retransmits && u -> us_client_retransmits > max_retransmits) {
	    link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_TIMEOUT;
	    DOLOG(authentication_failure = "Authentication failed";)
	    lcp_close(u -> us_unit);
	}
	else {
	    /*
	     * Send another response.
	     */
	    chap_sresponse(u, u -> us_client_id);
	}
    }
}


/***********************************************************************
 *				chap_lowerup
 ***********************************************************************
 * SYNOPSIS:	The lower layer is up.
 * CALLED BY:	lcp_up
 * RETURN:	nothing
 *
 * STRATEGY:	Remember that the lower layer is up.
 *	    	If server is waiting, start it up.
 *	    	If client is waiting, start it up.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_lowerup (int unit)
{
    chap_state *u = &chap[unit];
#ifdef MSCHAP
    lcp_options *ho = &lcp_heroptions[unit];
#endif

    u -> us_flags |= CHAP_LOWERUP;

    if (u -> us_server_state == CHAP_WAITING)
	chap_authpeer(unit);

    if (u -> us_client_state == CHAP_WAITING)
	chap_authwithpeer(unit);
}


/***********************************************************************
 *				chap_lowerdown
 ***********************************************************************
 * SYNOPSIS:	The lower layer is down.
 * CALLED BY:	chap_protrej
 *	    	lcp_down
 * RETURN:	nothing
 *
 * STRATEGY:	Remember lower layer is down.  Stop all timers.
 *	    	reset client states and take CHAP out of authentication
 *	    	phase
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_lowerdown (int unit)
{
    chap_state *u = &chap[unit];

    u -> us_flags = CHAP_IN_AUTH_PHASE;
    u -> server_timer = u -> client_timer = u -> rechap_timer = 0;
    u -> us_client_state = u -> us_server_state = CHAP_CLOSED;
}


/***********************************************************************
 *				chap_protrej
 ***********************************************************************
 * SYNOPSIS:	Peer rejected CHAP protocol.  Process it.
 * CALLED BY:	demuxprotrej using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	This shouldn't happen.  In any case, pretend the lower
 *	    	layer went down.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_protrej (int unit)
{
    chap_lowerdown(unit);
}


/***********************************************************************
 *				chap_input
 ***********************************************************************
 * SYNOPSIS:	Process a received CHAP packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	Verify length of packet.
 *	    	Parse code, id and length and verify length field.
 *	    	Process according to code.
 *	    	Free packet.  New packets will have been allocated for
 *	    	any needed responses.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
byte chap_input (int unit,
		 PACKET *inpacket,
		 int l)
{
    chap_state *u = &chap[unit];
    unsigned char *inp, code, id;
    int len;
    DOLOG(char buffer[SHORT_STR_LEN];)

    /*
     * Parse the CHAP packet header (code, id and length)
     */
    inp = PACKET_DATA(inpacket);

    if (l < CHAP_HEADERLEN) {
	LOG3(LOG_NEG, (LOG_CHAP_SHORT_HDR));
	goto freepacket;
    }

    GETCHAR(code, inp);
    GETCHAR(id, inp);
    GETSHORT(len, inp);

    if (len < CHAP_HEADERLEN) {
	LOG3(LOG_NEG, (LOG_CHAP_SHORT_LEN));
	goto freepacket;
    }

    if (len > l) {
	LOG3(LOG_NEG, (LOG_CHAP_MISMATCHED_LEN));
	goto freepacket;
    }

    len -= CHAP_HEADERLEN;  	    	/* Adjust remaining length */

    DOLOG(chap_packet_name(code, buffer);)
    LOG3(u -> us_flags & CHAP_IN_AUTH_PHASE ? LOG_NEG : LOG_LQSTAT,
	(LOG_CHAP_RCVD, buffer, id));

    switch (code)
	{
	case CHAP_CHALLENGE:
	    chap_rchallenge(u, inp, id, len);
	    break;

	case CHAP_RESPONSE:
	    chap_rresponse(u, inp, id, len);
	    break;

	case CHAP_SUCCESS:
	    chap_rsuccess(u, inp, id, len);
	    break;

	case CHAP_FAILURE:
	    chap_rfailure(u, inp, id, len);
	    break;
	}

freepacket:
    PACKET_FREE(inpacket);
    return(1);
}



/***********************************************************************
 *				chap_rchallenge
 ***********************************************************************
 * SYNOPSIS:	Process receiving a Challenge packet.
 * CALLED BY:	chap_input
 * RETURN:	nothing
 *
 * STRATEGY:	If client state is closed, do nothing.
 *	    	Verify length.  Parse value length and verify it.
 *	    	Parse name and use to lookup secret.
 *	    	Do the encryption with MD5.
 *	    	Send a response.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_rchallenge (chap_state *u,
		      unsigned char *inp,
		      unsigned char id,
		      int len)
{
    char *secret;
    unsigned char *value, digest[CHAP_VALUE_SIZE];
    int valuelen;
    MD5_CTX md_context;
    DOLOG(Handle hernameBlk = NullHandle;)
    DOLOG(unsigned char *hername;)

    if (u -> us_client_state == CHAP_CLOSED) {
	LOG3(LOG_NEG, (LOG_CHAP_UNEXPECTED, "Challenge"));
	return;
    }

    /*
     * Get length of value, adjust remaining length and verify length field.
     */
    GETCHAR(valuelen, inp);
    len -= 1;

    if (len < valuelen) {
	LOG3(LOG_NEG, (LOG_CHAP_SHORT_CHALLENGE));
	return;
    }
    value = inp;

    /*
     * Advance pointer to name data in packet.  Adjust remaining length.
     */
    INCPTR(valuelen, inp);
    len -= valuelen;

#ifdef LOGGING_ENABLED
    /*
     * Get peer name for logging purposes.
     */
    PPPFreeBlock(u -> us_hername);  	    /* Free old block. */
    u -> us_hernamelen = len;		     /* Store new length */

    if (len > 0 &&
	((hernameBlk = MemAllocSetOwner(GeodeGetProcessHandle(),
					len, HF_DYNAMIC, HAF_STANDARD)) != 0)) {
	MemLock(hernameBlk);
	hername = (unsigned char *)MemDeref(hernameBlk);
	memcpy(hername, inp, len);
	hername[len] = '\0';
    }

    u -> us_hername = hernameBlk;

#endif /* LOGGING_ENABLED */

    /*
     * Do the encryption if we know the secret.  Otherwise, send garbage.
     */
    if (u -> us_secret) {
	MemLock(u -> us_secret);
	secret = (char *)MemDeref(u -> us_secret);

#ifdef MSCHAP
	if (u -> us_use_ms_chap) {
	    ChapMS(u, (char *)value, valuelen, secret, u -> us_secretlen);
	} else {
	    MD5Init(&md_context);
	    MD5Update(&md_context, &id, 1);
	    MD5Update(&md_context, secret, u -> us_secretlen);
	    MD5Update(&md_context, value, valuelen);
	    MD5Final(digest, &md_context);
	    memcpy(u -> us_myresponse, digest, CHAP_VALUE_SIZE);
	    u -> us_myresponse_len = CHAP_VALUE_SIZE;
	}
#else
	MD5Init(&md_context);
	MD5Update(&md_context, &id, 1);
	MD5Update(&md_context, secret, u -> us_secretlen);
	MD5Update(&md_context, value, valuelen);
	MD5Final(digest, &md_context);
	memcpy(u -> us_myresponse, digest, CHAP_VALUE_SIZE);
#endif

	MemUnlock(u -> us_secret);
    }

    /*
     * Reset retransmit count and set client state.  Send a response.
     */
    u -> us_client_retransmits = 1;
    u -> us_client_state = CHAP_WAITING;
    chap_sresponse(u, u -> us_client_id = id);
}


/***********************************************************************
 *				chap_rresponse
 ***********************************************************************
 * SYNOPSIS:	Process a received Response packet.
 * CALLED BY:	chap_input
 * RETURN:	nothing
 *
 * STRATEGY:	If not expecting a response, don't do anything.
 *	    	Get value length and verify.
 *	    	Get peer name to look up secret.
 *	    	Encrypt peer's secret and compare against received value
 *	    	If matches, send success and begin network phase
 *	    	Else send failure and close LCP
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_rresponse (chap_state *u,
		     unsigned char *inp,
		     unsigned char id,
		     int len)
{
    char *secret;
    unsigned char *value, digest[CHAP_VALUE_SIZE], *hername;
    int valuelen, secretLen;
    MD5_CTX md_context;
    Handle secretBlk = 0, hernameBlk;

    /*
     * If not expecting a response, don't do anything.
     */
    if (u -> us_server_state == CHAP_CLOSED) {
	LOG3(LOG_NEG, (LOG_CHAP_UNEXPECTED, "Response"));
	return;
    }

    /*
     * Get value length and verify.
     */
    GETCHAR(valuelen, inp);
    len -= 1;

    if (len < valuelen) {
	LOG3(LOG_NEG, (LOG_CHAP_SHORT_RESPONSE));
	return;
    }
    value = inp;

    /*
     * Process only if ID matches our ID.
     */
    if (id == u -> us_id) {

	INCPTR(valuelen, inp);
	len -= valuelen;

	/*
	 * Free block containing old peer name and store current one.
	 */
	DOLOG(PPPFreeBlock(u -> us_hername);)
	DOLOG(u -> us_hernamelen = len;)
	DOLOG(u -> us_hername = 0;)

	if (len == 0 ||
	    ((hernameBlk = MemAllocSetOwner(GeodeGetProcessHandle(),
				    len, HF_DYNAMIC, HAF_STANDARD)) == 0)) {
	    hername = (unsigned char *)"";  	    /* prevents us from dying */
	}
	else {
	    MemLock(hernameBlk);
	    hername = (unsigned char *)MemDeref(hernameBlk);
	    memcpy(hername, inp, len);
	    hername[len] = '\0';   	    /* Null terminate it */
	    /*
	     * Look up peer's secret.
	     */
	    PPPGetPeerSecret(hername, &secretBlk, &secretLen);
#ifndef LOGGING_ENABLED
	    MemFree(hernameBlk);
#else
	    u -> us_hername = hernameBlk;
#endif
	}

	/*
	 * Encrypt value to compare against peer's response.
	 */

	if (secretBlk) {
	    MemLock(secretBlk);
	    secret = (char *)MemDeref(secretBlk);
	    MD5Init(&md_context);
	    MD5Update(&md_context, &id, 1);
	    MD5Update(&md_context, secret, secretLen);
	    MD5Update(&md_context, u -> us_mychallenge, CHAP_VALUE_SIZE);
	    MD5Final(digest, &md_context);
	    MemFree(secretBlk);
	}

	/*
	 * Check if our encrypted secret for the peer matches the
	 * received value.  If we don't know the peer's secret,
	 * then send failure.
	 */
	if (valuelen == CHAP_VALUE_SIZE &&
	    memcmp(digest, value, valuelen) == 0 &&
	    secretBlk) {
	    /*
	     * It matches!  Send success.  Cancel server timeout.
	     */
	    chap_sresult(CHAP_SUCCESS, u , id, "", 0);
	    u -> us_server_state = CHAP_OPEN;
	    u -> server_timer = 0;

	    if (u -> us_client_state != CHAP_WAITING) {
#ifdef LOGGING_ENABLED
		int chap_debug = u -> us_flags & CHAP_IN_AUTH_PHASE ?
		                 LOG_BASE : LOG_LQSTAT;
		if (debug >= chap_debug) {
		    int i;
		    LOG3(chap_debug, (LOG_CHAP_PEER));
		    if (u -> us_hername) {
		    	hername = (unsigned char *)MemDeref(u -> us_hername);
			for (i = 0; i < u -> us_hernamelen; ++i)
			    LOG3(chap_debug, (LOG_FORMAT_CHAR, hername[i]));
		    }
		    LOG3(chap_debug, (LOG_NEWLINE_QUOTED));
		}
#endif /* LOGGING_ENABLED */

		/*
		 * Start timer for reauthentication.
		 */
		if (u -> us_rechap_period)
		    u -> rechap_timer = u -> us_rechap_period;

		/*
		 * Remember we are done with authentication in CHAP.
		 * Begin network phase.
		 */
		if (u -> us_flags & CHAP_IN_AUTH_PHASE) {
		    u -> us_flags &= ~CHAP_IN_AUTH_PHASE;
		    BeginNetworkPhase(u -> us_unit);
		}
	    }
	}
	else {
	    /*
	     * Didn't match.  Send failure and close LCP.
	     *
	     * Set generic error to reset because this may be a
	     * reauthentication response.
	     */
	    chap_sresult(CHAP_FAILURE, u, id, "", 0);
	    link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_RESET;
	    DOLOG(authentication_failure = "Authentication failed";)
	    lcp_close(u -> us_unit);
	}
    }
}


/***********************************************************************
 *				chap_rsuccess
 ***********************************************************************
 * SYNOPSIS:	Process received success packet.
 * CALLED BY:	chap_input
 * RETURN:	nothing
 *
 * STRATEGY:	If not expecting a response, do nothing.
 *	    	Remember client is done and clear client timer.
 *	    	If server isn't authenticating and this isn't a rechap,
 *	    	    begin network phase.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_rsuccess (chap_state *u,
		    unsigned char *inp,
		    unsigned char id,
		    int len)
{
    /*
     * If not expecting a response, don't process.
     */
    if (u -> us_client_state != CHAP_WAITING) {
	LOG3(LOG_NEG, (LOG_CHAP_UNEXPECTED, "Success"));
	return;
    }

    PRINTMSG(inp, len)

    /*
     * Remember client authentication is complete and stop client timer.
     */
    u -> us_client_state = CHAP_OPEN;
    u -> client_timer = 0;

    /*
     * If server isn't still authentication and we are authenticating,
     * begin network phase and remember that authentication is done so
     * reauthentication doesn't generate redundant notifications.
     */
    if (u -> us_server_state != CHAP_WAITING)
	if (u -> us_flags & CHAP_IN_AUTH_PHASE) {
	    u -> us_flags |= CHAP_IN_AUTH_PHASE;
	    BeginNetworkPhase(u -> us_unit);
	}

} /* End Of chap_rsuccess */



/***********************************************************************
 *				chap_rfailure
 ***********************************************************************
 * SYNOPSIS:	Process a received failure packet.
 * CALLED BY:	chap_input
 * RETURN:	nothing
 *
 * STRATEGY:	if not expecting a response, do nothing
 *	    	stop client timer so no more responses get sent
 *	    	close LCP
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_rfailure (chap_state *u,
		    unsigned char *inp,
		    unsigned char id,
		    int len)
{
    /*
     * Only process if expecting response.
     */
    if (u -> us_client_state != CHAP_WAITING) {
	LOG3(LOG_NEG, (LOG_CHAP_UNEXPECTED, "Failure"));
	return;
    }

    PRINTMSG(inp, len)

    /*
     * Stop client from sending anymore responses and close LCP.
     */
    u -> client_timer = 0;

    link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_RESET;
    LOG3(LOG_BASE, (LOG_CHAP_FAILED));
    DOLOG(authentication_failure = "Authentication failed";)

    lcp_close(u -> us_unit);
}


/***********************************************************************
 *				chap_schallengeOrResponse
 ***********************************************************************
 * SYNOPSIS:	Common processing required for sending challenges or
 *	    	responses.
 * CALLED BY:	chap_schallenge
 *	    	chap_sresponse
 * RETURN:	nothing
 *
 * STRATEGY:	Allocate a packet, fill it with data
 *	    	Stick value and name in packet and send it
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/95		Initial Revision
 *
 ***********************************************************************/
void
#ifdef MSCHAP
chap_schallengeOrResponse (chap_state *u,
			   unsigned char code,
			   unsigned char id,
			   char *value,	    	/* challenge/response value */
			   int valueLen)
#else
chap_schallengeOrResponse (chap_state *u,
			   unsigned char code,
			   unsigned char id,
			   char *value)	    	/* challenge/response value */
#endif
{
    PACKET *outpacket;
    unsigned char *outp, *myname;
    int outlen, mynamelen;

    /*
     * Compute size and allocate packet.  Packet consists of
     * chap header, 1 byte for value suze, the value and my name.
     */
    if (u -> us_mynamelen)
	mynamelen = u -> us_mynamelen;
    else
	mynamelen = 1;	    	    	    /* size of dummy name: "?" */

#ifdef MSCHAP
    outlen = CHAP_HEADERLEN + 1 + valueLen + mynamelen;
#else
    outlen = CHAP_HEADERLEN + 1 + CHAP_VALUE_SIZE + mynamelen;
#endif
    outpacket = PACKET_ALLOC(outlen);
    if (outpacket == 0)	    	/* no memory, oh well... */
	return;
    outp = PACKET_DATA(outpacket);

    /*
     * Place the data in the packet.
     */
    PUTCHAR(code, outp);
    PUTCHAR(id, outp);
    PUTSHORT(outlen, outp);
#ifdef MSCHAP
    PUTCHAR(valueLen, outp);

    memcpy(outp, value, valueLen);
    INCPTR(valueLen, outp);
#else
    PUTCHAR(CHAP_VALUE_SIZE, outp);

    memcpy(outp, value, CHAP_VALUE_SIZE);
    INCPTR(CHAP_VALUE_SIZE, outp);
#endif

    /*
     * Place my name in the packet and send it, if known.
     */
    if (u -> us_myname) {
	MemLock(u -> us_myname);
	myname = (unsigned char *)MemDeref(u -> us_myname);
	memcpy(outp, myname, mynamelen);
	MemUnlock(u -> us_myname);
    }
    else
	memcpy(outp, "?", mynamelen);           /* Use a dummy name */


    LOG3(u -> us_flags & CHAP_IN_AUTH_PHASE? LOG_NEG : LOG_LQSTAT,
	(LOG_CHAP_SENDING,
	 code == CHAP_CHALLENGE ? "Challenge" : "Response", id));

    PPPSendPacket(u -> us_unit, outpacket, CHAP);

}	/* End of chap_schallengeOrResponse */


/***********************************************************************
 *				chap_schallenge
 ***********************************************************************
 * SYNOPSIS:    Send a Challenge packet.
 * CALLED BY:	chap_authpeer
 *	    	chap_servertimeout
 * RETURN:  	nothing
 *
 * STRATEGY:	If no username, cannot send a challenge packet.
 *	    	    (unless we want to be RFC deviants)
 *	    	Allocate a packet, fill it with data
 *	    	Generate a random challenge and stick in packet.
 *	    	Stick name in packet and send it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_schallenge (chap_state *u)
{
    int i;

#ifdef LOGGING_ENABLED
    if (! u -> us_myname) {
	LOG3(LOG_MISC, (LOG_CHAP_NO_NAME));
    }
#endif

    /*
     * Generate a random challenge, then allocate the packet, fill
     * it with data and send it.
     */
    for (i = 0; i < CHAP_VALUE_SIZE; ++i)
	u -> us_mychallenge[i] = (char)NetGenerateRandom8(255);

#ifdef MSCHAP
    chap_schallengeOrResponse(u, CHAP_CHALLENGE, ++u -> us_id,
			      u -> us_mychallenge, CHAP_VALUE_SIZE);
#else
    chap_schallengeOrResponse(u, CHAP_CHALLENGE, ++u -> us_id,
			      u -> us_mychallenge);
#endif

}



/***********************************************************************
 *				chap_sresponse
 ***********************************************************************
 * SYNOPSIS:	Send a Response packet.
 * CALLED BY:	chap_clienttimeout
 *	    	chap_rchallenge
 * RETURN:	nothing
 *
 * STRATEGY:   	Allocate a packet.  Stick encrypted challenge value
 *	    	in packet.  Stick name in packet and send it.
 *	    	Start timer for result packet.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void chap_sresponse (chap_state *u,
		     unsigned char id)
{
    /*
     * Allocate the packet, fill it with data and send it.
     * Start timer to wait for a result response.
     */
#ifdef MSCHAP
    chap_schallengeOrResponse(u, CHAP_RESPONSE, id, u -> us_myresponse,
			      /*(u -> us_use_ms_chap : u -> us_myresponse_len ?
					CHAP_VALUE_SIZE)*/u->us_myresponse_len);
#else
    chap_schallengeOrResponse(u, CHAP_RESPONSE, id, u -> us_myresponse);
#endif
#if DELAYED_BACKOFF_TIMER
    /*
     * us_retransmits starts counting at 0.  FSM backoff timer
     * starts at 1.  Adjust this backoff algorithm to match
     * FSM backoff timer behaviour.
     */
    if (u -> us_client_retransmits > MIN_RX_BEFORE_BACKOFF)
      u -> client_timer = u -> us_timeouttime *
	(u -> us_client_retransmits - MIN_RX_BEFORE_BACKOFF + 1);
    else
      u -> client_timer = u -> us_timeouttime;
#else
      u -> client_timer = u -> us_timeouttime * u -> us_client_retransmits;
#endif /* BACKOFF_TIMER */
}


/***********************************************************************
 *				chap_sresult
 ***********************************************************************
 * SYNOPSIS:	Send a Success or Failure packet
 * CALLED BY:	chap_rresponse
 * RETURN:	nothing
 *
 * STRATEGY:	Allocate a packet, fill it in with data and send it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *	jwu 	10/24/95    	Merged chap_ssuccess and chap_sfailure
 ***********************************************************************/
void chap_sresult (unsigned char result,
		   chap_state *u,
		   unsigned char id,
		   char *msg,
		   int msglen)
{
    PACKET *outpacket;
    unsigned char *outp;
    int outlen;

    outlen = CHAP_HEADERLEN + msglen;
    outpacket = PACKET_ALLOC(outlen);

    if (outpacket) {
	outp = PACKET_DATA(outpacket);

	PUTCHAR(result, outp);
	PUTCHAR(id, outp);
	PUTSHORT(outlen, outp);

	if (msglen)
	    memcpy(outp, msg, msglen);

	LOG3(u -> us_flags & CHAP_IN_AUTH_PHASE ? LOG_NEG : LOG_LQSTAT,
	    (LOG_CHAP_SENDING,
	     result == CHAP_SUCCESS ? "Success" : "Failure",
	     id));

	PPPSendPacket(u -> us_unit, outpacket, CHAP);
    }
}
