#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = mailbox
OUTBOX          = outboxTransmitQ.asm outboxFeedbackNote.asm\
                  outboxTransportList.asm outboxMedia.asm\
                  outboxMessageList.asm outboxSendableConfirmation.asm\
                  outboxTransportMenu.asm outboxErrorRetry.asm\
                  outboxConfirmation.asm outboxPoofMenu.asm\
                  outboxTransportMonikerSource.asm outboxTransmit.asm\
                  outboxControlMessageList.asm outboxC.asm\
                  outboxFeedbackGlyph.asm outboxControlPanel.asm\
                  outboxRegister.asm outboxNotify.asm outboxUtils.asm\
                  outboxThread.asm outboxManager.asm outboxInit.asm\
                  outboxDetails.asm outboxTransWin.asm outboxProgress.asm\
                  outboxReason.asm outboxVariable.def outboxConstant.def
UTILS           = utilsCode.asm utilsGlobal.asm utilsEC.asm\
                  utilsManager.asm utilsResident.asm utilsC.asm
MAIN            = mainManager.asm mainNotify.asm mainProcess.asm\
                  mainLibrary.asm mainThread.asm mainVariable.def
ADMIN           = adminCode.asm adminInit.asm adminManager.asm adminC.asm\
                  adminVariable.def adminConstant.def
INBOX           = inboxFetch.asm inboxInit.asm inboxApplicationList.asm\
                  inboxManager.asm inboxControlPanel.asm inboxDetails.asm\
                  inboxMessageList.asm inboxTransWin.asm inboxUtils.asm\
                  inboxAppToken.asm inboxRegister.asm inboxVariable.def\
                  inboxConstant.def
DBQ             = dbqManager.asm dbqEC.asm dbqCode.asm dbqConstant.def
VMSTORE         = vmstoreInit.asm vmstoreC.asm vmstoreCode.asm\
                  vmstoreManager.asm vmstoreConstant.def
UI              = uiPoofDialog.asm uiApplication.asm uiProgressBox.asm\
                  uiC.asm uiAddressControl.asm uiProgressGauge.asm\
                  uiEMOM.asm uiSendControl.asm uiOutboxControl.asm\
                  uiSendDialog.asm uiStrings.asm uiSpoolAddress.asm\
                  uiManager.asm uiVariable.def uiConstant.def uiMacro.def\
                  uiOutCancel.ui uiOutProgress.ui uiOutTransWin.ui\
                  uiOutboxControl.ui uiUnsendable.ui uiSendControl.ui\
                  uiOutPanel.ui uiOutConfirm.ui uiPoof.ui uiInTransWin.ui\
                  uiOutLostConnection.ui uiOutConfirmSendable.ui uiMain.ui\
                  uiInPanel.ui uiOutboxFeedback.ui uiOutErrorRetry.ui
DMAP            = dmapManager.asm dmapCode.asm dmapConstant.def
MEDIA           = mediaStatus.asm mediaC.asm mediaInit.asm\
                  mediaTransport.asm mediaManager.asm mediaConstant.def
MESSAGE         = messageRegister.asm messageDetails.asm messageList.asm\
                  messageManager.asm messageGlyph.asm\
                  messageSendableNotifyDialog.asm messageMoniker.asm\
                  messageControlPanel.asm messageC.asm messageUtils.asm\
                  messageInfo.asm messageConstant.def messageVariable.def
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = mailboxConstant.def mailboxDMap.def mailboxDBQ.def\
                  mailboxMain.def mailboxInbox.def mailboxMedia.def\
                  mailboxOutbox.def mailboxUI.uih mailboxUI.def\
                  mailboxMacro.def mailboxMessage.def mailboxInbox.uih\
                  mailboxUtils.def mailboxAdmin.def mailboxGeode.def\
                  mailboxVMStore.def mailboxOutbox.uih mailboxMessage.uih
MODULES         = Outbox Utils Main Admin Inbox DBQ VMStore UI DMap Media\
                  Message
CMODULES        =
SRCS            = $(OUTBOX) $(UTILS) $(MAIN) $(ADMIN) $(INBOX) $(DBQ)\
                  $(VMSTORE) $(UI) $(DMAP) $(MEDIA) $(MESSAGE) $(COMMON)
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
