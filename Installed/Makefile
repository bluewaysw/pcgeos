#
# there is a circular dependency between pcmcia and ui, so you need to have
# an old ui.ldf to start with.
#

MAKELIB	:	.USE
#if defined(linux)
	mkdir -p ../$(.TARGET)
	cd ../$(.TARGET)
	$(MAKE) -k -I../$(.TARGET) full lib
#else
	if not exist  ..\$(.TARGET:S/\//\\/g) mkdir ..\$(.TARGET:S/\//\\/g)
	cd ..\$(.TARGET:S/\//\\/g)
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full lib
#endif

MAKETOOL:	.USE
#if defined(linux)
	mkdir -p ../$(.TARGET)
	cd ../$(.TARGET)
	$(MAKE) -k -I../$(.TARGET) full
#else
	if not exist  ..\$(.TARGET:S/\//\\/g) mkdir ..\$(.TARGET:S/\//\\/g)
	cd ..\$(.TARGET:S/\//\\/g)
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full
#endif

MAKEDRV:	.USE
#if defined(linux)
	mkdir -p ../$(.TARGET)
	cd ../$(.TARGET)
	$(MAKE) -k -I../$(.TARGET) full
#else
	if not exist  ..\$(.TARGET:S/\//\\/g) mkdir ..\$(.TARGET:S/\//\\/g)
	cd ..\$(.TARGET:S/\//\\/g)
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full
#endif

MAKEAPPL:	.USE
#if defined(linux)
	mkdir -p ../$(.TARGET)
	cd ../$(.TARGET)
	$(MAKE) -k -I../$(.TARGET) full
#else
	if not exist  ..\$(.TARGET:S/\//\\/g) mkdir ..\$(.TARGET:S/\//\\/g)
	cd ..\$(.TARGET:S/\//\\/g)
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full
#endif

MAKESTUB:	.USE
#if defined(linux)
	mkdir -p ../$(.TARGET)
	cd ../$(.TARGET)
	cd ..
	export SUBDIRS=$(.TARGET:X*\/Stub\/\\[*\\])
	$(MAKE) -k -I../$(.TARGET)
#else
	if not exist  ..\$(.TARGET:S/\//\\/g) mkdir ..\$(.TARGET:S/\//\\/g)
	cd ..\$(.TARGET:S/\//\\/g)
	cd ..
	set  SUBDIRS=$(.TARGET:X*\/Stub\/\\[*\\])
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g)
#endif


minimal		: minimalLoader minimalLibrary minimalDriver minimalAppl \
		  otherEnsemble minimalStub

minimalLoader	: textLoader VGALoader

#
# Stubs
#
minimalStub	: stub stub_netware stub_wincom

stub		: Installed/Tools/swat/Stub/LowMem
Installed/Tools/swat/Stub/LowMem:	MAKESTUB

stub_netware	: Installed/Tools/swat/Stub/NetWare
Installed/Tools/swat/Stub/NetWare:	MAKESTUB

stub_wincom	: Installed/Tools/swat/Stub/WinCom
Installed/Tools/swat/Stub/WinCom:	MAKESTUB


#
# Libraries
#
minimalLibrary	: kernel swap sound net ui isui motif spool text mailbox \
		  genpc ansic cdaudio cell chart color compress config hash impex \
		  borlandc math pen resolver spline ssmeta styles \
		  wav game cards spreadsheet parse spell convert \
		  saver prefLibs accpnt netutils \
		  socket dhcp borlandrtl ffile streamc mailhub mailsmtp \
		  modemc mailpop3 lot123ss csv \
		  parentc wmlib rtf \
		  jpeg giflib gif htmlimpx n2txt inetmsg extui \
		  winword8 zlib dirlist minizip idialc eps impex_libs \
		  thumbdb ftplib flllib sitelist int8087 intx87\
		  basicdb gridlib gsol treplib
#ascii

prefLibs	: prefvid preftd \
		  prefsnd prefos prefmous preflo preflf prefkbd \
		  prefintl prefcomp prefbg prefpntc preffont configui

# prefs not used preflvl prefuic prefui prefts prefspui prefsock preflink preflang

# Geos impex libraries
impex_libs	: dib bmp clp ico pcx tif \
		  dbase3 dbase4 htmlpars htmlimpx
#lot123 msmword msword wordperf5


# Extra Pref libs - don't bother making these
#
extraPrefLibs	: prefpag prefjfep

#
# Revived specigic UI libraries
#
revivedUI	: openlpook

#
# Applications
#
minimalAppl	: minimalGame minimalUtils minimalTools minimalSavers \
		  minimalEdu calendar geodex geocalc geodraw geowrite \
		  scrapbk clock bigcalc geopoint \
		  email manager isdesk linktool setup \
		  launcher webmagick idialup \
		  charm wordmat banner \
		  bbxchat bbxmail \
		  newsread geozip sclock\
 	  	  hmbase pdfvu  bnkr30 ftpc

minimalUtils	: prefmgr

minimalGame	: solitaire cword amateur bjack hearts gwpoker \
                  pyramid sokoban taipei uki mine column

minimalEdu	: flash fontmgck hangman laserl mflash numbers pvault \
                  taide thinker wsm wsplay xwm
# ttype

minimalSavers	: lol blackhole blank bobbin circles dribble dust \
		  fades flame hopalong letter logo maze lastwords \
		  melt noodle palette pieces pith qix rotate sand \
		  spotlight stars string swarm tickertape tiles worms

minimalTools	: prntscrn

otherEnsemble	: conview reader term tedit geofile dirls  \
		   graphvwr macror dump perf bim ffind bbxcd webbox
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
		  vga vga8 vga15 vga16 vga24 ega cga mcga hgc att6300 dscga \
		  printerDriver ctm ctmabs imps2 \
		  ps2 msys msser msbus kbmouse absgen genmouse emm extmem \
		  xms filestr nonts sblaster comm spooltd \
		  vmtree filedd logibus logiser dma mslf kbd_drivers \
		  etherodi etherpkt msnet cdados

printerDriver	: deskjet dj500c lbp mercury pcl4 quietjet canon48 \
		  canonbjc  epshi24 epson24 epson48 nec24 \
		  ppds24 tosh24 pscript dumb diablo citoh9 prop9 \
 	  	  diconix9 eplx9 epmx9 eprx9 bchip9 star9 \
   	  	  oki9 grpr9 epson9 propx24
#canonrgb
#escp2 remove from above since it doesn't compile

#faxDriver	: class1in class1out class2in class2out

textLoader	:	Installed/Loader/Text
Installed/Loader/Text	:	MAKETOOL

VGALoader	:	Installed/Loader/VGA
Installed/Loader/VGA	: 	MAKETOOL

kernel	:	Installed/Library/Kernel
Installed/Library/Kernel 	:	MAKELIB

swap	:	Installed/Library/Swap
Installed/Library/Swap	:	kernel MAKELIB

sound	: Installed/Library/Sound
Installed/Library/Sound	: kernel stream MAKELIB

# Cannot state true dependency for PCMCIA & Net (they both rely
# upon the UI library), as we would have a circular dependency.

#pcmcia	:	Installed\Library\PCMCIA
#Installed\Library\PCMCIA : MAKELIB

net	:	Installed/Library/Net
Installed/Library/Net :	kernel MAKELIB

# removed pcmcia
ui	: Installed/Library/User
Installed/Library/User	:	kernel sound compress net wav MAKELIB

isui	: Installed/Library/SpecUI/ISUI
Installed/Library/SpecUI/ISUI	:	kernel text MAKELIB

motif	: Installed/Library/SpecUI/Motif
Installed/Library/SpecUI/Motif:	kernel text MAKELIB

motif	: Installed/Library/ReviveUI/OpenLook
Installed/Library/ReviveUI/OpenLook:	kernel text MAKELIB

spool	: Installed/Library/Spool
Installed/Library/Spool:	kernel text MAKELIB

text	: Installed/Library/Text
Installed/Library/Text:	ui styles color ruler bitmap MAKELIB

styles	: Installed/Library/Styles
Installed/Library/Styles:	ui MAKELIB

color	: Installed/Library/Color
Installed/Library/Color: 	ui MAKELIB

mailbox	: Installed/Library/Mailbox
Installed/Library/Mailbox:	ui spool MAKELIB

compress	: Installed/Library/Compress
Installed/Library/Compress:	kernel MAKELIB

ruler	: Installed/Library/Ruler
Installed/Library/Ruler:	ui MAKELIB

bitmap	: Installed/Library/Bitmap
Installed/Library/Bitmap: 	ui MAKELIB

pen	: Installed/Library/Pen
Installed/Library/Pen:	ui text MAKELIB

genpc	: Installed/Library/GDI/GenPC
Installed/Library/GDI/GenPC: kernel MAKELIB

shell	: Installed/Library/Shell
Installed/Library/Shell: 	ui MAKELIB

ansic	: Installed/Library/AnsiC
Installed/Library/AnsiC: kernel math borlandc MAKELIB

cell	: Installed/Library/Cell
Installed/Library/Cell: 	kernel MAKELIB

chart	: Installed/Library/Chart
Installed/Library/Chart:	ui grobj spline text MAKELIB

config	: Installed/Library/Config
Installed/Library/Config: 	ui MAKELIB

grobj	: Installed/Library/GrObj
Installed/Library/GrObj:	ui text bitmap ruler spline color \
				styles impex MAKELIB

hash	: Installed/Library/Hash
Installed/Library/Hash:	kernel MAKELIB

impex	: Installed/Library/Impex
Installed/Library/Impex: 	ui MAKELIB

# Don't compile import yet because the unix files haven't
# converted to dos files.
# import	:
#	mdcd %ROOT_DIR%\Installed\Library\Import
#	$(MAKE) -k -I$(ROOT_DIR)\Library\Import lib full

lot123ss	: Installed/Library/Trans/SSheet/Lotus123
Installed/Library/Trans/SSheet/Lotus123: ui ansic impex math ssmeta MAKELIB

csv	: Installed/Library/Trans/Database/CSV
Installed/Library/Trans/Database/CSV:	ui impex ssmeta MAKELIB

rtf	: Installed/Library/Breadbox/Impex/RTF
Installed/Library/Breadbox/Impex/RTF: 	ui impex text ansic MAKELIB

jpeg	: Installed/Library/Breadbox/Impex/JPEG
Installed/Library/Breadbox/Impex/JPEG: ui impex ansic ijgjpeg math MAKELIB

gif : Installed/Library/Breadbox/Impex/GIF
Installed/Library/Breadbox/Impex/GIF: ui impex ansic extgraph giflib MAKELIB

wmf : Installed/Library/Trans/Graphics/Vector/Wmf
Installed/Library/Trans/Graphics/Vector/Wmf: ui impex ansic MAKELIB

ascii	: Installed/Library/Trans/Text/Ascii
Installed/Library/Trans/Text/Ascii: 	ui text MAKELIB

msword	: Installed/Library/Trans/Text/MicrosoftWord
Installed/Library/Trans/Text/MicrosoftWord: 	ui ansic impex msmfile MAKELIB

htmlpars : Installed/Library/Breadbox/HtmlPars
Installed/Library/Breadbox/HtmlPars: kernel ansic text MAKELIB

htmlimpx : Installed/Library/Trans/Web/HtmlImpx
Installed/Library/Trans/Web/HtmlImpx: htmlpars ansic text impex ui MAKELIB

sstor	: Installed/Library/Breadbox/SStor
Installed/Library/Breadbox/SStor: 	kernel ansic MAKELIB

wfwlib	: Installed/Library/Breadbox/Impex/WFWLib
Installed/Library/Breadbox/Impex/WFWLib:	kernel text ansic sstor MAKELIB

winword8 : Installed/Library/Breadbox/Impex/WinWord8
Installed/Library/Breadbox/Impex/WinWord8: kernel impex ansic text sstor wfwlib MAKELIB

borlandrtl	:
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Library/BorlandRTL/...

borlandc	: Installed/Library/Math/Compiler/BorlandC
Installed/Library/Math/Compiler/BorlandC: kernel math MAKELIB

math	: Installed/Library/Math
Installed/Library/Math:	ui MAKELIB

resolver	: Installed/Library/Resolver
Installed/Library/Resolver:	netutils ui socket accpnt MAKELIB

spline	: Installed/Library/Spline
Installed/Library/Spline:	ui MAKELIB

ssmeta	: Installed/Library/SSMeta
Installed/Library/SSMeta:	ui math MAKELIB

# bsnwav will only be compiled (and is only referenced in WAV) if PRODUCT==NDO2000
wav	: Installed/Library/Wav
Installed/Library/Wav:	kernel sound MAKELIB

game	: Installed/Library/Game
Installed/Library/Game:	ui wav MAKELIB

cards	: Installed/Library/Cards
Installed/Library/Cards:	ui MAKELIB

parse	: Installed/Library/Parse
Installed/Library/Parse:	cell math ui MAKELIB

spreadsheet	: Installed/Library/Spreadsheet
Installed/Library/Spreadsheet:	ui ruler cell math parse chart \
				text color ssmeta MAKELIB

spell	: Installed/Library/Spell
Installed/Library/Spell:	ansic ui text MAKELIB

#EC version link arguments is too long, so link manually
#	pmake -u > args1
#	perl fixArgs.pl args1
#	glue @args1
#	del args1

convert	: Installed/Library/Convert
Installed/Library/Convert:	ui grobj MAKELIB

saver	: Installed/Library/Saver
Installed/Library/Saver:	ui grobj net MAKELIB

#faxfile	: Installed/Library/Fax/File
#Installed/Library/Fax/File:	ui text MAKELIB

#faxctrl	: Installed/Library/Fax/Ctrl
#Installed/Library/Fax/Ctrl:	ui text faxfile mailbox MAKELIB

accpnt	: Installed/Library/AccPnt
Installed/Library/AccPnt:	ui MAKELIB

netutils	: Installed/Library/NetUtils
Installed/Library/NetUtils:	ui MAKELIB

eps	: Installed/Library/Trans/Graphics/Vector/EPS
Installed/Library/Trans/Graphics/Vector/EPS:	ui MAKELIB

ps2pdf	: Installed/Library/Breadbox/ps2pdf
Installed/Library/Breadbox/ps2pdf:	kernel ansic MAKELIB

socket	: Installed/Library/Socket
Installed/Library/Socket:	ui netutils MAKELIB

dhcp	: Installed/Library/DHCP
Installed/Library/DHCP:	socket ui accpnt MAKELIB

ffile	: Installed/Library/FlatFile
Installed/Library/FlatFile:	cell ui spreadsheet parse ansic math \
				text grobj spool ssmeta MAKELIB
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Library/FlatFile/...
#	build it anyway, because p4 sync does not work if not connected
#	while making the build (I know, all these warnings are annoying, and some
#	are definitely the cause of instabilities, but no reason to hide this :)

streamc : Installed/Library/StreamC
Installed/Library/StreamC:	ui MAKELIB

modemc : Installed/Library/ModemC
Installed/Library/ModemC:	kernel MAKELIB

mailhub : Installed/Library/Mail/MailHub
Installed/Library/Mail/MailHub:	kernel socket ansic MAKELIB

bbxmlib	: Installed/Library/dil/bbxmail
Installed/Library/dil/bbxmail:	kernel socket ansic MAKELIB

mailsmtp : Installed/Library/Mail/MailSMTP
Installed/Library/Mail/MailSMTP:	kernel socket ansic mailhub MAKELIB

mailpop3 : Installed/Library/Mail/MailPOP3

Installed/Library/Mail/MailPOP3:	kernel socket ansic mailhub MAKELIB
#bckrst : Installed/Library/BckRst
#Installed/Library/BckRst: 	ui ansic MAKELIB

filestr	: Installed/Driver/Stream/Filestr
Installed/Driver/Stream/Filestr:	kernel stream MAKEDRV

nonts	: Installed/Driver/Task/NonTS
Installed/Driver/Task/NonTS:	kernel MAKEDRV

sblaster	: Installed/Driver/Sound/SoundBlaster
Installed/Driver/Sound/SoundBlaster:	kernel stream MAKEDRV

comm	: Installed/Driver/Net/Comm
Installed/Driver/Net/Comm:	kernel net MAKEDRV

spooltd	: Installed/Driver/Mailbox/Transport/SpoolTD
Installed/Driver/Mailbox/Transport/SpoolTD:	ui mailbox spool MAKEDRV

vmtree	: Installed/Driver/Mailbox/Data/VMTree
Installed/Driver/Mailbox/Data/VMTree:	kernel mailbox MAKEDRV

filedd	: Installed/Driver/Mailbox/Data/FileDD
Installed/Driver/Mailbox/Data/FileDD:	kernel mailbox serial MAKEDRV

parentc : Installed/Library/ParentC
Installed/Library/ParentC:	ui config MAKELIB

wmlib	: Installed/Library/Breadbox/WMLib
Installed/Library/Breadbox/WMLib:	kernel ansic compress MAKELIB

n2txt	: Installed/Library/Breadbox/N2Txt
Installed/Library/Breadbox/N2Txt:	ui ansic text math MAKELIB

inetmsg : Installed/Library/Breadbox/INetMsg
Installed/Library/Breadbox/INetMsg:	ui ansic extui MAKELIB

extui   : Installed/Library/Breadbox/ExtUI
Installed/Library/Breadbox/ExtUI:	ui ansic MAKELIB

sitelist	: Installed/Library/Breadbox/sitelist
Installed/Library/Breadbox/sitelist: 	ui ansic MAKELIB

flllib	: Installed/Library/Breadbox/flllib
Installed/Library/Breadbox/flllib:	ui ansic MAKELIB

ftplib	: Installed/Library/Breadbox/ftplib
Installed/Library/Breadbox/ftplib:	 ui ansic socket MAKELIB

idialc	: Installed/Library/IDialC
Installed/Library/IDialC:	ui socket MAKELIB

thumbdb : Installed/Library/Breadbox/ThumbDB
Installed/Library/Breadbox/ThumbDB:	kernel ansic MAKELIB

# the EduApp libs
basicdb : Installed/Library/Breadbox/Basicdb
Installed/Library/Breadbox/Basicdb:	kernel ansic MAKELIB

gridlib : Installed/Library/Breadbox/Gridlib
Installed/Library/Breadbox/Gridlib:	ui ansic text MAKELIB

treplib : Installed/Library/Breadbox/Treplib
Installed/Library/Breadbox/Treplib:	ui ansic text spool MAKELIB

gsol	: Installed/Library/Breadbox/Gsol
Installed/Library/Breadbox/Gsol:	kernel ansic MAKELIB

# Preference libraries

configui	: Installed/Library/Pref/ConfigUI
Installed/Library/Pref/ConfigUI:	ui config ansic MAKELIB

prefbg	: Installed/Library/Pref/Prefbg
Installed/Library/Pref/Prefbg:	ui config color convert MAKELIB

prefcomp	: Installed/Library/Pref/Prefcomp
Installed/Library/Pref/Prefcomp:	ui config serial parallel MAKELIB

preffont	: Installed/Library/Pref/Preffont
Installed/Library/Pref/Preffont:	ui config ansic MAKELIB

prefintl	: Installed/Library/Pref/Prefintl
Installed/Library/Pref/Prefintl:	ui config MAKELIB

prefkbd	: Installed/Library/Pref/Prefkbd
Installed/Library/Pref/Prefkbd:		ui config MAKELIB

#preflang	: Installed/Library/Pref/Preflang
#Installed/Library/Pref/Preflang:	ui config MAKELIB

preflf	: Installed/Library/Pref/Preflf
Installed/Library/Pref/Preflf:		ui config MAKELIB

#preflink	: Installed/Library/Pref/Preflink
#Installed/Library/Pref/Preflink:	ui config MAKELIB

preflo	: Installed/Library/Pref/Preflo
Installed/Library/Pref/Preflo:		ui config saver net MAKELIB

#preflvl	: Installed/Library/Pref/Preflvl
#Installed/Library/Pref/Preflvl:	ui config MAKELIB

prefmous	: Installed/Library/Pref/Prefmous
Installed/Library/Pref/Prefmous:	ui config MAKELIB

prefos	: Installed/Library/Pref/Prefos
Installed/Library/Pref/Prefos:		ui config MAKELIB

#prefpag	: Installed/Library/Pref/Prefpag
#Installed/Library/Pref/Prefpag:	ui config MAKELIB

prefsnd	: Installed/Library/Pref/Prefsnd
Installed/Library/Pref/Prefsnd:		ui config MAKELIB

#prefsock	: Installed/Library/Pref/Prefsock
#Installed/Library/Pref/Prefsock:	ui config MAKELIB

#prefspui	: Installed/Library/Pref/Prefspui
#Installed/Library/Pref/Prefspui:	ui config MAKELIB

preftd	: Installed/Library/Pref/Preftd
Installed/Library/Pref/Preftd:		ui config MAKELIB

#prefts	: Installed/Library/Pref/Prefts
#Installed/Library/Pref/Prefts:		ui config MAKELIB

#prefui	: Installed/Library/Pref/Prefui
#Installed/Library7Pref/Prefui:		ui config MAKELIB

#prefuic	: Installed/Library/Pref/Prefuic
#Installed/Library/Pref/Prefuic:	ui config MAKELIB

prefvid	: Installed/Library/Pref/Prefvid
Installed/Library/Pref/Prefvid:		ui config MAKELIB

prefpntc	: Installed/Library/Pref/PrefPntC
Installed/Library/Pref/PrefPntC:	ui config parentc MAKELIB


#driver

stream	: Installed/Driver/Stream
Installed/Driver/Stream:		kernel MAKEDRV

nimbus	: Installed/Driver/Font/Nimbus
Installed/Driver/Font/Nimbus:		kernel MAKEDRV

ms4	: Installed/Driver/IFS/DOS/MS4
Installed/Driver/IFS/DOS/MS4:		kernel MAKEDRV

os2	: Installed/Driver/IFS/DOS/OS2
Installed/Driver/IFS/DOS/OS2:		kernel MAKEDRV

ntfat	: Installed/Driver/IFS/DOS/NTFat
Installed/Driver/IFS/DOS/NTFat:		kernel MAKEDRV

dri	: Installed/Driver/IFS/DOS/DRI
Installed/Driver/IFS/DOS/DRI:		kernel MAKEDRV

mslf	: Installed/Driver/IFS/DOS/MSLF
Installed/Driver/IFS/DOS/MSLF:		kernel MAKEDRV

cdrom     : Installed/Driver/IFS/DOS/CDROM
Installed/Driver/IFS/DOS/CDROM:		kernel MAKEDRV

gdi	: Installed/Driver/Keyboard/GDI
Installed/Driver/Keyboard/GDI:		kernel genpc MAKEDRV

msnet     : Installed/Driver/IFS/DOS/MSNet
Installed/Driver/IFS/DOS/MSNet:		kernel MAKEDRV

keyboard	: Installed/Driver/Keyboard
Installed/Driver/Keyboard:		kernel MAKEDRV

modem	: Installed/Driver/Modem
Installed/Driver/Modem:			kernel MAKEDRV

gdipointer	: Installed/Driver/Mouse/GDIPointer
Installed/Driver/Mouse/GDIPointer:	kernel MAKEDRV

standard	: Installed/Driver/Sound/Standard
Installed/Driver/Sound/Standard:	kernel MAKEDRV

winnt	: Installed/Driver/Sound/WinNT
Installed/Driver/Sound/WinNT:		kernel MAKEDRV

parallel	: Installed/Driver/Stream/Parallel
Installed/Driver/Stream/Parallel:	kernel stream MAKEDRV

serial	: Installed/Driver/Stream/Serial
Installed/Driver/Stream/Serial:		kernel stream MAKEDRV

disk	: Installed/Driver/Swap/Disk
Installed/Driver/Swap/Disk:		kernel MAKEDRV

emm	: Installed/Driver/Swap/EMS/EMM
Installed/Driver/Swap/EMS/EMM:		kernel MAKEDRV

extmem	: Installed/Driver/Swap/ExtMem
Installed/Driver/Swap/ExtMem:		kernel MAKEDRV

xms	: Installed/Driver/Swap/XMS
Installed/Driver/Swap/XMS:		kernel MAKEDRV

att6300	: Installed/Driver/Video/Dumb/ATT6300
Installed/Driver/Video/Dumb/ATT6300:	kernel MAKEDRV

vidmem	: Installed/Driver/Video/Dumb/VidMem
Installed/Driver/Video/Dumb/VidMem:	kernel MAKEDRV

svga	: Installed/Driver/Video/VGAlike/SVGA
Installed/Driver/Video/VGAlike/SVGA:	kernel MAKEDRV

vga	: Installed/Driver/Video/VGAlike/VGA

Installed/Driver/Video/VGAlike/VGA:	kernel MAKEDRV
vga8	: Installed/Driver/Video/VGAlike/VGA8
Installed/Driver/Video/VGAlike/VGA8:	kernel MAKEDRV

vga15	: Installed/Driver/Video/VGAlike/VGA15
Installed/Driver/Video/VGAlike/VGA15:	kernel MAKEDRV

vga16	: Installed/Driver/Video/VGAlike/VGA16
Installed/Driver/Video/VGAlike/VGA16:	kernel MAKEDRV

vga24	: Installed/Driver/Video/VGAlike/VGA24
Installed/Driver/Video/VGAlike/VGA24:	kernel MAKEDRV

etherodi	: Installed/Driver/Socket/EtherODI
Installed/Driver/Socket/EtherODI:	kernel socket accpnt MAKEDRV

etherpkt	: Installed/Driver/Socket/EtherPKT
Installed/Driver/Socket/EtherPKT:	kernel socket accpnt MAKEDRV

# International Keyboard Drivers
kbd_drivers : kbdb_cf kbde_cf kbd_csa kbde_df kbdn_df kbde_be kbd_dvrk  \
	kbde_fr kbdn_fr kps1_fr kbde_sf kbde_gr kbdn_gr kbde_sg        	\
	kbdn_sg kbde_it kbdn_it kbde_no kbdn_no kbde_po kbde_sp kbdn_sp	\
	kbde_sv kbdn_sv kbdt_sv kbde_uk lbdn_uk t1000

kbd_dvrk	: Installed/Driver/Keyboard/Dvorak
Installed/Driver/Keyboard/Dvorak:	kernel MAKEDRV

kbdb_cf	: Installed/Driver/Keyboard/Canadian/Bilingual
Installed/Driver/Keyboard/Canadian/Bilingual:	kernel MAKEDRV

kbde_cf	: Installed/Driver/Keyboard/Canadian/FrenchExtended
Installed/Driver/Keyboard/Canadian/FrenchExtended:	kernel MAKEDRV

kbd_csa	: Installed/Driver/Keyboard/Canadian/CSA-z243.200-91
Installed/Driver/Keyboard/Canadian/CSA-z243.200-91:	kernel MAKEDRV

kbde_df	: Installed/Driver/Keyboard/Danish/Extended
Installed/Driver/Keyboard/Danish/Extended:		kernel MAKEDRV

kbdn_df	: Installed/Driver/Keyboard/Danish/NonExtended
Installed/Driver/Keyboard/Danish/NonExtended:		kernel MAKEDRV

kbde_be	: Installed/Driver/Keyboard/Dutch/Extended
Installed/Driver/Keyboard/Dutch/Extended:		kernel MAKEDRV

kbde_fr	: Installed/Driver/Keyboard/French/Extended
Installed/Driver/Keyboard/French/Extended:		kernel MAKEDRV

kbdn_fr	: Installed/Driver/Keyboard/French/NonExtended
Installed/Driver/Keyboard/French/NonExtended:		kernel MAKEDRV

kps1_fr	: Installed/Driver/Keyboard/French/PS1
Installed/Driver/Keyboard/French/PS1:			kernel MAKEDRV

kbde_sf : Installed/Driver/Keyboard/French/SwissExtended
Installed/Driver/Keyboard/French/SwissExtended:		kernel MAKEDRV

kbde_gr : Installed/Driver/Keyboard/German/Extended
Installed/Driver/Keyboard/German/Extended:		kernel MAKEDRV

kbdn_gr : Installed/Driver/Keyboard/German/NonExtended
Installed/Driver/Keyboard/German/NonExtended:		kernel MAKEDRV

kbde_sg	: Installed/Driver/Keyboard/German/SwissExtended

Installed/Driver/Keyboard/German/SwissExtended:		kernel MAKEDRV
kbdn_sg	: Installed/Driver/Keyboard/German/SwissNonExtended
Installed/Driver/Keyboard/German/SwissNonExtended :	kernel MAKEDRV

kbde_it	: Installed/Driver/Keyboard/Italian/Extended
Installed/Driver/Keyboard/Italian/Extended:		kernel MAKEDRV

kbdn_it	: Installed/Driver/Keyboard/Italian/NonExtended
Installed/Driver/Keyboard/Italian/NonExtended:		kernel MAKEDRV

kbde_no	: Installed/Driver/Keyboard/Norwegian/Extended
Installed/Driver/Keyboard/Norwegian/Extended:		kernel MAKEDRV

kbdn_no	: Installed/Driver/Keyboard/Norwegian/NonExtended
Installed/Driver/Keyboard/Norwegian/NonExtended:	kernel MAKEDRV

kbde_po	: Installed/Driver/Keyboard/Portuguese/Extended
Installed/Driver/Keyboard/Portuguese/Extended:		kernel MAKEDRV

kbde_sp	: Installed/Driver/Keyboard/Spanish/Extended
Installed/Driver/Keyboard/Spanish/Extended:		kernel MAKEDRV

kbdn_sp	: Installed/Driver/Keyboard/Spanish/NonExtended
Installed/Driver/Keyboard/Spanish/NonExtended:		kernel MAKEDRV

kbde_sv	: Installed/Driver/Keyboard/Swedish/Extended
Installed/Driver/Keyboard/Swedish/Extended:		kernel MAKEDRV

kbdn_sv	: Installed/Driver/Keyboard/Swedish/NonExtended
Installed/Driver/Keyboard/Swedish/NonExtended:		kernel MAKEDRV

kbdt_sv	: Installed/Driver/Keyboard/Swedish/Typewriter

Installed/Driver/Keyboard/Swedish/Typewriter:		kernel MAKEDRV
kbde_uk	: Installed/Driver/Keyboard/UK/Extended

Installed/Driver/Keyboard/UK/Extended:			kernel MAKEDRV
lbdn_uk	: Installed/Driver/Keyboard/UK/NonExtended
Installed/Driver/Keyboard/UK/NonExtended:		kernel MAKEDRV

t1000	: Installed/Driver/Keyboard/Tandy1000

Installed/Driver/Keyboard/Tandy1000:			kernel MAKEDRV
#mousedrivers
genmouse	: Installed/Driver/Mouse/GenMouse
Installed/Driver/Mouse/GenMouse:	kernel MAKEDRV

absgen	: Installed/Driver/Mouse/AbsGen
Installed/Driver/Mouse/AbsGen:		kernel MAKEDRV

kbmouse	: Installed/Driver/Mouse/KBMouse
Installed/Driver/Mouse/KBMouse:		kernel MAKEDRV

msbus	: Installed/Driver/Mouse/MSBus
Installed/Driver/Mouse/MSBus:		kernel MAKEDRV

msser	: Installed/Driver/Mouse/MSSer
Installed/Driver/Mouse/MSSer:		kernel serial MAKEDRV

logibus	: Installed/Driver/Mouse/LogiBus
Installed/Driver/Mouse/LogiBus:		kernel MAKEDRV

logiser	: Installed/Driver/Mouse/LogiSer
Installed/Driver/Mouse/LogiSer:		kernel serial MAKEDRV

dma	: Installed/Driver/DMA/DOSReal
Installed/Driver/DMA/DOSReal:		kernel MAKEDRV

msys	:  Installed/Driver/Mouse/MSys
Installed/Driver/Mouse/MSys:		kernel serial MAKEDRV

ps2	: Installed/Driver/Mouse/PS2
Installed/Driver/Mouse/PS2:		ui MAKEDRV

imps2	: Installed/Driver/Mouse/imps2
Installed/Driver/Mouse/imps2:		ui MAKEDRV

ctm	: Installed/Driver/Mouse/ctm
Installed/Driver/Mouse/ctm:		ui MAKEDRV

ctmabs	: Installed/Driver/Mouse/ctmabs
Installed/Driver/Mouse/ctmabs:		ui MAKEDRV

# Printer Drivers

deskjet	: Installed/Driver/Printer/HP/Deskjet

Installed/Driver/Printer/HP/Deskjet:	spool MAKEDRV
dj500c	: Installed/Driver/Printer/HP/Dj500c
Installed/Driver/Printer/HP/Dj500c:	spool MAKEDRV

lbp	: Installed/Driver/Printer/HP/Lbp
Installed/Driver/Printer/HP/Lbp:	spool MAKEDRV

mercury	: Installed/Driver/Printer/HP/Mercury
Installed/Driver/Printer/HP/Mercury:	spool MAKEDRV

pcl4	: Installed/Driver/Printer/HP/Pcl4
Installed/Driver/Printer/HP/Pcl4:	spool MAKEDRV

quietjet	: Installed/Driver/Printer/HP/QuietJet
Installed/Driver/Printer/HP/QuietJet:	spool MAKEDRV

canon48	: Installed/Driver/Printer/DotMatrix/Canon48
Installed/Driver/Printer/DotMatrix/Canon48:	spool MAKEDRV

canonbjc	: Installed/Driver/Printer/DotMatrix/CanonBJC
Installed/Driver/Printer/DotMatrix/CanonBJC:	spool MAKEDRV

canonrgb	: Installed/Driver/Printer/DotMatrix/CanonRGB
Installed/Driver/Printer/DotMatrix/CanonRGB:	spool MAKEDRV

epshi24	: Installed/Driver/Printer/DotMatrix/Epshi24
Installed/Driver/Printer/DotMatrix/Epshi24:	spool MAKEDRV

epson24	: Installed/Driver/Printer/DotMatrix/Epson24
Installed/Driver/Printer/DotMatrix/Epson24:	spool MAKEDRV

epson48	: Installed/Driver/Printer/DotMatrix/Epson48
Installed/Driver/Printer/DotMatrix/Epson48:	spool MAKEDRV

escp2	: Installed/Driver/Printer/DotMatrix/Escp2
Installed/Driver/Printer/DotMatrix/Escp2:	spool MAKEDRV

nec24	: Installed/Driver/Printer/DotMatrix/Nec24
Installed/Driver/Printer/DotMatrix/Nec24:	spool MAKEDRV

ppds24	: Installed/Driver/Printer/DotMatrix/Ppds24
Installed/Driver/Printer/DotMatrix/Ppds24:	spool MAKEDRV

tosh24	: Installed/Driver/Printer/DotMatrix/Tosh24
Installed/Driver/Printer/DotMatrix/Tosh24:	spool MAKEDRV

pscript	: Installed/Driver/Printer/PScript
Installed/Driver/Printer/PScript:		spool eps ps2pdf MAKEDRV

dumb	: Installed/Driver/Printer/Ascii/Dumb
Installed/Driver/Printer/Ascii/Dumb:		spool MAKEDRV

diablo	: Installed/Driver/Printer/Ascii/Diablo
Installed/Driver/Printer/Ascii/Diablo:		spool MAKEDRV

citoh9	: Installed/Driver/Printer/DotMatrix/Citoh9
Installed/Driver/Printer/DotMatrix/Citoh9:	spool MAKEDRV

prop9	: Installed/Driver/Printer/DotMatrix/Prop9
Installed/Driver/Printer/DotMatrix/Prop9:	spool MAKEDRV

diconix9	: Installed/Driver/Printer/DotMatrix/Diconix9
Installed/Driver/Printer/DotMatrix/Diconix9:	spool MAKEDRV

eplx9	: Installed/Driver/Printer/DotMatrix/Eplx9
Installed/Driver/Printer/DotMatrix/Eplx9:	spool MAKEDRV

epmx9	: Installed/Driver/Printer/DotMatrix/Epmx9
Installed/Driver/Printer/DotMatrix/Epmx9:	spool MAKEDRV

eprx9	: Installed/Driver/Printer/DotMatrix/Eprx9
Installed/Driver/Printer/DotMatrix/Eprx9:	spool MAKEDRV

bchip9	: Installed/Driver/Printer/DotMatrix/Bchip9
Installed/Driver/Printer/DotMatrix/Bchip9:	spool MAKEDRV

star9	: Installed/Driver/Printer/DotMatrix/Star9
Installed/Driver/Printer/DotMatrix/Star9:	spool MAKEDRV

oki9	: Installed/Driver/Printer/DotMatrix/Oki9
Installed/Driver/Printer/DotMatrix/Oki9:	spool MAKEDRV

grpr9	: Installed/Driver/Printer/DotMatrix/Grpr9
Installed/Driver/Printer/DotMatrix/Grpr9:	spool MAKEDRV

epson9	: Installed/Driver/Printer/DotMatrix/Epson9
Installed/Driver/Printer/DotMatrix/Epson9:	spool MAKEDRV

propx24	: Installed/Driver/Printer/DotMatrix/Propx24
Installed/Driver/Printer/DotMatrix/Propx24:	spool MAKEDRV


#appl

#calendar	: ui text spool config pen
calendar	: Installed/Appl/Calendar
Installed/Appl/Calendar:	ui text spool config MAKEAPPL

geodex	: Installed/Appl/GeoDex
Installed/Appl/GeoDex:	ui text spool impex ssmeta convert \
			mailhub serial MAKEAPPL

geocalc	: Installed/Appl/GeoCalc
Installed/Appl/GeoCalc:		ui spool cell parse math spreadsheet \
				ruler text impex spline grobj chart bitmap \
				MAKEAPPL

geodraw	: Installed/Appl/GeoDraw
Installed/Appl/GeoDraw:		ui spool ruler text spline grobj chart \
				bitmap spell color convert MAKEAPPL

geopoint	: Installed/Appl/GeoPoint
Installed/Appl/GeoPoint:		ui ansic text color MAKEAPPL

geowrite	: Installed/Appl/GeoWrite
Installed/Appl/GeoWrite:	ui spool ruler text spline grobj chart \
				bitmap spell color impex styles ssmeta \
				convert compress MAKEAPPL

banner	: Installed/Appl/Banner
Installed/Appl/Banner:		ui spool MAKEAPPL

geodeck	: Installed/Appl/Art/Decks/GeoDeck
Installed/Appl/Art/Decks/GeoDeck:	MAKEAPPL

scrapbk	: Installed/Appl/ScrapBk
Installed/Appl/ScrapBk:		ui text impex convert MAKEAPPL

bigcalc	: Installed/Appl/BigCalc
Installed/Appl/BigCalc:		ui math parse MAKEAPPL

clock	: Installed/Appl/Clock
Installed/Appl/Clock:		ui color MAKEAPPL

#
# For now we can not remake mailtool or stcache or email
# email: ui text ansic socket spell spool mailtool stacache borlandc
#

email: ui text ansic socket spell spool  borlandc
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Appl/Email/...

manager: Installed/Appl/FileMgrs2/GeoManager
Installed/Appl/FileMgrs2/GeoManager:	ui shell spool MAKEAPPL

isdesk: Installed/Appl/FileMgrs2/ISDesk
Installed/Appl/FileMgrs2/ISDesk:	ui shell spool wav shell MAKEAPPL

sclock:	Installed/Appl/SysTray/SClock
Installed/Appl/SysTray/SClock:		ui MAKEAPPL

linktool: Installed/Library/FMTools/Linktool
Installed/Library/FMTools/Linktool:	ui shell MAKEAPPL

homebase:
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Appl/Breadbox/Homebase/...

newsread: Installed/Appl/Breadbox/NewsRead
Installed/Appl/Breadbox/NewsRead:	ui socket ansic text spool spell \
	 				inetmsg extui parentc idialc \
					MAKEAPPL

ftpc	: Installed/Appl/Breadbox/ftpc
Installed/Appl/Breadbox/ftpc:		ui flllib extui ansic ftplib MAKEAPPL

# Utilities

setup:	Installed/Appl/Preferences/Setup
Installed/Appl/Preferences/Setup:	ui spool config serial parallel MAKEAPPL

launcher: Installed/Appl/Launcher
Installed/Appl/Launcher:	ui MAKEAPPL

prefmgr	: Installed/Appl/Preferences/PrefMgr
Installed/Appl/Preferences/PrefMgr:	ui spool text spell config serial \
					MAKEAPPL

charm	: Installed/Appl/Charm
Installed/Appl/Charm:		ui text ansic MAKEAPPL

wordmat	: Installed/Appl/WordMat
Installed/Appl/WordMat:		ui ansic wmlib MAKEAPPL

# Tools

prntscrn	: Installed/Appl/Tools/PrntScrn
Installed/Appl/Tools/PrntScrn:	ui spool MAKEAPPL

# Games

solitaire	: Installed/Appl/Games/Solitaire
Installed/Appl/Games/Solitaire:	ui cards geodeck wav MAKEAPPL

cword	: Installed/Appl/Games/CWord
Installed/Appl/Games/CWord:	ui wav MAKEAPPL

amateur	: Installed/Appl/Games/Amateur
Installed/Appl/Games/Amateur:	ui sound game MAKEAPPL

bjack	: Installed/Appl/Games/BJack
Installed/Appl/Games/BJack:	ui sound game wav cards MAKEAPPL

gwpoker	: Installed/Appl/Games/GWPoker
Installed/Appl/Games/GWPoker:	ui sound game wav cards MAKEAPPL

hearts	: Installed/Appl/Games/Hearts
Installed/Appl/Games/Hearts:	ui sound wav cards MAKEAPPL

mine	: Installed/Appl/Games/Mine
Installed/Appl/Games/Mine:	ui game MAKEAPPL

pyramid	: Installed/Appl/Games/Pyramid
Installed/Appl/Games/Pyramid:	ui cards MAKEAPPL

sokoban	: Installed/Appl/Games/Sokoban
Installed/Appl/Games/Sokoban:	ui game MAKEAPPL

taipei	: Installed/Appl/Games/Taipei
Installed/Appl/Games/Taipei:	ui game MAKEAPPL

uki	: Installed/Appl/Games/Uki
Installed/Appl/Games/Uki:	ui sound text MAKEAPPL

column	: Installed/Appl/Breadbox/Column
Installed/Appl/Breadbox/Column:	ui game MAKEAPPL




idialup : Installed/Appl/IDialup
Installed/Appl/IDialup:		ui ansic socket accpnt MAKEAPPL

gpcmail : Installed/Appl/GPCMail
Installed/Appl/GPCMail:		ui ansic spell text mailhub mailsmtp \
				mailpop3 config spool idialc MAKEAPPL

bbxmail : Installed/Appl/dil/bbxmail
Installed/Appl/dil/bbxmail:	ui ansic spell text bbxmlib config spool \
				MAKEAPPL

bbxchat : Installed/Appl/Breadbox/BbxChat
Installed/Appl/Breadbox/BbxChat:	ui text ansic socket accpnt parentc \
					MAKEAPPL

bnkr30 : Installed/Appl/Breadbox/Bnkr30
Installed/Appl/Breadbox/Bnkr30:		ui ansic text spool math n2txt MAKEAPPL

hmbase : Installed/Appl/Breadbox/HmBase
Installed/Appl/Breadbox/HmBase:		ui ansic text spool math MAKEAPPL

# Savers

# currently does not make
# album	: Installed/Appl/Saver/Album
#Installed/Appl/Saver/Album:	saver config MAKEAPPL

lol	: Installed/Appl/LOL
Installed/Appl/LOL:		kernel saver MAKEAPPL

blackhole	: 	Installed/Appl/Saver/BlackHole \
			Installed/Appl/Saver/BlackHole/BlackHolePref
Installed/Appl/Saver/BlackHole:			saver config MAKEAPPL
Installed/Appl/Saver/BlackHole/BlackHolePref:	saver config MAKEAPPL

blank	: Installed/Appl/Saver/Blank
Installed/Appl/Saver/Blank:	saver config MAKEAPPL

bobbin	: 	Installed/Appl/Saver/Bobbin \
		Installed/Appl/Saver/Bobbin/BobbinPref
Installed/Appl/Saver/Bobbin: 			saver config MAKEAPPL
Installed/Appl/Saver/Bobbin/BobbinPref:		saver config MAKEAPPL

circles	: 	Installed/Appl/Saver/Circles \
		Installed/Appl/Saver/Circles/CirclesPref
Installed/Appl/Saver/Circles:			saver config MAKEAPPL
Installed/Appl/Saver/Circles/CirclesPref:	saver config MAKEAPPL

dribble	: 	Installed/Appl/Saver/Dribble \
		Installed/Appl/Saver/Dribble/DribblePref
Installed/Appl/Saver/Dribble:			saver config MAKEAPPL
Installed/Appl/Saver/Dribble/DribblePref:	saver config MAKEAPPL

dust	: 	Installed/Appl/Saver/Dust \
		Installed/Appl/Saver/Dust/DustPref
Installed/Appl/Saver/Dust:			saver config MAKEAPPL
Installed/Appl/Saver/Dust/DustPref:		saver config MAKEAPPL

fades	: 	Installed/Appl/Saver/Fades \
		Installed/Appl/Saver/Fades/FadesPref
Installed/Appl/Saver/Fades:			saver config MAKEAPPL
Installed/Appl/Saver/Fades/FadesPref:		saver config MAKEAPPL

flame	: 	Installed/Appl/Saver/Flame \
		Installed/Appl/Saver/Flame/FlamePref
Installed/Appl/Saver/Flame:			saver config MAKEAPPL
Installed/Appl/Saver/Flame/FlamePref:		saver config MAKEAPPL

hopalong	: 	Installed/Appl/Saver/Hopalong \
			Installed/Appl/Saver/Hopalong/HopalongPref
Installed/Appl/Saver/Hopalong:			saver config MAKEAPPL
Installed/Appl/Saver/Hopalong/HopalongPref:	saver config MAKEAPPL

lastwords	: 	Installed/Appl/Saver/LastWords \
			Installed/Appl/Saver/LWPref
Installed/Appl/Saver/LastWords:			saver config MAKEAPPL
Installed/Appl/Saver/LWPref:			saver config MAKEAPPL

letter	: 	Installed/Appl/Saver/Letter \
		Installed/Appl/Saver/Letter/LetterPref
Installed/Appl/Saver/Letter:			saver config MAKEAPPL
Installed/Appl/Saver/Letter/LetterPref:		saver config MAKEAPPL

logo	: Installed/Appl/Saver/Logo
Installed/Appl/Saver/Logo:		saver config MAKEAPPL

maze	: 	Installed/Appl/Saver/Maze \
		Installed/Appl/Saver/Maze/MazePref
Installed/Appl/Saver/Maze:		saver config MAKEAPPL
Installed/Appl/Saver/Maze/MazePref:	saver config MAKEAPPL

melt	: 	Installed/Appl/Saver/Melt \
		Installed/Appl/Saver/Melt/MeltPref
Installed/Appl/Saver/Melt:		saver config MAKEAPPL
Installed/Appl/Saver/Melt/MeltPref:	saver config MAKEAPPL

noodle	: 	Installed/Appl/Saver/Noodle \
		Installed/Appl/Saver/Noodle/NoodlePref
Installed/Appl/Saver/Noodle:		saver config MAKEAPPL
Installed/Appl/Saver/Noodle/NoodlePref:	saver config MAKEAPPL

palette	: 	Installed/Appl/Saver/Palette \
		Installed/Appl/Saver/Palette/PalettePref
Installed/Appl/Saver/Palette:			saver config MAKEAPPL
Installed/Appl/Saver/Palette/PalettePref:	saver config MAKEAPPL

pieces	: 	Installed/Appl/Saver/Pieces \
		Installed/Appl/Saver/Pieces/PiecesPref
Installed/Appl/Saver/Pieces:		saver config MAKEAPPL
Installed/Appl/Saver/Pieces/PiecesPref:	saver config MAKEAPPL

pith	: Installed/Appl/Saver/Pith
Installed/Appl/Saver/Pith:	saver config MAKEAPPL

qix	: 	Installed/Appl/Saver/Qix \
		Installed/Appl/Saver/Qix/QixPref
Installed/Appl/Saver/Qix:		saver config MAKEAPPL
Installed/Appl/Saver/Qix/QixPref:	saver config MAKEAPPL

rotate	: Installed/Appl/Saver/Rotate
Installed/Appl/Saver/Rotate:	saver config MAKEAPPL

sand	: 	Installed/Appl/Saver/Sand \
		Installed/Appl/Saver/Sand/SandPref
Installed/Appl/Saver/Sand:		saver config MAKEAPPL
Installed/Appl/Saver/Sand/SandPref:	saver config MAKEAPPL

spotlight	: 	Installed/Appl/Saver/Spotlight \
			Installed/Appl/Saver/Spotlight/SpotlightPref
Installed/Appl/Saver/Spotlight:			saver config MAKEAPPL
Installed/Appl/Saver/Spotlight/SpotlightPref:	saver config MAKEAPPL
#ifndef	NO_NEC
#	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\Spotlight.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\spotligh.geo
#endif
#ifndef	NO_EC
#	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\Spotlightec.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\spotlighec.geo
#endif
#ifndef	NO_NEC
#	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\SpotlightPref.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\slpref.geo
#endif
#ifndef	NO_EC
#	copy %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\SpotlightPrefEC.geo %ROOT_DIR%\Installed\Appl\Saver\Spotlight\SpotlightPref\slprefec.geo
#endif

stars	: 	Installed/Appl/Saver/Stars \
		Installed/Appl/Saver/Stars/StarsPref
Installed/Appl/Saver/Stars:		saver config MAKEAPPL
Installed/Appl/Saver/Stars/StarsPref:	saver config MAKEAPPL

string	: 	Installed/Appl/Saver/String \
		Installed/Appl/Saver/String/StringPref
Installed/Appl/Saver/String:		saver config MAKEAPPL
Installed/Appl/Saver/String/StringPref:	saver config MAKEAPPL

swarm	: 	Installed/Appl/Saver/Swarm \
		Installed/Appl/Saver/Swarm/SwarmPref
Installed/Appl/Saver/Swarm:		saver config MAKEAPPL
Installed/Appl/Saver/Swarm/SwarmPref:	saver config MAKEAPPL

tickertape	: 	Installed/Appl/Saver/Tickertape \
			Installed/Appl/Saver/Tickertape/TickertapePref
Installed/Appl/Saver/Tickertape:		saver config MAKEAPPL
Installed/Appl/Saver/Tickertape/TickertapePref:	saver config MAKEAPPL

tiles	: 	Installed/Appl/Saver/Tiles \
		Installed/Appl/Saver/Tiles/TilesPref
Installed/Appl/Saver/Tiles:		saver config MAKEAPPL
Installed/Appl/Saver/Tiles/TilesPref:	saver config MAKEAPPL

worms	: 	Installed/Appl/Saver/Worms \
		Installed/Appl/Saver/Worms/WormsPref
Installed/Appl/Saver/Worms:		saver config MAKEAPPL
Installed/Appl/Saver/Worms/WormsPref:	saver config MAKEAPPL


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

tcpip	: Installed/Driver/Socket/TCPIP
Installed/Driver/Socket/TCPIP:	netutils socket ansic resolver accpnt \
				MAKELIB

ppp	: Installed/Driver/Socket/PPP
Installed/Driver/Socket/PPP:	netutils ansic accpnt MAKELIB

# WebMagick app

webmagick	: 	Installed/Appl/Breadbox/BbxBrow
Installed/Appl/Breadbox/BbxBrow:	ui ansic text spool \
					wmg3http wmg3ftp wmg3ext \
					impgraph impdoc \
					modem \
					ibms parentc wav mailhub socket \
					js netutils cookies idialc \
					ppp  tcpip MAKEAPPL

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
#	$(MAKE) -I$(ROOT_DIR)\Appl\Breadbox\bbxbrow full

# webmagick libs

#html3par	: ui ansic text extgraph
#	mdcd %ROOT_DIR%\Installed\Library\Breadbox\html3par
#	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\html3par lib full

html4par	: Installed/Library/Breadbox/Html4Par
Installed/Library/Breadbox/Html4Par:	kernel ui ansic text extgraph MAKELIB

profpnt		: Installed/Library/ProfPnt
Installed/Library/ProfPnt:		ansic MAKELIB

js              : Installed/Library/JS
Installed/Library/JS:		ansic math borlandc mapheap profpnt MAKELIB

ibms    : Installed/Library/Breadbox/Ibms
Installed/Library/Breadbox/Ibms:	ansic MAKELIB

extgraph	: Installed/Library/Breadbox/ExtGraph
Installed/Library/Breadbox/ExtGraph:	ansic MAKELIB

wmg3http	: Installed/Library/Breadbox/UrlDrv/Wmg3Http
Installed/Library/Breadbox/UrlDrv/Wmg3Http:	ansic socket ui ssl netutils \
						cookies MAKELIB

wmg3ftp	: 	Installed/Library/Breadbox/UrlDrv/Wmg3Ftp
Installed/Library/Breadbox/UrlDrv/Wmg3Ftp:	ansic html4par socket ui \
						MAKELIB

wmg3ext	: 	Installed/Library/Breadbox/UrlDrv/Wmg3Ext
Installed/Library/Breadbox/UrlDrv/Wmg3Ext:	ansic ui MAKELIB

cookies : 	Installed/Library/Cookies
Installed/Library/Cookies:			ansic netutils MAKELIB

mapheap :	Installed/Library/MapHeap
Installed/Library/MapHeap:			kernel MAKELIB

ssl	: 	Installed/Library/SSL
Installed/Library/SSL:				ansic socket mapheap MAKELIB

# product-specific dependency on fjpeg
impgraph	: Installed/Library/Breadbox/ImpGraph
Installed/Library/Breadbox/ImpGraph:		ansic ijgjpeg MAKELIB #fjpeg

ijgjpeg	: 	Installed/Library/Breadbox/Ijgjpeg
Installed/Library/Breadbox/Ijgjpeg:		ui ansic MAKELIB

#fjpeg	: 	Installed/Library/Breadbox/fjpeg
#Installed/Library/Breadbox/fjpeg:		ui ansic MAKELIB
#	mdcd %ROOT_DIR%\
#	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\fjpeg lib full

impdoc	: 	Installed/Library/Breadbox/ImpDoc
Installed/Library/Breadbox/ImpDoc:		ui ansic MAKELIB

pdfvu	: 	Installed/Appl/PDFViewer
Installed/Appl/PDFViewer:			ui ansic spool borlandc \
						MAKEAPPL

#wavplay	: Installed/Appl/WavPlay
#Installed/Appl/WavPlay:				ui ansic wav MAKELIB

giflib  : 	Installed/Library/Breadbox/Giflib
Installed/Library/Breadbox/Giflib:		ansic extgraph MAKELIB

#
# GeoZip application & libraries
#
zlib    : 	Installed/Library/Breadbox/zlib
Installed/Library/Breadbox/zlib:		ansic MAKELIB


#if defined(PRODUCT) && $(PRODUCT) == "NDO2000"
#else
dirlist : 	Installed/Library/Breadbox/DirList
Installed/Library/Breadbox/DirList:		ansic ui MAKELIB
#endif

minizip : 	Installed/Library/Breadbox/MiniZip
Installed/Library/Breadbox/MiniZip:		ansic ui zlib MAKELIB

#if defined(PRODUCT) && $(PRODUCT) == "NDO2000"
#else
geozip  : 	Installed/Appl/Breadbox/GEOZIP
Installed/Appl/Breadbox/GEOZIP:			minizip dirlist MAKEAPPL
# endif

#
# PicAlbum application & libraries
#
#photopc : 	Installed/Library/PhotoPC
#Installed/Library/PhotoPC:			streamc ansic MAKEAPPL
#	mdcd %ROOT_DIR%\
#	$(MAKE) -I$(ROOT_DIR)\Library\PhotoPC full

#picalbum : 	Installed/Appl/PicAlbum
#Installed/Appl/PicAlbum:		ui spool ansic extgraph photopc \
					MAKEAPPL

# Geos impex libraries

dib	: 	Installed/Library/Trans/Graphics/Bitmap/Dib
Installed/Library/Trans/Graphics/Bitmap/Dib:	ui ansic impex MAKELIB

msmfile :
#Installed/Library/Trans/Text/MSMFile
#Installed/Library/Trans/Text/MSMFile:		text MAKELIB

bmp	: 	Installed/Library/Trans/Graphics/Bitmap/Bmp
Installed/Library/Trans/Graphics/Bitmap/Bmp:	math dib MAKELIB

clp	: 	Installed/Library/Trans/Graphics/Bitmap/Clp
Installed/Library/Trans/Graphics/Bitmap/Clp:	math dib MAKELIB

ico	: 	Installed/Library/Trans/Graphics/Bitmap/Ico
Installed/Library/Trans/Graphics/Bitmap/Ico:	math dib MAKELIB

pcx	: 	Installed/Library/Trans/Graphics/Bitmap/Pcx
Installed/Library/Trans/Graphics/Bitmap/Pcx:	math dib MAKELIB

tif	: 	Installed/Library/Trans/Graphics/Bitmap/Tif
Installed/Library/Trans/Graphics/Bitmap/Tif:	math dib MAKELIB

#lot123	: 	Installed/Library/Trans/Text/Lotus123
Installed/Library/Trans/Text/Lotus123:		ansic impex msmfile MAKELIB

wordperf5 : 	Installed/Library/Trans/Text/WordPerfect5X
Installed/Library/Trans/Text/WordPerfect5X:	ansic impex msmfile MAKELIB

dbase3	:	Installed/Library/Trans/Database/DBase3
Installed/Library/Trans/Database/DBase3:	ansic impex MAKELIB

dbase4	: 	Installed/Library/Trans/Database/DBase4
Installed/Library/Trans/Database/DBase4:	ansic impex MAKELIB

# Other Geos stuff (not in GPC)
conview	: 	Installed/Library/ConView
Installed/Library/ConView:			ui spool MAKELIB

reader	: 	Installed/Appl/Reader
Installed/Appl/Reader:				ui text conview MAKEAPPL

term	: 	Installed/Appl/Term
Installed/Appl/Term:				ui text MAKEAPPL

tedit	: 	Installed/Appl/TEdit
Installed/Appl/TEdit:				ui text mailbox MAKEAPPL

geofile	: 	Installed/Appl/GeoFile
Installed/Appl/GeoFile:				ui grobj spool parse cell \
						ruler spline math spreadsheet \
	  					text ansic bitmap ffile impex \
						MAKEAPPL

dirls	: Installed/Appl/Breadbox/DirList
Installed/Appl/Breadbox/DirList:		ui ansic text spool MAKEAPPL

bim	: Installed/Appl/Breadbox/BIM
Installed/Appl/Breadbox/BIM:			ui ansic socket sound MAKEAPPL

ffind	: Installed/Appl/Breadbox/FFind
Installed/Appl/Breadbox/FFind:			ui ansic text MAKEAPPL

cdaudio	: Installed/Library/Breadbox/CDAudio
Installed/Library/Breadbox/CDAudio:		ansic MAKELIB

cdados	: Installed/Library/Breadbox/CDADOS
Installed/Library/Breadbox/CDADOS:		kernel MAKELIB

bbxcd	: Installed/Appl/Breadbox/bbxcd
Installed/Appl/Breadbox/bbxcd:			ui ansic sound cdaudio MAKEAPPL

webbox	: Installed/Appl/Breadbox/Webbox
Installed/Appl/Breadbox/Webbox:			ui ansic text spool spell \
						MAKEAPPL

#geocon3	: Installed/Appl/Breadbox/Geocon3
#Installed/Appl/Breadbox/Geocon3:		ui ansic color MAKEAPPL

graphvwr : Installed/Appl/Breadbox/Graphvwr
Installed/Appl/Breadbox/Graphvwr:	ui ansic extui giflib thumbdb ijgjpeg \
					MAKEAPPL

macror	: Installed/Appl/Breadbox/MacroR
Installed/Appl/Breadbox/MacroR:		ui ansic MAKEAPPL

perf	: Installed/Appl/Perf
Installed/Appl/Perf:			ui color MAKEAPPL

dump	: Installed/Appl/Dump
Installed/Appl/Dump:			kernel spool ijgjpeg giflib MAKEAPPL

# Edu Apps
flash	: Installed/Appl/EduApps/Flash
Installed/Appl/EduApps/Flash:		ui ansic text math MAKEAPPL

fontmgck : Installed/Appl/EduApps/Fontmgck
Installed/Appl/EduApps/Fontmgck:	ui ansic text color gsol MAKEAPPL

hangman	: Installed/Appl/EduApps/hangman
Installed/Appl/EduApps/hangman:		ui ansic math wmlib MAKEAPPL

laserl	: Installed/Appl/EduApps/laserl
Installed/Appl/EduApps/laserl:		ui ansic MAKEAPPL

mflash	: Installed/Appl/EduApps/mflash
Installed/Appl/EduApps/mflash:		ui ansic text treplib MAKEAPPL

numbers	: Installed/Appl/EduApps/numbers
Installed/Appl/EduApps/numbers:		ui ansic math MAKEAPPL

pvault	: Installed/Appl/EduApps/pvault
Installed/Appl/EduApps/pvault:		ui ansic MAKEAPPL

taide	: Installed/Appl/EduApps/TAide
Installed/Appl/EduApps/TAide:		ui ansic text math spool basicdb \
					gridlib treplib MAKEAPPL

thinker	: Installed/Appl/EduApps/Thinker
Installed/Appl/EduApps/Thinker:		ui ansic MAKEAPPL

ttype	: Installed/Appl/EduApps/Ttype
Installed/Appl/EduApps/Ttype:		ui ansic text treplib MAKEAPPL

wsm	: Installed/Appl/EduApps/wsm
Installed/Appl/EduApps/wsm:		ui ansic spool MAKEAPPL

wsplay	: Installed/Appl/EduApps/WSPlay
Installed/Appl/EduApps/WSPlay:		ui ansic spool MAKEAPPL

xwm	: Installed/Appl/EduApps/XWM
Installed/Appl/EduApps/XWM:		ui ansic spool compress MAKEAPPL

tgen	: Installed/Appl/EduApps/tgen
Installed/Appl/EduApps/tgen:		ui ansic text math spool basicdb \
					treplib MAKEAPPL

ttkr	: Installed/Appl/EduApps/ttkr
Installed/Appl/EduApps/ttkr:		ui ansic text math basicdb MAKEAPPL

oliner	: Installed/Appl/EduApps/oliner
Installed/Appl/EduApps/oliner:		ui ansic text math spool basicdb \
					treplib spell MAKEAPPL


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

borlandobj : Installed/Library/BorlandRTL
Installed/Library/BorlandRTL:

ndorest:  regis run legos 	\
	  ms3 ntfat int8087 intx87 netware	\
	  irlap loopback slip 		\
	  vid_drivers	\
	  impex_libs bestsnd mp3snd rfsd	\
	  print_drivers extras taskmax cvttool more_prefs	\
	  faxsendtd geosafari slides

ms3     : Installed/Driver/IFS/DOS/MS3
Installed/Driver/IFS/DOS/MS3:			kernel MAKEDRV

ms7     : Installed/Driver/IFS/DOS/MS7
Installed/Driver/IFS/DOS/MS7:			kernel MAKEDRV

netware     : Installed/Driver/IFS/DOS/NETWARE
Installed/Driver/IFS/DOS/NETWARE:		kernel MAKEDRV

rfsd     : Installed/Driver/IFS/RFSD
Installed/Driver/IFS/RFSD:			net ui MAKEDRV

int8087	: Installed/Library/CoProcessor/Int8087
Installed/Library/CoProcessor/Int8087:		kernel math MAKELIB

intx87	: Installed/Library/CoProcessor/Intx87
Installed/Library/CoProcessor/Intx87:		kernel math MAKELIB

taskmax	: Installed/Driver/Task/Taskmax
Installed/Driver/Task/Taskmax:			ui text MAKEDRV

cvttool	: Installed/Library/FMTools/CvtTool
Installed/Library/FMTools/CvtTool:		ui convert MAKELIB

faxsendtd	: Installed/Driver/Mailbox/Transport/Faxsendtd
Installed/Driver/Mailbox/Transport/Faxsendtd:	mailbox faxfile faxctrl ui \
						spool MAKEDRV


# NewDeal socket drivers
irlap		: Installed/Driver/Socket/Irlap
Installed/Driver/Socket/Irlap:			kernel socket serial MAKEDRV

loopback	: Installed/Driver/Socket/Loopback
Installed/Driver/Socket/Loopback:		kernel socket MAKEDRV

slip	: Installed/Driver/Socket/Slip
Installed/Driver/Socket/Slip:			kernel netutils MAKEDRV

# NewDeal video drivers
vid_drivers: kernel ega mcga hgc att6300

ega	: Installed/Driver/Video/VGAlike/EGA
Installed/Driver/Video/VGAlike/EGA:		kernel MAKEDRV

cga	: Installed/Driver/Video/Dumb/CGA
Installed/Driver/Video/Dumb/CGA:		kernel MAKEDRV

dscga	: Installed/Driver/Video/Dumb/DSCGA
Installed/Driver/Video/Dumb/DSCGA:		kernel MAKEDRV

mcga	: Installed/Driver/Video/Dumb/MCGA
Installed/Driver/Video/Dumb/MCGA:		kernel MAKEDRV

hgc	: Installed/Driver/Video/Dumb/HGC
Installed/Driver/Video/Dumb/HGC:		kernel MAKEDRV

# Terminal application
regis	: Installed/Appl/Regis
Installed/Appl/Regis:				ui MAKEAPPL

run	: Installed/Appl/Run
Installed/Appl/Run:				ui MAKEAPPL

sprite	: Installed/Library/Sprite
Installed/Library/Sprite:			ui MAKELIB

tree	: Installed/Library/Tree
Installed/Library/Tree:				ansic MAKELIB

datax	: Installed/Library/DataX
Installed/Library/DataX:			ui MAKELIB

datastore	:  Installed/Library/Datastore
Installed/Library/Datastore:			kernel text datax MAKELIB


# Printer Drivers
#         escp2

#more_savers: lastword spotligh

# Additional Preferences Modules
more_prefs: tweakui hprefcn prefsndn

tweakui	: Installed/Library/Pref/Tweakui
Installed/Library/Pref/Tweakui:			ui config color MAKELIB

hprefcn	: Installed/Library/Pref/Hprefcn
Installed/Library/Pref/Hprefcn:			ui config serial MAKELIB

prefsndn	: Installed/Library/Pref/Prefsndn
Installed/Library/Pref/Prefsndn:		ui ansic config sound MAKELIB

# BestSound - supplemental sound API.
bestsnd	: bsnwav mixlib bsd16 bsd8st bsqp sndchk

bsnwav	: Installed/Library/Audio/BSNWav
Installed/Library/Audio/BSNWav:			kernel MAKELIB

mixlib	: Installed/Library/Audio/MixLib
Installed/Library/Audio/MixLib:			bsnwav sound ui ansic MAKELIB

bsd16	: Installed/Driver/Sound/BSD16
Installed/Driver/Sound/BSD16:			kernel stream MAKEDRV

bsd8st	: Installed/Driver/Sound/BSD8ST
Installed/Driver/Sound/BSD8ST:			kernel stream MAKEDRV

bsqp	: Installed/Appl/Audio/Bsqp
Installed/Appl/Audio/Bsqp:			bsnwav ansic ui MAKEDRV

sndchk	: Installed/Appl/Audio/SndChk
Installed/Appl/Audio/SndChk:			bsnwav wav ansic ui MAKEAPPL

# MP3 - audio format decoder
mp3snd	: kernel mp3 mp3play

mp3	: Installed/Library/Audio/Mp3
Installed/Library/Audio/Mp3:			math ansic MAKELIB

mp3play	: Installed/Appl/Audio/Mp3Play
Installed/Appl/Audio/Mp3Play:			ui sound mp3 MAKEAPPL

# Extras apps
extras : bounce spintext timer

bounce	: Installed/Appl/Bounce
Installed/Appl/Bounce:				ui MAKEAPPL

spintext	: Installed/Appl/Spintext
Installed/Appl/Spintext:			ui MAKEAPPL

timer	: Installed/Appl/Tools/Timer
Installed/Appl/Tools/Timer:			ui text MAKEAPPL

slides	: Installed/Appl/Slides
Installed/Appl/Slides:				ui text impex convert MAKEAPPL
