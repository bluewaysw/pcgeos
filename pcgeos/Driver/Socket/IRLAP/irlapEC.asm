COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapEC.asm

AUTHOR:		Cody Kwok, Apr  4, 1994

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/ 4/94   	Initial revision


DESCRIPTION:
	EC code for IRLAP-SIR driver
		

	$Id: irlapEC.asm,v 1.1 97/04/18 11:56:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IRLAP_CALLBACK_NOT_DEFINED              enum FatalErrors
; User of driver did not define one of the callbacks
IRLAP_ARG_ERROR                         enum FatalErrors
IRLAP_INVALID_STATION                   enum FatalErrors
; Station where event is invoked is not valid 
IRLAP_ERROR_DS_NOT_DGROUP_SEGMENT       enum FatalErrors
IRLAP_ERROR_ES_NOT_DGROUP_SEGMENT       enum FatalErrors
IRLAP_CONNECTION_FAILED                 enum FatalErrors
IRLAP_IDENTICAL_DEVICE_ADDRESS          enum FatalErrors
IRLAP_UNRECOGNIZED_PACKET               enum FatalErrors
IRLAP_UNRECOGNIZED_CONTROL_FIELD        enum FatalErrors
IRLAP_INVALID_PARAM_ID			enum FatalErrors
IRLAP_INVALID_PARAM_VALUE		enum FatalErrors
IRLAP_INVALID_SEQ_INFO			enum FatalErrors
IRLAP_INVALID_LINK_MGT_MODE		enum FatalErrors
IRLAP_INVALID_DISCONNECTION_REASON	enum FatalErrors
IRLAP_STATION_CORRUPTED			enum FatalErrors
IRLAP_GENERAL_FAILURE			enum FatalErrors
IRLAP_INVALID_MEDIUM_TYPE		enum FatalErrors
IRLAP_ADDRESS_INCONSISTANT		enum FatalErrors
IRLAP_STRANGE_ERROR			enum FatalErrors

;; pseudo warnings for tracing events
COLLISION			     enum    Warnings
IRLAP_HACK_FAILED		     enum    Warnings
IRLAP_RECV_INIT_DISCOVERY_FRAME      enum    Warnings
IRLAP_RECV_END_DISCOVERY_FRAME       enum    Warnings
IRLAP_CONNECTION_REQUEST             enum    Warnings
IRLAP_RECV_SNRM_SETUP                enum    Warnings
IRLAP_RECV_SNRM_NDM                  enum    Warnings
IRLAP_CONN_REQUESTED                 enum    Warnings
IRLAP_RECV_SETUP_UA                  enum    Warnings
IRLAP_RECV_DISC_NRM_S                enum    Warnings
IRLAP_RECV_DISC_SETUP                enum    Warnings
IRLAP_RECV_DM_RSP                    enum    Warnings
IRLAP_REQUEST_DISCONNECT_NRM_S       enum    Warnings
IRLAP_REQUEST_DISCONNECT_NRM_P       enum    Warnings
IRLAP_REQUEST_DISCONNECT_CONNECTED   enum    Warnings
IRLAP_RECV_DISCONNECT_NRM_S          enum    Warnings
IRLAP_RECV_DISCONNECT_NRM_P          enum    Warnings
IRLAP_RECV_DISCONNECT_CONNECTED      enum    Warnings
IRLAP_DATA_REQUEST                   enum    Warnings
IRLAP_RECV_DATA_F                    enum    Warnings
IRLAP_RECV_DATA_NON_F                enum    Warnings
IRLAP_RECV_DATA_UNEXP_NR             enum    Warnings
IRLAP_RECV_DATA_UNEXP_NS             enum    Warnings
IRLAP_RECV_DATA_INVAL_NR             enum    Warnings
IRLAP_RECV_DATA_INVAL_NS             enum    Warnings
IRLAP_SEND_RR                        enum    Warnings
IRLAP_REQUEST_DISCONNECT             enum    Warnings
IRLAP_RESENDING_REJ_FRAME            enum    Warnings
_RELEASE_BUFFERED_DATA               enum    Warnings
IRLAP_EXIT                           enum    Warnings
IRLAP_SUCCESS                        enum    Warnings

DISCOVERY_REQUEST                    enum    Warnings
RECV_DISCOVERY_XID_CMD_NDM           enum    Warnings
_SEND_DISCOVERY_SLOT_REPLY	     enum    Warnings
SLOT_TIMER_EXPIRED_QUERY              enum    Warnings
_LAST_DISCOVERY_SLOT                 enum    Warnings
RECV_DISCOVERY_XID_RSP_QUERY         enum    Warnings
DEFAULT_HANDLER_QUERY                enum    Warnings
RECV_DISCOVERY_XID_CMD_REPLY         enum    Warnings
RECV_END_DISCOVERY_XID_CMD_REPLY     enum    Warnings
QUERY_TIMER_EXPIRED_REPLY            enum    Warnings
DEFAULT_HANDLER_REPLY                enum    Warnings
_DISCOVERY_INDICATION                enum    Warnings
_DISCOVERY_CONFIRM                   enum    Warnings
CONNECT_REQUEST                      enum    Warnings
DEFAULT_HANDLER_NDM                  enum    Warnings
RECV_DM_RSP_SETUP                    enum    Warnings
CONNECT_REQUEST_NDM                  enum    Warnings
RECV_SNRM_CMD_NDM                    enum    Warnings
CONNECT_RESPONSE_CONN                enum    Warnings
DISCONNECT_REQUEST_CONN              enum    Warnings
F_TIMER_EXPIRED_SETUP                enum    Warnings
RECV_SNRM_CMD_SETUP                  enum    Warnings
RECV_UA_RSP_SETUP                    enum    Warnings
_CONNECTION_INDICATION                enum    Warnings
_DISCONNECTION_INDICATION             enum    Warnings
_CONNECTION_CONFIRM                   enum    Warnings
_NEGOTIATE_CONNECTION_PARAMETERS      enum    Warnings
_APPLY_CONNECTION_PARAMETERS          enum    Warnings
;; real EC problems
IRLAP_LOCAL_EVENT_NOT_RECOGNIZED     			enum Warnings
_DATA_INDICATION					enum Warnings
_RESEND_REJ_FRAMES					enum Warnings
_RESEND_SREJ_FRAME					enum Warnings
_STOP_ALL_TIMERS					enum Warnings
_RESET_INDICATION					enum Warnings
_STATUS_INDICATION					enum Warnings
_APPLY_DEFAULT_CONNECTION_PARAMS			enum Warnings
_RENEGOTIATE_CONNECTION					enum Warnings
_UNIT_DATA_INDICATION					enum Warnings
_RESET_CONFIRM						enum Warnings
_INIT_CONNECTION_STATE					enum Warnings
DATA_REQUEST_XMIT_P					enum Warnings
DISCONNECT_REQUEST_XMIT_P				enum Warnings
RESET_REQUEST_XMIT_P					enum Warnings
LOCAL_BUSY_DETECTED_XMIT_P				enum Warnings
P_TIMER_EXPIRED_XMIT_P					enum Warnings
RECV_I_RSP_RECV_P					enum Warnings
RECV_I_RSP_NOT_F_RECV_P					enum Warnings
RECV_INVALID_SEQ_RECV_P					enum Warnings
RECV_RNRM_RSP_RECV_P					enum Warnings
RECV_RD_RSP_RECV_P					enum Warnings
RECV_FRMR_RSP_RECV_P					enum Warnings
RECV_REJ_RSP_RECV_P					enum Warnings
RECV_SREJ_RSP_RECV_P					enum Warnings
RECV_RR_RSP_RECV_P					enum Warnings
RECV_RNR_RSP_RECV_P					enum Warnings
F_TIMER_EXPIRED_RECV_P					enum Warnings
LOCAL_BUSY_DETECTED_RECV_P				enum Warnings
RECV_UI_RSP_RECV_P					enum Warnings
RECV_UI_NOT_F_RSP_RECV_P				enum Warnings
RECV_XID_RSP_RECV_P					enum Warnings
DEFAULT_HANDLER_RECV_P					enum Warnings
RESET_REQUEST_RESET_WAIT_P				enum Warnings
RECV_UA_RSP_RESET_P					enum Warnings
RECV_DM_RSP_RESET_P					enum Warnings
F_TIMER_EXPIRED_RESET_P					enum Warnings
DEFAULT_HANDLER_RESET_P					enum Warnings
DATA_REQUEST_BUSY_P					enum Warnings
LOCAL_BUSY_CLEARED_BUSY_P				enum Warnings
P_TIMER_EXPIRED_BUSY_P					enum Warnings
RECV_I_RSP_BUSY_WAIT_P					enum Warnings
RECV_I_RSP_NOT_F_BUSY_WAIT_P				enum Warnings
RECV_UI_RSP_BUSY_WAIT_P					enum Warnings
RECV_RR_RSP_BUSY_WAIT_P					enum Warnings
RECV_REJ_RSP_BUSY_WAIT_P				enum Warnings
F_TIMER_EXPIRED_BUSY_WAIT_P				enum Warnings
DEFAULT_HANDLER_BUSY_WAIT_P				enum Warnings
RECV_UA_RSP_PCLOSE					enum Warnings
F_TIMER_EXPIRED_PCLOSE					enum Warnings
_START_P_TIMER						enum Warnings
_STOP_P_TIMER						enum Warnings
_START_F_TIMER						enum Warnings
_STOP_F_TIMER						enum Warnings
DATA_REQUEST_XMIT_S					enum Warnings
DISCONNECT_REQUEST_XMIT_S				enum Warnings
RESET_REQUEST_XMIT_S					enum Warnings
LOCAL_BUSY_DETECTED_XMIT_S				enum Warnings
RECV_RR_CMD_XMIT_S					enum Warnings
RECV_I_CMD_RECV_S					enum Warnings
RECV_I_CMD_NOT_P_RECV_S					enum Warnings
RECV_SNRM_CMD_RECV_S					enum Warnings
RECV_DISC_CMD_RECV_S					enum Warnings
RECV_REJ_CMD_RECV_S					enum Warnings
RECV_SREJ_CMD_RECV_S					enum Warnings
RECV_RR_CMD_RECV_S					enum Warnings
RECV_RNR_CMD_RECV_S					enum Warnings
WD_TIMER_EXPIRED_RECV_S					enum Warnings
LOCAL_BUSY_DETECTED_BUSY_S				enum Warnings
RECV_UI_CMD_RECV_S					enum Warnings
RECV_UI_CMD_NOT_P_RECV_S				enum Warnings
RECV_XID_CMD_RECV_S					enum Warnings
RECV_INVALID_SEQ_RECV_S					enum Warnings
DEFAULT_HANDER_RECV_S					enum Warnings
RESET_REQUEST_RESET_WAIT_S				enum Warnings
RESET_RESPONSE_RESET_CHECK_S				enum Warnings
DISCONNECT_REQUEST_RESET_CHECK_S			enum Warnings
RECV_SNRM_CMD_RESET_S					enum Warnings
RECV_DM_CMD_RESET_S					enum Warnings
WD_TIMER_EXPIRED_RESET_S				enum Warnings
DEFAULT_HANDLER_RESET_S					enum Warnings
DEFAULT_HANDLER_BUSY_S					enum Warnings
LOCAL_BUSY_CLEARED_BUSY_S				enum Warnings
RECV_I_CMD_BUSY_WAIT_S					enum Warnings
RECV_I_CMD_NOT_P_BUSY_WAIT_S				enum Warnings
RECV_UI_CMD_NOT_P_BUSY_WAIT_S				enum Warnings
RECV_UI_CMD_BUSY_WAIT_S					enum Warnings
RECV_XID_CMD_BUSY_WAIT_S				enum Warnings
RECV_RR_CMD_BUSY_WAIT_S					enum Warnings
RECV_RNR_CMD_BUSY_WAIT_S				enum Warnings
RECV_REJ_CMD_BUSY_WAIT_S				enum Warnings
WD_TIMER_EXPIRED_BUSY_WAIT_S				enum Warnings
RECV_DISC_CMD_SCLOSE					enum Warnings
RECV_DM_RSP_SCLOSE					enum Warnings
WD_TIMER_EXPIRED_SCLOSE					enum Warnings
DEFAULT_HANDLER_SCLOSE					enum Warnings
_WAIT_MINIMUM_TURN_AROUND_DELAY				enum Warnings
_START_WD_TIMER						enum Warnings
_STOP_WD_TIMER						enum Warnings
;
; Sniff
;
SNIFF_REQUEST_NDM					enum Warnings
SENSE_TIMER_EXPIRED_POUT				enum Warnings
RECV_DISCOVERY_XID_CMD_POUT				enum Warnings
RECV_DISCOVERY_XID_CMD_SNIFF				enum Warnings
RECV_SNRM_CMD_SNIFF					enum Warnings
SNIFF_TIMER_EXPIRED_SNIFF				enum Warnings
SLEEP_TIMER_EXPIRED_SLEEP				enum Warnings
RECV_SNIFF_XID_RSP_NDM					enum Warnings
SNIFF_CONNECT_REQUEST_NDM				enum Warnings
RECV_SNIFF_XID_RSP_SCONN				enum Warnings
PTIMER_EXPIRED_SSETUP					enum Warnings
RECV_UA_RSP_SSETUP					enum Warnings
RECV_DM_RSP_SSETUP					enum Warnings
_START_SENSE_TIMER					enum Warnings
_START_SNIFF_TIMER					enum Warnings
_START_SLEEP_TIMER					enum Warnings
;
; Flush data requests
;
FLUSH_DATA_REQUEST_START				enum Warnings
FLUSHING_DATA_REQUEST					enum Warnings
FLUSH_DATA_REQUEST_END					enum Warnings

;
; Frame sent
;
_U_FRAME_SENT						enum Warnings
_I_FRAME_SENT						enum Warnings
_S_FRAME_SENT						enum Warnings
_IRLAP_VS_RESET_TO_NS					enum Warnings
_IRLAP_INC_VS						enum Warnings
_IRLAP_INC_VR						enum Warnings
_IRLAP_CORRUPTED_PACKET_FRAGMENT_DISCARDED		enum Warnings
_DISCARDING_PACKET_IN_REASSEMBLY			enum Warnings
_IRLAP_MISDELIVERED_DATAGRAM				enum Warnings
_IRLAP_OUT_OF_SEQUENCE_FRAGMENT				enum Warnings

;
; Negotiation & Discovery warnings
;
_NO_BAUD_RATE_IN_SNRM					enum Warnings
_NO_NUM_BOF_IN_SNRM					enum Warnings
_NO_MAX_TURN_AROUND_IN_SNRM				enum Warnings
_NO_DATA_SIZE_IN_SNRM					enum Warnings
_NO_WINDOW_SIZE_IN_SNRM					enum Warnings
_NO_MIN_TURN_AROUND_IN_SNRM				enum Warnings
_NO_P_TIMER_IN_SNRM					enum Warnings
_NO_LINK_DISCONNECT_IN_SNRM				enum Warnings
BAD_CONTENTION_TIMEOUT_VALUE				enum Warnings
_ADDRESS_SELECTED					enum Warnings
IRLAP_DEBUG_THIS_NO_LINK_CONNECTION			enum Warnings
_IRLAP_DOES_NOT_PROVIDE_MTU_INFO			enum Warnings

;
; Unitdata
;
UNITDATA_REQUEST_NDM					enum Warnings
UNITDATA_REQUEST_XMIT_P					enum Warnings
UNITDATA_REQUEST_XMIT_S					enum Warnings

DATA_REQUEST_NDM					enum Warnings

IrlapResidentCode	segment resource

if ERROR_CHECK
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that es:di is a valid pointer

CALLED BY:	EC
PASS:		es:di - ptr to verify
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckESDI		proc	far
	uses	ds, si
	.enter

	segmov	ds, es
	mov	si, di				;ds:si <- ptr to check
	call	ECCheckBounds

	.leave
	ret
ECCheckESDI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that ds:si is a valid pointer

CALLED BY:	EC code
PASS:		ds:si - ptr to verify
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckDSSI		proc	far
	.enter

	call	ECCheckBounds

	.leave
	ret
ECCheckDSSI		endp

if 0

;
; I'm taking out this code since it's probably better to use
; the Assert dgroup macro and this code generates a reference
; to dgroup.  Leaving it commented out for the time being in
; case anyone objects, but should probably be cleaned up later.
;



COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckDS_dgroup, ECCheckES_dgroup, ECCheckDS_ES_dgroup

DESCRIPTION:	Error checking routines to make sure we are not fucking up.

PASS:		ds, es	= see below

RETURN:		ds, es	= same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/90		initial version

------------------------------------------------------------------------------@

	


ECCheckES_dgroup	proc	far
	uses 	ax, bx
	.enter
	mov	ax, es
	mov	bx, segment dgroup
	cmp	ax, bx
	ERROR_NE IRLAP_ERROR_ES_NOT_DGROUP_SEGMENT
	.leave
	ret
ECCheckES_dgroup	endp

ECCheckDS_dgroup	proc	far
	uses 	ax, bx, es
	.enter
	mov	bx, handle dgroup
	call	MemDerefES
	mov	bx, ES
	mov	ax, ds
	cmp	ax, bx
	ERROR_NE IRLAP_ERROR_DS_NOT_DGROUP_SEGMENT
	.leave
	ret
ECCheckDS_dgroup	endp

ECCheckDS_ES_dgroup	proc	far
	.enter
	call	ECCheckDS_dgroup
	call	ECCheckES_dgroup
	.leave
	ret
ECCheckDS_ES_dgroup	endp
ForceRef ECCheckDS_ES_dgroup
	
endif

endif

IrlapResidentCode	ends


