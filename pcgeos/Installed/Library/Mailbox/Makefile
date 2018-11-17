#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Mailbox
ADMIN           = adminC.asm adminCode.asm adminInit.asm adminManager.asm\
                  adminConstant.def adminVariable.def
DBQ             = dbqCode.asm dbqEC.asm dbqManager.asm dbqConstant.def
DMAP            = dmapCode.asm dmapManager.asm dmapConstant.def
INBOX           = inboxApplicationList.asm inboxAppToken.asm\
                  inboxControlPanel.asm inboxDetails.asm inboxFetch.asm\
                  inboxInit.asm inboxManager.asm inboxMessageList.asm\
                  inboxRegister.asm inboxTransWin.asm inboxUtils.asm\
                  inboxConstant.def inboxVariable.def
MAIN            = mainLibrary.asm mainManager.asm mainNotify.asm\
                  mainProcess.asm mainThread.asm mainVariable.def
MEDIA           = mediaC.asm mediaInit.asm mediaManager.asm mediaStatus.asm\
                  mediaTransport.asm mediaConstant.def
MESSAGE         = messageC.asm messageControlPanel.asm messageDetails.asm\
                  messageGlyph.asm messageInfo.asm messageList.asm\
                  messageManager.asm messageMoniker.asm messageRegister.asm\
                  messageSendableNotifyDialog.asm messageUtils.asm\
                  messageConstant.def messageVariable.def
OUTBOX          = outboxC.asm outboxConfirmation.asm\
                  outboxControlMessageList.asm outboxControlPanel.asm\
                  outboxDetails.asm outboxErrorRetry.asm\
                  outboxFeedbackGlyph.asm outboxFeedbackNote.asm\
                  outboxInit.asm outboxManager.asm outboxMedia.asm\
                  outboxMessageList.asm outboxNotify.asm outboxPoofMenu.asm\
                  outboxProgress.asm outboxReason.asm outboxRegister.asm\
                  outboxSendableConfirmation.asm outboxThread.asm\
                  outboxTransmit.asm outboxTransmitQ.asm\
                  outboxTransportList.asm outboxTransportMenu.asm\
                  outboxTransportMonikerSource.asm outboxTransWin.asm\
                  outboxUtils.asm outboxConstant.def outboxVariable.def
UI              = uiAddressControl.asm uiApplication.asm uiC.asm uiEMOM.asm\
                  uiManager.asm uiOutboxControl.asm uiPoofDialog.asm\
                  uiProgressBox.asm uiProgressGauge.asm uiSendControl.asm\
                  uiSendDialog.asm uiSpoolAddress.asm uiStrings.asm\
                  uiConstant.def uiMacro.def uiVariable.def uiInPanel.ui\
                  uiInTransWin.ui uiMain.ui uiOutboxControl.ui\
                  uiOutboxFeedback.ui uiOutCancel.ui uiOutConfirm.ui\
                  uiOutConfirmSendable.ui uiOutErrorRetry.ui\
                  uiOutLostConnection.ui uiOutPanel.ui uiOutProgress.ui\
                  uiOutTransWin.ui uiPoof.ui uiSendControl.ui\
                  uiUnsendable.ui
UTILS           = utilsC.asm utilsCode.asm utilsEC.asm utilsGlobal.asm\
                  utilsManager.asm utilsResident.asm
VMSTORE         = vmstoreC.asm vmstoreCode.asm vmstoreInit.asm\
                  vmstoreManager.asm vmstoreConstant.def
UI_TO_RDFS      = UIMAIN.UI
OBJS            =
COMMON          = mailboxAdmin.def mailboxConstant.def mailboxDBQ.def\
                  mailboxDMap.def mailboxGeode.def mailboxInbox.def\
                  mailboxInbox.uih mailboxMacro.def mailboxMain.def\
                  mailboxMedia.def mailboxMessage.def mailboxMessage.uih\
                  mailboxOutbox.def mailboxOutbox.uih mailboxUI.def\
                  mailboxUI.uih mailboxUtils.def mailboxVMStore.def
MODULES         = Admin DBQ DMap Inbox Main Media Message Outbox UI Utils\
                  VMStore
CMODULES        =
SRCS            = $(ADMIN) $(DBQ) $(DMAP) $(INBOX) $(MAIN) $(MEDIA)\
                  $(MESSAGE) $(OUTBOX) $(UI) $(UTILS) $(VMSTORE) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = mailbox

SYSMAKEFILE     = geode.mk

#include <geos.mk>
#include <gpath.mk>

#if exists(local.mk)
#include "local.mk"
#else
#include <$(SYSMAKEFILE)>
#endif

#if exists($(DEPFILE))
#include "$(DEPFILE)"
#endif
