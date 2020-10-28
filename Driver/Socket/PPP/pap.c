/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  pap.c
 *
 * AUTHOR:  	  Jennifer Wu: May 11, 1995
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	pap_init
 *	pap_authwithpeer    Start PAP client
 *	pap_authpeer	    Start PAP server
 *
 *	pap_timeout 	    Process PAP timer expiring
 *
 *	pap_lowerup 	    Start authentication if pending
 *	pap_lowerdown	    Stop PAP
 *
 *	pap_protrej 	    Process a received Protocol-Reject for PAP
 *	pap_input   	    Process a received PAP packet
 *
 *	pap_rauth   	    Process a received Authenticate-Request
 *	pap_rauthackornack  Common code for the next 2 routines.
 *	pap_rauthack	    Process a received Authenticate-Ack
 *	pap_rauthnak	    Process a received Authenticate-Nak
 *
 *	pap_sauth   	    Send an Authenticate-Request
 *	pap_sresp   	    Send a response (ack or nak)
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/11/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP Password Authentication Protocol code.
 *
 * 	$Id: pap.c,v 1.7 97/04/10 18:29:56 jwu Exp $
 *
 ***********************************************************************/
/*
 *
 * Copyright (c) 1989 Carnegie Mellon University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by Carnegie Mellon University.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */


#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>

#ifdef __HIGHC__
# pragma Code("PAPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg PAPCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("PAPCODE")
#endif

void pap_rauth(pap_state *u, unsigned char *inp, unsigned char id, int len);
void pap_rauthack(pap_state *u, unsigned char *inp, unsigned char id, int len);
void pap_rauthnak(pap_state *u, unsigned char *inp, unsigned char id, int len);
void pap_sresp(pap_state *u, unsigned char code, unsigned char id, char *msg,
	       int msglen);
void pap_sauth(pap_state *u);


/***********************************************************************
 *				pap_init
 ***********************************************************************
 * SYNOPSIS:	Initialize a PAP unit.
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
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_init (int unit)
{
    pap_state *u = &pap[unit];

    u -> us_unit = unit;

/*    u -> us_user = u -> us_userlen = 0;   	    */
/*    u -> us_passwd = 0;   	    	    	    */
/*    u -> us_passwdlen = 0;	    	    	    */
/*    u -> us_peerid = 0;   	    	    	    */
/*    u -> us_peeridlen = 0;	    	    	    */

    u -> us_clientstate = PAPCS_CLOSED;
    u -> us_serverstate = PAPSS_CLOSED;
/*    u -> us_flags = 0;    	    	    	    */
/*    u -> us_id = 0;	    	    	    	    */
/*    u -> us_retransmits = 0;	    	    	    */

    u -> us_timeouttime = PAP_DEFTIMEOUT;
/*    u -> timer = 0;	    	    	    	    */
}


/***********************************************************************
 *				pap_authwithpeer
 ***********************************************************************
 * SYNOPSIS:	Authenticate us with our peer (start client).
 * CALLED BY:	pap_lowerup
 *	    	lcp_up
 * RETURN:	nothing
 *
 * STRATEGY:	Set new state and send authenticate request.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_authwithpeer (int unit)
{
    pap_state *u = &pap[unit];

    /*
     * Clear pending flag.
     */
    u -> us_flags &= ~PAPF_AWPPENDING;

    /*
     * If already authenticat{ed, ing}, then don't do anything.
     */
    if (u -> us_clientstate != PAPCS_CLOSED)
	return;

    /*
     * If lower layer is not up, wait for it to come up before
     * sending an authentication.
     */
    if (! (u -> us_flags & PAPF_LOWERUP)) {
	u -> us_flags |= PAPF_AWPPENDING;
	return;
    }

#ifdef LOGGING_ENABLED
    if (! u -> us_user || ! u -> us_passwd )
	LOG3(LOG_MISC, (LOG_PAP_NO_NAME));
#endif /* LOGGING_ENABLED */

    /*
     * Send authenticate request packet and start timer for a response.
     */
    pap_sauth(u);
    u -> timer = u -> us_timeouttime;

    u -> us_clientstate = PAPCS_AUTHSENT;
    u -> us_retransmits = 0;
}




/***********************************************************************
 *				pap_authpeer
 ***********************************************************************
 * SYNOPSIS:	Authenticate our peer (start server).
 * CALLED BY:	lcp_up
 *	    	pap_lowerup
 * RETURN:	nothing
 *
 * STRATEGY:	Set new state to wait for an authenticate request.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_authpeer (int unit)
{
    pap_state *u = &pap[unit];

    /*
     * Clear pending flag.
     */
    u -> us_flags &= ~PAPF_APPENDING;

    /*
     * If already authenticat{ed, ing}, don't do anything.
     */
    if (u -> us_serverstate != PAPSS_CLOSED)
	return;

    /*
     * If lower layer is not up, wait.
     */
    if (! (u -> us_flags & PAPF_LOWERUP)) {
	u -> us_flags |= PAPF_APPENDING;
	return;
    }

    u -> us_serverstate = PAPSS_LISTEN;

}



/***********************************************************************
 *				pap_timeout
 ***********************************************************************
 * SYNOPSIS:	Handle PAP timer expiring.
 * CALLED BY:	PPPHandleTimeout
 * RETURN:	nothing
 *
 * STRATEGY:	If sent too many already, then authentication fails.
 * 	    	Else send another authentication request if needed.
 *	    	    restart timer for response.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_timeout (pap_state *u)
{
    /*
     * If haven't sent an authenticate request, then there's nothing to do.
     */
    if (u -> us_clientstate != PAPCS_AUTHSENT)
	return;

    ++u -> us_retransmits;

    /*
     * If sent too many packets, then authentication failed.
     */
    if (max_retransmits && u -> us_retransmits > max_retransmits) {
	link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_TIMEOUT;
	DOLOG(authentication_failure = "Authentication failed";)
	lcp_close(u -> us_unit);
    }
    else {
	/*
	 * Send another authenticate request, restart timer and increment
	 * number of retransmits.
	 */
	pap_sauth(u);
#if DELAYED_BACKOFF_TIMER
	/*
	 * us_retransmits starts counting at 0.  FSM backoff timer
	 * starts at 1.  Adjust this backoff algorithm to match
	 * FSM backoff timer behaviour.
	 */
	if (u -> us_retransmits > MIN_RX_BEFORE_BACKOFF)
	  u -> timer = u -> us_timeouttime *
	    (u -> us_retransmits - MIN_RX_BEFORE_BACKOFF + 1);
	else
	  u -> timer = u -> us_timeouttime;
#else
	u -> timer = u -> us_timeouttime * u -> us_retransmits;
#endif /* BACKOFF_TIMER */
    }
}



/***********************************************************************
 *				pap_lowerup
 ***********************************************************************
 * SYNOPSIS:	The lower layer is up.  Start authentication if pending.
 * CALLED BY:	lcp_up
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_lowerup (int unit)
{
    pap_state *u = &pap[unit];

    /*
     * Remember that the lower layer is up.  If PAP was waiting for
     * the lower layer to come up before starting up, start now.
     */
    u -> us_flags |= PAPF_LOWERUP;

    if (u -> us_flags & PAPF_AWPPENDING)
	pap_authwithpeer(unit);

    if (u -> us_flags & PAPF_APPENDING)
	pap_authpeer(unit);
}


/***********************************************************************
 *				pap_lowerdown
 ***********************************************************************
 * SYNOPSIS:	The lower layer is down.
 * CALLED BY:	lcp_down
 *	    	pap_protrej
 * RETURN:	nothing
 *
 * STRATEGY:	Cancel timeout.  Reset states.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_lowerdown (int unit)
{
    pap_state *u = &pap[unit];

    u -> us_flags &= ~PAPF_LOWERUP;
    u -> us_clientstate = u -> us_serverstate = PAPSS_CLOSED;
    u -> timer = 0;
}



/***********************************************************************
 *				pap_protrej
 ***********************************************************************
 * SYNOPSIS:	Process a received Protocol-Reject for PAP.
 * CALLED BY:	demuxprotrej using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	Bring down PAP.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_protrej (int unit)
{
    pap_lowerdown(unit);
}


/***********************************************************************
 *				pap_input
 ***********************************************************************
 * SYNOPSIS:	Process a received PAP packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects idle timer.
 *
 * STRATEGY:	Check the length.
 *	    	Parse the code, id and length.
 *	    	Process packet according to code.
 *	    	Free packet.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
byte pap_input (int unit,
		PACKET *inpacket,
		int l)
{
    pap_state *u = &pap[unit];
    unsigned char *inp, code, id;
    int len;

    /*
     * Drop packet if too short to even contain a PAP header.
     */
    inp = PACKET_DATA(inpacket);
    if (l < PAP_HEADERLEN) {
	LOG3(LOG_NEG, (LOG_PAP_SHORT_HDR));
	goto freepacket;
    }

    /*
     * Parse the header for code, id and length.  Verify transmitted
     * length and that it matches the size of the packet.
     */
    GETCHAR(code, inp);
    GETCHAR(id, inp);
    GETSHORT(len, inp);

    if (len < PAP_HEADERLEN) {
	LOG3(LOG_NEG, (LOG_PAP_SHORT_LEN));
	goto freepacket;
    }

    if (len > l) {
	LOG3(LOG_NEG, (LOG_PAP_MISMATCHED_LEN));
	goto freepacket;
    }

    /*
     * Drop packet header from total length.  Then process packet based
     * on the code.  Free packet when done.  If any of these generate a
     * response, a new packet is allocated for it.
     */
    len -= PAP_HEADERLEN;

    switch (code)
	{
	case PAP_AUTH:
	    pap_rauth(u, inp, id, len);
	    break;

	case PAP_AUTHACK:
	    pap_rauthack(u, inp, id, len);
	    break;

	case PAP_AUTHNAK:
	    pap_rauthnak(u, inp, id, len);
	    break;

	default:
	    break;  	    	    	/* Need code reject? */
	}

freepacket:
    PACKET_FREE(inpacket);
    return (1);
}


/***********************************************************************
 *				pap_rauth
 ***********************************************************************
 * SYNOPSIS:	Process a recieved Authenticate-Request packet.
 * CALLED BY:	pap_input
 * RETURN:	nothing
 *
 * STRATEGY:	if not listening for packets or server is not open
 *	    	    then do nothing
 *	    	make sure packet contains at least a byte of data
 *	    	Get the id length and verify it
 *	    	If server is open and we know the peer id and the length
 *	    	    differs or the id differs, the packet is bad so don't
 *	    	    do anything with it
 *	    	if we have an old peer id block, free it
 *	    	Allocate a new block for peer id and copy peer id into it
 *	    	Set the peer id length
 *	    	get the password length and verify it
 *	    	get the peer's password from the INI file
 *	    	if we have the peer's password and the peer name matches
 *	    	    the username and the password is correct, send an ack.
 *	    	    server is open and enter network phase
 *	    	else
 *	    	    send a nak
 *	    	    close PPP link
 *
 * NOTES:   	We store the username, peerid and password in dynamically
 *	    	allocated memory blocks so they must be locked and
 *	    	dereferenced before you.   MST code didn't need this.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_rauth (pap_state *u,
		unsigned char *inp,
		unsigned char id,
		int len)
{
    unsigned char id_len, rpasswdlen, result;
    int passwdlen;
    Handle passwdBlk = 0;
    unsigned char *peerid, *user, *passwd, *rpasswd;

    result = 0;
    LOG3(LOG_NEG, (LOG_PAP_RECV_AUTH, "Request", id));

    /*
     * Do not process if not waiting for an authenticate request.
     */
    if (u -> us_serverstate == PAPSS_CLOSED) {
	LOG3(LOG_NEG, (LOG_PAP_UNEXPECTED));
	return;
    }

    /*
     * Make sure packet contains data.  Then parse the peer-id length,
     * adjusting remaining length to exclude peerid and length bytes.
     * Verify peer-id length.
     */
    if (len < 1) {
	LOG3(LOG_NEG, (LOG_PAP_UNEXPECTED_SHORT));
	return;
    }

    GETCHAR(id_len, inp);
    len -= 1 + id_len + 1;
    if (len < 0) {
	/* received peerid length was too big! */
	LOG3(LOG_NEG, (LOG_PAP_BAD, "Request"));
	return;
    }

    /*
     * If state is already open, make sure this request matches previous
     * peer-id.
     */
    if (u -> us_serverstate == PAPSS_OPEN && u -> us_peerid) {

	if (u -> us_peeridlen != id_len) {
	    LOG3(LOG_BASE, (LOG_PAP_WRONG_ID));
	    return;
	}

	MemLock(u -> us_peerid);
	peerid = (unsigned char *)MemDeref(u -> us_peerid);
	result = memcmp(inp, peerid, id_len);
	MemUnlock(u -> us_peerid);
	if (result) {
	    LOG3(LOG_BASE, (LOG_PAP_WRONG_ID));
	    return;
	}
    }

    /*
     * Free block holding old peer_id and store new one.  If peer
     * sent a zero-sized id, send a nak response because we can't
     * verify the password without a username to associate it with.
     */
    PPPFreeBlock(u -> us_peerid);
    u -> us_peeridlen = id_len;

    if (id_len == 0) {
	LOG3(LOG_MISC, (LOG_PAP_NO_USERNAME));
	goto sendNak;
    }
    if ((u -> us_peerid = MemAllocSetOwner(GeodeGetCodeProcessHandle(),
				   id_len, HF_DYNAMIC, HAF_STANDARD)) == 0) {
	LOG3(LOG_BASE, (LOG_PAP_NO_MEM));
	return;
    }
    else {
	MemLock(u -> us_peerid);
	peerid = (unsigned char *)MemDeref(u -> us_peerid);
	memcpy(peerid, inp, id_len);
	peerid[id_len] = '\0';
    }

    /*
     * Advance pointer to peer's password in packet.  Get password length
     * and verify.
     */
    INCPTR(id_len, inp);
    GETCHAR(rpasswdlen, inp);
    if (len < (int)rpasswdlen) {
	LOG3(LOG_NEG, (LOG_PAP_BAD, "Request"));
	MemUnlock(u -> us_peerid);
	return;
    }

    /*
     * Look up peer's password.  If none, NAK.  Else verify password.
     */
    rpasswd = inp;
    PPPGetPeerPasswd(peerid, &passwdBlk, &passwdlen);
    if (passwdBlk) {
	MemLock(passwdBlk);
	passwd = (unsigned char *)MemDeref(passwdBlk);

	/*
	 * If password length matches and peer id is not the same as
	 * username and password matches, then request is good.  Respond
	 * with an ACK.
	 */
	if (u -> us_user) {
	    MemLock(u -> us_user);
	    user = (unsigned char *)MemDeref(u -> us_user);
	    result = u -> us_peeridlen == u -> us_userlen &&
		     memcmp(peerid, user, u -> us_peeridlen) == 0;
	    MemUnlock(u -> us_user);
	}

	if (rpasswdlen == passwdlen &&
	    memcmp(rpasswd, passwd, passwdlen) == 0 &&
	    !result) {

	    pap_sresp(u, PAP_AUTHACK, id, "", 0);

#ifdef LOGGING_ENABLED
	    if (debug >= LOG_BASE) {
		int i;
		LOG3(LOG_BASE, (LOG_PAP_PEER_IS));

		for (i = 0; i < u -> us_peeridlen; ++i)
		    LOG3(LOG_BASE, (LOG_FORMAT_CHAR, peerid[i]));

		LOG3(LOG_BASE, (LOG_NEWLINE_QUOTED));
	    }
#endif /* LOGGING_ENABLED */

	    u -> us_serverstate = PAPSS_OPEN;
	    BeginNetworkPhase(u -> us_unit);
	    goto done;
	}
	else
	    goto sendNak;
    }
    else {
sendNak:
	pap_sresp(u, PAP_AUTHNAK, id, "", 0);
	link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_RESET;
	DOLOG(authentication_failure = "Authentication failed";)
	lcp_close(u -> us_unit);
    }
done:
    PPPFreeBlock(passwdBlk);
    if (u -> us_peerid)
	MemUnlock(u -> us_peerid);
}


/***********************************************************************
 *				pap_rathackornak
 ***********************************************************************
 * SYNOPSIS:	Common processing required for acks and naks.
 * CALLED BY:	pap_rauthack
 *	    	pap_rauthnak
 * RETURN:	TRUE if ack/nak was good, else FALSE
 *	    	*inp adjusted to start of message in packet
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/95		Initial Revision
 *
 ***********************************************************************/
int
pap_rauthackornak (pap_state *u,
		   unsigned char **inp,
		   unsigned char id,
		   int len,
		   unsigned char code,
		   unsigned char *msglen)
{
    LOG3(LOG_NEG, (LOG_PAP_RECV_AUTH,
		  code == PAP_AUTHACK ? "Ack" : "Nak", id));

    /*
     * Only process if expecting a response to our request.
     */
    if (u -> us_clientstate != PAPCS_AUTHSENT)
	return(FALSE);

    /*
     * Parse message.  Verify packet length and length field.
     */
    if (len < 1) {
	LOG3(LOG_NEG, (LOG_PAP_SHORT,
		      code == PAP_AUTHACK ? "Ack" : "Nak"));
	return(FALSE);
    }

    GETCHAR(*msglen, *inp);
    len -= 1;	    	    	    	/* Adjust remaining length */

    if (len < (int)*msglen) {
	LOG3(LOG_NEG, (LOG_PAP_BAD,
		      code == PAP_AUTHACK ? "Ack" : "Nak"));
	return(FALSE);
    }

    return(id == u ->us_id);
}


/***********************************************************************
 *				pap_rauthack
 ***********************************************************************
 * SYNOPSIS:	Process received Authenticate-Nak.
 * CALLED BY:	ppp_input
 * RETURN:	nothing
 *
 * STRATEGY:	Verify packet length and length field.
 *	    	Parse message.
 *	    	If id is correct, begin neetwork phase.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_rauthack (pap_state *u,
		   unsigned char *inp,
		   unsigned char id,
		   int len)
{
    unsigned char msglen;

    if (pap_rauthackornak(u, &inp, id, len, PAP_AUTHACK, &msglen)) {
	PRINTMSG(inp, msglen)
	u -> us_clientstate = PAPCS_OPEN;
	BeginNetworkPhase(u -> us_unit);
    }

}  /* End of pap_rauthack */


/***********************************************************************
 *				pap_rauthnak
 ***********************************************************************
 * SYNOPSIS:	Process received Authenticate-Nak.
 * CALLED BY:	ppp_input
 * RETURN:	nothing
 *
 * STRATEGY:	Verify packet length and message length field
 *	    	If id matches then authentication failed so close LCP
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_rauthnak (pap_state *u,
		   unsigned char *inp,
		   unsigned char id,
		   int len)
{
    unsigned char msglen;

    if (pap_rauthackornak(u, &inp, id, len, PAP_AUTHNAK, &msglen)) {
	PRINTMSG(inp, msglen)
	u -> us_clientstate = PAPCS_CLOSED;
	link_error = SSDE_AUTH_FAILED | SDE_CONNECTION_RESET;
	LOG3(LOG_BASE, (LOG_PAP_FAILED));
	DOLOG(authentication_failure = "Authentication failed";)
	lcp_close(u -> us_unit);
    }
}


/***********************************************************************
 *				pap_sauth
 ***********************************************************************
 * SYNOPSIS:	Send an Authenticate-Request.
 * CALLED BY:	pap_authwithpeer
 *	    	pap_timeout
 * RETURN:	nothing
 *
 * STRATEGY:	Allocate packet and stick in user name and password.
 *	    	If either is missing, stick in a zero length for it.
 *	    	Send the packet.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_sauth (pap_state *u)
{
    PACKET *outpacket;
    unsigned char *outp, *data;
    int outlen;

#ifdef LOGGING_ENABLED
    if (! u -> us_user || ! u -> us_passwd)
	LOG3(LOG_BASE, (LOG_PAP_NO_NAME));
#endif /* LOGGING_ENABLED */

    /*
     * Verify lengths are reset to zero whenever data for username or
     * password is freed or not found.
     */
    EC_ERROR_IF((! u -> us_user && u -> us_userlen), -1);
    EC_ERROR_IF((! u -> us_passwd && u -> us_passwdlen), -1);

    outlen = PAP_HEADERLEN + 2 + u -> us_userlen + u -> us_passwdlen;
    outpacket = PACKET_ALLOC(outlen);
    if (outpacket == 0)	    	    	/* no memory */
	return;
    outp = PACKET_DATA(outpacket);

    PUTCHAR(PAP_AUTH, outp);
    PUTCHAR(++u -> us_id, outp);
    PUTSHORT(outlen, outp);
    PUTCHAR(u -> us_userlen, outp);

     /*
      * Stick my name in the packet and send it.  Should have a name
      * as authentication will fail without it, but we don't want to
      * fatal error because of it.  Same goes for the password below.
      * RFC 1334 allows for zero usernames and passwords in PAP.
      */
    if (u -> us_user) {
	MemLock(u -> us_user);
	data = (unsigned char *)MemDeref(u -> us_user);
	memcpy(outp, data, u -> us_userlen);
	MemUnlock(u -> us_user);
    }
    INCPTR(u -> us_userlen, outp);

    PUTCHAR(u -> us_passwdlen, outp);
    if (u -> us_passwd) {
	MemLock(u -> us_passwd);
	data = (unsigned char *)MemDeref(u -> us_passwd);
	memcpy(outp, data, u -> us_passwdlen);
	MemUnlock(u -> us_passwd);
    }

    LOG3(LOG_NEG, (LOG_PAP_SENDING, "Request", u -> us_id));

    PPPSendPacket(u -> us_unit, outpacket, PAP);
}


/***********************************************************************
 *				pap_sresp
 ***********************************************************************
 * SYNOPSIS:	Send a response (ack or nak).
 * CALLED BY:	pap_rauth
 * RETURN:	nothing
 *
 * STRATEGY:	Allocate a packet, fill in data and send it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/11/95		Initial Revision
 *
 ***********************************************************************/
void pap_sresp (pap_state *u,
		unsigned char code,
		unsigned char id,
		char *msg,
		int msglen)
{
    PACKET *outpacket;
    unsigned char *outp;
    int outlen;

    /*
     * Compute packet length and allocate a buffer for it.
     * Packet length is PAP header length, plus 1 byte for msg length,
     * plus the length of the message.
     */
    outlen = PAP_HEADERLEN + 1 + msglen;
    outpacket = PACKET_ALLOC(outlen);
    if (outpacket == 0)	    	    	/* no memory */
	return;
    outp = PACKET_DATA(outpacket);

    PUTCHAR(code, outp);
    PUTCHAR(id, outp);
    PUTSHORT(outlen, outp);
    PUTCHAR(msglen, outp);
    memcpy(outp, msg, msglen);

    LOG3(LOG_NEG, (LOG_PAP_SENDING,
		  code == PAP_AUTHACK ? "Ack" : "Nak", id));

    PPPSendPacket(u -> us_unit, outpacket, PAP);

}
