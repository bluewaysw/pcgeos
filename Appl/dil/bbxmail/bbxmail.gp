# Parameters file for: mail.geo
#
#	$Id$
#
##############################################################################
#
# Permanent name
#
name bbxmail.app
#
# Specify geode type
#
type	process, appl, single
#
# Specify class name and application object for process
#
class	MailProcessClass
appobj	MailAppObj

stack 3000

heapspace	100k

#
# Import library routine definitions
#
library	geos
library ui
library ansic
library spell
library text
library bbxmlib
library config
library spool
library parentc

#
# Desktop-related definitions
#
longname "Email"
tokenchars "bbxm"
tokenid 0
#
# Special resource definitions
#
resource STRINGS   lmem shared read-only
resource CBITMAPS  lmem shared read-only
resource AppUI     ui-object
resource PrimaryUI ui-object
resource ToolUI    ui-object
resource FldrMenuUI ui-object
resource MsgMenuUI ui-object
resource OptionsUI ui-object
resource ComposeUI ui-object
resource ReadUI    ui-object
resource PrefUI	   ui-object
resource FListUI   ui-object
resource MListUI   ui-object
resource PrintUI   ui-object
resource AttachUI  ui-object
#resource ImportUI  ui-object
resource ProcObjs  object
resource TabItemTemplateResource ui-object

resource APPSCMONIKERRESOURCE	lmem shared read-only
resource APPTCMONIKERRESOURCE	lmem shared read-only
resource APPMONIKERRESOURCE1    lmem shared read-only
resource APPMONIKERRESOURCE2    lmem shared read-only
resource APPMONIKERRESOURCE3    lmem shared read-only
resource APPMONIKERRESOURCE4    lmem shared read-only
resource APPFOLDERICONS         lmem shared read-only
resource PointerData            lmem shared read-only


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
export MailContentClass
export MailWarningClass
export MailFieldTextClass
export MailComposeTextClass
export MailSearcherClass
export AccountDialogClass
export MailListHeaderClass
export FolderRecoverClass
