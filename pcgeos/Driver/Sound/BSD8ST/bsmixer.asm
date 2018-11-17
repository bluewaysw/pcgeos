COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved


 THE MIXER FUNCTIONS ARE NOT PART OF THE LICENSING CONTRACT
 BETWEEN NEWDEAL INC. AND DIRK LAUSECKER !
 THE COMMENTS WILL BE FULLY TRANSLATED WHEN THE MIXER FEATURE
 WAS LICENSED BY NEWDEAL OR OTHER COMPANIES !


PROJECT:	BestSound

DATEI:		bsmixer.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	06.10.98	Init
        DL	20.02.2000	NewWave (bsRecordState -> bsStatus)

ROUTINEN:
	Name			Description
	----			-----------
	BSMixerGetCap		Anzahl Einstellkanaele
	BSMixerGetValue		Einstellwert abfragen
        BSMixerSetValue		Einstellwert setzen
        BSMixerSetDefault	Defaultwerte setzen
        BSMixerReset		Mixerchip resetten

Beschreibung:
	Routinen zum Ansteuern des Mixerchips.

*****************************************************************/@

VAL_LEN		equ	12

idata           segment

	bsMixerValMax		word	1h	; Anzahl Values
        valTabOffs		word	0	; Offset valueTable
	subTabOffs		word	0	; Offset subTokenTable

idata           ends

LoadableCode            segment resource


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	GetOffToValTab
;
; Offset zur ValueTable zurÅck
;
;  IN:	[valTabOffs]	Offset valueTable
;  	[subTabOffs]	Offset subTokenTable
;
; OUT:	bx  Offset zur valueTable
;	cx  Offset zur subTokenTable
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GetOffToValTab	proc	far
	uses	ax,dx,di
        .enter
	mov	ax,segment dgroup
        mov	ds,ax

; Pointer testen

        mov	bx,ds:[valTabOffs]
        mov	cx,ds:[subTabOffs]
        tst	bx			; valueTable gesetzt ?
        jne	done			; ja, fertig

; Pointer neu setzen

;-------------------------
; Warten bis DSP frei ist
;-------------------------
teststream:
	tst	ds:[dacStatus]		; DAC frei ?
        jz	testrecording		; ja
; Warten
	mov	ax,10
        call	TimerSleep		; warten
        jmp	teststream

;------------------
; Rec/Play testen
;------------------
testrecording:
	tst	ds:[bsStatus]		; Rec/Play im Gange ?
        jz	getversion		; nein, weiter

; Warten
	mov	ax,10
        call	TimerSleep		; warten
        jmp	testrecording

getversion:
	call	BSGetDSPVersion

        mov	di,offset mixerSuperTable
        mov	ax,ds:[DSPVersion]	; DSP Version

        cmp	ax,400h			; SB 16 ?
        jae	select			; ja
        add	di,4			; Zeiger weiter

        cmp	ax,201h			; SB Pro
        jae	select			; ja
        add	di,4			; Zeiger weiter

        cmp	ax,200h			; SB 2.0 CD
        jae	select			; ja
        add	di,4			; Zeiger weiter

; Pointer holen/speichern
select:
	mov	bx,cs:[di]		; valueTable
        inc	di
        inc	di
	mov	cx,cs:[di]		; SubtokenTable
        mov	ds:[valTabOffs],bx
        mov	ds:[subTabOffs],cx

; Pointer zurÅckgeben
done:
                .leave
                ret

GetOffToValTab	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerGetCap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Einstellkanaele (Values) ermitteln

Aufrufer:	Mixerlibrary

IN:

OUT:            cx      Anzahl Kanaele
		dx	DSP-Version
		CF=1 	Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	06.10.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerGetCap proc    far
	uses    ax,bx,ds		;PUSH ax, ...
	.enter

	mov	ax,segment dgroup
        mov	ds,ax

;	WARNING	MIXER_GET_CAP

        clr	ds:[valTabOffs]

; Zeiger neu berechnen lassen

	call	GetOffToValTab

; Valuetable abzÑhlen
        clr	ds:[bsMixerValMax]
next:
        tst	cs:[bx]			; Ende ?
        jz	done			; ja
        add	bx,VAL_LEN
        inc	ds:[bsMixerValMax]
        jmp	short next

;-----------------
;     ENDE
; bsMixerValMax
;-----------------
done:
        mov	cx,ds:[bsMixerValMax]	; Test
        mov	dx,ds:[DSPVersion]
	.leave
        ret

BSMixerGetCap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerGetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Kanal lesen

Aufrufer:	Mixerlibrary

IN:		dx	Token

OUT:            ax      Wert
		CF=1 	Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	08.10.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerGetValue proc    far
	uses    bx,cx,dx,si,di		;PUSH ax, ...
	.enter

; Token in TokenRegTable suchen

        mov     ax,0		; fuer Fehlerfall
        mov	cx,dx		; Token
        call	TokenToIndex	; di = Index
	jc      error		; Fehler

        add	bx,4		; Typ
        mov	dh,cs:[bx]	; Valuetyp

        add	bx,4		; Offset 1
        mov	di,bx

; Parameter auslesen

	mov	dl,cs:[di]
        inc	di
        mov	bl,cs:[di]		; Bitmask
        inc	di
        push	dx
        call	BSMixerGetRegister	; Links
	pop	dx			; dh = Valuetyp
	mov	bh,al			; Wert retten

; zweiten Parameter (Rechts) schreiben wenn definiert

	mov	dl,cs:[di]
        cmp	dl,0			; leer ?
        je	done			; ja, Abbruch
        inc	di
        mov	bl,cs:[di]		; Bitmask
        call	BSMixerGetRegister	; Rechts
	mov	ah,al			; ah = 2. Wert
        mov	al,bh			; al = 1. Wert

;-----------------
;	ENDE
;-----------------
done:
        clc
error:
	.leave
        ret

BSMixerGetValue	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Mixerkanal beschreiben

Aufrufer:	Mixerlibrary

IN:		dx	Token	0 = Reset
		al	Wert L
                ah	Wert R

OUT:            CF=1 	Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	08.10.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerSetValue proc    far
	uses    ax,bx,cx,dx,di,si		;PUSH ax, ...
	.enter

;        call	SysEnterInterrupt	; LA 18.10.99 deaktiviert

; Reset
; (irgendeinen Wert in Register 00 schreiben)

        tst	dx		; Reset ?
        jnz	tsearch		; nein
	mov	dh,2		; keine Korrektur
        mov	ah,1		; Bitmaske
	call	BSMixerSetRegister
        jmp	done		; Ende

; Token in TokenRegTable suchen
tsearch:
        mov	cx,dx		; Token
        call	TokenToIndex	; di = Index
	jc      error		; Fehler

        add	bx,4		; Zeiger auf Typ
				; (Boolean darf nicht korr. werden)
        mov	dh,cs:[bx]	; Valuetyp

        add	bx,4		; Zeiger auf Offset1
        mov	cx,ax		; Wert L,R

; Parameter auslesen

	mov	dl,cs:[bx]	; Register
        inc	bx
        mov	ah,cs:[bx]	; Bitmaske
        inc	bx
        mov	al,cl		; Wert L
        call	BSMixerSetRegister	; ausgeben

; zweiten Parameter (Rechts) schreiben wenn definiert

	mov	dl,cs:[bx]
        cmp	dl,0			; leer ?
        je	done			; ja, Abbruch
        inc	bx
        mov	ah,cs:[bx]
        mov	al,ch
        call	BSMixerSetRegister	; Rechts

;-----------------
;	ENDE
;-----------------
done:
        clc
error:
;        call	SysExitInterrupt	; LA 18.10.99
	.leave
        ret

BSMixerSetValue	endp

;-----------------------
;
;	TokenToIndex
;
; 	Token suchen
;
;  IN	cx	token
;  OUT	di	index (valNum)
;	bx	Zeiger Eintrag
;	CY=1	not found
;
;-----------------------
TokenToIndex proc    near
	uses	ax,cx,dx,ds,si
        .enter
	mov	ax,segment dgroup
        mov	ds,ax
start:
        push	cx
	call	GetOffToValTab
        mov	si,bx			; si Valuetable
        pop	cx
        mov	dx,ds:[bsMixerValMax]

        mov	di,0
search:
	cmp     cs:[bx], cx
        je	found
        add	bx,VAL_LEN
        inc	di
        dec	dx
        jne	search
        mov	bx,si
        mov	di,0
        stc
        jmp	done
found:
	clc
done:
	.leave
        ret
TokenToIndex endp

;--------------------------------
;
;	BSMixerGetRegister
;
; IN	dl	Registernummer
;	dh	Valuetyp
;		1 = Slider (korrigieren)
;	bl	Bitmask
; OUT	al	Wert
;	dx	Adresse Dataport
;--------------------------------

BSMixerGetRegister proc    near
	uses	bx,cx
        .enter
        mov	ch,dh		; dh = Typ retten
        mov	al,dl
	mov	dx,ds:[basePortAddress]
        add	dx,4		; Mixer Address Port
        out	dx,al
        inc	dx
        in	al,dx		; Auslesen
	and	al,bl		; Bits maskieren
        tst	bl		; mindestens 1 Bit gesetzt ?
	je	done		; nein
        cmp	ch,1		; Slider ?
        je	slider		; ja
        cmp	ch,2		; Itemgroup ?
        jne	done		; nein

itemgroup:
        sar	bl		; Bit 0 gesetzt ?
        jc	done		; ja
        shr	al		; nein,Value korrigieren
        jmp short itemgroup	; next

slider:
        sal	bl		; Bit 7 gesetzt ?
        jc	done		; ja
        shl	al		; Value korrigieren
        jmp short slider
done:
	.leave
        ret             	; dx = Data Port

BSMixerGetRegister endp

;--------------------------------
;
;	BSMixerSetRegister
;
; IN    dl	Register
;	dh	Valuetyp
;		1 = Slider (korrigieren)
;		2 = Itemgroup
;	al	Wert
;	ah	Bitmaske
;--------------------------------

BSMixerSetRegister proc    near

	uses	ax,bx,cx,dx
        .enter

; Wert korrigieren wenn Typ = Slider,Itemgroup
        mov	cl,ah		; Bitmaske
        tst	cl		; Bitmaske gÅltig ?
        jz	getreg		; nein

	cmp	dh,1		; Slider ?
        jz	slider		; ja
        cmp	dh,3		; Boolean ?
        jz	getreg		; ja, keine Korrektur

itemgroup:
        sar	cl		; Bit 0 gesetzt ?
        jc	getreg		; ja
        shl	al		; Value korrigieren
        jmp short itemgroup

; Korrektur
slider:
        sal	cl		; Bit 7 gesetzt ?
        jc	getreg		; ja
        shr	al		; Value korrigieren
        jmp short slider

; Register einlesen
getreg:
        mov	cx,ax		; save Wert,Bitmaske
        mov	bl,0ffh		; Bitmaske = 0FFh keine Korrektur
        call	BSMixerGetRegister

        mov	ah,0ffh
        xor	ah,ch		; Bitmaske negiert
        and	al,ah		; al = ausmaskierte Bits

        and	cl,ch		; Wert Bits maskieren
        or	al,cl		; Einstellwert berechnen
        out	dx,al
	.leave
        ret             	; dx = Data Port

BSMixerSetRegister endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerSetDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Mixerchip init.

Aufrufer:	Mixerlibrary

IN:		-

OUT:            CF=1 	Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	08.10.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerSetDefault proc    far
	uses    ax,bx,cx,dx		;PUSH ax, ...
	.enter

;-----------------
;	ENDE
;-----------------
;done:
        clc
	.leave
        ret

BSMixerSetDefault	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerGetSubToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Zum Token zugewiesenen Text zurueckgeben

Aufrufer:	Mixerlibrary

IN:             dx	identifier
		cx	Token

OUT:            ax	SubToken

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	10.10.98	Init

 ACHTUNG: Obwohl identifier von Typ word ist sind nur 8 Identifier
 	  wegen der Tabellenlaenge erlaubt (0x01 .. 0x80)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerGetSubToken proc    far
	uses    bx,cx,dx,di		;PUSH ax, ...
	.enter

;-----------------------
; Token suchen
;-----------------------
start:
        mov	di,dx			; identifier for later
        push	cx
        call	GetOffToValTab
        mov	bx,cx
        pop	cx			; Token zurÅck
        mov	ax,0			; not found Token
search:
        mov	dx,cs:[bx]
        cmp	dx,0			; Endekennung ?
        je	done			; ja !
        cmp	dx,cx			; Token gefunden ?
        je	found			; ja !
        add	bx,18			; naechste Pos.
        jmp	search

;-----------------------
; SubToken ermitteln
;-----------------------
found:
        inc	bx
        inc	bx
	mov	dx,di			; identifier
        tst	dl			; identifier OK (0x01 bis 0x80) ?
        je	done
subsearch:
        shr	dl			; LSB gesetzt ?
        jc	found2			; ja
        inc	bx			; nein nÑchste Stelle
        inc	bx
        jmp	subsearch
found2:
	mov	ax,cs:[bx]		; SubToken

;-----------------
;	ENDE
;-----------------
done:
	.leave
        ret

BSMixerGetSubToken	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerTokenToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Zum Token zugewiesenen Text zurueckgeben

Aufrufer:	Mixerlibrary

IN:		ax:bx	Zieltextpuffer
		cx	Token

OUT:            CF=1 	Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	09.10.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerTokenToText proc    far
	uses    ax,bx,cx,dx,es,si,di		;PUSH ax, ...
	.enter

        mov	es,ax		; Ziel
        mov	si,bx

;-----------------------
; Token suchen
;-----------------------
start:
        mov	bx,0
search:
        mov	ax,cs:tokenToTextList[bx]
        tst	ax
        jz	notfound

	cmp     ax , cx
        je	found
        add	bx,2
        jmp	short search

notfound:
        mov	bx,TTLnotFound

;-----------------------
; Zeiger auf Text (Src)
;-----------------------
found:
	mov	di,cs:tokenTextList[bx]

;-----------------------
; Text kopieren (Src) --> (Ziel)
;-----------------------

	mov	cx,31		; max. Count
loop1:
	mov	al,cs:[di]
	mov	es:[si],al
	tst	al		; Ende ?
	je	done		; ja
        inc	si
        inc	di
	dec	cx
	jne	loop1		; next

;-----------------
;	ENDE
;-----------------
done:
        clc
	.leave
        ret

BSMixerTokenToText	endp

tokenToTextList	word	50
		word	51
                word	52

tokenTextList	word	offset	tokenText50
		word	offset	tokenText51
TTLnotFound	word	offset	notfoundText

tokenText50	char	'Eingangsquelle',0
tokenText51	char	'token51',0
notfoundText	char	'unknown',0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSMixerSpecValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Value genauer definieren

Aufrufer:	Mixerlibrary

IN:		dx	valNum

OUT:            ax	Range
		bx	Token
                cl	Type
                ch	sliderNum
                dl	target
                dh	visible,stereo
		CF=1 	Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	10.10.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSMixerSpecValue proc    far
	uses    di		;PUSH ax, ...
	.enter

; Zeiger berechnen
	call	GetOffToValTab	; bx = Zeiger valueTab

	mov	ax,VAL_LEN    	; Laenge eines Eintrags
        mul	dx
        add	ax,bx
        mov	di,ax

; Tokentabelle auslesen

	mov     bx,cs:[di]	; Token
        inc	di
        inc	di
	mov     ax,cs:[di]	; Range
        inc	di
        inc	di
	mov     cx,cs:[di]	; Typ, Slidernum
        inc	di
        inc	di
	mov     dx,cs:[di]	; target, visible

;-----------------
;	ENDE
;-----------------
;done:
        clc
	.leave
        ret

BSMixerSpecValue	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mixerSuperTable:
	word	offset	valTab1745	; valueTable CT1745
        word	offset  subTab1745	; subTokenTable

	word	offset	valTab1345
	word	offset	subTab1345

	word	offset	valTab1335
	word	offset	subTab1335

	word	offset	valTabDum	; fÅr unbekannte DSP Version
	word	offset	subTabDum

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		CT 1745
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
valTab1745:
	word	1		; BSMX_TOKEN_MASTER
	word	255		; Range
        byte	1,0,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    030h,0f8h	; Offset, Bitmaske 1
        byte	031h,0f8h	; Offset, Bitmaske 2
; MIDI (FM)
	word	2		; BSMX_TOKEN_MIDI
	word	255		; Range
        byte	1,1,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    034h,0f8h	; Offset, Bitmaske 1
        byte	035h,0f8h	; Offset, Bitmaske 2
; VOICE (WAV)
	word	4		; BSMX_TOKEN_VOICE
	word	255
        byte	1,2,1
	byte	0C0h
	byte    032h,0f8h	; Offset, Bitmaske 1
        byte	033h,0f8h	; Offset, Bitmaske 2
; CD
	word	3		; BSMX_TOKEN_CD
	word	255
        byte	1,3,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    036h,0f8h	; Offset, Bitmaske 1
        byte	037h,0f8h	; Offset, Bitmaske 2
; LINE
	word	5		; BSMX_TOKEN_LINE
	word	255		; Range
        byte	1,4,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    038h,0f8h	; Offset, Bitmaske 1
        byte	039h,0f8h	; Offset, Bitmaske 2
; Mikro
	word	6		; BSMX_TOKEN_MIC
	word	255		; Range
        byte	1,5,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    03ah,0f8h
        byte	00h,00h

; Speaker
	word	7		; BSMX_TOKEN_SPEAKER
	word	255		; Range
        byte	1,6,1		; Type,sliderNum,target
	byte	00h		; visible,stereo
	byte    03bh,0c0h
        byte	00h,00h
; Tiefen
	word	9		; BSMX_TOKEN_BASS
	word	255		; Range
        byte	1,7,1		; Type,sliderNum,target
	byte	0c0h		; visible,stereo
	byte    046h,0f0h
        byte	047h,0f0h
; Hîhen
	word	8		; BSMX_TOKEN_TREBLE
	word	255		; Range
        byte	1,8,1		; Type,sliderNum,target
	byte	0c0h		; visible,stereo
	byte    044h,0f0h
        byte	045h,0f0h

; Output mixer switches (Quellen fÅr Wiedergabe)
	word	15		; BSMX_TOKEN_OUT_MX_SW
	word	5		; Range
        byte	3,9,3		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    03ch,01fh
        byte	00h,00h
; Input mixer switches Links (Quellen fÅr Aufnahme)
	word	16		; BSMX_TOKEN_IN_MX_SW_L
	word	7		; Range
        byte	3,10,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    03dh,07fh
        byte	00h,00h
; Input mixer switches Rechts (Quellen fÅr Aufnahme)
	word	17		; BSMX_TOKEN_IN_MX_SW_R
	word	7		; Range
        byte	3,11,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    03eh,07fh
        byte	00h,00h
; Input Gain Links
	word	18		; BSMX_TOKEN_IN_GAIN_L
	word	4		; Range
        byte	2,12,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    03fh,0c0h
        byte	00h,00h
; Input Gain Rechts
	word	19		; BSMX_TOKEN_IN_GAIN_R
	word	4		; Range
        byte	2,13,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    040h,0c0h
        byte	00h,00h
; Output Gain Links
	word	20		; BSMX_TOKEN_OUT_GAIN_L
	word	4		; Range
        byte	2,14,3		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    041h,0c0h
        byte	00h,00h
; Output Gain Rechts
	word	21		; BSMX_TOKEN_OUT_GAIN_R
	word	4		; Range
        byte	2,15,3		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    042h,0c0h
        byte	00h,00h
; AGC
	word	22		; BSMX_TOKEN_AGC
	word	2		; Range
        byte	2,16,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    043h,01h
        byte	00h,00h

subTab1745:
	word	BSMX_TOKEN_OUT_MX_SW
        word	6 ,28,27,26,25, 0, 0, 0	; subTokens

	word	BSMX_TOKEN_IN_MX_SW_L
        word	6 ,28,27,26,25,24,23, 0	; subTokens

	word	BSMX_TOKEN_IN_MX_SW_R
        word	6 ,28,27,26,25,24,23, 0	; subTokens

	word	BSMX_TOKEN_IN_GAIN_L
        word	29,30,31,32, 0, 0, 0, 0	; subTokens

	word	BSMX_TOKEN_IN_GAIN_R
        word	29,30,31,32, 0, 0, 0, 0	; subTokens

	word	BSMX_TOKEN_OUT_GAIN_L
        word	29,30,31,32, 0, 0, 0, 0	; subTokens

	word	BSMX_TOKEN_OUT_GAIN_R
        word	29,30,31,32, 0, 0, 0, 0	; subTokens

	word	BSMX_TOKEN_AGC,		; mainToken
		BSMX_TOKEN_ON,
        	BSMX_TOKEN_OFF,
        	 0, 0, 0, 0, 0, 0	; subTokens LSB..MSB

	word	BSMX_TOKEN_LOWPASS,	; Tiefpass
		BSMX_TOKEN_ON,
        	BSMX_TOKEN_OFF,
		 0, 0, 0, 0, 0, 0	; subTokens

        word	0			; Endekennung

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		CT 1345
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
valTab1345:
	word	1		; BSMX_TOKEN_MASTER
	word	255		; Range
        byte	1,0,1		; Type,sliderNum,target
	byte	0c0h		; visible,stereo
	byte    022h,0e0h	; Offset, Bitmaske 1
        byte	022h,00eh	; Offset, Bitmaske 2
; MIDI (FM)
	word	2		; BSMX_TOKEN_MIDI
	word	255		; Range
        byte	1,1,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    026h,0e0h	; Offset, Bitmaske 1
        byte	026h,00eh	; Offset, Bitmaske 2
; VOICE (WAV)
	word	4		; BSMX_TOKEN_VOICE
	word	255
        byte	1,2,1
	byte	0C0h
	byte    004h,0e0h
        byte	004h,00eh
; CD
	word	3		; BSMX_TOKEN_CD
	word	255
        byte	1,3,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    028h,0e0h
        byte	028h,00eh
; LINE
	word	5		; BSMX_TOKEN_LINE
	word	255		; Range
        byte	1,4,1		; Type,sliderNum,target
	byte	0C0h		; visible,stereo
	byte    02eh,0e0h
        byte	02eh,00eh
; Mikro
	word	6		; BSMX_TOKEN_MIC
	word	255		; Range
        byte	1,5,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    0ah,06h
        byte	00h,00h

; Inputfilter
	word	10		; BSMX_TOKEN_IN_FLT
	word	2		; Range
        byte	2,6,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    0ch,020h
        byte	00h,00h
; Tiefpassfilter
	word	11		; BSMX_TOKEN_LOWPASS
	word	2		; Range
        byte	2,7,3		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    0ch,08h
        byte	00h,00h
; Input Source
	word	12		; BSMX_TOKEN_INP_SRC
	word	4		; Range
        byte	2,8,2		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    0Ch,06h
        byte	00h,00h

valTabEnd:
	word	0

subTab1345:
	word	BSMX_TOKEN_IN_FLT,	; mainToken
		BSMX_TOKEN_ON,
        	BSMX_TOKEN_OFF,
        	 0, 0, 0, 0, 0, 0	; subTokens LSB..MSB

	word	BSMX_TOKEN_LOWPASS,	; Tiefpass
		BSMX_TOKEN_ON,
        	BSMX_TOKEN_OFF,
		 0, 0, 0, 0, 0, 0	; subTokens

	word	BSMX_TOKEN_INP_SRC
        word	0 , 3, 6, 5, 0, 0, 0, 0	; subTokens

        word	0			; Endekennung

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		CT 1335
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
valTab1335:
	word	1		; BSMX_TOKEN_MASTER
	word	255		; Range
        byte	1,0,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    02h,0e0h	; Offset, Bitmaske 1
        byte	0h,00h		; Offset, Bitmaske 2
; MIDI (FM)
	word	2		; BSMX_TOKEN_MIDI
	word	255		; Range
        byte	1,1,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    06h,0e0h	; Offset, Bitmaske 1
        byte	0h,00h		; Offset, Bitmaske 2
; VOICE (WAV)
	word	4		; BSMX_TOKEN_VOICE
	word	255
        byte	1,2,1
	byte	080h
	byte    0ah,060h
        byte	00h,00h
; CD
	word	3		; BSMX_TOKEN_CD
	word	255
        byte	1,3,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    08h,0eh
        byte	0h,0h

subTab1335:
	word	0		; Ende

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		unbekannte DSP Version
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
valTabDum:
	word	1		; BSMX_TOKEN_MASTER
	word	255		; Range
        byte	1,0,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    02h,0h
        byte	0h,0h
; MIDI (FM)
	word	2		; BSMX_TOKEN_MIDI
	word	255		; Range
        byte	1,1,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    02h,0h
        byte	0h,0h
; VOICE (WAV)
	word	4		; BSMX_TOKEN_VOICE
	word	255
        byte	1,2,1
	byte	080h
	byte    02h,0h
        byte	0h,0h
; CD
	word	3		; BSMX_TOKEN_CD
	word	255
        byte	1,3,1		; Type,sliderNum,target
	byte	080h		; visible,stereo
	byte    02h,0h
        byte	0h,0h

subTabDum:
	word	0		; Ende

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LoadableCode		ends


