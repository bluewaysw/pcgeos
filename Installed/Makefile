#
# there is a circular dependency between pcmcia and ui, so you need to have
# an old ui.ldf to start with.
#
#if defined(win32)
#else
MK_SET =
MK_MAKE = mkdir -p $PARAM ; \
		cd $PARAM ; \
		$(MAKE) -k -I$PARAM


#endif

minimal		: minimalLoader minimalLibrary minimalDriver minimalAppl \
		  otherEnsemble

minimalLoader	: textLoader VGALoader

#
# Libraries
#
minimalLibrary	: kernel swap sound net ui isui motif spool text mailbox \
		  genpc ansic cell chart color compress config hash impex \
		  borlandc math pen resolver spline ssmeta styles \
		  wav game cards spreadsheet parse spell convert \
		  saver prefLibs accpnt netutils \
		  socket dhcp borlandrtl ffile streamc mailhub mailsmtp \
		  mailpop3 rtf ascii lot123ss csv \
		  parentc wmlib \
		  jpeg giflib gif htmlimpx n2txt inetmsg extui \
		  winword8 zlib dirlist minizip idialc eps impex_libs \
		  thumbdb ftplib flllib sitelist int8087 intx87\
		  basicdb gridlib gsol treplib
# cdaudio

prefLibs	: prefvid preftd \
		  prefsnd prefos prefmous preflo preflf prefkbd \
		  prefintl prefcomp prefbg prefpntc preffont configui

# prefs not used preflvl prefuic prefui prefts prefspui prefsock preflink preflang

# Geos impex libraries
impex_libs: dib bmp clp ico pcx tif \
	    msmfile msword \
	    wordperf5 \
	    dbase3 dbase4 htmlpars htmlimpx
#lot123


# Extra Pref libs - don't bother making these
#
extraPrefLibs	: prefpag prefjfep

#
# Applications
#
minimalAppl	: minimalGame minimalUtils minimalTools minimalSavers \
		  minimalEdu calendar geodex geocalc geodraw geowrite \
		  scrapbk clock bigcalc \
		  email manager isdesk linktool setup \
		  launcher webmagick idialup \
		  charm wordmat banner \
		  bbxchat bnkr30 hmbase\
		  newsread geozip ftpc sclock bbxmail pdfvu

minimalUtils	: prefmgr

minimalGame	: solitaire cword amateur bjack hearts gwpoker \
                  pyramid sokoban taipei uki mine column

minimalEdu	: flash fontmgck hangman laserl mflash numbers pvault \
                  taide thinker ttype wsm wsplay xwm

minimalSavers	: lol blackhole blank bobbin circles dribble dust \
		  fades flame hopalong lastwords letter logo maze \
		  melt noodle palette pieces pith qix rotate sand \
		  spotlight stars string swarm tickertape tiles worms

minimalTools	: prntscrn

otherEnsemble	: conview reader term tedit geofile dirls bim ffind  \
		  webbox graphvwr macror dump perf
# bbxcd
#geocon3

#
# Drivers
#

#minimalDriver	: ms3 ms4 ntfat dri netware rfsd ega vga hgc svga \
#		  keyboard dvorak stream serial parallel \
#		  nimbus vidmem logibus logiser msbus msser \
#		  disk xms emm nonts epson9 epson24 sound_std

minimalDriver	: nimbus ms4 ntfat os2 cdrom stream dri gdi keyboard modem gdipointer \
		  standard winnt parallel serial disk vidmem svga \
		  vga vga8 vga16 ega cga mcga hgc att6300 dscga printerDriver \
		  ps2 msys msser msbus kbmouse absgen genmouse emm extmem \
		  xms filestr nonts sblaster comm spooltd \
		  vmtree filedd logibus logiser dma mslf kbd_drivers \
		  etherodi msnet
# cdados
printerDriver	: deskjet dj500c lbp mercury pcl4 quietjet canon48 \
		  canonbjc canonrgb epshi24 epson24 epson48 nec24 \
		  ppds24 tosh24 pscript dumb diablo citoh9 prop9 \
 	  	  diconix9 eplx9 epmx9 eprx9 bchip9 star9 \
   	  	  oki9 grpr9 epson9 propx24

#escp2 remove from above since it doesn't compile

#faxDriver	: class1in class1out class2in class2out

textLoader	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Loader/Text ; \
	$(MK_MAKE) full

VGALoader	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Loader/VGA ; \
	$(MK_MAKE) full

kernel	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Kernel ; \
	$(MK_MAKE) full lib

swap	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Swap ; \
	$(MK_MAKE) full lib

sound	: stream
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Sound ; \
	$(MK_MAKE) full lib

# Cannot state true dependency for PCMCIA & Net (they both rely
# upon the UI library), as we would have a circular dependency.

#pcmcia	:
#	mdcd %ROOT_DIR%\Installed\Library\PCMCIA
#	$(MAKE) -k -I$(ROOT_DIR)\Library\PCMCIA lib full

net	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Net ; \
	$(MK_MAKE) full lib

# removed pcmcia
ui	: sound compress net wav
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/User ; \
	$(MK_MAKE) full lib

isui	: text
	mdcd %ROOT_DIR%\Installed\Library\SpecUI\isui
	$(MAKE)  -k -I$(ROOT_DIR)\Library\SpecUI\isui lib full

motif	: text
	mdcd %ROOT_DIR%\Installed\Library\SpecUI\Motif
	$(MAKE) -k -I$(ROOT_DIR)\Library\SpecUI\Motif lib full

spool	: text
	mdcd %ROOT_DIR%\Installed\Library\Spool
	$(MAKE) -k  -I$(ROOT_DIR)\Library\Spool lib full

text	: ui styles color ruler bitmap
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Text ; \
	$(MK_MAKE) full lib

styles	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Styles ; \
	$(MK_MAKE) full lib

color	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Color ; \
	$(MK_MAKE) full lib

mailbox	: ui spool
	mdcd %ROOT_DIR%\Installed\Library\Mailbox
	$(MAKE)  -k -I$(ROOT_DIR)\Library\Mailbox lib full

compress	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Compress ; \
	$(MK_MAKE) full lib

ruler	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Ruler ; \
	$(MK_MAKE) full lib

bitmap	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Bitmap ; \
	$(MK_MAKE) full lib

pen	: ui text
	mdcd %ROOT_DIR%\Installed\Library\Pen
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pen lib full

genpc	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/GDI/GenPC ; \
	$(MK_MAKE) full lib

shell	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Shell ; \
	$(MK_MAKE) full lib

ansic	: math borlandc
	mdcd %ROOT_DIR%\Installed\Library\AnsiC
	$(MAKE) -k -I$(ROOT_DIR)\Library\AnsiC lib full

cell	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Cell ; \
	$(MK_MAKE) full lib

chart	: ui grobj spline text
	mdcd %ROOT_DIR%\Installed\Library\Chart
	$(MAKE) -k -I$(ROOT_DIR)\Library\Chart lib full

config	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Config ; \
	$(MK_MAKE) full lib

grobj	: ui text bitmap ruler spline color styles impex
	mdcd %ROOT_DIR%\Installed\Library\GrObj
	$(MAKE) -k -I$(ROOT_DIR)\Library\GrObj lib full

hash	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Hash ; \
	$(MK_MAKE) full lib

impex	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Impex ; \
	$(MK_MAKE) full lib

# Don't compile import yet because the unix files haven't
# converted to dos files.
# import	:
#	mdcd %ROOT_DIR%\Installed\Library\Import
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Import lib full

lot123ss	: ui ansic impex math ssmeta
	mdcd %ROOT_DIR%\Installed\Library\Trans\SSheet\Lotus123
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\SSheet\Lotus123 lib full

csv	: ui impex ssmeta
	mdcd %ROOT_DIR%\Installed\Library\Trans\Database\CSV
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Database\CSV lib full

rtf	: ui impex text ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Impex\RTF
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Impex\RTF lib full

jpeg	: ui impex ansic ijgjpeg math
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Impex\JPEG
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Impex\JPEG lib full

gif : ui impex ansic extgraph giflib
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Impex\GIF
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Impex\GIF lib full

wmf : ui impex ansic
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Vector\Wmf
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Vector\Wmf lib full

ascii	: ui text
	mdcd %ROOT_DIR%\Installed\Library\Trans\Text\Ascii
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Text\Ascii lib full

msword	: ui ansic impex msmfile
	mdcd %ROOT_DIR%\Installed\Library\Trans\Text\MicrosoftWord
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Text\MicrosoftWord lib full

htmlpars : ansic text
	mdcd %ROOT_DIR%\Installed\Library\BreadBox\HtmlPars
	$(MAKE) -k -I$(ROOT_DIR)\Library\BreadBox\HtmlPars lib full

htmlimpx : htmlpars ansic text impex ui
	mdcd %ROOT_DIR%\Installed\Library\Trans\Web\HtmlImpx
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Web\HtmlImpx lib full

sstor	: ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\SStor
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\SStor lib full

wfwlib	: text ansic sstor
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Impex\WFWLib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Impex\WFWLib lib full

winword8 : impex ansic text sstor wfwlib
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Impex\WinWord8
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Impex\WinWord8 lib full

borlandrtl	:
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Library/BorlandRTL/...

borlandc	: math
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Math/Compiler/BorlandC ; \
	$(MK_MAKE) full lib -k

math	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Math ; \
	$(MK_MAKE) full lib

resolver	: netutils ui socket accpnt
	mdcd %ROOT_DIR%\Installed\Library\Resolver
	$(MAKE) -k -I$(ROOT_DIR)\Library\Resolver lib full

spline	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Spline ; \
	$(MK_MAKE) full lib

ssmeta	: ui math
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/SSMeta ; \
	$(MK_MAKE) full lib -k

# bsnwav will only be compiled (and is only referenced in WAV) if PRODUCT==NDO2000
wav	: sound bsnwav
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Wav ; \
	$(MK_MAKE) full lib

game	: ui wav
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Game ; \
	$(MK_MAKE) full lib

cards	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Cards ; \
	$(MK_MAKE) full lib

parse	: cell math ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Parse ; \
	$(MK_MAKE) full lib -k

spreadsheet	: ui ruler cell math parse chart text color ssmeta
	mdcd %ROOT_DIR%\Installed\Library\Spreadsheet
	$(MAKE) -k -I$(ROOT_DIR)\Library\Spreadsheet lib full

spell	: ansic ui text
	mdcd %ROOT_DIR%\Installed\Library\Spell
	$(MAKE) -k -I$(ROOT_DIR)\Library\Spell lib full
#EC version link arguments is too long, so link manually
#	pmake -u > args1
#	perl fixArgs.pl args1
#	glue @args1
#	del args1

convert	: ui grobj
	mdcd %ROOT_DIR%\Installed\Library\Convert
	$(MAKE) -k -I$(ROOT_DIR)\Library\Convert lib full

saver	: ui grobj net
	mdcd %ROOT_DIR%\Installed\Library\Saver
	$(MAKE) -k -I$(ROOT_DIR)\Library\Saver lib full

#faxfile	: ui text
#	mdcd %ROOT_DIR%\Installed\Library\Fax\File
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Fax\File lib full

#faxctrl	: ui text faxfile mailbox
#	mdcd %ROOT_DIR%\Installed\Library\Fax\Ctrl
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Fax\Ctrl lib full

accpnt	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/AccPnt ; \
	$(MK_MAKE) full lib

netutils	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/NetUtils ; \
	$(MK_MAKE) full lib

eps	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Trans/Graphics/Vector/EPS ; \
	$(MK_MAKE) full lib

ps2pdf	: ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\ps2pdf
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\ps22pdf lib full

socket	: ui netutils
	mdcd %ROOT_DIR%\Installed\Library\Socket
	$(MAKE) -k -I$(ROOT_DIR)\Library\Socket lib full

dhcp	: socket ui accpnt
	mdcd %ROOT_DIR%\Installed\Library\dhcp
	$(MAKE) -k -I$(ROOT_DIR)\Library\dhcp lib full

ffile	: cell ui spreadsheet parse ansic math text grobj spool ssmeta
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Library/FlatFile/...
#	build it anyway, because p4 sync does not work if not connected
#	while making the build (I know, all these warnings are annoying, and some
#	are definitely the cause of instabilities, but no reason to hide this :)
	mdcd %ROOT_DIR%\Installed\Library\FlatFile
	$(MAKE) -k -I$(ROOT_DIR)\Library\FlatFile lib full

streamc : ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/StreamC ; \
	$(MK_MAKE) full lib

mailhub : socket ansic
	mdcd %ROOT_DIR%\Installed\Library\Mail\MailHub
	$(MAKE) -k -I$(ROOT_DIR)\Library\Mail\MailHub lib full

bbxmlib	: socket ansic
	mdcd %ROOT_DIR%\Installed\Library\dil\bbxmail
	$(MAKE) -k -I$(ROOT_DIR)\Library\dil\bbxmail lib full

mailsmtp : socket ansic mailhub
	mdcd %ROOT_DIR%\Installed\Library\Mail\MailSMTP
	$(MAKE) -k -I$(ROOT_DIR)\Library\Mail\MailSMTP lib full

mailpop3 : socket ansic mailhub
	mdcd %ROOT_DIR%\Installed\Library\Mail\MailPOP3
	$(MAKE) -k -I$(ROOT_DIR)\Library\Mail\MailPOP3 lib full

#bckrst : ui ansic
#	mdcd %ROOT_DIR%\Installed\Library\BckRst
#	$(MAKE) -k -I$(ROOT_DIR)\Library\BckRst lib full

filestr	: stream
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Stream/Filestr ; \
	$(MK_MAKE) full lib

nonts	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Task/NonTS ; \
	$(MK_MAKE) full lib

sblaster	: stream
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Sound/SoundBlaster ; \
	$(MK_MAKE) full lib

comm	: net
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Net/Comm ; \
	$(MK_MAKE) full lib

spooltd	: ui mailbox spool
	mdcd %ROOT_DIR%\Installed\Driver\Mailbox\Transport\SpoolTD
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Mailbox\Transport\SpoolTD full

vmtree	: mailbox
	mdcd %ROOT_DIR%\Installed\Driver\Mailbox\Data\VMTree
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Mailbox\Data\VMTree full

filedd	: mailbox serial
	mdcd %ROOT_DIR%\Installed\Driver\Mailbox\Data\FileDD
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Mailbox\Data\FileDD full

parentc : ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/ParentC ; \
	$(MK_MAKE) full lib

wmlib	: ansic compress
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\WMLib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\WMLib lib full

n2txt	: ui ansic text math
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\N2Txt
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\N2Txt lib full

inetmsg : ui ansic extui
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\INetMsg
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\INetMsg lib full

extui   : ui ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\ExtUI
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\ExtUI lib full

sitelist	: ui ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\sitelist
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\sitelist lib full

flllib	: ui ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\flllib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\flllib lib full

ftplib	: ui ansic socket
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\ftplib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\ftplib lib full

idialc	: ui socket
	mdcd %ROOT_DIR%\Installed\Library\IDialC
	$(MAKE) -k -I$(ROOT_DIR)\Library\IDialC lib full

thumbdb : ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Thumbdb
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Thumbdb lib full

# the EduApp libs
basicdb : ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Basicdb
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Basicdb lib full

gridlib : ui ansic text
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Gridlib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Gridlib lib full

treplib : ui ansic text spool
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Treplib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Treplib lib full

gsol	: ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Gsol
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Gsol lib full

# Preference libraries

configui	: ui config ansic
	mdcd %ROOT_DIR%\Installed\Library\Pref\ConfigUI
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\ConfigUI configui.rdef
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\ConfigUI lib full

prefbg	: ui config color convert
	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefbg
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefbg lib full

prefcomp	: ui config serial parallel
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefcomp ; \
	$(MK_MAKE) full lib

preffont	: ui config ansic
	mdcd %ROOT_DIR%\Installed\Library\Pref\Preffont
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Preffont lib full

prefintl	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefintl ; \
	$(MK_MAKE) full lib

prefkbd	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefkbd ; \
	$(MK_MAKE) full lib

#preflang	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Preflang
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Preflang lib full

preflf	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Preflf ; \
	$(MK_MAKE) full lib

#preflink	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Preflink
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Preflink lib full

preflo	: ui config saver net
	mdcd %ROOT_DIR%\Installed\Library\Pref\Preflo
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Preflo lib full

#preflvl	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Preflvl
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Preflvl lib full

prefmous	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefmous ; \
	$(MK_MAKE) full lib

prefos	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefos ; \
	$(MK_MAKE) full lib

#prefpag	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefpag
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefpag lib full

prefsnd	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefsnd ; \
	$(MK_MAKE) full lib

#prefsock	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefsock
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefsock lib full

#prefspui	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefspui
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefspui lib full

preftd	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Preftd ; \
	$(MK_MAKE) full lib

#prefts	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefts
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefts lib full

#prefui	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefui
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefui lib full

#prefuic	: ui config
#	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefuic
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefuic lib full

prefvid	: ui config
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Pref/Prefvid ; \
	$(MK_MAKE) full lib

prefpntc	: ui config parentc
	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefpntc
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefpntc lib full



#driver

stream	: kernel
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Stream ; \
	$(MK_MAKE) full lib

nimbus	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Font/Nimbus ; \
	$(MK_MAKE) full lib

ms4	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/MS4 ; \
	$(MK_MAKE) full lib

os2	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/OS2 ; \
	$(MK_MAKE) full lib

ntfat	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/NTFat ; \
	$(MK_MAKE) full lib

dri	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/DRI ; \
	$(MK_MAKE) full lib

mslf	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/MSLF ; \
	$(MK_MAKE) full lib

cdrom     :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/CDROM ; \
	$(MK_MAKE) full lib

gdi	: genpc
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/GDI ; \
	$(MK_MAKE) full lib

msnet     :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/IFS/DOS/MSNet ; \
	$(MK_MAKE) full lib

keyboard	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard ; \
	$(MK_MAKE) full lib

modem	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Modem ; \
	$(MK_MAKE) full lib

gdipointer	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/GDIPointer ; \
	$(MK_MAKE) full lib

standard	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Sound/Standard ; \
	$(MK_MAKE) full lib

winnt	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Sound/WinNT ; \
	$(MK_MAKE) full lib

parallel	: stream
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Stream/Parallel ; \
	$(MK_MAKE) full lib

serial	: stream
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Stream/Serial ; \
	$(MK_MAKE) full lib

disk	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Swap/Disk ; \
	$(MK_MAKE) full lib

emm	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Swap/EMS/EMM ; \
	$(MK_MAKE) full lib

extmem	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Swap/ExtMem ; \
	$(MK_MAKE) full lib

xms	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Swap/XMS ; \
	$(MK_MAKE) full lib

att6300	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/Dumb/ATT6300 ; \
	$(MK_MAKE) full lib

vidmem	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/Dumb/VidMem ; \
	$(MK_MAKE) full lib

svga	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/VGAlike/SVGA ; \
	$(MK_MAKE) full lib

vga	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/VGAlike/VGA ; \
	$(MK_MAKE) full lib

vga8	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/VGAlike/VGA8 ; \
	$(MK_MAKE) full lib

vga16	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/VGAlike/VGA16 ; \
	$(MK_MAKE) full lib

etherodi	: socket accpnt
	mdcd %ROOT_DIR%\Installed\Driver\Socket\EtherODI
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Socket\EtherODI lib full

# International Keyboard Drivers
kbd_drivers : kbdb_cf kbde_cf kbd_csa kbde_df kbdn_df kbde_be kbd_dvrk  \
	kbde_fr kbdn_fr kps1_fr kbde_sf kbde_gr kbdn_gr kbde_sg        	\
	kbdn_sg kbde_it kbdn_it kbde_no kbdn_no kbde_po kbde_sp kbdn_sp	\
	kbde_sv kbdn_sv kbdt_sv kbde_uk lbdn_uk t1000

kbd_dvrk	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Dvorak ; \
	$(MK_MAKE) full lib

kbdb_cf	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Canadian/Bilingual ; \
	$(MK_MAKE) full lib
kbde_cf	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Canadian/FrenchExtended ; \
	$(MK_MAKE) full lib

kbd_csa	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Canadian/CSA-z243.200-91 ; \
	$(MK_MAKE) full lib

kbde_df	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Danish/Extended ; \
	$(MK_MAKE) full lib

kbdn_df	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Danish/NonExtended ; \
	$(MK_MAKE) full lib

kbde_be	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Dutch/Extended ; \
	$(MK_MAKE) full lib

kbde_fr	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/French/Extended ; \
	$(MK_MAKE) full lib

kbdn_fr	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/French/NonExtended ; \
	$(MK_MAKE) full lib

kps1_fr	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/French/Ps1 ; \
	$(MK_MAKE) full lib

kbde_sf :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/French/SwissExtended ; \
	$(MK_MAKE) full lib

kbde_gr :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/German/Extended ; \
	$(MK_MAKE) full lib

kbdn_gr :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/German/NonExtended ; \
	$(MK_MAKE) full lib

kbde_sg	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/German/SwissExtended ; \
	$(MK_MAKE) full lib

kbdn_sg	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/German/SwissNonExtended ; \
	$(MK_MAKE) full lib

kbde_it	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Italian/Extended ; \
	$(MK_MAKE) full lib

kbdn_it	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Italian/NonExtended ; \
	$(MK_MAKE) full lib

kbde_no	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Norwegian/Extended ; \
	$(MK_MAKE) full lib

kbdn_no	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Norwegian/NonExtended ; \
	$(MK_MAKE) full lib

kbde_po	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Portuguese/Extended ; \
	$(MK_MAKE) full lib

kbde_sp	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Spanish/Extended ; \
	$(MK_MAKE) full lib

kbdn_sp	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Spanish/NonExtended ; \
	$(MK_MAKE) full lib

kbde_sv	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Swedish/Extended ; \
	$(MK_MAKE) full lib

kbdn_sv	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Swedish/NonExtended ; \
	$(MK_MAKE) full lib

kbdt_sv	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Swedish/Typewriter ; \
	$(MK_MAKE) full lib

kbde_uk	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/UK/Extended ; \
	$(MK_MAKE) full lib

lbdn_uk	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/UK/NonExtended ; \
	$(MK_MAKE) full lib

t1000	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Keyboard/Tandy1000 ; \
	$(MK_MAKE) full lib

#mousedrivers
genmouse	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/GenMouse ; \
	$(MK_MAKE) full lib

absgen	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/AbsGen ; \
	$(MK_MAKE) full lib

kbmouse	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/KBMouse ; \
	$(MK_MAKE) full lib

msbus	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/MSBus ; \
	$(MK_MAKE) full lib

msser	: serial
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/MSSer ; \
	$(MK_MAKE) full lib

logibus	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/LogiBus ; \
	$(MK_MAKE) full lib

logiser	: serial
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/LogiSer ; \
	$(MK_MAKE) full lib

dma	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/DMA/DOSReal ; \
	$(MK_MAKE) full lib

msys	:  serial
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/MSys ; \
	$(MK_MAKE) full lib

ps2	: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Mouse/PS2 ; \
	$(MK_MAKE) full lib

# Printer Drivers

deskjet	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\HP\Deskjet
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\HP\Deskjet full

dj500c	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\HP\Dj500c
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\HP\Dj500c full

lbp	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\HP\Lbp
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\HP\Lbp full

mercury	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\HP\Mercury
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\HP\Mercury full


pcl4	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\HP\Pcl4
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\HP\Pcl4 full

quietjet	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\HP\QuietJet
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\HP\QuietJet full

canon48	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Canon48
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Canon48 full

canonbjc	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\CanonBJC
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\CanonBJC full

canonrgb	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\CanonRGB
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\CanonRGB full

epshi24	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Epshi24
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Epshi24 full

epson24	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Epson24
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Epson24 full

epson48	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Epson48
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Epson48 full

escp2	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Escp2
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Escp2 full

nec24	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Nec24
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Nec24 full

ppds24	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Ppds24
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Ppds24 full

tosh24	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Tosh24
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Tosh24 full

pscript	: spool eps ps2pdf
	mdcd %ROOT_DIR%\Installed\Driver\Printer\PScript
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\PScript full

dumb	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\Ascii\Dumb
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\Ascii\Dumb full

diablo	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\Ascii\Diablo
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\Ascii\Diablo full

citoh9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Citoh9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Citoh9 full

prop9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Prop9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Prop9 full

diconix9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Diconix9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Diconix9 full

eplx9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Eplx9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Eplx9 full

epmx9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Epmx9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Epmx9 full

eprx9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Eprx9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Eprx9 full

bchip9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Bchip9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Bchip9 full

star9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Star9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Star9 full

oki9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Oki9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Oki9 full

grpr9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Grpr9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Grpr9 full

epson9	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Epson9
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Epson9 full

propx24	: spool
	mdcd %ROOT_DIR%\Installed\Driver\Printer\DotMatrix\Propx24
	$(MAKE) -I$(ROOT_DIR)\Driver\Printer\DotMatrix\Propx24 full


#appl

#calendar	: ui text spool config pen
calendar	: ui text spool config
	mdcd %ROOT_DIR%\Installed\Appl\Calendar
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Calendar full

geodex	: ui text spool impex ssmeta convert mailhub serial
	mdcd %ROOT_DIR%\Installed\Appl\GeoDex
	$(MAKE) -k -I$(ROOT_DIR)\Appl\GeoDex full

geocalc	: ui spool cell parse math spreadsheet ruler text impex spline grobj chart bitmap
	mdcd %ROOT_DIR%\Installed\Appl\GeoCalc
	$(MAKE) -k -I$(ROOT_DIR)\Appl\GeoCalc full

geodraw	: ui spool ruler text spline grobj chart bitmap spell color convert
	mdcd %ROOT_DIR%\Installed\Appl\GeoDraw
	$(MAKE) -k -I$(ROOT_DIR)\Appl\GeoDraw full

geowrite	: ui spool ruler text spline grobj chart bitmap spell color impex styles ssmeta convert compress
	mdcd %ROOT_DIR%\Installed\Appl\GeoWrite
	$(MAKE) -k -I$(ROOT_DIR)\Appl\GeoWrite full

banner	: ui spool
	mdcd %ROOT_DIR%\Installed\Appl\Banner
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Banner full

geodeck	:
#	p4 sync -f //depot/pcgeos/Installed/Appl/Art/Decks/GeoDeck/geodeck.vm
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Art/Decks/GeoDeck ; \
	$(MK_MAKE) full lib

scrapbk	: ui text impex convert
	mdcd %ROOT_DIR%\Installed\Appl\ScrapBk
	$(MAKE) -k -I$(ROOT_DIR)\Appl\ScrapBk full

bigcalc	: ui math parse
	mdcd %ROOT_DIR%\Installed\Appl\BigCalc
	$(MAKE) -k -I$(ROOT_DIR)\Appl\BigCalc full

clock	: ui color
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Clock ; \
	$(MK_MAKE) full lib

#
# For now we can not remake mailtool or stcache or email
# email: ui text ansic socket spell spool mailtool stacache borlandc
#

email: ui text ansic socket spell spool  borlandc
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Appl/Email/...

manager: ui shell spool
	mdcd %ROOT_DIR%\Installed\Appl\FileMgrs2\GeoManager
	$(MAKE) -k -I$(ROOT_DIR)\Appl\FileMgrs2\Geomanager full

isdesk: ui shell spool wav shell
	mdcd %ROOT_DIR%\Installed\Appl\FileMgrs2\ISDesk
	$(MAKE) -k -I$(ROOT_DIR)\Appl\FileMgrs2\ISDesk full

sclock:	ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/SysTray/SClock ; \
	$(MK_MAKE) full lib

linktool: ui shell
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/FMTools/Linktool ; \
	$(MK_MAKE) full lib

homebase:
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Appl/BreadBox/Homebase/...

newsread: ui socket ansic text spool spell inetmsg extui parentc idialc
	mdcd %ROOT_DIR%\Installed\Appl\BreadBox\NewsRead
	$(MAKE) -k -I$(ROOT_DIR)\Appl\BreadBox\NewsRead full

ftpc	: ui flllib extui ansic ftplib
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\ftpc
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\ftpc full

# Utilities

setup:	ui spool config serial parallel
	mdcd %ROOT_DIR%\Installed\Appl\Preferences\Setup
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Preferences\Setup full

launcher: ui
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Launcher ; \
	$(MK_MAKE) full lib

prefmgr	: ui spool text spell config serial
	mdcd %ROOT_DIR%\Installed\Appl\Preferences\PrefMgr
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Preferences\PrefMgr full

charm	: ui text ansic
	mdcd %ROOT_DIR%\Installed\Appl\Charm
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Charm full

wordmat	: ui ansic wmlib
	mdcd %ROOT_DIR%\Installed\Appl\WordMat
	$(MAKE) -k -I$(ROOT_DIR)\Appl\WordMat full

# Tools

prntscrn	: ui spool
	mdcd %ROOT_DIR%\Installed\Appl\Tools\PrntScrn
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Tools\PrntScrn full

# Games

solitaire	: ui cards geodeck wav
	mdcd %ROOT_DIR%\Installed\Appl\Games\Solitaire
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Games\Solitaire full

cword	: ui wav
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Games/CWord ; \
	$(MK_MAKE) full lib

amateur	: ui sound game
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Games/Amateur ; \
	$(MK_MAKE) full lib

bjack	: ui sound game wav cards
	mdcd %ROOT_DIR%\Installed\Appl\Games\Bjack
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Games\Bjack full

gwpoker	: ui sound game wav cards
	mdcd %ROOT_DIR%\Installed\Appl\Games\GWPoker
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Games\GWPoker full

hearts	: ui sound wav cards
	mdcd %ROOT_DIR%\Installed\Appl\Games\Hearts
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Games\Hearts full

mine	: ui game
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Games/Mine ; \
	$(MK_MAKE) full lib

pyramid	: ui cards
	mdcd %ROOT_DIR%\Installed\Appl\Games\Pyramid
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Games\Pyramid full

sokoban	: ui game
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Games/Sokoban ; \
	$(MK_MAKE) full lib

taipei	: ui game
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Games/Taipei ; \
	$(MK_MAKE) full lib

uki	: ui sound text
	mdcd %ROOT_DIR%\Installed\Appl\Games\Uki
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Games\Uki full

column	: ui game
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Column
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Column full




idialup : ui ansic socket accpnt
	mdcd %ROOT_DIR%\Installed\Appl\IDialup
	$(MAKE) -k -I$(ROOT_DIR)\Appl\IDialup full

gpcmail : ui ansic spell text mailhub mailsmtp mailpop3 config spool idialc
	mdcd %ROOT_DIR%\Installed\Appl\GPCMail
	$(MAKE) -k -I$(ROOT_DIR)\Appl\GPCMail full

bbxmail : ui ansic spell text bbxmlib config spool
	mdcd %ROOT_DIR%\Installed\Appl\dil\bbxmail
	$(MAKE) -k -I$(ROOT_DIR)\Appl\dil\bbxmail full

bbxchat : ui text ansic socket accpnt parentc
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\BbxChat
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\BbxChat full

bnkr30 : ui ansic text spool math n2txt
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Bnkr30
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Bnkr30 full

hmbase : ui ansic text spool math
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\HmBase
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\HmBase full

# Savers

# currently does not make
# album	: saver config
#	mdcd %ROOT_DIR%\Installed\Appl\Saver\Album
#	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Album full

lol	: saver
	mdcd %ROOT_DIR%\Installed\Appl\LOL
	$(MAKE) -k -I$(ROOT_DIR)\Appl\LOL full

blackhole	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\BlackHole
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\BlackHole full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\BlackHole\BlackHolePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\BlackHole\BlackHolePref full

blank	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Blank
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Blank full

bobbin	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Bobbin
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Bobbin full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Bobbin\BobbinPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Bobbin\BobbinPref  full

circles	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Circles
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Circles full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Circles\CirclesPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Circles\CirclesPref full

dribble	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Dribble
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Dribble full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Dribble\DribblePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Dribble\DribblePref full

dust	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Dust
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Dust full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Dust\DustPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Dust\DustPref full

fades	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Fades
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Fades full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Fades\FadesPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Fades\FadesPref full

flame	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Flame
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Flame full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Flame\FlamePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Flame\FlamePref full

hopalong	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Hopalong
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Hopalong full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Hopalong\HopalongPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Hopalong\HopalongPref full

lastwords	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\LastWords
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\LastWords full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\LWPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\LWPref full

letter	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Letter
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Letter full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Letter\LetterPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Letter\LetterPref full

logo	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\logo
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\logo full

maze	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Maze
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Maze full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Maze\MazePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Maze\MazePref full

melt	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Melt
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Melt full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Melt\MeltPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Melt\MeltPref full

noodle	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Noodle
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Noodle full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Noodle\NoodlePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Noodle\NoodlePref full

palette	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Palette
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Palette full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Palette\PalettePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Palette\PalettePref full

pieces	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Pieces
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Pieces full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Pieces\PiecesPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Pieces\PiecesPref full

pith	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Pith
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Pith full

qix	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Qix
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Qix full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Qix\QixPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Qix\QixPref full

rotate	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Rotate
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Rotate full

sand	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Sand
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Sand full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Sand\SandPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Sand\SandPref full

spotlight	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Spotlight
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Spotlight full
#ifndef	NO_NEC
	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\Spotlight.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\spotligh.geo
#endif
#ifndef	NO_EC
	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\Spotlightec.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\spotlighec.geo
#endif
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Spotlight\SpotlightPref full
#ifndef	NO_NEC
	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\SpotlightPref.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\slpref.geo
#endif
#ifndef	NO_EC
	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\SpotlightPrefEC.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\slprefec.geo
#endif

stars	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Stars
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Stars full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Stars\StarsPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Stars\StarsPref full

string	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\String
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\String full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\String\StringPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\String\StringPref full

swarm	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Swarm
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Swarm full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Swarm\SwarmPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Swarm\SwarmPref full

tickertape	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Tickertape
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Tickertape full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Tickertape\TickertapePref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Tickertape\TickertapePref full

tiles	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Tiles
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Tiles full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Tiles\TilesPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Tiles\TilesPref full

worms	: saver config
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Worms
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Worms full
	mdcd %ROOT_DIR%\Installed\Appl\Saver\Worms\WormsPref
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Saver\Worms\WormsPref full

# infoserv app

#infoserv	: ui ansic spool socket \
#		  htcore htmem htcache \
#		  http htfile htftp \
#		  htconv htgif htjpeg sgml html htmlp \
#		  tcpip ppp modem
#	mdcd %ROOT_DIR%\Installed\Appl\InfoServ
#	$(MAKE) -I$(ROOT_DIR)\Appl\InfoServ lib full

# infoserv libs

#http	: ansic htcore htmem htcache
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Schemes\HTTP
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Schemes\HTTP lib full
#
#htcore	: ui ansic socket htmem math
#	mdcd %ROOT_DIR%\Installed\Library\WWW\HTCore
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\HTCore lib full
#
#htmem	: ansic
#	mdcd %ROOT_DIR%\Installed\Library\WWW\HTMem
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\HTMem lib full
#
#htcache	: ansic htmem htcore
#	mdcd %ROOT_DIR%\Installed\Library\WWW\HTCache
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\HTCache lib full
#
#htfile	: ansic htmem htcore
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Schemes\HTFile
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Schemes\HTFile lib full
#
#htftp	: ansic htmem htcore socket
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Schemes\HTFTP
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Schemes\HTFTP lib full
#
#pmanager	: htcore htmem
#	mdcd %ROOT_DIR%\Installed\Library\WWW\PManager
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\PManager lib full
#
#uigenera	: htcore htmem
#	mdcd %ROOT_DIR%\Installed\Library\WWW\UIGenera
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\UIGenera lib full
#
#htconv	: netutils htcore html
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Conv\HTConv
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Conv\HTConv lib full
#
#htgif	: netutils htcore html htconv
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Conv\HTGIF
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Conv\HTGIF lib full
#
#htjpeg	: netutils htcore html htconv
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Conv\HTJPEG
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Conv\HTJPEG lib full
#
#sgml	: htcore
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Conv\SGML
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Conv\SGML lib full
#
#html	: htcore htmem
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Conv\HTML
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Conv\HTML lib full
#
#htmlp	: htcore
#	mdcd %ROOT_DIR%\Installed\Library\WWW\Conv\HTMLP
#	$(MAKE) -I$(ROOT_DIR)\Library\WWW\Conv\HTMLP lib full

# infosrv drvs

tcpip	: netutils socket ansic resolver accpnt
	mdcd %ROOT_DIR%\Installed\Driver\Socket\TCPIP
	$(MAKE) -I$(ROOT_DIR)\Driver\Socket\TCPIP lib full

ppp	: netutils ansic accpnt
	mdcd %ROOT_DIR%\Installed\Driver\Socket\PPP
	$(MAKE) -I$(ROOT_DIR)\Driver\Socket\PPP lib full

# WebMagick app

webmagick	: ui ansic text spool html4par \
		  wmg3http wmg3ftp wmg3ext \
		  impgraph impdoc \
		  tcpip ppp modem \
                  ibms parentc wav mailhub socket \
                  js netutils cookies idialc
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\bbxbrow\JS
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\bbxbrow\AB
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\bbxbrow

# sorry, executing CLEAN in the global makefile is not only bad style, it forces
# EVERYONE, even people not working on the browser, to compile the whole stuff
# FOUR TIMES each build. So make a working dependency file or something else, but not
# this.

# since dependencies are broken, force remake
#	$(MAKE) clean

#pmake clean gives syntax error then executes correctly, no time to investigate
#	del *.eobj
#	del *.obj
#	del *.rsc
#	del *.sym
#	del *.geo
#	del *.ldf
	$(MAKE) -I$(ROOT_DIR)\Appl\Breadbox\bbxbrow full

# webmagick libs

#html3par	: ui ansic text extgraph
#	mdcd %ROOT_DIR%\Installed\Library\Breadbox\html3par
#	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\html3par lib full

html4par	: ui ansic text extgraph
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\html4par\JS
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\html4par
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\html4par lib full

profpnt		: ansic
	mdcd %ROOT_DIR%\Installed\Library\profpnt
	$(MAKE) -I$(ROOT_DIR)\Library\profpnt lib full

js              : ansic math borlandc mapheap profpnt
	mdcd %ROOT_DIR%\Installed\Library\js
	$(MAKE) -I$(ROOT_DIR)\Library\js lib full

ibms    : ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\ibms
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\ibms lib full

extgraph	: ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\extgraph
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\extgraph lib full

wmg3http	: ansic socket ui ssl netutils cookies
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\urldrv\wmg3http
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\urldrv\wmg3http lib full

wmg3ftp	: ansic html4par socket ui
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\urldrv\wmg3ftp
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\urldrv\wmg3ftp lib full

wmg3ext	: ansic ui
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\urldrv\wmg3ext
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\urldrv\wmg3ext lib full

cookies : ansic netutils
	mdcd %ROOT_DIR%\Installed\Library\Cookies
	$(MAKE) -I$(ROOT_DIR)\Library\Cookies lib full

mapheap :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/MapHeap ; \
	$(MK_MAKE) full lib

ssl	: ansic socket mapheap
	mdcd %ROOT_DIR%\Installed\Library\ssl
	$(MAKE) -I$(ROOT_DIR)\Library\ssl lib full

# product-specific dependency on fjpeg
impgraph	: ansic ijgjpeg #fjpeg
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\impgraph
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\impgraph lib full

ijgjpeg	: ui ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\ijgjpeg
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\ijgjpeg lib full

#fjpeg	: ui ansic
#	mdcd %ROOT_DIR%\Installed\Library\Breadbox\fjpeg
#	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\fjpeg lib full

impdoc	: ui ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\impdoc
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\impdoc lib full

pdfvu	: ui ansic spool borlandc
	mdcd %ROOT_DIR%\Installed\Appl\PDFViewer
	$(MAKE) -I$(ROOT_DIR)\Appl\PDFViewer full

#wavplay	: ui ansic wav
#	mdcd %ROOT_DIR%\Installed\Appl\WavPlay
#	$(MAKE) -I$(ROOT_DIR)\Appl\WavPlay full

giflib  : ansic extgraph
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Giflib
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\Giflib lib full

#
# GeoZip application & libraries
#
zlib    : ansic
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\zlib
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\zlib lib full


dirlist : ansic ui
#if defined(PRODUCT) && $(PRODUCT) == "NDO2000"
#else
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\dirlist
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\dirlist lib full
#endif

minizip : ansic ui zlib
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\minizip
	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\minizip lib full

geozip  : minizip dirlist
#if defined(PRODUCT) && $(PRODUCT) == "NDO2000"
#else
	mdcd %ROOT_DIR%\Installed\Appl\BreadBox\GEOZIP
	$(MAKE) -I$(ROOT_DIR)\Appl\BreadBox\GEOZIP full
# endif

#
# PicAlbum application & libraries
#
#photopc : streamc ansic
#	mdcd %ROOT_DIR%\Installed\Library\PhotoPC
#	$(MAKE) -I$(ROOT_DIR)\Library\PhotoPC full

#picalbum : ui spool ansic extgraph photopc
#	mdcd %ROOT_DIR%\Installed\Appl\PicAlbum
#	$(MAKE) -I$(ROOT_DIR)\Appl\PicAlbum full

# Geos impex libraries

dib	: ui ansic impex
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Bitmap\Dib
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Bitmap\Dib lib full

msmfile : text
	mdcd %ROOT_DIR%\Installed\Library\Trans\Text\MSMFile
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Text\MSMFile lib full

bmp	: math dib
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Bitmap\Bmp
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Bitmap\Bmp lib full

clp	: math dib
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Bitmap\Clp
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Bitmap\Clp lib full

ico	: math dib
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Bitmap\Ico
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Bitmap\Ico lib full

pcx	: math dib
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Bitmap\Pcx
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Bitmap\Pcx lib full

tif	: math dib
	mdcd %ROOT_DIR%\Installed\Library\Trans\Graphics\Bitmap\Tif
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Graphics\Bitmap\Tif lib full

#lot123	: ansic impex msmfile
#	mdcd %ROOT_DIR%\Installed\Library\Trans\Text\Lotus123
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Text\Lotus123 lib full

wordperf5 : ansic impex msmfile
	mdcd %ROOT_DIR%\Installed\Library\Trans\Text\WordPerfect5X
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Text\WordPerfect5X lib full

dbase3	: ansic impex
	mdcd %ROOT_DIR%\Installed\Library\Trans\Database\DBase3
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Database\DBase3 lib full

dbase4	: ansic impex
	mdcd %ROOT_DIR%\Installed\Library\Trans\Database\DBase4
	$(MAKE) -k -I$(ROOT_DIR)\Library\Trans\Database\DBase4 lib full

# Other Geos stuff (not in GPC)
conview	: ui spool
	mdcd %ROOT_DIR%\Installed\Library\Conview
	$(MAKE) -k -I$(ROOT_DIR)\Library\Conview lib full

reader	: ui text conview
	mdcd %ROOT_DIR%\Installed\Appl\Reader
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Reader full

term	: ui text
	mdcd %ROOT_DIR%\Installed\Appl\Term
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Term lib full

tedit	: ui text mailbox
	mdcd %ROOT_DIR%\Installed\Appl\Tedit
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Tedit full

geofile	: ui grobj spool parse cell ruler spline math spreadsheet \
	  text	ansic bitmap ffile impex
	mdcd %ROOT_DIR%\Installed\Appl\Geofile
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Geofile full

dirls	: ui ansic text spool
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Dirlist
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Dirlist full

bim	: ui ansic socket sound
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\bim
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\bim full

ffind	: ui ansic text
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Ffind
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Ffind full

cdaudio	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/Breadbox/CDAudio ; \
	$(MK_MAKE) full lib

cdados	:
	mdcd %ROOT_DIR%\Installed\Library\Breadbox\Cdados
	$(MAKE) -k -I$(ROOT_DIR)\Library\Breadbox\Cdados full

bbxcd	: ui ansic sound cdaudio
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Bbxcd
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Bbxcd full

webbox	: ui ansic text spool spell
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Webbox
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Webbox full

#geocon3	: ui ansic color
#	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Geocon3
#	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Geocon3 full

graphvwr : ui ansic extui giflib thumbdb ijgjpeg
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Graphvwr
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Graphvwr full

macror	: ui ansic
	mdcd %ROOT_DIR%\Installed\Appl\Breadbox\Macror
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Breadbox\Macror full

perf	: ui color
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Appl/Perf ; \
	$(MK_MAKE) full lib

dump	: spool ijgjpeg giflib
	mdcd %ROOT_DIR%\Installed\Appl\Dump
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Dump full

# Edu Apps
flash	: ui ansic text math
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\flash
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\flash full

fontmgck : ui ansic text color gsol
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\fontmgck
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\fontmgck full

hangman	: ui ansic math wmlib
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\hangman
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\hangman full

laserl	: ui ansic
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\laserl
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\laserl full

mflash	: ui ansic text treplib
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\mflash
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\mflash full

numbers	: ui ansic math
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\numbers
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\numbers full

pvault	: ui ansic
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\pvault
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\pvault full

taide	: ui ansic text math spool basicdb gridlib treplib
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\taide
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\taide full

thinker	: ui ansic
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\thinker
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\thinker full

ttype	: ui ansic text treplib
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\Ttype
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\Ttype full

wsm	: ui ansic spool
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\wsm
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\wsm full

wsplay	: ui ansic spool
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\wsplay
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\wsplay full

xwm	: ui ansic spool compress
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\xwm
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\xwm full

tgen	: ui ansic text math spool basicdb treplib
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\tgen
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\tgen full

ttkr	: ui ansic text math basicdb
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\ttkr
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\ttkr full

oliner	: ui ansic text math spool basicdb treplib spell
	mdcd %ROOT_DIR%\Installed\Appl\EduApps\oliner
	$(MAKE) -k -I$(ROOT_DIR)\Appl\EduApps\oliner full


#=======================================================================

################################
# NewDeal extra build geodes
################################
# USAGE: pmake -k ndo2000
# [builds entire product without stopping for silly errors]

# For some reason, using 'minimal' causes pmake to make motif etc. first before
# building the minimal parts, making a second run necessary.
# to prevent this, ndo2000 directly uses the 'minimalxxx' calls and 'ndorest'

ndo2000	: borlandobj minimalLoader minimalLibrary minimalDriver \
	  minimalAppl ndorest

# The borland.obj is one of the first files that needs to be compiled
# after a clean of the Installed directory.  The kernel and other
# essential libraries will not compile without it.

borlandobj :
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/BorlandRTL ; \
	$(MK_MAKE) borland.obj

ndorest:  regis run legos 	\
	  ms3 ntfat int8087 intx87 netware	\
	  irlap loopback slip 		\
	  vid_drivers	\
	  impex_libs bestsnd mp3snd rfsd	\
	  print_drivers extras taskmax cvttool more_prefs	\
	  faxsendtd geosafari slides

ms3     :
	mdcd %ROOT_DIR%\Installed\Driver\IFS\DOS\MS3
	$(MAKE) -k -I$(ROOT_DIR)\Driver\IFS\DOS\MS3 lib full

ms7     :
	mdcd %ROOT_DIR%\Installed\Driver\IFS\DOS\MS7
	$(MAKE) -k -I$(ROOT_DIR)\Driver\IFS\DOS\MS7 lib full

netware     :
	mdcd %ROOT_DIR%\Installed\Driver\IFS\DOS\NETWARE
	$(MAKE) -k -I$(ROOT_DIR)\Driver\IFS\DOS\NETWARE lib full

rfsd     : net ui
	mdcd %ROOT_DIR%\Installed\Driver\IFS\RFSD
	$(MAKE) -k -I$(ROOT_DIR)\Driver\IFS\RFSD lib full

int8087	: math
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/CoProcessor/Int8087 ; \
	$(MK_MAKE) full lib -k

intx87	: math
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Library/CoProcessor/Intx87 ; \
	$(MK_MAKE) full lib -k

taskmax	: ui text
	mdcd %ROOT_DIR%\Installed\Driver\Task\Taskmax
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Task\Taskmax lib full

cvttool	: ui convert
	mdcd %ROOT_DIR%\Installed\Library\FMTools\CvtTool
	$(MAKE) -k -I$(ROOT_DIR)\Library\FMTools\CvtTool lib full

faxsendtd	: mailbox faxfile faxctrl ui spool
	mdcd %ROOT_DIR%\Installed\Driver\Mailbox\Transport\Faxsendtd
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Mailbox\Transport\Faxsendtd lib full


# NewDeal socket drivers
irlap		: socket serial
	mdcd %ROOT_DIR%\Installed\Driver\Socket\Irlap
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Socket\Irlap lib full

loopback	: socket
	mdcd %ROOT_DIR%\Installed\Driver\Socket\Loopback
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Socket\Loopback lib full

slip	: netutils
	mdcd %ROOT_DIR%\Installed\Driver\Socket\Slip
	$(MAKE) -k -I$(ROOT_DIR)\Driver\Socket\Slip lib full

# NewDeal video drivers
vid_drivers: ega mcga hgc att6300

ega	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/VGAlike/EGA ; \
	$(MK_MAKE) full lib

cga	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/Dumb/CGA ; \
	$(MK_MAKE) full lib

dscga	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/Dumb/DSCGA ; \
	$(MK_MAKE) full lib

mcga	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/Dumb/MCGA ; \
	$(MK_MAKE) full lib

hgc	:
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Driver/Video/Dumb/HGC ; \
	$(MK_MAKE) full lib

# Terminal application
regis	: ui
	mdcd %ROOT_DIR%\Installed\Appl\Regis
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Regis lib full

run	: ui
	mdcd %ROOT_DIR%\Installed\Appl\Run
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Run lib full

sprite	: ui
	mdcd %ROOT_DIR%\Installed\Library\Sprite
	$(MAKE) -k -I$(ROOT_DIR)\Library\Sprite lib full

tree	: ansic
	mdcd %ROOT_DIR%\Installed\Library\Tree
	$(MAKE) -k -I$(ROOT_DIR)\Library\Tree lib full

datax	: ui
	mdcd %ROOT_DIR%\Installed\Library\DataX
	$(MAKE) -k -I$(ROOT_DIR)\Library\DataX lib full

datastore	:  text datax
	mdcd %ROOT_DIR%\Installed\Library\Datastore
	$(MAKE) -k -I$(ROOT_DIR)\Library\Datastore lib full


# Printer Drivers
#         escp2

#more_savers: lastword spotligh

# Additional Preferences Modules
more_prefs: tweakui hprefcn prefsndn

tweakui	: ui config color
	mdcd %ROOT_DIR%\Installed\Library\Pref\Tweakui
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Tweakui lib full

hprefcn	: ui config serial
	mdcd %ROOT_DIR%\Installed\Library\Pref\Hprefcn
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Hprefcn lib full

prefsndn	: ui ansic config sound
	mdcd %ROOT_DIR%\Installed\Library\Pref\Prefsndn
	$(MAKE) -k -I$(ROOT_DIR)\Library\Pref\Prefsndn lib full

# BestSound - supplemental sound API.
bestsnd	: bsnwav mixlib bsd16 bsd8st bsqp sndchk

bsnwav	: kernel
#if defined(PRODUCT) && $(PRODUCT) == "NDO2000"
	mdcd %ROOT_DIR%\Installed\Library\Audio\BSNWav
	$(MAKE) -k  -I$(ROOT_DIR)\Library\Audio\BSNWav lib full
#endif

mixlib	: bsnwav sound ui ansic
	mdcd %ROOT_DIR%\Installed\Library\Audio\MixLib
	$(MAKE) -k  -I$(ROOT_DIR)\Library\Audio\MixLib lib full

bsd16	: stream
	mdcd %ROOT_DIR%\Installed\Driver\Sound\BSD16
	$(MAKE) -k  -I$(ROOT_DIR)\Driver\Sound\BSD16 lib full

bsd8st	: stream
	mdcd %ROOT_DIR%\Installed\Driver\Sound\BSD8ST
	$(MAKE) -k  -I$(ROOT_DIR)\Driver\Sound\BSD8ST lib full

bsqp	: bsnwav ansic ui
	mdcd %ROOT_DIR%\Installed\Appl\Audio\Bsqp
	$(MAKE) -k  -I$(ROOT_DIR)\Appl\Audio\Bsqp lib full

sndchk	: bsnwav wav ansic ui
	mdcd %ROOT_DIR%\Installed\Appl\Audio\SndChk
	$(MAKE) -k  -I$(ROOT_DIR)\Appl\Audio\SndChk lib full

# MP3 - audio format decoder
mp3snd	: mp3 mp3play

mp3	: math ansic
	mdcd %ROOT_DIR%\Installed\Library\Audio\Mp3
	$(MAKE) -k  -I$(ROOT_DIR)\Library\Audio\Mp3  lib full

mp3play	: ui sound mp3
	mdcd %ROOT_DIR%\Installed\Appl\Audio\Mp3Play
	$(MAKE) -k  -I$(ROOT_DIR)\Appl\Audio\Mp3Play lib full

# Extras apps
extras : bounce spintext timer

bounce	: ui
	mdcd %ROOT_DIR%\Installed\Appl\Bounce
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Bounce full

spintext	: ui
	mdcd %ROOT_DIR%\Installed\Appl\Spintext
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Spintext full

timer	: ui text
	mdcd %ROOT_DIR%\Installed\Appl\Tools\Timer
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Tools\Timer full

slides	: ui text impex convert
	mdcd %ROOT_DIR%\Installed\Appl\Slides
	$(MAKE) -k -I$(ROOT_DIR)\Appl\Slides full
