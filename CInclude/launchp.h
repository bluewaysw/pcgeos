/* for Launch pad lights: */
#define MANUFACTURER_ID_BREADBOX                 16431
#define BREADBOX_LAUNCH_PAD_TRANSFER_STATE       0
typedef struct {
    Boolean BLPTSI_isConnected ;
    dword BLPTSI_dataIn ;
    dword BLPTSI_dataOut ;
} BreadboxLaunchPadTransferState ;
