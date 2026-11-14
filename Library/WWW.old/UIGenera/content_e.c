pragma Comment("@content.goc");

# 1 "content_e.c"

# 27 "content_e.c"


#ifndef __GOCuigenera
#define __GOCuigenera

# 1 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

































#ifndef __GOCstdapp
#define __GOCstdapp

# 1 "/staff/pcgeos/CInclude/stdapp.goh"



















#include <geos.h>
#include <heap.h>
#include <geode.h>
#include <resource.h>
#include <ec.h>

#ifndef __GOCobject
#define __GOCobject

# 1 "/staff/pcgeos/CInclude/object.goh"































#endif

# 26 "/staff/pcgeos/CInclude/stdapp.goh"
#include <object.h>
#include <graphics.h>
#include <fontID.h>
#include <gstring.h>
#include <timer.h>
#include <vm.h>
#include <dbase.h>
#include <localize.h>
#include <system.h>
#include <geoworks.h>


#ifndef __GOCui
#define __GOCui

# 1 "/staff/pcgeos/CInclude/ui.goh"




















#ifndef __GOCmetaC
#define __GOCmetaC

# 1 "/staff/pcgeos/CInclude/Objects/metaC.goh"




















#include <chunkarr.h>

#ifndef __GOCobject
#define __GOCobject
#include "/staff/pcgeos/CInclude/object.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/metaC.goh"
#include <object.h>
#include <geode.h>
#include <Objects/helpCC.h>








typedef struct {
    ClassStruct	*MB_class;
} MetaBase;

typedef struct {
    word	ax;
    word	cx;
    word	dx;
    word	bp;
} AsmPassReturn;








#define _FIRST_MetaClass 0
# 51 "/staff/pcgeos/CInclude/Objects/metaC.goh"


















	

#define MSG_META_ATTACH_PROCESS MSG_META_ATTACH


#define MSG_META_ATTACH_GENPROCESSCLASS MSG_META_ATTACH



#define MSG_META_ATTACH_OBJECT MSG_META_ATTACH

#define MSG_META_ATTACH_THREAD MSG_META_ATTACH





















	









  


  


  



	

#define PTR_LEAVE_LEFT		0x01
#define PTR_LEAVE_TOP		0x02
#define PTR_LEAVE_RIGHT		0x04
#define PTR_LEAVE_BOTTOM	0x08



 

  



 		







#define MSG_META_QUIT_PROCESS MSG_META_QUIT


#define MSG_META_QUIT_OBJECT MSG_META_QUIT



typedef enum  {
    QL_BEFORE_UI,
    QL_UI,
    QL_AFTER_UI,
    QL_DETACH,
    QL_AFTER_DETACH
} QuitLevel;














  

typedef enum {
    TO_NULL,
    TO_SELF,
    TO_OBJ_BLOCK_OUTPUT,
    TO_PROCESS
} TravelOption;


	

	

typedef struct {
    ClassStruct		*GTP_class;
    optr		GTP_target;
} GetTargetParams;



	




 

 








typedef struct {
	ManufacturerID	NT_manuf;
	word		NT_type;
} NotificationType;



















typedef	struct {
    word	GCNLT_manuf;
    word	GCNLT_type;
} GCNListType;


typedef WordFlags GCNListTypeFlags;
#define GCNLTF_SAVE_TO_STATE	0x0001


typedef struct {
	optr	GCNLE_item;
} GCNListElement;


typedef struct {
	ChunkArrayHeader	GCNLH_meta;
	word			GCNLH_statusEvent;
	MemHandle		GCNLH_statusData;
	word			GCNLH_statusCount;
	
} GCNListHeader;


typedef struct {
	GCNListType		GCNLOLE_ID;
	ChunkHandle		GCNLOLE_list;
} GCNListOfListsElement;




typedef struct {
	ChunkArrayHeader	GCNLOL_meta;
	
} GCNListOfListsHeader;











typedef ByteFlags TempMetaGCNFlags;
#define TMGCNF_RELOCATED	0x80

typedef	struct {
	ChunkHandle		TMGCND_listOfLists;
	TempMetaGCNFlags	TMGCND_flags;
} TempMetaGCNData;

#define TEMP_META_GCN 0

#define TEMP_META_QUIT_LIST 4





typedef	struct {
    GCNListType		GCNLP_ID;
    optr		GCNLP_optr;
} GCNListParams;


 				 

  				



typedef WordFlags GCNListSendFlags;
#define GCNLSF_SET_STATUS			0x8000
#define GCNLSF_IGNORE_IF_STATUS_TRANSITIONING	0x4000
#define GCNLSF_FORCE_QUEUE			0x2000



 






#define INI_CATEGORY_BUFFER_SIZE 64









	


 

typedef enum {
    OFIQNS_SYSTEM_INPUT_OBJ=0,
    OFIQNS_INPUT_OBJ_OF_OWNING_GEODE=2,
    OFIQNS_PROCESS_OF_OWNING_GEODE=4,
    OFIQNS_DISPATCH=6
} ObjFlushInputQueueNextStop;



	



typedef WordFlags UpdateWindowFlags;
#define UWF_ATTACHING			0x8000;
#define UWF_DETACHING			0x4000;
#define UWF_RESTORING_FROM_STATE	0x2000;
#define UWF_TOP_LEVEL_WINDOW		0x1000;










typedef struct {
    HelpType	HTR_helpType;
    byte    	HTR_unused1;
    word    	HTR_unused2;
} HelpTypeReturn;













 				 






















































































typedef	struct {
	word		DDE_ackCount;
	word		DDE_callerID;
	optr		DDE_ackOD;
	word		DDE_completeMsg;
} DetachDataEntry;
#define DETACH_DATA 8

#define TEMP_EC_IN_USE_COUNT 12

#define TEMP_EC_INTERACTIBLE_COUNT 16


					
typedef struct {
	word	EAFTPPD_priority;
	optr	EAFTPPD_avoidOptr;
} EnsureActiveFTPriorityPreferenceData;
#define TEMP_META_ENSURE_ACTIVE_FT_LAYER_PRIORITY_PREFERENCE 20


typedef struct {
        char            DODRI_tempOwner[GEODE_NAME_SIZE];
        word            DODRI_tempResource;
} DebugObjDuplicateResourceInfo;
#define DEBUG_META_OBJ_DUPLICATE_RESOURCE_INFO 24


extern ClassStruct _far MetaClass; extern Message _Messages_MetaClass[]; extern MessageMethod *_Methods_MetaClass[]; extern CMethodDef _htypes_MetaClass[];extern MessageMethod *_Reloc_MetaClass;
typedef struct _MetaInstance {

# 53 "/staff/pcgeos/CInclude/Objects/metaC.goh"
    MetaBase MI_base;} MetaInstance; 
# 494 "/staff/pcgeos/CInclude/Objects/metaC.goh"
typedef enum{MSG_META_NULL,MSG_META_INITIALIZE,MSG_META_RESERVED_1,MSG_META_DUMMY,MSG_META_APP_STARTUP,MSG_META_ATTACH,MSG_META_DETACH,MSG_META_DETACH_COMPLETE,MSG_META_DETACH_ABORT,MSG_META_ACK,MSG_META_APP_SHUTDOWN,MSG_META_SHUTDOWN_COMPLETE,MSG_META_SHUTDOWN_ACK,MSG_META_GET_CLASS,MSG_META_IS_OBJECT_IN_CLASS,MSG_META_BLOCK_FREE,MSG_META_OBJ_FREE,MSG_META_FINAL_OBJ_FREE,MSG_META_DEC_BLOCK_REF_COUNT,MSG_META_RESOLVE_VARIANT_SUPERCLASS,MSG_META_RELOCATE,MSG_META_UNRELOCATE,MSG_META_LEAVE_CONSTRAIN,MSG_META_SET_FLAGS,MSG_META_GET_FLAGS,MSG_META_VM_FILE_DIRTY,MSG_META_QUIT,MSG_META_QUIT_ACK,MSG_META_DISPATCH_EVENT,MSG_META_SEND_CLASSED_EVENT,MSG_META_GET_OPTR,MSG_META_GET_TARGET_AT_TARGET_LEVEL,MSG_META_ADD_VAR_DATA,MSG_META_DELETE_VAR_DATA,MSG_META_INITIALIZE_VAR_DATA,MSG_META_NOTIFY,MSG_META_NOTIFY_WITH_DATA_BLOCK,MSG_META_GCN_LIST_ADD,MSG_META_GCN_LIST_REMOVE,MSG_META_GCN_LIST_SEND,MSG_META_GCN_LIST_DESTROY,MSG_META_SAVE_OPTIONS,MSG_META_GET_INI_CATEGORY,MSG_META_SUSPEND,MSG_META_UNSUSPEND,MSG_META_LOAD_OPTIONS,MSG_META_GET_VAR_DATA,MSG_META_NOTIFY_OBJ_BLOCK_INTERACTIBLE,MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE,MSG_META_OBJ_FLUSH_INPUT_QUEUE,MSG_META_WIN_DEC_REF_COUNT,MSG_META_UPDATE_WINDOW,MSG_META_FINISH_QUIT,MSG_META_SET_OBJ_BLOCK_OUTPUT,MSG_META_GET_HELP_FILE,MSG_META_GET_HELP_TYPE,MSG_META_GET_OBJ_BLOCK_OUTPUT,MSG_META_RESET_OPTIONS,MSG_META_BRING_UP_HELP,MSG_META_SET_HELP_FILE,MSG_META_GCN_LIST_FIND_ITEM,MSG_META_TRANSPARENT_DETACH,MSG_META_REMOVING_DISK,MSG_META_VM_FILE_SET_INITIAL_DIRTY_LIMIT,MSG_META_VM_FILE_AUTO_SAVE,}MetaMessages;





extern void	
    _pascal ObjInitDetach(MetaMessages msg, optr obj, word callerID, optr ackOD);



extern void	
    _pascal ObjIncDetach(optr obj);



extern void	
    _pascal ObjEnableDetach(optr obj);





typedef struct {
    optr	LP_next;	
				
				
} LinkPart;

#define LP_IS_PARENT	1		



extern optr
    _pascal ObjLinkFindParent(optr obj, word masterOffset, word linkOffset);





typedef struct {
    optr	CP_firstChild;
} CompPart;

typedef WordFlags CompChildFlags;
#define CCF_MARK_DIRTY	0x8000
#define CCF_REFERENCE	0x7fff

#define CCO_FIRST	0x0000
#define CCO_LAST	0x7FFF

#define CCF_REFERENCE_OFFSET 0

typedef ByteEnum InsertChildOption;
#define ICO_FIRST 0
#define ICO_LAST 1
#define ICO_BEFORE_REFERENCE 2
#define ICO_AFTER_REFERENCE 3

typedef WordFlags InsertChildFlags;
#define ICF_MARK_DIRTY	0x8000
#define ICF_OPTIONS	0x0003



extern word			
    _pascal ObjCompFindChildByOptr(optr obj, optr childToFind, word masterOffset,
			   word compOffset, word linkOffset);

extern optr	
    _pascal ObjCompFindChildByNumber(optr obj, word childToFind, word masterOffset,
			     word compOffset, word linkOffset);



extern void	
    _pascal ObjCompAddChild(optr obj, optr objToAdd, word flags, word masterOffset,
		    word compOffset, word linkOffset);



extern void	
    _pascal ObjCompRemoveChild(optr obj, optr objToRemove, word flags,
		       word masterOffset, word compOffset, word linkOffset);



extern void	
    _pascal ObjCompMoveChild(optr obj, optr objToMove, word flags, word masterOffset,
		     word compOffset, word linkOffset);



typedef enum  {
    OCCT_SAVE_PARAMS_TEST_ABORT=0,
    OCCT_SAVE_PARAMS_DONT_TEST_ABORT=2,
    OCCT_DONT_SAVE_PARAMS_TEST_ABORT=4,
    OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT=6,
    OCCT_ABORT_AFTER_FIRST=8,
    OCCT_COUNT_CHILDREN=10
} ObjCompCallType;

extern Boolean			
    _pascal ObjCompProcessChildren(optr obj, optr firstChild,
			   ObjCompCallType stdCallback,
			   void *cbData, word masterOffset,
			   word compOffset, word linkOffset,
			   PCB(Boolean, callback, (optr parent, optr child,
						void *cbData)));


#ifdef __HIGHC__
pragma Alias(ObjInitDetach, "OBJINITDETACH");
pragma Alias(ObjIncDetach, "OBJINCDETACH");
pragma Alias(ObjEnableDetach, "OBJENABLEDETACH");
pragma Alias(ObjLinkFindParent, "OBJLINKFINDPARENT");
pragma Alias(ObjCompFindChildByOptr, "OBJCOMPFINDCHILDBYOPTR");
pragma Alias(ObjCompFindChildByNumber, "OBJCOMPFINDCHILDBYNUMBER");
pragma Alias(ObjCompAddChild, "OBJCOMPADDCHILD");
pragma Alias(ObjCompRemoveChild, "OBJCOMPREMOVECHILD");
pragma Alias(ObjCompMoveChild, "OBJCOMPMOVECHILD");
pragma Alias(ObjCompProcessChildren, "OBJCOMPPROCESSCHILDREN");
#endif


#endif

# 21 "/staff/pcgeos/CInclude/ui.goh"

#ifndef __GOCinputC
#define __GOCinputC

# 1 "/staff/pcgeos/CInclude/Objects/inputC.goh"
























#ifndef __GOCmetaC
#define __GOCmetaC
#include "/staff/pcgeos/CInclude/Objects/metaC.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/inputC.goh"





#define GET_BUTTON_INFO(val) 	((byte) (val))
#define GET_SHIFT_STATE(val) 	((byte) ((val) >> 8))




#define MSG_META_MOUSE_BUTTON 117








#define MSG_META_MOUSE_PTR 118	









#define MSG_META_PTR MSG_META_MOUSE_PTR











#define MSG_META_KBD_CHAR 119

#define MSG_META_PRESSURE 120	

#define MSG_META_DIRECTION 121	

#define MSG_META_MOUSE_TIMER 122




#define MSG_META_MOUSE_DRAG 123








#endif

# 22 "/staff/pcgeos/CInclude/ui.goh"
#include <disk.h>

#ifndef __GOCclipbrd
#define __GOCclipbrd

# 1 "/staff/pcgeos/CInclude/Objects/clipbrd.goh"





















#include <geoworks.h>
#include <geode.h>
#include <graphics.h>

#ifndef __GOCmetaC
#define __GOCmetaC
#include "/staff/pcgeos/CInclude/Objects/metaC.poh"
#endif

# 26 "/staff/pcgeos/CInclude/Objects/clipbrd.goh"

#ifndef __GOCuiInputC
#define __GOCuiInputC

# 1 "/staff/pcgeos/CInclude/Objects/uiInputC.goh"





















#include <input.h>

typedef WordFlags MetaAlterFTVMCExclFlags;
#define MAEF_NOT_HERE		0x8000
#define MAEF_SYS_EXCL		0x4000
#define MAEF_APP_EXCL		0x2000
#define MAEF_GRAB		0x1000
#define MAEF_FOCUS		0x0800
#define MAEF_TARGET		0x0400
#define MAEF_MODEL		0x0200
#define MAEF_FULL_SCREEN	0x0100
#define MAEF_MODAL		0x0004
#define MAEF_OD_IS_WINDOW	0x0002
#define MAEF_OD_IS_MENU_RELATED 0x0001

#define MAEF_MASK_OF_ALL_HIERARCHIES    0x0f00

typedef enum  {
	IRV_NO_REPLY,
	IRV_NO_INK,
	IRV_INK_WITH_STANDARD_OVERRIDE,
	IRV_DESIRES_INK,
	IRV_WAIT
} InkReturnValue;

typedef struct {
    MemHandle	    destInfo;
    InkReturnValue  inkType;
    word    unused1;
    word    unused2;
} InkReturnParams; 
















typedef struct {
    optr		IDI_destObj;



    GStateHandle	IDI_gstate;






    word		IDI_brushSize;






    dword	IDI_gestureCallback;



















} InkDestinationInfo;

typedef ByteFlags UIFunctionsActive;
#define UIFA_SELECT	0x80
#define UIFA_MOVE_COPY	0x40
#define UIFA_FEATURES	0x20
#define UIFA_CONSTRAIN	0x10
#define UIFA_PREF_A	0x08
#define UIFA_PREF_B	0x04
#define UIFA_PREF_C	0x02
#define UIFA_IN		0x01

#define UIFA_ADJUST	0x08
#define UIFA_EXTEND	0x04
#define UIFA_MOVE	0x08
#define UIFA_COPY	0x04
#define UIFA_POPUP	0x08
#define UIFA_PAN	0x04





#define GET_BUTTON_INFO(val) 		((byte) (val))
#define GET_UI_FUNCTIONS_ACTIVE(val) 	((byte) ((val) >> 8))

typedef WordFlags MouseReturnFlags;
#define    MRF_PROCESSED		0x8000
#define    MRF_REPLAY			0x4000
#define    MRF_PREVENT_PASS_THROUGH	0x2000
#define    MRF_SET_POINTER_IMAGE	0x1000
#define    MRF_CLEAR_POINTER_IMAGE	0x0800





typedef struct {
	word			unused;
	MouseReturnFlags	flags;
	optr			ptrImage;
	
} MouseReturnParams;





typedef struct {
	PointDWFixed	LMD_location;
	byte		LMD_buttonInfo;
	UIFunctionsActive	LMD_uiFunctionsActive;
} LargeMouseData;



typedef ByteFlags UIButtonFlags;
#define UIBF_NO_KEYBOARD		0x80
#define UIBF_CLICK_TO_TYPE		0x40
#define UIBF_SELECT_ALWAYS_RAISES	0x20
#define UIBF_SELECT_DISPLAYS_MENU	0x10
#define UIBF_KEYBOARD_ONLY		0x08
#define UIBF_CLICK_GOES_THRU		0x04
#define UIBF_SPECIFIC_UI_COMPATIBLE	0x02
#define UIBF_BLINKING_CURSOR		0x01







typedef	ByteEnum UChar;
#define UC_NULL			0x00
#define UC_QUICK_COPY		0x01
#define UC_BUTTON_EVENT		0x02
#define UC_CUT			0x03
#define UC_COPY			0x04
#define UC_PASTE		0x05
#define UC_DATE			0x06
#define UC_TIME			0x07
#define	UC_EXIT			0x08
#define	UC_ON			0x09
#define	UC_OFF			0x10
#define	UC_LOCK			0x11
#define	UC_JOTTER		0x12
#define	UC_MENU			0x13
#define UC_DELETE   	    	0x14
#define UC_ROTATE               0x15

typedef struct {
    optr    	    	BG_OD;
    word		BG_data;
} BasicGrab;

typedef struct {
    optr    	    	KG_OD;
    word		KG_unused;
} KbdGrab;

typedef struct {
    optr    	    	MG_OD;
    WindowHandle	MG_gWin;
} MouseGrab;

typedef struct {
    optr    	    		FTVMC_OD;
    MetaAlterFTVMCExclFlags	FTVMC_flags;
} FTVMCGrab;

extern word
    _pascal FlowCheckKbdShortcut(KeyboardShortcut *shortcutTable,
				 word numEntriesInTable,
				 word character,
				 word flags,
				 word state);

typedef WordFlags HierarchicalGrabFlags;
#define HGF_SYS_EXCL	0x4000
#define HGF_APP_EXCL	0x2000
#define HGF_GRAB	0x1000
#define HGF_OTHER_INFO	0x0fff

typedef struct {
    optr    	    	HG_OD;
    HierarchicalGrabFlags HG_flags;
} HierarchicalGrab;

extern Segment 
    _pascal FlowAlterHierarchicalGrab(optr objectOptr, 
			 Message gainedMessage,
			 word offsetToMasterInstance,
			 word offsetToHierarchicalGrab,
			 optr objectToBeGivenExclusive,
			 HierarchicalGrabFlags flags);

extern Segment 
    _pascal FlowUpdateHierarchicalGrab(optr objectOptr,
		   Message gainedMessage,
		   word offsetToMasterInstance,
		   word offsetToHierarchicalGrab,
		   Message updateMessage);

typedef struct {
    word ax_value;
    word bp_value;
    word cx_value;
    word dx_value;
} MessageReturnValues;

extern Boolean 
    _pascal FlowDispatchSendOnOrDestroyClassedEvent(
			MessageReturnValues *retvals,
			optr objectOptr,
			Message messageToSend,
			EventHandle classedEvent,
			word otherData,
			optr objectToSendTo,
			MessageFlags flags);


typedef ByteFlags HoldUpInputFlags;
#define HUIF_FLUSHING_QUEUE 0x80
#define HUIF_HOLD_UP_MODE_DISABLED 0x40


#ifdef __HIGHC__
pragma Alias (FlowCheckKbdShortcut, "FLOWCHECKKBDSHORTCUT");
pragma Alias (FlowAlterHierarchicalGrab, "FLOWALTERHIERARCHICALGRAB");
pragma Alias (FlowUpdateHierarchicalGrab, "FLOWUPDATEHIERARCHICALGRAB");
pragma Alias (FlowDispatchSendOnOrDestroyClassedEvent,
		"FLOWDISPATCHSENDONORDESTROYCLASSEDEVENT");
#endif



#endif

# 27 "/staff/pcgeos/CInclude/Objects/clipbrd.goh"





typedef WordFlags ClipboardQuickNotifyFlags;
#define CQNF_ERROR		0x8000
#define CQNF_SOURCE_EQUAL_DEST	0x4000
#define CQNF_MOVE		0x2000
#define CQNF_COPY		0x1000
#define CQNF_NO_OPERATION	0x0800
#define CQNF_UNUSED		0x04ff





#define CLIPBOARD_MAX_FORMATS	10

typedef dword ClipboardItemFormatID;

#define FormatIDFromManufacturerAndType(m,t) 	((((dword)(t)) << 16) | (m) )
#define ManufacturerFromFormatID(id) 		((word) (id))
#define TypeFromFormatID(id) 			((word) ((id) >> 16))

typedef dword TransferBlockID;

#define BlockIDFromFileAndBlock(f,b) 	(((dword)(f) << 16) | (b))
#define FileFromTransferBlockID(id) 	((VMFileHandle) ((id) >> 16))
#define BlockFromTransferBlockID(id) 	((VMBlockHandle) (id))

typedef WordFlags ClipboardItemFlags;
#define CIF_UNUSED1	0x8000
#define CIF_QUICK	0x4000
#define TIF_NORMAL	0x0000
#define CIF_UNUSED2	0x2fff

#if DBCS_GEOS
#define CLIPBOARD_ITEM_NAME_LENGTH	15
#else
#define CLIPBOARD_ITEM_NAME_LENGTH	32
#endif

typedef TCHAR ClipboardItemNameBuffer[CLIPBOARD_ITEM_NAME_LENGTH+1];

typedef struct {
    ClipboardItemFormatID	CIFI_format;
    word		CIFI_extra1;
    word		CIFI_extra2;
    VMChain		CIFI_vmChain;
    GeodeToken		CIFI_renderer;
} ClipboardItemFormatInfo;

typedef ClipboardItemFormatInfo	FormatArray[CLIPBOARD_MAX_FORMATS];

typedef struct {
    optr			CIH_owner;
    ClipboardItemFlags		CIH_flags;
    ClipboardItemNameBuffer	CIH_name;
#if DBCS_GEOS
    char			CIH_pad0DBCS;
#endif
    word			CIH_formatCount;
    optr			CIH_sourceID;
    FormatArray			CIH_formats;
    dword			CIH_reserved;
} ClipboardItemHeader;






extern Boolean
    _pascal ClipboardRegisterItem(TransferBlockID header, ClipboardItemFlags flags);

extern void	
    _pascal ClipboardUnregisterItem(optr owner);

typedef struct {
    word		CQA_numFormats;
    optr		CQA_owner;
    TransferBlockID	CQA_header;
} ClipboardQueryArgs;

extern void
    _pascal ClipboardQueryItem(word ClipboardItemFlags, ClipboardQueryArgs *retValues);

extern Boolean
    _pascal ClipboardTestItemFormat(TransferBlockID header, ClipboardItemFormatID format);

extern word _pascal	
    ClipboardEnumItemFormats(TransferBlockID header,
			     word maxNumFormats,
			     ClipboardItemFormatID *buffer);

extern dword		
    _pascal ClipboardGetItemInfo(TransferBlockID header);

typedef struct {
    VMFileHandle    	CRA_file;
    VMChain 		CRA_data;
    word		CRA_extra1;
    word		CRA_extra2;
} ClipboardRequestArgs;

extern void		
	_pascal ClipboardRequestItemFormat(ClipboardItemFormatID format,
					   TransferBlockID header,
					   ClipboardRequestArgs *retValue);
extern void		
    _pascal ClipboardDoneWithItem(TransferBlockID header);

extern TransferBlockID	
    _pascal ClipboardGetNormalItemInfo(void);

extern TransferBlockID	
    _pascal ClipboardGetQuickItemInfo(void);

extern TransferBlockID	
    _pascal ClipboardGetUndoItemInfo(void);

extern VMFileHandle	
    _pascal ClipboardGetClipboardFile(void);




extern word		
    _pascal ClipboardOpenClipboardFile(void);

extern void
    _pascal ClipboardCloseClipboardFile(void);

extern void		
    _pascal ClipboardAddToNotificationList(optr notificationOD);

extern Boolean		
    _pascal ClipboardRemoveFromNotificationList(optr notificationOD);

extern Boolean		
    _pascal ClipboardRemoteSend(void);
extern Boolean		
    _pascal ClipboardRemoteReceive(void);





typedef WordFlags ClipboardQuickTransferFlags;
#define CQTF_IN_PROGRESS	0x8000
#define CQTF_COPY_ONLY		0x4000
#define CQTF_USE_REGION		0x2000
#define CQTF_NOTIFICATION	0x1000

typedef struct {
    word	CQTRI_paramAX;
    word	CQTRI_paramBX;
    word	CQTRI_paramCX;
    word	CQTRI_paramDX;
    Point	CQTRI_regionPos;
    dword	CQTRI_strategy;
    dword	CQTRI_region;
} ClipboardQuickTransferRegionInfo;

typedef enum {
    CQTF_SET_DEFAULT,
    CQTF_CLEAR_DEFAULT,
    CQTF_MOVE,
    CQTF_COPY,
    CQTF_CLEAR
} ClipboardQuickTransferFeedback;






extern Boolean	
    _pascal ClipboardStartQuickTransfer(ClipboardQuickTransferFlags flags,
			   ClipboardQuickTransferFeedback initialCursor, 
			   word mouseXPos,
			   word mouseYPos, 
			   ClipboardQuickTransferRegionInfo *regionParams,
			   optr notificationOD);

extern Boolean 	
    _pascal ClipboardGetQuickTransferStatus(void);

extern void	
    _pascal ClipboardSetQuickTransferFeedback(
			ClipboardQuickTransferFeedback cursor, 
			UIFunctionsActive buttonFlags);

extern void	
    _pascal ClipboardEndQuickTransfer(ClipboardQuickNotifyFlags flags);

extern void	
    _pascal ClipboardAbortQuickTransfer(void);

extern void
    _pascal ClipboardClearQuickTransferNotification(optr notificationOD);

extern dword _pascal	
    ClipboardHandleEndMoveCopy(word activeGrab,
			       word uifa,
			       Boolean checkQTInProgress);



#define UIFAFromClipboardHandleEndMoveCopy(retValue) \
    ((word) ((retValue) >> 16))
#define MethodFromClipboardHandleEndMoveCopy(retValue) \
    ((word) (retValue))



#ifdef __HIGHC__
pragma Alias(ClipboardRegisterItem, "CLIPBOARDREGISTERITEM");
pragma Alias(ClipboardUnregisterItem, "CLIPBOARDUNREGISTERITEM");
pragma Alias(ClipboardQueryItem, "CLIPBOARDQUERYITEM");
pragma Alias(ClipboardTestItemFormat, "CLIPBOARDTESTITEMFORMAT");
pragma Alias(ClipboardEnumItemFormats, "CLIPBOARDENUMITEMFORMATS");
pragma Alias(ClipboardGetItemInfo, "CLIPBOARDGETITEMINFO");
pragma Alias(ClipboardRequestItemFormat, "CLIPBOARDREQUESTITEMFORMAT");
pragma Alias(ClipboardDoneWithItem, "CLIPBOARDDONEWITHITEM");
pragma Alias(ClipboardGetNormalItemInfo, "CLIPBOARDGETNORMALITEMINFO");
pragma Alias(ClipboardGetQuickItemInfo, "CLIPBOARDGETQUICKITEMINFO");
pragma Alias(ClipboardGetUndoItemInfo, "CLIPBOARDGETUNDOITEMINFO");
pragma Alias(ClipboardGetClipboardFile, "CLIPBOARDGETCLIPBOARDFILE");
pragma Alias(ClipboardOpenClipboardFile, "CLIPBOARDOPENCLIPBOARDFILE");
pragma Alias(ClipboardCloseClipboardFile, "CLIPBOARDCLOSECLIPBOARDFILE");
pragma Alias(ClipboardAddToNotificationList, "CLIPBOARDADDTONOTIFICATIONLIST");
pragma Alias(ClipboardRemoveFromNotificationList, "CLIPBOARDREMOVEFROMNOTIFICATIONLIST");
pragma Alias(ClipboardStartQuickTransfer, "CLIPBOARDSTARTQUICKTRANSFER");
pragma Alias(ClipboardGetQuickTransferStatus, "CLIPBOARDGETQUICKTRANSFERSTATUS");
pragma Alias(ClipboardSetQuickTransferFeedback, "CLIPBOARDSETQUICKTRANSFERFEEDBACK");
pragma Alias(ClipboardEndQuickTransfer, "CLIPBOARDENDQUICKTRANSFER");
pragma Alias(ClipboardAbortQuickTransfer, "CLIPBOARDABORTQUICKTRANSFER");
pragma Alias(ClipboardClearQuickTransferNotification, "CLIPBOARDCLEARQUICKTRANSFERNOTIFICATION");
pragma Alias(ClipboardHandleEndMoveCopy, "CLIPBOARDHANDLEENDMOVECOPY");
pragma Alias(ClipboardRemoteSend, "CLIPBOARDREMOTESEND");
pragma Alias(ClipboardRemoteReceive, "CLIPBOARDREMOTERECEIVE");
#endif



#endif

# 24 "/staff/pcgeos/CInclude/ui.goh"





#define UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION	 600
#define UI_MAXIMUM_THREAD_BORROW_STACK_SPACE_AMOUNT		1200
#define INTERFACE_THREAD_MINIMUM_STACK_SIZE			1500
#define INTERFACE_THREAD_DEF_STACK_SIZE				2000






typedef ByteFlags AppLaunchFlags;
#define ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE	0x80
#define ALF_OPEN_IN_BACK			0x40
#define ALF_DESK_ACCESSORY			0x20
#define ALF_DO_NOT_OPEN_ON_TOP			0x10
#define ALF_OVERRIDE_MULTIPLE_INSTANCE		0x08
#define ALF_LAUNCHED_FOR_PRINTING_ONLY		0x04

typedef Boolean _pascal GestureCallback (Point *arrayOfInkPoints, word numPoints, word numStrokes);

extern MemHandle _pascal
    UserCreateInkDestinationInfo(optr dest,
				 GStateHandle gs,
				 word brushSize,
				 GestureCallback *callback);

extern GeodeHandle _pascal
    UserGetHWRLibraryHandle(void);

extern void _pascal
    UserRegisterForTextContext(optr obj);
extern void _pascal
    UserUnregisterForTextContext(optr obj);

extern Boolean _pascal
    UserCheckIfContextUpdateDesired(void);

extern void _pascal
    UserGetInitFileCategory(char *buf);

extern GeodeHandle _pascal 
    UserLoadApplication(AppLaunchFlags alf,
			Message attachMethod,
			MemHandle appLaunchBlock,
			char *filename,
			StandardPath sPath,
			GeodeLoadError *err);

extern MemHandle _pascal
    UserAllocObjBlock (ThreadHandle threadHandle);





typedef enum  {
	UIIL_INTRODUCTORY,
	UIIL_BEGINNING,
	UIIL_INTERMEDIATE,
	UIIL_ADVANCED,
	UIIL_GURU
#define UIIL_MAX_LEVEL	UIIL_GURU
} UIInterfaceLevel;

extern UIInterfaceLevel
    _pascal UserGetDefaultLaunchLevel(void);	

extern UIInterfaceLevel
    _pascal UserGetDefaultUILevel(void);	

typedef WordFlags UIInterfaceOptions;
#define UIIO_OPTIONS_MENU			0x8000
#define UIIO_DISABLE_POPOUTS			0x4000
#define UIIO_ALLOW_INITIALLY_HIDDEN_MENU_BARS	0x2000

typedef enum {
    UILM_TRANSPARENT,
    UILM_SINGLE_INSTANCE,
    UILM_MULTIPLE_INSTANCES,
    UILM_GURU
} UILaunchModel;

extern UILaunchModel
    _pascal UserGetLaunchModel(void);		

typedef WordFlags UILaunchOptions;
#define UILO_DESK_ACCESSORIES		0x8000
#define UILO_CLOSABLE_APPS		0x4000

extern UILaunchOptions
    _pascal UserGetLaunchOptions(void);		

typedef enum {
    UIEP_NONE,
    UIEP_TOP_PRIMARY,
    UIEP_LOWER_LEFT
} UIExpressPositions;

typedef WordFlags UIExpressOptions;
#define UIEO_RETURN_TO_DEFAULT_LAUNCHER	0x0800
#define UIEO_GEOS_TASKS_LIST		0x0400
#define UIEO_DESK_ACCESSORY_LIST	0x0200
#define UIEO_MAIN_APPS_LIST		0x0100
#define UIEO_OTHER_APPS_LIST		0x0080
#define UIEO_CONTROL_PANEL		0x0040
#define UIEO_DOS_TASKS_LIST		0x0020
#define UIEO_UTILITIES_PANEL		0x0010
#define UIEO_EXIT_TO_DOS		0x0008
#define UIEO_POSITION			0x0007

typedef ByteFlags UIWindowOptions;
#define UIWO_MAXIMIZE_ON_STARTUP	0x40
#define UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS	0x20
#define UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS		0x10
#define UIWO_WINDOW_MENU				0x08
#define UIWO_PINNABLE_MENUS				0x04
#define UIWO_KBD_NAVIGATION				0x02
#define UIWO_POPOUT_MENU_BAR				0x01

typedef WordFlags UIWindowOptionsInteger;
#define UIWOI_MASK	0xff00
#define UIWOI_OPTIONS	0x00ff

typedef WordFlags UIHelpOptions;
#define UIHO_HIDE_HELP_BUTTONS	0x0001


extern UIInterfaceOptions
    _pascal UserGetInterfaceOptions(void);	






extern void _pascal UserAddAutoExec(const char *appName);
extern void _pascal UserRemoveAutoExec(const char *appName);




typedef enum  {
	SST_ERROR, 		    

	SST_WARNING,		    
	SST_NOTIFY,		    
	SST_NO_INPUT,		    




	SST_KEY_CLICK,		    

	SST_ALARM,		    

	SST_CUSTOM_SOUND=0xfffd,    



	SST_CUSTOM_BUFFER=0xfffe,   



		
















	SST_CUSTOM_NOTE=0xffff	    


} StandardSoundType;

#define SST_IGNORE_SOUND_OFF 0x8000



















typedef WordFlags StandardSoundFlags;
#define	SSF_ALARM       0x0020
#define	SSF_KEY_CLICK   0x0010
#define	SSF_NO_INPUT    0x0008
#define	SSF_NOTIFY      0x0004
#define	SSF_WARNING     0x0002
#define	SSF_ERROR       0x0001

#define SOUND_MASK_ALL  0xffff












extern word _cdecl UserStandardSound(StandardSoundType type, ...);












extern void _far _pascal UserStopStandardSound(StandardSoundType soundType,
					       word		 countID);






extern word _pascal UserDiskRestore(void *savedData, word *diskHandlePtr);






extern Boolean _pascal UserEncryptPassword(const char *string, char *dest);

#define PASSWORD_ENCRYPTED_SIZE 8
#define MAX_PASSWORD_SOURCE_SIZE 32












typedef enum  {
    TL_TARGET=			0,
    TL_CONTENT,
    TL_GENERIC_OBJECTS=  	1000,
    TL_GEN_SYSTEM,
    TL_GEN_FIELD,
    TL_GEN_APPLICATION,
    TL_GEN_PRIMARY,
    TL_GEN_DISPLAY_CTRL,
    TL_GEN_DISPLAY,
    TL_GEN_VIEW,
    TL_LIBRARY_LEVELS=  	2000,
    TL_APPLICATION_OBJECTS=  	3000,
} TargetLevel;



#define MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK 165	
#define MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_CONCLUDED 166	



#define MSG_META_CLIPBOARD_CUT 168
#define MSG_META_CLIPBOARD_COPY 169
#define MSG_META_CLIPBOARD_PASTE 170
#define MSG_META_UNDO 171

#define MSG_META_UNDO_FREEING_ACTION 172

#define MSG_META_SELECT_ALL 173
#define MSG_META_DELETE 174
#define MSG_META_CLIPBOARD_NOTIFY_TRANSFER_ITEM_FREED 175	
#define MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED 176	



#define MSG_META_CONTENT_SET_VIEW 177   


#define MSG_META_CONTENT_VIEW_OPENING 178 

#define MSG_META_CONTENT_VIEW_CLOSING 179   




#define MSG_META_CONTENT_VIEW_WIN_OPENED 180  

#define MSG_META_CONTENT_VIEW_WIN_CLOSED 181   

#define MSG_META_CONTENT_VIEW_ORIGIN_CHANGED 182  




#define MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED 183  



#define MSG_META_CONTENT_VIEW_SIZE_CHANGED 184   


#define MSG_META_CONTENT_TRACK_SCROLLING 185

#define MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL 186  



#define MSG_META_CONTENT_NAVIGATION_QUERY 187  
#define MSG_META_CONTENT_APPLY_DEFAULT_FOCUS 188  


#define MSG_META_CONTENT_ENTER 189 

#define MSG_META_CONTENT_LEAVE 190 






#define MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE 191


#define MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT 192


#define MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT 193


#define MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT 194


#define MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT 195


#define MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE 196


#define MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE 197


#define MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED 198




#define MSG_META_DOC_OUTPUT_PHYSICAL_SAVE 199




#define MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE 200




#define MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE 201




#define MSG_META_DOC_OUTPUT_PHYSICAL_REVERT 202




#define MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT 203




#define MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT 204


#define MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED 205


#define MSG_META_DOC_OUTPUT_ATTACH_FAILED 206





#define MSG_META_DOC_OUTPUT_PHYSICAL_REVERT_TO_AUTO_SAVE 207

#define MSG_META_UNUSED_META_UI_11 208
#define MSG_META_UNUSED_META_UI_12 209
#define MSG_META_UNUSED_META_UI_13 210
#define MSG_META_UNUSED_META_UI_14 211
#define MSG_META_UNUSED_META_UI_15 212
#define MSG_META_UNUSED_META_UI_16 213
#define MSG_META_UNUSED_META_UI_17 214
#define MSG_META_UNUSED_META_UI_18 215
#define MSG_META_UNUSED_META_UI_19 216
#define MSG_META_UNUSED_META_UI_20 217






#define MSG_META_UI_FORCE_CONTROLLER_UPDATE 218


typedef struct {
    word    	    	GPDRA_pathType;	    	
    word    	    	GPDRA_savedDiskType;	

    char    	    	*GPDRA_driveName;   	

    char    	    	*GPDRA_diskName;    	
    DiskRestoreError	GPDRA_errorCode;    	



} GenPathDiskRestoreArgs;



#define MSG_META_GEN_PATH_RESTORE_DISK_PROMPT 219	

#define MSG_META_PAGED_OBJECT_GOTO_PAGE 220
#define MSG_META_PAGED_OBJECT_NEXT_PAGE 221
#define MSG_META_PAGED_OBJECT_PREVIOUS_PAGE 222

#define MSG_META_NOTIFY_TASK_SELECTED 223




#define MSG_META_GAINED_MOUSE_EXCL 224   
#define MSG_META_LOST_MOUSE_EXCL 225   
#define MSG_META_GAINED_KBD_EXCL 226   
#define MSG_META_LOST_KBD_EXCL 227   
#define MSG_META_GAINED_PRESSURE_EXCL 228   
#define MSG_META_LOST_PRESSURE_EXCL 229   
#define MSG_META_GAINED_DIRECTION_EXCL 230   
#define MSG_META_LOST_DIRECTION_EXCL 231   



#define MSG_META_GRAB_FOCUS_EXCL 232   
#define MSG_META_RELEASE_FOCUS_EXCL 233   

#define MSG_META_GET_FOCUS_EXCL 234   
#define MSG_META_GRAB_TARGET_EXCL 235   
#define MSG_META_RELEASE_TARGET_EXCL 236   

#define MSG_META_GET_TARGET_EXCL 237   
#define MSG_META_GRAB_MODEL_EXCL 238   
#define MSG_META_RELEASE_MODEL_EXCL 239   

#define MSG_META_GET_MODEL_EXCL 240   
#define MSG_META_RELEASE_FT_EXCL 241   



#define MSG_META_MUP_ALTER_FTVMC_EXCL 242  

#define MSG_META_GAINED_FOCUS_EXCL 243   
#define MSG_META_LOST_FOCUS_EXCL 244   
#define MSG_META_GAINED_SYS_FOCUS_EXCL 245   
#define MSG_META_LOST_SYS_FOCUS_EXCL 246   
#define MSG_META_GAINED_TARGET_EXCL 247
#define MSG_META_LOST_TARGET_EXCL 248
#define MSG_META_GAINED_SYS_TARGET_EXCL 249
#define MSG_META_LOST_SYS_TARGET_EXCL 250
#define MSG_META_GAINED_MODEL_EXCL 251   
#define MSG_META_LOST_MODEL_EXCL 252   
#define MSG_META_GAINED_SYS_MODEL_EXCL 253   
#define MSG_META_LOST_SYS_MODEL_EXCL 254   
#define MSG_META_QUERY_SAVE_DOCUMENTS 255
#define MSG_META_BROADCAST_RETURNING_TO_WELCOME 256

#define MSG_META_GAINED_DEFAULT_EXCL 257   
#define MSG_META_LOST_DEFAULT_EXCL 258   

#define MSG_META_MOUSE_BUMP_NOTIFICATION 259   



#define MSG_META_FUP_KBD_CHAR 260   

typedef WordFlags KbdReturnFlags;
#define KRF_PREVENT_PASS_THROUGH	0x8000




#define MSG_META_PRE_PASSIVE_KBD_CHAR 261   



#define MSG_META_POST_PASSIVE_KBD_CHAR 262   






#define MSG_META_QUERY_IF_PRESS_IS_INK 263



#define MSG_META_LARGE_QUERY_IF_PRESS_IS_INK 264















   
#define MSG_META_START_SELECT 265
#define MSG_META_END_SELECT 266
#define MSG_META_START_MOVE_COPY 267
#define MSG_META_END_MOVE_COPY 268
#define MSG_META_START_FEATURES 269
#define MSG_META_END_FEATURES 270
#define MSG_META_START_OTHER 271
#define MSG_META_END_OTHER 272
#define MSG_META_DRAG_SELECT 273
#define MSG_META_DRAG_MOVE_COPY 274
#define MSG_META_DRAG_FEATURES 275
#define MSG_META_DRAG_OTHER 276
#define MSG_META_PRE_PASSIVE_BUTTON 277
#define MSG_META_POST_PASSIVE_BUTTON 278
#define MSG_META_PRE_PASSIVE_START_SELECT 279
#define MSG_META_PRE_PASSIVE_END_SELECT 280
#define MSG_META_PRE_PASSIVE_START_MOVE_COPY 281
#define MSG_META_PRE_PASSIVE_END_MOVE_COPY 282
#define MSG_META_PRE_PASSIVE_START_FEATURES 283
#define MSG_META_PRE_PASSIVE_END_FEATURES 284
#define MSG_META_PRE_PASSIVE_START_OTHER 285
#define MSG_META_PRE_PASSIVE_END_OTHER 286
#define MSG_META_POST_PASSIVE_START_SELECT 287
#define MSG_META_POST_PASSIVE_END_SELECT 288
#define MSG_META_POST_PASSIVE_START_MOVE_COPY 289
#define MSG_META_POST_PASSIVE_END_MOVE_COPY 290
#define MSG_META_POST_PASSIVE_START_FEATURES 291
#define MSG_META_POST_PASSIVE_END_FEATURES 292
#define MSG_META_POST_PASSIVE_START_OTHER 293
#define MSG_META_POST_PASSIVE_END_OTHER 294








#define MSG_META_LARGE_PTR 295
#define MSG_META_LARGE_START_SELECT 296
#define MSG_META_LARGE_END_SELECT 297
#define MSG_META_LARGE_START_MOVE_COPY 298
#define MSG_META_LARGE_END_MOVE_COPY 299
#define MSG_META_LARGE_START_FEATURES 300
#define MSG_META_LARGE_END_FEATURES 301
#define MSG_META_LARGE_START_OTHER 302
#define MSG_META_LARGE_END_OTHER 303
#define MSG_META_LARGE_DRAG_SELECT 304
#define MSG_META_LARGE_DRAG_MOVE_COPY 305
#define MSG_META_LARGE_DRAG_FEATURES 306
#define MSG_META_LARGE_DRAG_OTHER 307


#define MSG_META_ENSURE_MOUSE_NOT_ACTIVELY_TRESPASSING 308   


typedef struct {
    word		ENMISUMP_menuCount;	
} EnsureNoMenusInStayUpModeParams;

#define MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE 309   

#define MSG_META_ENSURE_ACTIVE_FT 310   
#define MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE 311   

#define MSG_META_DOC_OUTPUT_IMPORT_FILE 312	
#define MSG_META_DOC_OUTPUT_EXPORT_FILE 313	
#define MSG_META_GRAB_KBD 314	
#define MSG_META_FORCE_GRAB_KBD 315	
#define MSG_META_RELEASE_KBD 316	
#define MSG_META_VIEW_COMMAND_CHANGE_SCALE 317 

#define MSG_META_FIELD_NOTIFY_DETACH 318
#define MSG_META_FIELD_NOTIFY_NO_FOCUS 319
#define MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR 320

#define MSG_META_DELETE_RANGE_OF_CHARS 321
#define MSG_META_TEST_WIN_INTERACTIBILITY 322 
#define MSG_META_CHECK_IF_INTERACTABLE_OBJECT 323 
#define MSG_META_GAINED_FULL_SCREEN_EXCL 324 
#define MSG_META_LOST_FULL_SCREEN_EXCL 325 

#if defined(__HIGHC__)
pragma Alias(UserStandardSound, "_UserStandardSound");
pragma Alias(UserStopStandardSound, "USERSTOPSTANDARDSOUND");
pragma Alias(UserAddAutoExec, "USERADDAUTOEXEC");
pragma Alias(UserRemoveAutoExec, "USERREMOVEAUTOEXEC");
pragma Alias(UserGetHWRLibraryHandle, "USERGETHWRLIBRARYHANDLE");
pragma Alias(UserRegisterForTextContext, "USERREGISTERFORTEXTCONTEXT");
pragma Alias(UserUnregisterForTextContext, "USERUNREGISTERFORTEXTCONTEXT");
pragma Alias(UserCheckIfContextUpdateDesired,"USERCHECKIFCONTEXTUPDATEDESIRED");
pragma Alias(UserGetDefaultUILevel, "USERGETDEFAULTUILEVEL");
pragma Alias(UserGetDefaultLaunchLevel, "USERGETDEFAULTLAUNCHLEVEL");
pragma Alias(UserGetInterfaceOptions, "USERGETINTERFACEOPTIONS");
pragma Alias(UserGetLaunchModel, "USERGETLAUNCHMODEL");
pragma Alias(UserGetLaunchOptions, "USERGETLAUNCHOPTIONS");
pragma Alias(UserCreateInkDestinationInfo, "USERCREATEINKDESTINATIONINFO");
pragma Alias(UserGetInitFileCategory, "USERGETINITFILECATEGORY");
pragma Alias(UserLoadApplication, "USERLOADAPPLICATION");
pragma Alias(UserAllocObjBlock, "USERALLOCOBJBLOCK");
pragma Alias(UserEncryptPassword, "USERENCRYPTPASSWORD");
#endif


#endif

# 38 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCiacp
#define __GOCiacp

# 1 "/staff/pcgeos/CInclude/iacp.goh"

































 
typedef word IACPConnection;

#define IACP_NO_CONNECTION 	0	







typedef ByteEnum IACPServerMode;
#define IACPSM_NOT_USER_INTERACTIBLE	0
#define IACPSM_IN_FLUX	    	    	1
#define IACPSM_USER_INTERACTIBLE    	2

typedef ByteFlags IACPServerFlags;
#define    IACPSF_MULTIPLE_INSTANCES 	0x80
    
#define	   IACPSF_MAILBOX_DONT_NOTIFY_USER 0x40
    


typedef WordFlags IACPConnectFlags;	
#define IACPCF_OBEY_LAUNCH_MODEL	0x0020
    




#define IACPCF_CLIENT_OD_SPECIFIED	0x0010
    



#define IACPCF_FIRST_ONLY		0x0008
    


#define IACPCF_SERVER_MODE  	    	0x0007
    



#define IACPCF_SERVER_MODE_OFFSET	0

typedef enum {				


    IACPS_CLIENT,
    IACPS_SERVER
} IACPSide;






 
typedef enum {
    IACPCE_CANNOT_FIND_SERVER=GLE_LAST_GEODE_LOAD_ERROR,
    


    IACPCE_NO_SERVER
    

} IACPConnectError;










#define MSG_META_IACP_PROCESS_MESSAGE 981































#define MSG_META_IACP_NEW_CONNECTION 982
























#define MSG_META_IACP_LOST_CONNECTION 983
						  
























#define MSG_META_IACP_SHUTDOWN_CONNECTION 984
















typedef struct {
    optr    	    IDOAP_docObj;	

    IACPConnection  IDOAP_connection;	

    word    	    IDOAP_serverNum;	



} IACPDocOpenAckParams;


#define MSG_META_IACP_DOC_OPEN_ACK 985


























typedef struct {
    optr	    IDCAP_docObj;	

    IACPConnection  IDCAP_connection;	

    word    	    IDCAP_serverNum;	



    word    	    IDCAP_status;   	

} IACPDocCloseAckParams;


#define MSG_META_IACP_DOC_CLOSE_ACK 986






























#define MSG_META_IACP_ALLOW_FILE_ACCESS 987


























#define MSG_META_IACP_NOTIFY_FILE_ACCESS_FINISHED 988




























#define MSG_META_IACP_DATA_EXCHANGE 989













extern void
    _pascal IACPRegisterServer(GeodeToken *list, optr server,
			       IACPServerMode mode,
			       IACPServerFlags flags);

extern void
    _pascal IACPUnregisterServer(GeodeToken *list, optr server);

extern void
    _pascal IACPRegisterDocument(optr server, word disk, dword fileID);

extern void
    _pascal IACPUnregisterDocument(optr server, word disk, dword fileID);

extern IACPConnection
    _pascal IACPConnect(GeodeToken *list,
		IACPConnectFlags flags,
		MemHandle appLaunchBlock,
		optr client,
		word *numServersPtr);

extern IACPConnection
    _pascal IACPConnectToDocumentServer(const char _far *pathname,
					const char _far *filename,
					DiskHandle disk,
					IACPConnectFlags flags,
					optr client);


extern void
    _pascal IACPFinishConnect(IACPConnection connection, optr server);

extern word
    _pascal IACPSendMessage(IACPConnection connection,
		    EventHandle msgToSend,
		    TravelOption topt,	
		    EventHandle completionMsg,
		    IACPSide side);

extern word
    _pascal IACPSendMessageAndWait(IACPConnection connection,
		    EventHandle msgToSend,
		    TravelOption topt,	
		    IACPSide side);

extern word
    _pascal IACPSendMessageToServer(IACPConnection connection,
		    EventHandle msgToSend,
		    TravelOption topt,
		    EventHandle completionMsg,
		    word serverNum);
extern void
    _pascal IACPShutdown(IACPConnection connection, optr server);

extern void
    _pascal IACPShutdownAll(optr obj);

extern dword
    _pascal IACPGetDocumentID(const char _far *pathname,
			      const char _far *filename,
			      DiskHandle *disk);










extern void
    _pascal IACPProcessMessage(optr oself,
			       EventHandle msgToSend,
			       TravelOption topt,
			       EventHandle completionMsg);

extern void
    _pascal IACPLostConnection(optr oself, IACPConnection connection);

extern MemHandle
    _pascal IACPCreateDefaultLaunchBlock(word appMode);

extern word
    _pascal IACPGetServerNumber(IACPConnection connection, optr server);

extern MemHandle
    _pascal IACPLocateServer(const GeodeToken *token);

extern void
    _pascal IACPBindToken(const GeodeToken *token, const char *appPath);

extern void
    _pascal IACPUnbindToken(const GeodeToken *token);

#ifdef __HIGHC__

pragma Alias(IACPRegisterServer,           "IACPREGISTERSERVER");
pragma Alias(IACPUnregisterServer,         "IACPUNREGISTERSERVER");
pragma Alias(IACPConnect,                  "IACPCONNECT");
pragma Alias(IACPConnectToDocumentServer,  "IACPCONNECTTODOCUMENTSERVER");
pragma Alias(IACPSendMessage,              "IACPSENDMESSAGE");
pragma Alias(IACPSendMessageToServer,	   "IACPSENDMESSAGETOSERVER");
pragma Alias(IACPSendMessageAndWait,       "IACPSENDMESSAGEANDWAIT");
pragma Alias(IACPShutdown,                 "IACPSHUTDOWN");
pragma Alias(IACPShutdownAll,              "IACPSHUTDOWNALL");
pragma Alias(IACPGetDocumentID,            "IACPGETDOCUMENTID");



pragma Alias(IACPProcessMessage,           "IACPPROCESSMESSAGE");
pragma Alias(IACPLostConnection,           "IACPLOSTCONNECTION");
pragma Alias(IACPCreateDefaultLaunchBlock, "IACPCREATEDEFAULTLAUNCHBLOCK");
pragma Alias(IACPGetServerNumber,	   "IACPGETSERVERNUMBER");
pragma Alias(IACPRegisterDocument,  	   "IACPREGISTERDOCUMENT");
pragma Alias(IACPUnregisterDocument,  	   "IACPUNREGISTERDOCUMENT");
pragma Alias(IACPFinishConnect,		   "IACPFINISHCONNECT");
pragma Alias(IACPLocateServer,		   "IACPLOCATESERVER");
pragma Alias(IACPBindToken,		   "IACPBINDTOKEN");
pragma Alias(IACPUnbindToken,		   "IACPUNBINDTOKEN");
#endif




#endif

# 39 "/staff/pcgeos/CInclude/stdapp.goh"
#include <uDialog.h>

#ifndef __GOCwinC
#define __GOCwinC

# 1 "/staff/pcgeos/CInclude/Objects/winC.goh"




















#ifndef __GOCmetaC
#define __GOCmetaC
#include "/staff/pcgeos/CInclude/Objects/metaC.poh"
#endif

# 21 "/staff/pcgeos/CInclude/Objects/winC.goh"

#define MSG_META_EXPOSED 69


#define MSG_META_EXPOSED_FOR_PRINT 70

#define MSG_META_WIN_UPDATE_COMPLETE 71	

#define MSG_META_WIN_UNUSED_2 72

#define MSG_META_WIN_CHANGE 73	

#define MSG_META_IMPLIED_WIN_CHANGE 74	

#define MSG_META_RAW_UNIV_ENTER 75	

#define MSG_META_RAW_UNIV_LEAVE 76	

#define MSG_META_UNUSED_1 77

#define MSG_META_INVAL_TREE 78	

#define MSG_META_INVAL_BOUNDS 79		



#endif

# 41 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCinputC
#define __GOCinputC
#include "/staff/pcgeos/CInclude/Objects/inputC.poh"
#endif

# 42 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCuiInputC
#define __GOCuiInputC
#include "/staff/pcgeos/CInclude/Objects/uiInputC.poh"
#endif

# 43 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgProcC
#define __GOCgProcC

# 1 "/staff/pcgeos/CInclude/Objects/gProcC.goh"





















#include <file.h>
#include <vm.h>

#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/gProcC.goh"

#ifndef __GOCalb
#define __GOCalb

# 1 "/staff/pcgeos/CInclude/alb.goh"


















typedef struct {
    PathName		AIR_fileName;
    FileLongName	AIR_stateFile;
    DiskHandle		AIR_diskHandle;
    byte		AIR_savedDiskData[1];
} AppInstanceReference;

typedef struct {
    AppInstanceReference	ALB_appRef;
    word			ALB_appMode;
    AppLaunchFlags		ALB_launchFlags;
    MemHandle			ALB_diskHandle;
    TCHAR			ALB_path[PATH_BUFFER_SIZE];
    FileLongName		ALB_dataFile;
    optr			ALB_genParent;
    optr			ALB_userLoadAckOutput;
    Message			ALB_userLoadAckMessage;
    word			ALB_userLoadAckID;
    word			ALB_extraData;
} AppLaunchBlock;

#endif

# 26 "/staff/pcgeos/CInclude/Objects/gProcC.goh"

#ifndef __GOCprocessC
#define __GOCprocessC

# 1 "/staff/pcgeos/CInclude/Objects/processC.goh"




















#ifndef __GOCmetaC
#define __GOCmetaC
#include "/staff/pcgeos/CInclude/Objects/metaC.poh"
#endif

# 21 "/staff/pcgeos/CInclude/Objects/processC.goh"


#define _FIRST_ProcessClass 8192
# 22 "/staff/pcgeos/CInclude/Objects/processC.goh"
























	
		

	

	
	
    #define MSG_PROCESS_COPY_CHUNK_IN_FROM_OPTR MSG_PROCESS_COPY_CHUNK_IN
    #define MSG_PROCESS_COPY_CHUNK_IN_FROM_FPTR MSG_PROCESS_COPY_CHUNK_IN
    #define MSG_PROCESS_COPY_CHUNK_IN_FROM_HPTR MSG_PROCESS_COPY_CHUNK_IN



#define COPY_CHUNK_DWORD_TO_CHUNK(dw) 	((ChunkHandle) ((dw) & 0xffff))
#define COPY_CHUNK_DWORD_TO_SIZE(dw) 	((word) ((dw) >> 16))

	
	
    #define MSG_PROCESS_COPY_CHUNK_OVER_OPTR MSG_PROCESS_COPY_CHUNK_OVER
    #define MSG_PROCESS_COPY_CHUNK_OVER_FPTR MSG_PROCESS_COPY_CHUNK_OVER
    #define MSG_PROCESS_COPY_CHUNK_OVER_HPTR MSG_PROCESS_COPY_CHUNK_OVER

	
	
    #define MSG_PROCESS_COPY_CHUNK_OUT_TO_OPTR MSG_PROCESS_COPY_CHUNK_OUT
    #define MSG_PROCESS_COPY_CHUNK_OUT_TO_FPTR MSG_PROCESS_COPY_CHUNK_OUT
    #define MSG_PROCESS_COPY_CHUNK_OUT_TO_HPTR MSG_PROCESS_COPY_CHUNK_OUT

 

	


















    




	



extern ClassStruct _far ProcessClass; extern Message _Messages_ProcessClass[]; extern MessageMethod *_Methods_ProcessClass[]; extern CMethodDef _htypes_ProcessClass[];extern MessageMethod *_Reloc_ProcessClass;typedef enum{MSG_PROCESS_NOTIFY_PROCESS_EXIT=8192,MSG_PROCESS_NOTIFY_THREAD_EXIT,MSG_PROCESS_MEM_FULL,MSG_PROCESS_CREATE_UI_THREAD,MSG_PROCESS_CREATE_EVENT_THREAD,MSG_PROCESS_INSTANTIATE,MSG_PROCESS_EXIT,MSG_PROCESS_STARTUP_UI_THREAD,MSG_PROCESS_COPY_CHUNK_IN,MSG_PROCESS_COPY_CHUNK_OVER,MSG_PROCESS_COPY_CHUNK_OUT,MSG_PROCESS_FLUSH_PROCESS_QUEUE,MSG_PROCESS_FINAL_BLOCK_FREE,MSG_PROCESS_CALL_ROUTINE,MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER,MSG_PROCESS_OBJ_BLOCK_DISCARD,MSG_PROCESS_INSTANTIATE_FOR_THREAD,}ProcessMessages;





typedef ByteEnum CopyChunkMode;
#define CCM_OPTR 0
#define CCM_HPTR 1
#define CCM_FPTR 2
#define CCM_STRING 3

typedef WordFlags CopyChunkFlags;
#define CCF_DIRTY	0x8000
#define CCF_MODE	0x6000
#define CCF_SIZE	0x1fff
#define CCF_MODE_OFFSET	13



#endif

# 27 "/staff/pcgeos/CInclude/Objects/gProcC.goh"


#define _FIRST_GenProcessClass 8704
# 28 "/staff/pcgeos/CInclude/Objects/gProcC.goh"





	

typedef WordFlags AppAttachFlags;
#define AAF_RESTORING_FROM_STATE	0x8000
#define AAF_STATE_FILE_PASSED		0x4000
#define AAF_DATA_FILE_PASSED		0x2000
#define AAF_RESTORING_FROM_QUIT		0x1000












	
	


 

 
	

	











	
	









typedef enum  {
	UADT_FLAGS=0, 
	UADT_PTR=2,
	UADT_VM_CHAIN=4
} UndoActionDataType;

typedef struct {
    dword   UADF_flags;
    word    UADF_extraflags;
} UndoActionDataFlags;

typedef struct {
    void    *UADP_ptr;
    word    UADP_size;
} UndoActionDataPtr;

typedef struct {
    VMChain UADVMC_vmChain;
    VMFileHandle UADVMC_file;
} UndoActionDataVMChain;

typedef union {
    UndoActionDataFlags	    UADU_flags;
    UndoActionDataPtr	    UADU_ptr;
    UndoActionDataVMChain   UADU_vmChain;
} UndoActionDataUnion;
#define NULL_UNDO_CONTEXT   0

typedef WordFlags AddUndoActionFlags;
#define AUAF_NOTIFY_BEFORE_FREEING 0x8000
#define AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK 0x4000

typedef struct {
    UndoActionDataType	UAS_dataType;
    UndoActionDataUnion	UAS_data;
    dword   	    	UAS_appType;
} UndoActionStruct;

typedef struct {
    UndoActionStruct	AUAS_data;
    optr    	    	AUAS_output;
    AddUndoActionFlags	AUAS_flags;
} AddUndoActionStruct;

extern VMFileHandle _pascal GenProcessUndoGetFile(void);
extern Boolean _pascal GenProcessUndoCheckIfIgnoring(void);
#ifdef __HIGHC__
pragma Alias(GenProcessUndoGetFile, "GENPROCESSUNDOGETFILE");
pragma Alias(GenProcessUndoCheckIfIgnoring, "GENPROCESSUNDOCHECKIFIGNORING");
#endif




















#define	AIRDN_DRIVE	0x80

extern ClassStruct _far GenProcessClass; extern Message _Messages_GenProcessClass[]; extern MessageMethod *_Methods_GenProcessClass[]; extern CMethodDef _htypes_GenProcessClass[];extern MessageMethod *_Reloc_GenProcessClass;typedef enum{MSG_GEN_PROCESS_RESTORE_FROM_STATE=8704,MSG_GEN_PROCESS_OPEN_APPLICATION,MSG_GEN_PROCESS_OPEN_ENGINE,MSG_GEN_PROCESS_CLOSE_APPLICATION,MSG_GEN_PROCESS_CLOSE_ENGINE,MSG_GEN_PROCESS_CLOSE_CUSTOM,MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE,MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE,MSG_GEN_PROCESS_INSTALL_TOKEN,MSG_GEN_PROCESS_GET_PARENT_FIELD=8714,MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST,MSG_GEN_PROCESS_REAL_DETACH,MSG_GEN_PROCESS_FINAL_DETACH,MSG_GEN_PROCESS_UNDO_START_CHAIN,MSG_GEN_PROCESS_UNDO_END_CHAIN,MSG_GEN_PROCESS_UNDO_ADD_ACTION,MSG_GEN_PROCESS_UNDO_GET_FILE,MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS,MSG_GEN_PROCESS_UNDO_SET_CONTEXT,MSG_GEN_PROCESS_UNDO_GET_CONTEXT,MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN,MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS,MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS,MSG_GEN_PROCESS_UNDO_CHECK_IF_IGNORING,MSG_GEN_PROCESS_UNDO_ABORT_CHAIN,MSG_GEN_PROCESS_TRANSITION_FROM_ENGINE_TO_APPLICATION_MODE,}GenProcessMessages;



#endif

# 44 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCvisC
#define __GOCvisC

# 1 "/staff/pcgeos/CInclude/Objects/visC.goh"





















#include <graphics.h>
#include <win.h>

#ifndef __GOCobject
#define __GOCobject
#include "/staff/pcgeos/CInclude/object.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/visC.goh"

#ifndef __GOCmetaC
#define __GOCmetaC
#include "/staff/pcgeos/CInclude/Objects/metaC.poh"
#endif

# 26 "/staff/pcgeos/CInclude/Objects/visC.goh"

#ifndef __GOCuiInputC
#define __GOCuiInputC
#include "/staff/pcgeos/CInclude/Objects/uiInputC.poh"
#endif

# 27 "/staff/pcgeos/CInclude/Objects/visC.goh"

extern void _pascal
    	VisObjectHandlesInkReply();

typedef struct {MetaBase Vis_metaBase; word Vis_offset; } VisBase;
#define _FIRST_VisClass 16384
# 31 "/staff/pcgeos/CInclude/Objects/visC.goh"






#define ObjDerefVis(obj) ObjDeref1(obj)




typedef ByteFlags DrawFlags;
#define DF_EXPOSED		0x80
#define DF_OBJECT_SPECIFIC	0x40
#define DF_PRINT		0x20
#define DF_DONT_DRAW_CHILDREN	0x10
#define DF_DISPLAY_TYPE		0x0f




 

  

	



	

typedef ByteFlags ColorScheme;
#define CS_lightColor		0xf0
#define CS_darkColor		0x0f
#define CS_lightColor_OFFSET	4

typedef struct {
	byte DS_colorScheme;
	byte DS_displayType;
	word DS_unused;
	FontID DS_fontID;
	sword DS_pointSize;
} DisplayScheme;


  


typedef enum {
    TO_VIS_PARENT=_FIRST_VisClass
} VisTravelOption;




typedef ByteEnum VisUpdateMode;
#define VUM_MANUAL 0
#define VUM_NOW 1
#define VUM_DELAYED_VIA_UI_QUEUE 2
#define VUM_DELAYED_VIA_APP_QUEUE 3

typedef ByteFlags VisAttrs;
#define VA_VISIBLE			0x80
#define VA_FULLY_ENABLED		0x40
#define VA_MANAGED			0x20
#define VA_DRAWABLE			0x10
#define VA_DETECTABLE			0x08
#define VA_BRANCH_NOT_MINIMIZABLE	0x04
#define VA_OLD_BOUNDS_SAVED		0x02
#define VA_REALIZED			0x01

typedef ByteFlags VisOptFlags;
#define VOF_GEOMETRY_INVALID	0x80
#define VOF_GEO_UPDATE_PATH	0x40
#define VOF_IMAGE_INVALID	0x20
#define VOF_IMAGE_UPDATE_PATH	0x10
#define VOF_WINDOW_INVALID	0x08
#define VOF_WINDOW_UPDATE_PATH	0x04
#define VOF_UPDATE_PENDING	0x02
#define VOF_EC_UPDATING		0x01

typedef ByteFlags VisGeoAttrs;
#define VGA_GEOMETRY_CALCULATED			0x80
#define VGA_NO_SIZE_HINTS			0x40
#define VGA_NOTIFY_GEOMETRY_VALID		0x20
#define VGA_DONT_CENTER				0x10
#define VGA_USE_VIS_SET_POSITION		0x08
#define VGA_USE_VIS_CENTER			0x04
#define VGA_ONLY_RECALC_SIZE_WHEN_INVALID	0x02
#define VGA_ALWAYS_RECALC_SIZE			0x01

typedef ByteFlags VisTypeFlags;
#define VTF_IS_COMPOSITE	0x80
#define VTF_IS_WINDOW		0x40
#define VTF_IS_PORTAL		0x20
#define VTF_IS_WIN_GROUP	0x10
#define VTF_IS_CONTENT		0x08
#define VTF_IS_INPUT_NODE	0x04
#define VTF_IS_GEN		0x02
#define VTF_CHILDREN_OUTSIDE_PORTAL_WIN	0x01

typedef ByteFlags SpecAttrs;
#define SA_ATTACHED			0x80
#define SA_REALIZABLE			0x40
#define SA_BRANCH_MINIMIZED		0x20
#define SA_USES_DUAL_BUILD		0x10
#define SA_CUSTOM_VIS_PARENT		0x08
#define SA_SIMPLE_GEN_OBJ		0x04
#define SA_CUSTOM_VIS_PARENT_FOR_CHILD	0x02
#define SA_TREE_BUILT_BUT_NOT_REALIZED	0x01

  

 


  

  

  





	



	



	 


	

	

	




  

	

	


	

	

typedef struct {
	word	GCP_aboveCenter;
	word	GCP_belowCenter;
	word	GCP_leftOfCenter;
	word	GCP_rightOfCenter;
} GetCenterParams;

	








	

	


   


	






  


  





	
		

	

	

	

typedef ByteFlags VisUpdateImageFlags;
#define	VUIF_ALREADY_INVALIDATED  0x80
#define VUIF_SEND_TO_ALL_CHILDREN 0x40
#define VUIF_JUST_OPENED          0x20    



#define VUIF_ALREADY_INVALID VUIF_ALREADY_INVALIDATED
#define VUIF_ALWAYS_INVALIDATE VUIF_SEND_TO_ALL_CHILDREN


 

	



   

typedef ByteFlags VisAddRectFlags;
#define VARF_NOT_IF_ALREADY_INVALID	0x80
#define VARF_ONLY_REDRAW_MARGINS	0x40

	




	
	
	
	

  
	
	
 
	






	


  
	
 
	
	

   
   
   



 
 
 
 
 

  
  
  
  




	
	
	


typedef struct	{
	HierarchicalGrabFlags	OAGP_grabFlags;
	word			OAGP_unused;
	optr			OAGP_object;
} ObjectAndGrabParams;


 


 


typedef ByteFlags VisInputFlowGrabFlags;
#define		VIFGF_NOT_HERE	0x80
#define		VIFGF_FORCE	0x20
#define		VIFGF_GRAB	0x10
#define		VIFGF_KBD	0x08
#define 	VIFGF_MOUSE	0x04
#define		VIFGF_LARGE	0x02
#define		VIFGF_PTR	0x01

typedef ByteEnum VisInputFlowGrabType;
#define VIFGT_ACTIVE 0
#define VIFGT_PRE_PASSIVE 1
#define VIGFT_POST_PASSIVE 2











	

  

  



	

 



typedef ByteFlags DrawMonikerFlags;
#define DMF_TEXT_ONLY			0x80
#define	DMF_UNDERLINE_ACCELERATOR	0x40
#define DMF_CLIP_TO_MAX_WIDTH		0x20
#define DMF_NONE			0x10
#define	DMF_Y_JUST_MASK			0x0c	
#define DMF_X_JUST_MASK			0x03    

#define DMF_Y_JUST_OFFSET		2
#define DMF_X_JUST_OFFSET		0

typedef WordFlags VisMonikerSearchFlags;
#define VMSF_STYLE		0xf000
#define VMSF_COPY_CHUNK		0x0400
#define VMSF_REPLACE_LIST	0x0200
#define VMSF_GSTRING		0x0100

#define VMSF_STYLE_OFFSET	12




























  










 

 

 








typedef WordFlags SpecSizeSpec;
#define SSS_TYPE	0x8c00
#define	SSS_DATA	0x03ff

typedef WordFlags SpecWidth;
#define SW_TYPE		0x8c00
#define	SW_DATA		0x03ff

typedef WordFlags SpecHeight;
#define SH_TYPE		0x8c00
#define	SH_DATA		0x03ff

#define SSS_TYPE_OFFSET	10
#define SSS_DATA_OFFSET	0

typedef ByteEnum SpecSizeType;
#define SST_PIXELS				  0x0000
#define SST_COUNT				  0x0400
#define SST_PCT_OF_FIELD_WIDTH	  0x0800
#define SST_PCT_OF_FIELD_HEIGHT	  0x0c00
#define SST_AVG_CHAR_WIDTHS	  0x1000
#define SST_WIDE_CHAR_WIDTHS	  0x1400
#define SST_LINES_OF_TEXT		  0x1800


#define PCT_0	0x000
#define PCT_5	0x033
#define PCT_10	0x066
#define PCT_15	0x099
#define PCT_20	0x0cc
#define PCT_25	0x100
#define PCT_30	0x133
#define PCT_35	0x166
#define PCT_40	0x199
#define PCT_45	0x1cc
#define PCT_50	0x200
#define PCT_55	0x233
#define PCT_60	0x266
#define PCT_65	0x299
#define PCT_70	0x2cc
#define PCT_75	0x300
#define PCT_80	0x333
#define PCT_85	0x366
#define PCT_90	0x399
#define PCT_95	0x3cc
#define PCT_100	0x3ff

typedef WordFlags SpecWinSizeSpec;
#define SWSS_RATIO	0x8000
#define SWSS_SIGN	0x4000
#define SWSS_MANTISSA	0x3c00
#define SWSS_FRACTION	0x03ff

typedef WordFlags RecalcSizeArgs;
#define RSA_CHOOSE_OWN_SIZE 	0x8000
#define RSA_SUGGESTED_SIZE	0x7fff

typedef struct {
    SpecWinSizeSpec	SWSP_x;
    SpecWinSizeSpec	SWSP_y;
} SpecWinSizePair;

typedef ByteEnum WinPositionType;
#define WPT_AT_RATIO 0
#define WPT_STAGGER 1
#define WPT_CENTER 2
#define WPT_TILED 3
#define WPT_AT_MOUSE_POSITION 4
#define WPT_AS_REQUIRED 5
#define WPT_AT_SPECIFIC_POSITION 6


typedef ByteEnum WinSizeType;
#define WST_AS_RATIO_OF_PARENT 0
#define WST_AS_RATIO_OF_FIELD 1
#define WST_AS_DESIRED 2
#define WST_EXTEND_TO_BOTTOM_RIGHT 3
#define WST_EXTEND_NEAR_BOTTOM_RIGHT 4

typedef ByteEnum WinConstrainType;
#define WCT_NONE 0
#define WCT_KEEP_PARTIALLY_VISIBLE 1
#define WCT_KEEP_VISIBLE 2
#define WCT_KEEP_VISIBLE_WITH_MARGIN 3


typedef WordFlags WinPosSizeFlags;
#define WPSF_PERSIST		0x8000
#define WPSF_HINT_FOR_ICON	0x4000
#define WPSF_NEVER_SAVE_STATE	0x2000
#define WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT	0x1000
#define WPSF_CONSTRAIN_TYPE	0x00c0
#define WPSF_POSITION_TYPE	0x0038
#define WPSF_SIZE_TYPE		0x0007






typedef dword SizeAsDWord;

#define DWORD_WIDTH(val)	((word) (val))
#define DWORD_HEIGHT(val) 	((word) ((val) >> 16))

#define MAKE_SIZE_DWORD(width,height) ((((dword) (height)) << 16) | (word)(width))





typedef ByteEnum VMStyle;
#define VMS_TEXT 0
#define VMS_ABBREV_TEXT 1
#define VMS_GRAPHIC_TEXT 2
#define VMS_ICON 3
#define VMS_TOOL 4

typedef WordFlags VisMonikerListEntryType;
#define VMLET_GS_SIZE 		0x3000	
#define VMLET_STYLE		0x0f00  
#define VMLET_MONIKER_LIST	0x0080
#define VMLET_GSTRING		0x0040
#define VMLET_GS_ASPECT_RATIO	0x0030	
#define VMLET_GS_COLOR		0x000f	

#define VMLET_GS_SIZE_OFFSET 12
#define VMLET_STYLE_OFFSET 8
#define VMLET_GS_ASPECT_RATIO_OFFSET 4
#define VMLET_GS_COLOR_OFFSET 0

typedef ByteFlags VisMonikerType;
#define VMT_MONIKER_LIST	0x80
#define VMT_GSTRING		0x40
#define VMT_GS_ASPECT_RATIO	0x30	
#define VMT_GS_COLOR		0x0f	

#define VMT_GS_ASPECT_RATIO_OFFSET 4
#define VMT_GS_COLOR_OFFSET 0

typedef struct {
     word		VMLE_type;
     optr		VMLE_moniker;
} VisMonikerListEntry;

typedef WordFlags VisMonikerCachedWidth;
#define VMCW_HINTED		0x8000
#define VMCW_BERKELEY_9		0x7f00
#define VMCW_BERKELEY_10	0x00ff

#define VMCW_BERKELEY_9_OFFSET	8
#define VMCW_BERKELEY_10_OFFSET	0

typedef struct {
    byte		VM_type;
    word		VM_width;
} VisMoniker;


typedef struct {
    VisMoniker		VMWGS_common;
    word		VMWGS_height;
} VisMonikerWithGString;

#define VMWGS_gString	(sizeof(VisMonikerWithGString))   


typedef struct {
    VisMoniker		VMWT_common;
    char		VMWT_mnemonicOffset;
} VisMonikerWithText;

#define VMWT_text	(sizeof(VisMonikerWithText))  





typedef ByteFlags CreateVisMonikerFlags;
#define CVMF_DIRTY		0x80

typedef ByteEnum VisMonikerSourceType;
#define VMST_FPTR 0
#define VMST_OPTR 1
#define VMST_HPTR 2

typedef ByteEnum VisMonikerDataType;
#define VMDT_NULL 0
#define VMDT_VIS_MONIKER 1
#define VMDT_TEXT 2
#define VMDT_GSTRING 3
#define VMDT_TOKEN 4



typedef WordFlags SpecBuildFlags;
#define SBF_IN_UPDATE_WIN_GROUP			0x8000
#define SBF_WIN_GROUP				0x4000
#define SBF_TREE_BUILD				0x2000
#define SBF_VIS_PARENT_WITHIN_SCOPE_OF_TREE_BUILD 0x1000
#define SBF_SKIP_CHILD				0x0800
#define SBF_FIND_LAST				0x0400
#define SBF_VIS_PARENT_UNBUILDING		0x0200
#define SBF_VIS_PARENT_FULLY_ENABLED		0x0100
#define SBF_UPDATE_MODE				0x0003

	
	
	
	
	

	

	
	






  








	

	



	

	


	


	



	

	



typedef struct {
	word		ESP_extraWidth;
	word		ESP_extraHeight;
	word		ESP_leftoverChildren;
	word		ESP_unused;
} ExtraSizeParams;


	





	


  

typedef struct {
	word		WSIP_windowWidth;
	word		WSIP_windowHeight;
	byte		WSIP_bottomArea;
	byte		WSIP_rightArea;
	word		WSIP_unused;
} WinSizeInfoParams;

 



	

	

typedef WordFlags NavigationFlags;
#define NF_COMPLETED_CIRCUIT		0x8000
#define NF_REACHED_ROOT			0x4000
#define NF_NAV_MENU_BAR			0x0020
#define NF_INITIATE_QUERY		0x0008
#define NF_SKIP_NODE			0x0004
#define NF_TRAVEL_CIRCUIT		0x0002
#define NF_BACKTRACK_AFTER_TRAVELING	0x0001



typedef NavigationFlags NavigateFlags;

typedef ByteFlags NavigateCommonFlags;
#define NCF_IS_COMPOSITE	0x80
#define NCF_IS_FOCUSABLE	0x40
#define NCF_IS_MENU_RELATED	0x20
#define NCF_IS_INPUT_NODE	0x10

typedef struct {
    optr		NCP_object;
    NavigationFlags	NCP_navFlags;
    NavigateCommonFlags	NCP_navCommonFlags;
    ChunkHandle		NCP_genPart;
    byte		NCP_backtrackFlag;
} NavigateCommonParams;


  

 

  

typedef struct {
	word	NQP_navFlags;
	byte	NQP_backtrackFlag;
	byte	NQP_unused;
	optr	NQP_nextObject;
} NavigationQueryParams;




	

 


	



   

typedef ByteFlags MenuSepFlags;
#define MSF_SEP		0x80
#define MSF_USABLE	0x40
#define MSF_FROM_CHILD	0x20

	

	



 

 


  

  

typedef struct {
    word    	VCCIBF_data1;
    word    	VCCIBF_data2;
    word    	VCCIBF_data3;
    word    	VCCIBF_data4;
    word    	VCCIBF_data5;
    Rectangle	VCCIBF_bounds;
} VisCallChildrenInBoundsFrame;



  
  
  
  

typedef word InsertDeleteSpaceTypes;
#define IDST_MOVE_OBJECTS_INSIDE_DELETED_SPACE_BY_AMOUNT_DELETED    0x0010
#define IDST_MOVE_OBJECTS_INTERSECTING_DELETED_SPACE	    	    0x0008
#define IDST_RESIZE_OBJECTS_INTERSECTING_SPACE	    	    	    0x0004
#define IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE	    	    	    0x0002
#define IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE \
    	    	    	    	    	    	    	    	    0x0001




















	








typedef WordFlags GenBranchInfo;
#define GBI_USABLE		0x8000
#define GBI_BRANCH_MINIMIZED	0x4000



typedef struct {
	word VGD_lineWidth;
	word VGD_centerOffset;
	word VGD_secondWidth;
} VarGeoData;


    #define TEMP_VIS_OLD_BOUNDS 16384

    #define ATTR_VIS_GEOMETRY_DATA 16388

    #define TEMP_VIS_INVAL_REGION 16392




    #define ATTR_SPEC_POSITION 16396
	
    #define ATTR_SPEC_POSITION_X 16400

    #define ATTR_SPEC_POSITION_Y 16404








    
    
    

    



    
    
    
extern ClassStruct _far VisClass; extern Message _Messages_VisClass[]; extern MessageMethod *_Methods_VisClass[]; extern CMethodDef _htypes_VisClass[];extern MessageMethod *_Reloc_VisClass;
typedef struct _VisInstance {

# 883 "/staff/pcgeos/CInclude/Objects/visC.goh"
    Rectangle VI_bounds;
    VisTypeFlags VI_typeFlags;

    VisAttrs VI_attrs;



    VisOptFlags VI_optFlags;
    VisGeoAttrs VI_geoAttrs;
    SpecAttrs VI_specAttrs;
    LinkPart VI_link;} VisInstance; 
# 894 "/staff/pcgeos/CInclude/Objects/visC.goh"
typedef enum{MSG_VIS_DRAW=16480,MSG_VIS_REDRAW_ENTIRE_OBJECT,MSG_VIS_VUP_CREATE_GSTATE,MSG_VIS_VUP_QUERY,MSG_VIS_VUP_FIND_OBJECT_OF_CLASS,MSG_VIS_VUP_CALL_OBJECT_OF_CLASS,MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS,MSG_VIS_VUP_TEST_FOR_OBJECT_OF_CLASS,MSG_VIS_VUP_CALL_WIN_GROUP,MSG_VIS_VUP_SEND_TO_WIN_GROUP,MSG_VIS_SET_ATTRS,MSG_VIS_SET_GEO_ATTRS,MSG_VIS_GET_GEO_ATTRS,MSG_VIS_GET_OPT_FLAGS,MSG_VIS_SET_TYPE_FLAGS,MSG_VIS_GET_TYPE_FLAGS,MSG_VIS_GET_ATTRS,MSG_VIS_GET_POSITION,MSG_VIS_SET_POSITION,MSG_VIS_GET_BOUNDS,MSG_VIS_GET_SIZE,MSG_VIS_SET_SIZE,MSG_VIS_GET_CENTER,MSG_VIS_RECALC_SIZE,MSG_VIS_POSITION_BRANCH,MSG_VIS_NOTIFY_GEOMETRY_VALID,MSG_VIS_BOUNDS_CHANGED,MSG_VIS_RESET_TO_INITIAL_SIZE,MSG_VIS_RECALC_SIZE_AND_INVAL_IF_NEEDED,MSG_VIS_POSITION_AND_INVAL_IF_NEEDED,MSG_VIS_MARK_INVALID,MSG_VIS_VUP_UPDATE_WIN_GROUP,MSG_VIS_UPDATE_WIN_GROUP,MSG_VIS_UPDATE_GEOMETRY,MSG_VIS_UPDATE_WINDOWS_AND_IMAGE,MSG_VIS_INVALIDATE,MSG_VIS_ADD_RECT_TO_UPDATE_REGION,MSG_VIS_INVAL_TREE,MSG_VIS_OPEN,MSG_VIS_CLOSE,MSG_VIS_DESTROY,MSG_VIS_REMOVE,MSG_VIS_QUERY_WINDOW,MSG_VIS_OPEN_WIN,MSG_VIS_CLOSE_WIN,MSG_VIS_WIN_ABOUT_TO_BE_CLOSED,MSG_VIS_MOVE_RESIZE_WIN,MSG_VIS_ADD_CHILD,MSG_VIS_REMOVE_CHILD,MSG_VIS_MOVE_CHILD,MSG_VIS_FIND_CHILD,MSG_VIS_FIND_CHILD_AT_POSITION,MSG_VIS_COUNT_CHILDREN,MSG_VIS_FIND_PARENT,MSG_VIS_CALL_PARENT,MSG_VIS_SEND_TO_PARENT,MSG_VIS_SEND_TO_CHILDREN,MSG_VIS_GRAB_MOUSE,MSG_VIS_FORCE_GRAB_MOUSE,MSG_VIS_GRAB_LARGE_MOUSE,MSG_VIS_FORCE_GRAB_LARGE_MOUSE,MSG_VIS_RELEASE_MOUSE,MSG_VIS_ADD_BUTTON_PRE_PASSIVE,MSG_VIS_REMOVE_BUTTON_PRE_PASSIVE,MSG_VIS_ADD_BUTTON_POST_PASSIVE,MSG_VIS_REMOVE_BUTTON_POST_PASSIVE,MSG_VIS_TAKE_GADGET_EXCL,MSG_VIS_RELEASE_GADGET_EXCL,MSG_VIS_LOST_GADGET_EXCL,MSG_VIS_VUP_QUERY_FOCUS_EXCL=16551,MSG_VIS_FUP_QUERY_FOCUS_EXCL,MSG_VIS_VUP_ALTER_INPUT_FLOW,MSG_VIS_VUP_SET_MOUSE_INTERACTION_BOUNDS,MSG_VIS_VUP_GET_MOUSE_STATUS,MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION,MSG_VIS_VUP_BUMP_MOUSE,MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER,MSG_VIS_CALL_ROUTINE,MSG_VIS_DRAW_MONIKER,MSG_VIS_GET_MONIKER_POS,MSG_VIS_GET_MONIKER_SIZE,MSG_VIS_FIND_MONIKER,MSG_VIS_CREATE_VIS_MONIKER,MSG_VIS_VUP_EC_ENSURE_WINDOW_NOT_REFERENCED,MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED,MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED,MSG_SPEC_BUILD,MSG_SPEC_BUILD_BRANCH,MSG_SPEC_UNBUILD_BRANCH,MSG_SPEC_UNBUILD,MSG_SPEC_GET_VIS_PARENT,MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD,MSG_SPEC_GUP_QUERY_VIS_PARENT,MSG_SPEC_GET_SPECIFIC_VIS_OBJECT,MSG_SPEC_ADD_CHILD_RELATIVE_TO_GEN,MSG_SPEC_RESOLVE_MONIKER_LIST,MSG_SPEC_RESOLVE_TOKEN_MONIKER,MSG_SPEC_SET_ATTRS,MSG_SPEC_GET_ATTRS,MSG_SPEC_SET_USABLE,MSG_SPEC_SET_NOT_USABLE,MSG_SPEC_NOTIFY_ENABLED,MSG_SPEC_NOTIFY_NOT_ENABLED,MSG_SPEC_UPDATE_VIS_MONIKER,MSG_SPEC_UPDATE_VISUAL,MSG_SPEC_GET_EXTRA_SIZE,MSG_SPEC_CONVERT_DESIRED_SIZE_HINT,MSG_SPEC_CONVERT_SIZE,MSG_SPEC_VUP_GET_WIN_SIZE_INFO,MSG_SPEC_NAVIGATE_TO_NEXT_FIELD,MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD,MSG_SPEC_NAVIGATE_COMMON,MSG_SPEC_ACTIVATE_INTERACTION_DEFAULT,MSG_SPEC_NAVIGATE,MSG_SPEC_NAVIGATION_QUERY,MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE,MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC,MSG_SPEC_CHECK_MNEMONIC,MSG_SPEC_MENU_SEP_QUERY,MSG_SPEC_UPDATE_MENU_SEPARATORS,MSG_SPEC_START_BROADCAST_FOR_DEFAULT_FOCUS,MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS,MSG_VIS_LAYER_SET_DOC_BOUNDS,MSG_VIS_LAYER_GET_DOC_BOUNDS,MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK,MSG_SPEC_SCAN_GEOMETRY_HINTS,MSG_SPEC_RESCAN_GEO_AND_UPDATE,MSG_SPEC_UPDATE_SPECIFIC_OBJECT,MSG_VIS_RECREATE_CACHED_GSTATES,MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE,MSG_VIS_CREATE_CACHED_GSTATES,MSG_VIS_DESTROY_CACHED_GSTATES,MSG_SPEC_VIS_OPEN_NOTIFY,MSG_SPEC_VIS_CLOSE_NOTIFY,MSG_SPEC_GET_MENU_CENTER,MSG_SPEC_UPDATE_KBD_ACCELERATOR,MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD,MSG_VIS_REMOVE_NON_DISCARDABLE_VM_CHILD,MSG_VIS_REMOVE_NON_DISCARDABLE,MSG_VIS_INVAL_ALL_GEOMETRY,MSG_SPEC_GUP_QUERY,MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN,MSG_SPEC_SET_LEGOS_LOOK,MSG_SPEC_GET_LEGOS_LOOK,}VisMessages;

#if defined (__HIGHC__)
pragma Alias(VisObjectHandlesInkReply, "VISOBJECTHANDLESINKREPLY");
#endif


#endif

# 45 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCvCompC
#define __GOCvCompC

# 1 "/staff/pcgeos/CInclude/Objects/vCompC.goh"






















#ifndef __GOCvisC
#define __GOCvisC
#include "/staff/pcgeos/CInclude/Objects/visC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/vCompC.goh"

#define VisCompBase VisBase
#define _FIRST_VisCompClass 18432
# 24 "/staff/pcgeos/CInclude/Objects/vCompC.goh"




typedef ByteEnum WidthJustification;
#define WJ_LEFT_JUSTIFY_CHILDREN 		  0x00
#define WJ_RIGHT_JUSTIFY_CHILDREN 		  0x40
#define WJ_CENTER_CHILDREN_HORIZONTALLY		  0x80
#define WJ_FULL_JUSTIFY_CHILDREN_HORIZONTALLY	  0xc0
	
typedef ByteEnum HeightJustification;
#define HJ_TOP_JUSTIFY_CHILDREN			  0x00
#define HJ_BOTTOM_JUSTIFY_CHILDREN		  0x04
#define HJ_CENTER_CHILDREN_VERTICALLY		  0x08
#define HJ_FULL_JUSTIFY_CHILDREN_VERTICALLY	  0x0c

typedef ByteFlags VisCompGeoDimensionAttrs;
#define VCGDA_WIDTH_JUSTIFICATION               0xc0
#define VCGDA_EXPAND_WIDTH_TO_FIT_PARENT        0x20
#define VCGDA_DIVIDE_WIDTH_EQUALLY              0x10
#define VCGDA_HEIGHT_JUSTIFICATION              0x0c
#define VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT       0x02
#define VCGDA_DIVIDE_HEIGHT_EQUALLY             0x01




typedef ByteFlags VisCompGeoAttrs;
#define	VCGA_ORIENT_CHILDREN_VERTICALLY		0x80
#define VCGA_INCLUDE_ENDS_IN_CHILD_SPACING	0x40
#define VCGA_ALLOW_CHILDREN_TO_WRAP		0x20
#define VCGA_ONE_PASS_OPTIMIZATION		0x10
#define VCGA_CUSTOM_MANAGE_CHILDREN		0x08
#define VCGA_HAS_MINIMUM_SIZE			0x04
#define	VCGA_WRAP_AFTER_CHILD_COUNT		0x02
#define VCGA_ONLY_DRAWS_IN_MARGINS		0x01

typedef struct {
    VisCompGeoAttrs	    	GADA_geoAttrs;
    VisCompGeoDimensionAttrs	GADA_geoDimensionAttrs;
} GeoAndDimensionAttrs;

#define GEO_ATTRS(val) ((val).GADA_geoAttrs)
#define GEO_DIMENSION_ATTRS(val) ((val).GADA_geoDimensionAttrs)

 









typedef dword SpacingAsDWord;

#define DWORD_CHILD_SPACING(val) 	((word) (val))
#define DWORD_WRAP_SPACING(val) 	((word) ((val) >> 16))

#define MAKE_SPACING_DWORD(width,height) \
    ((((dword) (height)) << 16) | (width))


	
	

	
	

	
	

	
	
	
	
	

extern ClassStruct _far VisCompClass; extern Message _Messages_VisCompClass[]; extern MessageMethod *_Methods_VisCompClass[]; extern CMethodDef _htypes_VisCompClass[];extern MessageMethod *_Reloc_VisCompClass;
typedef struct _VisCompInstance {

# 883 "/staff/pcgeos/CInclude/Objects/visC.goh"
    Rectangle VI_bounds;
    VisTypeFlags VI_typeFlags;

    VisAttrs VI_attrs;



    VisOptFlags VI_optFlags;
    VisGeoAttrs VI_geoAttrs;
    SpecAttrs VI_specAttrs;
    LinkPart VI_link;
# 97 "/staff/pcgeos/CInclude/Objects/vCompC.goh"
    CompPart VCI_comp;
    optr VCI_gadgetExcl;
    WindowHandle VCI_window;
    VisCompGeoAttrs VCI_geoAttrs;
    VisCompGeoDimensionAttrs VCI_geoDimensionAttrs;} VisCompInstance; 
# 103 "/staff/pcgeos/CInclude/Objects/vCompC.goh"
typedef enum{MSG_VIS_COMP_GET_GEO_ATTRS=18432,MSG_VIS_COMP_SET_GEO_ATTRS,MSG_VIS_COMP_GET_CHILD_SPACING,MSG_VIS_COMP_GET_MINIMUM_SIZE,MSG_VIS_COMP_GET_MARGINS,MSG_VIS_COMP_GET_WRAP_COUNT,}VisCompMessages;


#endif

# 46 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCvCntC
#define __GOCvCntC

# 1 "/staff/pcgeos/CInclude/Objects/vCntC.goh"




















#ifndef __GOCuiInputC
#define __GOCuiInputC
#include "/staff/pcgeos/CInclude/Objects/uiInputC.poh"
#endif

# 21 "/staff/pcgeos/CInclude/Objects/vCntC.goh"

#ifndef __GOCvCompC
#define __GOCvCompC
#include "/staff/pcgeos/CInclude/Objects/vCompC.poh"
#endif

# 22 "/staff/pcgeos/CInclude/Objects/vCntC.goh"

#ifndef __GOCvisC
#define __GOCvisC
#include "/staff/pcgeos/CInclude/Objects/visC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/vCntC.goh"

#define VisContentBase VisCompBase
#define _FIRST_VisContentClass 18944
# 24 "/staff/pcgeos/CInclude/Objects/vCntC.goh"


	

typedef ByteFlags VisContentAttrs;
#define	VCNA_SAME_WIDTH_AS_VIEW			0x80
#define VCNA_SAME_HEIGHT_AS_VIEW			0x40
#define	VCNA_LARGE_DOCUMENT_MODEL			0x20
#define VCNA_WINDOW_COORDINATE_MOUSE_EVENTS		0x10
#define VCNA_ACTIVE_MOUSE_GRAB_REQUIRES_LARGE_EVENTS	0x08
#define VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY		0x04
#define VCNA_VIEW_DOES_NOT_WIN_SCROLL			0x02


 
  


    	    	    	    	    	    	    	      
  
  
  
  
  
  
  
  

  



typedef struct {
    optr			VMG_object;
    WindowHandle		VMG_gWin;
    PointDWord			VMG_translation;
    VisInputFlowGrabFlags	VMG_flags;
    byte			VMG_unused;
} VisMouseGrab;

	



	
	
	
	
	

	
	
	
	

	

	
	
	
	
	
	
	

extern ClassStruct _far VisContentClass; extern Message _Messages_VisContentClass[]; extern MessageMethod *_Methods_VisContentClass[]; extern CMethodDef _htypes_VisContentClass[];extern MessageMethod *_Reloc_VisContentClass;
typedef struct _VisContentInstance {

# 883 "/staff/pcgeos/CInclude/Objects/visC.goh"
    Rectangle VI_bounds;
    VisTypeFlags VI_typeFlags;

    VisAttrs VI_attrs;



    VisOptFlags VI_optFlags;
    VisGeoAttrs VI_geoAttrs;
    SpecAttrs VI_specAttrs;
    LinkPart VI_link;
# 97 "/staff/pcgeos/CInclude/Objects/vCompC.goh"
    CompPart VCI_comp;
    optr VCI_gadgetExcl;
    WindowHandle VCI_window;
    VisCompGeoAttrs VCI_geoAttrs;
    VisCompGeoDimensionAttrs VCI_geoDimensionAttrs;
# 68 "/staff/pcgeos/CInclude/Objects/vCntC.goh"
    optr VCNI_view;
    WindowHandle VCNI_window;
    word VCNI_viewHeight;
    word VCNI_viewWidth;
    VisContentAttrs VCNI_attrs;

    PointDWord VCNI_docOrigin;
    PointWWFixed VCNI_scaleFactor;
    ChunkHandle VCNI_prePassiveMouseGrabList;

    VisMouseGrab VCNI_impliedMouseGrab;

    VisMouseGrab VCNI_activeMouseGrab;
    ChunkHandle VCNI_postPassiveMouseGrabList;
    KbdGrab VCNI_kbdGrab;
    FTVMCGrab VCNI_focusExcl;
    FTVMCGrab VCNI_targetExcl;
    Handle VCNI_holdUpInputQueue;
    word VCNI_holdUpInputCount;
    HoldUpInputFlags VCNI_holdUpInputFlags;} VisContentInstance; 
# 89 "/staff/pcgeos/CInclude/Objects/vCntC.goh"
typedef enum{MSG_VIS_CONTENT_GET_WIN_SIZE=18944,MSG_VIS_CONTENT_SET_ATTRS,MSG_VIS_CONTENT_GET_ATTRS,MSG_VIS_CONTENT_RECALC_SIZE_BASED_ON_VIEW,MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW,MSG_VIS_CONTENT_RESUME_INPUT_FLOW,MSG_VIS_CONTENT_DISABLE_HOLD_UP,MSG_VIS_CONTENT_ENABLE_HOLD_UP,MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN,MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT,MSG_VIS_CONTENT_UNWANTED_KBD_EVENT,MSG_VIS_CONTENT_REMOTE_OBJ_MESSAGE_VIA_HOLD_UP_QUEUE,MSG_VIS_CONTENT_SET_DOC_BOUNDS,MSG_VIS_CONTENT_NOTIFY_ACTIVE_MOUSE_GRAB_WIN_CHANGED,}VisContentMessages;


#endif

# 47 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgAppC
#define __GOCgAppC

# 1 "/staff/pcgeos/CInclude/Objects/gAppC.goh"





















#include <geode.h>
#include <win.h>
#include <localize.h>

#ifndef __GOCvisC
#define __GOCvisC
#include "/staff/pcgeos/CInclude/Objects/visC.poh"
#endif

# 26 "/staff/pcgeos/CInclude/Objects/gAppC.goh"

#ifndef __GOCgenC
#define __GOCgenC

# 1 "/staff/pcgeos/CInclude/Objects/genC.goh"



















#include    <file.h>	
#include    <disk.h>	
#include    <object.h>  




#ifndef __GOCvisC
#define __GOCvisC
#include "/staff/pcgeos/CInclude/Objects/visC.poh"
#endif

# 27 "/staff/pcgeos/CInclude/Objects/genC.goh"

typedef struct {VisBase Gen_metaBase; word Gen_offset; } GenBase;
#define _FIRST_GenClass 24576
# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"










#define ObjDerefGen(obj) ObjDeref2(obj)












	
	




 
	





























 





 
			



 



 

    




	
	

	



	
	








	
 

	
 

	




 
 
 

typedef enum  {
    TO_GEN_PARENT=_FIRST_GenClass,
    TO_FOCUS,
    TO_TARGET,
    TO_MODEL,
    TO_APP_FOCUS,
    TO_APP_TARGET,
    TO_APP_MODEL,
    TO_SYS_FOCUS,
    TO_SYS_TARGET,
    TO_SYS_MODEL
} GenTravelOption;

 
 

 

 
 
 
 

 







 

typedef enum  {
    BRPT_OUTPUT_OPTR
} BranchReplaceParamType;


 
#define BRP_DUMMY_OPTR_START	1


 










 
    	    	    	    	    	    	    	    	     



#define GET_MM_AND_TYPE(M,T) 	((M) | (((word) (T)) << 8))


	


	
 

 



typedef struct {
    word		SSA_width;
    word		SSA_height;
    word		SSA_count;
    VisUpdateMode	SSA_updateMode;
} SetSizeArgs;

typedef struct {
    word	GSA_width;
    word	GSA_height;
    word	GSA_unused;
    word	GSA_count;
} GetSizeArgs;


	

	

	

	
	
	
	
	



 



	
	




	
 



	
	



 

typedef struct {
    word	GRP_ax;
    word	GRP_bp;
    word	GRP_cx;
    word	GRP_dx;
} GenReturnParams;



typedef enum {
    GUQT_UI_FOR_APPLICATION,
    GUQT_UI_FOR_SCREEN,
    GUQT_UI_FOR_FIELD,
    GUQT_UI_FOR_MISC,
    GUQT_FIELD,
    GUQT_SCREEN,
    GUQT_DELAYED_OPERATION
} GenUpwardQueryType;



 

typedef struct {
    optr	GGFI_optr;
    MemHandle	GGFI_window;
    word	GGFI_unused;
} GenGupFieldInfo;


#define MSG_GEN_GUP_QUERY_FOR_FIELD MSG_GEN_GUP_QUERY
typedef struct {
    optr	GGSI_optr;
    MemHandle	GGSI_window;
    word	GGSI_unused;
} GenGupScreenInfo;


#define MSG_GEN_GUP_QUERY_FOR_SCREEN MSG_GEN_GUP_QUERY

 



#define GET_CHAR_AND_SHIFT(C,S) 	((C) | (((word) (S)) << 8))


 
	



typedef ByteFlags NotifyEnabledFlags;
#define NEF_STATE_CHANGING	0x80


	

	



typedef ByteEnum RequestedViewArea;
#define RVA_NO_AREA_CHOICE 0
#define RVA_X_SCROLLER_AREA 1
#define RVA_Y_SCROLLER_AREA 2
#define RVA_LEFT_AREA 3
#define RVA_TOP_AREA 4
#define RVA_RIGHT_AREA 5
#define RVA_BOTTOM_AREA 6

typedef struct {
    byte	GFVRP_hViewArea;
    byte	GFVRP_vViewArea;
    ChunkHandle	GFVRP_hRange;
    ChunkHandle	GFVRP_vRange;
    word    	GFVRP_unused;
} GenFindViewRangesParams;

#define GET_VIEW_AREAS(H,V) 	((H) | (((word) (V)) << 8))




 

	



typedef struct {
    char    GOP_category[INI_CATEGORY_BUFFER_SIZE];
    char    GOP_key[INI_CATEGORY_BUFFER_SIZE];
} GenOptionsParams;














typedef struct {
    DiskHandle	GFP_disk;   	


    PathName	GFP_path;   	

} GenFilePath;

    #define ATTR_GEN_PATH_DATA 24576

    #define TEMP_GEN_PATH_SAVED_DISK_HANDLE 24580




	
#define MSG_GEN_PATH_GET_BLOCK MSG_GEN_PATH_GET




  

typedef WordFlags GenFindObjectWithMonikerFlags;
#define	GFTMF_EXACT_MATCH	0x8000
#define GFTMF_SKIP_THIS_NODE	0x4000

	    	    












typedef enum {
    	KO_NO_KEYBOARD,
	KO_KEYBOARD_REQUIRED,
	KO_KEYBOARD_EMBEDDED
} KeyboardOverride;













   

















typedef struct {
    ClassStruct *DCA_class;
} DestinationClassArgs;

    #define HINT_DUMMY 24584

    #define HINT_FREQUENTLY_USED 24588

    #define HINT_INFREQUENTLY_USED 24592

    #define HINT_AN_ADVANCED_FEATURE 24596

    #define HINT_DEFAULT_DEFAULT_ACTION 24600

    #define HINT_ENSURE_TEMPORARY_DEFAULT 24604

    #define HINT_SAME_CATEGORY_AS_PARENT 24608

    #define HINT_SYS_MENU 24612

    #define HINT_USE_TEXT_MONIKER 24616

    #define HINT_USE_ICONIC_MONIKER 24620

    #define HINT_DEFAULT_FOCUS 24624

    #define HINT_DEFAULT_TARGET 24628

    #define HINT_DEFAULT_MODEL 24632

    #define HINT_PREVENT_DEFAULT_OVERRIDES 24636

    #define HINT_PRESERVE_FOCUS 24640

    #define HINT_DO_NOT_PRESERVE_FOCUS 24644

    #define HINT_GENERAL_CONSUMER_MODE 24648

    #define HINT_NEVER_ADOPT_MENUS 24652

    #define HINT_ALWAYS_ADOPT_MENUS 24656

    #define HINT_ALLOW_CHILDREN_TO_WRAP 24660

    #define HINT_BOTTOM_JUSTIFY_CHILDREN 24664

    #define HINT_CENTER_CHILDREN_HORIZONTALLY 24668

    #define HINT_CENTER_CHILDREN_ON_MONIKERS 24672

    #define HINT_CENTER_CHILDREN_VERTICALLY 24676

    #define HINT_CENTER_MONIKER 24680

    #define HINT_CUSTOM_CHILD_SPACING 24684

    #define HINT_DONT_ALLOW_CHILDREN_TO_WRAP 24688

    #define HINT_DONT_FULL_JUSTIFY_CHILDREN 24692

    #define HINT_DONT_INCLUDE_ENDS_IN_CHILD_SPACING 24696

    #define HINT_DO_NOT_USE_MONIKER 24700

    #define HINT_DRAW_IN_BOX 24704

    #define HINT_EXPAND_HEIGHT_TO_FIT_PARENT 24708

    #define HINT_EXPAND_WIDTH_TO_FIT_PARENT 24712

    #define HINT_FIXED_SIZE 24716

    #define HINT_FULL_JUSTIFY_CHILDREN_HORIZONTALLY 24720

    #define HINT_FULL_JUSTIFY_CHILDREN_VERTICALLY 24724

    #define HINT_INCLUDE_ENDS_IN_CHILD_SPACING 24728

    #define HINT_INITIAL_SIZE 24732

    #define HINT_LEFT_JUSTIFY_CHILDREN 24736

    #define HINT_LEFT_JUSTIFY_MONIKERS 24740

    #define HINT_MAKE_REPLY_BAR 24744

    #define HINT_MAXIMUM_SIZE 24748

    #define HINT_MINIMUM_SIZE 24752

    #define HINT_NO_TALLER_THAN_CHILDREN_REQUIRE 24756

    #define HINT_NO_WIDER_THAN_CHILDREN_REQUIRE 24760

    #define HINT_ORIENT_CHILDREN_HORIZONTALLY 24764

    #define HINT_ORIENT_CHILDREN_VERTICALLY 24768

    #define HINT_PLACE_MONIKER_ABOVE 24772

    #define HINT_ALIGN_LEFT_MONIKER_EDGE_WITH_CHILD 24776

    #define HINT_PLACE_MONIKER_TO_LEFT 24780

    #define HINT_PLACE_MONIKER_TO_RIGHT 24784

    #define HINT_RIGHT_JUSTIFY_CHILDREN 24788

    #define HINT_TOP_JUSTIFY_CHILDREN 24792

    #define HINT_WRAP_AFTER_CHILD_COUNT 24796

    #define HINT_DIVIDE_WIDTH_EQUALLY 24800

    #define HINT_DIVIDE_HEIGHT_EQUALLY 24804

    #define HINT_NO_BORDERS_ON_MONIKERS 24808

    #define HINT_GADGET_TEXT_COLOR 24812

    #define HINT_POPS_UP_TO_RIGHT 24816

    #define HINT_POPS_UP_BELOW 24820

    #define ATTR_GEN_PROPERTY 24824

    #define ATTR_GEN_NOT_PROPERTY 24828

    #define HINT_SEEK_MENU_BAR 24832

    #define HINT_AVOID_MENU_BAR 24836

    #define HINT_NAVIGATION_ID 24840

    #define HINT_NAVIGATION_NEXT_ID 24844

    #define HINT_DISMISS_WHEN_DISABLED 24848

    #define HINT_SEEK_X_SCROLLER_AREA 24852

    #define HINT_SEEK_Y_SCROLLER_AREA 24856

    #define HINT_SEEK_LEFT_OF_VIEW 24860

    #define HINT_SEEK_TOP_OF_VIEW 24864

    #define HINT_SEEK_RIGHT_OF_VIEW 24868

    #define HINT_SEEK_BOTTOM_OF_VIEW 24872

    #define HINT_GEN_UNUSED 24876
      
    #define HINT_USE_INITIAL_BOUNDS_WHEN_RESTORED 24880

    #define HINT_KEEP_INITIALLY_ONSCREEN 24884

    #define HINT_DONT_KEEP_INITIALLY_ONSCREEN 24888

    #define HINT_KEEP_PARTIALLY_ONSCREEN 24892

    #define HINT_KEEP_ENTIRELY_ONSCREEN 24896

    #define HINT_KEEP_ENTIRELY_ONSCREEN_WITH_MARGIN 24900

    #define HINT_DONT_KEEP_PARTIALLY_ONSCREEN 24904

    #define HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT 24908

    #define HINT_STAGGER_WINDOW 24912

    #define HINT_CENTER_WINDOW 24916

    #define HINT_TILE_WINDOW 24920

    #define HINT_POSITION_WINDOW_AT_MOUSE 24924

    #define HINT_EXTEND_WINDOW_TO_BOTTOM_RIGHT 24928

    #define HINT_EXTEND_WINDOW_NEAR_BOTTOM_RIGHT 24932

    #define HINT_SIZE_WINDOW_AS_DESIRED 24936

    #define HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT 24940

    #define HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD 24944

    #define HINT_POSITION_ICON_AS_RATIO_OF_FIELD 24948

    #define ATTR_GEN_DESTINATION_CLASS 24952

    ;
    #define HINT_INITIATED 24956
   	
    #define ATTR_GEN_INIT_FILE_KEY 24960

    #define ATTR_GEN_INIT_FILE_CATEGORY 24964

    #define ATTR_GEN_INIT_FILE_PROPAGATE_TO_CHILDREN 24968

    #define ATTR_GEN_FEATURE_LINK 24972

    #define HINT_TOOLBOX 24976

    #define HINT_SAME_ORIENTATION_AS_PARENT 24980

    #define HINT_SEEK_REPLY_BAR 24984

    #define ATTR_GEN_WINDOW_CUSTOM_LAYER_ID 24988

    ;
    #define HINT_SHOW_SHORTCUT 24992

    #define HINT_DRAW_SHORTCUT_BELOW 24996

    #define HINT_CAN_CLIP_MONIKER_WIDTH 25000

    #define HINT_CAN_CLIP_MONIKER_HEIGHT 25004

    #define HINT_SHOW_ENTIRE_MONIKER 25008

    #define ATTR_GEN_POSITION 25012

    #define ATTR_GEN_POSITION_X 25016

    #define ATTR_GEN_POSITION_Y 25020

    #define HINT_ALIGN_LEFT_EDGE_WITH_OBJECT 25024

    ;
    #define HINT_ALIGN_TOP_EDGE_WITH_OBJECT 25028

    ;
    #define HINT_ALIGN_RIGHT_EDGE_WITH_OBJECT 25032

    ;
    #define HINT_ALIGN_BOTTOM_EDGE_WITH_OBJECT 25036

    ;
    #define HINT_DONT_SHOW_SHORTCUT 25040

    #define ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED 25044

    #define ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_ENABLED 25048

    #define ATTR_GEN_VISIBILITY_DATA 25052

    #define ATTR_GEN_VISIBILITY_MESSAGE 25056

    #define ATTR_GEN_VISIBILITY_DESTINATION 25060

    ;
    #define HINT_IS_POPUP_LIST 25064
	    
    #define HINT_MINIMIZE_CHILD_SPACING 25068


typedef struct {
    Color	BC_unselectedColor1;
    Color	BC_unselectedColor2;
    Color 	BC_selectedColor1;
    Color 	BC_selectedColor2;
} BackgroundColors;

    #define HINT_GADGET_BACKGROUND_COLORS 25072

    #define ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY 25076

    #define ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY 25080

    #define ATTR_GEN_WINDOW_CUSTOM_PARENT 25084

    #define TEMP_GEN_SAVE_WINDOW_INFO 25088
	
    #define TEMP_GEN_SAVE_ICON_INFO 25092
	
    #define ATTR_GEN_WINDOW_CUSTOM_WINDOW 25096

    #define HINT_ORIENT_CHILDREN_ALONG_LARGER_DIMENSION 25100

    #define HINT_PLACE_MONIKER_ALONG_LARGER_DIMENSION 25104

    #define HINT_WRAP_AFTER_CHILD_COUNT_IF_VERTICAL_SCREEN 25108

    #define HINT_NOT_MOVABLE 25112

    #define HINT_SEEK_TITLE_BAR_LEFT 25116

    #define HINT_SEEK_TITLE_BAR_RIGHT 25120


typedef enum {
    GDMT_LEVEL_0,
    GDMT_LEVEL_1,
    GDMT_LEVEL_2,
    GDMT_LEVEL_3,
    GDMT_HELP,
    GDMT_HELP_PRIMARY
} GenDefaultMonikerType;

    #define ATTR_GEN_DEFAULT_MONIKER 25124


    #define ATTR_GEN_HELP_FILE 25128

    #define ATTR_GEN_HELP_TYPE 25132

    #define ATTR_GEN_HELP_FILE_FROM_INIT_FILE 25136

    #define ATTR_GEN_FOCUS_HELP 25140

	;
    #define ATTR_GEN_FOCUS_HELP_LIB 25144

        ;

    #define HINT_UNUSED_G 25148


    #define ATTR_GEN_HELP_CONTEXT 25152

    #define HINT_WINDOW_NO_CONSTRAINTS 25156

    #define ATTR_GEN_OUTPUT_TRAVEL_START 25160

	;
    #define HINT_CUSTOM_CHILD_SPACING_IF_LIMITED_SPACE 25164

    #define HINT_WINDOW_NO_TITLE_BAR 25168

    #define HINT_WINDOW_NO_SYS_MENU 25172

    #define ATTR_GEN_USES_HIERARCHICAL_INIT_FILE_CATEGORY 25176

    #define ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED 25180


typedef WordFlags SystemAttrs;
#define SA_NOT			0x8000
#define SA_TINY			0x4000
#define SA_HORIZONTALLY_TINY	0x2000
#define SA_VERTICALLY_TINY	0x1000
#define SA_COLOR		0x0800
#define SA_PEN_BASED		0x0400
#define SA_KEYBOARD_ONLY	0x0200
#define SA_NO_KEYBOARD		0x0100

    #define HINT_IF_SYSTEM_ATTRS 25184

    #define HINT_ENDIF 25188

    #define HINT_ELSE 25192


    #define TEMP_GEN_EMC_PANEL_ITEM_PRIORITY 25196

    #define ATTR_GEN_WINDOW_KBD_OVERRIDE 25200

    #define ATTR_GEN_WINDOW_KBD_POSITION 25204

    #define HINT_WINDOW_MINIMIZE_TITLE_BAR 25208

    #define HINT_WINDOW_ALWAYS_DRAW_WITH_FOCUS 25212






    #define HINT_DRAW_SHADOW 25216

    #define HINT_SEEK_SLOT 25220

    #define HINT_INDENT_CHILDREN 25224




    




    #define HINT_WINDOW_PCV_TOOL_DIALOG_LOOK 25228

    


    #define HINT_WINDOW_PCV_FIT_NOTE_PAD_LOOK 25232

    



    #define HINT_WINDOW_PCV_FIT_NOTE_LOOK 25236

    


    #define HINT_WINDOW_PCV_ROLODEX_CARD_LOOK 25240

    



    #define HINT_CUSTOM_CHILD_WRAP_SPACING 25244

    #define HINT_ALIGN_WITH_CENTERED_MONIKERS 25248

    #define HINT_DONT_INDENT_BOX 25252




    #define HINT_BLANK_WINDOW_STYLE 25256

    

    #define HINT_BLANK_GREY_WINDOW_STYLE 25260

    

    #define HINT_BLANK_BLACK_GROUP_STYLE 25264

    

    #define HINT_BORDERED_GROUP_STYLE 25268

    



    #define HINT_LEFT_JUSTIFY_Y_SCROLLER 25272

    #define HINT_TOP_JUSTIFY_X_SCROLLER 25276

    #define HINT_DRAW_STYLE_3D_RAISED 25280

    #define HINT_DRAW_STYLE_3D_LOWERED 25284

    #define HINT_DRAW_STYLE_FLAT 25288

    





    #define HINT_USE_COMPRESSED_INSETS_FOR_MONIKER 25292

    



    #define HINT_SEEK_NOTEBOOK_LEFT 25296

    #define HINT_SEEK_NOTEBOOK_RIGHT 25300


    #define HINT_WINDOW_WASH_COLOR 25304












typedef struct {
    BackgroundColors	TBC_backgroundColors1;
    BackgroundColors	TBC_backgroundColors2;
} TwoBackgroundColors;


#define HINT_GADGET_TWO_BACKGROUND_COLORS 25072;

typedef struct {
    BackgroundColors	TBC_backgroundColors1;
    BackgroundColors	TBC_backgroundColors2;
    BackgroundColors	TBC_backgroundColors3;
} ThreeBackgroundColors;


#define HINT_GADGET_THREE_BACKGROUND_COLORS 25072;

#define HINT_CUSTOM_EXTRA_MARGINS 25308






typedef struct {
    word    KTP_displayType;
    word    KTP_disallowType;
    word    KTP_entryMode;
} KeyboardTypeParams;

#define HINT_KEYBOARD_TYPE 25312


#define HINT_PREVIOUS_KBD_OVERRIDE 25316









typedef struct {
    word SLTP_shortMessage;
    optr SLTP_shortDestination;
    word SLTP_longMessage;
    optr SLTP_longDestination;
} ShortLongTouchParams;

#define HINT_SHORT_LONG_TOUCH 25320

;
;






typedef ByteEnum GCMIcon;
#define GCMI_NONE 0
#define GCMI_EXIT 1
#define GCMI_HELP 2

typedef ByteFlags GeneralConsumerModeFlags;
#define GCMF_LEFT_ICON	0x38
#define GCMF_RIGHT_ICON 0x07

typedef struct {
    SpecWidth	CSHA_width;
    SpecHeight	CSHA_height;
    sword	CSHA_count;
} CompSizeHintArgs;

typedef struct {
    SpecWidth	GSHA_width;
    SpecHeight	GSHA_height;
} GadgetSizeHintArgs;

typedef struct {
    word	HE_type;
    word	HE_size;
} HintEntry;

typedef struct {
    Color	TC_unselectedColor;
    Color 	TC_selectedColor;
} TextColors;







extern word
    _pascal GenCopyChunk(MemHandle destBlock,
				MemHandle blk, ChunkHandle chnk,
				CompChildFlags flags); 

extern void
    _pascal GenInsertChild(MemHandle mh, ChunkHandle chnk,
				optr childToAdd,
				optr referenceChild,
				CompChildFlags flags); 

extern void
    _pascal GenSetUpwardLink(MemHandle mh, ChunkHandle chnk,
				optr parent); 

extern void
    _pascal GenRemoveDownwardLink(MemHandle mh, ChunkHandle chnk,
				CompChildFlags flags); 

extern void
    _pascal GenSpecShrink(MemHandle mh, ChunkHandle chnk); 

extern void
    _pascal GenProcessGenAttrsBeforeAction(
				MemHandle mh, ChunkHandle chnk); 

extern void
    _pascal GenProcessGenAttrsAfterAction(
				MemHandle mh, ChunkHandle chnk); 

extern optr
    _pascal GenFindObjectInTree(optr startObject,
					dword childTable); 

#define GenFindParent(oself)	\
    ObjLinkFindParent(oself, word_offsetof(GenBase, Gen_offset), \
		      word_offsetof(GenInstance, GI_link))

#ifdef __HIGHC__
pragma Alias(GenCopyChunk, "GENCOPYCHUNK");
pragma Alias(GenInsertChild, "GENINSERTCHILD");
pragma Alias(GenSetUpwardLink, "GENSETUPWARDLINK");
pragma Alias(GenRemoveDownwardLink, "GENREMOVEDOWNWARDLINK");
pragma Alias(GenSpecShrink, "GENSPECSHRINK");
pragma Alias(GenProcessGenAttrsBeforeAction, "GENPROCESSGENATTRSBEFOREACTION");
pragma Alias(GenProcessGenAttrsAfterAction, "GENPROCESSGENATTRSAFTERACTION");
pragma Alias(GenFindObjectInTree, "GENFINDOBJECTINTREE");
#endif






typedef ByteFlags GenAttrs;
#define GA_SIGNAL_INTERACTION_COMPLETE	0x80
#define GA_INITIATES_BUSY_STATE		0x40
#define GA_INITIATES_INPUT_HOLD_UP		0x20
#define GA_INITIATES_INPUT_IGNORE		0x10
#define GA_READ_ONLY				0x08
#define GA_KBD_SEARCH_PATH			0x04
#define GA_TARGETABLE				0x02
#define GA_NOTIFY_VISIBILITY			0x01

typedef ByteFlags GenStates;
#define GS_USABLE	0x80
#define GS_ENABLED	0x40


    
    
    
    
    
    

extern ClassStruct _far GenClass; extern Message _Messages_GenClass[]; extern MessageMethod *_Methods_GenClass[]; extern CMethodDef _htypes_GenClass[];extern MessageMethod *_Reloc_GenClass;
typedef struct _GenInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;} GenInstance; 
# 904 "/staff/pcgeos/CInclude/Objects/genC.goh"
typedef enum{MSG_GEN_SET_ENABLED=24960,MSG_GEN_SET_NOT_ENABLED,MSG_GEN_GET_ENABLED,MSG_GEN_SET_USABLE,MSG_GEN_SET_NOT_USABLE,MSG_GEN_GET_USABLE,MSG_GEN_CHECK_IF_FULLY_ENABLED,MSG_GEN_CHECK_IF_FULLY_USABLE,MSG_GEN_SET_ATTRS,MSG_GEN_GET_ATTRIBUTES,MSG_GEN_GET_VIS_MONIKER,MSG_GEN_USE_VIS_MONIKER,MSG_GEN_REPLACE_VIS_MONIKER,MSG_GEN_REPLACE_VIS_MONIKER_OPTR,MSG_GEN_REPLACE_VIS_MONIKER_TEXT,MSG_GEN_CREATE_VIS_MONIKER,MSG_GEN_DRAW_MONIKER,MSG_GEN_GET_MONIKER_POS,MSG_GEN_GET_MONIKER_SIZE,MSG_GEN_FIND_MONIKER,MSG_GEN_RELOC_MONIKER_LIST,MSG_GEN_SET_KBD_ACCELERATOR,MSG_GEN_GET_KBD_ACCELERATOR,MSG_GEN_CHANGE_ACCELERATOR,MSG_GEN_GET_HELP,MSG_GEN_SET_HELP,MSG_GEN_ADD_CHILD,MSG_GEN_REMOVE_CHILD,MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY,MSG_GEN_MOVE_CHILD,MSG_GEN_FIND_CHILD,MSG_GEN_FIND_CHILD_AT_POSITION,MSG_GEN_FIND_PARENT,MSG_GEN_COUNT_CHILDREN,MSG_GEN_CALL_PARENT,MSG_GEN_SEND_TO_PARENT,MSG_GEN_SEND_TO_CHILDREN,MSG_GEN_GUP_CALL_OBJECT_OF_CLASS,MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS,MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS,MSG_GEN_GUP_FIND_OBJECT_OF_CLASS,MSG_GEN_CALL_APPLICATION,MSG_GEN_SEND_TO_PROCESS,MSG_GEN_CALL_SYSTEM,MSG_GEN_OUTPUT_ACTION,MSG_GEN_COPY_TREE,MSG_GEN_DESTROY,MSG_GEN_BRANCH_REPLACE_PARAMS,MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT,MSG_GEN_BRING_TO_TOP,MSG_GEN_LOWER_TO_BOTTOM,MSG_GEN_START_BROADCAST_FOR_DEFAULT_FOCUS,MSG_GEN_SET_WIN_POSITION,MSG_GEN_SET_WIN_SIZE,MSG_GEN_RESET_TO_INITIAL_SIZE,MSG_GEN_SET_WIN_CONSTRAIN,MSG_GEN_SET_INITIAL_SIZE,MSG_GEN_SET_MINIMUM_SIZE,MSG_GEN_SET_MAXIMUM_SIZE,MSG_GEN_SET_FIXED_SIZE,MSG_GEN_GET_INITIAL_SIZE,MSG_GEN_GET_MINIMUM_SIZE,MSG_GEN_GET_MAXIMUM_SIZE,MSG_GEN_GET_FIXED_SIZE,MSG_GEN_UPDATE_VISUAL,MSG_GEN_APPLY,MSG_GEN_RESET,MSG_GEN_PRE_APPLY,MSG_GEN_POST_APPLY,MSG_GEN_MAKE_APPLYABLE,MSG_GEN_MAKE_NOT_APPLYABLE,MSG_GEN_ACTIVATE,MSG_GEN_ACTIVATE_INTERACTION_DEFAULT,MSG_GEN_NAVIGATE_TO_NEXT_FIELD,MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD,MSG_GEN_NAVIGATION_QUERY,MSG_GEN_GUP_QUERY,MSG_GEN_GUP_INTERACTION_COMMAND,MSG_GEN_FIND_KBD_ACCELERATOR,MSG_GEN_SET_KBD_MKR_PATH,MSG_GEN_NOTIFY_ENABLED,MSG_GEN_NOTIFY_NOT_ENABLED,MSG_GEN_FIND_VIEW_RANGES,MSG_GEN_QUERY_VIEW_AREA,MSG_GEN_QUERY_NEED_TO_BE_ON_ACTIVE_LIST,MSG_GEN_LOAD_OPTIONS,MSG_GEN_SAVE_OPTIONS,MSG_GEN_ADD_GEOMETRY_HINT,MSG_GEN_REMOVE_GEOMETRY_HINT,MSG_GEN_PATH_SET,MSG_GEN_PATH_GET,MSG_GEN_PATH_GET_DISK_HANDLE,MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER,MSG_GEN_GROW_PARENTS,MSG_GEN_GUP_ENSURE_UPDATE_WINDOW,MSG_GEN_GUP_FINISH_QUIT,MSG_GEN_REMOVE,MSG_GEN_DESTROY_AND_FREE_BLOCK,MSG_GEN_SET_KBD_OVERRIDE,MSG_GEN_SET_KBD_POSITION,MSG_GEN_FIND_OBJECT_WITH_TEXT_MONIKER_C,MSG_GEN_ROTATE_DISPLAY,MSG_GEN_TOGGLE_FLOATING_KBD,}GenMessages;


#endif

# 27 "/staff/pcgeos/CInclude/Objects/gAppC.goh"

#ifndef __GOCgInterC
#define __GOCgInterC

# 1 "/staff/pcgeos/CInclude/Objects/gInterC.goh"






















#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
#include <Objects/gInterC.h>

#define GenInteractionBase GenBase
#define _FIRST_GenInteractionClass 26624
# 25 "/staff/pcgeos/CInclude/Objects/gInterC.goh"


	

	


	



 
	
	

	
    	    	    	    	    	    	    
	
    	    	    	    	    	    	    









    #define HINT_INTERACTION_SINGLE_USAGE 26624

    #define HINT_INTERACTION_FREQUENT_USAGE 26628

    #define HINT_INTERACTION_COMPLEX_PROPERTIES 26632

    #define HINT_INTERACTION_SIMPLE_PROPERTIES 26636

    #define HINT_INTERACTION_RELATED_PROPERTIES 26640

    #define HINT_INTERACTION_UNRELATED_PROPERTIES 26644

    #define HINT_INTERACTION_SLOW_RESPONSE_PROPERTIES 26648

    #define HINT_INTERACTION_FAST_RESPONSE_PROPERTIES 26652

    #define HINT_INTERACTION_REQUIRES_VALIDATION 26656

    #define HINT_INTERACTION_MAKE_RESIZABLE 26660

    #define HINT_INTERACTION_CANNOT_BE_DEFAULT 26664

    #define HINT_INTERACTION_MODAL 26668

    #define HINT_INTERACTION_UNUSED_1 26672

    #define ATTR_GEN_INTERACTION_UNUSED_2 26676

    #define ATTR_GEN_INTERACTION_UNUSED_3 26680


    
    #define TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE 26684


    #define HINT_INTERACTION_NO_DISTURB 26688

    #define ATTR_GEN_INTERACTION_GROUP_TYPE 26692

    #define ATTR_GEN_INTERACTION_UNUSED_4 26696

    #define ATTR_GEN_INTERACTION_OVERRIDE_INPUT_RESTRICTIONS 26700

    #define ATTR_GEN_INTERACTION_ABIDE_BY_INPUT_RESTRICTIONS 26704


    #define HINT_INTERACTION_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD 26708


    #define HINT_INTERACTION_INFREQUENT_USAGE 26712

    #define HINT_CUSTOM_SYS_MENU 26716


    #define ATTR_GEN_INTERACTION_POPPED_OUT 26720


    
    #define TEMP_GEN_INTERACTION_SAVE_POPOUT_INFO 26724


    #define ATTR_GEN_INTERACTION_POPOUT_NOT_CLOSABLE 26728


    
    #define ATTR_GEN_INTERACTION_PEN_MODE_KEYBOARD_OBJECT 26732


    #define HINT_INTERACTION_MAXIMIZABLE 26736

    #define HINT_INTERACTION_POPOUT_HIDDEN_ON_STARTUP 26740

    #define TEMP_GEN_INTERACTION_POPOUT_HIDDEN 26744

    #define HINT_INTERACTION_DISCARD_WHEN_CLOSED 26748


    
    #define TEMP_INTERACTION_DISCARD_INFO 26752






    
    #define HINT_INTERACTION_ACTIVATED_BY 26756

    ;

    #define HINT_INTERACTION_FOCUSABLE 26760



    #define HINT_INTERACTION_FOLDER_TAB_DIALOG 26764


    #define HINT_INTERACTION_NOTEBOOK_STYLE 26768




    
    #define HINT_INTERACTION_ACTIVATOR_POINT 26772





    





    
    
    

extern ClassStruct _far GenInteractionClass; extern Message _Messages_GenInteractionClass[]; extern MessageMethod *_Methods_GenInteractionClass[]; extern CMethodDef _htypes_GenInteractionClass[];extern MessageMethod *_Reloc_GenInteractionClass;
typedef struct _GenInteractionInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;} GenInteractionInstance; 
# 137 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
typedef enum{MSG_GEN_INTERACTION_GET_TYPE=26624,MSG_GEN_INTERACTION_SET_TYPE,MSG_GEN_INTERACTION_GET_VISIBILITY,MSG_GEN_INTERACTION_SET_VISIBILITY,MSG_GEN_INTERACTION_GET_ATTRS,MSG_GEN_INTERACTION_SET_ATTRS,MSG_GEN_INTERACTION_ACTIVATE_COMMAND,MSG_GEN_INTERACTION_INITIATE,MSG_GEN_INTERACTION_INITIATE_NO_DISTURB,MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_RESPONSE,MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE,MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY=26636,MSG_GEN_INTERACTION_POP_OUT,MSG_GEN_INTERACTION_POP_IN,MSG_GEN_INTERACTION_TOGGLE_POPOUT,MSG_GEN_INTERACTION_DISABLE_DISCARDING,}GenInteractionMessages;


#endif

# 28 "/staff/pcgeos/CInclude/Objects/gAppC.goh"

#ifndef __GOCgProcC
#define __GOCgProcC
#include "/staff/pcgeos/CInclude/Objects/gProcC.poh"
#endif

# 29 "/staff/pcgeos/CInclude/Objects/gAppC.goh"

#define GenApplicationBase GenBase
#define _FIRST_GenApplicationClass 26624
# 30 "/staff/pcgeos/CInclude/Objects/gAppC.goh"


	
	
	
	
	
	
	
	



	

 

 

 
	
	

 
	
	
	
	
	



typedef struct {
    UIInterfaceLevel AFI_uiInterfaceLevel;
    word    AFI_appFeatures;
} AppFeaturesInfo;

#define GET_UI_INTERFACE_LEVEL(val) ((val).AFI_uiInterfaceLevel)
#define GET_APP_FEATURES(val) ((val).AFI_appFeatures)




	





 











  

    


     

	
	
	
	
	
	
	
 
	

#define GET_MEASUREMENT_TYPE(m) ((byte) (m))
#define GET_APP_MEASUREMENT_TYPE(m) ((byte) ((m)>>8))

typedef ByteEnum AppMeasurementType;
#define	AMT_US		0
#define AMT_METRIC	1
#define	AMT_DEFAULT	0xff




typedef struct {
    MeasurementType 	WMT_measurementType; 	
    AppMeasurementType	WMT_appMeasurementType;	
} WholeMeasurementType;

	

	

typedef struct {
    CharFlags	CFASS_charFlags;
    ShiftState	CFASS_shiftState;
} CharFlagsAndShiftState;

typedef struct {
    ToggleState	TSASC_toggleState;
    byte    	TSASC_scanCode;
} ToggleStateAndScanCode;




 




	
	

 

 
 

 

typedef struct {
    CustomDialogType	ND_dialogType;
    byte    	    	ND_unused1;
    word    	    	ND_unused2;
    optr    	    	ND_dialog;
} NewDialog;




    	    	    	    	    	

typedef ByteEnum GenAppUsabilityCommand;
#define GAUC_USABILITY 0




#define GAUC_RECALC_CONTROLLER 1




#define GAUC_REPARENT 2



#define GAUC_POPUP 3




#define GAUC_TOOLBAR 4





#define GAUC_RESTART 5





typedef ByteFlags GenAppUsabilityTupleFlags;
#define GAUTF_END_OF_LIST	0x20
#define GAUTF_OFF_IF_BIT_ON	0x10
#define GAUTF_COMMAND		0x0f

typedef struct {
    GenAppUsabilityTupleFlags	GAUT_flags;
    optr			GAUT_object;	
} GenAppUsabilityTuple;


























































































typedef enum  {
    TO_PRINT_CONTROL=_FIRST_GenApplicationClass
} GenApplicationTravelOption;

    #define HINT_APP_IS_ENTERTAINING 26624

    #define HINT_APP_IS_EDUCATIONAL 26628

    #define HINT_APP_IS_PRODUCTIVITY_ORIENTED 26632


    #define ATTR_GEN_APPLICATION_PRINT_CONTROL 26636

    ;

    #define TEMP_GEN_APPLICATION_NO_LONGER_USED 26640

    #define ATTR_GEN_APPLICATION_KBD_OBJ 26644

    ;
    #define TEMP_GEN_APPLICATION_SAVED_ALB 26648

    #define TEMP_GEN_APPLICATION_ABORT_QUIT 26652

    #define ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER 26656

    ;

typedef struct {
    Boolean FKI_defaultPosition;
    Boolean FKI_sysModal;
} FloatingKeyboardInfo;

    #define TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO 26660

    #define TEMP_GEN_APPLICATION_EXTRA_STATE_BLOCK 26664

    #define TEMP_GEN_APPLICATION_APP_MODE_COMPLETE_ACK_OD 26668

    #define ATTR_GEN_APPLICATION_ADDITIONAL_TOKENS 26672

    #define HINT_APPLICATION_NO_INBOX_QUERY_WHEN_FOREGROUND_APP 26676

    #define HINT_APPLICATION_QUIT_ON_IACP_ALLOW_FILE_ACCESS 26680



    #define TEMP_GEN_APPLICATION_CLOSE_FILE_ACK_EVENT 26684




    #define TEMP_GEN_APPLICATION_DISPLAY_MODE 26688



typedef WordFlags ApplicationStates;
#define AS_TRANSPARENT			0x4000
#define AS_HAS_FULL_SCREEN_EXCL		0x2000
#define AS_SINGLE_INSTANCE		0x1000
#define AS_QUIT_DETACHING		0x0800
#define AS_AVOID_TRANSPARENT_DETACH	0x0400
#define AS_TRANSPARENT_DETACHING	0x0200
#define AS_REAL_DETACHING		0x0100
#define AS_QUITTING			0x0080
#define AS_DETACHING			0x0040
#define AS_FOCUSABLE			0x0020
#define AS_MODELABLE			0x0010
#define AS_NOT_USER_INTERACTABLE	0x0008
#define AS_RECEIVED_APP_OBJECT_DETACH	0x0004
#define AS_ATTACHED_TO_STATE_FILE	0x0002
#define AS_ATTACHING			0x0001

typedef ByteFlags AppOptFlags;
#define AOF_MULTIPLE_INIT_FILE_CATEGORIES	0x80
typedef AppOptFlags ApplicationOptFlags;


    

    
    
    
    
    
    
    
    
    

    
    

extern ClassStruct _far GenApplicationClass; extern Message _Messages_GenApplicationClass[]; extern MessageMethod *_Methods_GenApplicationClass[]; extern CMethodDef _htypes_GenApplicationClass[];extern MessageMethod *_Reloc_GenApplicationClass;
typedef struct _GenApplicationInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 360 "/staff/pcgeos/CInclude/Objects/gAppC.goh"
    AppInstanceReference GAI_appRef;

    Message GAI_appMode;
    AppLaunchFlags GAI_launchFlags;
    ApplicationOptFlags GAI_optFlags;
    word GAI_appFeatures;
    Handle GAI_specificUI;
    ApplicationStates GAI_states;
    AppAttachFlags GAI_attachFlags;
    UIInterfaceLevel GAI_appLevel;
    ChunkHandle GAI_iacpConnects;} GenApplicationInstance; 
# 375 "/staff/pcgeos/CInclude/Objects/gAppC.goh"
typedef enum{MSG_GEN_APPLICATION_MARK_BUSY=26624,MSG_GEN_APPLICATION_MARK_NOT_BUSY,MSG_GEN_APPLICATION_HOLD_UP_INPUT,MSG_GEN_APPLICATION_RESUME_INPUT,MSG_GEN_APPLICATION_IGNORE_INPUT,MSG_GEN_APPLICATION_ACCEPT_INPUT,MSG_GEN_APPLICATION_QUERY_UI,MSG_GEN_APPLICATION_GET_STATE,MSG_GEN_APPLICATION_FIND_MONIKER,MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER,MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME,MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE,MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE,MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE,MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE,MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE_TO_FIELD,MSG_GEN_APPLICATION_INITIATE_UI_QUIT,MSG_GEN_APPLICATION_INSTALL_TOKEN,MSG_GEN_APPLICATION_TOGGLE_CURSOR,MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS,MSG_GEN_APPLICATION_SET_APP_LEVEL,MSG_GEN_APPLICATION_GET_APP_FEATURES,MSG_GEN_APPLICATION_SET_APP_FEATURES,MSG_GEN_APPLICATION_DETACH_PENDING,MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG,MSG_GEN_APPLICATION_UNUSED,MSG_GEN_APPLICATION_DO_STANDARD_DIALOG,MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY,MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY,MSG_GEN_APPLICATION_OPEN_COMPLETE,MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE,MSG_GEN_APPLICATION_SET_USER_INTERACTABLE,MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE,MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE,MSG_GEN_APPLICATION_SET_NOT_QUITTING,MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE,MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE,MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE,MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC,MSG_GEN_APPLICATION_INK_QUERY_REPLY,MSG_GEN_APPLICATION_GCN_LIST_SEND_INTERNAL,MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS,MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION=26667,MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP,MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM,MSG_GEN_APPLICATION_GET_ATTACH_FLAGS,MSG_GEN_APPLICATION_BUILD_DIALOG_FROM_TEMPLATE,MSG_GEN_APPLICATION_UPDATE_APP_FEATURES,MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE,MSG_GEN_APPLICATION_IACP_NO_MORE_CONNECTIONS,MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS,MSG_GEN_APPLICATION_APP_MODE_COMPLETE,MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS,MSG_GEN_APPLICATION_IACP_REGISTER,MSG_GEN_APPLICATION_IACP_UNREGISTER,MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS,MSG_GEN_APPLICATION_BRING_UP_HELP=26685,MSG_GEN_APPLICATION_UNUSED_3,MSG_GEN_APPLICATION_UNUSED_4,MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR,MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD,MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU,MSG_GEN_APPLICATION_GET_MODAL_WIN=26692,MSG_GEN_APPLICATION_UNUSED_2,MSG_GEN_APPLICATION_CHECK_IF_ALWAYS_INTERACTABLE_OBJECT,MSG_GEN_APPLICATION_SET_STATE,MSG_GEN_APPLICATION_QUIT_AFTER_UI,MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS,MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG,MSG_GEN_APPLICATION_FLOATING_KEYBOARD_CLOSED,MSG_GEN_APPLICATION_GET_TRANSPARENT_DETACH_LIST,MSG_GEN_APPLICATION_CLOSE_COMPLETE,MSG_GEN_APPLICATION_FIELD_QUIT_ABORTED,MSG_GEN_APPLICATION_REMOVE_ALL_BLOCKING_DIALOGS,MSG_GEN_APPLICATION_GET_FLOATING_KEYBOARD_OD,MSG_GEN_APPLICATION_ROTATE_DISPLAY,MSG_GEN_APPLICATION_CLOSE_FILE_ACK,MSG_GEN_APPLICATION_CHANGE_DISPLAY_MODE,}GenApplicationMessages;



#endif

# 48 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgPrimC
#define __GOCgPrimC

# 1 "/staff/pcgeos/CInclude/Objects/gPrimC.goh"






















#ifndef __GOCgDispC
#define __GOCgDispC

# 1 "/staff/pcgeos/CInclude/Objects/gDispC.goh"






















#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gDispC.goh"

#define GenDisplayBase GenBase
#define _FIRST_GenDisplayClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gDispC.goh"












	








    #define HINT_DISPLAY_MINIMIZED_ON_STARTUP 26624

    #define HINT_DISPLAY_NOT_MINIMIZED_ON_STARTUP 26628

    #define HINT_DISPLAY_MAXIMIZED_ON_STARTUP 26632

    #define HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP 26636


typedef struct {
	optr		TIR_travelingObject;
	ChunkHandle	TIR_parent;
	word		TIR_compChildFlags;
} TravelingObjectReference;

    #define ATTR_GEN_DISPLAY_TRAVELING_OBJECTS 26640


    #define ATTR_GEN_DISPLAY_NOT_MINIMIZABLE 26644

    #define ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE 26648

    #define ATTR_GEN_DISPLAY_NOT_RESTORABLE 26652


    #define ATTR_GEN_DISPLAY_MINIMIZED_STATE 26656

    #define ATTR_GEN_DISPLAY_MAXIMIZED_STATE 26660


    #define HINT_DISPLAY_NOT_RESIZABLE 26664


    #define ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT 26668


    
    #define TEMP_GEN_DISPLAY_SAVE_POPOUT_MENU_BAR_INFO 26672


    #define HINT_DISPLAY_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD 26676


    #define HINT_DISPLAY_USE_APPLICATION_MONIKER_WHEN_MINIMIZED 26680


    #define HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP 26684


    #define TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN 26688


    #define HINT_DISPLAY_USE_APPLICATION_MONIKER_WHEN_MENU_BAR_POPPED_OUT 26692


typedef ByteFlags GenDisplayAttrs;
#define GDA_USER_DISMISSABLE	0x80

    
    

    
extern ClassStruct _far GenDisplayClass; extern Message _Messages_GenDisplayClass[]; extern MessageMethod *_Methods_GenDisplayClass[]; extern CMethodDef _htypes_GenDisplayClass[];extern MessageMethod *_Reloc_GenDisplayClass;
typedef struct _GenDisplayInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 85 "/staff/pcgeos/CInclude/Objects/gDispC.goh"
    GenDisplayAttrs GDI_attributes;
    optr GDI_document;} GenDisplayInstance; 
# 89 "/staff/pcgeos/CInclude/Objects/gDispC.goh"
typedef enum{MSG_GEN_DISPLAY_SET_MINIMIZED=26624,MSG_GEN_DISPLAY_SET_NOT_MINIMIZED,MSG_GEN_DISPLAY_GET_MINIMIZED,MSG_GEN_DISPLAY_SET_MAXIMIZED,MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED,MSG_GEN_DISPLAY_GET_MAXIMIZED,MSG_GEN_DISPLAY_SET_ATTRS,MSG_GEN_DISPLAY_GET_ATTRS,MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT,MSG_GEN_DISPLAY_GET_DOCUMENT,MSG_GEN_DISPLAY_CLOSE,MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING,MSG_GEN_DISPLAY_INTERNAL_SET_FULL_SIZED,}GenDisplayMessages;



#endif

# 23 "/staff/pcgeos/CInclude/Objects/gPrimC.goh"

#define GenPrimaryBase GenDisplayBase
#define _FIRST_GenPrimaryClass 27136
# 24 "/staff/pcgeos/CInclude/Objects/gPrimC.goh"











    #define HINT_PRIMARY_FULL_SCREEN 27136

    #define HINT_PRIMARY_NO_FILE_MENU 27140

    #define HINT_PRIMARY_NO_EXPRESS_MENU 27144

    #define HINT_PRIMARY_OPEN_ICON_BOUNDS 27148

    #define HINT_PRIMARY_NO_HELP_BUTTON 27152


    

    

extern ClassStruct _far GenPrimaryClass; extern Message _Messages_GenPrimaryClass[]; extern MessageMethod *_Methods_GenPrimaryClass[]; extern CMethodDef _htypes_GenPrimaryClass[];extern MessageMethod *_Reloc_GenPrimaryClass;
typedef struct _GenPrimaryInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 85 "/staff/pcgeos/CInclude/Objects/gDispC.goh"
    GenDisplayAttrs GDI_attributes;
    optr GDI_document;
# 41 "/staff/pcgeos/CInclude/Objects/gPrimC.goh"
    ChunkHandle GPI_longTermMoniker;} GenPrimaryInstance; 
# 45 "/staff/pcgeos/CInclude/Objects/gPrimC.goh"
typedef enum{MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER=27136,MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER,MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER,}GenPrimaryMessages;



#endif

# 49 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgTrigC
#define __GOCgTrigC

# 1 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"





















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 22 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"

#define GenTriggerBase GenBase
#define _FIRST_GenTriggerClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"



 
	
	
  
   
   



    #define HINT_TRIGGER_BRINGS_UP_WINDOW 26624

    #define ATTR_GEN_TRIGGER_IMMEDIATE_ACTION 26628

    #define HINT_TRIGGER_UNUSED 26632

    #define ATTR_GEN_TRIGGER_ACTION_DATA 26636

    #define ATTR_GEN_TRIGGER_INTERACTION_COMMAND 26640

    #define ATTR_GEN_TRIGGER_CUSTOM_DOUBLE_PRESS 26644

    #define HINT_TRIGGER_UNUSED1 26648

    #define HINT_TRIGGER_UNUSED2 26652

    #define HINT_TRIGGER_UNUSED3 26656

    #define HINT_TRIGGER_UNUSED4 26660

    #define HINT_TRIGGER_DESTRUCTIVE_ACTION 26664


    #define HINT_TRIGGER_BLANK_STYLE_BUTTON 26668

    #define HINT_TRIGGER_TOOL_STYLE_BUTTON 26672

    #define HINT_TRIGGER_WINDOW_CONTROL_BUTTON 26676

    #define HINT_TRIGGER_EDGE_STYLE_UPPER_RIGHT 26680

    #define HINT_TRIGGER_EDGE_STYLE_LOWER_RIGHT 26684

    #define HINT_TRIGGER_COMMAND_STYLE_BUTTON 26688


     
        


    

      

    

    typedef struct { word foo, foo2; } TwoWordArgs;
    
#define ATTR_GEN_TRIGGER_ACTION_TWO_WORDS 26636;

    

    typedef struct { word foo, foo2, foo3; } ThreeWordArgs;
    
#define ATTR_GEN_TRIGGER_ACTION_THREE_WORDS 26636;

    

    typedef struct { optr output; word foo; } OptrWordArgs;
    
#define ATTR_GEN_TRIGGER_ACTION_OPTR_AND_WORD 26636;


extern ClassStruct _far GenTriggerClass; extern Message _Messages_GenTriggerClass[]; extern MessageMethod *_Methods_GenTriggerClass[]; extern CMethodDef _htypes_GenTriggerClass[];extern MessageMethod *_Reloc_GenTriggerClass;
typedef struct _GenTriggerInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 55 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"
    optr GTI_destination;
    Message GTI_actionMsg;} GenTriggerInstance; 
# 82 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"
typedef enum{MSG_GEN_TRIGGER_SEND_ACTION=26624,MSG_GEN_TRIGGER_GET_ACTION_MSG,MSG_GEN_TRIGGER_SET_ACTION_MSG,MSG_GEN_TRIGGER_SET_DESTINATION,MSG_GEN_TRIGGER_GET_DESTINATION,MSG_GEN_TRIGGER_MAKE_DEFAULT_ACTION,}GenTriggerMessages;




#endif

# 50 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgViewC
#define __GOCgViewC

# 1 "/staff/pcgeos/CInclude/Objects/gViewC.goh"





















#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 22 "/staff/pcgeos/CInclude/Objects/gViewC.goh"
#include <win.h>

#define GenViewBase GenBase
#define _FIRST_GenViewClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gViewC.goh"


#define GVCD_INDEX(val) 	((byte) (val))
#define GVCD_RED(val) 		((byte) (val))	
#define GVCD_FLAGS(val) 	((byte) ((val) >> 8))
#define GVCD_BLUE_AND_GREEN(val)  ((word) ((val) >> 16))

#define GVCD_BLUE(val) 		((byte) ((val) >> 16))
#define GVCD_GREEN(val) 	((byte) ((val) >> 24))

typedef WordFlags MakeRectVisibleFlags;
#define MRVF_ALWAYS_SCROLL		0x0080
#define MRVF_USE_MARGIN_FROM_TOP_LEFT	0x0040

typedef enum  {
    MRVM_0_PERCENT  	= 0,
    MRVM_25_PERCENT 	= 0xffff/4,
    MRVM_50_PERCENT 	= 0xffff/2,
    MRVM_75_PERCENT 	= 0xffff*3/4,
    MRVM_100_PERCENT	= 0xffff
} MakeRectVisibleMargin;

typedef ByteEnum ScaleViewType;
#define SVT_AROUND_UPPER_LEFT 0
#define SVT_AROUND_CENTER 1
#define SVT_AROUND_POINT 2

typedef struct {
    optr	TR_object;
    ClassStruct	*TR_class;
} TargetReference;

typedef struct {
    TargetReference	VTI_target;
    TargetReference	VTI_content;
} ViewTargetInfo;

typedef ByteEnum ScrollAction;
#define SA_NOTHING 0
#define SA_TO_BEGINNING 1
#define SA_PAGE_BACK 2
#define SA_INC_BACK 3
#define SA_INC_FWD 4
#define SA_DRAGGING 5
#define SA_PAGE_FWD 6
#define SA_TO_END 7
#define SA_SCROLL 8
#define SA_SCROLL_INTO 9
#define SA_INITIAL_POS 10
#define SA_SCALE 11
#define SA_PAN 12
#define SA_DRAG_SCROLL 13
#define SA_SCROLL_FOR_SIZE_CHANGE 14

typedef ByteFlags ScrollFlags;
#define SF_VERTICAL		0x80
#define SF_ABSOLUTE		0x40
#define SF_DOC_SIZE_CHANGE	0x20
#define SF_WINDOW_NOT_SUSPENDED	0x10
#define SF_SCALE_TO_FIT		0x08
#define SF_SETUP_HAPPENED	0x04
#define SF_EC_SETUP_CALLED	0x02	

typedef struct {
    ScrollAction	TSP_action;
    ScrollFlags		TSP_flags;
    optr		TSP_caller;
    PointDWord		TSP_change;
    PointDWord		TSP_newOrigin;
    PointDWord		TSP_oldOrigin;
    sword		TSP_viewWidth;
    sword		TSP_viewHeight;
} TrackScrollingParams;

#define VS_TYPICAL 0x8000
#define VS_SMALL 0x8001
#define VS_LARGE 0x8002


typedef WordFlags GenViewAttrs;
#define GVA_CONTROLLED				0x8000
#define GVA_GENERIC_CONTENTS			0x4000
#define GVA_TRACK_SCROLLING			0x2000
#define GVA_DRAG_SCROLLING			0x1000
#define GVA_NO_WIN_FRAME			0x0800
#define GVA_SAME_COLOR_AS_PARENT_WIN		0x0400
#define GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY	0x0200
#define GVA_WINDOW_COORDINATE_MOUSE_EVENTS	0x0100
#define GVA_DONT_SEND_PTR_EVENTS		0x0080
#define GVA_DONT_SEND_KBD_RELEASES		0x0040
#define GVA_SEND_ALL_KBD_CHARS			0x0020
#define GVA_FOCUSABLE				0x0010
#define GVA_SCALE_TO_FIT			0x0008
#define GVA_ADJUST_FOR_ASPECT_RATIO		0x0004

typedef ByteFlags GenViewDimensionAttrs;
#define GVDA_SCROLLABLE				0x80
#define GVDA_SPLITTABLE				0x40
#define GVDA_TAIL_ORIENTED			0x20
#define GVDA_DONT_DISPLAY_SCROLLBAR		0x10
#define GVDA_NO_LARGER_THAN_CONTENT		0x08
#define GVDA_NO_SMALLER_THAN_CONTENT		0x04
#define GVDA_SIZE_A_MULTIPLE_OF_INCREMENT	0x02
#define GVDA_KEEP_ASPECT_RATIO			0x01


  

  

  







 






typedef struct {
	WWFixedAsDWord GSP_yScaleFactor;
	WWFixedAsDWord GSP_xScaleFactor;
} GetScaleParams;

 

  

   

  

  

  


  

  

  


  

  

#define MAKE_HORIZ_ATTRS(val) ((byte) (val))
#define MAKE_VERT_ATTRS(val) ((byte) ((val) >> 8))
#define MAKE_SET_CLEAR_ATTRS(setAttrs, clrAttrs)	\
			( (((word) (clrAttrs)) << 8) | (setAttrs))

  

typedef struct {
    VisUpdateMode   VUMAW_mode;
    byte    	    VUMAW_unused;
} VisUpdateModeAsWord;




  


  

  


  


  

  

  

typedef struct {
    GenViewDimensionAttrs   DA_horizAttrs;
    GenViewDimensionAttrs   DA_verAttrs;
} DimensionAttrs; 

   

typedef struct {
    GenViewDimensionAttrs   DATSC_attrsToSet;
    GenViewDimensionAttrs   DATSC_attrsToClear;
} DimensionAttrsToSetClear; 





   
   

  

   

  

#define VERTICAL_VIEW_BASE_MESSAGE  MSG_GEN_VIEW_SCROLL_TOP

  
  
   
  
  

   

#define HORIZONTAL_VIEW_BASE_MESSAGE  MSG_GEN_VIEW_SCROLL_LEFT_EDGE

   


  

   

   

  

  

   

   

  


#define GVSOL_NO_CHANGE		0x8000000

typedef ByteEnum GenViewInkType;
#define GVIT_PRESSES_ARE_NOT_INK 0
#define GVIT_INK_WITH_STANDARD_OVERRIDE 1
#define GVIT_PRESSES_ARE_INK 2
#define GVIT_QUERY_OUTPUT 3



















#define HINT_VIEW_LEAVE_ROOM_FOR_VERT_SCROLLER 26624

#define HINT_VIEW_LEAVE_ROOM_FOR_HORIZ_SCROLLER 26628


typedef struct {
    optr    IDIP_dest;
    word    IDIP_brushSize;
    Color   IDIP_color;
    byte    IDIP_reserved1;	
    Boolean IDIP_createGState;
} InkDestinationInfoParams;

#define ATTR_GEN_VIEW_INK_DESTINATION_INFO 26632


#define ATTR_GEN_VIEW_PAGE_SIZE 26636


#define ATTR_GEN_VIEW_SCALE_TO_FIT_BASED_ON_X 26640


#define ATTR_GEN_VIEW_SCALE_TO_FIT_BOTH_DIMENSIONS 26644


#define ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL 26648


#define HINT_VIEW_IMMEDIATE_DRAG_UPDATES 26652

#define HINT_VIEW_DELAYED_DRAG_UPDATES 26656


#define HINT_VIEW_REMOVE_SCROLLERS_WHEN_NOT_SCROLLABLE 26660

#define HINT_VIEW_SHOW_SCROLLERS_WHEN_NOT_SCROLLABLE 26664


#define HINT_VIEW_SHARES_SPACE_WITH_VIEW_ABOVE 26668

#define HINT_VIEW_SHARES_SPACE_WITH_VIEW_BELOW 26672

#define HINT_VIEW_SHARES_SPACE_WITH_VIEW_TO_LEFT 26676

#define HINT_VIEW_SHARES_SPACE_WITH_VIEW_TO_RIGHT 26680

#define ATTR_GEN_VIEW_DOES_NOT_ACCEPT_TEXT_INPUT 26684




    
    
    
    
    
    
    
    
    
    
    
    

    

    ;
extern ClassStruct _far GenViewClass; extern Message _Messages_GenViewClass[]; extern MessageMethod *_Methods_GenViewClass[]; extern CMethodDef _htypes_GenViewClass[];extern MessageMethod *_Reloc_GenViewClass;
typedef struct _GenViewInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 330 "/staff/pcgeos/CInclude/Objects/gViewC.goh"
    PointDWFixed GVI_origin;
    RectDWord GVI_docBounds;
    PointDWord GVI_increment;
    PointWWFixed GVI_scaleFactor;
    ColorQuad GVI_color;
    GenViewAttrs GVI_attrs;
    GenViewDimensionAttrs GVI_horizAttrs;
    GenViewDimensionAttrs GVI_vertAttrs;
    GenViewInkType GVI_inkType;
    optr GVI_content;
    optr GVI_horizLink;
    optr GVI_vertLink;} GenViewInstance; 
# 346 "/staff/pcgeos/CInclude/Objects/gViewC.goh"
typedef enum{MSG_GEN_VIEW_GET_ORIGIN=26624,MSG_GEN_VIEW_SET_ORIGIN,MSG_GEN_VIEW_SCROLL,MSG_GEN_VIEW_MAKE_RECT_VISIBLE,MSG_GEN_VIEW_SET_SCALE_FACTOR,MSG_GEN_VIEW_GET_SCALE_FACTOR,MSG_GEN_VIEW_SET_CONTENT,MSG_GEN_VIEW_GET_CONTENT,MSG_GEN_VIEW_GET_WINDOW,MSG_GEN_VIEW_GET_VISIBLE_RECT,MSG_GEN_VIEW_GET_INCREMENT,MSG_GEN_VIEW_SET_INCREMENT,MSG_GEN_VIEW_SUSPEND_UPDATE,MSG_GEN_VIEW_UNSUSPEND_UPDATE,MSG_GEN_VIEW_SET_DOC_BOUNDS,MSG_GEN_VIEW_GET_DOC_BOUNDS,MSG_GEN_VIEW_GET_ATTRS,MSG_GEN_VIEW_SET_ATTRS,MSG_GEN_VIEW_SET_COLOR,MSG_GEN_VIEW_GET_COLOR,MSG_GEN_VIEW_CALC_WIN_SIZE,MSG_GEN_VIEW_SET_PTR_IMAGE,MSG_GEN_VIEW_UPDATE_CONTENT_TARGET_INFO,MSG_GEN_VIEW_INITIATE_DRAG_SCROLL,MSG_GEN_VIEW_GET_DIMENSION_ATTRS,MSG_GEN_VIEW_SET_DIMENSION_ATTRS,MSG_GEN_VIEW_SCROLL_TOP,MSG_GEN_VIEW_SCROLL_PAGE_UP,MSG_GEN_VIEW_SCROLL_UP,MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN,MSG_GEN_VIEW_SCROLL_DOWN,MSG_GEN_VIEW_SCROLL_PAGE_DOWN,MSG_GEN_VIEW_SCROLL_BOTTOM,MSG_GEN_VIEW_SCROLL_LEFT_EDGE,MSG_GEN_VIEW_SCROLL_PAGE_LEFT,MSG_GEN_VIEW_SCROLL_LEFT,MSG_GEN_VIEW_SCROLL_SET_X_ORIGIN,MSG_GEN_VIEW_SCROLL_RIGHT,MSG_GEN_VIEW_SCROLL_PAGE_RIGHT,MSG_GEN_VIEW_SCROLL_RIGHT_EDGE,MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER,MSG_GEN_VIEW_SET_DRAG_BOUNDS,MSG_GEN_VIEW_SETUP_TRACKING_ARGS,MSG_GEN_VIEW_TRACKING_COMPLETE,MSG_GEN_VIEW_DETERMINE_VIS_PARENT,MSG_GEN_VIEW_SEND_TO_LINKS,MSG_GEN_VIEW_SEND_TO_VLINK,MSG_GEN_VIEW_SEND_TO_HLINK,MSG_GEN_VIEW_CALL_WITHOUT_LINKS,MSG_GEN_VIEW_SET_ORIGIN_LOW,MSG_GEN_VIEW_SET_INK_TYPE,MSG_GEN_VIEW_SET_EXTENDED_INK_TYPE,MSG_GEN_VIEW_RESET_EXTENDED_INK_TYPE,MSG_GEN_VIEW_SEND_NOTIFICATION,MSG_GEN_VIEW_SCALE_LOW,MSG_GEN_VIEW_REDRAW_CONTENT,MSG_GEN_VIEW_SET_CONTROLLED_ATTRS,}GenViewMessages;


#endif

# 51 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgTextC
#define __GOCgTextC

# 1 "/staff/pcgeos/CInclude/Objects/gTextC.goh"





















#include <Objects/Text/tCommon.h>

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gTextC.goh"

#ifndef __GOCvTextC
#define __GOCvTextC

# 1 "/staff/pcgeos/CInclude/Objects/vTextC.goh"
























#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/vTextC.goh"
#include <Objects/Text/tCommon.h>


#ifndef __GOCvisC
#define __GOCvisC
#include "/staff/pcgeos/CInclude/Objects/visC.poh"
#endif

# 28 "/staff/pcgeos/CInclude/Objects/vTextC.goh"

#ifndef __GOCgCtrlC
#define __GOCgCtrlC

# 1 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"






















#ifndef __GOCgInterC
#define __GOCgInterC
#include "/staff/pcgeos/CInclude/Objects/gInterC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"

#ifndef __GOCgcnlist
#define __GOCgcnlist

# 1 "/staff/pcgeos/CInclude/gcnlist.goh"























#include <lmem.h>	
#include <file.h>	

#ifndef __GOCmetaC
#define __GOCmetaC
#include "/staff/pcgeos/CInclude/Objects/metaC.poh"
#endif

# 27 "/staff/pcgeos/CInclude/gcnlist.goh"













typedef	struct {
    LMemBlockHeader	GCNLBH_lmemHeader;
    ChunkHandle 	GCNLBH_listOfLists;
} GCNListBlockHeader;





extern Boolean
    _pascal GCNListAdd(optr OD, ManufacturerID manufID, word listType);

#define GCNListAddHandles(mh, ch, mid, lt) \
		GCNListAdd(ConstructOptr(mh, ch), mid, lt)

extern Boolean
    _pascal GCNListRemove(optr OD, ManufacturerID manufID, word listType);

#define GCNListRemoveHandles(mh, ch, mid, lt) \
		GCNListRemove(ConstructOptr(mh, ch), mid, lt)


extern word	
    _pascal GCNListSend(ManufacturerID manufID, word listType, EventHandle event,
		MemHandle dataBlock, GCNListSendFlags gcnListSendFlags);





extern ChunkHandle
    _pascal GCNListCreateBlock(MemHandle mh);

extern Boolean
    _pascal GCNListAddToBlock(optr OD, ManufacturerID manufID, word listType,
		      MemHandle mh, ChunkHandle listOfLists);

extern Boolean
    _pascal GCNListRemoveFromBlock(optr OD, ManufacturerID manufID, word listType,
			   MemHandle mh, ChunkHandle listOfLists);

extern word
    _pascal GCNListSendToBlock(ManufacturerID manufID, word listType,
		       EventHandle event, MemHandle dataBlock, MemHandle mh,
		       ChunkHandle listOfLists, GCNListSendFlags flags);

extern ChunkHandle
    _pascal GCNListFindListInBlock(ManufacturerID manufID, word changeType,
			   MemHandle mh, ChunkHandle listOfLists,
			   Boolean createIfNotFound);

extern void
    _pascal GCNListDestroyBlock(MemHandle mh, ChunkHandle listOfLists);

extern void
    _pascal GCNListRelocateBlock(MemHandle mh, ChunkHandle listOfLists,
				MemHandle relocBlock);

extern Boolean
    _pascal GCNListUnRelocateBlock(MemHandle mh, ChunkHandle listOfLists,
				MemHandle relocBlock);



extern ChunkHandle
    _pascal GCNListCreateList(MemHandle mh);

extern Boolean
    _pascal GCNListAddToList(optr OD, optr list);

#define GCNListAddToListODHandles(mh, ch, list) \
		GCNListAddToList(ConstructOptr(mh, ch), list)

#define GCNListAddToListListHandles(OD, listmh, listch) \
		GCNListAddToList(OD, ConstructOptr(listmh, listch))

#define GCNListAddToListODListHandles(mh, ch, listmh, listch) \
		GCNListAddToList(ConstructOptr(mh, ch), ConstructOptr(listmh, listch))

extern Boolean
    _pascal GCNListRemoveFromList(optr OD, optr list);

#define GCNListRemoveFromListODHandles(mh, ch, list) \
		GCNListRemoveFromList(ConstructOptr(mh, ch), list)

#define GCNListRemoveFromListListHandles(OD, listmh, listch) \
		GCNListRemoveFromList(OD, ConstructOptr(listmh, listch))

#define GCNListRemoveFromListODListHandles(mh, ch, listmh, listch) \
		GCNListRemoveFromList(ConstructOptr(mh, ch), ConstructOptr(listmh, listch))

extern void
    _pascal GCNListSendToList(optr list, EventHandle event, MemHandle dataBlock,
		      GCNListSendFlags flags);

#define GCNListSendToListHandles(mh, ch, ev, db, fl) \
		GCNListSendToList(ConstructOptr(mh, ch), ev, db, fl)

extern Boolean	
    _pascal GCNListFindItemInList(optr OD, optr list);

#define GCNListFindItemInListODHandles(mh, ch, list) \
		GCNListFindItemInList(ConstructOptr(mh, ch), list)

#define GCNListFindItemInListListHandles(OD, listmh, listch) \
		GCNListFindItemInList(OD, ConstructOptr(listmh, listch))

#define GCNListFindItemInListODListHandles(mh, ch, listmh, listch) \
		GCNListFindItemInList(ConstructOptr(mh, ch), ConstructOptr(listmh, listch))

extern void
    _pascal GCNListDestroyList(optr list);

#define GCNListDestroyListHandles(listmh, listch) \
		GCNListDestroyList(ConstructOptr(listmh, listch))

extern void
    _pascal GCNListRelocateList(optr list, MemHandle relocBlock);

extern void
    _pascal GCNListUnRelocateList(optr list, MemHandle relocBlock);

#define GCNListRelocateListHandles(lishmh, listch, rBlk) \
		GCNListRelocateList(ConstructOptr(listhmh, listhch, rBlk))

#define GCNListUnRelocateListHandles(lishmh, listch, rBlk) \
		GCNListUnRelocateList(ConstructOptr(listhmh, listhch, rBlk))




typedef enum {
    GCNSLT_FILE_SYSTEM=0,
    GCNSLT_APPLICATION=2,
    GCNSLT_DATE_TIME=4,
    GCNSLT_DICTIONARY=6,
    GCNSLT_KEYBOARD_OBJECTS=8,
    GCNSLT_EXPRESS_MENU_CHANGE=10,
    GCNSLT_INSTALLED_PRINTERS=12,
    GCNSLT_SHUTDOWN_CONTROL=14,
    GCNSLT_TRANSFER_NOTIFICATION=16,
    GCNSLT_EXPRESS_MENU_OBJECTS=18,
    GCNSLT_TRANSPARENT_DETACH=20,
    GCNSLT_TRANSPARENT_DETACH_DA=22,
    GCNSLT_REMOVABLE_DISK=24,
    GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS=26,
    GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL=28,
    GCNSLT_EMAIL_DATABASE_CHANGE=30,
    GCNSLT_FONT_CHANGES=32,
    GCNSLT_INK=34,
    GCNSLT_PRINT_JOB_STATUS=36,
    GCNSLT_FOAM_DB_CHANGES=38,
    GCNSLT_NOTIFY_SERIAL_LURKER=40,
    GCNSLT_FAX_INFO_FILE_CHANGE=42,
    GCNSLT_NOTIFY_INIT_FILE_CHANGE=44,
    GCNSLT_NOTIFY_KEYBOARD_EVENT=46,
    GCNSLT_NOTIFY_INDICATOR_EVENT=48,
    GCNSLT_CONTACT_LIST_SELECTION=50,
    GCNSLT_CONTACT_LOG_CHANGES=52,
    GCNSLT_RESPONDER_NOTIFICATIONS=54,
    GCNSLT_ACCESS_POINT_CHANGE=56,
    GCNSLT_PCMCIA_NOTIFY_CARD_CHANGE=58,
    GCNSLT_SECURITY_SETTINGS_NOTIFICATIONS=60,
    GCNSLT_PENELOPE_HARDWARE_NOTIFICATIONS=62
} GCNStandardListType;



typedef enum {
    FCNT_CREATE, FCNT_RENAME, FCNT_OPEN, FCNT_DELETE, FCNT_CONTENTS,
    FCNT_ATTRIBUTES, FCNT_DISK_FORMAT, FCNT_CLOSE, FCNT_BATCH
} FileChangeNotificationType;

typedef struct {
    word    	    FCND_disk; 	
    FileID  	    FCND_id;   	

    FileLongName    FCND_name;	

} FileChangeNotificationData;

typedef struct {
    FileChangeNotificationType	FCBNI_type;
    word    	    	    	FCBNI_disk;
    FileID  	    	    	FCBNI_id;
    FileLongName    	    	FCBNI_name; 


} FileChangeBatchNotificationItem;

typedef struct {    
    word    	    	    	    FCBND_end;   	

    FileChangeBatchNotificationItem FCBND_notifications[1]; 

} FileChangeBatchNotificationData;
    
typedef enum {
    GCNDCNT_CREATED,
    GCNDCNT_DESTROYED
} GCNDriveChangeNotificationType;



#define MSG_NOTIFY_FILE_CHANGE 693



#define MSG_NOTIFY_DRIVE_CHANGE 694

#define MSG_NOTIFY_APP_STARTED 695

#define MSG_NOTIFY_APP_EXITED 696

#define MSG_NOTIFY_DATE_TIME_CHANGE 697



#define MSG_NOTIFY_USER_DICT_CHANGE 698

#define MSG_NOTIFY_KEYBOARD_LAYOUT_CHANGE 699

typedef enum {
    GCNEMNT_CREATED,
    GCNEMNT_DESTROYED
} GCNExpressMenuNotificationTypes;



#define MSG_NOTIFY_EXPRESS_MENU_CHANGE 700

#define MSG_PRINTER_INSTALLED_REMOVED 701

typedef enum {
    GCNSCT_SUSPEND,
    GCNSCT_SHUTDOWN,
    GCNSCT_UNSUSPEND
} GCNShutdownControlType;



#define MSG_META_CONFIRM_SHUTDOWN 702



#define MSG_META_CONFIRM_SHUTDOWN_QUERY MSG_META_CONFIRM_SHUTDOWN

#define MSG_NOTIFY_INK_REDISPLAY 703
#define MSG_PRINT_DIALOG_INITIALIZED 704
#define MSG_PRINT_JOB_CANCELLED 705

typedef enum {
	PSCT_NEW_PAGE,	
	PSCT_COMPLETE,	
	PSCT_CANCELED,	
	PSCT_ERROR	
} PrintStatusChangeType;




#define MSG_PRINT_STATUS_CHANGE 706




#ifdef __HIGHC__
pragma Alias(GCNListAdd, "GCNLISTADD");
pragma Alias(GCNListRemove, "GCNLISTREMOVE");
pragma Alias(GCNListSend, "GCNLISTSEND");

pragma Alias(GCNListAddToBlock, "GCNLISTADDTOBLOCK");
pragma Alias(GCNListRemoveFromBlock, "GCNLISTREMOVEFROMBLOCK");
pragma Alias(GCNListSendToBlock, "GCNLISTSENDTOBLOCK");
pragma Alias(GCNListFindListInBlock, "GCNLISTFINDLISTINBLOCK");
pragma Alias(GCNListCreateBlock, "GCNLISTCREATEBLOCK");
pragma Alias(GCNListDestroyBlock, "GCNLISTDESTROYBLOCK");
pragma Alias(GCNListRelocateBlock, "GCNLISTRELOCATEBLOCK");
pragma Alias(GCNListUnRelocateBlock, "GCNLISTUNRELOCATEBLOCK");

pragma Alias(GCNListAddToList, "GCNLISTADDTOLIST");
pragma Alias(GCNListRemoveFromList, "GCNLISTREMOVEFROMLIST");
pragma Alias(GCNListFindItemInList, "GCNLISTFINDITEMINLIST");
pragma Alias(GCNListSendToList, "GCNLISTSENDTOLIST");
pragma Alias(GCNListCreateList, "GCNLISTCREATELIST");
pragma Alias(GCNListDestroyList, "GCNLISTDESTROYLIST");
pragma Alias(GCNListRelocateList, "GCNLISTRELOCATELIST");
pragma Alias(GCNListUnRelocateList, "GCNLISTUNRELOCATELIST");
#endif



#endif

# 24 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"

#define GenControlBase GenInteractionBase
#define _FIRST_GenControlClass 27136
# 25 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"




typedef ByteFlags GenControlFeatureFlags;

typedef struct {
    ChunkHandle			GCFI_object;
    optr			GCFI_name;
    GenControlFeatureFlags    	GCFI_flags;
} GenControlFeaturesInfo;

typedef ByteFlags GenControlChildFlags;
#define GCCF_NOTIFY_WHEN_ADDING		0x04
#define GCCF_ALWAYS_ADD			0x02
#define GCCF_IS_DIRECTLY_A_FEATURE	0x01

typedef struct {
    ChunkHandle			GCCI_object;
    WordFlags			GCCI_featureMask;
    GenControlChildFlags	GCCI_flags;
} GenControlChildInfo;

typedef WordFlags GenControlBuildFlags;
#define GCBF_SUSPEND_ON_APPLY			0x8000
#define GCBF_USE_GEN_DESTROY			0x4000
#define GCBF_SPECIFIC_UI			0x2000
#define GCBF_CUSTOM_ENABLE_DISABLE		0x1000
#define GCBF_ALWAYS_UPDATE  	    		0x0800
#define GCBF_EXPAND_TOOL_WIDTH_TO_FIT_PARENT   	0x0400
#define GCBF_ALWAYS_INTERACTABLE    		0x0200
#define GCBF_ALWAYS_ON_GCN_LIST	    		0x0100
#define GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST 	0x0080
#define GCBF_IS_ON_ACTIVE_LIST    		0x0040
#define GCBF_IS_ON_START_LOAD_OPTIONS_LIST	0x0020
#define GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST 0x0010
#define GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED    0x0008

typedef struct {
    GenControlBuildFlags	GCBI_flags;
    const char			*GCBI_initFileKey;
    const GCNListType		*GCBI_gcnList;
    word			GCBI_gcnCount;
    const NotificationType	*GCBI_notificationList;
    word			GCBI_notificationCount;
    optr			GCBI_controllerName;

    MemHandle			GCBI_dupBlock;
    const GenControlChildInfo	*GCBI_childList;
    word			GCBI_childCount;
    const GenControlFeaturesInfo *GCBI_featuresList;
    word			GCBI_featuresCount;
    WordFlags			GCBI_features;

    MemHandle			GCBI_toolBlock;
    const GenControlChildInfo	*GCBI_toolList;
    word			GCBI_toolCount;
    const GenControlFeaturesInfo *GCBI_toolFeaturesList;
    word			GCBI_toolFeaturesCount;
    WordFlags			GCBI_toolFeatures;
    char			*GCBI_helpContext;

    byte			GCBI_reserved [8];
} GenControlBuildInfo;





















typedef enum  {
    GCUIT_NORMAL,
    GCUIT_TOOLBOX
} GenControlUIType;

typedef struct {
    WordFlags	GCSI_userAdded;
    WordFlags	GCSI_userRemoved;
    WordFlags	GCSI_appRequired;
    WordFlags	GCSI_appProhibited;
} GenControlScanInfo;













typedef WordFlags GenControlInteractableFlags;
#define GCIF_CONTROLLER	0x8000
#define GCIF_TOOLBOX_UI	0x0002
#define GCIF_NORMAL_UI	0x0001













typedef struct {
    WordFlags    GCSR_features;
    WordFlags    GCSR_required;
    WordFlags    GCSR_prohibited;
    WordFlags    GCSR_supported;
} GenControlGetFeaturesReturn;





























typedef WordFlags GenControlStatusChange;
#define GCSF_HIGHLIGHTED_TOOLGROUP_SELECTED	0x0004
#define GCSF_TOOLBOX_FEATURES_CHANGED		0x0002
#define GCSF_NORMAL_FEATURES_CHANGED		0x0001

typedef struct {
    optr    			NGCS_controller;
    GenControlStatusChange	NGCS_statusChange;
} NotifyGenControlStatusChange;





typedef struct {
    GenControlInteractableFlags	TGCI_interactableFlags;
    MemHandle			TGCI_childBlock;
    MemHandle			TGCI_toolBlock;
    optr			TGCI_toolParent;
    WordFlags			TGCI_features;
    WordFlags			TGCI_toolboxFeatures;
    GCNListType	    	    	TGCI_activeNotificationList;
    GenControlInteractableFlags	TGCI_upToDate;
} TempGenControlInstance;

    #define TEMP_GEN_CONTROL_INSTANCE 27136


typedef WordFlags GenControlUserFlags;
#define GCUF_USER_TOOLBOX_UI	0x0002
#define GCUF_USER_UI	    	0x0001

typedef struct {
    GenControlUserFlags	GCUD_flags;
    word	    	GCUD_userAddedUI;
    word	    	GCUD_userRemovedUI;
    word	    	GCUD_userAddedToolboxUI;
    word	    	GCUD_userRemovedToolboxUI;
} GenControlUserData;

    #define HINT_GEN_CONTROL_MODIFY_INITIAL_UI 27140

    #define HINT_GEN_CONTROL_USER_MODIFIED_UI 27144


    #define HINT_GEN_CONTROL_TOOLBOX_ONLY 27148


    #define ATTR_GEN_CONTROL_REQUIRE_UI 27152

    #define ATTR_GEN_CONTROL_REQUIRE_TOOLBOX_UI 27156


    #define ATTR_GEN_CONTROL_PROHIBIT_UI 27160

    #define ATTR_GEN_CONTROL_PROHIBIT_TOOLBOX_UI 27164


    #define ATTR_GEN_CONTROL_APP_UI 27168

    ;

    #define ATTR_GEN_CONTROL_APP_TOOLBOX_UI 27172

    ;

typedef ByteEnum GenControlScalableUICommand;
#define GCSUIC_SET_NORMAL_FEATURES_IF_APP_FEATURE_ON	0




#define GCSUIC_SET_TOOLBOX_FEATURES_IF_APP_FEATURE_ON	1




#define GCSUIC_SET_NORMAL_FEATURES_IF_APP_FEATURE_OFF	2




#define GCSUIC_SET_TOOLBOX_FEATURES_IF_APP_FEATURE_OFF	3




#define GCSUIC_SET_NORMAL_FEATURES_IF_APP_LEVEL    	4




#define GCSUIC_SET_TOOLBOX_FEATURES_IF_APP_LEVEL    	5




#define GCSUIC_ADD_NORMAL_FEATURES_IF_APP_FEATURE_ON	6




#define GCSUIC_ADD_TOOLBOX_FEATURES_IF_APP_FEATURE_ON	7





typedef struct {
    GenControlScalableUICommand		GCSUIE_command;
    WordFlags				GCSUIE_appFeature;
    WordFlags				GCSUIE_newFeatures;
} GenControlScalableUIEntry;

   #define HINT_GEN_CONTROL_SCALABLE_UI_DATA 27176


   #define TEMP_GEN_CONTROL_OPTIONS_LOADED 27180


   #define ATTR_GEN_CONTROL_DO_NOT_USE_LIBRARY_NAME_FOR_HELP 27184


   #define HINT_GEN_CONTROL_DESTROY_CHILDREN_WHEN_NOT_INTERACTABLE 27188






    

    

extern ClassStruct _far GenControlClass; extern Message _Messages_GenControlClass[]; extern MessageMethod *_Methods_GenControlClass[]; extern CMethodDef _htypes_GenControlClass[];extern MessageMethod *_Reloc_GenControlClass;
typedef struct _GenControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;} GenControlInstance; 
# 306 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
typedef enum{MSG_GEN_CONTROL_GET_INFO=27136,MSG_GEN_CONTROL_GENERATE_UI,MSG_GEN_CONTROL_DESTROY_UI,MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI,MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI,MSG_GEN_CONTROL_UPDATE_UI,MSG_GEN_CONTROL_ENABLE_DISABLE,MSG_GEN_CONTROL_SCAN_FEATURE_HINTS,MSG_GEN_CONTROL_ADD_FEATURE,MSG_GEN_CONTROL_REMOVE_FEATURE,MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE,MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE,MSG_GEN_CONTROL_NOTIFY_INTERACTABLE,MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE,MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE,MSG_GEN_CONTROL_ADD_TO_GCN_LISTS,MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS,MSG_GEN_CONTROL_GET_NORMAL_FEATURES,MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES,MSG_GEN_CONTROL_ADD_APP_UI,MSG_GEN_CONTROL_ADD_APP_TOOLBOX_UI,MSG_GEN_CONTROL_REBUILD_NORMAL_UI,MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI,MSG_GEN_CONTROL_ADD_TO_UI,MSG_GEN_CONTROL_REMOVE_FROM_UI,MSG_GEN_CONTROL_OUTPUT_ACTION,MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI,MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI,MSG_GEN_CONTROL_NOTIFY_ADDING_FEATURE,MSG_GEN_CONTROL_FREE_OBJ_BLOCK,}GenControlMessages;

#ifdef __HIGHC__
#endif




#endif

# 29 "/staff/pcgeos/CInclude/Objects/vTextC.goh"

#ifndef __GOCgViewC
#define __GOCgViewC
#include "/staff/pcgeos/CInclude/Objects/gViewC.poh"
#endif

# 30 "/staff/pcgeos/CInclude/Objects/vTextC.goh"

#ifndef __GOCspool
#define __GOCspool

# 1 "/staff/pcgeos/CInclude/spool.goh"

























#ifndef __GOCgProcC
#define __GOCgProcC
#include "/staff/pcgeos/CInclude/Objects/gProcC.poh"
#endif

# 26 "/staff/pcgeos/CInclude/spool.goh"

#ifndef __GOCobject
#define __GOCobject
#include "/staff/pcgeos/CInclude/object.poh"
#endif

# 27 "/staff/pcgeos/CInclude/spool.goh"
#include <driver.h>
#include <thread.h>
#include <print.h>




#include <Internal/spoolInt.h>










#define PrintControlBase GenControlBase
#define _FIRST_PrintControlClass 27648
# 45 "/staff/pcgeos/CInclude/spool.goh"































































 

















































typedef ByteFlags PrintControlFeatures;
#define PRINTCF_PRINT_TRIGGER	0x02 	 
#define PRINTCF_FAX_TRIGGER	0x01	 

typedef ByteFlags PrintControlToolboxFeatures;
#define PRINTCTF_PRINT_TRIGGER	0x02	
#define PRINTCTF_FAX_TRIGGER	0x01	

#define PRINTC_DEFAULT_FEATURES (PRINTCF_PRINT_TRIGGER | \
				 PRINTCF_FAX_TRIGGER)

#define PRINTC_DEFAULT_TOOLBOX_FEATURES	(PRINTCTF_PRINT_TRIGGER | \
					 PRINTCTF_FAX_TRIGGER)


#define MAXIMUM_NUMBER_OF_PRINTERS	255
#define MAXIMUM_PRINTER_NAME_LENGTH	64	; includes NULL terminator


typedef ByteFlags PrinterOutputModes;
#define POM_unused  	    	0xe0 
#define POM_GRAPHICS_LOW	0x10 
#define POM_GRAPHICS_MEDIUM	0x08 
#define POM_GRAPHICS_HIGH	0x04 
#define POM_TEXT_DRAFT		0x02 
#define POM_TEXT_NLQ		0x01 

#define PRINT_GRAPHICS	(POM_GRAPHICS_LOW | \
			 POM_GRAPHICS_MEDIUM |  POM_GRAPHICS_HIGH )

#define PRINT_TEXT	(POM_TEXT_DRAFT | POM_TEXT_NLQ)




typedef ByteEnum PrintQualityEnum;
#define	PQT_HIGH	0	
#define	PQT_MEDIUM	1	
#define	PQT_LOW		2	

#define PQE_HIGH    PQT_HIGH	
#define PQE_MEDIUM  PQT_MEDIUM	
#define PQE_LOW	    PQT_LOW	

typedef WordFlags PrintControlAttrs;
#define PCA_NO_PRINTER_CONTROLS	0x8000	
#define PCA_SEE_IF_DOC_WILL_FIT	0x4000	

#define PCA_MARK_APP_BUSY	0x2000	

#define PCA_VERIFY_PRINT	0x1000	

#define PCA_SHOW_PROGRESS	0x0800	
#define PCA_PROGRESS_PERCENT	0x0400	

#define PCA_PROGRESS_PAGE	0x0200	
#define PCA_FORCE_ROTATION	0x0100	
#define PCA_COPY_CONTROLS	0x0080	
#define PCA_PAGE_CONTROLS	0x0040	
#define PCA_QUALITY_CONTROLS	0x0020	

#define PCA_USES_DIALOG_BOX	0x0010	
#define PCA_GRAPHICS_MODE	0x0008	
#define PCA_TEXT_MODE		0x0004	
#define PCA_DEFAULT_QUALITY	0x0003	

typedef enum  {
    PCS_PRINT_BOX_VISIBLE,  	    
    PCS_PRINT_BOX_NOT_VISIBLE       
} PrintControlStatus;

typedef enum  {
    PCPT_PAGE	    = 0,	
    PCPT_PERCENT    = 2,	
    PCPT_TEXT	    = 4		
} PCProgressType;






































































































#define MSG_PRINT_CONTROL_REPORT_STRING MSG_PRINT_CONTROL_REPORT_PROGRESS



















	


















































































typedef struct {
	word	PCPR_lastPage;
	word	PCPR_firstPage;
} PCPageRange;















































































































































































































































 















































































































typedef struct {
    	word	PD_widthHigh;	
	word	PD_widthLow;	
	dword	PD_height;  	
} PaperDimensions;





#define PAPER_WIDTH(pd) (((pd).PD_widthHigh << 16) | (pd).PD_widthLow)
#define PAPER_HEIGHT(pd) ((pd).PD_height)











































 

































































































































































;

























































#define MSG_PRINT_VERIFY_PRINT_REQUEST 597




























#define MSG_PRINT_START_PRINTING 598


















#define MSG_PRINT_GET_DOC_NAME 599


















 




#define MSG_PRINT_NOTIFY_PRINT_DB 600
















 



#define MSG_PRINT_NOTIFY_PRINT_JOB_CREATED 601































	  
	  
	  
 
	  
 	    	    	    	    	  

		  
	  





#define	PRINT_TRIGGER_VALUES  		'GI_visMoniker = "Print";'
#define	FAX_TRIGGER_VALUES 		'GI_visMoniker = "Fax";'





typedef ByteFlags PrintStatusFlags;
#define PSF_FAX_AVAILABLE	0x80	
#define PSF_ABORT		0x08	
#define PSF_RECEIVED_COMPLETED	0x04	
#define PSF_RECEIVED_NAME	0x02	
#define PSF_VERIFIED		0x01	

typedef struct {
    optr	TPCI_currentSummons;	
    optr	TPCI_progressBox;	
    ChunkHandle	TPCI_jobParHandle;	
    word	TPCI_fileHandle;	
    word	TPCI_gstringHandle;	
    word	TPCI_printBlockHan;	
    PrintControlAttrs	TPCI_attrs;
    PrintStatusFlags	TPCI_status;
    byte	TPCI_holdUpCompletionCount; 



} TempPrintCtrlInstance;

#define TEMP_PRINT_CONTROL_INSTANCE 27648












#define ATTR_PRINT_CONTROL_APP_UI 27652

;

typedef struct {
	MemHandle	TPCED_event;
	MessageFlags	TPCED_messageFlags;
} TempPrintCompletionEventData;
#define TEMP_PRINT_COMPLETION_EVENT 27656


typedef struct {
	optr			TPACD_addrControl;
	PrinterDriverType	TPACD_driverType;
} TempPrintAddressControlData;

#define TEMP_PRINT_CONTROL_ADDRESS_CONTROL 27660




extern ClassStruct _far PrintControlClass; extern Message _Messages_PrintControlClass[]; extern MessageMethod *_Methods_PrintControlClass[]; extern CMethodDef _htypes_PrintControlClass[];extern MessageMethod *_Reloc_PrintControlClass;
typedef struct _PrintControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;
# 1192 "/staff/pcgeos/CInclude/spool.goh"
    PrintControlAttrs PCI_attrs;

    word PCI_startPage;
    word PCI_endPage;
    word PCI_startUserPage;
    word PCI_endUserPage;
    word PCI_defPrinter;

    PageSizeReport PCI_docSizeInfo;
    optr PCI_output;
    optr PCI_docNameOutput;} PrintControlInstance; 
# 1267 "/staff/pcgeos/CInclude/spool.goh"
typedef enum{MSG_PRINT_CONTROL_INITIATE_PRINT=27648,MSG_PRINT_CONTROL_PRINT,MSG_PRINT_CONTROL_VERIFY_COMPLETED,MSG_PRINT_CONTROL_SET_DOC_NAME,MSG_PRINT_CONTROL_REPORT_PROGRESS,MSG_PRINT_CONTROL_PRINTING_CANCELLED,MSG_PRINT_CONTROL_PRINTING_COMPLETED,MSG_PRINT_CONTROL_SET_ATTRS,MSG_PRINT_CONTROL_GET_ATTRS,MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE,MSG_PRINT_CONTROL_GET_TOTAL_PAGE_RANGE,MSG_PRINT_CONTROL_SET_SELECTED_PAGE_RANGE,MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE,MSG_PRINT_CONTROL_SET_DOC_SIZE,MSG_PRINT_CONTROL_GET_DOC_SIZE,MSG_PRINT_CONTROL_SET_EXTENDED_DOC_SIZE,MSG_PRINT_CONTROL_GET_EXTENDED_DOC_SIZE,MSG_PRINT_CONTROL_SET_DOC_MARGINS,MSG_PRINT_CONTROL_GET_DOC_MARGINS,MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO,MSG_PRINT_CONTROL_GET_DOC_SIZE_INFO,MSG_PRINT_CONTROL_SET_OUTPUT,MSG_PRINT_CONTROL_GET_OUTPUT,MSG_PRINT_CONTROL_SET_DOC_NAME_OUTPUT,MSG_PRINT_CONTROL_GET_DOC_NAME_OUTPUT,MSG_PRINT_CONTROL_SET_DEFAULT_PRINTER,MSG_PRINT_CONTROL_GET_DEFAULT_PRINTER,MSG_PRINT_CONTROL_GET_PRINT_MODE,MSG_PRINT_CONTROL_GET_PAPER_SIZE_INFO,MSG_PRINT_CONTROL_GET_PAPER_SIZE,MSG_PRINT_CONTROL_GET_PRINTER_MARGINS,MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS,MSG_PRINT_CONTROL_CHECK_IF_DOC_WILL_FIT,MSG_PRINT_CONTROL_VERIFY_PRINT,MSG_PRINT_CONTROL_VERIFY_SCALE,MSG_PRINT_CONTROL_VERIFY_CANCEL,MSG_PRINT_CONTROL_ABORT_PRINT_JOB,MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI,MSG_PRINT_SET_PRINT_CONTROL_PAGE_SIZE,MSG_PRINT_GET_MAILBOX_OBJECT_TYPE,MSG_PRINT_CANNOT_PRINT,MSG_PRINT_GET_FIRST_PAGE_OFFSET,}PrintControlMessages; 	
























#define PageSizeControlBase GenControlBase
#define _FIRST_PageSizeControlClass 27648
# 1292 "/staff/pcgeos/CInclude/spool.goh"






#define MINIMUM_PAGE_WIDTH_VALUE	36		 
#define MINIMUM_PAGE_HEIGHT_VALUE	36		 

#ifdef DO_PIZZA
#define MAXIMUM_PAGE_WIDTH_VALUE	3189	 
#define MAXIMUM_PAGE_HEIGHT_VALUE	3189	 
#else
#define MAXIMUM_PAGE_WIDTH_VALUE	(72*45)	 
#define MAXIMUM_PAGE_HEIGHT_VALUE	(72*45)	 
#endif

#define MAXIMUM_LABELS_ACROSS		63
#define MAXIMUM_LABELS_DOWN		63



typedef WordFlags PageSizeCtrlAttrs;

#define PZCA_ACT_LIKE_GADGET	0x8000	
#define PZCA_PAPER_SIZE 	0x4000	
#define PZCA_INITIALIZE		0x2000	

#define PZCA_LOAD_SAVE_OPTIONS	0x1000	


#define PZCA_NEW_PAGE_TYPE	0x0080
#define PZCA_SWAP_WIDTH_HEIGHT  0x0040
#define PZCA_INITIALIZED	0x0020
#define PZCA_IGNORE_UPDATE	0x0010
#define PZCA_PORTRAIT_VALID	0x0008
#define PZCA_LANDSCAPE_VALID	0x0004




typedef WordFlags PageSizeControlFeatures;
#define PSIZECF_MARGINS		0x0010	
#define PSIZECF_CUSTOM_SIZE	0x0008
#define PSIZECF_LAYOUT		0x0004
#define PSIZECF_SIZE_LIST	0x0002
#define PSIZECF_PAGE_TYPE	0x0001

#define PSIZEC_DEFAULT_FEATURES (PSIZECF_PAGE_TYPE | \
				 PSIZECF_SIZE_LIST | \
				 PSIZECF_LAYOUT | \
				 PSIZECF_CUSTOM_SIZE)




typedef WordFlags PageSizeControlToolboxFeatures;
#define PSIZECTF_DIALOG_BOX 	0x0001

#define PSIZECT_DEFAULT_TOOLBOX_FEATURES	PSIZECTF_DIALOG_BOX












































































































#define MSG_PRINT_REPORT_PAGE_SIZE 602





















		
		
	
	




#define	PAGE_SETUP_CONTROL_VALUES 	'GI_visMoniker = "Page Setup";'





typedef struct {
    dword	PZCMD_width;		
    dword	PZCMD_height;		
} PageSizeControlMaxDimensions;

#define TEMP_PAGE_SIZE_CONTROL_MAX_DIMENSIONS 27648








typedef struct {
    optr	PSCC_destination;	
    Message	PSCC_message;		
} PageSizeControlChanges;

#define ATTR_PAGE_SIZE_CONTROL_UI_CHANGES 27652











extern ClassStruct _far PageSizeControlClass; extern Message _Messages_PageSizeControlClass[]; extern MessageMethod *_Methods_PageSizeControlClass[]; extern CMethodDef _htypes_PageSizeControlClass[];extern MessageMethod *_Reloc_PageSizeControlClass;
typedef struct _PageSizeControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;
# 1480 "/staff/pcgeos/CInclude/spool.goh"
    PageSizeCtrlAttrs PZCI_attrs;

    dword PZCI_width;
    dword PZCI_height;
    PageLayout PZCI_layout;
    PCMarginParams PZCI_margins;} PageSizeControlInstance; 
# 1525 "/staff/pcgeos/CInclude/spool.goh"
typedef enum{MSG_PZC_SET_PAGE_SIZE=27648,MSG_PZC_GET_PAGE_SIZE,MSG_PZC_REQUEST_PAGE_SIZE_MONIKER,MSG_PZC_SET_PAGE_TYPE,MSG_PZC_SET_PAGE_SIZE_ENTRY,MSG_PZC_SET_PAGE_WIDTH,MSG_PZC_SET_PAGE_HEIGHT,MSG_PZC_SET_PAPER_ORIENTATION,MSG_PZC_SET_ENVELOPE_ORIENTATION,MSG_PZC_SET_LABEL_COLUMNS,MSG_PZC_SET_LABEL_ROWS,MSG_PZC_SET_MARGIN_LEFT,MSG_PZC_SET_MARGIN_TOP,MSG_PZC_SET_MARGIN_RIGHT,MSG_PZC_SET_MARGIN_BOTTOM,MSG_PZC_SET_MAXIMUM_WIDTH,MSG_PZC_SET_MAXIMUM_HEIGHT,}PageSizeControlMessages;	






#define _FIRST_SpoolProcClass 9216
# 1531 "/staff/pcgeos/CInclude/spool.goh"



























extern ClassStruct _far SpoolProcClass; extern Message _Messages_SpoolProcClass[]; extern MessageMethod *_Methods_SpoolProcClass[]; extern CMethodDef _htypes_SpoolProcClass[];extern MessageMethod *_Reloc_SpoolProcClass;typedef enum{MSG_SPOOL_SHOW_PRINTER_CONTROL_PANEL=9216,}SpoolProcMessages;	 





#define DWhigh(x) ((word) ((x) >> 16))
#define DWlow(x) ((word) (x))




#define MAX_PAPER_STRING_LENGTH 	48	




#define MAX_PRE_DEFINED_PAPER_SIZES	128
#define MAX_USER_DEFINED_PAPER_SIZES	128
#define MAX_PAPER_SIZES			(MAX_PRE_DEFINED_PAPER_SIZES + \
					 MAX_USER_DEFINED_PAPER_SIZES)




typedef enum  {
    SPOOL_OPERATION_SUCCESSFUL,
    SPOOL_JOB_NOT_FOUND,
    SPOOL_QUEUE_EMPTY,
    SPOOL_QUEUE_NOT_EMPTY,
    SPOOL_QUEUE_NOT_FOUND,
    SPOOL_CANT_VERIFY_PORT,
    SPOOL_OPERATION_FAILED,
} SpoolOpStatus;




typedef struct {
    byte	STS_second;		
    byte	STS_minute;		
    byte	STS_hour;		
} SpoolTimeStruct;




typedef struct {			
    char SFN_base[5];
    char SFN_num[3]; 
    char SFN_ext[5]; 
} SpoolFileName;




typedef enum  {
    SIT_JOB_INFO    	= 0,
    SIT_QUEUE_INFO  	= 2,
    SIT_JOB_PARAMETERS	= 4
} SpoolInfoType;




typedef struct {
    char JS_fname[13]; 				
    char JS_parent[FILE_LONGNAME_LENGTH+1];	    
    char JS_documentName[FILE_LONGNAME_LENGTH+1];   
    word JS_numPages;			
    SpoolTimeStruct JS_time; 	 	
    byte JS_printing;			
} JobStatus;





extern void
    _pascal SpoolGetDefaultPageSizeInfo(PageSizeReport *psr);








extern void
    _pascal SpoolSetDefaultPageSizeInfo(PageSizeReport *psr);









typedef struct {
	word	NPSI_numSizes;
	word	NPSI_defaultSize;
} NumPaperSizesInfo;

extern void
    _pascal SpoolGetNumPaperSizes(NumPaperSizesInfo *sizesInfo,
				  PageType pageType);












extern word 
    _pascal SpoolGetPaperString(char *stringBuf,
				word paperSizeNum,
				PageType pageType);














typedef struct {
    word    	PSI_width;  	    
    word    	PSI_height; 	    
    PageLayout	PSI_defaultLayout;
} PaperSizeInfo;

extern void
     _pascal SpoolGetPaperSize(PaperSizeInfo *sizeInfo,
			       word paperSizeNum,
	 		       PageType pageType);














extern word 
    _pascal SpoolConvertPaperSize(word width,
				  word height,
				  PageType pageType);













typedef struct {
    word    PSOI_numOrdered;	
    word    PSOI_numUnused; 	
} PaperSizeOrderInfo;

extern void
    _pascal SpoolGetPaperSizeOrder(byte *orderBuf,
				   byte *userDefBuf,
			           PaperSizeOrderInfo *numBuf);













extern void 
    _pascal SpoolSetPaperSizeOrder(byte *orderArray,
				   word numEntries,
				   PageType pageType);













extern word
    _pascal SpoolCreatePaperSize(char *paperSizeString,
    	    	    	    	 word width,
    	    	    	    	 word height,
    	    	    	    	 PageLayout layout,
    	    	    	    	 PageType pageType);













extern Boolean
    _pascal SpoolDeletePaperSize(word paperSizeNum,
    	    	    	    	 PageType pageType);












extern word
    _pascal SpoolGetNumPrinters(PrinterDriverType driverType,
				byte localOnlyFlag);











typedef struct {
    char     	    	PSI_stringBuf[GEODE_MAX_DEVICE_NAME_SIZE];
    word    	    	PSI_stringLength;
    PrinterDriverType	PSI_driverType;
} PrinterStringInfo;

extern Boolean
    _pascal SpoolGetPrinterString(PrinterStringInfo *retInfo,
    	    	    	    	  word printerNum);












extern word
    _pascal SpoolCreatePrinter(char *printerName,
    	    	    	       PrinterDriverType driverType);












extern void
    _pascal SpoolDeletePrinter(word printerNum);










extern int
    _pascal SpoolGetDefaultPrinter(void);











extern void
    _pascal SpoolSetDefaultPrinter(word printerNum);











extern FileHandle
    _pascal SpoolCreateSpoolFile(char *fileNameBuf);












extern SpoolOpStatus
    _pascal SpoolDelJob(word jobID);














typedef struct {
    Boolean	    	SIQP_activityQuery;
    struct _PrintPortInfo  *SIQP_portInfo;
    MemHandle	    	SIQP_retBlock;
    word	    	SIQP_retNumJobs;
} SpoolInfoQueueParams;




typedef struct {
    word	SIJP_jobID;
    MemHandle	SIJP_retBlock;
} SpoolInfoJobParams;




typedef union {
    SpoolInfoQueueParams    SIP_queueParams;
    SpoolInfoJobParams	    SIP_jobParams;
} SpoolInfoParams;

extern SpoolOpStatus
    _pascal SpoolInfo(SpoolInfoType infoType,
		      SpoolInfoParams *params);

# 2016 "/staff/pcgeos/CInclude/spool.goh"


extern SpoolOpStatus
    _pascal SpoolHurryJob(word jobID);










extern SpoolOpStatus
    _pascal SpoolDelayJob(word jobID);








extern SpoolOpStatus
	_pascal SpoolModifyPriority(word jobID,
    	    	    	    	    ThreadPriority priority);














extern SpoolOpStatus
	_pascal SpoolVerifyPrinterPort(struct _PrintPortInfo *portInfo);
















extern void
    _pascal SpoolSetDocSize(Boolean openFlag,
    	    	    	    PageSizeReport *psr);












#ifdef __HIGHC__

pragma Alias(SpoolGetNumPaperSizes, "SPOOLGETNUMPAPERSIZES");
pragma Alias(SpoolGetPaperString, "SPOOLGETPAPERSTRING");
pragma Alias(SpoolGetPaperSize, "SPOOLGETPAPERSIZE");
pragma Alias(SpoolConvertPaperSize, "SPOOLCONVERTPAPERSIZE");
pragma Alias(SpoolGetPaperSizeOrder, "SPOOLGETPAPERSIZEORDER");
pragma Alias(SpoolSetPaperSizeOrder, "SPOOLSETPAPERSIZEORDER");
pragma Alias(SpoolCreatePaperSize, "SPOOLCREATEPAPERSIZE");
pragma Alias(SpoolDeletePaperSize, "SPOOLDELETEPAPERSIZE");

pragma Alias(SpoolGetNumPrinters, "SPOOLGETNUMPRINTERS");
pragma Alias(SpoolGetPrinterString, "SPOOLGETPRINTERSTRING");
pragma Alias(SpoolCreatePrinter, "SPOOLCREATEPRINTER");
pragma Alias(SpoolDeletePrinter, "SPOOLDELETEPRINTER");
pragma Alias(SpoolGetDefaultPrinter, "SPOOLGETDEFAULTPRINTER");
pragma Alias(SpoolSetDefaultPrinter, "SPOOLSETDEFAULTPRINTER");

pragma Alias(SpoolCreateSpoolFile, "SPOOLCREATESPOOLFILE");
pragma Alias(SpoolSetDocSize, "SPOOLSETDOCSIZE");

pragma Alias(SpoolDelJob, "SPOOLDELJOB");
pragma Alias(SpoolInfo, "SPOOLINFO");
pragma Alias(SpoolHurryJob, "SPOOLHURRYJOB");
pragma Alias(SpoolDelayJob, "SPOOLDELAYJOB");
pragma Alias(SpoolModifyPriority, "SPOOLMODIFYPRIORITY");
pragma Alias(SpoolVerifyPrinterPort, "SPOOLVERIFYPRINTERPORT");

pragma Alias(SpoolGetDefaultPageSizeInfo, "SPOOLGETDEFAULTPAGESIZEINFO");
pragma Alias(SpoolSetDefaultPageSizeInfo, "SPOOLSETDEFAULTPAGESIZEINFO");

#endif


#endif

# 31 "/staff/pcgeos/CInclude/Objects/vTextC.goh"
#include <hugearr.h>
#include <dbase.h>






#define VisTextBase VisBase
#define _FIRST_VisTextClass 18432
# 39 "/staff/pcgeos/CInclude/Objects/vTextC.goh"


typedef	dword	TokenAsDWord;
typedef	dword	SizeAsDWord;

#define DWORD_TOKEN(val) ((word)( (val) & 0xffff ))
#define DWORD_DATA(val) ((word)( ((val) >> 16) & 0xffff ))




typedef WordFlags TextFocusFlags;
#define TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS  0x8000
#define TFF_OBJECT_RUN_BY_UI_THREAD 	    0x4000






#define SEARCH_REPLACE_TEXT_MAXIMUM 	    65	    

typedef ByteFlags SearchOptions;

#define SO_START_FROM_TOP		    0x40


#define SO_NO_WILDCARDS	    	    	    0x20


#define SO_IGNORE_SOFT_HYPHENS	    	    0x10






#define SO_BACKWARD_SEARCH	    	    0x08


#define SO_IGNORE_CASE	    	    	    0x04


#define SO_PARTIAL_WORD	    	    	    0x02


#define SO_PRESERVE_CASE_OF_DOCUMENT_STRING 0x01





typedef ByteEnum SearchNoteOptionType;
#define SNOT_INCLUDE_NOTE		0x0
#define SNOT_EXCLUDE_NOTE		0x1
#define SNOT_NOTE_ONLY			0x2


typedef ByteEnum WildCard;
#define WC_MATCH_SINGLE_CHAR   	    0x10
#define WC_MATCH_MULTIPLE_CHARS     0x11
#define WC_MATCH_WHITESPACE_CHAR    0x12



extern char *
    _pascal TextSearchInString(const char *str1, const char *startPtr,
				const char *endPtr, word str1Size,
				const char *str2, word str2Size,
				word searchOptions, word *matchLen);










































extern dword
    _pascal TextSearchInHugeArray(char *str2, word str2Size,
				       dword str1Size, dword curOffset,
				       dword endOffset, 
				       FileHandle hugeArrayFile,
				       VMBlockHandle hugeArrayBlock,
				       word searchOptions, 
				       dword *matchLen);

















 

typedef WordFlags VisTextRangeContext;

#define VTRC_PARAGRAPH_CHANGE		0x8000


#define VTRC_CHAR_ATTR_CHANGE		0x4000


#define VTRC_PARA_ATTR_BORDER_CHANGE	0x2000
























typedef struct {
    ChunkArrayHeader	TRAH_meta;
    VMBlockHandle	TRAH_elementVMBlock;	
    ChunkHandle		TRAH_elementArray;  	
} TextRunArrayHeader;




typedef struct {
    ChunkArrayHeader	TLRAH_meta;		
    VMBlockHandle	TLRAH_elementVMBlock;	
} TextLargeRunArrayHeader;




typedef struct {
    WordAndAHalf 	TRAE_position;		
    word	    	TRAE_token;		
} TextRunArrayElement;


typedef ByteEnum TextArrayType;
#define TAT_CHAR_ATTRS 	0
#define TAT_PARA_ATTRS 	1
#define TAT_GRAPHICS 	2
#define TAT_TYPES   	3




typedef struct {
    ElementArrayHeader	TEAH_meta;
    TextArrayType	TEAH_arrayType;
    byte		TEAH_unused;
} TextElementArrayHeader;






#define TRAE(pos, base, type) {{pos-base, 0}, type}
#define TRAE_ABS(pos, type) {{pos, 0}, type}
#define TRAE_ALL(type) {{0, 0}, type}
#define TRAE_END {{TEXT_ADDRESS_PAST_END&0xffff, TEXT_ADDRESS_PAST_END>>16}, \
                                                        CA_NULL_ELEMENT}










typedef WordFlags TextStyleFlags;
#define TSF_APPLY_TO_SELECTION_ONLY 0x8000
#define TSF_POINT_SIZE_RELATIVE	    0x4000
#define TSF_MARGINS_RELATIVE	    0x2000
#define TSF_SPACING_RELATIVE	    0x1000

typedef struct {
    TextStyleFlags    	TSPD_flags;
    byte    	    	TSPD_unused[2];
} TextStylePrivateData;

typedef struct {
    NameArrayElement	    	TSEH_meta;
    word	    	    	TSEH_baseStyle;
    StyleElementFlags	    	TSEH_flags;
    byte	    	    	TSEH_reserved[6];
    TextStylePrivateData	TSEH_privateData;
    word	    	    	TSEH_charAttrToken;
    word	    	    	TSEH_paraAttrToken;
} TextStyleElementHeader;






extern void
    _pascal TextMapDefaultCharAttr(VisTextDefaultCharAttr defaulAttr,
				   VisTextCharAttr *attr);







extern Boolean
    _pascal TextFindDefaultCharAttr(VisTextDefaultCharAttr  *defaultAttr,
				    VisTextCharAttr *attr);










extern void
    _pascal TextMapDefaultParaAttr(VisTextDefaultParaAttr defaulAttr,
				   VisTextParaAttr *attr);







extern Boolean
    _pascal TextFindDefaultParaAttr(VisTextDefaultParaAttr  *defaultAttr,
				    VisTextParaAttr *attr);









extern Boolean	
    _pascal TextGetSystemCharAttrRun(word *chunkOrConstant, optr object, 
				     ObjChunkFlags flags);


















extern word
    _pascal GetTokenForPosition(optr object, word runOffset,
				dword *position);
























extern void 	 
     _pascal TextSetSpellLibrary(MemHandle libHandle);







extern void 	
     _pascal TextSetHyphenationCall(void *hyphenationWordEntryPoint);




















































				




#define MSG_VIS_TEXT_SET_FONT_ID 741








#define MSG_VIS_TEXT_SET_FONT_WEIGHT 742



								




#define MSG_VIS_TEXT_SET_FONT_WIDTH 743








#define MSG_VIS_TEXT_SET_POINT_SIZE 744








#define MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE 745








#define MSG_VIS_TEXT_SET_LARGER_POINT_SIZE 746












#define MSG_VIS_TEXT_SET_TEXT_STYLE 747











#define MSG_VIS_TEXT_SET_COLOR 748








#define MSG_VIS_TEXT_SET_GRAY_SCREEN 749



								   




#define MSG_VIS_TEXT_SET_PATTERN 750








#define MSG_VIS_TEXT_SET_CHAR_BG_COLOR 751








#define MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN 752








#define MSG_VIS_TEXT_SET_CHAR_BG_PATTERN 753








#define MSG_VIS_TEXT_SET_TRACK_KERNING 754









typedef WordFlags VisTextCharAttrFlags;
#define VTCAF_MULTIPLE_FONT_IDS		0x8000	
#define VTCAF_MULTIPLE_POINT_SIZES	0x4000
#define VTCAF_MULTIPLE_COLORS		0x2000
#define VTCAF_MULTIPLE_GRAY_SCREENS	0x1000
#define VTCAF_MULTIPLE_PATTERNS		0x0800
#define VTCAF_MULTIPLE_TRACK_KERNINGS	0x0400
#define VTCAF_MULTIPLE_FONT_WEIGHTS	0x0200
#define VTCAF_MULTIPLE_FONT_WIDTHS	0x0100
#define VTCAF_MULTIPLE_BG_COLORS	0x0080
#define VTCAF_MULTIPLE_BG_GRAY_SCREENS	0x0040
#define VTCAF_MULTIPLE_BG_PATTERNS	0x0020
#define VTCAF_MULTIPLE_STYLES		0x0010

typedef struct {
    VisTextCharAttrFlags	VTCAD_diffs;
    VisTextExtendedStyles	VTCAD_extendedStyles;
    TextStyle			VTCAD_textStyles;
    byte			VTCAD_unused;
} VisTextCharAttrDiffs;

typedef WordFlags VisTextGetAttrFlags;
#define VTGAF_MERGE_WITH_PASSED	    0x8000























































































































#define MSG_VIS_TEXT_SET_BORDER_COLOR 755



								    




#define MSG_VIS_TEXT_SET_BORDER_GRAY_SCREEN 756








#define MSG_VIS_TEXT_SET_BORDER_PATTERN 757









#define MSG_VIS_TEXT_SET_PARA_ATTRIBUTES 758



			    	      	    	


































































































































































































typedef WordFlags VisTextParaAttrFlags;
#define VTPAF_MULTIPLE_LEFT_MARGINS		0x8000
#define VTPAF_MULTIPLE_RIGHT_MARGINS		0x4000
#define VTPAF_MULTIPLE_PARA_MARGINS		0x2000
#define VTPAF_MULTIPLE_LINE_SPACINGS		0x1000
#define VTPAF_MULTIPLE_DEFAULT_TABS		0x0800
#define VTPAF_MULTIPLE_TOP_SPACING		0x0400
#define VTPAF_MULTIPLE_BOTTOM_SPACING		0x0200
#define VTPAF_MULTIPLE_LEADINGS			0x0100
#define VTPAF_MULTIPLE_BG_COLORS		0x0080
#define VTPAF_MULTIPLE_BG_GRAY_SCREENS		0x0040
#define VTPAF_MULTIPLE_BG_PATTERNS		0x0020
#define VTPAF_MULTIPLE_TAB_LISTS		0x0010
#define VTPAF_MULTIPLE_STYLES			0x0008
#define VTPAF_MULTIPLE_PREPEND_CHARS		0x0004
#define VTPAF_MULTIPLE_STARTING_PARA_NUMBERS	0x0002
#define VTPAF_MULTIPLE_NEXT_STYLES		0x0001

typedef WordFlags VisTextParaAttrFlags2;
#define VTPAF2_MULTIPLE_LANGUAGES		0x8000

typedef WordFlags VisTextParaAttrBorderFlags;
#define VTPABF_MULTIPLE_BORDER_LEFT		0x8000
#define VTPABF_MULTIPLE_BORDER_TOP		0x4000
#define VTPABF_MULTIPLE_BORDER_RIGHT		0x2000
#define VTPABF_MULTIPLE_BORDER_BOTTOM		0x1000
#define VTPABF_MULTIPLE_BORDER_DOUBLES		0x0800
#define VTPABF_MULTIPLE_BORDER_DRAW_INNERS	0x0400
#define VTPABF_MULTIPLE_BORDER_ANCHORS		0x0200
#define VTPABF_MULTIPLE_BORDER_WIDTHS		0x0100
#define VTPABF_MULTIPLE_BORDER_SPACINGS		0x0080
#define VTPABF_MULTIPLE_BORDER_SHADOWS		0x0040
#define VTPABF_MULTIPLE_BORDER_COLORS		0x0020
#define VTPABF_MULTIPLE_BORDER_GRAY_SCREENS	0x0010
#define VTPABF_MULTIPLE_BORDER_PATTERNS	    	0x0008

typedef struct {
    VisTextParaAttrFlags	VTPAD_diffs;
    VisTextParaAttrFlags2	VTPAD_diffs2;
    VisTextParaAttrBorderFlags	VTPAD_borderDiffs;
    VisTextParaAttrAttributes	VTPAD_attributes;
    VisTextHyphenationInfo	VTPAD_hyphenationInfo;
    VisTextKeepInfo		VTPAD_keepInfo;
    VisTextDropCapInfo		VTPAD_dropCapInfo;
} VisTextParaAttrDiffs;

































































					    
























typedef struct {
    RefElementHeader	VTT_meta;
    word		VTT_hyperlinkName; 
    word		VTT_hyperlinkFile; 
    word		VTT_context;	   
    byte		VTT_unused[1];
} VisTextType;


typedef ByteFlags VisTextSetContextFlags;	
#define VTCF_TOKEN	  			0x01
				
#define VTCF_SHOWING_HYPERLINKS 		0x02
				
#define	VTCF_REDIRECT_HYPERLINKS		0x04
				




#define VTCF_ENSURE_CONTEXT_NOT_ALREADY_SET	0x08
				


			  










					 




















typedef WordFlags VisTextTypeDiffs;
#define VTTF_MULTIPLE_HYPERLINKS	0x8000
#define VTTF_MULTIPLE_CONTEXTS		0x4000





































 














#define VIS_TEXT_CURRENT_FILE_TOKEN	-1 

typedef ByteEnum VisTextNameType;
#define	VTNT_CONTEXT	0
#define VTNT_FILE   	1

typedef ByteEnum VisTextContextType;
#define VTCT_TEXT   	0
#define VTCT_CATEGORY	1
#define VTCT_QUESTION	2
#define VTCT_ANSWER 	3
#define VTCT_DEFINITION	4
#define VTCT_FILE   	255

typedef struct {
    VisTextNameType 	VTND_type;
    VisTextContextType	VTND_contextType;
    word    	    	VTND_file;
    DBGroupAndItem  	VTND_helpText;
} VisTextNameData;














































 








































 




















#define VIS_TEXT_GRAPHIC_OPAQUE_SIZE	32




typedef ByteEnum VisTextGraphicType;
#define VTGT_GSTRING 0
#define VTGT_VARIABLE 1




typedef WordFlags VisTextGraphicFlags;

#define VTGF_DRAW_FROM_BASELINE	    0x8000	
	
#define VTGF_HANDLES_POINTER	    0x4000  
	
#define VTGF_HOT_SPOT	    	    0x2000
	








typedef struct {
    TransMatrix	VTGG_tmatrix;
    XYOffset	VTGG_drawOffset;
} VisTextGraphicGString;





typedef struct {
    ManufacturerID	VTGV_manufacturerID;
    VisTextVariableType	VTGV_type;
    byte		VTGV_privateData[VIS_TEXT_GRAPHIC_OPAQUE_SIZE-4];
} VisTextGraphicVariable;


typedef union {
    VisTextGraphicGString	VTGD_gstring;
    VisTextGraphicVariable	VTGD_variable;
    byte			VTGD_opaque[VIS_TEXT_GRAPHIC_OPAQUE_SIZE];
} VisTextGraphicData;





typedef struct {
    RefElementHeader	VTG_meta;
    dword	    	VTG_vmChain;	   
















    XYSize		VTG_size;   	
    VisTextGraphicType	VTG_type;
    VisTextGraphicFlags	VTG_flags;
    byte		VTG_reserved[4];
    VisTextGraphicData	VTG_data;
} VisTextGraphic;


#define VIS_TEXT_DEFAULT_GRAPHIC_WIDTH	10
#define VIS_TEXT_DEFAULT_GRAPHIC_HEIGHT	10



































































 
 
 






extern VMChain
   _pascal VisTextGraphicCompressGraphic(VisTextGraphic *graphic, 
					 FileHandle sourceFile,
					 FileHandle destFile,
					 BMFormat format,
					 byte compressFlag,
					 word xRes, word yRes);




















extern void
    _pascal VisTextFormatNumber(char *buf, dword num, VisTextNumberType numtype);




















typedef ByteEnum VisTextSaveType;
#define	VTST_NONE 		0	
#define VTST_SINGLE_CHUNK 	1	
#define VTST_RUNS_ONLY 		2
#define VTST_RUNS_AND_ELEMENTS 	3

typedef WordFlags VisTextSaveDBFlags;
#define VTSDBF_TEXT 	    0x8000	
#define VTSDBF_CHAR_ATTR    0x6000
#define VTSDBF_PARA_ATTR    0x1800
#define VTSDBF_TYPE 	    0x0600
#define VTSDBF_GRAPHIC 	    0x0180
#define VTSDBF_STYLE 	    0x0040
#define VTSDBF_REGION 	    0x0020 	
#define VTSDBF_NAME 	    0x0010

#define VTSDBF_CHAR_ATTR_OFFSET	13
#define VTSDBF_PARA_ATTR_OFFSET	11
#define VTSDBF_TYPE_OFFSET  	9
#define VTSDBF_GRAPHIC_OFFSET  	7

















#define MSG_VIS_TEXT_SAVE_TO_DB_GROUP_ITEM MSG_VIS_TEXT_SAVE_TO_DB_ITEM



typedef struct {
    StyleSheetParams	VTSSSP_common;
    word		VTSSSP_graphicsElements; 


    word		VTSSSP_treeBlock;
    word		VTSSSP_graphicTreeOffset; 

} VisTextSaveStyleSheetParams;









































#define MSG_VIS_TEXT_LOAD_FROM_DB_GROUP_ITEM MSG_VIS_TEXT_LOAD_FROM_DB_ITEM























































typedef struct {
  VisTextStorageFlags	VTCEAP_storageFlags;	
  byte			VTCEAP_blockOrChunk;	
} VisTextChangeElementArrayParams;











































































#define VM_ELEMENT_ARRAY_CHUNK	(((sizeof(LMemBlockHeader)) + 3) & ~3)

typedef struct {
    VMChainTree	TTBH_meta;
    word	TTBH_reservedOther[20];
    VMChain	TTBH_text;
    VMChain	TTBH_charAttrRuns;
    VMChain	TTBH_paraAttrRuns;
    VMChain	TTBH_typeRuns;
    VMChain	TTBH_graphicRuns;
    VMChain	TTBH_charAttrElements;
    VMChain	TTBH_paraAttrElements;
    VMChain	TTBH_typeElements;
    VMChain	TTBH_graphicElements;
    VMChain	TTBH_styles;
    VMChain	TTBH_names;
    VMChain	TTBH_pageSetup;
    VMChain	TTBH_reservedVM[10];
} TextTransferBlockHeader;





typedef struct {
    VMChainLink	PSI_meta;
    XYSize  	PSI_page;
    PageLayout  PSI_layout;
    word    	PSI_numColumns;
    word    	PSI_columnSpacing;  	
    word    	PSI_ruleWidth;		

    word    	PSI_leftMargin;	    	
    word    	PSI_rightMargin;    	
    word    	PSI_topMargin;	    	
    word    	PSI_bottomMargin;   	
} PageSetupInfo;




extern 	void	
    _pascal VTFClearSmartQuotes();










extern optr 
    _pascal TextAllocClipboardObject(VMFileHandle file, 
				     VisTextStorageFlags storageFlags,
			     	     byte regionFlag);
























typedef enum {
    TCO_COPY,
    TCO_RETURN_TRANSFER_FORMAT,
    TCO_RETURN_TRANSFER_ITEM,
    TCO_RETURN_NOTHING,
} TextClipboardOption;




extern VMBlockHandle	
    _pascal TextFinishWithClipboardObject(optr obj, TextClipboardOption opt,
    			    	    	  optr owner, const char *name);



















































































































































































































































































































































































typedef struct {
    word		VTGRS_length;
    word		VTGRS_handle;
    word		VTGRS_dx;
    DBGroup		VTGRS_group;
} VisTextGetReturnStruct;



















			




































































typedef struct {
    word		VTGHARS_bp;
    dword		VTGHARS_length;
    word		VTGHARS_handle;
} VisTextGetHugeArrayReturnStruct;


















				







































 




































































































































typedef struct {
    byte    VTWCMR_redOrIndex;
    byte    VTWCMR_mapMode;
} VisTextWashColorModeRed;

typedef struct {
    byte    VTWCBG_green;
    byte    VTWCBG_blue;
} VisTextWashColorBlueGreen;




















typedef struct {
    VisTextWashColorBlueGreen VTGWC_blueGreen;
    VisTextWashColorModeRed VTGWC_modeRed;
} VisTextGetWashColor;


























	











typedef struct {
    VisTextCharAttr	    	VTNCAC_charAttr;
    word	    	    	VTNCAC_charAttrToken;
    VisTextCharAttrDiffs	VTNCAC_charAttrDiffs;
} VisTextNotifyCharAttrChange;


typedef struct {
    VisTextMaxParaAttr	    	VTNPAC_paraAttr;
    word	    	    	VTNPAC_paraAttrToken;
    VisTextParaAttrDiffs	VTNPAC_paraAttrDiffs;
    sdword			VTNPAC_regionOffset;
    sword			VTNPAC_regionWidth;
    word			VTNPAC_selectedTab;
} VisTextNotifyParaAttrChange;


typedef struct {
    VisTextType	    	    	VTNTC_type;
    word	    	    	VTNTC_typeToken;
    VisTextTypeDiffs	    	VTNTC_typeDiffs;
    VisTextType		    	VTNTC_index;
} VisTextNotifyTypeChange;


typedef struct {
    dword	    	    	VTNSC_selectStart;
    dword	    	    	VTNSC_selectEnd;
    dword	    	    	VTNSC_lineNumber;
    dword	    	    	VTNSC_lineStart;
    word	    	    	VTNSC_region;
    dword	    	    	VTNSC_regionStartLine;
    dword	    	    	VTNSC_regionStartOffset;
} VisTextNotifySelectionChange;


typedef struct {
    Boolean	    	    	VTNHC_hyperlinkable;
} VisTextNotifyHyperlinkabilityChange;


typedef struct {
    dword	    	    	VTNCC_charCount;
    dword	    	    	VTNCC_wordCount;
    dword	    	    	VTNCC_lineCount;
    dword	    	    	VTNCC_paraCount;
} VisTextNotifyCountChange;


typedef ByteEnum VisTextNameChangeType;
#define	VTNCT_NULL	0
#define	VTNCT_ADD	1
#define	VTNCT_REMOVE	2
#define	VTNCT_RENAME	3

typedef	struct {
    word			VTNNC_count;
    VisTextNameType		VTNNC_type;		
    VisTextNameChangeType	VTNNC_changeType; 		
    word			VTNNC_index;		
    word			VTNNC_fileIndex;	

} VisTextNotifyNameChange;


typedef struct {
    dword 			VTCPC_lineNumber;
    dword 			VTCPC_rowNumber;
} VisTextCursorPositionChange;


typedef WordFlags VisTextNotificationFlags;
#define VTNF_SELECT_STATE	0x8000
#define VTNF_CHAR_ATTR		0x4000
#define VTNF_PARA_ATTR		0x2000
#define VTNF_TYPE		0x1000
#define VTNF_SELECTION		0x0800
#define VTNF_COUNT		0x0400
#define VTNF_STYLE_SHEET	0x0200
#define VTNF_STYLE		0x0100
#define VTNF_SEARCH_ENABLE	0x0080
#define VTNF_SPELL_ENABLE	0x0040
#define VTNF_NAME		0x0020
#define VTNF_CURSOR_POSITION	0x0010
#define VTNF_HYPERLINKABILITY	0x0008

#define VIS_TEXT_STANDARD_NOTIFICATION_FLAGS  	(VTNF_SELECT_STATE | \
						 VTNF_CHAR_ATTR | \
						 VTNF_PARA_ATTR | \
	    	    	    	    	    	 VTNF_TYPE | \
						 VTNF_STYLE | \
						 VTNF_STYLE_SHEET | \
						 VTNF_CURSOR_POSITION | \
						 VTNF_HYPERLINKABILITY)

#define VIS_TEXT_GAINED_TARGET_NOTIFICATION_FLAGS 	\
	    	    	    	(VIS_TEXT_STANDARD_NOTIFICATION_FLAGS | \
				 VTNF_SEARCH_ENABLE | \
				 VTNF_SPELL_ENABLE | \
				 VTNF_NAME)

typedef WordFlags VisTextNotifySendFlags;
#define VTNSF_UPDATE_APP_TARGET_GCN_LISTS	0x8000





#define VTNSF_NULL_STATUS			0x4000







#define VTNSF_STRUCTURE_INITIALIZED		0x2000





#define VTNSF_SEND_AFTER_GENERATION		0x1000




#define VTNSF_SEND_ONLY				0x0800




#define VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS	0x0400






typedef struct {
    VisTextNotificationFlags	VTGNP_notificationTypes;
    VisTextNotifySendFlags	VTGNP_sendFlags;
    MemHandle			VTGNP_notificationBlocks[16];
} VisTextGenerateNotifyParams;












































#define MSG_META_TEXT_USER_MODIFIED 759





















typedef	struct {
    CharFlags 	MTFP_charFlags;
    ShiftState	MTFP_shiftState;
    ToggleState MTFP_toggleState;
    byte	MTFP_scanCode;    
} MetaTextFilteredParameters;




#define MSG_META_TEXT_CR_FILTERED 760				













#define MSG_META_TEXT_TAB_FILTERED 761













#define MSG_META_TEXT_LOST_FOCUS 762










#define MSG_META_TEXT_GAINED_FOCUS 763










#define MSG_META_TEXT_LOST_TARGET 764










#define MSG_META_TEXT_GAINED_TARGET 765












#define MSG_META_TEXT_EMPTY_STATUS_CHANGED 766













#define MSG_META_TEXT_NOT_USER_MODIFIED 767














	











typedef WordFlags VisTextShowSelectionFlags;
#define VTSSF_DRAGGING		0x8000


























































typedef struct {
    WBFixed	VTMDP_height;
    WBFixed	VTMDP_width;
} VisTextMinimumDimensionsParameters;

































typedef ByteEnum VisTextExtendedFilterType;

#define VTEFT_REPLACE_PARAMS		0


#define VTEFT_CHARACTER_LEVELER_LEVEL	1


#define VTEFT_BEFORE_AFTER		2


















typedef enum  {
    TRT_POINTER=0,		
    TRT_SEGMENT_CHUNK=2,	
    TRT_OPTR=4,			
    TRT_BLOCK=6,		
    TRT_VM_BLOCK=8,		
    TRT_DB_ITEM=10,		
    TRT_HUGE_ARRAY=12,		
} TextReferenceType;

typedef struct {
    char _far *TRP_pointer;
   












} TextReferencePointer;


typedef struct {
    ChunkHandle	TRSC_chunk;
    Segment	TRSC_segment;
   











} TextReferenceSegmentChunk;

typedef struct {
    optr	TRBC_ref;
   











} TextReferenceBlockChunk;

typedef struct {
    MemHandle TRB_handle;
   








} TextReferenceBlock;

typedef struct {
    FileHandle 		TRVMB_file;
    VMBlockHandle 	TRVMB_block;
   








} TextReferenceVMBlock;

typedef struct {
    FileHandle 		TRDBI_file;
    DBItem		TRDBI_item;
    DBGroup		TRDBI_group;
   












} TextReferenceDBItem;

typedef struct {
    FileHandle		TRHA_file;
    word		TRHA_array;
   









} TextReferenceHugeArray;




typedef union {
    TextReferencePointer 	TRU_pointer;
    TextReferenceSegmentChunk 	TRU_segChunk;
    TextReferenceBlockChunk 	TRU_blockChunk;
    TextReferenceBlock	 	TRU_block;
    TextReferenceVMBlock	TRU_vmBlock;
    TextReferenceDBItem	 	TRU_dbItem;
    TextReferenceHugeArray	TRU_hugeArray;
} TextReferenceUnion;




typedef struct {
    TextReferenceType	TR_type;
    TextReferenceUnion 	TR_ref;
} TextReference;


typedef WordFlags VisTextReplaceFlags;

#define VTRF_FILTER			0x8000


#define VTRF_KEYBOARD_INPUT		0x4000


#define VTRF_USER_MODIFICATION		0x2000


#define VTRF_UNDO			0x1000


#define VTRF_DO_NOT_SEND_CONTEXT_UPDATE	0x0800





#define VTRF_TRUNCATE	    	    	0x0400



typedef	struct {
   


    VisTextRange	VTRP_range;	      
    dword		VTRP_insCount;	      
    TextReference	VTRP_textReference;   
    VisTextReplaceFlags VTRP_flags;		
} VisTextReplaceParameters;







#define INSERT_COMPUTE_TEXT_LENGTH	0x01ff

















































































extern void
    _pascal MsgVisTextLoadStyleSheetParams(StyleSheetParams *params,
			    	    	   optr object,
					   word preserveArrays);




















































































































typedef struct { 
    word    searchSize;		

    word    replaceSize;	

    byte    params;
    optr    replyObject; 	

    Message replyMsg;		

} SearchReplaceStruct;
















#define MSG_SEARCH 645











#define MSG_REPLACE_CURRENT 646












#define MSG_REPLACE_ALL_OCCURRENCES 647
















#define MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION 648













#define MSG_ABORT_ACTIVE_SPELL 649
#define MSG_ABORT_ACTIVE_SEARCH 650












typedef enum {
    GSSOT_FIRST_OBJECT,






    GSSOT_LAST_OBJECT,





    GSSOT_NEXT_OBJECT,






    GSSOT_PREV_OBJECT




} GetSearchSpellObjectOption;


typedef WordFlags GetSearchSpellObjectParam;
#define GSSOP_RELAYED_FLAG	0x8000
#define GSSOP_TYPE		0x000f


#define MSG_META_GET_OBJECT_FOR_SEARCH_SPELL 651















typedef enum {
    CL_STARTING_AT_POSITION,

    CL_ENDING_AT_POSITION,

    CL_CENTERED_AROUND_POSITION,

    CL_CENTERED_AROUND_SELECTION,

    CL_CENTERED_AROUND_SELECTION_START,

    CL_GET_SELECTED_WORD

} ContextLocation;






#define MSG_META_GET_CONTEXT 652



















#define MSG_META_GENERATE_CONTEXT_NOTIFICATION 653















typedef struct {
    optr    	    CD_object;
    
	
    dword   	    CD_numChars;
    

    VisTextRange    CD_range;
    

    VisTextRange    CD_selection;
    
} ContextData;


#define MSG_META_CONTEXT 654











#define MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL 655











































































typedef ByteFlags SpellCheckFromOffsetFlags;
#define SCFOF_CHECK_NUM_CHARS		0x01




























typedef ByteFlags SearchFromOffsetFlags;
#define SFOF_STOP_AT_STARTING_POINT	0x01


typedef struct {
    optr	SFORS_object;	

    dword	SFORS_offset;	

    dword	SFORS_len;	
} SearchFromOffsetReturnStruct;



































typedef WordFlags   ReplaceAllFromOffsetFlags;
#define	RAFOF_CONTINUING_REPLACE    0x8000



 
#define	RAFOF_HAS_UNDO 	    	    0x4000























































typedef ByteEnum VisTextFilterClass;
#define VTFC_NO_FILTER	 		0	
#define VTFC_ALPHA 			1	
#define VTFC_NUMERIC	 		2	
#define VTFC_SIGNED_NUMERIC	 	3	
#define VTFC_SIGNED_DECIMAL	 	4	
#define VTFC_FLOAT_DECIMAL	 	5	
#define VTFC_ALPHA_NUMERIC 		6	
#define VTFC_FILENAMES	 		7	
#define VTFC_DOS_FILENAMES 		8	
#define VTFC_DOS_PATH 			9	
#define VTFC_DATE 			10	
#define VTFC_TIME	 		11 	
#define VTFC_DASHED_ALPHA_NUMERIC 	12	
#define VTFC_NORMAL_ASCII 		13	
#define VTFC_DOS_VOLUME_NAMES 		14	
#define VTFC_DOS_CHARACTER_SET 		15	
#define VTFC_ALLOW_COLUMN_BREAKS 	16	

typedef ByteFlags VisTextFilters;
#define VTF_NO_SPACES		0x80	




#define VTF_NO_TABS		0x40	
#define VTF_UPCASE_CHARS    	0x20	
#define VTF_FILTER_CLASS	0x1f	





typedef enum  {
    VTKF_FORWARD_LINE=0,
    VTKF_BACKWARD_LINE=6,
    VTKF_SELECT_ADJUST_FORWARD_LINE=12,
    VTKF_SELECT_ADJUST_BACKWARD_LINE=18,
    VTKF_FORWARD_CHAR=24,
    VTKF_BACKWARD_CHAR=30,
    VTKF_FORWARD_WORD=36,
    VTKF_BACKWARD_WORD=42,
    VTKF_FORWARD_PARAGRAPH=48,
    VTKF_BACKWARD_PARAGRAPH=54,
    VTKF_START_OF_LINE=60,
    VTKF_END_OF_LINE=66,
    VTKF_START_OF_TEXT=72,
    VTKF_END_OF_TEXT=78,
    VTKF_SELECT_WORD=84,






	
    VTKF_SELECT_LINE=90,
    VTKF_SELECT_PARAGRAPH=96,
    VTKF_SELECT_OBJECT=102,


    VTKF_SELECT_ADJUST_FORWARD_CHAR=108,
    VTKF_SELECT_ADJUST_BACKWARD_CHAR=114,
    VTKF_SELECT_ADJUST_FORWARD_WORD=120,
    VTKF_SELECT_ADJUST_BACKWARD_WORD=126,
    VTKF_SELECT_ADJUST_FORWARD_PARAGRAPH=132,
    VTKF_SELECT_ADJUST_BACKWARD_PARAGRAPH=138,
    VTKF_SELECT_ADJUST_TO_START=144,
    VTKF_SELECT_ADJUST_TO_END=150,
    VTKF_SELECT_ADJUST_START_OF_LINE=156,
    VTKF_SELECT_ADJUST_END_OF_LINE=162,
    VTKF_DELETE_BACKWARD_CHAR=168,
    VTKF_DELETE_BACKWARD_WORD=174,
    VTKF_DELETE_BACKWARD_LINE=180,
    VTKF_DELETE_BACKWARD_PARAGRAPH=186,
    VTKF_DELETE_TO_START=192,
    VTKF_DELETE_CHAR=198,
    VTKF_DELETE_WORD=204,
    VTKF_DELETE_LINE=210,
    VTKF_DELETE_PARAGRAPH=216,
    VTKF_DELETE_TO_END=222,
    VTKF_DELETE_EVERYTHING=228,
    VTKF_DESELECT=234,
    VTKF_TOGGLE_OVERSTRIKE_MODE=240,
    VTKF_TOGGLE_SMART_QUOTES=246,
    VTKF_PAGE_UP=252,
    VTKF_PAGE_DOWN=258,
    VTKF_INSERT_TIME=264,
    VTKF_INSERT_DATE=270,
    VTKF_INSERT_NAME=276,
    VTKF_SELECT_ADJUST_BACKWARD_PAGE=282,
    VTKF_SELECT_ADJUST_FORWARD_PAGE=288
} VisTextKeyFunction;











































typedef ByteFlags VisTextGetTextRangeFlags;
#define VTGTRF_ALLOCATE	    	0x80	
					
#define VTGTRF_ALLOCATE_ALWAYS	0x40	
					
#define VTGTRF_RESIZE_DEST	0x20	





























































































































































typedef WordFlags VisTextHWRFlags;
#define	VTHWRF_NO_CONTEXT   	    0x8000





#define	VTHWRF_USE_PASSED_CONTEXT   0x4000























































































typedef	struct {
    LineInfo 	*VTGLIP_buffer;		
	



    word 	VTGLIP_bsize;		
    dword 	VTGLIP_line;		
} VisTextGetLineInfoParameters;

typedef	struct {
    word    	VTGLIRV_unused;
    word    	VTGLIRV_byteCount;
} VisTextGetLineInfoReturnValues;





















typedef struct {
    NameArrayElement	VTNAE_meta;	
    VisTextNameData	VTNAE_data;	
} VisTextNameArrayElement;

typedef	ByteFlags VisTextNameCommonFlags;
#define	VTNCF_COLOR_MONIKERS_FOR_UNSET_CONTEXTS	0x80
						





#define	VTNCF_DISABLE_MONIKERS_FOR_SET_CONTEXTS	0x40
						




typedef struct {
    VisTextNameData		VTNCP_data;	

    word    	    		VTNCP_index;    
    optr    	    		VTNCP_object;   
    word    	    		VTNCP_message;	
    VisTextNameCommonFlags	VTNCP_flags;	


    byte			VTNCP_unused;
} VisTextNameCommonParams;


 












 
 











 
 












 
 












 














 
typedef struct {
    VisTextRange VTFHLP_range;
} VisTextFollowHyperLinkParams;


























typedef struct {
    dword	VTGLOAFP_line;		
    dword	VTGLOAFP_offset;	
    LineFlags	VTGLOAFP_flags;		
} VisTextGetLineOffsetAndFlagsParameters;



 

























 























	
 	






































#define OFFSET_FOR_TYPE_RUNS	0
#define OFFSET_FOR_GRAPHIC_RUNS	1

















































typedef struct {
  word VTGFEPB_layerID;	    	
  word VTGFEPB_baselineOffset;
} VisTextGetFEPBounds;






























					 















typedef struct {
    dword   VTCOP_offset;	
    	    	    	    	
    sdword   VTCOP_xPos;	
    sdword   VTCOP_yPos;    	
} VisTextConvertOffsetParams;

































typedef WordFlags VisTextUpdateGraphicFlags;	
#define VTUGF_RECALC	    	(0x8000)    


#define VTUGF_NEW_ELEMENT	(0x4000)    




typedef enum {



    UGRV_MODIFIED_ELEMENT,
	

    UGRV_CREATED_NEW_ELEMENT,
	





    UGRV_INVALID_GRAPHIC_TYPE,
	

    UGRV_INVALID_GRAPHIC_FLAGS,
	

    UGRV_INVALID_GSTRING_SIZE,
	


    UGRV_INVALID_GSTRING_VMCHAIN_HANDLE,
	


    UGRV_INVALID_GSTRING_VMCHAIN,
	

    UGRV_INVALID_VARIABLE_TYPE,
	

    UGRV_INVALID_VARIABLE_VMCHAIN_HANDLE,
	


    UGRV_INVALID_VARIABLE_MANUFACTURER_ID,
	

    UGRV_INVALID_VARIABLE_PRIVATE_DATA,
	


} UpdateGraphicReturnValue;
































		








#define MSG_VIS_TEXT_SET_TEXT_MISC_MODE 768
























#define MSG_META_TEXT_SET_HYPERLINK 769














#define MSG_META_TEXT_FOLLOW_HYPERLINK 770





































 













 






















































 



























































typedef WordFlags VisTextFeatures;
#define VTF_NO_WORD_WRAPPING		0x8000
	
#define VTF_AUTO_HYPHENATE		0x4000
	
#define VTF_ALLOW_SMART_QUOTES		0x2000
	
#define VTF_ALLOW_UNDO			0x1000
	
#define VTF_SHOW_HIDDEN_TEXT		0x0800
	
#define VTF_OUTLINE_MODE		0x0400
	
#define VTF_DONT_SHOW_SOFT_PAGE_BREAKS	0x0200
	


#define VTF_DONT_SHOW_GRAPHICS		0x0100
	
#define VTF_TRANSPARENT			0x0080
	
#define VTF_USE_50_PCT_TEXT_MASK    	0x0040
	




typedef ByteFlags VisTextStates;
#define VTS_EDITABLE			0x80	
#define VTS_SELECTABLE			0x40	
#define VTS_TARGETABLE			0x20	
#define VTS_ONE_LINE			0x10	

#define VTS_SUBCLASS_VIRT_PHYS_TRANSLATION 0x08	



#define VTS_OVERSTRIKE_MODE		0x04	
#define VTS_USER_MODIFIED		0x02	












typedef ByteEnum SelectionType;
#define ST_DOING_CHAR_SELECTION 0	
#define ST_DOING_WORD_SELECTION 1
#define ST_DOING_LINE_SELECTION 2
#define ST_DOING_PARA_SELECTION 3

typedef ByteFlags VisTextIntSelFlags;
#define VTISF_IS_TARGET			0x80	
#define VTISF_IS_FOCUS			0x40	
#define VTISF_CURSOR_ON			0x20	
#define VTISF_CURSOR_ENABLED		0x10	
#define VTISF_DOING_SELECTION		0x08 	
#define VTISF_DOING_DRAG_SELECTION	0x04	




#define VTISF_SELECTION_TYPE		0x03 	




typedef ByteEnum AdjustType;
#define AT_NORMAL 	0
#define AT_NO_ADJUST 	1
#define AT_PASTE 	2
#define AT_QUICK 	3
#define AT_ENTIRE_RANGE 4

typedef ByteEnum ActiveSearchSpellType;
#define ASST_NOTHING_ACTIVE 0
#define ASST_SPELL_ACTIVE 1
#define ASST_SEARCH_ACTIVE 2

#define	ASST_OFFSET 3	

typedef ByteFlags VisTextIntFlags;
#define VTIF_HAS_LINES			0x80 
	
#define VTIF_SUSPENDED			0x40 
	
#define VTIF_UPDATE_PENDING		0x20
	
#define VTIF_ACTIVE_SEARCH_SPELL	0x18 
	


#define VTIF_HILITED			0x04
	
#define VTIF_ADJUST_TYPE		0x03 
	




typedef ByteFlags GSRefCountAndFlags;
#define GSRCAF_USE_DOC_CLIP_REGION	0x80
	
#define GSRCAF_REF_COUNT		0x7f






    #define ATTR_VIS_TEXT_TYPE_RUNS 18432

    #define ATTR_VIS_TEXT_GRAPHIC_RUNS 18436

    #define ATTR_VIS_TEXT_STYLE_ARRAY 18440

    #define ATTR_VIS_TEXT_NAME_ARRAY 18444


typedef struct {
    word    	    VTSD_count;
    VisTextRange    VTSD_recalcRange;		
    VisTextRange    VTSD_selectRange;		
    dword	    VTSD_showSelectionPos;	
    WordFlags	    VTSD_notifications;
    byte	    VTSD_needsRecalc;
} VisTextSuspendData;

    #define ATTR_VIS_TEXT_SUSPEND_DATA 18448


    #define ATTR_VIS_TEXT_NOTIFY_CONTENT 18452


    #define ATTR_VIS_TEXT_SELECTED_TAB 18456


    #define ATTR_VIS_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL 18460






    #define ATTR_VIS_TEXT_EXTENDED_FILTER 18464


    #define ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN 18468

    #define ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN 18472





typedef struct {
    dword	VTCRI_lastCharAttrRun;
    dword	VTCRI_lastParaAttrRun;
    dword	VTCRI_lastTypeRun;
    dword	VTCRI_lastGraphicRun;
} VisTextCachedRunInfo;

    #define TEMP_VIS_TEXT_CACHED_RUN_INFO 18476


    #define TEMP_VIS_TEXT_FORCE_SEND_IS_LAST_REGION 18480


typedef struct {
    VMChain   	    VTCUI_vmChain;
    VMFileHandle    VTCUI_file;
} VisTextCachedUndoInfo;

    #define TEMP_VIS_TEXT_CACHED_UNDO_INFO 18484


typedef struct {
    wchar    VTCFD_startOfRange;
    wchar    VTCFD_endOfRange;
} VisTextCustomFilterData;

    #define ATTR_VIS_TEXT_CUSTOM_FILTER 18488







    #define ATTR_VIS_TEXT_UPDATE_VIA_PROCESS 18492






    #define ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK 18496





    #define ATTR_VIS_TEXT_MINIMUM_SINGLE_LINE_HEIGHT 18500






    #define TEMP_VIS_TEXT_SYS_TARGET 18504




    #define ATTR_VIS_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED 18508








    #define ATTR_VIS_TEXT_DO_NOT_NOTIFY_CONTENT 18512




    #define ATTR_VIS_TEXT_ADD_SPACE_ON_TOP_TO_FIRST_LINE_OF_REGION 18516
























    #define ATTR_VIS_TEXT_ADD_SPACE_TO_ALL_LINES 18520
































    #define ATTR_VIS_TEXT_NOTIFY_CURSOR_POSITION 18524











    #define TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_TIME 18528


typedef struct {
    word    TVTNCPID_handle;
    word    TVTNCPID_id;
} TVTNCPIData;

    #define TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO 18532


    #define TEMP_VIS_TEXT_FREEING_OBJECT 18536






    #define TEMP_VIS_TEXT_UNDO_FOR_SUSPEND 18540










    #define ATTR_VIS_TEXT_DISABLE_OPTIMIZED_REDRAW 18544
 











#define ATTR_VIS_TEXT_DONT_SHOW_POSITION_ON_GAINED_TARGET_EXCL 18548









#define ATTR_VIS_TEXT_SHOW_POSITION_ON_GAINED_TARGET_EXCL 18552









#define ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR 18556











#define ATTR_VIS_TEXT_NO_FEP 18560














#define ATTR_VIS_TEXT_NOTIFY_EVEN_IF_NOT_TARGETED 18564










#define ATTR_VIS_TEXT_XOR_SELECTION 18568

















typedef enum  {
    VTCT_NORMAL_CURSOR=0,
    VTCT_CAPLOCK_CURSOR=2,
    VTCT_NUMLOCK_CURSOR=4,
    VTCT_EQNLOCK_CURSOR=6,
} VisTextCursorType;

#define TEMP_VIS_TEXT_CURSOR_TYPE 18572










#define ATTR_VIS_TEXT_CURSOR_NO_FOCUS 18576










#define ATTR_VIS_TEXT_NO_CURSOR 18580










#define ATTR_VIS_TEXT_ALLOW_FULLWIDTH_DIGITS 18584












    
	

    
	

    
	

    
	

    
	




    

    
    




    
    

    
	

    
	

    
	




    
	

    
	

    
	







	;
    
    
	





    
	





    



    
	

    
	

    
	






    
    
	

    





	

    
	



    
	

    




    
	

    
	




    
    

extern ClassStruct _far VisTextClass; extern Message _Messages_VisTextClass[]; extern MessageMethod *_Methods_VisTextClass[]; extern CMethodDef _htypes_VisTextClass[];extern MessageMethod *_Reloc_VisTextClass;
typedef struct _VisTextInstance {

# 883 "/staff/pcgeos/CInclude/Objects/visC.goh"
    Rectangle VI_bounds;
    VisTypeFlags VI_typeFlags;

    VisAttrs VI_attrs;



    VisOptFlags VI_optFlags;
    VisGeoAttrs VI_geoAttrs;
    SpecAttrs VI_specAttrs;
    LinkPart VI_link;
# 5429 "/staff/pcgeos/CInclude/Objects/vTextC.goh"
    ChunkHandle VTI_text;


    word VTI_charAttrRuns;


    word VTI_paraAttrRuns;


    VMFileHandle VTI_vmFile;


    word VTI_lines;






    VisTextStorageFlags VTI_storageFlags;
    VisTextFeatures VTI_features;
    VisTextStates VTI_state;




    VisTextIntFlags VTI_intFlags;
    VisTextIntSelFlags VTI_intSelFlags;

    GSRefCountAndFlags VTI_gsRefCount;


    GStateHandle VTI_gstate;


    word VTI_gstateRegion;





    dword VTI_selectStart;


    dword VTI_selectEnd;


    PointDWord VTI_startEventPos;









    dword VTI_selectMinStart;
    dword VTI_selectMinEnd;






    dword VTI_lastOffset;






    word VTI_goalPosition;



    Point VTI_cursorPos;


    word VTI_cursorRegion;


    word VTI_leftOffset;







    byte VTI_lrMargin;
    byte VTI_tbMargin;







    ColorQuad VTI_washColor;


    word VTI_maxLength;




    VisTextFilters VTI_filters;


    optr VTI_output;




    WBFixed VTI_height;


    word VTI_lastWidth;





    TimerHandle VTI_timerHandle;
    word VTI_timerID;} VisTextInstance; 
# 5556 "/staff/pcgeos/CInclude/Objects/vTextC.goh"
typedef enum{MSG_VIS_TEXT_GET_RANGE=18432,MSG_VIS_TEXT_SET_CHAR_ATTR_BY_DEFAULT,MSG_VIS_TEXT_SET_CHAR_ATTR,MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN,MSG_VIS_TEXT_GET_CHAR_ATTR,MSG_VIS_TEXT_ADD_CHAR_ATTR,MSG_VIS_TEXT_REMOVE_CHAR_ATTR,MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT,MSG_VIS_TEXT_SET_PARA_ATTR,MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN,MSG_VIS_TEXT_SET_BORDER_BITS,MSG_VIS_TEXT_SET_BORDER_WIDTH,MSG_VIS_TEXT_SET_BORDER_SPACING,MSG_VIS_TEXT_SET_BORDER_SHADOW,MSG_VIS_TEXT_SET_LINE_SPACING,MSG_VIS_TEXT_SET_DEFAULT_TABS,MSG_VIS_TEXT_SET_LEFT_MARGIN,MSG_VIS_TEXT_SET_RIGHT_MARGIN,MSG_VIS_TEXT_SET_PARA_MARGIN,MSG_VIS_TEXT_SET_LEFT_AND_PARA_MARGIN,MSG_VIS_TEXT_SET_SPACE_ON_TOP,MSG_VIS_TEXT_SET_SPACE_ON_BOTTOM,MSG_VIS_TEXT_SET_LEADING,MSG_VIS_TEXT_SET_PARA_BG_COLOR,MSG_VIS_TEXT_SET_PARA_BG_GRAY_SCREEN,MSG_VIS_TEXT_SET_PARA_BG_PATTERN,MSG_VIS_TEXT_SET_TAB,MSG_VIS_TEXT_CLEAR_TAB,MSG_VIS_TEXT_MOVE_TAB,MSG_VIS_TEXT_CLEAR_ALL_TABS,MSG_VIS_TEXT_SET_PREPEND_CHARS,MSG_VIS_TEXT_SET_HYPHENATION_PARAMS,MSG_VIS_TEXT_SET_DROP_CAP_PARAMS,MSG_VIS_TEXT_SET_KEEP_PARAMS,MSG_VIS_TEXT_SET_PARAGRAPH_NUMBER,MSG_VIS_TEXT_GET_PARA_ATTR,MSG_VIS_TEXT_ADD_PARA_ATTR,MSG_VIS_TEXT_REMOVE_PARA_ATTR,MSG_VIS_TEXT_SUBST_ATTR_TOKEN,MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE,MSG_VIS_TEXT_SET_HYPERLINK,MSG_VIS_TEXT_SET_CONTEXT,MSG_VIS_TEXT_GET_TYPE=18475,MSG_VIS_TEXT_ADD_TYPE,MSG_VIS_TEXT_REMOVE_TYPE,MSG_VIS_TEXT_ADD_NAME,MSG_VIS_TEXT_FIND_NAME,MSG_VIS_TEXT_FIND_NAME_BY_TOKEN,MSG_VIS_TEXT_ADD_REF_FOR_NAME,MSG_VIS_TEXT_REMOVE_NAME,MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC,MSG_VIS_TEXT_GET_GRAPHIC_AT_POSITION,MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE,MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW,MSG_VIS_TEXT_GRAPHIC_VARIABLE_START_SELECT,MSG_VIS_TEXT_GRAPHIC_VARIABLE_OPEN,MSG_VIS_TEXT_GRAPHIC_VARIABLE_CLOSE,MSG_VIS_TEXT_SAVE_TO_DB_ITEM,MSG_VIS_TEXT_SAVE_TO_DB_ITEM_WITH_STYLES,MSG_VIS_TEXT_LOAD_FROM_DB_ITEM,MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_WITH_STYLES,MSG_VIS_TEXT_SET_VM_FILE,MSG_VIS_TEXT_CREATE_STORAGE,MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY,MSG_VIS_TEXT_FREE_STORAGE,MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT,MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT,MSG_VIS_TEXT_REPLACE_ALL_PTR,MSG_VIS_TEXT_REPLACE_ALL_OPTR,MSG_VIS_TEXT_REPLACE_ALL_BLOCK,MSG_VIS_TEXT_REPLACE_ALL_VM_BLOCK,MSG_VIS_TEXT_REPLACE_ALL_DB_ITEM,MSG_VIS_TEXT_REPLACE_ALL_HUGE_ARRAY,MSG_VIS_TEXT_REPLACE_SELECTION_PTR,MSG_VIS_TEXT_REPLACE_SELECTION_OPTR,MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK,MSG_VIS_TEXT_REPLACE_SELECTION_VM_BLOCK,MSG_VIS_TEXT_REPLACE_SELECTION_DB_ITEM,MSG_VIS_TEXT_REPLACE_SELECTION_HUGE_ARRAY,MSG_VIS_TEXT_APPEND_PTR,MSG_VIS_TEXT_APPEND_OPTR,MSG_VIS_TEXT_APPEND_BLOCK,MSG_VIS_TEXT_APPEND_VM_BLOCK,MSG_VIS_TEXT_APPEND_DB_ITEM,MSG_VIS_TEXT_APPEND_HUGE_ARRAY,MSG_VIS_TEXT_GET_ALL_PTR,MSG_VIS_TEXT_GET_ALL_OPTR,MSG_VIS_TEXT_GET_ALL_BLOCK,MSG_VIS_TEXT_GET_ALL_VM_BLOCK,MSG_VIS_TEXT_GET_ALL_DB_ITEM,MSG_VIS_TEXT_GET_ALL_HUGE_ARRAY,MSG_VIS_TEXT_GET_SELECTION_PTR,MSG_VIS_TEXT_GET_SELECTION_OPTR,MSG_VIS_TEXT_GET_SELECTION_BLOCK,MSG_VIS_TEXT_GET_SELECTION_VM_BLOCK,MSG_VIS_TEXT_GET_SELECTION_DB_ITEM,MSG_VIS_TEXT_GET_SELECTION_HUGE_ARRAY,MSG_VIS_TEXT_DELETE_ALL,MSG_VIS_TEXT_DELETE_SELECTION,MSG_VIS_TEXT_GET_SELECTION_RANGE,MSG_VIS_TEXT_SELECT_RANGE_SMALL,MSG_VIS_TEXT_SELECT_ALL,MSG_VIS_TEXT_SELECT_START,MSG_VIS_TEXT_SELECT_END,MSG_VIS_TEXT_SELECT_RELATIVE,MSG_VIS_TEXT_GET_STATE,MSG_VIS_TEXT_GET_FEATURES,MSG_VIS_TEXT_SET_FEATURES,MSG_VIS_TEXT_SET_MAX_LENGTH,MSG_VIS_TEXT_GET_MAX_LENGTH,MSG_VIS_TEXT_GET_USER_MODIFIED_STATE,MSG_VIS_TEXT_SET_NOT_USER_MODIFIED,MSG_VIS_TEXT_SET_USER_MODIFIED,MSG_VIS_TEXT_SET_WASH_COLOR,MSG_VIS_TEXT_GET_WASH_COLOR,MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE,MSG_VIS_TEXT_UPDATE_GENERIC,MSG_VIS_TEXT_GENERATE_NOTIFY,MSG_VIS_TEXT_CHAR_ATTR_VIRTUAL_TO_PHYSICAL,MSG_VIS_TEXT_PARA_ATTR_VIRTUAL_TO_PHYSICAL,MSG_VIS_TEXT_EDIT_DRAW,MSG_VIS_TEXT_SHOW_SELECTION,MSG_VIS_TEXT_HEIGHT_NOTIFY,MSG_VIS_TEXT_ENTER_OVERSTRIKE_MODE,MSG_VIS_TEXT_ENTER_INSERT_MODE,MSG_VIS_TEXT_GET_MINIMUM_DIMENSIONS,MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS,MSG_VIS_TEXT_FILTER_VIA_CHARACTER,MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER,MSG_VIS_TEXT_LOAD_STYLE_SHEET,MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS,MSG_VIS_TEXT_GET_MIN_WIDTH,MSG_VIS_TEXT_GET_AVERAGE_CHAR_WIDTH,MSG_VIS_TEXT_CALC_HEIGHT,MSG_VIS_TEXT_GET_LINE_HEIGHT,MSG_VIS_TEXT_RECALC_AND_DRAW,MSG_VIS_TEXT_GET_ONE_LINE_WIDTH,MSG_VIS_TEXT_GET_SIMPLE_MIN_WIDTH,MSG_VIS_TEXT_SCROLL_ONE_LINE,MSG_VIS_TEXT_GET_SCROLL_AMOUNT,MSG_VIS_TEXT_SCROLL_PAGE_UP,MSG_VIS_TEXT_SCROLL_PAGE_DOWN,MSG_VIS_TEXT_SCREEN_UPDATE,MSG_VIS_TEXT_FLASH_CURSOR_ON,MSG_VIS_TEXT_FLASH_CURSOR_OFF,MSG_VIS_TEXT_SPELL_CHECK_FROM_OFFSET,MSG_VIS_TEXT_SEARCH_FROM_OFFSET,MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_FROM_OFFSET,MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_IN_RANGE,MSG_VIS_TEXT_DO_KEY_FUNCTION=18583,MSG_VIS_TEXT_REPLACE_TEXT,MSG_VIS_TEXT_GET_TEXT_RANGE,MSG_VIS_TEXT_SELECT_RANGE,MSG_VIS_TEXT_SHOW_POSITION,MSG_VIS_TEXT_SET_FILTER,MSG_VIS_TEXT_GET_FILTER,MSG_VIS_TEXT_SET_OUTPUT,MSG_VIS_TEXT_GET_OUTPUT,MSG_VIS_TEXT_SET_LR_MARGIN,MSG_VIS_TEXT_GET_LR_MARGIN,MSG_VIS_TEXT_SET_TB_MARGIN,MSG_VIS_TEXT_GET_TB_MARGIN,MSG_VIS_TEXT_REPLACE_WITH_HWR,MSG_VIS_TEXT_SET_HWR_CONTEXT,MSG_VIS_TEXT_SET_HWR_FILTER,MSG_VIS_TEXT_SET_SELECTED_TAB,MSG_VIS_TEXT_GET_TEXT_SIZE,MSG_VIS_TEXT_INVALIDATE_RANGE,MSG_VIS_TEXT_ATTRIBUTE_CHANGE,MSG_VIS_TEXT_GET_LINE_INFO,MSG_VIS_TEXT_DEFINE_NAME,MSG_VIS_TEXT_DELETE_NAME,MSG_VIS_TEXT_RENAME_NAME,MSG_VIS_TEXT_UPDATE_NAME_LIST,MSG_VIS_TEXT_GET_NAME_LIST_MONIKER,MSG_VIS_TEXT_FOLLOW_HYPERLINK,MSG_VIS_TEXT_GET_LINE_FROM_OFFSET,MSG_VIS_TEXT_GET_LINE_OFFSET_AND_FLAGS,MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD,MSG_VIS_TEXT_GET_NAME_LIST_NAME_TYPE,MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED,MSG_VIS_TEXT_SET_SPELL_IN_PROGRESS,MSG_VIS_TEXT_SET_SEARCH_IN_PROGRESS,MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT,MSG_VIS_TEXT_GET_RUN_BOUNDS,MSG_VIS_TEXT_FREE_ALL_STORAGE,MSG_VIS_TEXT_GENERATE_CURSOR_POSITION_NOTIFICATION,MSG_VIS_TEXT_GET_SELECTION_START,MSG_VIS_TEXT_GET_GSTATE,MSG_VIS_TEXT_GET_FEP_BOUNDS,MSG_VIS_TEXT_DELETE_ALL_HYPERLINKS,MSG_VIS_TEXT_UNSET_ALL_CONTEXTS,MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE,MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE,MSG_VIS_TEXT_UPDATE_GRAPHIC_ELEMENT,MSG_VIS_TEXT_NAME_TOKENS_TO_LIST_INDICES,MSG_VIS_TEXT_FIND_NAME_BY_INDEX,MSG_VIS_TEXT_REGION_FROM_POINT,MSG_VIS_TEXT_GET_NAME_LIST_MONIKER_FRAME,MSG_VIS_TEXT_GET_SINGLE_CHAR_ATTR,MSG_VIS_TEXT_SET_CONTEXT_GIVEN_NAME_TEXT,MSG_VIS_TEXT_REDIRECT_HYPERLINKS,}VisTextMessages;


pragma Alias(TextSearchInString, "TEXTSEARCHINSTRING");
pragma Alias(TextSearchInHugeArray, "TEXTSEARCHINHUGEARRAY");
pragma Alias(TextMapDefaultCharAttr, "TEXTMAPDEFAULTCHARATTR");
pragma Alias(TextFindDefaultCharAttr, "TEXTFINDDEFAULTCHARATTR");
pragma Alias(TextMapDefaultParaAttr, "TEXTMAPDEFAULTPARAATTR");
pragma Alias(TextFindDefaultParaAttr, "TEXTFINDDEFAULTPARAATTR");
pragma Alias(TextGetSystemCharAttrRun, "TEXTGETSYSTEMCHARATTRRUN");
pragma Alias(TextSetHyphenationCall, "TEXTSETHYPHENATIONCALL");
pragma Alias(TextAllocClipboardObject, "TEXTALLOCCLIPBOARDOBJECT");
pragma Alias(TextFinishWithClipboardObject, "TEXTFINISHWITHCLIPBOARDOBJECT");
pragma Alias(VisTextFormatNumber, "VISTEXTFORMATNUMBER");
pragma Alias(MsgVisTextLoadStyleSheetParams, "MSGVISTEXTLOADSTYLESHEETPARAMS");
pragma Alias(GetTokenForPosition, "GETTOKENFORPOSITION");







#endif

# 25 "/staff/pcgeos/CInclude/Objects/gTextC.goh"



#define GenTextBase GenBase
#define _FIRST_GenTextClass 26624
# 28 "/staff/pcgeos/CInclude/Objects/gTextC.goh"


		



  



 
   


 
   


  

   
   

   
   



    #define ATTR_GEN_TEXT_STATUS_MSG 26624

    #define ATTR_GEN_TEXT_UNUSED 26628

    #define ATTR_GEN_TEXT_SELECTABLE 26632


    #define HINT_TEXT_WASH_COLOR 26636

    #define HINT_TEXT_WHITE_WASH_COLOR 26640

    #define ATTR_GEN_TEXT_DEFAULT_CHAR_ATTR 26644

    #define ATTR_GEN_TEXT_DEFAULT_PARA_ATTR 26648

    #define ATTR_GEN_TEXT_CHAR_ATTR 26652

    #define ATTR_GEN_TEXT_MULTIPLE_CHAR_ATTR_RUNS 26656

    #define ATTR_GEN_TEXT_PARA_ATTR 26660

    #define ATTR_GEN_TEXT_MULTIPLE_PARA_ATTR_RUNS 26664


    #define ATTR_GEN_TEXT_UNUSED_1 26668

    #define HINT_TEXT_AUTO_HYPHENATE 26672

    #define HINT_TEXT_SELECT_TEXT 26676

    #define HINT_TEXT_CURSOR_AT_START 26680

    #define HINT_TEXT_CURSOR_AT_END 26684

    #define HINT_TEXT_FRAME 26688

    #define HINT_TEXT_NO_FRAME 26692

    #define HINT_TEXT_ALLOW_UNDO 26696

    #define HINT_TEXT_ALLOW_SMART_QUOTES 26700

    #define ATTR_GEN_TEXT_ALPHA 26704

    #define ATTR_GEN_TEXT_NUMERIC 26708

    #define ATTR_GEN_TEXT_SIGNED_NUMERIC 26712

    #define ATTR_GEN_TEXT_SIGNED_DECIMAL 26716

    #define ATTR_GEN_TEXT_FLOAT_DECIMAL 26720
  
    #define ATTR_GEN_TEXT_ALPHA_NUMERIC 26724

    #define ATTR_GEN_TEXT_LEGAL_FILENAMES 26728

    #define ATTR_GEN_TEXT_LEGAL_DOS_FILENAMES 26732

    #define ATTR_GEN_TEXT_LEGAL_DOS_PATH 26736

    #define ATTR_GEN_TEXT_DATE 26740

    #define ATTR_GEN_TEXT_TIME 26744

    #define ATTR_GEN_TEXT_MAKE_UPPERCASE 26748

    #define ATTR_GEN_TEXT_ALLOW_COLUMN_BREAKS 26752

    #define ATTR_GEN_TEXT_DASHED_ALPHA_NUMERIC 26756

    #define ATTR_GEN_TEXT_NORMAL_ASCII 26760

    #define ATTR_GEN_TEXT_LEGAL_DOS_VOLUME_NAMES 26764

    #define ATTR_GEN_TEXT_DOS_CHARACTER_SET 26768

    #define ATTR_GEN_TEXT_NO_SPACES 26772

    #define ATTR_GEN_TEXT_ALLOW_SPACES 26776

    #define ATTR_GEN_TEXT_EXTENDED_FILTER 26780



    #define ATTR_GEN_TEXT_TYPE_RUNS 26784

    #define ATTR_GEN_TEXT_GRAPHIC_RUNS 26788

    #define ATTR_GEN_TEXT_STYLE_ARRAY 26792

    #define ATTR_GEN_TEXT_NAME_ARRAY 26796


    #define ATTR_GEN_TEXT_RUNS_ITEM_GROUP 26800

    
    
    #define HINT_TEXT_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS 26804

    #define ATTR_GEN_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL 26808

    #define ATTR_GEN_TEXT_SET_OBJECT_ENABLED_WHEN_TEXT_EXISTS 26812

    
    #define ATTR_GEN_TEXT_NEVER_MAKE_SCROLLABLE 26816

    #define ATTR_GEN_TEXT_DOES_NOT_ACCEPT_INK 26820

    #define ATTR_GEN_TEXT_CUSTOM_FILTER 26824




    #define ATTR_GEN_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED 26828






    #define ATTR_GEN_TEXT_DONT_BEEP_ON_INSERTION_ERROR 26832






#define ATTR_GEN_TEXT_NO_FEP 26836














#define HINT_TEXT_UNDERLINE 26840

#define HINT_TEXT_NO_UNDERLINE 26844



#define ATTR_GEN_TEXT_XOR_SELECTION 26848













#define ATTR_GEN_TEXT_CURSOR_NO_FOCUS 26852










#define HINT_TEXT_DISPLAY_FOCUSABLE 26856






#define ATTR_GEN_TEXT_NO_CURSOR 26860










#define ATTR_GEN_TEXT_ALLOW_FULLWIDTH_DIGITS 26864















typedef ByteFlags GenTextStateFlags;
#define GTSF_INDETERMINATE	0x80
#define	GTSF_MODIFIED		0x40

typedef ByteFlags GenTextAttrs;
#define GTA_SINGLE_LINE_TEXT		0x80
#define GTA_USE_TAB_FOR_NAVIGATION	0x40
#define GTA_INIT_SCROLLING		0x20
#define GTA_NO_WORD_WRAPPING		0x10
#define GTA_ALLOW_TEXT_OFF_END		0x08
#define GTA_TAIL_ORIENTED		0x04
#define GTA_DONT_SCROLL_TO_CHANGES	0x02



    
    
    
    
    
    

extern ClassStruct _far GenTextClass; extern Message _Messages_GenTextClass[]; extern MessageMethod *_Methods_GenTextClass[]; extern CMethodDef _htypes_GenTextClass[];extern MessageMethod *_Reloc_GenTextClass;
typedef struct _GenTextInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 217 "/staff/pcgeos/CInclude/Objects/gTextC.goh"
    ChunkHandle GTXI_text;
    word GTXI_maxLength;
    GenTextAttrs GTXI_attrs;
    GenTextStateFlags GTXI_stateFlags;
    optr GTXI_destination;
    word GTXI_applyMsg;} GenTextInstance; 
# 224 "/staff/pcgeos/CInclude/Objects/gTextC.goh"
typedef enum{MSG_GEN_TEXT_SET_ATTRS=26624,MSG_GEN_TEXT_GET_ATTRS,MSG_GEN_TEXT_SET_INDETERMINATE_STATE,MSG_GEN_TEXT_IS_INDETERMINATE,MSG_GEN_TEXT_SET_MODIFIED_STATE,MSG_GEN_TEXT_IS_MODIFIED,MSG_GEN_TEXT_SEND_STATUS_MSG,MSG_GEN_TEXT_GET_DESTINATION,MSG_GEN_TEXT_SET_DESTINATION,MSG_GEN_TEXT_GET_APPLY_MSG,MSG_GEN_TEXT_SET_APPLY_MSG,MSG_GEN_TEXT_SET_FROM_ITEM_GROUP,}GenTextMessages;





#endif

# 52 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgInterC
#define __GOCgInterC
#include "/staff/pcgeos/CInclude/Objects/gInterC.poh"
#endif

# 53 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgFSelC
#define __GOCgFSelC

# 1 "/staff/pcgeos/CInclude/Objects/gFSelC.goh"




















#include <file.h>
#include <geode.h>

#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gFSelC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/gFSelC.goh"
#include <fileEnum.h>		

#define GenFileSelectorBase GenBase
#define _FIRST_GenFileSelectorClass 26624
# 27 "/staff/pcgeos/CInclude/Objects/gFSelC.goh"


typedef WordFlags FileSelectorFileCriteria;

#define FSFC_DIRS			0x8000
#define FSFC_NON_GEOS_FILES		0x4000
#define FSFC_GEOS_EXECUTABLES		0x2000
#define FSFC_GEOS_NON_EXECUTABLES	0x1000
#define FSFC_MASK_CASE_INSENSITIVE	0x0800
#define FSFC_FILE_FILTER		0x0400
#define FSFC_FILTER_IS_C		0x0200
#define FSFC_TOKEN_NO_ID		0x0100
#define FSFC_USE_MASK_FOR_DIRS		0x0080
#define FSFC_USE_FAKE_FILE_SYSTEM	0x0040




typedef WordFlags FileSelectorAttrs;

#define FSA_ALLOW_CHANGE_DIRS		0x8000

#define FSA_SHOW_FIXED_DISKS_ONLY	0x2000
#define FSA_SHOW_FILES_DISABLED		0x1000
#define FSA_HAS_CLOSE_DIR_BUTTON	0x0800
#define FSA_HAS_OPEN_DIR_BUTTON		0x0400
#define FSA_HAS_DOCUMENT_BUTTON		0x0200
#define FSA_HAS_CHANGE_DIRECTORY_LIST	0x0100
#define FSA_HAS_CHANGE_DRIVE_LIST	0x0080
#define FSA_HAS_FILE_LIST		0x0040
#define FSA_USE_VIRTUAL_ROOT		0x0020
#define FSA_SHOW_WRITABLE_DISKS_ONLY	0x0010





typedef ByteEnum GenFileSelectorEntryType;
#define GFSET_FILE 0
#define GFSET_SUBDIR 1
#define GFSET_VOLUME 2

typedef WordFlags GenFileSelectorEntryFlags;

#define GFSEF_TYPE		0xc000
#define GFSEF_OPEN		0x2000
#define GFSEF_NO_ENTRIES	0x1000
#define GFSEF_ERROR		0x0800
#define GFSEF_TEMPLATE		0x0400
#define GFSEF_SHARED_MULTIPLE	0x0200
#define GFSEF_SHARED_SINGLE	0x0100
#define GFSEF_READ_ONLY		0x0080
#define GFSEF_PARENT_DIR	0x0040
#define GFSEF_DISABLED          0x0020 

#define GFSEF_TYPE_OFFSET	14

#define GFS_GET_ENTRY_TYPE(A) (((A) & GFSEF_TYPE) >> GFSEF_TYPE_OFFSET)




typedef FileLongName GenFileSelectorMask;
typedef VolumeName GenFileSelectorVolume;
typedef FileLongName GenFileSelectorSelection;

#define GFS_GET_ENTRY_NUMBER(A) ((word) ((A) >> 16))
#define GFS_GET_ENTRY_FLAGS(A)	((word) (A))







#define GFS_GET_FULL_SELECTION_PATH_DISK_HANDLE(A) ((DiskHandle) ((A) >> 16))












#define GET_MATCH_FILE_ATTRS(attr)	((byte) (attr))
#define GET_MISMATCH_FILE_ATTRS(attr)	((byte) ((attr) >> 8))






typedef struct {
    GeodeToken	GTP_token;
    word	GTP_unused;
} GetTokenCreatorParams;











#define SET_TOKEN_CHARS(A, B, C, D) ((A) | ((B) << 8) | ((C) << 16) | ((D) << 24))


 





 

#define GET_MATCH_ATTRS(attr) (((attr) >> 16) & 0xffff)
#define GET_MISMATCH_ATTRS(attr) ((attr) & 0xffff)
 





typedef struct {
    Message		GAP_message;
    word		GAP_unused;
    optr		GAP_output;
} GetActionParams;






 

 


 

	


 





	









typedef Boolean GenFileSelectorFilterRoutine (optr oself,
					      FileEnumCallbackData *fecd,
					      word frame);
typedef struct {
	GenFileSelectorFilterRoutine *filterRoutine;
	const FileExtAttrDesc	*filterAttrs;
} GenFileSelectorGetFilterRoutineResults;
				



















































































    #define TEMP_GEN_FILE_SELECTOR_DATA 26624
 

    #define ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH 26628

    #define ATTR_GEN_FILE_SELECTOR_CREATOR_MATCH 26632


    typedef struct {
	FileAttrs GFSFA_match;
	FileAttrs GFSFA_mismatch;
    } GenFileSelectorFileAttrs;
    #define ATTR_GEN_FILE_SELECTOR_FILE_ATTR 26636


    typedef struct {
	GeodeAttrs GFSGA_match;
	GeodeAttrs GFSGA_mismatch;
    } GenFileSelectorGeodeAttrs;
    #define ATTR_GEN_FILE_SELECTOR_GEODE_ATTR 26640


    #define ATTR_GEN_FILE_SELECTOR_NAME_MASK 26644


    #define ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT 26648

 
    #define HINT_FILE_SELECTOR_NUMBER_OF_FILES_TO_SHOW 26652


typedef ByteEnum GenFileSelectorScalableUICommand;
#define GFSSUIC_SET_FEATURES_IF_APP_FEATURE_ON 0
#define GFSSUIC_SET_FEATURES_IF_APP_FEATURE_OFF 1
#define GFSSUIC_ADD_FEATURES_IF_APP_FEATURE_ON 2
#define GFSSUIC_SET_FEATURES_IF_APP_LEVEL 3
#define GFSSUIC_ADD_FEATURES_IF_APP_LEVEL 4

typedef struct {
    GenFileSelectorScalableUICommand	GFSSUIE_command;
    WordFlags				GFSSUIE_appFeature;
    FileSelectorAttrs			GFSSUIE_fsFeatures;
} GenFileSelectorScalableUIEntry;

#define FLEXIBLE_ARRAY_SIZE 100
 




typedef GenFileSelectorScalableUIEntry  
		GenFileSelectorScalableUIEntryArray[FLEXIBLE_ARRAY_SIZE];

    #define HINT_FILE_SELECTOR_SCALABLE_UI_DATA 26656





typedef FilePathID FilePathIDArray[FLEXIBLE_ARRAY_SIZE];

    #define TEMP_GEN_FILE_SELECTOR_DIR_IDS 26660


    #define HINT_FILE_SELECTOR_FILE_LIST_WIDTH 26664


    #define HINT_FILE_SELECTOR_USE_DESKTOP_HOME 26668


    #define TEMP_GEN_FILE_SELECTOR_HOME_DIRECTORY 26672


    #define HINT_FILE_SELECTOR_SINGLE_ACTION 26676


    #define HINT_FILE_SELECTOR_SHOW_FILE_SIZE 26680



    typedef struct {
	GeosFileHeaderFlags GFSFHF_match;
	GeosFileHeaderFlags GFSFHF_mismatch;
    } GenFileSelectorFileHeaderFlags;

    #define ATTR_GEN_FILE_SELECTOR_FILE_HEADER_FLAGS 26684












    #define HINT_FILE_SELECTOR_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS 26688







    #define HINT_FILE_SELECTOR_MINIMIZE_WIDTH 26692












    #define HINT_FILE_SELECTOR_ALWAYS_SORT_ALPHABETICALLY 26696










    #define HINT_FILE_SELECTOR_DONT_SORT 26700






    #define HINT_FILE_SELECTOR_REVERSE_SORT 26704










    

    



    





    
    
extern ClassStruct _far GenFileSelectorClass; extern Message _Messages_GenFileSelectorClass[]; extern MessageMethod *_Methods_GenFileSelectorClass[]; extern CMethodDef _htypes_GenFileSelectorClass[];extern MessageMethod *_Reloc_GenFileSelectorClass;
typedef struct _GenFileSelectorInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 414 "/staff/pcgeos/CInclude/Objects/gFSelC.goh"
    GenFileSelectorSelection GFSI_selection;



    FileSelectorFileCriteria GFSI_fileCriteria;





    FileSelectorAttrs GFSI_attrs;

    optr GFSI_destination;
    Message GFSI_notificationMsg;} GenFileSelectorInstance; 
# 428 "/staff/pcgeos/CInclude/Objects/gFSelC.goh"
typedef enum{MSG_GEN_FILE_SELECTOR_GET_SELECTION=26624,MSG_GEN_FILE_SELECTOR_SET_SELECTION,MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH,MSG_GEN_FILE_SELECTOR_SET_FULL_SELECTION_PATH,MSG_GEN_FILE_SELECTOR_GET_MASK,MSG_GEN_FILE_SELECTOR_SET_MASK,MSG_GEN_FILE_SELECTOR_GET_FILE_ATTRS,MSG_GEN_FILE_SELECTOR_SET_FILE_ATTRS,MSG_GEN_FILE_SELECTOR_GET_TOKEN,MSG_GEN_FILE_SELECTOR_SET_TOKEN,MSG_GEN_FILE_SELECTOR_GET_CREATOR,MSG_GEN_FILE_SELECTOR_SET_CREATOR,MSG_GEN_FILE_SELECTOR_GET_GEODE_ATTRS,MSG_GEN_FILE_SELECTOR_SET_GEODE_ATTRS,MSG_GEN_FILE_SELECTOR_GET_ACTION,MSG_GEN_FILE_SELECTOR_SET_ACTION,MSG_GEN_FILE_SELECTOR_GET_ATTRS,MSG_GEN_FILE_SELECTOR_SET_ATTRS,MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA,MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA,MSG_GEN_FILE_SELECTOR_RESCAN,MSG_GEN_FILE_SELECTOR_UP_DIRECTORY,MSG_GEN_FILE_SELECTOR_UNUSED,MSG_GEN_FILE_SELECTOR_OPEN_ENTRY,MSG_GEN_FILE_SELECTOR_SUSPEND,MSG_GEN_FILE_SELECTOR_END_SUSPEND,MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH,MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE,MSG_GEN_FILE_SELECTOR_DELETE_SELECTION,MSG_GEN_FILE_SELECTOR_GET_FILE_ENUM_ROUTINE,MSG_GEN_FILE_SELECTOR_FAKE_PATH_GET,MSG_GEN_FILE_SELECTOR_FAKE_VOLUME_NAME_GET,MSG_GEN_FILE_SELECTOR_FAKE_ASSERT_HAVE_VOLUME_DATA,MSG_GEN_FILE_SELECTOR_FAKE_DRIVE_CHANGE,MSG_GEN_FILE_SELECTOR_FAKE_FLUSH_CACHES,MSG_GEN_FILE_SELECTOR_GET_SELECTION_TOKEN,}GenFileSelectorMessages;


#endif

# 54 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgDispC
#define __GOCgDispC
#include "/staff/pcgeos/CInclude/Objects/gDispC.poh"
#endif

# 55 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgGlyphC
#define __GOCgGlyphC

# 1 "/staff/pcgeos/CInclude/Objects/gGlyphC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gGlyphC.goh"

#define GenGlyphBase GenBase
#define _FIRST_GenGlyphClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gGlyphC.goh"


extern ClassStruct _far GenGlyphClass; extern Message _Messages_GenGlyphClass[]; extern MessageMethod *_Methods_GenGlyphClass[]; extern CMethodDef _htypes_GenGlyphClass[];extern MessageMethod *_Reloc_GenGlyphClass;
typedef struct _GenGlyphInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;} GenGlyphInstance; 
# 26 "/staff/pcgeos/CInclude/Objects/gGlyphC.goh"




#endif

# 56 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgCtrlC
#define __GOCgCtrlC
#include "/staff/pcgeos/CInclude/Objects/gCtrlC.poh"
#endif

# 57 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgDocCtrl
#define __GOCgDocCtrl

# 1 "/staff/pcgeos/CInclude/Objects/gDocCtrl.goh"





















#include <file.h>
#include <geode.h>

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/gDocCtrl.goh"

#ifndef __GOCgCtrlC
#define __GOCgCtrlC
#include "/staff/pcgeos/CInclude/Objects/gCtrlC.poh"
#endif

# 26 "/staff/pcgeos/CInclude/Objects/gDocCtrl.goh"

#define GenDocumentControlBase GenControlBase
#define _FIRST_GenDocumentControlClass 27648
# 27 "/staff/pcgeos/CInclude/Objects/gDocCtrl.goh"






























typedef struct {
    FileLongName    DFCP_name;
    DiskHandle	    DFCP_diskHandle;
    PathName	    DFCP_path;
    optr	    DFCP_display;
    optr	    DFCP_document;
} DocumentFileChangedParams;
























    #define ATTR_GEN_DOCUMENT_CONTROL_NO_EMPTY_DOC_IF_NOT_ABOVE 27648


    #define HINT_GEN_DOCUMENT_CONTROL_NO_PROGRESS_DIALOG_ON_UPDATE_MAJOR 27652

    #define HINT_GEN_DOCUMENT_CONTROL_PROGRESS_DIALOG_ON_UPDATE_MINOR 27656


    #define ATTR_GEN_DOCUMENT_CONTROL_FILE_LIST_TITLE 27660




    #define HINT_DOCUMENT_CONTROL_NO_FILE_LIST 27664






typedef WordFlags GDCFeatures;
#define GDCF_NEW			0x4000
#define GDCF_OPEN_CLOSE			0x2000
#define GDCF_QUICK_BACKUP		0x1000
#define GDCF_SAVE			0x0800
#define GDCF_SAVE_AS			0x0400
#define GDCF_COPY			0x0200
#define GDCF_EXPORT			0x0100
#define GDCF_REVERT			0x0080
#define GDCF_RENAME			0x0040
#define GDCF_EDIT_USER_NOTES		0x0020
#define GDCF_SET_TYPE			0x0010
#define GDCF_SET_PASSWORD		0x0008
#define GDCF_SAVE_AS_TEMPLATE		0x0004
#define GDCF_SET_EMPTY_DOCUMENT		0x0002
#define GDCF_SET_DEFAULT_DOCUMENT	0x0001

typedef WordFlags GDCToolboxFeatures;
#define GDCTF_NEW_EMPTY		0x0020
#define GDCTF_USE_TEMPLATE	0x0010
#define GDCTF_OPEN		0x0008
#define GDCTF_CLOSE		0x0004
#define GDCTF_SAVE		0x0002
#define GDCTF_QUICK_BACKUP	0x0001

#define GDC_SUGGESTED_INTRODUCTORY_FEATURES	(0)

#define GDC_SUGGESTED_BEGINNING_FEATURES	\
		(GDC_SUGGESTED_INTRODUCTORY_FEATURES | \
		 GDCF_QUICK_BACKUP | \
		 GDCF_COPY | \
		 GDCF_RENAME | \
		 GDCF_EXPORT | \
		 GDCF_EDIT_USER_NOTES)

#define GDC_SUGGESTED_INTERMEDIATE_FEATURES	\
		(GDC_SUGGESTED_BEGINNING_FEATURES | \
		 GDCF_SAVE_AS | \
		 GDCF_REVERT | \
		 GDCF_SET_PASSWORD)

#define GDC_SUGGESTED_ADVANCED_FEATURES	\
		(GDC_SUGGESTED_INTERMEDIATE_FEATURES | \
		 GDCF_SET_TYPE | \
		 GDCF_SAVE_AS_TEMPLATE | \
		 GDCF_SET_EMPTY_DOCUMENT | \
		 GDCF_SET_DEFAULT_DOCUMENT)


typedef struct {
    word	NDC_attrs;	
    word	NDC_type;	
    FileHandle	NDC_fileHandle;
    byte	NDC_emptyExists;
    byte	NDC_defaultExists;
} NotifyDocumentChange;


typedef ByteEnum GDCTask;
#define GDCT_NONE 0
#define GDCT_NEW 1
#define GDCT_OPEN 2
#define GDCT_USE_TEMPLATE 3
#define GDCT_SAVE_AS 4
#define GDCT_COPY_TO 5
#define GDCT_DIALOG 6
#define GDCT_TYPE 7
#define GDCT_PASSWORD 8
#define GDCT_MOVE_TO 9

typedef ByteEnum GenDocumentControlMode;
#define GDCM_VIEWER 0
#define GDCM_SHARED_SINGLE 1
#define GDCM_SHARED_MULTIPLE 2

typedef WordFlags GenDocumentControlAttrs;
#define GDCA_MULTIPLE_OPEN_FILES	0x8000
#define GDCA_MODE  	    	    	0x6000
#define GDCA_DOS_FILE_DENY_WRITE	0x1000
#define GDCA_VM_FILE	    	    	0x0800
#define GDCA_NATIVE			0x0400
#define GDCA_SUPPORTS_SAVE_AS_REVERT	0x0200
#define GDCA_DOCUMENT_EXISTS	    	0x0100
#define GDCA_CURRENT_TASK	    	0x00f0
#define GDCA_DO_NOT_SAVE_FILES	    	0x0008

#define GDCA_MODE_OFFSET   	    	13
#define GDCA_CURRENT_TASK_OFFSET   	4

typedef WordFlags GenDocumentControlFeatures;
#define GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT	    	0x8000
#define GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN	    	0x4000
#define GDCF_SUPPORTS_TEMPLATES	    	    	    	0x2000
#define GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT	0x1000
#define GDCF_SUPPORTS_USER_SETTABLE_DEFAULT_DOCUMENT	0x0800
#define GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS	0x0400
#define GDCF_NAME_ON_PRIMARY	    	    	    	0x0200

typedef ByteEnum GenFileSelectorType;
#define GFST_DOCUMENTS 0
#define GFST_EXECUTABLES 1
#define GFST_NON_GEOS_FILES 2
#define GFST_ALL_FILES 3


    

    

    





    







    
    
    
    
    

    
    
    
    
    
    
    
    

    
    
    
    
    

    
    
    
    
    
    

    
    
    
    
    
    


    
    

extern ClassStruct _far GenDocumentControlClass; extern Message _Messages_GenDocumentControlClass[]; extern MessageMethod *_Methods_GenDocumentControlClass[]; extern CMethodDef _htypes_GenDocumentControlClass[];extern MessageMethod *_Reloc_GenDocumentControlClass;
typedef struct _GenDocumentControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;
# 209 "/staff/pcgeos/CInclude/Objects/gDocCtrl.goh"
    GeodeToken GDCI_documentToken;

    GenFileSelectorType GDCI_selectorType;





    GenDocumentControlAttrs GDCI_attrs;







    GenDocumentControlFeatures GDCI_features;

    word GDCI_docAttrs;
    word GDCI_docType;
    FileHandle GDCI_docFileHandle;
    byte GDCI_emptyExists;
    byte GDCI_defaultExists;

    ChunkHandle GDCI_enableDisableList;
    optr GDCI_openGroup;
    optr GDCI_importGroup;
    optr GDCI_useTemplateGroup;
    optr GDCI_saveAsGroup;
    optr GDCI_exportGroup;
    optr GDCI_dialogGroup;
    optr GDCI_userLevelGroup;

    ChunkHandle GDCI_noNameText;
    ChunkHandle GDCI_defaultFile;
    ChunkHandle GDCI_templateDir;
    optr GDCI_documentGroup;
    FileLongName GDCI_targetDocName;

    ChunkHandle GDCI_dialogNewText;
    ChunkHandle GDCI_dialogTemplateText;
    ChunkHandle GDCI_dialogOpenDefaultText;
    ChunkHandle GDCI_dialogImportText;
    ChunkHandle GDCI_dialogOpenText;
    ChunkHandle GDCI_dialogUserLevelText;

    ChunkHandle GDCI_dialogNewMoniker;
    ChunkHandle GDCI_dialogTemplateMoniker;
    ChunkHandle GDCI_dialogOpenDefaultMoniker;
    ChunkHandle GDCI_dialogImportMoniker;
    ChunkHandle GDCI_dialogOpenMoniker;
    ChunkHandle GDCI_dialogUserLevelMoniker;} GenDocumentControlInstance; 
# 266 "/staff/pcgeos/CInclude/Objects/gDocCtrl.goh"
typedef enum{MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG=27648,MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_TEMPLATE_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC,MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_PASSWORD_DOC,MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS,MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES,MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN,MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR,MSG_GEN_DOCUMENT_CONTROL_GET_TEMPLATE_DIR,MSG_GEN_DOCUMENT_CONTROL_SAVE_AS_CANCELLED,MSG_GEN_DOCUMENT_CONTROL_FILE_CHANGED,MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR,MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED,MSG_GEN_DOCUMENT_CONTROL_FILE_EXPORTED,MSG_GEN_DOCUMENT_CONTROL_OPEN_DEFAULT_DOC,MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED,MSG_GEN_DOCUMENT_CONTROL_INITIATE_MOVE_TO_DOC,}GenDocumentControlMessages;



#endif

# 58 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgDocGrpC
#define __GOCgDocGrpC

# 1 "/staff/pcgeos/CInclude/Objects/gDocGrpC.goh"






















#ifndef __GOCgDocC
#define __GOCgDocC

# 1 "/staff/pcgeos/CInclude/Objects/gDocC.goh"





















#include <file.h>

#ifndef __GOCgContC
#define __GOCgContC

# 1 "/staff/pcgeos/CInclude/Objects/gContC.goh"






















#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gContC.goh"


#define GenContentBase GenBase
#define _FIRST_GenContentClass 26624
# 25 "/staff/pcgeos/CInclude/Objects/gContC.goh"


  

  

#define HINT_CONTENT_KEEP_FOCUS_VISIBLE 26624
  

     
    

extern ClassStruct _far GenContentClass; extern Message _Messages_GenContentClass[]; extern MessageMethod *_Methods_GenContentClass[]; extern CMethodDef _htypes_GenContentClass[];extern MessageMethod *_Reloc_GenContentClass;
typedef struct _GenContentInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 33 "/staff/pcgeos/CInclude/Objects/gContC.goh"
    byte GCI_attrs;
    optr GCI_genView;} GenContentInstance; 
# 36 "/staff/pcgeos/CInclude/Objects/gContC.goh"
typedef enum{MSG_GEN_CONTENT_GET_ATTRS=26624,MSG_GEN_CONTENT_SET_ATTRS,}GenContentMessages;



#endif

# 24 "/staff/pcgeos/CInclude/Objects/gDocC.goh"

#ifndef __GOCiacp
#define __GOCiacp
#include "/staff/pcgeos/CInclude/iacp.poh"
#endif

# 25 "/staff/pcgeos/CInclude/Objects/gDocC.goh"

#define GenDocumentBase GenContentBase
#define _FIRST_GenDocumentClass 27136
# 26 "/staff/pcgeos/CInclude/Objects/gDocC.goh"


typedef WordFlags GenDocumentAttrs;
#define GDA_READ_ONLY	    	    0x8000
#define GDA_READ_WRITE	    	    0x4000
#define GDA_FORCE_DENY_WRITE	    0x2000
#define GDA_SHARED_MULTIPLE	    0x1000
#define GDA_SHARED_SINGLE	    0x0800
#define GDA_UNTITLED	    	    0x0400
#define GDA_DIRTY	    	    0x0200
#define GDA_CLOSING	    	    0x0100
#define GDA_ATTACH_TO_DIRTY_FILE    0x0080
#define GDA_SAVE_FAILED	    	    0x0040
#define GDA_OPENING	    	    0x0020
#define GDA_AUTO_SAVE_STOPPED	    0x0010
#define GDA_MODEL		    0x0008
#define GDA_ON_WRITABLE_MEDIA	    0x0004
#define GDA_BACKUP_EXISTS	    0x0002
#define GDA_PREVENT_AUTO_SAVE	    0x0001

typedef enum {
    GDT_NORMAL,
    GDT_READ_ONLY,
    GDT_TEMPLATE,
    GDT_READ_ONLY_TEMPLATE,
    GDT_PUBLIC,
    GDT_MULTI_USER
} GenDocumentType;

typedef enum  {
    GDO_NORMAL,
    GDO_SAVE_AS,
    GDO_REVERT,
    GDO_REVERT_QUICK,
    GDO_ATTACH,
    GDO_DETACH,
    GDO_NEW,
    GDO_OPEN,
    GDO_SAVE,
    GDO_CLOSE,
    GDO_AUTO_SAVE,
    GDO_REVERT_TO_AUTO_SAVE,
} GenDocumentOperation;

typedef WordFlags DocumentOpenFlags;
#define DOF_CREATE_FILE_IF_FILE_DOES_NOT_EXIST	0x8000
#define DOF_FORCE_TEMPLATE_BEHAVIOR	    	0x4000
#define DOF_SAVE_AS_OVERWRITE_EXISTING_FILE	0x2000
#define DOF_REOPEN				0x1000
#define DOF_RAISE_APP_AND_DOC			0x0800
#define DOF_NAME_HOLDS_FILE_ID			0x0400
#define DOF_FORCE_REAL_EMPTY_DOCUMENT		0x0200
#define DOF_OPEN_FOR_IACP_ONLY			0x0100

typedef struct {
    FileLongName	DCP_name;
    DiskHandle		DCP_diskHandle;
    PathName		DCP_path;
    GenDocumentAttrs   	DCP_docAttrs;
    DocumentOpenFlags	DCP_flags;
    IACPConnection	DCP_connection;
} DocumentCommonParams;




















 	



















 	




 	





















#define GEN_DOCUMENT_GENERATE_NAME_ERROR	0xffff
#define GEN_DOCUMENT_GENERATE_NAME_CANCEL	0xfffe



 	



















 	




 	












 	




 	




 	








 	














 	
















#define GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE 100










 	

















    #define ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY 27136


    
    
    
    
    
    

    

extern ClassStruct _far GenDocumentClass; extern Message _Messages_GenDocumentClass[]; extern MessageMethod *_Methods_GenDocumentClass[]; extern CMethodDef _htypes_GenDocumentClass[];extern MessageMethod *_Reloc_GenDocumentClass;
typedef struct _GenDocumentInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 33 "/staff/pcgeos/CInclude/Objects/gContC.goh"
    byte GCI_attrs;
    optr GCI_genView;
# 280 "/staff/pcgeos/CInclude/Objects/gDocC.goh"
    GenDocumentAttrs GDI_attrs;
    GenDocumentType GDI_type;
    word GDI_operation;
    FileHandle GDI_fileHandle;
    FileLongName GDI_fileName;
    MemHandle GDI_display;} GenDocumentInstance; 
# 289 "/staff/pcgeos/CInclude/Objects/gDocC.goh"
typedef enum{MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE=27136,MSG_GEN_DOCUMENT_IMPORT,MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT,MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT,MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT,MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT,MSG_GEN_DOCUMENT_EXPORT,MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE,MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE,MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED,MSG_GEN_DOCUMENT_PHYSICAL_SAVE,MSG_GEN_DOCUMENT_PHYSICAL_UPDATE,MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS,MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE,MSG_GEN_DOCUMENT_PHYSICAL_REVERT,MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT,MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT,MSG_GEN_DOCUMENT_PHYSICAL_CREATE,MSG_GEN_DOCUMENT_PHYSICAL_OPEN,MSG_GEN_DOCUMENT_PHYSICAL_CLOSE,MSG_GEN_DOCUMENT_PHYSICAL_DELETE,MSG_GEN_DOCUMENT_PHYSICAL_CHECK_FOR_MODIFICATIONS,MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE,MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED,MSG_GEN_DOCUMENT_ATTACH_FAILED,MSG_GEN_DOCUMENT_MARK_DIRTY,MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW,MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED,MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS,MSG_GEN_DOCUMENT_GET_ATTRS,MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE,MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE,MSG_GEN_DOCUMENT_GET_FILE_NAME,MSG_GEN_DOCUMENT_GET_FILE_HANDLE,MSG_GEN_DOCUMENT_GET_OPERATION,MSG_GEN_DOCUMENT_GET_DISPLAY,MSG_GEN_DOCUMENT_NEW,MSG_GEN_DOCUMENT_OPEN,MSG_GEN_DOCUMENT_CLOSE,MSG_GEN_DOCUMENT_QUICK_BACKUP,MSG_GEN_DOCUMENT_RECOVER_QUICK_BACKUP,MSG_GEN_DOCUMENT_SAVE,MSG_GEN_DOCUMENT_SAVE_AS,MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE,MSG_GEN_DOCUMENT_COPY_TO,MSG_GEN_DOCUMENT_REVERT,MSG_GEN_DOCUMENT_EDIT_USER_NOTES,MSG_GEN_DOCUMENT_CHANGE_TYPE,MSG_GEN_DOCUMENT_CHANGE_PASSWORD,MSG_GEN_DOCUMENT_RENAME,MSG_GEN_DOCUMENT_SET_EMPTY,MSG_GEN_DOCUMENT_CLEAR_EMPTY,MSG_GEN_DOCUMENT_SET_DEFAULT,MSG_GEN_DOCUMENT_CLEAR_DEFAULT,MSG_GEN_DOCUMENT_CLOSE_IF_CLEAN_UNNAMED,MSG_GEN_DOCUMENT_SEARCH_FOR_DOC,MSG_GEN_DOCUMENT_TEST_FOR_FILE,MSG_GEN_DOCUMENT_AUTO_SAVE,MSG_GEN_DOCUMENT_UPDATE,MSG_GEN_DOCUMENT_CHECK_FOR_MODIFICATIONS,MSG_GEN_DOCUMENT_CLOSE_FILE,MSG_GEN_DOCUMENT_REOPEN_FILE,MSG_GEN_DOCUMENT_GET_VARIABLE,MSG_GEN_DOCUMENT_REVERT_NO_PROMPT,MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI,MSG_GEN_DOCUMENT_CLOSE_IF_OPEN_FOR_IACP_ONLY,MSG_GEN_DOCUMENT_MOVE_TO,MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE,MSG_GEN_DOCUMENT_PHYSICAL_REVERT_TO_AUTO_SAVE,MSG_GEN_DOCUMENT_DUPLICATE,MSG_GEN_DOCUMENT_DELETE,MSG_GEN_DOCUMENT_USE_TEMPLATE,}GenDocumentMessages;



#endif

# 23 "/staff/pcgeos/CInclude/Objects/gDocGrpC.goh"

#define GenDocumentGroupBase GenBase
#define _FIRST_GenDocumentGroupClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gDocGrpC.goh"


































































     #define ATTR_GEN_DOCUMENT_GROUP_ALLOW_MULTIPLE_WRITE_ACCESS 26624






typedef WordFlags GenDocumentGroupAttrs;
#define GDGA_VM_FILE		    	    	0x8000
#define GDGA_NATIVE		    	    	0x4000
#define GDGA_SUPPORTS_AUTO_SAVE    	    	0x2000
#define GDGA_AUTOMATIC_CHANGE_NOTIFICATION  	0x1000
#define GDGA_AUTOMATIC_DIRTY_NOTIFICATION   	0x0800
#define GDGA_APPLICATION_THREAD	    	    	0x0400
#define GDGA_VM_FILE_CONTAINS_OBJECTS	    	0x0200
#define GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN	0x0100
#define GDGA_LARGE_CONTENT  	    	    	0x0080
#define GDGA_AUTOMATIC_UNDO_INTERACTION	    	0x0040

typedef enum  {
    DQS_OK,
    DQS_CANCEL,
    DQS_DELAYED,
    DQS_SAVE_ERROR
} DocQuitStatus;


    







    
    
    
    
    
    
    
    
    
    

extern ClassStruct _far GenDocumentGroupClass; extern Message _Messages_GenDocumentGroupClass[]; extern MessageMethod *_Methods_GenDocumentGroupClass[]; extern CMethodDef _htypes_GenDocumentGroupClass[];extern MessageMethod *_Reloc_GenDocumentGroupClass;
typedef struct _GenDocumentGroupInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 123 "/staff/pcgeos/CInclude/Objects/gDocGrpC.goh"
    GenDocumentGroupAttrs GDGI_attrs;
    ChunkHandle GDGI_untitledName;
    ClassStruct * GDGI_documentClass;
    optr GDGI_genDocument;
    optr GDGI_output;
    optr GDGI_documentControl;
    optr GDGI_genView;
    optr GDGI_genDisplay;
    optr GDGI_genDisplayGroup;
    word GDGI_protocolMajor;
    word GDGI_protocolMinor;} GenDocumentGroupInstance; 
# 135 "/staff/pcgeos/CInclude/Objects/gDocGrpC.goh"
typedef enum{MSG_GEN_DOCUMENT_GROUP_NEW_DOC=26624,MSG_GEN_DOCUMENT_GROUP_IMPORT_NEW_DOC,MSG_GEN_DOCUMENT_GROUP_OPEN_DOC,MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY,MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE,MSG_GEN_DOCUMENT_GROUP_OPEN_DEFAULT_DOC,MSG_GEN_DOCUMENT_GROUP_GET_ATTRS,MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS,MSG_GEN_DOCUMENT_GROUP_GET_TEMPLATE_DIR,MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES,MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME,MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT,MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT,MSG_GEN_DOCUMENT_GROUP_GET_TOKEN,MSG_GEN_DOCUMENT_GROUP_GET_CREATOR,MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL,MSG_GEN_DOCUMENT_GROUP_GET_VIEW,MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY,MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP,MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE,MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED,MSG_GEN_DOCUMENT_GROUP_SEARCH_FOR_DOC,MSG_GEN_DOCUMENT_GROUP_AUTO_SAVE_BY_FILE,MSG_GEN_DOCUMENT_GROUP_SET_DIRTY_LIMIT_BY_FILE,}GenDocumentGroupMessages;



#endif

# 59 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgDocC
#define __GOCgDocC
#include "/staff/pcgeos/CInclude/Objects/gDocC.poh"
#endif

# 60 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgDCtrlC
#define __GOCgDCtrlC

# 1 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"






















#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"

#define GenDisplayGroupBase GenBase
#define _FIRST_GenDisplayGroupClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"










   
   



	
	




    #define HINT_DISPLAY_GROUP_SEPARATE_MENUS 26624

    #define HINT_DISPLAY_GROUP_ARRANGE_TILED 26628

    #define HINT_DISPLAY_GROUP_FULL_SIZED_ON_STARTUP 26632

    #define HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP 26636

    #define HINT_DISPLAY_GROUP_FULL_SIZED_IF_TRANSPARENT_DOC_CTRL_MODE 26640


    #define ATTR_GEN_DISPLAY_GROUP_NO_FULL_SIZED 26644

    #define ATTR_GEN_DISPLAY_GROUP_NO_OVERLAPPING 26648

    #define ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE 26652


    #define HINT_DISPLAY_GROUP_TILE_HORIZONTALLY 26656

    #define HINT_DISPLAY_GROUP_TILE_VERTICALLY 26660


    #define HINT_DISPLAY_GROUP_SIZE_INDEPENDENTLY_OF_DISPLAYS 26664


    

extern ClassStruct _far GenDisplayGroupClass; extern Message _Messages_GenDisplayGroupClass[]; extern MessageMethod *_Methods_GenDisplayGroupClass[]; extern CMethodDef _htypes_GenDisplayGroupClass[];extern MessageMethod *_Reloc_GenDisplayGroupClass;
typedef struct _GenDisplayGroupInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;} GenDisplayGroupInstance; 
# 62 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"
typedef enum{MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED=26624,MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING,MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED,MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS,MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY,MSG_GEN_DISPLAY_GROUP_SET_NUM_ITEMS,MSG_GEN_DISPLAY_GROUP_SET_MONIKER,MSG_GEN_DISPLAY_GROUP_SWAP_DISPLAYS,MSG_GEN_DISPLAY_GROUP_RESIZE_DISPLAYS,}GenDisplayGroupMessages;



#define GenDisplayControlBase GenControlBase
#define _FIRST_GenDisplayControlClass 27648
# 66 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"















typedef ByteFlags GenDisplayControlAttributes;
#define GDCA_MAXIMIZED_NAME_ON_PRIMARY	0x80

#define MAX_DISPLAY_NAME_SIZE	64

typedef WordFlags GDICFeatures;
#define GDCF_OVERLAPPING_MAXIMIZED	0x0004
#define GDCF_TILE			0x0002
#define GDCF_DISPLAY_LIST		0x0001

typedef WordFlags GDICToolboxFeatures;
#define GDCTF_OVERLAPPING_MAXIMIZED	0x0004
#define GDCTF_TILE			0x0002
#define GDCTF_DISPLAY_LIST		0x0001



#define GDC_DEFAULT_FEATURES  \
    (GDCF_OVERLAPPING_MAXIMIZED | GDCF_TILE | GDCF_DISPLAY_LIST)
#define GDC_DEFAULT_TOOLBOX_FEATURES  (GDCF_DISPLAY_LIST)

typedef struct {
    optr	NDC_display;
    TCHAR	NDC_name[MAX_DISPLAY_NAME_SIZE];
    byte	NDC_overlapping;
} NotifyDisplayChange;

typedef struct {
    word    	NDLC_counter;
    optr	NDLC_group;
} NotifyDisplayListChange;

typedef ByteFlags GenDisplayControlAttributes;
#define GDCA_MAXIMIZED_NAME_ON_PRIMARY	0x80

    #define HINT_DISPLAY_CONTROL_NO_FEATURES_IF_TRANSPARENT_DOC_CTRL_MODE 27648


    #define TEMP_GDC_CACHED_NAME 27652

    #define TEMP_GDC_CACHED_LIST_DATA 27656

    #define TEMP_GDC_CACHED_TOOL_LIST_DATA 27660

    #define TEMP_GDC_CACHED_SELECTED_DISPLAY 27664


    


    
    

extern ClassStruct _far GenDisplayControlClass; extern Message _Messages_GenDisplayControlClass[]; extern MessageMethod *_Methods_GenDisplayControlClass[]; extern CMethodDef _htypes_GenDisplayControlClass[];extern MessageMethod *_Reloc_GenDisplayControlClass;
typedef struct _GenDisplayControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;
# 124 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"
    GenDisplayControlAttributes GDCII_attrs;} GenDisplayControlInstance; 
# 129 "/staff/pcgeos/CInclude/Objects/gDCtrlC.goh"
typedef enum{MSG_GDC_SET_OVERLAPPING=27648,MSG_GDC_TILE,MSG_GDC_LIST_APPLY,MSG_GDC_LIST_QUERY,MSG_GDC_SWAP_DISPLAYS,MSG_GDC_RESIZE_DISPLAYS,}GenDisplayControlMessages;




#endif

# 61 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgEditCC
#define __GOCgEditCC

# 1 "/staff/pcgeos/CInclude/Objects/gEditCC.goh"




















#define GenEditControlBase GenControlBase
#define _FIRST_GenEditControlClass 27648
# 21 "/staff/pcgeos/CInclude/Objects/gEditCC.goh"


    #define TEMP_UNDO_DESCRIPTION 27648

    #define TEMP_CLIPBOARD_NOTIFICATION_LIST_COUNT 27652


typedef WordFlags GECFeatures;
#define GECF_UNDO	0x0020
#define GECF_CUT	0x0010
#define GECF_COPY	0x0008
#define GECF_PASTE	0x0004
#define GECF_SELECT_ALL	0x0002
#define GECF_DELETE	0x0001

typedef WordFlags GECToolboxFeatures;
#define GECTF_UNDO		0x0020
#define GECTF_CUT		0x0010
#define GECTF_COPY		0x0008
#define GECTF_PASTE		0x0004
#define GECTF_SELECT_ALL	0x0002
#define GECTF_DELETE		0x0001







#define GEC_DEFAULT_FEATURES 	(GECF_UNDO | GECF_CUT \
				| GECF_COPY | GECF_PASTE \
				| GECF_SELECT_ALL | GECF_DELETE)

#define GEC_DEFAULT_TOOLBOX_FEATURES 	(GECTF_UNDO | GECTF_CUT \
				| GECTF_COPY | GECTF_PASTE \
				| GECTF_SELECT_ALL | GECTF_DELETE)
typedef enum {
    SDT_TEXT,
    SDT_GRAPHICS,
    SDT_SPREADHSEET,
    SDT_INK,
    SDT_OTHER
} SelectionDataType;

typedef struct {
    SelectionDataType  	    	NSSC_selectionType;
    byte			NSSC_clipboardableSelection;
    byte			NSSC_selectAllAvailable;
    byte			NSSC_deleteableSelection;
    byte			NSSC_pasteable;
} NotifySelectStateChange;

typedef ByteEnum UndoDescription;
#define	UD_UNDO	    	0
#define	UD_REDO	    	1
#define	UD_NOT_UNDOABLE	2

typedef struct {
    optr			NUSC_undoTitle;
    UndoDescription		NUSC_undoType;
} NotifyUndoStateChange;

    
    
    

extern ClassStruct _far GenEditControlClass; extern Message _Messages_GenEditControlClass[]; extern MessageMethod *_Methods_GenEditControlClass[]; extern CMethodDef _htypes_GenEditControlClass[];extern MessageMethod *_Reloc_GenEditControlClass;
typedef struct _GenEditControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;} GenEditControlInstance; 
# 85 "/staff/pcgeos/CInclude/Objects/gEditCC.goh"





#endif

# 62 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgBoolGC
#define __GOCgBoolGC

# 1 "/staff/pcgeos/CInclude/Objects/gBoolGC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gBoolGC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gBoolGC.goh"

#define GenBooleanGroupBase GenBase
#define _FIRST_GenBooleanGroupClass 26624
# 25 "/staff/pcgeos/CInclude/Objects/gBoolGC.goh"



#define BGROUP_UNUSED 26624

#define ATTR_GEN_BOOLEAN_GROUP_STATUS_MSG 26628

#define ATTR_GEN_BOOLEAN_GROUP_INIT_FILE_BOOLEAN 26632

#define HINT_BOOLEAN_GROUP_SCROLLABLE 26636

#define HINT_BOOLEAN_GROUP_MINIMIZE_SIZE 26640

#define HINT_BOOLEAN_GROUP_CHECKBOX_STYLE 26644

#define HINT_BOOLEAN_GROUP_TOOLBOX_STYLE 26648

#define ATTR_GEN_BOOLEAN_GROUP_LINK 26652

;



 


  

  
  
  

 



  



  



  


 

  

  


   
  
   
  

 







  





  



 


    
    
    
    
    
extern ClassStruct _far GenBooleanGroupClass; extern Message _Messages_GenBooleanGroupClass[]; extern MessageMethod *_Methods_GenBooleanGroupClass[]; extern CMethodDef _htypes_GenBooleanGroupClass[];extern MessageMethod *_Reloc_GenBooleanGroupClass;
typedef struct _GenBooleanGroupInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 97 "/staff/pcgeos/CInclude/Objects/gBoolGC.goh"
    word GBGI_selectedBooleans;
    word GBGI_indeterminateBooleans;
    word GBGI_modifiedBooleans;
    optr GBGI_destination;
    Message GBGI_applyMsg;} GenBooleanGroupInstance; 
# 102 "/staff/pcgeos/CInclude/Objects/gBoolGC.goh"
typedef enum{MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE=26624,MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE,MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS,MSG_GEN_BOOLEAN_GROUP_GET_INDETERMINATE_BOOLEANS,MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS,MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG,MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR,MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE,MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_INDETERMINATE_STATE,MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_MODIFIED_STATE,MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED,MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_INDETERMINATE,MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_MODIFIED,MSG_GEN_BOOLEAN_GROUP_GET_DESTINATION,MSG_GEN_BOOLEAN_GROUP_SET_DESTINATION,MSG_GEN_BOOLEAN_GROUP_GET_APPLY_MSG,MSG_GEN_BOOLEAN_GROUP_SET_APPLY_MSG,MSG_GEN_BOOLEAN_GROUP_MAKE_BOOLEAN_VISIBLE,MSG_GEN_BOOLEAN_GROUP_SCAN_BOOLEANS,MSG_GEN_BOOLEAN_GROUP_REDRAW_BOOLEANS,}GenBooleanGroupMessages;



#endif

# 63 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgItemGC
#define __GOCgItemGC

# 1 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"

#define GenItemGroupBase GenBase
#define _FIRST_GenItemGroupClass 26624
# 25 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"


typedef ByteEnum GenItemGroupBehaviorType;
#define GIGBT_EXCLUSIVE 0
#define GIGBT_EXCLUSIVE_NONE 1
#define GIGBT_EXTENDED_SELECTION 2
#define GIGBT_NON_EXCLUSIVE 3


#define  GIGS_NONE	(0xffff)
































 















typedef ByteFlags GenScanItemsFlags;
#define	GSIF_FROM_START				0x80
#define	GSIF_FORWARD				0x40
#define GSIF_WRAP_AROUND			0x20
#define GSIF_INITIAL_ITEM_FOUND			0x10
#define GSIF_USABLE_AND_ENABLED_ITEM_FOUND	0x08
#define GSIF_EXISTING_ITEMS_ONLY		0x04
#define GSIF_DYNAMIC_LIST			0x02






  

 



  












typedef ByteFlags GenItemGroupStateFlags;
#define  GIGSF_INDETERMINATE	0x80
#define  GIGSF_MODIFIED		0x40















#define ATTR_GEN_ITEM_GROUP_STATUS_MSG 26624

#define ATTR_GEN_ITEM_GROUP_SET_MODIFIED_ON_REDUNDANT_SELECTION 26628

#define ATTR_GEN_ITEM_GROUP_CUSTOM_DOUBLE_PRESS 26632

#define HINT_ITEM_GROUP_SCROLLABLE 26636

#define HINT_ITEM_GROUP_MINIMIZE_SIZE 26640

#define HINT_ITEM_GROUP_RADIO_BUTTON_STYLE 26644

#define HINT_ITEM_GROUP_TOOLBOX_STYLE 26648


#define HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION 26652

#define HINT_ITEM_GROUP_MINIMIZE_SIZE_IF_VERTICAL_SCREEN 26656

#define ATTR_GEN_ITEM_GROUP_LINK 26660

;
#define ATTR_GEN_ITEM_GROUP_INIT_FILE_BOOLEAN 26664

#define HINT_ITEM_GROUP_SHOW_SELECTION_EVEN_WHEN_NOT_FOCUS 26668



#define HINT_ITEM_GROUP_LOWER_LEFT_STYLE 26672

#define HINT_ITEM_GROUP_LOWER_RIGHT_STYLE 26676

	




#define HINT_ITEM_GROUP_UPPER_TAB_STYLE 26680

#define HINT_ITEM_GROUP_LOWER_TAB_STYLE 26684

	




#define HINT_ITEM_GROUP_BLANK_STYLE 26688

	
#define HINT_ITEM_GROUP_PCV_RADIO_BUTTON_STYLE 26692






#define HINT_ITEM_GROUP_TAB_STYLE 26696

	




typedef WordFlags ScrollListGridState;
#define SLGS_HGRID_LINES	0x8000
#define SLGS_HGRID_SPACING	0x7f00
#define SLGS_VGRID_LINES	0x0080
#define SLGS_VGRID_SPACING	0x007f

#define SLGS_HGRID_SPACING_OFFSET    8
#define SLGS_VGRID_SPACING_OFFSET    0

#define HINT_ITEM_GROUP_GRID_LINES 26700


#define HINT_ITEM_GROUP_PREV_LINK 26704



#define HINT_ITEM_GROUP_NEXT_LINK 26708



typedef struct {
    word SOOBM_upMessage;
    word SOOBM_downMessage;
} ScrollOutOfBoundsMsgs;

#define HINT_ITEM_GROUP_SCROLL_OUT_OF_BOUNDS_MSGS 26712




#define HINT_ITEM_GROUP_WRAPPING_LIST 26716

#define HINT_ITEM_GROUP_NON_WRAPPING_LIST 26720

	








    
    
    
    
    
    
extern ClassStruct _far GenItemGroupClass; extern Message _Messages_GenItemGroupClass[]; extern MessageMethod *_Methods_GenItemGroupClass[]; extern CMethodDef _htypes_GenItemGroupClass[];extern MessageMethod *_Reloc_GenItemGroupClass;
typedef struct _GenItemGroupInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 215 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"
    GenItemGroupBehaviorType GIGI_behaviorType;
    word GIGI_selection;
    word GIGI_numSelections;
    GenItemGroupStateFlags GIGI_stateFlags;
    optr GIGI_destination;
    Message GIGI_applyMsg;} GenItemGroupInstance; 
# 221 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"
typedef enum{MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED=26624,MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION,MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS,MSG_GEN_ITEM_GROUP_GET_SELECTION,MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS,MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS,MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE,MSG_GEN_ITEM_GROUP_IS_INDETERMINATE,MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE,MSG_GEN_ITEM_GROUP_IS_MODIFIED,MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG,MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR,MSG_GEN_ITEM_GROUP_SET_ITEM_STATE,MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED,MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE,MSG_GEN_ITEM_GROUP_GET_DESTINATION,MSG_GEN_ITEM_GROUP_SET_DESTINATION,MSG_GEN_ITEM_GROUP_GET_APPLY_MSG,MSG_GEN_ITEM_GROUP_SET_APPLY_MSG,MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE,MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE,MSG_GEN_ITEM_GROUP_GET_UNIQUE_IDENTIFIER,MSG_GEN_ITEM_GROUP_SCAN_ITEMS,MSG_GEN_ITEM_GROUP_REDRAW_ITEMS,MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION,MSG_GEN_ITEM_GROUP_UPDATE_EXTENDED_SELECTION,MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM,MSG_GEN_ITEM_GROUP_SET_FOCUS_ITEM,}GenItemGroupMessages;


#endif

# 64 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgDListC
#define __GOCgDListC

# 1 "/staff/pcgeos/CInclude/Objects/gDListC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gDListC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gDListC.goh"

#define GenDynamicListBase GenItemGroupBase
#define _FIRST_GenDynamicListClass 27136
# 25 "/staff/pcgeos/CInclude/Objects/gDListC.goh"




typedef WordFlags ReplaceItemMonikerFlags;
#define RIMF_NOT_ENABLED	0x8000




						



















#define GDLI_NO_CHANGE 	0xffff










    

#define GDLP_FIRST	0x0000
#define GDLP_LAST	0xffff



   

  



 


  
 



    
    


extern ClassStruct _far GenDynamicListClass; extern Message _Messages_GenDynamicListClass[]; extern MessageMethod *_Methods_GenDynamicListClass[]; extern CMethodDef _htypes_GenDynamicListClass[];extern MessageMethod *_Reloc_GenDynamicListClass;
typedef struct _GenDynamicListInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 215 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"
    GenItemGroupBehaviorType GIGI_behaviorType;
    word GIGI_selection;
    word GIGI_numSelections;
    GenItemGroupStateFlags GIGI_stateFlags;
    optr GIGI_destination;
    Message GIGI_applyMsg;
# 87 "/staff/pcgeos/CInclude/Objects/gDListC.goh"
    word GDLI_numItems;
    word GDLI_queryMsg;} GenDynamicListInstance; 
# 91 "/staff/pcgeos/CInclude/Objects/gDListC.goh"
typedef enum{MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER=27136,MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR,MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT,MSG_GEN_DYNAMIC_LIST_INITIALIZE,MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS,MSG_GEN_DYNAMIC_LIST_ADD_ITEMS,MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS,MSG_GEN_DYNAMIC_LIST_REMOVE_ITEM_LIST,MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER,MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS,MSG_GEN_DYNAMIC_LIST_TOP_ITEM_CHANGED,MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED,MSG_GEN_DYNAMIC_LIST_NUM_ITEMS_CHANGED,}GenDynamicListMessages;



#endif

# 65 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgItemC
#define __GOCgItemC

# 1 "/staff/pcgeos/CInclude/Objects/gItemC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gItemC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gItemC.goh"

#define GenItemBase GenBase
#define _FIRST_GenItemClass 26624
# 25 "/staff/pcgeos/CInclude/Objects/gItemC.goh"


   
  




    


extern ClassStruct _far GenItemClass; extern Message _Messages_GenItemClass[]; extern MessageMethod *_Methods_GenItemClass[]; extern CMethodDef _htypes_GenItemClass[];extern MessageMethod *_Reloc_GenItemClass;
typedef struct _GenItemInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 33 "/staff/pcgeos/CInclude/Objects/gItemC.goh"
    word GII_identifier;} GenItemInstance; 
# 36 "/staff/pcgeos/CInclude/Objects/gItemC.goh"
typedef enum{MSG_GEN_ITEM_GET_IDENTIFIER=26624,MSG_GEN_ITEM_SET_IDENTIFIER,MSG_GEN_ITEM_SET_INTERACTABLE_STATE,}GenItemMessages;




#endif

# 66 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgBoolC
#define __GOCgBoolC

# 1 "/staff/pcgeos/CInclude/Objects/gBoolC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gBoolC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gBoolC.goh"

#define GenBooleanBase GenBase
#define _FIRST_GenBooleanClass 26624
# 25 "/staff/pcgeos/CInclude/Objects/gBoolC.goh"


   
  




    


extern ClassStruct _far GenBooleanClass; extern Message _Messages_GenBooleanClass[]; extern MessageMethod *_Methods_GenBooleanClass[]; extern CMethodDef _htypes_GenBooleanClass[];extern MessageMethod *_Reloc_GenBooleanClass;
typedef struct _GenBooleanInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 33 "/staff/pcgeos/CInclude/Objects/gBoolC.goh"
    word GBI_identifier;} GenBooleanInstance; 
# 36 "/staff/pcgeos/CInclude/Objects/gBoolC.goh"
typedef enum{MSG_GEN_BOOLEAN_GET_IDENTIFIER=26624,MSG_GEN_BOOLEAN_SET_IDENTIFIER,MSG_GEN_BOOLEAN_SET_INTERACTABLE_STATE,}GenBooleanMessages;




#endif

# 67 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgGadgetC
#define __GOCgGadgetC

# 1 "/staff/pcgeos/CInclude/Objects/gGadgetC.goh"






















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gGadgetC.goh"

#define GenGadgetBase GenBase
#define _FIRST_GenGadgetClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gGadgetC.goh"

		


typedef ByteFlags GenGadgetAttributes;
#define GGA_COMPOSITE	0x8000


	
extern ClassStruct _far GenGadgetClass; extern Message _Messages_GenGadgetClass[]; extern MessageMethod *_Methods_GenGadgetClass[]; extern CMethodDef _htypes_GenGadgetClass[];extern MessageMethod *_Reloc_GenGadgetClass;
typedef struct _GenGadgetInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 32 "/staff/pcgeos/CInclude/Objects/gGadgetC.goh"
    GenGadgetAttributes GGI_attrs;} GenGadgetInstance; 
# 33 "/staff/pcgeos/CInclude/Objects/gGadgetC.goh"

	


#endif

# 68 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgToolCC
#define __GOCgToolCC

# 1 "/staff/pcgeos/CInclude/Objects/gToolCC.goh"






















#ifndef __GOCgCtrlC
#define __GOCgCtrlC
#include "/staff/pcgeos/CInclude/Objects/gCtrlC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gToolCC.goh"

#ifndef __GOCgcnlist
#define __GOCgcnlist
#include "/staff/pcgeos/CInclude/gcnlist.poh"
#endif

# 24 "/staff/pcgeos/CInclude/Objects/gToolCC.goh"

#define GenToolControlBase GenControlBase
#define _FIRST_GenToolControlClass 27648
# 25 "/staff/pcgeos/CInclude/Objects/gToolCC.goh"


















typedef WordFlags GTCFeatures;
#define GTCF_TOOL_DIALOG	0x0001




#define MAX_NUM_TOOLBOXES	25

typedef struct {
    optr	TI_object;
    optr	TI_name;
} ToolboxInfo;

typedef struct {
    optr	TGI_object;
} ToolGroupInfo;






typedef struct {
    optr	TGTCI_curController;
    word	TGTCI_features;
    word    	TGTCI_required;
    word    	TGTCI_allowed;
} TempGenToolControlInstance;

    #define TEMP_GEN_TOOL_CONTROL_INSTANCE 27648






    

    
    

extern ClassStruct _far GenToolControlClass; extern Message _Messages_GenToolControlClass[]; extern MessageMethod *_Methods_GenToolControlClass[]; extern CMethodDef _htypes_GenToolControlClass[];extern MessageMethod *_Reloc_GenToolControlClass;
typedef struct _GenToolControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;
# 80 "/staff/pcgeos/CInclude/Objects/gToolCC.goh"
    ChunkHandle GTCI_toolboxList;
    ChunkHandle GTCI_toolGroupList;} GenToolControlInstance; 
# 83 "/staff/pcgeos/CInclude/Objects/gToolCC.goh"
typedef enum{MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST=27648,MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST_QUERY,MSG_GEN_TOOL_CONTROL_INTERNAL_GROUP_LIST_VISIBILITY,MSG_GEN_TOOL_CONTROL_INTERNAL_TOOLS_LIST,MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_TOOLS,MSG_GEN_TOOL_CONTROL_INTERNAL_PLACEMENT_LIST,MSG_GEN_TOOL_CONTROL_INTERNAL_PLACEMENT_LIST_QUERY,MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_PLACEMENT,MSG_GEN_TOOL_CONTROL_INTERNAL_POSITION_VALUE,MSG_GEN_TOOL_CONTROL_INTERNAL_NUDGE_BACK,MSG_GEN_TOOL_CONTROL_INTERNAL_NUDGE_FORWARD,MSG_GEN_TOOL_CONTROL_INTERNAL_RESET_POSITION,}GenToolControlMessages;




#endif

# 69 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgValueC
#define __GOCgValueC

# 1 "/staff/pcgeos/CInclude/Objects/gValueC.goh"





















#ifndef __GOCui
#define __GOCui
#include "/staff/pcgeos/CInclude/ui.poh"
#endif

# 22 "/staff/pcgeos/CInclude/Objects/gValueC.goh"

#ifndef __GOCgenC
#define __GOCgenC
#include "/staff/pcgeos/CInclude/Objects/genC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gValueC.goh"

#define GenValueBase GenBase
#define _FIRST_GenValueClass 26624
# 24 "/staff/pcgeos/CInclude/Objects/gValueC.goh"










#define MSG_GEN_VALUE_GET_INTEGER_VALUE MSG_GEN_VALUE_GET_VALUE














 
   


 
   

typedef ByteEnum GenValueDisplayFormat;








  

   
   

   
   

typedef enum  {
	GVT_VALUE,
	GVT_MINIMUM,
	GVT_MAXIMUM,
	GVT_INCREMENT,
	GVT_LONG,
	GVT_RANGE_LENGTH,
	GVT_RANGE_END,
	GVI_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
} GenValueType;

#define GEN_VALUE_MAX_TEXT_LEN 30








  


  




  

  
  
  
  





typedef ByteFlags GenValueStateFlags;
#define GVSF_INDETERMINATE	0x80
#define	GVSF_MODIFIED		0x40
#define GVSF_OUT_OF_DATE	0x20

typedef struct {
	GenValueStateFlags	GVSFAW_flags;
	byte			GVSFAW_unused;
} GenValueStateFlagsAsWord;







#define ATTR_GEN_VALUE_STATUS_MSG 26624

#define ATTR_GEN_VALUE_DECIMAL_PLACES 26628

#define ATTR_GEN_VALUE_METRIC_INCREMENT 26632

#define HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS 26636

#define HINT_VALUE_CUSTOM_RETURN_PRESS 26640

#define ATTR_GEN_VALUE_RUNS_ITEM_GROUP 26644

;
#define ATTR_GEN_VALUE_SET_MODIFIED_ON_REDUNDANT_SELECTION 26648

#define HINT_VALUE_INCREMENTABLE 26652

#define HINT_VALUE_NOT_INCREMENTABLE 26656

#define HINT_VALUE_X_SCROLLER 26660

#define HINT_VALUE_Y_SCROLLER 26664

#define HINT_VALUE_DISPLAYS_RANGE 26668

#define HINT_VALUE_ANALOG_DISPLAY 26672


typedef struct {
	word	GVI_numMajorIntervals;
	word	GVI_numMinorIntervals;
} GenValueIntervals;

#define HINT_VALUE_DISPLAY_INTERVALS 26676

#define HINT_VALUE_CONSTRAIN_TO_INTERVALS 26680

#define HINT_VALUE_SHOW_MIN_AND_MAX 26684

#define HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION 26688

#define HINT_VALUE_DELAYED_DRAG_NOTIFICATION 26692

#define HINT_VALUE_ORIENT_HORIZONTALLY 26696

#define HINT_VALUE_ORIENT_VERTICALLY 26700

#define HINT_VALUE_DIGITAL_DISPLAY 26704

#define HINT_VALUE_NO_DIGITAL_DISPLAY 26708

#define HINT_VALUE_NO_ANALOG_DISPLAY 26712

#define HINT_VALUE_NOT_DIGITALLY_EDITABLE 26716

#define HINT_VALUE_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS 26720

#define HINT_VALUE_WRAP 26724

#define HINT_VALUE_FRAME 26728

#define HINT_VALUE_ITEM_GROUP_GADGET 26732

#define HINT_VALUE_MERGE_ANALOG_AND_DIGITAL_DISPLAYS 26736

#define HINT_VALUE_SEPARATE_ANALOG_AND_DIGITAL_DISPLAYS 26740







#define HINT_VALUE_UNDERLINE 26744

#define HINT_VALUE_NO_UNDERLINE 26748






typedef struct {
    ChunkHandle	    MMM_min;
    ChunkHandle	    MMM_max;
} MinMaxMonikers;

#define HINT_VALUE_MIN_MAX_MONIKERS 26752


#define HINT_VALUE_NO_FRAME 26756





#define GVDF_INTEGER 0
#define GVDF_DECIMAL 1
#define	GVDF_POINTS 2
#define GVDF_INCHES 3
#define GVDF_CENTIMETERS 4
#define GVDF_MILLIMETERS 5
#define GVDF_PICAS 6
#define GVDF_EUR_POINTS 7
#define GVDF_CICEROS 8
#define GVDF_POINTS_OR_MILLIMETERS 9
#define GVDF_INCHES_OR_CENTIMETERS 10


#define GVDF_PERCENTAGE 11	












extern ClassStruct _far GenValueClass; extern Message _Messages_GenValueClass[]; extern MessageMethod *_Methods_GenValueClass[]; extern CMethodDef _htypes_GenValueClass[];extern MessageMethod *_Reloc_GenValueClass;
typedef struct _GenValueInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 207 "/staff/pcgeos/CInclude/Objects/gValueC.goh"
    WWFixedAsDWord GVLI_value;
    WWFixedAsDWord GVLI_minimum;
    WWFixedAsDWord GVLI_maximum;
    WWFixedAsDWord GVLI_increment;
    GenValueStateFlags GVLI_stateFlags;
    GenValueDisplayFormat GVLI_displayFormat;
    optr GVLI_destination;
    Message GVLI_applyMsg;} GenValueInstance; 
# 216 "/staff/pcgeos/CInclude/Objects/gValueC.goh"
typedef enum{MSG_GEN_VALUE_SET_VALUE=26624,MSG_GEN_VALUE_SET_INTEGER_VALUE,MSG_GEN_VALUE_GET_VALUE,MSG_GEN_VALUE_SET_MINIMUM,MSG_GEN_VALUE_GET_MINIMUM,MSG_GEN_VALUE_SET_MAXIMUM,MSG_GEN_VALUE_GET_MAXIMUM,MSG_GEN_VALUE_SET_INCREMENT,MSG_GEN_VALUE_GET_INCREMENT,MSG_GEN_VALUE_SET_INDETERMINATE_STATE,MSG_GEN_VALUE_IS_INDETERMINATE,MSG_GEN_VALUE_SET_MODIFIED_STATE,MSG_GEN_VALUE_IS_MODIFIED,MSG_GEN_VALUE_SET_DISPLAY_FORMAT,MSG_GEN_VALUE_GET_DISPLAY_FORMAT,MSG_GEN_VALUE_SEND_STATUS_MSG,MSG_GEN_VALUE_GET_DESTINATION,MSG_GEN_VALUE_SET_DESTINATION,MSG_GEN_VALUE_GET_APPLY_MSG,MSG_GEN_VALUE_SET_APPLY_MSG,MSG_GEN_VALUE_SET_RANGE_LENGTH,MSG_GEN_VALUE_GET_RANGE_LENGTH,MSG_GEN_VALUE_ADD_RANGE_LENGTH,MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH,MSG_GEN_VALUE_GET_VALUE_TEXT,MSG_GEN_VALUE_SET_VALUE_FROM_TEXT,MSG_GEN_VALUE_GET_VALUE_RATIO,MSG_GEN_VALUE_SET_VALUE_FROM_RATIO,MSG_GEN_VALUE_INCREMENT,MSG_GEN_VALUE_DECREMENT,MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM,MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM,MSG_GEN_VALUE_GET_TEXT_FILTER,MSG_GEN_VALUE_GET_MAX_TEXT_LEN,MSG_GEN_VALUE_SET_OUT_OF_DATE,MSG_GEN_VALUE_SELECT_TEXT,}GenValueMessages;




#endif

# 70 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOCgToolGC
#define __GOCgToolGC

# 1 "/staff/pcgeos/CInclude/Objects/gToolGC.goh"






















#ifndef __GOCgInterC
#define __GOCgInterC
#include "/staff/pcgeos/CInclude/Objects/gInterC.poh"
#endif

# 23 "/staff/pcgeos/CInclude/Objects/gToolGC.goh"

#define GenToolGroupBase GenInteractionBase
#define _FIRST_GenToolGroupClass 27136
# 24 "/staff/pcgeos/CInclude/Objects/gToolGC.goh"

typedef ByteEnum ToolGroupHighlightType;
#define TGHT_INACTIVE_HIGHLIGHT	0
#define TGHT_ACTIVE_HIGHLIGHT	1
#define TGHT_NO_HIGHLIGHT	2








    #define TEMP_TOOL_GROUP_HIGHLIGHT 27136






    

    

extern ClassStruct _far GenToolGroupClass; extern Message _Messages_GenToolGroupClass[]; extern MessageMethod *_Methods_GenToolGroupClass[]; extern CMethodDef _htypes_GenToolGroupClass[];extern MessageMethod *_Reloc_GenToolGroupClass;
typedef struct _GenToolGroupInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 43 "/staff/pcgeos/CInclude/Objects/gToolGC.goh"
    optr GTGI_controller;} GenToolGroupInstance; 
# 47 "/staff/pcgeos/CInclude/Objects/gToolGC.goh"
typedef enum{MSG_GEN_TOOL_GROUP_SET_HIGHLIGHT=27136,}GenToolGroupMessages;

#ifdef __HIGHC__
#endif




#endif

# 71 "/staff/pcgeos/CInclude/stdapp.goh"

#ifndef __GOChelpCC
#define __GOChelpCC

# 1 "/staff/pcgeos/CInclude/Objects/helpCC.goh"

























#include <file.h>
#include <Objects/helpCC.h>





extern void _far _pascal HelpSendHelpNotification(word HelpType, const char *contextname, const char *filename);





#define HelpControlBase GenControlBase
#define _FIRST_HelpControlClass 27648
# 39 "/staff/pcgeos/CInclude/Objects/helpCC.goh"


typedef struct {
    word    	    	PI_unused;
    MouseReturnFlags	PI_mouseFlags;
    



    optr    	    	PI_pointerImage;
} PointerImage;


















	    	





































    #define ATTR_HELP_SUPPRESS_INITIATE 27648

    #define ATTR_HELP_INITIAL_HELP 27652

    #define ATTR_HELP_CUSTOM_POINTER_IMAGE 27656


    #define HINT_HELP_TEXT_FIXED_SIZE 27660

    #define HINT_HELP_NOT_RESIZABLE 27664



    #define ATTR_HELP_INITIAL_HELP_FILE 27668





    #define TEMP_HELP_ERROR_FILENAME 27672

    #define TEMP_HELP_TOC_FILENAME 27676

    #define TEMP_HELP_DETACH_RECEIVED 27680

    #define TEMP_HELP_HEAPSPACE_TOKEN 27684





    
    
    
    
    

    
    

extern ClassStruct _far HelpControlClass; extern Message _Messages_HelpControlClass[]; extern MessageMethod *_Methods_HelpControlClass[]; extern CMethodDef _htypes_HelpControlClass[];extern MessageMethod *_Reloc_HelpControlClass;
typedef struct _HelpControlInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 302 "/staff/pcgeos/CInclude/Objects/gCtrlC.goh"
    optr GCI_output;
# 127 "/staff/pcgeos/CInclude/Objects/helpCC.goh"
    HelpType HCI_helpType;
    MemHandle HCI_curFile;
    MemHandle HCI_historyBuf;
    word HCI_nameArrayVM;
    GeodeHandle HCI_compressLib;} HelpControlInstance; 
# 136 "/staff/pcgeos/CInclude/Objects/helpCC.goh"
typedef enum{MSG_HELP_CONTROL_FOLLOW_LINK=27648,MSG_HELP_CONTROL_GET_POINTER_IMAGE,MSG_HC_GO_BACK,MSG_HC_FIRST_AID_GO_BACK,MSG_HC_GET_HISTORY_LIST_MONIKER,MSG_HC_GOTO_HISTORY,}HelpControlMessages;


#endif

# 72 "/staff/pcgeos/CInclude/stdapp.goh"



#ifndef __GOCvTextC
#define __GOCvTextC
#include "/staff/pcgeos/CInclude/Objects/vTextC.poh"
#endif

# 75 "/staff/pcgeos/CInclude/stdapp.goh"



#endif

# 34 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
#include <ec.h>

#ifndef __GOChtlist
#define __GOChtlist

# 1 "/staff/pcgeos/CInclude/WWW/HTCore/htlist.goh"































#ifndef __GOCstdapp
#define __GOCstdapp
#include "/staff/pcgeos/CInclude/stdapp.poh"
#endif

# 32 "/staff/pcgeos/CInclude/WWW/HTCore/htlist.goh"





typedef optr HTListHandle;	





extern void _far _pascal
	ECCheckHTList(HTListHandle list);

extern HTListHandle _far _pascal 
	HTListNew(void);

extern void _far _pascal
	HTListDelete(HTListHandle list);

extern void _far _pascal
	HTListDeleteAllItems(HTListHandle list);

extern void _far _pascal
	HTListDeleteRange(HTListHandle list, word index, word count);

extern word _far _pascal
	HTListAppend(HTListHandle list, const void *item, word size);

extern void _far _pascal
	HTListPrepend(HTListHandle list, const void *item, word size);

extern word _far _pascal
	HTListReplaceItem(HTListHandle list, word index, const void *item, 
	                  word size);

extern int _far _pascal 
	HTListFindItem(HTListHandle list, const void *item, word size);

extern void _far _pascal
	HTListGetItem(HTListHandle list, word index, void *item, word size);

extern word _far _pascal
	HTListGetItemSize(HTListHandle list, word index);

extern word _far _pascal
	HTListGetCount(HTListHandle list);

extern void _far _pascal
	HTListRemoveItem(HTListHandle list, word index, void *item, word size);

#ifdef __HIGHC__
pragma Alias(ECCheckHTList, "ECCHECKHTLIST");
pragma Alias(HTListNew, "HTLISTNEW");
pragma Alias(HTListDelete, "HTLISTDELETE");
pragma Alias(HTListDeleteAllItems, "HTLISTDELETEALLITEMS");
pragma Alias(HTListDeleteRange, "HTLISTDELETERANGE");
pragma Alias(HTListAppend, "HTLISTAPPEND");
pragma Alias(HTListPrepend, "HTLISTPREPEND");
pragma Alias(HTListReplaceItem, "HTLISTREPLACEITEM");
pragma Alias(HTListFindItem, "HTLISTFINDITEM");
pragma Alias(HTListGetItem, "HTLISTGETITEM");
pragma Alias(HTListGetItemSize, "HTLISTGETITEMSIZE");
pragma Alias(HTListGetCount, "HTLISTGETCOUNT");
pragma Alias(HTListRemoveItem, "HTLISTREMOVEITEM");
#endif



#endif

# 36 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

#ifndef __GOChtstring
#define __GOChtstring

# 1 "/staff/pcgeos/CInclude/WWW/HTCore/htstring.goh"





































#ifndef __GOCstdapp
#define __GOCstdapp
#include "/staff/pcgeos/CInclude/stdapp.poh"
#endif

# 38 "/staff/pcgeos/CInclude/WWW/HTCore/htstring.goh"

#ifndef __GOClibrary
#define __GOClibrary

# 1 "/staff/pcgeos/CInclude/library.h"

















#ifndef	__LIBRARY_H
#define __LIBRARY_H

#include <geode.h>



extern GeodeHandle				
    _pascal GeodeUseLibrary(const char *name, word protoMajor, word protoMinor,
		    	    	GeodeLoadError	*err);



extern void	
    _pascal GeodeFreeLibrary(GeodeHandle gh);



typedef enum  {
    LCT_ATTACH,
    LCT_DETACH,
    LCT_NEW_CLIENT,
    LCT_NEW_CLIENT_THREAD,
    LCT_CLIENT_THREAD_EXIT,
    LCT_CLIENT_EXIT,
} LibraryCallType;








#ifdef __HIGHC__
pragma Alias(GeodeUseLibrary, "GEODEUSELIBRARY");
pragma Alias(GeodeFreeLibrary, "GEODEFREELIBRARY");
#endif

#endif
#endif

# 39 "/staff/pcgeos/CInclude/WWW/HTCore/htstring.goh"
#include <WWW/htmem.h>

typedef word HTStringHandle;       

extern void _far _pascal
	ECCheckHTString(HTStringHandle string);

extern HTStringHandle _far _pascal
	HTStringFor(const char *string);

extern const char* _far _pascal
	HTStringLock(HTStringHandle string);

extern void _far _pascal
	HTStringUnlock(HTStringHandle string);

extern int _far _pascal
	HTStringLen(HTStringHandle string);

extern HTMemHandle _far _pascal
	HTStrAllocCopy(const char *str);

extern HTMemHandle _far _pascal
	HTStrHTMemAllocCopy(const HTMemHandle str);

extern HTMemHandle _far _pascal
	HTStrAllocCat(HTMemHandle s, const char *t);

extern int _far _pascal
	strlenHTMem(const HTMemHandle str);

extern void _far _pascal
	strcpyHTMem(const HTMemHandle s, const HTMemHandle t);

extern void _far _pascal
	strcatHTMem(const HTMemHandle s, const HTMemHandle t);

extern int _far _pascal
	strcasecmp (const char *a, const char *b);

extern int _far _pascal
	strcasecmpHTMemHandle (const HTMemHandle a, const char *b);

extern int _far _pascal
	strncasecmp (const char *a, const char *b, int n);

extern char * _far _pascal
	strcasestr (const char *s1, const char *s2);

extern char * _far _pascal
	strtolower (char * a);

extern char * _far _pascal
	strtoupper (char *a);

extern Boolean _far _pascal
	HTParseTime(const char *s, TimerDateAndTime *tm);

#ifdef __HIGHC__
pragma Alias(ECCheckHTString, "ECCHECKHTSTRING");
pragma Alias(HTStringFor, "HTSTRINGFOR");
pragma Alias(HTStringLock, "HTSTRINGLOCK");
pragma Alias(HTStringUnlock, "HTSTRINGUNLOCK");
pragma Alias(HTStringLen, "HTSTRINGLEN");
pragma Alias(HTStrAllocCopy, "HTSTRALLOCCOPY");
pragma Alias(HTStrAllocCat, "HTSTRALLOCCAT");
pragma Alias(HTStrHTMemAllocCopy, "HTSTRHTMEMALLOCCOPY");
pragma Alias(strlenHTMem, "STRLENHTMEM");
pragma Alias(strcpyHTMem, "STRCPYHTMEM");
pragma Alias(strcatHTMem, "STRCATHTMEM");
pragma Alias(strcasecmp, "STRCASECMP");
pragma Alias(strcasecmpHTMemHandle, "STRCASECMPHTMEMHANDLE");
pragma Alias(strncasecmp, "STRNCASECMP");
pragma Alias(strcasestr, "STRCASESTR");
pragma Alias(strtolower, "STRTOLOWER");
pragma Alias(strtoupper, "STRTOUPPER");
pragma Alias(HTParseTime, "HTPARSETIME");
#endif


#endif

# 37 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

#ifndef __GOChtreq
#define __GOChtreq

# 1 "/staff/pcgeos/CInclude/WWW/HTCore/htreq.goh"































#ifndef __GOCstdapp
#define __GOCstdapp
#include "/staff/pcgeos/CInclude/stdapp.poh"
#endif

# 32 "/staff/pcgeos/CInclude/WWW/HTCore/htreq.goh"

#ifndef __GOChtutils
#define __GOChtutils

# 1 "/staff/pcgeos/CInclude/WWW/HTCore/htutils.goh"































#ifndef __GOCstdapp
#define __GOCstdapp
#include "/staff/pcgeos/CInclude/stdapp.poh"
#endif

# 32 "/staff/pcgeos/CInclude/WWW/HTCore/htutils.goh"





typedef word HTRequestHandle;		 
typedef word HTLibHandle; 	






typedef optr HTStreamHandle;




#ifndef CR
#define CR	C_CR
#endif

#ifndef LF
#define LF	C_LF
#endif









#ifdef __HIGHC__

#ifndef PUSHDS
#define PUSHDS	_inline(0x1e)	
#endif

#ifndef POPDS
#define POPDS	_inline(0x1f)	
#endif

#endif

#ifdef __BORLANDC__

#ifndef PUSHDS
#define PUSHDS  asm{push ds}
#endif

#ifndef POPDS
#define POPDS   asm{pop  ds}
#endif

#endif

#ifndef SET_DS_LIB_DGROUP
#define SET_DS_LIB_DGROUP GeodeLoadDGroup (GeodeGetCodeProcessHandle())
                                
#endif





#if ERROR_CHECK
#define ECCheckRequest(request) ECCheckMemHandle(request)
#endif



#endif

# 33 "/staff/pcgeos/CInclude/WWW/HTCore/htreq.goh"



#ifndef __GOChtanchor
#define __GOChtanchor

# 1 "/staff/pcgeos/CInclude/WWW/HTCore/htanchor.goh"







































#include <WWW/htmem.h>


#define HTAnchorHandle HTMemHandle
#define HTDocument HTListHandle  





#define ECCheckHTAnchor(anchor) ECCheckHTMemHandle(anchor)

extern HTAnchorHandle _far _pascal 
    HTAnchorNew(void);

extern HTAnchorHandle _far _pascal
    HTAnchorFind (const char *url);

extern HTMemHandle _far _pascal
    HTAnchorAddress (HTAnchorHandle parent);

extern void _far _pascal
    HTAnchorSetPhysical (HTAnchorHandle parent, const char *physicalURL);

extern HTMemHandle _far _pascal
    HTAnchorPhysical (HTAnchorHandle parent);

extern HTStringHandle _far _pascal
    HTAnchorContentType (HTAnchorHandle parent);

extern void _far _pascal
    HTAnchorSetContentType (HTAnchorHandle parent, 
			    HTStringHandle contentType);

extern dword _far _pascal
    HTAnchorContentLength (HTAnchorHandle parent);

extern void _far _pascal
    HTAnchorSetContentLength (HTAnchorHandle parent,
			      dword contentLength);

extern void _far _pascal
    HTAnchorLastModified (HTAnchorHandle parent, TimerDateAndTime *dateTime);

extern void _far _pascal
    HTAnchorSetLastModified (HTAnchorHandle parent, 
			     const TimerDateAndTime *dateTime);

extern void _far _pascal
    HTAnchorExpires (HTAnchorHandle parent, TimerDateAndTime *dateTime);

extern void _far _pascal
    HTAnchorSetExpires (HTAnchorHandle parent, 
			const TimerDateAndTime *dateTime);

extern void _far _pascal
    HTAnchorSetDocument(HTAnchorHandle parent,
			HTDocument document);

#ifdef __HIGHC__
pragma Alias(HTAnchorNew, "HTANCHORNEW");
pragma Alias(HTAnchorFind, "HTANCHORFIND");
pragma Alias(HTAnchorAddress, "HTANCHORADDRESS");
pragma Alias(HTAnchorSetPhysical, "HTANCHORSETPHYSICAL");
pragma Alias(HTAnchorPhysical, "HTANCHORPHYSICAL");
pragma Alias(HTAnchorContentType, "HTANCHORCONTENTTYPE");
pragma Alias(HTAnchorSetContentType, "HTANCHORSETCONTENTTYPE");
pragma Alias(HTAnchorContentLength, "HTANCHORCONTENTLENGTH");
pragma Alias(HTAnchorSetContentLength, "HTANCHORSETCONTENTLENGTH");
pragma Alias(HTAnchorLastModified, "HTANCHORLASTMODIFIED");
pragma Alias(HTAnchorSetLastModified, "HTANCHORSETLASTMODIFIED");
pragma Alias(HTAnchorExpires, "HTANCHOREXPIRES");
pragma Alias(HTAnchorSetExpires, "HTANCHORSETEXPIRES");
pragma Alias(HTAnchorSetDocument, "HTANCHORSETDOCUMENT");
#endif






#endif

# 36 "/staff/pcgeos/CInclude/WWW/HTCore/htreq.goh"
#include <library.h>				
























typedef enum {
    HTGH_CONNECTION        = 0x1,
    HTGH_DATE              = 0x2,
    HTGH_FORWARDED         = 0x4,
    HTGH_KEEP_ALIVE        = 0x8,
    HTGH_MIME_VERSION      = 0x10
} HTGenHd;





#define DEFAULT_GENERAL_HEADERS   0x0  





typedef enum {
    HTRH_ACCEPT                    = 0x1,
    HTRH_ACCEPT_CHARSET            = 0x2,
    HTRH_ACCEPT_ENCODING           = 0x4,
    HTRH_ACCEPT_LANGUAGE           = 0x8,
    HTRH_PROXY_AUTHORIZATION       = 0x10,
    HTRH_USER_AGENT                = 0x20
} HTReqHd;

#define DEFAULT_REQUEST_HEADERS  0x0  





typedef enum {
    HTEH_CONTENT_ENCODING           = 0x1,
    HTEH_CONTENT_LANGUAGE           = 0x2,
    HTEH_CONTENT_LENGTH             = 0x4,
    HTEH_CONTENT_TYPE               = 0x8,
    HTEH_TRANSFER_ENCODING          = 0x10
} HTEntityHd;

#define DEFAULT_ENTITY_HEADERS   0x0    



























typedef enum {
	HTTPT_INVALID = 0x0,   	

	HTTPT_REQUEST 	= 0x1,
	HTTPT_RESPONSE	= 0x2,
	HTTPT_NULL     		
} HTTPType;





typedef enum {
	HTM_INVALID = 0x0,	


	HTM_OPTIONS,
	HTM_GET,		
	HTM_HEAD,
	HTM_POST,
	HTM_PUT,
	HTM_PATCH,
	HTM_COPY,
	HTM_MOVE,
	HTM_DELETE,
	HTM_LINK,
	HTM_UNLINK,
	HTM_TRACE,
	HTM_WRAPPED,
	HTM_NULL		
} HTMethod;




typedef enum {
	HTTPV_INVALID = 0x0,	


	HTTPV_0_9  = 0x1,	
	HTTPV_1_0  = 0x2,	
	HTTPV_1_1  = 0x3,	
	HTTPV_NULL		
} HTTPVersion;






typedef enum {
    HTRELOAD_INVALID        = 0x0,      
                                        

    HTRELOAD_ANY_VERSION    = 0x1,      
    HTRELOAD_MEMORY_VERSION = 0x2,      
    HTRELOAD_CACHE_REFRESH  = 0x4,      
    HTRELOAD_FORCE_RELOAD   = 0x8,      
    HTRELOAD_NULL           = 0x10      
} HTReload;









#define	HT_ERROR  		-1	
#define	HT_OK 			0	
#define	HT_NO 			1	















#define HT_RESOLVING_HOST               500
#define HT_CONNECTING_TO_SERVER         501   
#define HT_RETRY_CONNECTING_TO_SERVER   502   
#define HT_CONNECTED                    503   
#define HT_CONNECTION_CLOSED            504   

#define HT_WAITING_FOR_REPLY            505
#define HT_LOADING_DATA                 506   



#define HT_MORE_DATA                    507   

















#define HT_INTERRUPTED 			1000    
#define HT_OUT_OF_MEMORY                1001
#define HT_CANNOT_RESOLVE_HOST_NAME     1002
#define HT_CANNOT_CONNECT               1003    
#define HT_LINK_FAILED                  1004    


#define HT_NO_PROTOCOL                  1005    


#define HT_NO_CONTENT                   1006    


#define HT_STALLED_AND_CANNOT_RETRY     1007    



#define HT_CANNOT_OPEN_FILE             1008    

#define HT_CANNOT_WRITE_FILE            1009    

#define HT_SOCKET_ERROR		        1010    
#define	HT_LOADED 			1020	
#define	HT_UNAUTHORIZED			1021
#define	HT_PAYMENT_REQUIRED		1022
#define HT_DOCUMENT_MOVED               1023    






#define	HT_ALL				2000 	











#define HT_WOULD_BLOCK                  2001    
#define HT_ASYNCH_LOAD                  2002    









typedef int _far _pascal (*HTPostCallback)(HTRequestHandle request, 
					   HTStreamHandle stream);	





extern int _far _pascal
	HTRegister(GeodeHandle geodeHandle, word accessPoint);

extern int _far _pascal
	HTUnregister(GeodeHandle geodeHandle);

extern HTRequestHandle _far _pascal 
	HTRequestCreate(HTTPType ty);

extern int _far _pascal 
	HTRequestDelete(HTRequestHandle request);

extern int _far _pascal
        HTRequestSetRequestLine(HTRequestHandle request, 
				HTMethod method, 
				const char *uri,
				HTTPVersion version);

extern int _far _pascal
	HTRequestSetMethod(HTRequestHandle request, HTMethod method);

extern int _far _pascal
	HTRequestSetURI(HTRequestHandle request, const char *uri);

extern HTMemHandle _far _pascal
	HTRequestGetURI(HTRequestHandle request);

extern int _far _pascal
	HTRequestSetHTTPVersion(HTRequestHandle request, HTTPVersion version);

extern int _far _pascal
        HTRequestSetReloadMode(HTRequestHandle request, HTReload mode);

extern int _far _pascal
	HTRequestSetBeforeCallbackList(HTRequestHandle request, 
		HTListHandle list);

extern int _far _pascal
	HTRequestSetRequestCallbackList(HTRequestHandle request, 
		HTListHandle list);

extern int _far _pascal
	HTRequestSetAfterCallbackList(HTRequestHandle request,
		HTListHandle list);

extern int _far _pascal
	HTRequestSetProtocolList(HTRequestHandle request,
		HTListHandle list);

extern int _far _pascal
	HTRequestSetResponseParser(HTRequestHandle request,
		ClassStruct _far *class);

extern int _far _pascal 
	HTRequestSetPostCallback(HTRequestHandle request,
		HTPostCallback cbf);

extern int _far _pascal 
	HTRequestSetProxy(HTRequestHandle request, 
		const char *proxyName, word portNumber);

extern int _far _pascal
	HTRequestSetDataSource(HTRequestHandle request, HTAnchorHandle anchor);

extern int _far _pascal
	HTRequestSetGeneralHeaderMask(HTRequestHandle request,
		HTGenHd mask);

extern int _far _pascal
	HTRequestSetRequestHeaderMask(HTRequestHandle request,
		HTReqHd mask);

extern int _far _pascal
	HTRequestSetEntityHeaderMask(HTRequestHandle request,
		HTEntityHd mask);

extern int _far _pascal
	HTRequestSubmit(HTRequestHandle request, GeodeHandle client);

extern int _far _pascal
	HTRequestKill(HTRequestHandle request);

extern void _far _pascal
	HTRequestKillAll(GeodeHandle geode);

extern void _far _pascal
        HTRequestShutDown(void);  

extern dword _far _pascal
	HTRequestGetBytesRead(HTRequestHandle request);

extern word _far _pascal 
	HTRequestGetResponseStatusCode(HTRequestHandle request);

extern dword _far _pascal
	HTRequestGetResponseContentLength(HTRequestHandle request);

extern Boolean _far _pascal 
        HTRequestGetResponseLastModified(HTRequestHandle request,
					 TimerDateAndTime &dateTime);

#ifdef __HIGHC__
pragma Alias(HTRegister, "HTREGISTER");
pragma Alias(HTUnregister, "HTUNREGISTER");
pragma Alias(HTRequestCreate, "HTREQUESTCREATE");
pragma Alias(HTRequestDelete, "HTREQUESTDELETE");
pragma Alias(HTRequestSetRequestLine, "HTREQUESTSETREQUESTLINE");
pragma Alias(HTRequestSetMethod, "HTREQUESTSETMETHOD");
pragma Alias(HTRequestSetURI, "HTREQUESTSETURI");
pragma Alias(HTRequestGetURI, "HTREQUESTGETURI");
pragma Alias(HTRequestSetReloadMode, "HTREQUESTSETRELOADMODE");
pragma Alias(HTRequestSetHTTPVersion, "HTREQUESTSETHTTPVERSION");
pragma Alias(HTRequestSetBeforeCallbackList, "HTREQUESTSETBEFORECALLBACKLIST");
pragma Alias(HTRequestSetAfterCallbackList, "HTREQUESTSETAFTERCALLBACKLIST");
pragma Alias(HTRequestSetProtocolList, "HTREQUESTSETPROTOCOLLIST");
pragma Alias(HTRequestSetPostCallback, "HTREQUESTSETPOSTCALLBACK");
pragma Alias(HTRequestSetRequestCallbackList, "HTREQUESTSETREQUESTCALLBACKLIST");
pragma Alias(HTRequestSetResponseParser, "HTREQUESTSETRESPONSEPARSER");
pragma Alias(HTRequestSetProxy, "HTREQUESTSETPROXY");
pragma Alias(HTRequestSetGeneralHeaderMask, "HTREQUESTSETGENERALHEADERMASK");
pragma Alias(HTRequestSetRequestHeaderMask, "HTREQUESTSETREQUESTHEADERMASK");
pragma Alias(HTRequestSetEntityHeaderMask, "HTREQUESTSETENTITYHEADERMASK");
pragma Alias(HTRequestSetDataSource, "HTREQUESTSETDATASOURCE");
pragma Alias(HTRequestSubmit, "HTREQUESTSUBMIT");
pragma Alias(HTRequestKill, "HTREQUESTKILL");
pragma Alias(HTRequestKillAll, "HTREQUESTKILLALL");
pragma Alias(HTRequestShutDown, "HTREQUESTSHUTDOWN");
pragma Alias(HTRequestGetResponseStatusCode, "HTREQUESTGETRESPONSESTATUSCODE");
pragma Alias(HTRequestGetResponseContentLength, "HTREQUESTGETRESPONSECONTENTLENGTH");
pragma Alias(HTRequestGetResponseLastModified, "HTREQUESTGETRESPONSELASTMODIFIED");
pragma Alias(HTRequestGetBytesRead, "HTREQUESTGETBYTESREAD");
#endif


#endif

# 38 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

#ifndef __GOCsgml
#define __GOCsgml

# 1 "/staff/pcgeos/CInclude/WWW/sgml.goh"
































#ifndef __GOChtstream
#define __GOChtstream

# 1 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"


































#include <WWW/htmem.h>

#ifndef __GOCstdapp
#define __GOCstdapp
#include "/staff/pcgeos/CInclude/stdapp.poh"
#endif

# 37 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"




























































































#define HTStreamBase MetaBase
#define _FIRST_HTStreamClass 8192
# 129 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"












































































































































































































 








extern ClassStruct HTStreamClass; extern Message _Messages_HTStreamClass[]; extern MessageMethod *_Methods_HTStreamClass[]; extern CMethodDef _htypes_HTStreamClass[];extern MessageMethod *_Reloc_HTStreamClass;
typedef struct _HTStreamInstance {

# 53 "/staff/pcgeos/CInclude/Objects/metaC.goh"
    MetaBase MI_base;
# 318 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
    optr HTSI_target;








    Boolean HTSI_transparent;




    HTRequestHandle HTSI_request;







    GeodeHandle HTSI_libraryHandle;} HTStreamInstance; 
# 342 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
typedef enum{MSG_HT_STREAM_FLUSH=8192,MSG_HT_STREAM_ABORT,MSG_HT_STREAM_UNLOAD_LIBRARY,MSG_HT_STREAM_PUT_BLOCK,MSG_HT_STREAM_SET_REQUEST,MSG_HT_STREAM_GET_REQUEST,MSG_HT_STREAM_SET_TARGET,MSG_HT_STREAM_GET_TARGET,MSG_HT_STREAM_SET_TRANSPARENT,MSG_HT_STREAM_IS_TRANSPARENT,MSG_HT_STREAM_SET_DYNAMICALLY_LOADED,}HTStreamMessages;






#define HTStructuredBase HTStreamBase
#define _FIRST_HTStructuredClass 8704
# 349 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"

















































extern ClassStruct HTStructuredClass; extern Message _Messages_HTStructuredClass[]; extern MessageMethod *_Methods_HTStructuredClass[]; extern CMethodDef _htypes_HTStructuredClass[];extern MessageMethod *_Reloc_HTStructuredClass;
typedef struct _HTStructuredInstance {

# 53 "/staff/pcgeos/CInclude/Objects/metaC.goh"
    MetaBase MI_base;
# 318 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
    optr HTSI_target;








    Boolean HTSI_transparent;




    HTRequestHandle HTSI_request;







    GeodeHandle HTSI_libraryHandle;} HTStructuredInstance; 
# 398 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
typedef enum{MSG_HT_STRUCTURED_GET_DTD=8704,MSG_HT_STRUCTURED_PUT_START_ELEMENT,MSG_HT_STRUCTURED_PUT_END_ELEMENT,}HTStructuredMessages;






#define HTProtocolBase HTStreamBase
#define _FIRST_HTProtocolClass 8704
# 405 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"






















































extern ClassStruct HTProtocolClass; extern Message _Messages_HTProtocolClass[]; extern MessageMethod *_Methods_HTProtocolClass[]; extern CMethodDef _htypes_HTProtocolClass[];extern MessageMethod *_Reloc_HTProtocolClass;
typedef struct _HTProtocolInstance {

# 53 "/staff/pcgeos/CInclude/Objects/metaC.goh"
    MetaBase MI_base;
# 318 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
    optr HTSI_target;








    Boolean HTSI_transparent;




    HTRequestHandle HTSI_request;







    GeodeHandle HTSI_libraryHandle;
# 457 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
    HTStreamHandle HTPI_socket;} HTProtocolInstance; 
# 459 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
typedef enum{MSG_HT_PROTOCOL_LOAD=8704,MSG_HT_PROTOCOL_STOP,}HTProtocolMessages;





extern void _far _pascal
	HTUtilChangeClassToHTStreamClass(optr obj);

extern void _far _pascal
	HTUtilChangeClass(optr obj, ClassStruct _far *class);

extern int _far _pascal
	HTStreamGrowInputStreamStack(HTRequestHandle request, 
		HTStreamHandle stream);

EC(	
extern void _far _pascal	
	ECCheckStream(HTStreamHandle stream); 
)

#ifdef __HIGHC__
pragma Alias(HTUtilChangeClass, "HTUTILCHANGECLASS");
pragma Alias(HTUtilChangeClassToHTStreamClass, "HTUTILCHANGECLASSTOHTSTREAMCLASS");
pragma Alias(HTStreamGrowInputStreamStack, "HTSTREAMGROWINPUTSTREAMSTACK");

#if ERROR_CHECK
pragma Alias(ECCheckStream, "ECCHECKSTREAM");
#endif

#endif









#endif

# 33 "/staff/pcgeos/CInclude/WWW/sgml.goh"


typedef MemHandle SGMLScannerHandle;  






















typedef enum {
     SGMLC_EMPTY      = 0x1 



    ,SGMLC_LITERAL    = 0x2 

    ,SGMLC_PREFORMATTED = 0x4  

   

  

    ,SGMLC_MIXED      

 

} SGMLContent;




typedef struct {
    char *SGMLA_name;
    word SGMLA_token;         
} SGMLAttr;





typedef struct {
    
    






    
    char *SGMLT_name;              

    word SGMLT_token;              
    optr SGMLT_attrList;           

    word SGMLT_numOfAttrs;         



    SGMLContent SGMLT_content;     
} SGMLTag;







typedef struct {
    
    









    
    optr     SGMLD_tagList;       
    word     SGMLD_numOfTags;     

    optr     SGMLD_entityList;    
    optr     SGMLD_entityTranslate; 
    word     SGMLD_numOfEntities;  

    optr     SGMLD_characterList; 
    optr     SGMLD_characterTranslate; 

    word     SGMLD_numOfCharacters; 
} SGMLDTD;












typedef struct {
    word SGMLE_token;             
    ChunkHandle SGMLE_value;      
} SGMLEntity;








#define SGMLBase HTStreamBase
#define _FIRST_SGMLClass 8704
# 166 "/staff/pcgeos/CInclude/WWW/sgml.goh"






















extern ClassStruct SGMLClass; extern Message _Messages_SGMLClass[]; extern MessageMethod *_Methods_SGMLClass[]; extern CMethodDef _htypes_SGMLClass[];extern MessageMethod *_Reloc_SGMLClass;
typedef struct _SGMLInstance {

# 53 "/staff/pcgeos/CInclude/Objects/metaC.goh"
    MetaBase MI_base;
# 318 "/staff/pcgeos/CInclude/WWW/HTCore/htstream.goh"
    optr HTSI_target;








    Boolean HTSI_transparent;




    HTRequestHandle HTSI_request;







    GeodeHandle HTSI_libraryHandle;
# 176 "/staff/pcgeos/CInclude/WWW/sgml.goh"
    SGMLScannerHandle SGMLI_scanner;




    SGMLDTD * SGMLI_dtd;




    ThreadHandle SGMLI_parserThread;} SGMLInstance; 
# 188 "/staff/pcgeos/CInclude/WWW/sgml.goh"
;



#endif

# 39 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

#ifndef __GOChtmlDTD
#define __GOChtmlDTD

# 1 "/staff/pcgeos/CInclude/WWW/htmlDTD.goh"







































typedef enum {
    




     HTMLT_XXX_INVALID = 0x0 
    ,HTMLT_A
    ,HTMLT_ABBREV
    ,HTMLT_ABSTRACT
    ,HTMLT_ACRONYM
    ,HTMLT_ADDED
    ,HTMLT_ADDRESS
    ,HTMLT_APPLET
    ,HTMLT_AREA
    ,HTMLT_ARG
    ,HTMLT_B
    ,HTMLT_BASE
    ,HTMLT_BASEFONT
    ,HTMLT_BDO
    ,HTMLT_BGSOUND
    ,HTMLT_BIG
    ,HTMLT_BLOCKQUOTE
    ,HTMLT_BODY
    ,HTMLT_BR
    ,HTMLT_CAPTION
    ,HTMLT_CENTER
    ,HTMLT_CHANGED
    ,HTMLT_CITE
    ,HTMLT_CODE
    ,HTMLT_COL
    ,HTMLT_COLGROUP
    ,HTMLT_COMMENT
    ,HTMLT_DD
    ,HTMLT_DFN
    ,HTMLT_DIR
    ,HTMLT_DIV
    ,HTMLT_DL
    ,HTMLT_DOCTYPE
    ,HTMLT_DT
    ,HTMLT_EM
    ,HTMLT_EMBED
    ,HTMLT_FIELDSET
    ,HTMLT_FIG
    ,HTMLT_FONT
    ,HTMLT_FORM
    ,HTMLT_FRAME
    ,HTMLT_FRAMESET
    ,HTMLT_H1
    ,HTMLT_H2
    ,HTMLT_H3
    ,HTMLT_H4
    ,HTMLT_H5
    ,HTMLT_H6
    ,HTMLT_HEAD
    ,HTMLT_HR
    ,HTMLT_HTML
    ,HTMLT_I
    ,HTMLT_IMAGE
    ,HTMLT_IMG
    ,HTMLT_INPUT
    ,HTMLT_ISINDEX
    ,HTMLT_KBD
    ,HTMLT_L
    ,HTMLT_LABEL
    ,HTMLT_LI
    ,HTMLT_LINK
    ,HTMLT_LISTING
    ,HTMLT_LIT
    ,HTMLT_MAP
    ,HTMLT_MARGIN
    ,HTMLT_MARQUEE
    ,HTMLT_MATH
    ,HTMLT_MENU
    ,HTMLT_META
    ,HTMLT_NEXTID
    ,HTMLT_NOBR
    ,HTMLT_NOFRAMES
    ,HTMLT_NOTE
    ,HTMLT_OBJECT
    ,HTMLT_OL
    ,HTMLT_OPTION
    ,HTMLT_OVER
    ,HTMLT_P
    ,HTMLT_PARAM
    ,HTMLT_PERSON
    ,HTMLT_PLAINTEXT
    ,HTMLT_PRE
    ,HTMLT_Q
    ,HTMLT_QUOTE
    ,HTMLT_REMOVED
    ,HTMLT_RENDER
    ,HTMLT_S
    ,HTMLT_SAMP
    ,HTMLT_SCRIPT
    ,HTMLT_SELECT
    ,HTMLT_SMALL
    ,HTMLT_SPAN
    ,HTMLT_STRIKE
    ,HTMLT_STRONG
    ,HTMLT_STYLE
    ,HTMLT_SUB
    ,HTMLT_SUP
    ,HTMLT_TAB
    ,HTMLT_TABLE
    ,HTMLT_TBODY
    ,HTMLT_TD
    ,HTMLT_TEXTAREA
    ,HTMLT_TEXTFLOW
    ,HTMLT_TFOOT
    ,HTMLT_TH
    ,HTMLT_THEAD
    ,HTMLT_TITLE
    ,HTMLT_TR
    ,HTMLT_TT
    ,HTMLT_U
    ,HTMLT_UL
    ,HTMLT_VAR
    ,HTMLT_WBR
    ,HTMLT_XMP
    ,HTMLT_XXX_NULL  
} HTMLToken;










typedef enum {
	 HTML_ATTR_XXX_INVALID        = 0x0  
	,HTML_ATTR_ACTION
	,HTML_ATTR_ALIGN
	,HTML_ATTR_ALT
	,HTML_ATTR_AREA
	,HTML_ATTR_AT
	,HTML_ATTR_BACKGROUND
	,HTML_ATTR_BEHAVIOR
	,HTML_ATTR_BGCOLOR
	,HTML_ATTR_BORDER
	,HTML_ATTR_BORDERCOLOR
	,HTML_ATTR_BORDERCOLORDARK
	,HTML_ATTR_BORDERCOLORLIGHT
	,HTML_ATTR_CELLPADDING
	,HTML_ATTR_CELLSPACING
	,HTML_ATTR_CHECKED
	,HTML_ATTR_CLASSID
	,HTML_ATTR_CLEAR
	,HTML_ATTR_CODEBASE
	,HTML_ATTR_CODETYPE
	,HTML_ATTR_COLOR
	,HTML_ATTR_COLS
	,HTML_ATTR_COLSPAN
	,HTML_ATTR_COMPACT
	,HTML_ATTR_CONTENT
	,HTML_ATTR_COORDS
	,HTML_ATTR_CONTROLS
	,HTML_ATTR_DATA
	,HTML_ATTR_DECLARE
	,HTML_ATTR_DIRECTION
	,HTML_ATTR_DISABLED
	,HTML_ATTR_DYNSRC
	,HTML_ATTR_EFFECT
	,HTML_ATTR_ERROR
	,HTML_ATTR_FACE
	,HTML_ATTR_FRAME
	,HTML_ATTR_HEIGHT
	,HTML_ATTR_HREF
	,HTML_ATTR_HSPACE
	,HTML_ATTR_HTTP_EQUIV
	,HTML_ATTR_ID
	,HTML_ATTR_IDREF
	,HTML_ATTR_INDEX
	,HTML_ATTR_ISMAP
	,HTML_ATTR_LANG
	,HTML_ATTR_LANGUAGE
	,HTML_ATTR_LOOP
	,HTML_ATTR_MAXLENGTH
	,HTML_ATTR_METHOD
	,HTML_ATTR_METHODS
	,HTML_ATTR_MIN
	,HTML_ATTR_MULTIPLE
	,HTML_ATTR_N
	,HTML_ATTR_NAME
	,HTML_ATTR_NOHREF
	,HTML_ATTR_NOSHADE
	,HTML_ATTR_NOWRAP
	,HTML_ATTR_ONCLICK
	,HTML_ATTR_PLAIN
	,HTML_ATTR_PRINT
	,HTML_ATTR_REL
	,HTML_ATTR_REV
	,HTML_ATTR_ROLE
	,HTML_ATTR_ROWS
	,HTML_ATTR_ROWSPAN
	,HTML_ATTR_RULES
	,HTML_ATTR_SCROLLAMOUNT
	,HTML_ATTR_SCROLLDELAY
	,HTML_ATTR_SEETHRU
	,HTML_ATTR_SELECTED
	,HTML_ATTR_SHAPE
	,HTML_ATTR_SHAPES
	,HTML_ATTR_SIZE
	,HTML_ATTR_SRC
	,HTML_ATTR_STANDBY
	,HTML_ATTR_START
	,HTML_ATTR_STYLE
	,HTML_ATTR_TAG
	,HTML_ATTR_TARGET
	,HTML_ATTR_TITLE
	,HTML_ATTR_TYPE
	,HTML_ATTR_URL
	,HTML_ATTR_USEMAP
	,HTML_ATTR_VALIGN
	,HTML_ATTR_VALUE
	,HTML_ATTR_VALUETYPE
	,HTML_ATTR_VSPACE
	,HTML_ATTR_WIDTH
	,HTML_ATTR_WRAP
	,HTML_ATTR_XXX_NULL   
} HTMLAttr;








#endif

# 40 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

#define TAB_SIZE		160	
#define TAB_POINT		TAB_SIZE / 8
#define X_SCREEN_SIZE		405	
#define HR_HEIGHT_Y		5	
#define ROW_SIZE		25      
#define COLUMN_SIZE		5      
#define NESTED_MARGIN		14
#define MARGIN                  3       

typedef ByteEnum ErrorCode;
#define UI_GEN_NO_ERROR 	0
#define UI_GEN_ERROR		1

typedef ByteEnum StyleType;
#define STYLE_STRIKE		40
#define STYLE_FONT		41
#define STYLE_ITALIC		42
#define STYLE_BOLD		43
#define STYLE_ANCHOR		44
#define STYLE_SUPERSCRIPT	45
#define STYLE_SUBSCRIPT		46
#define STYLE_HEADER		47
#define STYLE_FW_FONT		48
#define STYLE_PRE		49
#define STYLE_UL		50
#define STYLE_OL		51
#define STYLE_DL		52
#define STYLE_BQ		53
#define STYLE_ALIGN		54
#define STYLE_PARAGRAPH		55
#define STYLE_NOBR		56

typedef ByteEnum FontType;
#define STYLE_FONT_0		7
#define STYLE_FONT_1		9
#define STYLE_FONT_2		10
#define STYLE_FONT_3		12	
#define STYLE_FONT_4		14
#define STYLE_FONT_5		16
#define STYLE_FONT_6		18
#define STYLE_FONT_7		24
#define STYLE_FONT_8		36


typedef ByteEnum ElementType;
#define	ELEMENT_START		0
#define	ELEMENT_END		1

typedef ByteEnum CellType;
#define	CELL_DATA		0
#define	CELL_HEADER		1

typedef ByteEnum InputType;
#define INPUT_NONE		0
#define INPUT_TEXT		1
#define INPUT_PASSWORD		2
#define INPUT_CHECKBOX		3
#define INPUT_RADIO		4
#define INPUT_SUBMIT		5
#define INPUT_RESET		6
#define INPUT_HIDDEN		7
#define INPUT_IMAGE		8

typedef ByteEnum AlignType;
#define ALIGN_TOP		0
#define ALIGN_MIDDLE		1
#define ALIGN_BOTTOM		2

typedef ByteEnum AreaType;
#define AREA_RECT		0
#define AREA_CIRC		1
#define AREA_POLY		2
#define AREA_DEFAULT		3

typedef ByteEnum TriggerType;
#define	TRIGGER_RESET		INPUT_RESET
#define	TRIGGER_SUBMIT		INPUT_SUBMIT


#define DEFAULT_STYLE_FONT	STYLE_FONT_3
#define DEFAULT_ALIGNMENT	J_LEFT






typedef struct {
	StyleType	LG_groupType;	
	int		LG_counter;	

	char		LG_displayType;	





} ListGroup;


typedef struct {
	optr obj;
	ClassStruct *class;
} ObjInfo;

typedef struct {
	HTMemHandle	MI_mapName;
	HTListHandle	MI_areas;
} MapItem;

typedef struct {
	HTMemHandle	AI_href;
	HTMemHandle	AI_coords;
	AreaType	AI_shape;
} AreaItem;

typedef struct {
        int             AE_token;
        dword           AE_start;
        dword           AE_end;
} AnchorElement;





void MapAttrSizeToPointSize (int size, WWFixed *number);
int MapPointSizeToAttrSize (int number);
void AddTextLineBreaks (ObjInfo *textObj, int numLine);
void AddSpaceSeparator(ObjInfo *textObj, int numLine, Boolean blankLine);
void ProcessOrderedListAttr
     (MemHandle block, SGMLEntity *entity, optr content);
void ProcessUnorderedListAttr
     (MemHandle block, SGMLEntity *entity, optr content);
void ProcessLIAttr (MemHandle block, SGMLEntity *entity,
     StyleType type, int *counter, char *displayType, optr content);
void SetTabsForListGroup (int level, optr obj);
void MyVisTextFormatNumber(char *temp, int counter, VisTextNumberType type);
Justification ProcessAlignAttr (char *type);
void FormatSetTextBQ(optr text, optr content);
void ProcessHeaderAttr(MemHandle block, SGMLEntity *entity,
     ObjInfo *target, optr content);
void ProcessParagraphAttr 
     (MemHandle dataBlock, ChunkHandle dataChunk, optr content);
int  UpdateItsPotentialPosition(optr obj, SizeAsDWord size, int *row);
int  GetItsPotentialHeight (optr obj, int row);
void AddNewLine(ObjInfo *Obj, int numLine, optr pmanager, optr content);
optr FinishCurrentObjectInForm (optr pmObj, ObjInfo *target);






#define MSG_META_UIG_SELECT_ALL 405
#define MSG_META_UIG_SELECT_NONE 406
#define MSG_META_UIG_CALC_POSITION 407

#define UIGeneratorBase MetaBase
#define _FIRST_UIGeneratorClass 8192
# 199 "/staff/pcgeos/CInclude/WWW/uigenera.goh"








































































	


	
	




	
	



	
	




	
	




	
extern ClassStruct UIGeneratorClass; extern Message _Messages_UIGeneratorClass[]; extern MessageMethod *_Methods_UIGeneratorClass[]; extern CMethodDef _htypes_UIGeneratorClass[];extern MessageMethod *_Reloc_UIGeneratorClass;
typedef struct _UIGeneratorInstance {

# 53 "/staff/pcgeos/CInclude/Objects/metaC.goh"
    MetaBase MI_base;
# 301 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    optr UIG_pmObj;





    ObjInfo UIG_target;




    optr UIG_content;





    HTMemHandle UIG_currentMap;





    int UIG_hrefToken;} UIGeneratorInstance; 
# 325 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_UI_GENERATOR_INITIALIZE=8192,MSG_UI_GENERATOR_SET_LOADING_OPTION,MSG_UI_GENERATOR_START_TITLE,MSG_UI_GENERATOR_END_TITLE,MSG_UI_GENERATOR_CREATE_BASE,MSG_UI_GENERATOR_CREATE_HR,MSG_UI_GENERATOR_APPEND_TEXT_PTR,MSG_UI_GENERATOR_CREATE_TEXT_OBJECT,MSG_UI_GENERATOR_START_FORM,MSG_UI_GENERATOR_END_FORM,MSG_UI_GENERATOR_START_SELECT,MSG_UI_GENERATOR_END_SELECT,MSG_UI_GENERATOR_CREATE_OPTION,MSG_UI_GENERATOR_CREATE_INPUT,MSG_UI_GENERATOR_START_TEXTAREA,MSG_UI_GENERATOR_END_TEXTAREA,MSG_UI_GENERATOR_START_TABLE,MSG_UI_GENERATOR_END_TABLE,MSG_UI_GENERATOR_START_CAPTION,MSG_UI_GENERATOR_END_CAPTION,MSG_UI_GENERATOR_START_TR,MSG_UI_GENERATOR_CREATE_TH,MSG_UI_GENERATOR_CREATE_TD,MSG_UI_GENERATOR_CREATE_IMAGE,MSG_UI_GENERATOR_START_MAP,MSG_UI_GENERATOR_END_MAP,MSG_UI_GENERATOR_CREATE_AREA,MSG_UI_GENERATOR_END_FORMAT,MSG_UI_GENERATOR_GET_CONTENT,MSG_UI_GENERATOR_START_BOLD,MSG_UI_GENERATOR_START_ITALIC,MSG_UI_GENERATOR_START_STRIKE,MSG_UI_GENERATOR_START_SUPERSCRIPT,MSG_UI_GENERATOR_START_SUBSCRIPT,MSG_UI_GENERATOR_START_FONT_SIZE,MSG_UI_GENERATOR_CHANGE_SMALL_FONT,MSG_UI_GENERATOR_CHANGE_BIG_FONT,MSG_UI_GENERATOR_ADD_BR,MSG_UI_GENERATOR_START_HEADER,MSG_UI_GENERATOR_START_FIXED_WIDTH_FONT,MSG_UI_GENERATOR_START_PRE,MSG_UI_GENERATOR_START_UNORDERED_LIST,MSG_UI_GENERATOR_END_LIST,MSG_UI_GENERATOR_START_ORDERED_LIST,MSG_UI_GENERATOR_CREATE_LIST_ITEM,MSG_UI_GENERATOR_CREATE_UNORDERED_LIST_ITEM,MSG_UI_GENERATOR_CREATE_ORDERED_LIST_ITEM,MSG_UI_GENERATOR_START_DEFINITION_LIST,MSG_UI_GENERATOR_CREATE_DEFINITION_DT,MSG_UI_GENERATOR_CREATE_DEFINITION_DD,MSG_UI_GENERATOR_START_BLOCKQUOTE,MSG_UI_GENERATOR_START_CENTER,MSG_UI_GENERATOR_END_ALIGN,MSG_UI_GENERATOR_START_PARAGRAPH,MSG_UI_GENERATOR_START_DIV,MSG_UI_GENERATOR_START_NOBR,MSG_UI_GENERATOR_END_NOBR,MSG_UI_GENERATOR_START_ANCHOR,MSG_UI_GENERATOR_PROCESS_A_ATTRIBUTE,MSG_UI_GENERATOR_END_HTML,MSG_UI_GENERATOR_CLEAR_UI_TREE,MSG_UI_GENERATOR_CREATE_SINGLE_IMAGE,MSG_UI_GENERATOR_BROADCAST_RESIZE_POSITION,}UIGeneratorMessages;;




#define HTGenTextBase GenTextBase
#define _FIRST_HTGenTextClass 27136
# 330 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 
 
 

 
 
	



	
	




	
	
	


	
        


	
	



	
	


	
        
	


	
	


	
extern ClassStruct HTGenTextClass; extern Message _Messages_HTGenTextClass[]; extern MessageMethod *_Methods_HTGenTextClass[]; extern CMethodDef _htypes_HTGenTextClass[];extern MessageMethod *_Reloc_HTGenTextClass;
typedef struct _HTGenTextInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 217 "/staff/pcgeos/CInclude/Objects/gTextC.goh"
    ChunkHandle GTXI_text;
    word GTXI_maxLength;
    GenTextAttrs GTXI_attrs;
    GenTextStateFlags GTXI_stateFlags;
    optr GTXI_destination;
    word GTXI_applyMsg;
# 351 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    GStateHandle HTGT_gstate;





    int HTGT_maxLen;
    int HTGT_accLen;



    Boolean HTGT_selected;



    HTListHandle HTGT_anchorList;




    int HTGT_focalAnchor;



    RectDWord HTGT_focalBound;
    Rectangle HTGT_focalBox;



    int HTGT_xPos;



    int HTGT_pageRow;} HTGenTextInstance; 
# 385 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_TEXT_CHANGE_SIMPLE_RENDERING=27136,MSG_GEN_TEXT_INITIALIZE,MSG_GEN_TEXT_UPDATE_MAX_LEN_AND_RESET_ACC_LEN,MSG_GEN_TEXT_SET_MIN_SIZE,MSG_GEN_TEXT_RECORD_HREF,MSG_GEN_TEXT_FIND_LINK_UNDER_MOUSE,MSG_GEN_TEXT_DRAW_FOCUS,MSG_GEN_TEXT_UNDRAW_FOCUS,MSG_GEN_TEXT_FIND_LINK_IN_RECT,}HTGenTextMessages;;





#define HTGenFormTextBase GenTextBase
#define _FIRST_HTGenFormTextClass 27136
# 391 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
	



	
	



	
	 



	
	 


	
extern ClassStruct HTGenFormTextClass; extern Message _Messages_HTGenFormTextClass[]; extern MessageMethod *_Methods_HTGenFormTextClass[]; extern CMethodDef _htypes_HTGenFormTextClass[];extern MessageMethod *_Reloc_HTGenFormTextClass;
typedef struct _HTGenFormTextInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 217 "/staff/pcgeos/CInclude/Objects/gTextC.goh"
    ChunkHandle GTXI_text;
    word GTXI_maxLength;
    GenTextAttrs GTXI_attrs;
    GenTextStateFlags GTXI_stateFlags;
    optr GTXI_destination;
    word GTXI_applyMsg;
# 401 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGFT_name;




    HTMemHandle HTGFT_value;




    int HTGFT_xPos;



    int HTGFT_pageRow;} HTGenFormTextInstance; 
# 416 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_FORM_TEXT_PROCESS_ATTRIBUTE=27136,MSG_GEN_FORM_TEXT_INITIALIZE,MSG_GEN_FORM_TEXT_SUBMIT,}HTGenFormTextMessages;;




#define HTGenFormHiddenBase GenInteractionBase
#define _FIRST_HTGenFormHiddenClass 27136
# 421 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
	



	
	
extern ClassStruct HTGenFormHiddenClass; extern Message _Messages_HTGenFormHiddenClass[]; extern MessageMethod *_Methods_HTGenFormHiddenClass[]; extern CMethodDef _htypes_HTGenFormHiddenClass[];extern MessageMethod *_Reloc_HTGenFormHiddenClass;
typedef struct _HTGenFormHiddenInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 429 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGFH_name;
    HTMemHandle HTGFH_value;} HTGenFormHiddenInstance; 
# 431 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_FORM_HIDDEN_INITIALIZE=27136,MSG_GEN_FORM_HIDDEN_SUBMIT,}HTGenFormHiddenMessages;;

#define HTGenFormTriggerBase GenTriggerBase
#define _FIRST_HTGenFormTriggerClass 27136
# 433 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
	




	
	


	
	 



	
	 


	
extern ClassStruct HTGenFormTriggerClass; extern Message _Messages_HTGenFormTriggerClass[]; extern MessageMethod *_Methods_HTGenFormTriggerClass[]; extern CMethodDef _htypes_HTGenFormTriggerClass[];extern MessageMethod *_Reloc_HTGenFormTriggerClass;
typedef struct _HTGenFormTriggerInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 55 "/staff/pcgeos/CInclude/Objects/gTrigC.goh"
    optr GTI_destination;
    Message GTI_actionMsg;
# 442 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGFT_name;



    TriggerType HTGFT_type;




    int HTGFT_xPos;



    int HTGFT_pageRow;} HTGenFormTriggerInstance; 
# 456 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_FORM_TRIGGER_INITIALIZE=27136,MSG_GEN_FORM_TRIGGER_SUBMIT,}HTGenFormTriggerMessages;;







#define HTGenOuterSelectBase GenInteractionBase
#define _FIRST_HTGenOuterSelectClass 27136
# 464 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

	 



	
	 


	
extern ClassStruct HTGenOuterSelectClass; extern Message _Messages_HTGenOuterSelectClass[]; extern MessageMethod *_Methods_HTGenOuterSelectClass[]; extern CMethodDef _htypes_HTGenOuterSelectClass[];extern MessageMethod *_Reloc_HTGenOuterSelectClass;
typedef struct _HTGenOuterSelectInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 469 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    int HTGOS_xPos;



    int HTGOS_pageRow;} HTGenOuterSelectInstance; 
# 474 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
;

#define HTGenSelectBase GenItemGroupBase
#define _FIRST_HTGenSelectClass 27136
# 476 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 
 
	



	
	



	
	



	 
	



	
	



	
extern ClassStruct HTGenSelectClass; extern Message _Messages_HTGenSelectClass[]; extern MessageMethod *_Methods_HTGenSelectClass[]; extern CMethodDef _htypes_HTGenSelectClass[];extern MessageMethod *_Reloc_HTGenSelectClass;
typedef struct _HTGenSelectInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 215 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"
    GenItemGroupBehaviorType GIGI_behaviorType;
    word GIGI_selection;
    word GIGI_numSelections;
    GenItemGroupStateFlags GIGI_stateFlags;
    optr GIGI_destination;
    Message GIGI_applyMsg;
# 488 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGS_name;




    int HTGS_size;




    InputType HTGS_type;




    int HTGS_select;




    int HTGS_idCounter;} HTGenSelectInstance; 
# 509 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_SELECT_PROCESS_ATTRIBUTE=27136,MSG_GEN_SELECT_GET_AND_INCREMENT_OPTION_ID,MSG_GEN_SELECT_COMPLETE_SELECT_CONSTRUCT,MSG_GEN_SELECT_SET_SELECT_ID,MSG_GEN_SELECT_SET_MULTIPLE_SELECTION,MSG_GEN_SELECT_SUBMIT,}HTGenSelectMessages;;





#define HTGenMultiLineSelectBase GenInteractionBase
#define _FIRST_HTGenMultiLineSelectClass 27136
# 515 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 
 
 
 
 
	



	
	



	
	
	

   	
	
	
	

	
	
	 



	
	 


	
extern ClassStruct HTGenMultiLineSelectClass; extern Message _Messages_HTGenMultiLineSelectClass[]; extern MessageMethod *_Methods_HTGenMultiLineSelectClass[]; extern CMethodDef _htypes_HTGenMultiLineSelectClass[];extern MessageMethod *_Reloc_HTGenMultiLineSelectClass;
typedef struct _HTGenMultiLineSelectInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 530 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    ChunkHandle HTGMLS_name;




    int HTGMLS_size;
    int HTGMLS_len;
    Boolean HTGMLS_exclusive;

    word HTGMLS_currentFirst;
    MemHandle HTGMLS_optionsHandle;
    ChunkHandle HTGMLS_optionsChunk;
    ChunkHandle HTGMLS_itemChunk;

    optr HTGMLS_up;
    optr HTGMLS_down;




    int HTGMLS_xPos;



    int HTGMLS_pageRow;} HTGenMultiLineSelectInstance; 
# 555 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_HTGMLS_PROCESS_ATTRIBUTE=27136,MSG_HTGMLS_ADD_OPTION_VALUE,MSG_HTGMLS_ADD_OPTION_TEXT,MSG_HTGMLS_COMPLETE_SELECT_CONSTRUCT,MSG_HTGMLS_SET_ALL_MONIKER,MSG_HTGMLS_SCROLL_UP,MSG_HTGMLS_SCROLL_DOWN,MSG_HTGMLS_CHANGE_SELECT,MSG_HTGMLS_SUBMIT,}HTGenMultiLineSelectMessages;;


#define HTOtherOptionBase GenGlyphBase
#define _FIRST_HTOtherOptionClass 27136
# 558 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 

	
	
extern ClassStruct HTOtherOptionClass; extern Message _Messages_HTOtherOptionClass[]; extern MessageMethod *_Methods_HTOtherOptionClass[]; extern CMethodDef _htypes_HTOtherOptionClass[];extern MessageMethod *_Reloc_HTOtherOptionClass;
typedef struct _HTOtherOptionInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 563 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    optr HTOO_multiLine;
    Boolean HTOO_selected;} HTOtherOptionInstance; 
# 565 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_HTOO_SET_ML=27136,MSG_HTOO_SET_SEL,MSG_HTOO_GET_SEL,}HTOtherOptionMessages;;





#define HTGenOptionBase GenItemBase
#define _FIRST_HTGenOptionClass 27136
# 571 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
	
		
extern ClassStruct HTGenOptionClass; extern Message _Messages_HTGenOptionClass[]; extern MessageMethod *_Methods_HTGenOptionClass[]; extern CMethodDef _htypes_HTGenOptionClass[];extern MessageMethod *_Reloc_HTGenOptionClass;
typedef struct _HTGenOptionInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 33 "/staff/pcgeos/CInclude/Objects/gItemC.goh"
    word GII_identifier;
# 577 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGO_value;
    Boolean HTGO_selected;} HTGenOptionInstance; 
# 579 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_OPTION_PROCESS_ATTRIBUTE=27136,MSG_GEN_OPTION_SET_SELECTED,MSG_GEN_OPTION_IS_SELECTED,MSG_GEN_OPTION_SUBMIT,}HTGenOptionMessages;;





#define HTGenInputBase GenItemGroupBase
#define _FIRST_HTGenInputClass 27136
# 585 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 

 
 
 
	 


	
	 


	
	 


	
	


	
	 



	
	 


	
extern ClassStruct HTGenInputClass; extern Message _Messages_HTGenInputClass[]; extern MessageMethod *_Methods_HTGenInputClass[]; extern CMethodDef _htypes_HTGenInputClass[];extern MessageMethod *_Reloc_HTGenInputClass;
typedef struct _HTGenInputInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 215 "/staff/pcgeos/CInclude/Objects/gItemGC.goh"
    GenItemGroupBehaviorType GIGI_behaviorType;
    word GIGI_selection;
    word GIGI_numSelections;
    GenItemGroupStateFlags GIGI_stateFlags;
    optr GIGI_destination;
    Message GIGI_applyMsg;
# 596 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    Boolean HTGI_select;



    HTMemHandle HTGI_name;



    HTMemHandle HTGI_value;



    optr HTGI_next;




    int HTGI_xPos;



    int HTGI_pageRow;} HTGenInputInstance; 
# 618 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_INPUT_STORE_DATA=27136,MSG_GEN_INPUT_ADD_SIBLING,MSG_GEN_INPUT_CLEAR_SELECTIONS,MSG_GEN_INPUT_SUBMIT,}HTGenInputMessages;;






#define HTGenTableBase GenInteractionBase
#define _FIRST_HTGenTableClass 27136
# 625 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 
 
 
 
 
 
 
 
 
	


	
	


	
	


	
	


	
	


	
	



	
	
	



	
	




	  
	    
	   
	 
	




	
	


	
	


	
	


	
extern ClassStruct HTGenTableClass; extern Message _Messages_HTGenTableClass[]; extern MessageMethod *_Methods_HTGenTableClass[]; extern CMethodDef _htypes_HTGenTableClass[];extern MessageMethod *_Reloc_HTGenTableClass;
typedef struct _HTGenTableInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 646 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    Boolean HTGT_showBorder;



    int HTGT_cellpadding;



    int HTGT_cellspacing;



    optr HTGT_caption;



    int HTGT_width;




    int HTGT_rowNo;
    int HTGT_colNo;




    word HTGT_numCols;





    ChunkHandle HTGT_rowHeight;
    int HTGT_rowSize;
    ChunkHandle HTGT_colWidth;
    int HTGT_columnSize;





    ChunkHandle HTGT_finalColWidth;



    int HTGT_xPos;



    int HTGT_pageRow;



    char HTGT_captionAlign;} HTGenTableInstance; 
# 701 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_TABLE_PROCESS_ATTRIBUTE=27136,MSG_GEN_TABLE_INCREMENT_ROW_COUNT,MSG_GEN_TABLE_INCREMENT_COL_COUNT,MSG_GEN_TABLE_GET_NEXT_TABLE_CELL_POSITION,MSG_GEN_TABLE_UPDATE_MAX_CELL_HEIGHT,MSG_GEN_TABLE_GET_FINAL_CELL_PIXEL_POSITION,MSG_GEN_TABLE_GET_ROWSPAN_SIZE,MSG_GEN_TABLE_GET_COLSPAN_SIZE,MSG_GEN_TABLE_SHOW_BORDER,MSG_GEN_TABLE_GET_CELLPADDING,MSG_GEN_TABLE_DISTRIBUTE_COLUMN_WIDTH,MSG_GEN_TABLE_SET_FINAL_CELL_WIDTH,MSG_GEN_TABLE_STORE_TCELL_WIDTH,}HTGenTableMessages;;






#define HTGenHtmlContentBase GenInteractionBase
#define _FIRST_HTGenHtmlContentClass 27136
# 708 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
	
	

	
	

	
	

	
	
	





	
	
	
	
	
	
	
        





	
	



	
	
	
	 


	
	 


	
	 


	
	 


	
	 


	
	 


	
	 


	
extern ClassStruct HTGenHtmlContentClass; extern Message _Messages_HTGenHtmlContentClass[]; extern MessageMethod *_Methods_HTGenHtmlContentClass[]; extern CMethodDef _htypes_HTGenHtmlContentClass[];extern MessageMethod *_Reloc_HTGenHtmlContentClass;
typedef struct _HTGenHtmlContentInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 739 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    StyleType HTGHC_formatStack[20];
    int HTGHC_formatIndex;

    FontType HTGHC_fontStack[10];
    int HTGHC_fontIndex;

    ListGroup HTGHC_listStack[10];
    int HTGHC_listIndex;

    Justification HTGHC_alignStack[10];
    int HTGHC_alignIndex;






    int HTGHC_cntUnderline;
    int HTGHC_cntBold;
    int HTGHC_cntItalic;
    int HTGHC_cntStrike;
    int HTGHC_cntSuperscript;
    int HTGHC_cntSubscript;
    int HTGHC_cntFWFont;






    int HTGHC_hrefToken;




    HTListHandle HTGHC_heightArray;
    int HTGHC_heightIndex;
    int HTGHC_sumOfHeights;



    int HTGHC_accumulatedPrevWidth;



    int HTGHC_rowIndex;



    int HTGHC_widthCurrentObj;



    int HTGHC_heightCurrentObj;



    int HTGHC_maxHeightInRow;



    int HTGHC_maxRowWidth;



    optr HTGHC_currentObj;} HTGenHtmlContentInstance; 
# 805 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_HTML_CONTENT_FORMAT_TEXT_OBJECT=27136,MSG_GEN_HTML_CONTENT_SET_CONTENT,MSG_GEN_HTML_CONTENT_REMOVE_CONTENT,MSG_GEN_HTML_CONTENT_GET_CONTENT_TYPE,MSG_GEN_HTML_CONTENT_GET_STYLE_COUNT,MSG_GEN_HTML_CONTENT_GET_FONT_SIZE,MSG_GEN_HTML_CONTENT_PUSH_FONT_SIZE,MSG_GEN_HTML_CONTENT_POP_FONT_SIZE,MSG_GEN_HTML_CONTENT_PUSH_JUSTIFICATION,MSG_GEN_HTML_CONTENT_POP_JUSTIFICATION,MSG_GEN_HTML_CONTENT_GET_JUSTIFICATION,MSG_GEN_HTML_CONTENT_PUSH_LIST_GROUP,MSG_GEN_HTML_CONTENT_POP_LIST_GROUP,MSG_GEN_HTML_CONTENT_GET_LIST_GROUP,MSG_HTGHC_MSG_GEN_HTML_CONTENT_GET_ANY_LAST_LIST_GROUP,MSG_GEN_HTML_CONTENT_UPDATE_COUNTER,MSG_GEN_HTML_CONTENT_INCREMENT_COUNTER,MSG_GEN_HTML_CONTENT_SET_TEXT_ALIGNMENT,MSG_GEN_HTML_CONTENT_SET_HREF_TOKEN,MSG_GEN_HTML_CONTENT_GET_PREV_SIBLING_R_EDGE,MSG_GEN_HTML_CONTENT_RESET_ROW_COUNTER,MSG_GEN_HTML_CONTENT_GET_ROW_HEIGHT,MSG_GEN_HTML_CONTENT_START_NEW_ROW,MSG_GEN_HTML_CONTENT_SUM_ROW_HEIGHTS,MSG_GEN_HTML_CONTENT_UPDATE_MAX_HEIGHT,}HTGenHtmlContentMessages;;





#define HTGenFormBase HTGenHtmlContentBase
#define _FIRST_HTGenFormClass 27648
# 811 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 

	


	
	


		
	




	
	
	


	
	


	
extern ClassStruct HTGenFormClass; extern Message _Messages_HTGenFormClass[]; extern MessageMethod *_Methods_HTGenFormClass[]; extern CMethodDef _htypes_HTGenFormClass[];extern MessageMethod *_Reloc_HTGenFormClass;
typedef struct _HTGenFormInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 739 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    StyleType HTGHC_formatStack[20];
    int HTGHC_formatIndex;

    FontType HTGHC_fontStack[10];
    int HTGHC_fontIndex;

    ListGroup HTGHC_listStack[10];
    int HTGHC_listIndex;

    Justification HTGHC_alignStack[10];
    int HTGHC_alignIndex;






    int HTGHC_cntUnderline;
    int HTGHC_cntBold;
    int HTGHC_cntItalic;
    int HTGHC_cntStrike;
    int HTGHC_cntSuperscript;
    int HTGHC_cntSubscript;
    int HTGHC_cntFWFont;






    int HTGHC_hrefToken;




    HTListHandle HTGHC_heightArray;
    int HTGHC_heightIndex;
    int HTGHC_sumOfHeights;



    int HTGHC_accumulatedPrevWidth;



    int HTGHC_rowIndex;



    int HTGHC_widthCurrentObj;



    int HTGHC_heightCurrentObj;



    int HTGHC_maxHeightInRow;



    int HTGHC_maxRowWidth;



    optr HTGHC_currentObj;
# 822 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGF_action;



    HTMethod HTGF_method;





    optr HTGF_first;
    optr HTGF_last;



    int HTGF_xPos;



    int HTGF_pageRow;} HTGenFormInstance; 
# 842 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_FORM_PROCESS_ATTRIBUTE=27648,MSG_GEN_FORM_RESET,MSG_GEN_FORM_SUBMIT,MSG_GEN_FORM_ADD_INPUT,MSG_GEN_FORM_SET_EXCLUSIVE_SELECTION,}HTGenFormMessages;;





#define HTGenTCellBase HTGenHtmlContentBase
#define _FIRST_HTGenTCellClass 27648
# 848 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
	
	
	
	



	
	
	
extern ClassStruct HTGenTCellClass; extern Message _Messages_HTGenTCellClass[]; extern MessageMethod *_Methods_HTGenTCellClass[]; extern CMethodDef _htypes_HTGenTCellClass[];extern MessageMethod *_Reloc_HTGenTCellClass;
typedef struct _HTGenTCellInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 739 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    StyleType HTGHC_formatStack[20];
    int HTGHC_formatIndex;

    FontType HTGHC_fontStack[10];
    int HTGHC_fontIndex;

    ListGroup HTGHC_listStack[10];
    int HTGHC_listIndex;

    Justification HTGHC_alignStack[10];
    int HTGHC_alignIndex;






    int HTGHC_cntUnderline;
    int HTGHC_cntBold;
    int HTGHC_cntItalic;
    int HTGHC_cntStrike;
    int HTGHC_cntSuperscript;
    int HTGHC_cntSubscript;
    int HTGHC_cntFWFont;






    int HTGHC_hrefToken;




    HTListHandle HTGHC_heightArray;
    int HTGHC_heightIndex;
    int HTGHC_sumOfHeights;



    int HTGHC_accumulatedPrevWidth;



    int HTGHC_rowIndex;



    int HTGHC_widthCurrentObj;



    int HTGHC_heightCurrentObj;



    int HTGHC_maxHeightInRow;



    int HTGHC_maxRowWidth;



    optr HTGHC_currentObj;
# 854 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    CellType HTGTC_cellType;
    byte HTGTC_rowSpan;
    byte HTGTC_colSpan;




    int HTGTC_rowPos;
    int HTGTC_colPos;
    Boolean HTGTC_positioning;} HTGenTCellInstance; 
# 864 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_TCELL_PROCESS_ATTRIBUTE=27648,MSG_GEN_TCELL_SET_CELL_POSITION,MSG_GEN_TCELL_GET_CELL_POSITION,MSG_GEN_TCELL_GET_CELL_SPAN,}HTGenTCellMessages;;





#define HTGenCaptionBase HTGenHtmlContentBase
#define _FIRST_HTGenCaptionClass 27648
# 870 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
	



	
        
	


	
	


	
extern ClassStruct HTGenCaptionClass; extern Message _Messages_HTGenCaptionClass[]; extern MessageMethod *_Methods_HTGenCaptionClass[]; extern CMethodDef _htypes_HTGenCaptionClass[];extern MessageMethod *_Reloc_HTGenCaptionClass;
typedef struct _HTGenCaptionInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 739 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    StyleType HTGHC_formatStack[20];
    int HTGHC_formatIndex;

    FontType HTGHC_fontStack[10];
    int HTGHC_fontIndex;

    ListGroup HTGHC_listStack[10];
    int HTGHC_listIndex;

    Justification HTGHC_alignStack[10];
    int HTGHC_alignIndex;






    int HTGHC_cntUnderline;
    int HTGHC_cntBold;
    int HTGHC_cntItalic;
    int HTGHC_cntStrike;
    int HTGHC_cntSuperscript;
    int HTGHC_cntSubscript;
    int HTGHC_cntFWFont;






    int HTGHC_hrefToken;




    HTListHandle HTGHC_heightArray;
    int HTGHC_heightIndex;
    int HTGHC_sumOfHeights;



    int HTGHC_accumulatedPrevWidth;



    int HTGHC_rowIndex;



    int HTGHC_widthCurrentObj;



    int HTGHC_heightCurrentObj;



    int HTGHC_maxHeightInRow;



    int HTGHC_maxRowWidth;



    optr HTGHC_currentObj;
# 879 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    optr HTGC_targetObj;
    ClassStruct   * HTGC_targetClass;



    int HTGC_xPos;



    int HTGC_pageRow;} HTGenCaptionInstance; 
# 889 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_CAPTION_SAVE_UIG_STATE=27648,MSG_GEN_CAPTION_RESTORE_UIG_STATE,}HTGenCaptionMessages;;





#define HTGenImageBase GenGlyphBase
#define _FIRST_HTGenImageClass 27136
# 895 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
 
 
 
 

 
 
 
 
 
	


	
	


	
	


	
	


	
	



	
	



	
        


  
        
        


        
        


        

 	
 	
	
        



        
        

	


	
extern ClassStruct HTGenImageClass; extern Message _Messages_HTGenImageClass[]; extern MessageMethod *_Methods_HTGenImageClass[]; extern CMethodDef _htypes_HTGenImageClass[];extern MessageMethod *_Reloc_HTGenImageClass;
typedef struct _HTGenImageInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 912 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    HTMemHandle HTGI_src;



    int HTGI_width;



    int HTGI_height;



    Boolean HTGI_ismap;




    HTMemHandle HTGI_alt;




    HTMemHandle HTGI_usemap;




    int HTGI_hrefToken;



    int HTGI_xPos;



    int HTGI_pageRow;

    VMFileHandle HTGI_bitmapFile;
    VMBlockHandle HTGI_bitmapBlock;
    Boolean first_draw;




    Boolean HTGI_focalAnchor;
    RectDWord HTGI_focalBound;




    Boolean HTGI_load;} HTGenImageInstance; 
# 963 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_IMAGE_PROCESS_ATTRIBUTE=27136,MSG_GEN_IMAGE_REQUEST,MSG_GEN_IMAGE_SET_HYPERLINK,MSG_GEN_IMAGE_GET_SRC,MSG_GEN_IMAGE_SET_BITMAP,MSG_GEN_IMAGE_SET_BOUNDS,MSG_GEN_IMAGE_ADD_ONE_LINE,MSG_GEN_IMAGE_DRAW_FOCUS,MSG_GEN_IMAGE_UNDRAW_FOCUS,MSG_GEN_IMAGE_FIND_LINK_IN_RECT,}HTGenImageMessages;;





#define HTGenHRBase GenGlyphBase
#define _FIRST_HTGenHRClass 27136
# 969 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

 
	


	
	



	
	


	
        


        
        


        
extern ClassStruct HTGenHRClass; extern Message _Messages_HTGenHRClass[]; extern MessageMethod *_Methods_HTGenHRClass[]; extern CMethodDef _htypes_HTGenHRClass[];extern MessageMethod *_Reloc_HTGenHRClass;
typedef struct _HTGenHRInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 975 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    int HTGHR_size;




    int HTGHR_width;



    Boolean HTGHR_noshade;



    int HTGHR_xPos;



    int HTGHR_pageRow;} HTGenHRInstance; 
# 993 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_HR_PROCESS_ATTRIBUTE=27136,}HTGenHRMessages;;





#define HTGenLineFeedBase GenInteractionBase
#define _FIRST_HTGenLineFeedClass 27136
# 999 "/staff/pcgeos/CInclude/WWW/uigenera.goh"

  
	
extern ClassStruct HTGenLineFeedClass; extern Message _Messages_HTGenLineFeedClass[]; extern MessageMethod *_Methods_HTGenLineFeedClass[]; extern CMethodDef _htypes_HTGenLineFeedClass[];extern MessageMethod *_Reloc_HTGenLineFeedClass;
typedef struct _HTGenLineFeedInstance {

# 28 "/staff/pcgeos/CInclude/Objects/genC.goh"
    MetaBase Gen;
# 897 "/staff/pcgeos/CInclude/Objects/genC.goh"
    LinkPart GI_link;
    CompPart GI_comp;
    ChunkHandle GI_visMoniker;
    word GI_kbdAccelerator;
    GenAttrs GI_attrs;
    GenStates GI_states;
# 131 "/staff/pcgeos/CInclude/Objects/gInterC.goh"
    GenInteractionType GII_type;

    GenInteractionVisibility GII_visibility;

    GenInteractionAttrs GII_attrs;
# 1001 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
    optr HTGLF_previous;} HTGenLineFeedInstance; 
# 1002 "/staff/pcgeos/CInclude/WWW/uigenera.goh"
typedef enum{MSG_GEN_LINE_FEED_INITIALIZE=27136,}HTGenLineFeedMessages;;





#endif

# 29 "content_e.c"

#ifndef __GOCuifatals
#define __GOCuifatals

# 1 "./uifatals.goh"

# 27 "./uifatals.goh"





typedef enum {
	UIG_INVALID_INPUT,
	UIG_INVALID_TEXT_OBJECT, 
	UIG_INVALID_OPERATION_ON_UI_TREE,
	UIG_UI_TREE_OPERATION_FAILS,
	UIG_UI_TABLE_OPERATION_FAILS,
	UIG_ERROR_IN_CONTENT_STACK,
	UIG_ERROR_IN_TITLE,
	UIG_ERROR_IN_TABLE,
	UIG_ERROR_NEGATIVE_WIDTH,
	UIG_ERROR_IN_FOCUS,
} FatalErrors;

typedef enum {
	UIG_INVALID_OPERATION,
	UIG_INVALID_LI_ITEM,
	UIG_UNBALANCED_LIST_STACK,
	UIG_UNBALANCED_ALIGN_STACK,
	UIG_UNBALANCED_POLY_PAIRS,
	UIG_UNBALANCED_COUNTER,
	UIG_UNBALANCED_ANCHORS,
	UIG_NESTED_ANCHORS_IN_CONTENT,
	UIG_NESTED_ANCHORS_IN_TEXT,
	UIG_WRONG_ASSUMPTION,
	UIG_TEXT_SPLITS_AT_4K_BYTES,
	UIG_TEXT_SPLITS_AT_5K_BYTES,
	UIG_BUTTON_NOT_SUPPORTED,
	UIG_FILE_NOT_SUPPORTED,
	UIG_NOT_SUPPORTED,
	UIG_TABLE_ARRAY_SIZE_REALLOC,
	UIG_NESTED_ANCHORS,
} Warnings;

extern FatalErrors uigenerashmefatals; 
extern Warnings uigenerashmewarnings;




#endif

# 30 "content_e.c"



#define POPPED	1	



















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 53 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_FORMAT_TEXT_OBJECT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, optr text, GStateHandle gstate){pragma Off(warn); pself; oself; message; pragma On(warn); 
  int 		n;
  WWFixed 	number;
  StyleType 	token;
  FontID	fontId;
  


  ((void(*)(word,dword,dword,word,optr,Message,word))&CObjMessage)(TAB_SIZE,
				TEXT_ADDRESS_PAST_END,
				TEXT_ADDRESS_PAST_END,  0x0, text, (Message) 18447, 0xa000+((0+(sizeof(word)+1)/2+(sizeof(dword)+1)/2+(sizeof(dword)+1)/2)*2));
  


  if (!(pself->HTGHC_cntFWFont))
    fontId = FID_DTC_URW_SANS;
  else
    fontId = FID_DTC_URW_MONO;
  ((void(*)(FontID,dword,dword,word,optr,Message,word))&CObjMessage)(fontId,
				TEXT_ADDRESS_PAST_END,
				TEXT_ADDRESS_PAST_END,  0x0, text, (Message) 741, 0xa000+((0+(sizeof(FontID)+1)/2+(sizeof(dword)+1)/2+(sizeof(dword)+1)/2)*2));
  




  number.WWF_int = ((byte(*)(word,optr,Message,word))&CObjMessage)( 0x8000, oself, (Message) 27141, 0xa200);
  number.WWF_frac = 0;
  
((void(*)(WWFixed,dword,dword,word,optr,Message,word))&CObjMessage)(number, TEXT_ADDRESS_PAST_END,TEXT_ADDRESS_PAST_END,  0x8000, text, (Message) 744, 0x0+((0+(sizeof(WWFixed)+1)/2+(sizeof(dword)+1)/2+(sizeof(dword)+1)/2)*2));
  


  GrSetFont(gstate, fontId, MakeWWFixed(number.WWF_int));
  



  ((void(*)(optr,word,optr,Message,word))&CObjMessage)(text,  0x8000, oself, (Message) 27153, 0x100+((0+(sizeof(optr)+1)/2)*2));

  for (n = 0, token = pself->HTGHC_formatStack[0];
	n < pself->HTGHC_formatIndex;
	n++, token = pself->HTGHC_formatStack[n]) {
    switch (token) {
	case STYLE_STRIKE:
	  
((void(*)(ElementType,TextStyle,word,optr,Message,word))&CObjMessage)(ELEMENT_START, TS_STRIKE_THRU,  0x8000, text, (Message) 27136, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(TextStyle)+1)/2)*2));
	  break;
	case STYLE_ITALIC:
	  
((void(*)(ElementType,TextStyle,word,optr,Message,word))&CObjMessage)(ELEMENT_START, TS_ITALIC,  0x8000, text, (Message) 27136, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(TextStyle)+1)/2)*2));
	  break;
	case STYLE_ANCHOR:
	  if (pself->HTGHC_hrefToken != -1) {
	    
((void(*)(ElementType,TextStyle,word,optr,Message,word))&CObjMessage)(ELEMENT_START, TS_UNDERLINE,  0x8000, text, (Message) 27136, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(TextStyle)+1)/2)*2));
	    
((void(*)(ElementType,int,word,optr,Message,word))&CObjMessage)(ELEMENT_START, pself->HTGHC_hrefToken,  0x8000, text, (Message) 27140, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(int)+1)/2)*2));
	  }
	  break;
	case STYLE_BOLD:
	  
((void(*)(ElementType,TextStyle,word,optr,Message,word))&CObjMessage)(ELEMENT_START, TS_BOLD,  0x8000, text, (Message) 27136, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(TextStyle)+1)/2)*2));
	  break;
	case STYLE_SUPERSCRIPT:
	  
((void(*)(ElementType,TextStyle,word,optr,Message,word))&CObjMessage)(ELEMENT_START, TS_SUPERSCRIPT,  0x8000, text, (Message) 27136, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(TextStyle)+1)/2)*2));
	  break;
	case STYLE_SUBSCRIPT:
	  
((void(*)(ElementType,TextStyle,word,optr,Message,word))&CObjMessage)(ELEMENT_START, TS_SUBSCRIPT,  0x8000, text, (Message) 27136, 0x100+((0+(sizeof(ElementType)+1)/2+(sizeof(TextStyle)+1)/2)*2));
	  break;
	case STYLE_BQ:

	  break;
  	case STYLE_PARAGRAPH:
	  break;
	case STYLE_ALIGN:
	  break;
	case STYLE_FONT:
	  number.WWF_int = ((byte(*)(word,optr,Message,word))&CObjMessage)( 0x8000, oself, (Message) 27141, 0xa200);
	  number.WWF_frac= 0;
	  
((void(*)(WWFixed,dword,dword,word,optr,Message,word))&CObjMessage)(number,TEXT_ADDRESS_PAST_END,TEXT_ADDRESS_PAST_END,  0x8000, text, (Message) 744, 0x0+((0+(sizeof(WWFixed)+1)/2+(sizeof(dword)+1)/2+(sizeof(dword)+1)/2)*2));
	  break;
	case STYLE_FW_FONT:
	  if (!pself->HTGHC_cntFWFont)
	    ((void(*)(FontID,dword,dword,word,optr,Message,word))&CObjMessage)(FID_DTC_URW_SANS,
						 TEXT_ADDRESS_PAST_END,
						 TEXT_ADDRESS_PAST_END,  0x0, text, (Message) 741, 0xa000+((0+(sizeof(FontID)+1)/2+(sizeof(dword)+1)/2+(sizeof(dword)+1)/2)*2));
	  break;
	case STYLE_PRE:
	case STYLE_UL:
	case STYLE_OL:
	  
	case STYLE_HEADER:
	case STYLE_DL:
	  
	  break;
    } 
  } 
  return;

}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 175 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_SET_CONTENT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, StyleType type){pragma Off(warn); pself; oself; message; pragma On(warn); 
  pself->HTGHC_formatStack[pself->HTGHC_formatIndex] = type;
  pself->HTGHC_formatIndex++;
  EC_ERROR_IF(pself->HTGHC_formatIndex > 20, UIG_ERROR_IN_CONTENT_STACK);

  switch (type) {
    case STYLE_ANCHOR:
	pself->HTGHC_cntUnderline++;
	EC_WARNING_IF(pself->HTGHC_cntUnderline > 1,
		      UIG_NESTED_ANCHORS_IN_CONTENT);
	break;
    case STYLE_BOLD:
	pself->HTGHC_cntBold++;
	break;
    case STYLE_ITALIC:
	pself->HTGHC_cntItalic++;
	break;
    case STYLE_STRIKE:
	pself->HTGHC_cntStrike++;
	break;
    case STYLE_SUPERSCRIPT:
	pself->HTGHC_cntSuperscript++;
	break;
    case STYLE_SUBSCRIPT:
	pself->HTGHC_cntSubscript++;
	break;
    case STYLE_FW_FONT:
	pself->HTGHC_cntFWFont++;
	break;
  }
  return;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 225 "content_e.c"
StyleType _pascal HTGenHtmlContentGEN_HTML_CONTENT_REMOVE_CONTENT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, int * counter){pragma Off(warn); pself; oself; message; pragma On(warn); 
  StyleType type;

  *counter = 0;

  EC_ERROR_IF(pself->HTGHC_formatIndex == 0, UIG_ERROR_IN_CONTENT_STACK);
  pself->HTGHC_formatIndex--;
  type = pself->HTGHC_formatStack[pself->HTGHC_formatIndex];
  


  pself->HTGHC_formatStack[pself->HTGHC_formatIndex] = NULL;

  switch (type) {
    case STYLE_ANCHOR:
	*counter = --pself->HTGHC_cntUnderline;
	break;
    case STYLE_BOLD:
	*counter = --pself->HTGHC_cntBold;
	break;
    case STYLE_ITALIC:
	*counter = --pself->HTGHC_cntItalic;
	break;
    case STYLE_STRIKE:
	*counter = --pself->HTGHC_cntStrike;
	break;
    case STYLE_SUPERSCRIPT:
	*counter = --pself->HTGHC_cntSuperscript;
	break;
    case STYLE_SUBSCRIPT:
	*counter = --pself->HTGHC_cntSubscript;
	break;
    case STYLE_FW_FONT:
	*counter = --pself->HTGHC_cntFWFont;
	break;
  }
  EC_WARNING_IF(*counter < 0, UIG_UNBALANCED_COUNTER);
  return type;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 282 "content_e.c"
StyleType _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_CONTENT_TYPE(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  return pself->HTGHC_formatStack[pself->HTGHC_formatIndex-1];
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 303 "content_e.c"
int _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_STYLE_COUNT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, StyleType type){pragma Off(warn); pself; oself; message; pragma On(warn); 
  int count = 0;

  switch (type) {
    case STYLE_ANCHOR:
	count = pself->HTGHC_cntUnderline;
	break;
    case STYLE_BOLD:
	count = pself->HTGHC_cntBold;
	break;
    case STYLE_ITALIC:
	count = pself->HTGHC_cntItalic;
	break;
    case STYLE_STRIKE:
	count = pself->HTGHC_cntStrike;
	break;
    case STYLE_SUPERSCRIPT:
	count = pself->HTGHC_cntSuperscript;
	break;
    case STYLE_SUBSCRIPT:
	count = pself->HTGHC_cntSubscript;
	break;
    case STYLE_FW_FONT:
	count = pself->HTGHC_cntFWFont;
	break;
  }
  return count;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 349 "content_e.c"
byte _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_FONT_SIZE(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 

  if(pself->HTGHC_fontIndex == 0)
	return DEFAULT_STYLE_FONT;

  return pself->HTGHC_fontStack[(pself->HTGHC_fontIndex) - 1];
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 374 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_PUSH_FONT_SIZE(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, int size){pragma Off(warn); pself; oself; message; pragma On(warn); 
  pself->HTGHC_fontStack[pself->HTGHC_fontIndex] = size;
  pself->HTGHC_fontIndex++;
  EC_ERROR_IF(pself->HTGHC_fontIndex > 10, UIG_ERROR_IN_CONTENT_STACK);

  return;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 399 "content_e.c"
FontType _pascal HTGenHtmlContentGEN_HTML_CONTENT_POP_FONT_SIZE(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  FontType size;

  if(pself->HTGHC_fontIndex == 0) {	
	EC_WARNING(UIG_INVALID_OPERATION);
	return DEFAULT_STYLE_FONT;      
  }

  pself->HTGHC_fontIndex--;
  
  pself->HTGHC_fontStack[pself->HTGHC_fontIndex] = NULL;

  if(pself->HTGHC_fontIndex == 0)
	return DEFAULT_STYLE_FONT;	

  
  size = pself->HTGHC_fontStack[pself->HTGHC_fontIndex - 1];

  return size;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 437 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_PUSH_JUSTIFICATION(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, Justification align){pragma Off(warn); pself; oself; message; pragma On(warn); 
  pself->HTGHC_alignStack[pself->HTGHC_alignIndex] = align;
  pself->HTGHC_alignIndex++;
  EC_ERROR_IF(pself->HTGHC_alignIndex == 0, UIG_ERROR_IN_CONTENT_STACK);
  return;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 461 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_POP_JUSTIFICATION(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  if(pself->HTGHC_alignIndex == 0) {
	EC_WARNING(UIG_INVALID_OPERATION);
	return;
  }
  pself->HTGHC_alignIndex--;
  pself->HTGHC_alignStack[pself->HTGHC_alignIndex] = NULL;
  return;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 488 "content_e.c"
Justification _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_JUSTIFICATION(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  if(pself->HTGHC_alignIndex == 0)
	return DEFAULT_ALIGNMENT;

  return pself->HTGHC_alignStack[pself->HTGHC_alignIndex - 1];
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 512 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_PUSH_LIST_GROUP(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, StyleType groupType, int start, char displayType){pragma Off(warn); pself; oself; message; pragma On(warn); 
  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_groupType=groupType;
  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_counter=start;
  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_displayType=displayType;
  pself->HTGHC_listIndex++;
  EC_ERROR_IF(pself->HTGHC_listIndex > 10, UIG_ERROR_IN_CONTENT_STACK);
  return;
}	



















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 539 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_POP_LIST_GROUP(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  if(pself->HTGHC_listIndex == 0) {	
	EC_WARNING(UIG_INVALID_OPERATION);
	return;
  }
  


  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_groupType = NULL;

  pself->HTGHC_listIndex--;
  
  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_groupType = POPPED;
  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_counter = NULL;
  pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_displayType = NULL;

  return;
}	





















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 578 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_LIST_GROUP(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, StyleType * group, int * counter, char * type, int * level){pragma Off(warn); pself; oself; message; pragma On(warn); 
  if (pself->HTGHC_listIndex == 0) {
	*group = -1;
	*level = -1;
	return;
  }
  *group = pself->HTGHC_listStack[(pself->HTGHC_listIndex)-1].LG_groupType;
  *counter = pself->HTGHC_listStack[(pself->HTGHC_listIndex)-1].LG_counter;
  *type  = pself->HTGHC_listStack[(pself->HTGHC_listIndex)-1].LG_displayType;
  *level = pself->HTGHC_listIndex - 1;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 607 "content_e.c"
Boolean _pascal HTGenHtmlContentHTGHC_MSG_GEN_HTML_CONTENT_GET_ANY_LAST_LIST_GROUP(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  if (pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_groupType == POPPED){
	pself->HTGHC_listStack[pself->HTGHC_listIndex].LG_groupType = NULL;
	return TRUE;
  }
  else
	return FALSE;
}	


















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 633 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_UPDATE_COUNTER(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, int start){pragma Off(warn); pself; oself; message; pragma On(warn); 
  EC_WARNING_IF(pself->HTGHC_listIndex == 0, UIG_INVALID_OPERATION);
  EC_WARNING_IF(pself->HTGHC_listStack[pself->HTGHC_listIndex-1].\
	LG_groupType != STYLE_OL, UIG_INVALID_OPERATION);

  pself->HTGHC_listStack[pself->HTGHC_listIndex-1].LG_counter = start;
}	



















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 659 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_INCREMENT_COUNTER(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  EC_WARNING_IF(pself->HTGHC_listIndex == 0, UIG_INVALID_OPERATION);
  EC_WARNING_IF(pself->HTGHC_listStack[pself->HTGHC_listIndex-1].\
	LG_groupType != STYLE_OL, UIG_INVALID_OPERATION);

  pself->HTGHC_listStack[(pself->HTGHC_listIndex)-1].LG_counter++;
}	



















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 685 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_SET_TEXT_ALIGNMENT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, optr text){pragma Off(warn); pself; oself; message; pragma On(warn); 
  VisTextParaAttrAttributes new_attr = 0, old_attr = 0;
  Justification	new_just, old_just;
  


  if(pself->HTGHC_alignIndex == 0)
	new_just = DEFAULT_ALIGNMENT;
  else
	new_just = pself->HTGHC_alignStack[(pself->HTGHC_alignIndex)-1];
  
  if(pself->HTGHC_alignIndex <= 1)
	old_just = DEFAULT_ALIGNMENT;
  else
	old_just = pself->HTGHC_alignStack[(pself->HTGHC_alignIndex)-2];
  


  new_attr = new_just << VTPAA_JUSTIFICATION_OFFSET;
  old_attr = old_just << VTPAA_JUSTIFICATION_OFFSET;
  
((void(*)(VisTextParaAttrAttributes,VisTextParaAttrAttributes,dword,dword,word,optr,Message,word))&CObjMessage)(old_attr, new_attr, 
		TEXT_ADDRESS_PAST_END,
		TEXT_ADDRESS_PAST_END,  0x8000, text, (Message) 758, 0x0+((0+(sizeof(VisTextParaAttrAttributes)+1)/2+(sizeof(VisTextParaAttrAttributes)+1)/2+(sizeof(dword)+1)/2+(sizeof(dword)+1)/2)*2));
  return;
}	



















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 730 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_SET_HREF_TOKEN(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, int token){pragma Off(warn); pself; oself; message; pragma On(warn); 
  pself->HTGHC_hrefToken = token;
}	





















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 754 "content_e.c"
int _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_PREV_SIBLING_R_EDGE(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, optr obj, SizeAsDWord size, int * row){pragma Off(warn); pself; oself; message; pragma On(warn); 
  if (pself->HTGHC_currentObj != obj) {
    




    pself->HTGHC_accumulatedPrevWidth += pself->HTGHC_widthCurrentObj+MARGIN;
    if (!pself->HTGHC_maxHeightInRow)
      pself->HTGHC_maxHeightInRow = DWORD_HEIGHT(size);
    else if (pself->HTGHC_heightCurrentObj > pself->HTGHC_maxHeightInRow) {
      pself->HTGHC_maxHeightInRow = pself->HTGHC_heightCurrentObj;
    }
    pself->HTGHC_currentObj = obj;
  }
  pself->HTGHC_widthCurrentObj = DWORD_WIDTH(size);
  pself->HTGHC_heightCurrentObj= DWORD_HEIGHT(size);
  





  *row = pself->HTGHC_rowIndex + 1;
  return pself->HTGHC_accumulatedPrevWidth;
}	





















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 801 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_RESET_ROW_COUNTER(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  pself->HTGHC_rowIndex = -1;
  pself->HTGHC_currentObj = NULL;
  pself->HTGHC_maxHeightInRow = pself->HTGHC_heightCurrentObj = 
  pself->HTGHC_widthCurrentObj = 0;
  pself->HTGHC_sumOfHeights = MARGIN;    
  pself->HTGHC_accumulatedPrevWidth = 0; 
  pself->HTGHC_maxRowWidth = 0;
  if (pself->HTGHC_heightArray)
      HTListDeleteAllItems(pself->HTGHC_heightArray);
  else
      pself->HTGHC_heightArray = HTListNew();

  return;
}	





















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 837 "content_e.c"
int _pascal HTGenHtmlContentGEN_HTML_CONTENT_GET_ROW_HEIGHT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, int row){pragma Off(warn); pself; oself; message; pragma On(warn); 
  int height = 0;
  
  EC_ERROR_IF(row > pself->HTGHC_rowIndex, 1);
  HTListGetItem(pself->HTGHC_heightArray, row, &height, sizeof(int));
  return height;
}	























#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 867 "content_e.c"
int _pascal HTGenHtmlContentGEN_HTML_CONTENT_START_NEW_ROW(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message, SizeAsDWord size, int * row){pragma Off(warn); pself; oself; message; pragma On(warn); 
  int height = DWORD_HEIGHT(size);

  if (pself->HTGHC_maxHeightInRow == 0)  
    return 0;
  



  
  pself->HTGHC_sumOfHeights += (pself->HTGHC_maxHeightInRow + MARGIN);
  


  pself->HTGHC_rowIndex = HTListAppend
    (pself->HTGHC_heightArray, &(pself->HTGHC_sumOfHeights), sizeof(int));
  





  *row = pself->HTGHC_rowIndex + 1;
  


  if (pself->HTGHC_accumulatedPrevWidth > pself->HTGHC_maxRowWidth)
    pself->HTGHC_maxRowWidth = pself->HTGHC_accumulatedPrevWidth;
  



  pself->HTGHC_maxHeightInRow = height;    
  pself->HTGHC_accumulatedPrevWidth = MARGIN; 

  return pself->HTGHC_accumulatedPrevWidth;
}	




















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 924 "content_e.c"
int _pascal HTGenHtmlContentGEN_HTML_CONTENT_SUM_ROW_HEIGHTS(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  



  return   pself->HTGHC_sumOfHeights + pself->HTGHC_maxHeightInRow 
    + MARGIN;  
}	




















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 952 "content_e.c"
void _pascal HTGenHtmlContentGEN_HTML_CONTENT_UPDATE_MAX_HEIGHT(HTGenHtmlContentInstance *pself, optr oself, HTGenHtmlContentMessages message){pragma Off(warn); pself; oself; message; pragma On(warn); 
  



  if (pself->HTGHC_heightCurrentObj > pself->HTGHC_maxHeightInRow)
       pself->HTGHC_maxHeightInRow = pself->HTGHC_heightCurrentObj;
  return;
}	



















#ifdef __CURROOT
#undef __CURROOT
#endif
#define __CURROOT HTGenHtmlContent

# 980 "content_e.c"
void _pascal HTGenHtmlContentGEN_DESTROY(HTGenHtmlContentInstance *pself, optr oself, GenMessages message, VisUpdateMode updateMode, CompChildFlags flags){pragma Off(warn); pself; oself; message; pragma On(warn); 
  ((void(*)(VisUpdateMode,CompChildFlags,ClassStruct *,optr,Message,word))&CObjCallSuper)(updateMode, flags, &HTGenHtmlContentClass, oself, message, 0x23b);
  HTListDelete(pself->HTGHC_heightArray);
  return;
}	

extern char _HTGenHtmlContent_HackByte;
char _HTGenHtmlContent_HackByte;
ObjRelocation _HTGenHtmlContent_Reloc[]={{1, word_offsetof(HTGenHtmlContentInstance, HTGHC_currentObj)+2}, {0,0}};
ClassStruct HTGenHtmlContentClass = {(ClassStruct *)&GenInteractionClass, 6, 26, sizeof(HTGenHtmlContentInstance), 0, (word)(dword) &_HTGenHtmlContent_Reloc, 2, 8};
Message _Messages_HTGenHtmlContentClass[]={25006, 27160, 27159, 27158, 27157, 27156, 27155, 27154, 27153, 27152, 27151, 27150, 27149, 27148, 27147, 27146, 27145, 27144, 27143, 27142, 27141, 27140, 27139, 27138, 27137, 27136};
MessageMethod *_Methods_HTGenHtmlContentClass[]={(MessageMethod *)&HTGenHtmlContentGEN_DESTROY, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_UPDATE_MAX_HEIGHT, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_SUM_ROW_HEIGHTS, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_START_NEW_ROW, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_ROW_HEIGHT, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_RESET_ROW_COUNTER, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_PREV_SIBLING_R_EDGE, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_SET_HREF_TOKEN, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_SET_TEXT_ALIGNMENT, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_INCREMENT_COUNTER, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_UPDATE_COUNTER, (MessageMethod *)&HTGenHtmlContentHTGHC_MSG_GEN_HTML_CONTENT_GET_ANY_LAST_LIST_GROUP, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_LIST_GROUP, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_POP_LIST_GROUP, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_PUSH_LIST_GROUP, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_JUSTIFICATION, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_POP_JUSTIFICATION, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_PUSH_JUSTIFICATION, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_POP_FONT_SIZE, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_PUSH_FONT_SIZE, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_FONT_SIZE, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_STYLE_COUNT, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_GET_CONTENT_TYPE, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_REMOVE_CONTENT, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_SET_CONTENT, (MessageMethod *)&HTGenHtmlContentGEN_HTML_CONTENT_FORMAT_TEXT_OBJECT};
CMethodDef _htypes_HTGenHtmlContentClass[]={{0x23b, 0}, {0x200, 0}, {0xa200, 0}, {0xa100+((0+(sizeof(SizeAsDWord)+1)/2+(sizeof(int *)+1)/2)*2), 0}, {0xa100+((0+(sizeof(int)+1)/2)*2), 0}, {0x200, 0}, {0xa100+((0+(sizeof(optr)+1)/2+(sizeof(SizeAsDWord)+1)/2+(sizeof(int *)+1)/2)*2), 0}, {0x100+((0+(sizeof(int)+1)/2)*2), 0}, {0x100+((0+(sizeof(optr)+1)/2)*2), 0}, {0x200, 0}, {0x100+((0+(sizeof(int)+1)/2)*2), 0}, {0xa200, 0}, {0x100+((0+(sizeof(StyleType *)+1)/2+(sizeof(int *)+1)/2+(sizeof(char *)+1)/2+(sizeof(int *)+1)/2)*2), 0}, {0x200, 0}, {0x100+((0+(sizeof(StyleType)+1)/2+(sizeof(int)+1)/2+(sizeof(char)+1)/2)*2), 0}, {0xa200, 0}, {0x200, 0}, {0x100+((0+(sizeof(Justification)+1)/2)*2), 0}, {0xa200, 0}, {0x100+((0+(sizeof(int)+1)/2)*2), 0}, {0xa200, 0}, {0xa100+((0+(sizeof(StyleType)+1)/2)*2), 0}, {0xa200, 0}, {0xa100+((0+(sizeof(int *)+1)/2)*2), 0}, {0x100+((0+(sizeof(StyleType)+1)/2)*2), 0}, {0x100+((0+(sizeof(optr)+1)/2+(sizeof(GStateHandle)+1)/2)*2), 0}};
pragma Off(Warn);
pragma Code("_BOGUS_PROTOMINORRELOCS");
void
content_ProtoMinorRoutine()
{
}
pragma Code();