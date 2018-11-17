# Parameters file for: mail.geo
#
#	$Id$
#
##############################################################################
#
# Permanent name
#
name email.app
#
# Specify geode type
#
type	process, appl, single
#
# Specify class name and application object for process
#
class	MailProcessClass
appobj	MailAppObj

stack 3072

heapspace	100k

#
# Import library routine definitions
#
library	geos
library ui
library ansic
library spell
library text
library mailhub
library mailsmtp
library mailpop3
library config
library spool
ifdef PRODUCT_NDO2000
else
library parentc
library impex
library idialc
endif
#
# Desktop-related definitions
#
ifdef PRODUCT_NDO2000
longname "NewMail"
else
longname "Global Email"
endif
tokenchars "mail"
tokenid 0
#
# Special resource definitions
#
resource STRINGS   lmem shared read-only
resource CBITMAPS  lmem shared read-only
resource APPUI     ui-object
resource PRIMARYUI ui-object
resource TOOLUI    ui-object
resource FLDRMENUUI ui-object
resource MSGMENUUI ui-object
resource OPTIONSUI ui-object
resource COMPOSEUI ui-object
resource READUI    ui-object
resource PREFUI	   ui-object
resource FLISTUI   ui-object
resource MLISTUI   ui-object
resource PRINTUI   ui-object
resource ATTACHUI  ui-object
resource CUIOBJS   ui-object
resource USERLEVELUI ui-object
ifdef PRODUCT_NDO2000
resource IMPORTUI  ui-object
endif
resource PROCOBJS  object

resource APPSCMONIKERRESOURCE	lmem shared read-only
resource APPTCMONIKERRESOURCE	lmem shared read-only
resource APPMONIKERRESOURCE1    lmem shared read-only
resource APPMONIKERRESOURCE2    lmem shared read-only
resource APPMONIKERRESOURCE3    lmem shared read-only
resource APPMONIKERRESOURCE4    lmem shared read-only
resource APPFOLDERICONS         lmem shared read-only
resource CUIFOLDERICONS         lmem shared read-only
resource CUIMAINICONS           lmem shared read-only
resource CUIICONS2              lmem shared read-only
resource POINTERDATA            lmem shared read-only
resource CUISTRINGS             lmem shared read-only
resource LSTRINGS               lmem shared read-only


#
# Define exported entry points (for unrelocating)
#
export MailAppClass
export FolderListClass
export FolderRenameDialogClass
export MailComposerClass
export MailReaderClass
export MailReadTextClass
export MailListClass
export AccountListClass
export ShowToolbarClass
export AttachListClass
export MailSendReceiveClass
export AddressDialogClass
export AddressListClass
export MailPrimary2Class
export MailSearchClass
export MailLargeTextClass
export PasswordTextClass
export FolderMoveClass
export EnableTextClass
#export AdvertisementClass
export MailContentClass
export MailWarningClass
export MailFieldTextClass
export MailComposeTextClass
export MailImporterClass
export MailImportSelectorClass
export MailSearcherClass
export AccountDialogClass
export MailListHeaderClass
export ConditionalNoticeClass
export BlackBorderClass
export FolderRecoverClass
