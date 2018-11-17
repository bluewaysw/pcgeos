COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapTables.asm

AUTHOR:		Cody Kwok, May 10, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/10/94   	Initial revision


DESCRIPTION:
	Event handling tables in IRLAP.
	Each state in IRLAP has 2 tables, one lookup and one jump.
	The lookup table consists of "event id",  which is a word.
	The jump table consists of a jump addr. (?!)

	Lookup tables consists of virtual far pointers to the routines.

	$Id: irlapTables.asm,v 1.1 97/04/18 11:56:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;; table named by "state???LookupTable" or "state???JumpTable"
;; where ??? = state name
IrlapCommonCode		segment	resource

;; ****************************************************************************
;;
;;  One checks whether an event is applicable for a given state by looking up
;;  this table.
;;
;;  request, 	 response,     busy, 	       expire
;;  ILE_REQUEST, ILE_RESPONSE, ILE_LOCAL_BUSY, ILE_TIME_EXPIRE ; EventCode.high
;;  IRV_????,    IRSV_????,    ILBV_????,      ITEV_????       ; EventCode.low
;;
;; ****************************************************************************
IrlapStateLocalEventTable	byte \
mask IRV_DISCOVERY or mask IRV_CONNECT or mask IRV_SNIFF or mask IRV_DISCONNECT or mask IRV_UNIT_DATA or mask IRV_DATA,
0, mask ILBV_CLEARED, 0,				; IMS_NDM
0, 0, 0, mask ITEV_SLOT,				; IMS_QUERY
0, 0, 0, mask ITEV_QUERY,				; IMS_REPLY
mask IRV_DISCONNECT, mask IRSV_CONNECT, 0, 0,		; IMS_CONN
0, 0, 0, mask ITEV_F,					; IMS_SETUP
mask IRV_DATA or mask IRV_DISCONNECT or mask IRV_RESET \
or mask IRV_UNIT_DATA, 0, mask ILBV_DETECTED or \
mask ILBV_SXCHG_REQ, mask ITEV_P, 			; IMS_XMIT_P
0, 0, mask ILBV_DETECTED, mask ITEV_F,			; IMS_RECV_P
mask IRV_RESET or mask IRV_DISCONNECT, 0, 0, 0,		; IMS_RESET_WAIT_P
mask IRV_DISCONNECT, mask IRSV_RESET, 0, 0,		; IMS_RESET_CHECK_P
0, 0, 0, mask ITEV_F,					; IMS_RESET_P
mask IRV_DATA or mask IRV_DISCONNECT, 0, mask \
	ILBV_CLEARED, mask ITEV_P,			; IMS_BUSY_P
0, 0, mask ILBV_CLEARED, mask ITEV_F,			; IMS_BUST_WAIT_P
0, 0, 0, mask ITEV_F,					; IMS_PCLOSE
mask IRV_DISCONNECT, mask IRSV_SXCHG, 0, mask ITEV_P,	; IMS_XCHG_P
0, 0, 0, mask ITEV_F,					; IMS_XWAIT_P
mask IRV_DATA or mask IRV_DISCONNECT or mask IRV_RESET \
or mask IRV_UNIT_DATA, 0, mask ILBV_DETECTED or \
mask ILBV_SXCHG_REQ, 0,					; IMS_XMIT_S
0, 0, mask ILBV_DETECTED, mask ITEV_WD,			; IMS_RECV_S
0, 0, 0, 0,						; IMS_ERROR_S
mask IRV_DISCONNECT, mask IRSV_RESET, 0, 0,		; IMS_RESET_CHECK_S
0, 0, 0, mask ITEV_WD,					; IMS_RESET_S
mask IRV_DATA, 0, mask ILBV_CLEARED, 0,			; IMS_BUSY_S
0, 0, mask ILBV_CLEARED, mask ITEV_WD,			; IMS_BUSY_WAIT_S
0, 0, 0, mask ITEV_WD,					; IMS_SCLOSE
0, 0, 0, 0,						; IMS_RXWAIT_S
0, 0, 0, mask ITEV_F,					; IMS_XWAIT_S
0, 0, 0, mask ITEV_SENSE,				; IMS_POUT
0, 0, 0, mask ITEV_SNIFF,				; IMS_SNIFF
0, 0, 0, mask ITEV_SLEEP,				; IMS_SLEEP
0, 0, 0, 0,						; IMS_SCONN
0, 0, 0, mask ITEV_P,					; IMS_SSETUP
mask IRV_DATA, mask IRSV_STOP_FLUSH, 0, 0		; IMS_FLUSH_DATA
.assert ((($-IrlapStateLocalEventTable)/4) eq IrlapMachineState)

;; 26 x 4 = 108 bytes 

DefEvent	macro	id
dw	id
COUNTER=COUNTER+1
endm

; ****************************************************************************
;
;	EVENT CODE TABLE
;
; ****************************************************************************
;;  	
;; Format of this table:
;; ;--------------------------------------------------------------------------
;; ;		              *state* name
;; ;--------------------------------------------------------------------------
;; *state*_STATE_OFFSET equ COUNTER
;; DefEvent	<ILE_??? 	shl 8 or mask ???>
;; 		...	local events    ....
;;  
;; *state*_NUM_LOCAL=COUNTER
;; DefEvent	<IEE_??? 	shl 8 or ???>
;; 		...     external events ....
;;  	
;; *state*_NUM_LOCAL = *state*_STATE_OFFSET - *state*_NUM_LOCAL
;;  
	
COUNTER=0
;; the local will always go first 
IrlapStateLookupTable	label	word 
;------------------------------------------------------------------------------
;				    NDM
;------------------------------------------------------------------------------
NDM_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST 	shl 8 or mask IRV_DISCOVERY>
DefEvent 	<ILE_REQUEST 	shl 8 or mask IRV_CONNECT>
DefEvent	<ILE_REQUEST 	shl 8 or mask IRV_SNIFF>
DefEvent	<ILE_REQUEST 	shl 8 or mask IRV_DISCONNECT>
DefEvent	<ILE_REQUEST 	shl 8 or mask IRV_UNIT_DATA>
DefEvent	<ILE_REQUEST 	shl 8 or mask IRV_DATA>
DefEvent	<ILE_LOCAL_BUSY  shl 8 or mask ILBV_CLEARED>
NDM_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD 	shl 8 or IUC_XID_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_XID_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_SNRM_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_UI_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UI_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_TEST_CMD or mask IUCF_PFBIT>
NDM_NUM_LOCAL = NDM_NUM_LOCAL - NDM_STATE_OFFSET
;------------------------------------------------------------------------------
;				   QUERY
;------------------------------------------------------------------------------
QUERY_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_SLOT>
QUERY_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_XID_RSP or mask IUCF_PFBIT>
QUERY_NUM_LOCAL = QUERY_NUM_LOCAL - QUERY_STATE_OFFSET 
;------------------------------------------------------------------------------
;				   REPLY
;------------------------------------------------------------------------------
REPLY_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_QUERY>
REPLY_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_XID_CMD or mask IUCF_PFBIT>
REPLY_NUM_LOCAL = REPLY_NUM_LOCAL - REPLY_STATE_OFFSET
;------------------------------------------------------------------------------
;				   CONN
;------------------------------------------------------------------------------
CONN_STATE_OFFSET equ COUNTER
DefEvent	<ILE_RESPONSE	shl 8 or mask IRSV_CONNECT>
DefEvent	<ILE_REQUEST	shl 8 or mask IRV_DISCONNECT>
CONN_NUM_LOCAL=COUNTER
CONN_NUM_LOCAL = CONN_NUM_LOCAL - CONN_STATE_OFFSET
;------------------------------------------------------------------------------
;				   SETUP
;------------------------------------------------------------------------------
SETUP_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_F>
SETUP_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_SNRM_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UA_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>	
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP>	
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD>	
;; The last 2 kinds of events have undefined PF bit,  so both cases are
;; provided.  
SETUP_NUM_LOCAL = SETUP_NUM_LOCAL - SETUP_STATE_OFFSET
;------------------------------------------------------------------------------
;				   XMIT_P
;------------------------------------------------------------------------------
XMIT_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DATA>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_RESET>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DISCONNECT>
DefEvent	<ILE_LOCAL_BUSY  shl 8 or mask ILBV_DETECTED>
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
DefEvent	<ILE_REQUEST	 shl 8 or mask IRV_UNIT_DATA>
DefEvent	<ILE_LOCAL_BUSY	 shl 8 or mask ILBV_SXCHG_REQ> ; s xchg request
XMIT_P_NUM_LOCAL=COUNTER
XMIT_P_NUM_LOCAL = XMIT_P_NUM_LOCAL - XMIT_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RECV_P
;------------------------------------------------------------------------------
RECV_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_LOCAL_BUSY  shl 8 or mask ILBV_DETECTED>
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_F>
RECV_P_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_RSP	shl 8>			; no poll bit I frame
DefEvent	<IEE_RECV_RSP	shl 8 or mask IICF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UI_RSP>	; UI no poll
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UI_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_XID_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_RR_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_REJ_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_SREJ_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_RNR_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_FRMR_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_RD_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_RNRM_RSP or mask IUCF_PFBIT>
DefEvent	<(IEE_RECV_RSP or mask IEI_SEQINVALID) shl 8>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_RXCHG or mask IUCF_PFBIT>
RECV_P_NUM_LOCAL = RECV_P_NUM_LOCAL - RECV_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RESET_WAIT_P
;------------------------------------------------------------------------------
RESET_WAIT_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_RESET>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DISCONNECT>
RESET_WAIT_P_NUM_LOCAL=COUNTER
RESET_WAIT_P_NUM_LOCAL = RESET_WAIT_P_NUM_LOCAL - RESET_WAIT_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RESET_CHECK_P
;------------------------------------------------------------------------------
RESET_CHECK_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_RESPONSE   shl 8 or mask IRSV_RESET>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DISCONNECT>
RESET_CHECK_P_NUM_LOCAL=COUNTER
RESET_CHECK_P_NUM_LOCAL = RESET_CHECK_P_NUM_LOCAL - RESET_CHECK_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RESET_P
;------------------------------------------------------------------------------
RESET_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_F>
RESET_P_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UA_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>
RESET_P_NUM_LOCAL = RESET_P_NUM_LOCAL - RESET_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   BUSY_P
;------------------------------------------------------------------------------
BUSY_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DATA>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DISCONNECT>
DefEvent	<ILE_LOCAL_BUSY  shl 8 or mask ILBV_CLEARED>
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
BUSY_P_NUM_LOCAL=COUNTER
BUSY_P_NUM_LOCAL = BUSY_P_NUM_LOCAL - BUSY_P_STATE_OFFSET	
;------------------------------------------------------------------------------
;				   BUSY_WAIT_P
;------------------------------------------------------------------------------
BUSY_WAIT_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_F>
DefEvent	<ILE_LOCAL_BUSY  	shl 8 or mask ILBV_CLEARED>
BUSY_WAIT_P_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_RSP	shl 8>			; no poll bit I frame
DefEvent	<IEE_RECV_RSP	shl 8 or mask IICF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UI_RSP>	; UI no poll
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UI_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_XID_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_RR_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_REJ_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or ISR_RNR_RSP or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_RD_RSP or mask IUCF_PFBIT>
BUSY_WAIT_P_NUM_LOCAL = BUSY_WAIT_P_NUM_LOCAL - BUSY_WAIT_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   PCLOSE
;------------------------------------------------------------------------------
PCLOSE_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_F>
PCLOSE_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UA_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>
PCLOSE_NUM_LOCAL = PCLOSE_NUM_LOCAL - PCLOSE_STATE_OFFSET
;------------------------------------------------------------------------------
;				   XCHG_P
;------------------------------------------------------------------------------
XCHG_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST	 shl 8 or mask IRV_DISCONNECT>
DefEvent	<ILE_RESPONSE 	 shl 8 or mask IRSV_SXCHG>
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
XCHG_P_NUM_LOCAL=COUNTER
XCHG_P_NUM_LOCAL = XCHG_P_NUM_LOCAL - XCHG_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   XWAIT_P
;------------------------------------------------------------------------------
XWAIT_P_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_F>
XWAIT_P_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_RR_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_FRMR_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_RD_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask ISCF_PFBIT>
XWAIT_P_NUM_LOCAL = XWAIT_P_NUM_LOCAL - XWAIT_P_STATE_OFFSET
;------------------------------------------------------------------------------
;				   XMIT_S
;------------------------------------------------------------------------------
XMIT_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DATA>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_RESET>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DISCONNECT>
DefEvent	<ILE_LOCAL_BUSY  shl 8 or mask ILBV_DETECTED>
DefEvent	<ILE_REQUEST	 shl 8 or mask IRV_UNIT_DATA>
DefEvent	<ILE_LOCAL_BUSY	 shl 8 or mask ILBV_SXCHG_REQ> ; s xchg request

DefEvent	<IEE_RECV_CMD	shl 8 or ISC_RR_CMD or mask ISCF_PFBIT>
; Handle and discard incoming RR frames in XMIT_S, so that RRs with spurrious
; Vr counts are not queued for later. -CHL 11/21/95

XMIT_S_NUM_LOCAL=COUNTER
XMIT_S_NUM_LOCAL = XMIT_S_NUM_LOCAL - XMIT_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RECV_S
;------------------------------------------------------------------------------
RECV_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_LOCAL_BUSY		shl 8 or mask ILBV_DETECTED>
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_WD>
RECV_S_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8>			; no poll bit I frame
DefEvent	<IEE_RECV_CMD	shl 8 or mask IICF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_UI_CMD>	; UI no poll
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_UI_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_XID_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_RR_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_REJ_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_SREJ_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_RNR_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD 	shl 8 or IUC_SNRM_CMD or mask IUCF_PFBIT>
DefEvent	<(IEE_RECV_CMD or mask IEI_SEQINVALID) shl 8>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_TEST_CMD or mask IUCF_PFBIT>
RECV_S_NUM_LOCAL = RECV_S_NUM_LOCAL - RECV_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   ERROR_S
;------------------------------------------------------------------------------
ERROR_S_STATE_OFFSET equ COUNTER
ERROR_S_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>
ERROR_S_NUM_LOCAL = ERROR_S_NUM_LOCAL - ERROR_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RESET_CHECK_S
;------------------------------------------------------------------------------
RESET_CHECK_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_RESPONSE   shl 8 or mask IRSV_RESET>
DefEvent	<ILE_REQUEST     shl 8 or mask IRV_DISCONNECT>
RESET_CHECK_S_NUM_LOCAL=COUNTER
RESET_CHECK_S_NUM_LOCAL = RESET_CHECK_S_NUM_LOCAL - RESET_CHECK_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RESET_S
;------------------------------------------------------------------------------
RESET_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_WD>
RESET_S_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_SNRM_CMD or mask IUCF_PFBIT>
;; u:dm:x:P -- how can u:dm:cmd:P happen?!  I wonder...
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>
RESET_S_NUM_LOCAL = RESET_S_NUM_LOCAL - RESET_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   BUSY_S
;------------------------------------------------------------------------------
BUSY_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST shl 8 or mask IRV_DATA>
DefEvent	<ILE_LOCAL_BUSY  shl 8 or mask ILBV_CLEARED>
BUSY_S_NUM_LOCAL=COUNTER
BUSY_S_NUM_LOCAL = BUSY_S_NUM_LOCAL - BUSY_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   BUSY_WAIT_S
;------------------------------------------------------------------------------
BUSY_WAIT_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_WD>
DefEvent	<ILE_LOCAL_BUSY  	shl 8 or mask ILBV_CLEARED>
BUSY_WAIT_S_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8>			; no poll bit I frame
DefEvent	<IEE_RECV_CMD	shl 8 or mask IICF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_UI_CMD>	; UI no poll
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_UI_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_XID_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_RR_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_REJ_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or ISC_RNR_CMD or mask ISCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask IUCF_PFBIT>
BUSY_WAIT_S_NUM_LOCAL = BUSY_WAIT_S_NUM_LOCAL - BUSY_WAIT_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   SCLOSE
;------------------------------------------------------------------------------
SCLOSE_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE	shl 8 or mask ITEV_WD>
SCLOSE_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>	
SCLOSE_NUM_LOCAL = SCLOSE_NUM_LOCAL - SCLOSE_STATE_OFFSET
;------------------------------------------------------------------------------
;				   RXWAIT_S
;------------------------------------------------------------------------------
RXWAIT_S_STATE_OFFSET equ COUNTER
RXWAIT_S_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_XCHG or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DXCHG or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask IUCF_PFBIT>
RXWAIT_S_NUM_LOCAL = RXWAIT_S_NUM_LOCAL - RXWAIT_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   XWAIT_S
;------------------------------------------------------------------------------
XWAIT_S_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_F>
XWAIT_S_NUM_LOCAL=COUNTER
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_XCHG or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_DISC_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_RD_RSP or mask IUCF_PFBIT>
XWAIT_S_NUM_LOCAL = XWAIT_S_NUM_LOCAL - XWAIT_S_STATE_OFFSET
;------------------------------------------------------------------------------
;				   POUT
;------------------------------------------------------------------------------
POUT_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
POUT_NUM_LOCAL = COUNTER
POUT_NUM_LOCAL = POUT_NUM_LOCAL - POUT_STATE_OFFSET
DefEvent	<IEE_RECV_CMD 	shl 8 or IUC_XID_CMD or mask IUCF_PFBIT>
;------------------------------------------------------------------------------
;				   SNIFF
;------------------------------------------------------------------------------
SNIFF_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
SNIFF_NUM_LOCAL = COUNTER - SNIFF_STATE_OFFSET
DefEvent	<IEE_RECV_CMD 	shl 8 or IUC_XID_CMD or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_CMD	shl 8 or IUC_SNRM_CMD or mask IUCF_PFBIT>
;------------------------------------------------------------------------------
;				   SLEEP
;------------------------------------------------------------------------------
SLEEP_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
SLEEP_NUM_LOCAL = COUNTER
SLEEP_NUM_LOCAL = SLEEP_NUM_LOCAL - SLEEP_STATE_OFFSET
;------------------------------------------------------------------------------
;				   SCONN
;------------------------------------------------------------------------------
SCONN_STATE_OFFSET equ COUNTER
SCONN_NUM_LOCAL = COUNTER - SCONN_STATE_OFFSET
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_XID_RSP or mask IUCF_PFBIT>
;------------------------------------------------------------------------------
;				   SSETUP
;------------------------------------------------------------------------------
SSETUP_STATE_OFFSET equ COUNTER
DefEvent	<ILE_TIME_EXPIRE shl 8 or mask ITEV_P>
SSETUP_NUM_LOCAL = COUNTER - SSETUP_STATE_OFFSET
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_UA_RSP or mask IUCF_PFBIT>
DefEvent	<IEE_RECV_RSP	shl 8 or IUR_DM_RSP or mask IUCF_PFBIT>	
;------------------------------------------------------------------------------
;				   FLUSH_DATA
;------------------------------------------------------------------------------
FLUSH_DATA_STATE_OFFSET equ COUNTER
DefEvent	<ILE_REQUEST    shl 8 or mask IRV_DATA>
DefEvent	<ILE_RESPONSE	shl 8 or mask IRSV_STOP_FLUSH>
FLUSH_DATA_NUM_LOCAL = COUNTER - FLUSH_DATA_STATE_OFFSET

IRLAP_EVENT_TABLE_SIZE	equ COUNTER


;; *************************************************************************
;;	
;;  A table for generic event handling 
;;  state offset in Lookup table,  number of local events
;;  Each time we fetch 3 bytes: offset, # of local,  and next offset
;;  (so there must be a last dummy byte).
;;
;; *************************************************************************
IrlapHandlerTable	byte	\
	NDM_STATE_OFFSET, 		NDM_NUM_LOCAL,
	QUERY_STATE_OFFSET,		QUERY_NUM_LOCAL,
	REPLY_STATE_OFFSET,		REPLY_NUM_LOCAL,
	CONN_STATE_OFFSET,		CONN_NUM_LOCAL,
	SETUP_STATE_OFFSET,		SETUP_NUM_LOCAL,
	XMIT_P_STATE_OFFSET,		XMIT_P_NUM_LOCAL,
	RECV_P_STATE_OFFSET,		RECV_P_NUM_LOCAL,
	RESET_WAIT_P_STATE_OFFSET,	RESET_WAIT_P_NUM_LOCAL,
	RESET_CHECK_P_STATE_OFFSET,	RESET_CHECK_P_NUM_LOCAL,
	RESET_P_STATE_OFFSET,		RESET_P_NUM_LOCAL,
	BUSY_P_STATE_OFFSET,		BUSY_P_NUM_LOCAL,
	BUSY_WAIT_P_STATE_OFFSET,	BUSY_WAIT_P_NUM_LOCAL,
	PCLOSE_STATE_OFFSET,		PCLOSE_NUM_LOCAL,
	XCHG_P_STATE_OFFSET,		XCHG_P_NUM_LOCAL,
	XWAIT_P_STATE_OFFSET,		XWAIT_P_NUM_LOCAL,
	XMIT_S_STATE_OFFSET,		XMIT_S_NUM_LOCAL,
	RECV_S_STATE_OFFSET,		RECV_S_NUM_LOCAL,
	ERROR_S_STATE_OFFSET,		ERROR_S_NUM_LOCAL,
	RESET_CHECK_S_STATE_OFFSET,	RESET_CHECK_S_NUM_LOCAL,
	RESET_S_STATE_OFFSET,		RESET_S_NUM_LOCAL,
	BUSY_S_STATE_OFFSET,		BUSY_S_NUM_LOCAL,
	BUSY_WAIT_S_STATE_OFFSET,	BUSY_WAIT_S_NUM_LOCAL,
	SCLOSE_STATE_OFFSET,		SCLOSE_NUM_LOCAL,
	RXWAIT_S_STATE_OFFSET,		RXWAIT_S_NUM_LOCAL,
	XWAIT_S_STATE_OFFSET,		XWAIT_S_NUM_LOCAL,
	POUT_STATE_OFFSET,		POUT_NUM_LOCAL,
	SNIFF_STATE_OFFSET,		SNIFF_NUM_LOCAL,
	SLEEP_STATE_OFFSET,		SLEEP_NUM_LOCAL,
	SCONN_STATE_OFFSET,		SCONN_NUM_LOCAL,
	SSETUP_STATE_OFFSET,		SSETUP_NUM_LOCAL,
	FLUSH_DATA_STATE_OFFSET,	FLUSH_DATA_NUM_LOCAL,
	IRLAP_EVENT_TABLE_SIZE		; we need this last entry
					; to get all info about SCLOSE
IRLAP_HANDLER_TABLE_SIZE equ ($-IrlapHandlerTable-1)	; 1 more than normal

;;
;; This would be true when all states are defined 
;;  .assert (IRLAP_HANDLER_TABLE_SIZE eq IrlapMachineState)
;;

; *****************************************************************************
;
;	MACROS
;
; *****************************************************************************

DefAction	macro	action
vfptr	IrlapConnectionCode:&action
COUNTER=COUNTER+1
endm	

DefSXfer	macro	action
vfptr	IrlapTransferCode:&action
COUNTER=COUNTER+1
endm	

DefPXfer	macro	action
vfptr	IrlapTransferCode:&action
COUNTER=COUNTER+1
endm

DefSniff	macro	action
vfptr	IrlapConnectionCode:&action
COUNTER=COUNTER+1
endm

FXIP<	IrlapCommonCode			ends			>
FXIP<	IrlapResidentCode		segment	resource	>

; *****************************************************************************
;
;	ROUTINE TABLE
;
; *****************************************************************************

COUNTER=0
IrlapStateActionTable	label	vfptr
;------------------------------------------------------------------------------
;				    NDM
;------------------------------------------------------------------------------
.assert	(COUNTER eq NDM_STATE_OFFSET)
DefAction	DiscoveryRequestNDM
DefAction	ConnectRequestNDM
DefSniff	SniffRequestNDM
DefAction	DisconnectRequestNDM
DefPXfer	UnitdataRequestNDM
DefPXfer	DataRequestNDM
DefAction	EmptyHandler
; external
DefAction	RecvDiscoveryXidCmdNDM
DefSniff	RecvSniffXidRspNDM
DefAction	RecvSnrmCmdNDM
DefPXfer	RecvUIFrameNDM
DefPXfer	RecvUIFrameNDM
DefAction	RecvTestCmdNDM
;------------------------------------------------------------------------------
;				   QUERY
;------------------------------------------------------------------------------
.assert	(COUNTER eq QUERY_STATE_OFFSET)
DefAction	SlotTimerExpiredQUERY
DefAction	RecvDiscoveryXidRspQUERY
;; DiscoveryAbortConditionQUERY is not included but defined
;------------------------------------------------------------------------------
;				   REPLY
;------------------------------------------------------------------------------
.assert (COUNTER eq REPLY_STATE_OFFSET)
DefAction	QueryTimerExpiredREPLY
DefAction	RecvDiscoveryXidCmdREPLY
;------------------------------------------------------------------------------
;				   CONN
;------------------------------------------------------------------------------
.assert (COUNTER eq CONN_STATE_OFFSET)
DefAction	ConnectResponseCONN
DefAction	DisconnectRequestCONN
;------------------------------------------------------------------------------
;				   SETUP
;------------------------------------------------------------------------------
.assert (COUNTER eq SETUP_STATE_OFFSET)
DefAction	FTimerExpiredSETUP
DefAction	RecvSnrmCmdSETUP
DefAction	RecvUaRspSETUP
DefAction	RecvDmRspSETUP
DefAction	RecvDmRspSETUP
DefAction	RecvDmRspSETUP	; They do the same things
DefAction	RecvDmRspSETUP
;; The last 2 kinds of events have undefined PF bit,  so both cases are
;; provided.  
;------------------------------------------------------------------------------
;				  XMIT_P
;------------------------------------------------------------------------------
.assert (COUNTER eq XMIT_P_STATE_OFFSET)
DefPXfer	DataRequestXMIT_P
DefPXfer	ResetRequestXMIT_P
DefPXfer	DisconnectRequestXMIT_P
DefPXfer	LocalBusyDetectedXMIT_P
DefPXfer	PTimerExpiredXMIT_P
DefPXfer	UnitdataRequestXMIT_P
DefPXfer	PrimaryRequestXMIT_P
;------------------------------------------------------------------------------
;				  RECV_P
;------------------------------------------------------------------------------
.assert (COUNTER eq RECV_P_STATE_OFFSET)
DefPXfer	LocalBusyDetectedRECV_P
DefPXfer	FTimerExpiredRECV_P
DefPXfer	RecvIRspNotFRECV_P
DefPXfer	RecvIRspFRECV_P
DefPXfer	RecvUiRspNotFRECV_P
DefPXfer	RecvUiRspFRECV_P
DefPXfer	RecvXidRspRECV_P
DefPXfer	RecvRrRspRECV_P
DefPXfer	RecvRejRspRECV_P
DefPXfer	RecvSrejRspRECV_P
DefPXfer	RecvRnrRspRECV_P
DefPXfer	RecvFrmrRspRECV_P
DefPXfer	RecvRdRspRECV_P
DefPXfer	RecvRnrmRspRECV_P
DefPXfer	RecvInvalidSeqRECV_P
DefPXfer	RecvRxchgRECV_P
;------------------------------------------------------------------------------
;			       RESET_WAIT_P
;------------------------------------------------------------------------------
.assert (COUNTER eq RESET_WAIT_P_STATE_OFFSET)
DefPXfer	ResetRequestRESET_WAIT_P
DefPXfer	DisconnectRequestXMIT_P  ; same action as XMIT_P's
;------------------------------------------------------------------------------
;			       RESET_CHECK_P
;------------------------------------------------------------------------------
.assert (COUNTER eq RESET_CHECK_P_STATE_OFFSET)
DefPXfer	ResetRequestRESET_WAIT_P
DefPXfer	DisconnectRequestXMIT_P  ; same action as XMIT_P's
;------------------------------------------------------------------------------
;				  RESET_P
;------------------------------------------------------------------------------
.assert (COUNTER eq RESET_P_STATE_OFFSET)
DefPXfer	FTimerExpiredRESET_P
DefPXfer	RecvUaRspRESET_P
DefPXfer	RecvDmRspRESET_P
;------------------------------------------------------------------------------
;				  BUSY_P
;------------------------------------------------------------------------------
.assert (COUNTER eq BUSY_P_STATE_OFFSET)
DefPXfer	DataRequestBUSY_P
DefPXfer	DisconnectRequestXMIT_P	; DisconnectRequestBUSY_P same as this
DefPXfer	LocalBusyClearedBUSY_P
DefPXfer	PTimerExpiredBUSY_P
;------------------------------------------------------------------------------
;				  BUSY_WAIT_P
;------------------------------------------------------------------------------
.assert (COUNTER eq BUSY_WAIT_P_STATE_OFFSET)
DefPXfer	FTimerExpiredBUSY_WAIT_P
DefPXfer	BusyClearedBUSY_WAIT_P
DefPXfer	RecvIRspNotFBUSY_WAIT_P
DefPXfer	RecvIRspFBUSY_WAIT_P
DefAction	EmptyHandler		; UI:notF: Empty action
DefPXfer	RecvUiRspFBUSY_WAIT_P
DefPXfer	RecvUiRspFBUSY_WAIT_P	; Recv XID, but same action
DefPXfer	RecvRrRspBUSY_WAIT_P
DefPXfer	RecvRejRspBUSY_WAIT_P
DefPXfer	RecvRrRspBUSY_WAIT_P	; Recv RNR, but same action as RR
DefPXfer	RecvRdRspRECV_P		; same action
;------------------------------------------------------------------------------
;				  PCLOSE
;------------------------------------------------------------------------------
.assert (COUNTER eq PCLOSE_STATE_OFFSET)
DefPXfer	FTimerExpiredPCLOSE
DefPXfer	RecvUaRspPCLOSE
DefPXfer	RecvUaRspPCLOSE		; Recv DM, but same action as UA
;------------------------------------------------------------------------------
;				  XCHG_P
;------------------------------------------------------------------------------
.assert (COUNTER eq XCHG_P_STATE_OFFSET)
DefPXfer	DisconnectRequestXCHG_P
DefPXfer	PrimaryResponseXCHG_P
DefPXfer	PTimerExpiredXCHG_P
;------------------------------------------------------------------------------
;				  XWAIT_P
;------------------------------------------------------------------------------
.assert (COUNTER eq XWAIT_P_STATE_OFFSET)
DefPXfer	FTimerExpiredXWAIT_P
DefPXfer	RecvRrCmdXWAIT_P
DefPXfer	RecvFrmrRspXWAIT_P
DefPXfer	RecvRdRspXWAIT_P
DefPXfer	RecvDiscCmdXWAIT_P
;------------------------------------------------------------------------------
;				  XMIT_S
;------------------------------------------------------------------------------
.assert (COUNTER eq XMIT_S_STATE_OFFSET)
DefSXfer	DataRequestXMIT_S
DefSXfer	ResetRequestXMIT_S
DefSXfer	DisconnectRequestXMIT_S
DefSXfer	LocalBusyDetectedXMIT_S
DefSXfer	UnitdataRequestXMIT_S
DefSXfer	PrimaryRequestXMIT_S

DefSXfer	RecvRrCmdXMIT_S
; Handle and discard incoming RR frames in XMIT_S, so that RRs with spurrious
; Vr counts are not queued for later. -CHL 11/21/95
 
;------------------------------------------------------------------------------
;				  RECV_S
;------------------------------------------------------------------------------
.assert (COUNTER eq RECV_S_STATE_OFFSET)
DefSXfer	LocalBusyDetectedRECV_S
DefSXfer	WDTimerExpiredRECV_S
DefSXfer	RecvICmdNotPRECV_S
DefSXfer	RecvICmdPRECV_S
DefSXfer	RecvUiCmdNotPRECV_S
DefSXfer	RecvUiCmdPRECV_S
DefSXfer	RecvXidCmdRECV_S
DefSXfer	RecvRrCmdRECV_S
DefSXfer	RecvRejCmdRECV_S
DefSXfer	RecvSrejCmdRECV_S
DefSXfer	RecvRnrCmdRECV_S
DefSXfer	RecvDiscCmdRECV_S
DefSXfer	RecvSnrmCmdRECV_S
DefSXfer	RecvInvalidSeqRECV_S
DefSXfer	RecvTestCmdRECV_S
;------------------------------------------------------------------------------
;			       ERROR_S
;------------------------------------------------------------------------------
.assert (COUNTER eq ERROR_S_STATE_OFFSET)
DefSXfer	RecvDiscCmdPERROR_S
DefSXfer	RecvDmRspPERROR_S
;------------------------------------------------------------------------------
;			       RESET_CHECK_S
;------------------------------------------------------------------------------
.assert (COUNTER eq RESET_CHECK_S_STATE_OFFSET)
DefSXfer	ResetResponseRESET_CHECK_S
DefSXfer	DisconnectRequestRESET_CHECK_S  ; same action as XMIT_S's
;------------------------------------------------------------------------------
;				  RESET_S
;------------------------------------------------------------------------------
.assert (COUNTER eq RESET_S_STATE_OFFSET)
DefSXfer	WDTimerExpiredRESET_S
DefSXfer	RecvSnrmCmdRESET_S
DefSXfer	RecvDmCmdRESET_S	; for u:dm:x:P
DefSXfer	RecvDmCmdRESET_S
;------------------------------------------------------------------------------
;				  BUSY_S
;------------------------------------------------------------------------------
.assert (COUNTER eq BUSY_S_STATE_OFFSET)
DefSXfer	DataRequestBUSY_S
DefSXfer	LocalBusyClearedBUSY_S
;------------------------------------------------------------------------------
;				  BUSY_WAIT_S
;------------------------------------------------------------------------------
.assert (COUNTER eq BUSY_WAIT_S_STATE_OFFSET)
DefSXfer	WDTimerExpiredBUSY_WAIT_S
DefSXfer	BusyClearedBUSY_WAIT_S
DefSXfer	RecvICmdNotPBUSY_WAIT_S
DefSXfer	RecvICmdPBUSY_WAIT_S
DefSXfer	RecvUiCmdNotPBUSY_WAIT_S
DefSXfer	RecvUiCmdPBUSY_WAIT_S
DefSXfer	RecvXidCmdBUSY_WAIT_S
DefSXfer	RecvRrCmdBUSY_WAIT_S
DefSXfer	RecvRejCmdBUSY_WAIT_S
DefSXfer	RecvRnrCmdBUSY_WAIT_S
DefSXfer	RecvDiscCmdRECV_S	; this is not in spec 1.0
;------------------------------------------------------------------------------
;				  SCLOSE
;------------------------------------------------------------------------------
.assert (COUNTER eq SCLOSE_STATE_OFFSET)
DefSXfer	WDTimerExpiredSCLOSE
DefSXfer	RecvDiscCmdSCLOSE
DefSXfer	RecvDmRspSCLOSE		; Recv DM, but same action as UA
;------------------------------------------------------------------------------
;				  RXWAIT_S
;------------------------------------------------------------------------------
.assert (COUNTER eq RXWAIT_S_STATE_OFFSET)
DefSXfer	RecvXchgCmdRXWAIT_S
DefSXfer	RecvDxchgRXWAIT_S
DefSXfer	RecvDiscCmdRXWAIT_S
;------------------------------------------------------------------------------
;				  XWAIT
;------------------------------------------------------------------------------
.assert (COUNTER eq XWAIT_S_STATE_OFFSET)
DefSXfer	FTimerExpiredXWAIT_S
DefSXfer	RecvXchgCmdXWAIT_S
DefSXfer	RecvDiscCmdXWAIT_S
DefSXfer	RecvRdCmdXWAIT_S
;------------------------------------------------------------------------------
;				  POUT
;------------------------------------------------------------------------------
.assert (COUNTER eq POUT_STATE_OFFSET)
DefSniff	SenseTimerExpiredPOUT
DefSniff	RecvDiscoveryXidCmdPOUT
;------------------------------------------------------------------------------
;				  SNIFF
;------------------------------------------------------------------------------
.assert (COUNTER eq SNIFF_STATE_OFFSET)
DefSniff	SniffTimerExpiredSNIFF
DefSniff	RecvDiscoveryXidCmdSNIFF
DefSniff	RecvSnrmCmdSNIFF
;------------------------------------------------------------------------------
;				  SLEEP
;------------------------------------------------------------------------------
.assert (COUNTER eq SLEEP_STATE_OFFSET)
DefSniff	SleepTimerExpiredSLEEP
;------------------------------------------------------------------------------
;				  SCONN
;------------------------------------------------------------------------------
.assert (COUNTER eq SCONN_STATE_OFFSET)
DefSniff	RecvSniffXidRspSCONN
;------------------------------------------------------------------------------
;				  SSETUP
;------------------------------------------------------------------------------
.assert (COUNTER eq SSETUP_STATE_OFFSET)
DefSniff	PTimerExpiredSSETUP
DefSniff	RecvUaRspSSETUP
DefSniff	RecvDmRspSSETUP

;------------------------------------------------------------------------------
;				  FLUSH_DATA
;------------------------------------------------------------------------------
.assert (COUNTER eq FLUSH_DATA_STATE_OFFSET)
DefAction	DataRequestFLUSH_DATA
DefAction	StopFlushResponseFLUSH_DATA
.assert	(COUNTER eq IRLAP_EVENT_TABLE_SIZE)

IRLAP_ACTION_TABLE_SIZE	equ COUNTER	; This is where the normal
					; function defs end.


FXIP<	IrlapResidentCode		ends			>
FXIP<	IrlapCommonCode			segment	resource	>
;------------------------------------------------------------------------------
;			Default handler for states
;------------------------------------------------------------------------------
COUNTER=0
IrlapDefaultHandlerTable 	label 	vfptr
DefAction	DefaultHandlerNDM			; NDM
DefAction	EmptyHandler				; QUERY
DefAction	EmptyHandler				; REPLY
DefAction	EmptyHandler				; CONN
DefAction	EmptyHandler				; SETUP
;; primary 
DefAction	NullHandler				; XMIT_P
DefPXfer	DefaultHandlerRECV_P			; RECV_P
DefAction	NullHandler				; RESET_WAIT_P
DefAction	NullHandler				; RESET_CHECK_P
DefPXfer	DefaultHandlerRESET_P			; RESET_P
DefAction	NullHandler				; BUSY_P
DefPXfer	DefaultHandlerBUSY_WAIT_P		; BUSY_WAIT_P
DefAction	NullHandler				; PCLOSE
DefAction	NullHandler				; XCHG_P
DefPXfer	DefaultHandlerXWAIT_P			; XWAIT_P
;; secondary 
DefAction	NullHandler				; XMIT_S
DefSXfer	DefaultHandlerRECV_S			; RECV_S
DefSXfer	DefaultHandlerERROR_S			; ERROR_S
DefAction	NullHandler				; RESET_CHECK_S
DefSXfer	DefaultHandlerRESET_S			; RESET_S
DefAction	NullHandler				; BUSY_S
DefAction	NullHandler				; BUSY_WAIT_S
DefSXfer	DefaultHandlerSCLOSE			; SCLOSE
DefSXfer	DefaultHandlerRXWAIT_S			; RXWAIT_S
DefSXfer	DefaultHandlerXWAIT_S			; XWAIT_S
;; sniff
DefAction	NullHandler				; POUT
DefAction	NullHandler				; SNIFF
DefAction	NullHandler				; SLEEP
DefAction	NullHandler				; SCONN
DefAction	NullHandler				; SSETUP
;
; outside Irlap State machine
;
DefAction	NullHandler				; FLUSH_DATA

;
; Driver control routines
;	These routines perform functions that do not belong to IRLAP protocol
; but that belong to the implementation of this driver(ex. shutdown thread).
;
DriverControlTable	nptr \
	offset IDCDetach,
if _SOCKET_INTERFACE
	offset IDCAddressSelected,
endif
	offset IDCAbortSniff,
	offset IDCStartFlushDataRequests,
	offset IrlapSocketDoNothing		; IDC_CHECK_STORED_EVENTS

IrlapCommonCode		ends


