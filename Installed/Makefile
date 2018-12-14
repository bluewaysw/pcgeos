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

MAKELIB	:	.USE 
#if defined(linux)
	mkdir -p ../$(.TARGET) 
	cd ../$(.TARGET) 
	$(MAKE) -k -I../$(.TARGET) full lib
#else
	mkdir -p ..\$(.TARGET:S/\//\\/g) 
	cd ..\$(.TARGET:S/\//\\/g) 
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full lib
#endif

MAKETOOL:	.USE 
#if defined(linux)
	mkdir -p ../$(.TARGET) 
	cd ../$(.TARGET) 
	$(MAKE) -k -I../$(.TARGET) full 
#else
	mkdir -p ..\$(.TARGET:S/\//\\/g) 
	cd ..\$(.TARGET:S/\//\\/g) 
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full 
#endif

MAKEDRV:	.USE 
#if defined(linux)
	mkdir -p ../$(.TARGET) 
	cd ../$(.TARGET) 
	$(MAKE) -k -I../$(.TARGET) full 
#else
	mkdir -p ..\$(.TARGET:S/\//\\/g) 
	cd ..\$(.TARGET:S/\//\\/g) 
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full 
#endif

MAKEAPPL:	.USE 
#if defined(linux)
	mkdir -p ../$(.TARGET) 
	cd ../$(.TARGET) 
	$(MAKE) -k -I../$(.TARGET) full 
#else
	mkdir -p ..\$(.TARGET:S/\//\\/g) 
	cd ..\$(.TARGET:S/\//\\/g) 
	$(MAKE) -k -I..\$(.TARGET:S/\//\\/g) full 
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

textLoader	:	Installed/Loader/Text
Installed/Loader/Text	:	MAKETOOL

VGALoader	:	Installed/Loader/VGA
Installed/Loader/VGA	: 	MAKETOOL

kernel	:	Installed/Library/Kernel
Installed/Library/Kernel 	:	MAKELIB

swap	:	Installed/Library/Swap
Installed/Library/Swap	:	MAKELIB

sound	: Installed/Library/Sound
Installed/Library/Sound	: stream MAKELIB

# Cannot state true dependency for PCMCIA & Net (they both rely
# upon the UI library), as we would have a circular dependency.

#pcmcia	:	Installed\Library\PCMCIA
#Installed\Library\PCMCIA : MAKELIB

net	:	Installed/Library/Net
Installed/Library/Net :	MAKELIB

# removed pcmcia
ui	: Installed/Library/User
Installed/Library/User	:	sound compress net wav MAKELIB

isui	: Installed/Library/SpecUI/isui
Installed/Library/SpecUI/isui	:	text MAKELIB

motif	: Installed/Library/SpecUI/Motif
Installed/Library/SpecUI/Motif:	text MAKELIB

spool	: Installed/Library/Spool
Installed/Library/Spool:	text MAKELIB

text	: Installed/Library/Text
Installed/Library/Text:	ui styles color ruler bitmap MAKELIB

styles	: Installed/Library/Styles
Installed/Library/Styles:	ui MAKELIB

color	: Installed/Library/Color
Installed/Library/Color: 	ui MAKELIB

mailbox	: Installed/Library/Mailbox
Installed/Library/Mailbox:	ui spool MAKELIB

compress	: Installed/Library/Compress
Installed/Library/Compress:	MAKELIB

ruler	: Installed/Library/Ruler
Installed/Library/Ruler:	ui MAKELIB

bitmap	: Installed/Library/Bitmap
Installed/Library/Bitmap: 	ui MAKELIB

pen	: Installed/Library/Pen
Installed/Library/Pen:	ui text MAKELIB

genpc	: Installed/Library/GDI/GenPC
Installed/Library/GDI/GenPC: MAKELIB

shell	: Installed/Library/Shell
Installed/Library/Shell: 	ui MAKELIB

ansic	: Installed/Library/AnsiC
Installed/Library/AnsiC: math borlandc MAKELIB

cell	: Installed/Library/Cell
Installed/Library/Cell: 	MAKELIB

chart	: Installed/Library/Chart
Installed/Library/Chart:	ui grobj spline text MAKELIB

config	: Installed/Library/Config
Installed/Library/Config: 	ui MAKELIB

grobj	: Installed/Library/GrObj
Installed/Library/GrObj:	ui text bitmap ruler spline color \
				styles impex MAKELIB

hash	: Installed/Library/Hash
Installed/Library/Hash:	MAKELIB	

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
INstalled/Library/Breadbox/Impex/RTF: 	ui impex text ansic MAKELIB

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

htmlpars : Installed/Library/BreadBox/HtmlPars
Installed/Library/BreadBox/HtmlPars: ansic text MAKELIB

htmlimpx : Installed/Library/Trans/Web/HtmlImpx
Installed/Library/Trans/Web/HtmlImpx: htmlpars ansic text impex ui MAKELIB

sstor	: Installed/Library/Breadbox/SStor
Installed/Library/Breadbox/SStor: 	ansic MAKELIB

wfwlib	: Installed/Library/Breadbox/Impex/WFWLib
Installed/Library/Breadbox/Impex/WFWLib:	text ansic sstor MAKELIB

winword8 : Installed/Library/Breadbox/Impex/WinWord8
Installed/Library/Breadbox/Impex/WinWord8: impex ansic text sstor wfwlib MAKELIB

borlandrtl	:
#	No need to do this because this is sync'ed by morning make script.
#	p4 sync -f //depot/pcgeos/Installed/Library/BorlandRTL/...

borlandc	: Installed/Library/Math/Compiler/BorlandC
Installed/Library/Math/Compiler/BorlandC: math MAKELIB

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
Installed/Library/Wav:	sound bsnwav MAKELIB

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
Installed/Library/Breadbox/ps2pdf:	ansic MAKELIB

socket	: Installed/Library/Socket
Installed/Library/Socket:	ui netutils MAKELIB

dhcp	: Installed/Library/dhcp
Installed/Library/dhcp:	socket ui accpnt MAKELIB

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

mailhub : Installed/Library/Mail/MailHub
Installed/Library/Mail/MailHub:	socket ansic MAKELIB

bbxmlib	: Installed/Library/dil/bbxmail
Installed/Library/dil/bbxmail:	socket ansic MAKELIB

mailsmtp : Installed/Library/Mail/MailSMTP
Installed/Library/Mail/MailSMTP:	socket ansic mailhub MAKELIB

mailpop3 : Installed/Library/Mail/MailPOP3
Installed/Library/Mail/MailPOP3:	socket ansic mailhub MAKELIB

#bckrst : Installed/Library/BckRst
#Installed/Library/BckRst: 	ui ansic MAKELIB

filestr	: Installed/Driver/Stream/Filestr
Installed/Driver/Stream/Filestr:	stream MAKEDRV

nonts	: Installed/Driver/Task/NonTS
Installed/Driver/Task/NonTS:	MAKEDRV

sblaster	: Installed/Driver/Sound/SoundBlaster
Installed/Driver/Sound/SoundBlaster:	stream MAKEDRV

comm	: Installed/Driver/Net/Comm
Installed/Driver/Net/Comm:	net MAKEDRV

spooltd	: Installed/Driver/Mailbox/Transport/SpoolTD
Installed/Driver/Mailbox/Transport/SpoolTD:	ui mailbox spool MAKEDRV

vmtree	: Installed/Driver/Mailbox/Data/VMTree
Installed/Driver/Mailbox/Data/VMTree:	mailbox MAKEDRV

filedd	: Installed/Driver/Mailbox/Data/FileDD
Installed/Driver/Mailbox/Data/FileDD:	mailbox serial MAKEDRV

parentc : Installed/Library/ParentC
Installed/Library/ParentC:	ui config MAKELIB

wmlib	: Installed/Library/Breadbox/WMLib
Installed/Library/Breadbox/WMLib:	ansic compress MAKELIB

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

thumbdb : Installed/Library/Breadbox/Thumbdb
Installed/Library/Breadbox/Thumbdb:	ansic MAKELIB

# the EduApp libs
basicdb : Installed/Library/Breadbox/Basicdb
Installed/Library/Breadbox/Basicdb:	ansic MAKELIB

gridlib : Installed/Library/Breadbox/Gridlib
Installed/Library/Breadbox/Gridlib:	ui ansic text MAKELIB

treplib : Installed/Library/Breadbox/Treplib
Installed/Library/Breadbox/Treplib:	ui ansic text spool MAKELIB

gsol	: Installed/Library/Breadbox/Gsol
Installed/Library/Breadbox/Gsol:	ansic MAKELIB

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

prefpntc	: Installed/Library/Pref/Prefpntc
Installed/Library/Pref/Prefpntc:	ui config parentc MAKELIB


#driver

stream	: Installed/Driver/Stream
Installed/Driver/Stream:		kernel MAKEDRV

nimbus	: Installed/Driver/Font/Nimbus
Installed/Driver/Font/Nimbus:		MAKEDRV

ms4	: Installed/Driver/IFS/DOS/MS4
Installed/Driver/IFS/DOS/MS4:		MAKEDRV

os2	: Installed/Driver/IFS/DOS/OS2
Installed/Driver/IFS/DOS/OS2:		MAKEDRV

ntfat	: Installed/Driver/IFS/DOS/NTFat
Installed/Driver/IFS/DOS/NTFat:		MAKEDRV

dri	: Installed/Driver/IFS/DOS/DRI
Installed/Driver/IFS/DOS/DRI:		MAKEDRV

mslf	: Installed/Driver/IFS/DOS/MSLF
Installed/Driver/IFS/DOS/MSLF:		MAKEDRV

cdrom     : Installed/Driver/IFS/DOS/CDROM
Installed/Driver/IFS/DOS/CDROM:		MAKEDRV

gdi	: Installed/Driver/Keyboard/GDI
Installed/Driver/Keyboard/GDI:		genpc MAKEDRV

msnet     : Installed/Driver/IFS/DOS/MSNet
Installed/Driver/IFS/DOS/MSNet:		MAKEDRV

keyboard	: Installed/Driver/Keyboard
Installed/Driver/Keyboard:		MAKEDRV

modem	: Installed/Driver/Modem
Installed/Driver/Modem:			MAKEDRV

gdipointer	: Installed/Driver/Mouse/GDIPointer
Installed/Driver/Mouse/GDIPointer:	MAKEDRV

standard	: Installed/Driver/Sound/Standard
Installed/Driver/Sound/Standard:	MAKEDRV

winnt	: Installed/Driver/Sound/WinNT
Installed/Driver/Sound/WinNT:		MAKEDRV

parallel	: Installed/Driver/Stream/Parallel
Installed/Driver/Stream/Parallel:	stream MAKEDRV

serial	: Installed/Driver/Stream/Serial
Installed/Driver/Stream/Serial:		stream MAKEDRV

disk	: Installed/Driver/Swap/Disk
Installed/Driver/Swap/Disk:		MAKEDRV

emm	: Installed/Driver/Swap/EMS/EMM
Installed/Driver/Swap/EMS/EMM:		MAKEDRV

extmem	: Installed/Driver/Swap/ExtMem
Installed/Driver/Swap/ExtMem:		MAKEDRV

xms	: Installed/Driver/Swap/XMS
Installed/Driver/Swap/XMS:		MAKEDRV

att6300	: Installed/Driver/Video/Dumb/ATT6300
Installed/Driver/Video/Dumb/ATT6300:	MAKEDRV

vidmem	: Installed/Driver/Video/Dumb/VidMem
Installed/Driver/Video/Dumb/VidMem:	MAKEDRV

svga	: Installed/Driver/Video/VGAlike/SVGA
Installed/Driver/Video/VGAlike/SVGA:	MAKEDRV

vga	: Installed/Driver/Video/VGAlike/VGA
Installed/Driver/Video/VGAlike/VGA:	MAKEDRV

vga8	: Installed/Driver/Video/VGAlike/VGA8
Installed/Driver/Video/VGAlike/VGA8:	MAKEDRV

vga16	: Installed/Driver/Video/VGAlike/VGA16
Installed/Driver/Video/VGAlike/VGA16:	MAKEDRV

etherodi	: Installed/Driver/Socket/EtherODI
Installed/Driver/Socket/EtherODI:	socket accpnt MAKEDRV

# International Keyboard Drivers
kbd_drivers : kbdb_cf kbde_cf kbd_csa kbde_df kbdn_df kbde_be kbd_dvrk  \
	kbde_fr kbdn_fr kps1_fr kbde_sf kbde_gr kbdn_gr kbde_sg        	\
	kbdn_sg kbde_it kbdn_it kbde_no kbdn_no kbde_po kbde_sp kbdn_sp	\
	kbde_sv kbdn_sv kbdt_sv kbde_uk lbdn_uk t1000

kbd_dvrk	: Installed/Driver/Keyboard/Dvorak
Installed/Driver/Keyboard/Dvorak:	MAKEDRV

kbdb_cf	: Installed/Driver/Keyboard/Canadian/Bilingual
Installed/Driver/Keyboard/Canadian/Bilingual:	MAKEDRV

kbde_cf	: Installed/Driver/Keyboard/Canadian/FrenchExtended
Installed/Driver/Keyboard/Canadian/FrenchExtended:	MAKEDRV

kbd_csa	: Installed/Driver/Keyboard/Canadian/CSA-z243.200-91
Installed/Driver/Keyboard/Canadian/CSA-z243.200-91:	MAKEDRV

kbde_df	: Installed/Driver/Keyboard/Danish/Extended
Installed/Driver/Keyboard/Danish/Extended:		MAKEDRV

kbdn_df	: Installed/Driver/Keyboard/Danish/NonExtended
Installed/Driver/Keyboard/Danish/NonExtended:		MAKEDRV

kbde_be	: Installed/Driver/Keyboard/Dutch/Extended
Installed/Driver/Keyboard/Dutch/Extended:		MAKEDRV

kbde_fr	: Installed/Driver/Keyboard/French/Extended
Installed/Driver/Keyboard/French/Extended:		MAKEDRV

kbdn_fr	: Installed/Driver/Keyboard/French/NonExtended
Installed/Driver/Keyboard/French/NonExtended:		MAKEDRV

kps1_fr	: Installed/Driver/Keyboard/French/Ps1
Installed/Driver/Keyboard/French/Ps1:			MAKEDRV

kbde_sf : Installed/Driver/Keyboard/French/SwissExtended
Installed/Driver/Keyboard/French/SwissExtended:		MAKEDRV

kbde_gr : Installed/Driver/Keyboard/German/Extended
Installed/Driver/Keyboard/German/Extended:		MAKEDRV

kbdn_gr : Installed/Driver/Keyboard/German/NonExtended
Installed/Driver/Keyboard/German/NonExtended:		MAKEDRV

kbde_sg	: Installed/Driver/Keyboard/German/SwissExtended
Installed/Driver/Keyboard/German/SwissExtended:		MAKEDRV

kbdn_sg	: Installed/Driver/Keyboard/German/SwissNonExtended
Installed/Driver/Keyboard/German/SwissNonExtended :	MAKEDRV

kbde_it	: Installed/Driver/Keyboard/Italian/Extended
Installed/Driver/Keyboard/Italian/Extended:		MAKEDRV

kbdn_it	: Installed/Driver/Keyboard/Italian/NonExtended
Installed/Driver/Keyboard/Italian/NonExtended:		MAKEDRV

kbde_no	: Installed/Driver/Keyboard/Norwegian/Extended
Installed/Driver/Keyboard/Norwegian/Extended:		MAKEDRV

kbdn_no	: Installed/Driver/Keyboard/Norwegian/NonExtended
Installed/Driver/Keyboard/Norwegian/NonExtended:	MAKEDRV

kbde_po	: Installed/Driver/Keyboard/Portuguese/Extended
Installed/Driver/Keyboard/Portuguese/Extended:		MAKEDRV

kbde_sp	: Installed/Driver/Keyboard/Spanish/Extended
Installed/Driver/Keyboard/Spanish/Extended:		MAKEDRV

kbdn_sp	: Installed/Driver/Keyboard/Spanish/NonExtended
Installed/Driver/Keyboard/Spanish/NonExtended:		MAKEDRV

kbde_sv	: Installed/Driver/Keyboard/Swedish/Extended
Installed/Driver/Keyboard/Swedish/Extended:		MAKEDRV

kbdn_sv	: Installed/Driver/Keyboard/Swedish/NonExtended
Installed/Driver/Keyboard/Swedish/NonExtended:		MAKEDRV

kbdt_sv	: Installed/Driver/Keyboard/Swedish/Typewriter
Installed/Driver/Keyboard/Swedish/Typewriter:		MAKEDRV

kbde_uk	: Installed/Driver/Keyboard/UK/Extended
Installed/Driver/Keyboard/UK/Extended:			MAKEDRV

lbdn_uk	: Installed/Driver/Keyboard/UK/NonExtended
Installed/Driver/Keyboard/UK/NonExtended:		MAKEDRV

t1000	: Installed/Driver/Keyboard/Tandy1000
Installed/Driver/Keyboard/Tandy1000:			MAKEDRV

#mousedrivers
genmouse	: Installed/Driver/Mouse/GenMouse
Installed/Driver/Mouse/GenMouse:	MAKEDRV

absgen	: Installed/Driver/Mouse/AbsGen
Installed/Driver/Mouse/AbsGen:		MAKEDRV

kbmouse	: Installed/Driver/Mouse/KBMouse
Installed/Driver/Mouse/KBMouse:		MAKEDRV

msbus	: Installed/Driver/Mouse/MSBus
Installed/Driver/Mouse/MSBus:		MAKEDRV

msser	: Installed/Driver/Mouse/MSSer
Installed/Driver/Mouse/MSSer:		serial MAKEDRV

logibus	: Installed/Driver/Mouse/LogiBus
Installed/Driver/Mouse/LogiBus:		MAKEDRV

logiser	: Installed/Driver/Mouse/LogiSer
Installed/Driver/Mouse/LogiSer:		serial MAKEDRV

dma	: Installed/Driver/DMA/DOSReal
Installed/Driver/DMA/DOSReal:		MAKEDRV

msys	:  Installed/Driver/Mouse/MSys
Installed/Driver/Mouse/MSys:		serial MAKEDRV

ps2	: Installed/Driver/Mouse/PS2
Installed/Driver/Mouse/PS2:		ui MAKEDRV

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

pscript	: Installed\Driver\Printer\PScript
Installed\Driver\Printer\PScript:		spool eps ps2pdf MAKEDRV

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
#	p4 sync -f //depot/pcgeos/Appl/BreadBox/Homebase/...

newsread: Installed/Appl/BreadBox/NewsRead
Installed/Appl/BreadBox/NewsRead:	ui socket ansic text spool spell \
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

bjack	: Installed/Appl/Games/Bjack
Installed/Appl/Games/Bjack:	ui sound game wav cards MAKEAPPL

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
Installed/Appl/LOL:		saver MAKEAPPL

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

logo	: Installed/Appl/Saver/logo
Installed/Appl/Saver/logo:		saver config MAKEAPPL

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
Installed/Appl/Saver/Stars7StarsPref:	saver config MAKEAPPL

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
Installed\Appl\Saver\Worms:		saver config MAKEAPPL
Installed\Appl\Saver\Worms\WormsPref:	saver config MAKEAPPL


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

webmagick	: 	Installed/Appl/Breadbox/bbxbrow/JS \
			Installed/Appl/Breadbox/bbxbrow/AB \
			Installed/Appl/Breadbox/bbxbrow
Installed/Appl/Breadbox/bbxbrow/JS:	ui ansic text spool html4par \
		  			wmg3http wmg3ftp wmg3ext \
		  			impgraph impdoc \
		  			tcpip ppp modem \
                  			ibms parentc wav mailhub socket \
                  			js netutils cookies idialc MAKEAPPL
Installed/Appl/Breadbox/bbxbrow/AB:	ui ansic text spool html4par \
		  			wmg3http wmg3ftp wmg3ext \
		  			impgraph impdoc \
		  			tcpip ppp modem \
                  			ibms parentc wav mailhub socket \
                  			js netutils cookies idialc MAKEAPPL
Installed/Appl/Breadbox/bbxbrow:	ui ansic text spool html4par \
		  			wmg3http wmg3ftp wmg3ext \
		  			impgraph impdoc \
		  			tcpip ppp modem \
                  			ibms parentc wav mailhub socket \
                  			js netutils cookies idialc MAKEAPPL

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

profpnt		: Installed/Library/profpnt
Installed/Library/profpnt:		ansic MAKELIB

js              : Installed/Library/js
Installed/Library/js:		ansic math borlandc mapheap profpnt MAKELIB

ibms    : Installed/Library/Breadbox/ibms
Installed/Library/Breadbox/ibms:	ansic MAKELIB

extgraph	: Installed/Library/Breadbox/extgraph
Installed/Library/Breadbox/extgraph:	ansic MAKELIB

wmg3http	: Installed/Library/Breadbox/urldrv/wmg3http
Installed/Library/Breadbox/urldrv/wmg3http:	ansic socket ui ssl netutils \
						cookies MAKELIB

wmg3ftp	: 	Installed/Library/Breadbox/urldrv/wmg3ftp
Installed/Library/Breadbox/urldrv/wmg3ftp:	ansic html4par socket ui \
						MAKELIB

wmg3ext	: 	Installed/Library/Breadbox/urldrv/wmg3ext
Installed/Library/Breadbox/urldrv/wmg3ext:	ansic ui MAKELIB

cookies : 	Installed/Library/Cookies
Installed/Library/Cookies:			ansic netutils MAKELIB

mapheap :	Installed/Library/MapHeap
Installed/Library/MapHeap:			MAKELIB

ssl	: 	Installed/Library/ssl
Installed/Library/ssl:				ansic socket mapheap MAKELIB

# product-specific dependency on fjpeg
impgraph	: Installed/Library/Breadbox/impgraph
Installed/Library/Breadbox/impgraph:		ansic ijgjpeg MAKELIB #fjpeg

ijgjpeg	: 	Installed/Library/Breadbox/ijgjpeg
Installed/Library/Breadbox/ijgjpeg:		ui ansic MAKELIB

#fjpeg	: 	Installed/Library/Breadbox/fjpeg
#Installed/Library/Breadbox/fjpeg:		ui ansic MAKELIB
#	mdcd %ROOT_DIR%\
#	$(MAKE) -I$(ROOT_DIR)\Library\Breadbox\fjpeg lib full

impdoc	: 	Installed/Library/Breadbox/impdoc
Installed/Library/Breadbox/impdoc:		ui ansic MAKELIB

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
dirlist : 	Installed/Library/Breadbox/dirlist
Installed/Library/Breadbox/dirlist:		ansic ui MAKELIB
#endif

minizip : 	Installed/Library/Breadbox/minizip
Installed/Library/Breadbox/minizip:		ansic ui zlib MAKELIB

#if defined(PRODUCT) && $(PRODUCT) == "NDO2000"
#else
geozip  : 	Installed/Appl/BreadBox/GEOZIP
Installed/Appl/BreadBox/GEOZIP:			minizip dirlist MAKEAPPL
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

msmfile : 	Installed/Library/Trans/Text/MSMFile
Installed/Library/Trans/Text/MSMFile:		text MAKELIB

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
conview	: 	Installed/Library/Conview
Installed/Library/Conview:			ui spool MAKELIB

reader	: 	Installed/Appl/Reader	
Installed/Appl/Reader:				ui text conview MAKEAPPL

term	: 	Installed/Appl/Term
Installed/Appl/Term:				ui text MAKEAPPL

tedit	: 	Installed/Appl/Tedit
Installed/Appl/Tedit:				ui text mailbox MAKEAPPL

geofile	: 	Installed/Appl/Geofile
Installed/Appl/Geofile:				ui grobj spool parse cell \
						ruler spline math spreadsheet \
	  					text ansic bitmap ffile impex \
						MAKEAPPL

dirls	: Installed/Appl/Breadbox/Dirlist
Installed/Appl/Breadbox/Dirlist:		ui ansic text spool MAKEAPPL

bim	: Installed/Appl/Breadbox/bim
Installed/Appl/Breadbox/bim:			ui ansic socket sound MAKEAPPL

ffind	: Installed/Appl/Breadbox/Ffind
Installed/Appl/Breadbox/Ffind:			ui ansic text MAKEAPPL

cdaudio	: Installed/Library/Breadbox/CDAudio
Installed/Library/Breadbox/CDAudio:		MAKELIB

cdados	: Installed/Library/Breadbox/Cdados
Installed/Library/Breadbox/Cdados:		MAKELIB

bbxcd	: Installed/Appl/Breadbox/Bbxcd
Installed/Appl/Breadbox/Bbxcd:			ui ansic sound cdaudio MAKEAPPL

webbox	: Installed/Appl/Breadbox/Webbox	
Installed/Appl/Breadbox/Webbox:			ui ansic text spool spell
						MAKEAPPL

#geocon3	: Installed/Appl/Breadbox/Geocon3
#Installed/Appl/Breadbox/Geocon3:		ui ansic color MAKEAPPL

graphvwr : Installed/Appl/Breadbox/Graphvwr
Installed/Appl/Breadbox/Graphvwr:	ui ansic extui giflib thumbdb ijgjpeg \
					MAKEAPPL

macror	: Installed/Appl/Breadbox/Macror
Installed/Appl/Breadbox/Macror:		ui ansic MAKEAPPL

perf	: Installed/Appl/Perf		
Installed/Appl/Perf:			ui color MAKEAPPL

dump	: Installed/Appl/Dump
Installed/Appl/Dump:			spool ijgjpeg giflib MAKEAPPL

# Edu Apps
flash	: Installed/Appl/EduApps/flash
Installed/Appl/EduApps/flash:		ui ansic text math MAKEAPPL

fontmgck : Installed/Appl/EduApps/fontmgck
Installed/Appl/EduApps/fontmgck:	ui ansic text color gsol MAKEAPPL

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

taide	: Installed/Appl/EduApps/taide
Installed/Appl/EduApps/taide:		ui ansic text math spool basicdb \
					gridlib treplib MAKEAPPL

thinker	: Installed/Appl/EduApps/thinker
Installed/Appl/EduApps/thinker:		ui ansic MAKEAPPL

ttype	: Installed/Appl/EduApps/Ttype
Installed/Appl/EduApps/Ttype:		ui ansic text treplib MAKEAPPL

wsm	: Installed/Appl/EduApps/wsm
Installed/Appl/EduApps/wsm:		ui ansic spool MAKEAPPL

wsplay	: Installed/Appl/EduApps/wsplay
Installed/Appl/EduApps/wsplay:		ui ansic spool MAKEAPPL

xwm	: Installed/Appl/EduApps/xwm
Installed/Appl/EduApps/xwm:		ui ansic spool compress MAKEAPPL

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
Installed/Driver/IFS/DOS/MS3:			MAKEDRV

ms7     : Installed/Driver/IFS/DOS/MS7
Installed/Driver/IFS/DOS/MS7:			MAKEDRV

netware     : Installed/Driver/IFS/DOS/NETWARE
Installed/Driver/IFS/DOS/NETWARE:		MAKEDRV

rfsd     : Installed/Driver/IFS/RFSD
Installed/Driver/IFS/RFSD:			net ui MAKEDRV

int8087	: Installed/Library/CoProcessor/Int8087
Installed/Library/CoProcessor/Int8087:		math MAKELIB

intx87	: Installed/Library/CoProcessor/Intx87
Installed/Library/CoProcessor/Intx87:		math MAKELIB

taskmax	: Installed/Driver/Task/Taskmax
Installed/Driver/Task/Taskmax:			ui text MAKEDRV

cvttool	: Installed/Library/FMTools/CvtTool
Installed/Library/FMTools/CvtTool:		ui convert MAKELIB

faxsendtd	: Installed/Driver/Mailbox/Transport/Faxsendtd
Installed/Driver/Mailbox/Transport/Faxsendtd:	mailbox faxfile faxctrl ui \
						spool MAKEDRV


# NewDeal socket drivers
irlap		: Installed/Driver/Socket/Irlap
Installed/Driver/Socket/Irlap:			socket serial MAKEDRV

loopback	: Installed/Driver/Socket/Loopback
Installed/Driver/Socket/Loopback:		socket MAKEDRV

slip	: Installed/Driver/Socket/Slip
Installed/Driver/Socket/Slip:			netutils MAKEDRV

# NewDeal video drivers
vid_drivers: ega mcga hgc att6300

ega	: Installed/Driver/Video/VGAlike/EGA
Installed/Driver/Video/VGAlike/EGA:		MAKEDRV

cga	: Installed/Driver/Video/Dumb/CGA
Installed/Driver/Video/Dumb/CGA:		MAKEDRV

dscga	: Installed/Driver/Video/Dumb/DSCGA
Installed/Driver/Video/Dumb/DSCGA:		MAKEDRV

mcga	: Installed/Driver/Video/Dumb/MCGA
Installed/Driver/Video/Dumb/MCGA:		MAKEDRV

hgc	: Installed/Driver/Video/Dumb/HGC
Installed/Driver/Video/Dumb/HGC:		MAKEDRV

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
Installed/Library/Datastore:			text datax MAKELIB


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
Installed/Driver/Sound/BSD16:			stream MAKEDRV

bsd8st	: Installed/Driver/Sound/BSD8ST
Installed/Driver/Sound/BSD8ST:			stream MAKEDRV

bsqp	: Installed/Appl/Audio/Bsqp
Installed/Appl/Audio/Bsqp:			bsnwav ansic ui MAKEDRV

sndchk	: Installed/Appl/Audio/SndChk
Installed/Appl/Audio/SndChk:			bsnwav wav ansic ui MAKEAPPL

# MP3 - audio format decoder
mp3snd	: mp3 mp3play

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
