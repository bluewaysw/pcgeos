include stdapp.def              ; Standard Geos stuff
include timer.def               ; Timer, sleeping etc.
include thread.def
include Objects/inputC.def
include Internal/im.def         ; Input Manager internals

include macroeng.def


                SetGeosConvention       ; set calling convention


udata           segment
  myGeodeHandle   word                  ; Geode handle of Monitor application

  recState        MacroStatus
  playbackSpeed   word                  ; delay (in ticks) between steps
  SoundState      word                  ; (boolean) Sound on/off?

  hotkeyList      fptr                  ; pointer to current hotkey list
  macroBuf        fptr                  ; pointer to buffer for current macro
  bufSize         word                  ; size of buffer (when recording)

  LastPtrCX       word
  LastPtrDX       word
  LastPtrBP       word
  PrevTick        word
udata           ends

idata           segment
  myMonitorData   Monitor
  myMonitor2Data  Monitor
idata           ends


MACROENG_FIXED  segment resource

                assume  ds:dgroup       ; dgroup loaded on call of MyMonitor

;
;       MyMonitor
;
MyMonitor       proc    far
                cmp     di,MSG_META_KBD_CHAR
                je      key_event
                cmp     di,MSG_IM_BUTTON_CHANGE
                je      button_event
passthrough:    ret

button_event:   test    ds:recState,mask MS_recording
                                        ; recording?
                jz      passthrough     ; no: don't do anything
                push    ax,bx,si,di,es
                jmp     record_mouse

key_event:      test    dl,mask CF_RELEASE
                jnz     nohot_event     ; not looking for releases of hotkey

                ;       Hotkey handling

                test    {word}ds:hotkeyList+2,0ffffh
                jz      nohot_event     ; no hotkey list: don't scan

                push    ax,dx,di,es

                ; convert key to KeyboardShortcut format for convenient
                ; comparison with table entries

                mov     ax,cx           ; get character
                and     ax,0fffh        ; mask out upper 4 bits of charset

                test    dh,mask SS_LSHIFT or mask SS_RSHIFT
                jz      noshift         ; both shifts are equal
                or      ax,mask KS_SHIFT
noshift:
                test    dh,mask SS_LALT or mask SS_RALT
                jz      noalt           ; both alts are equal
                or      ax,mask KS_ALT
noalt:
                test    dh,mask SS_LCTRL or mask SS_RCTRL
                jz      noctrl          ; both ctrls are equal
                or      ax,mask KS_CTRL
noctrl:

                ; start scanning from start of hotkey list
                les     di,ds:hotkeyList
                jmp     start_scan

hotkey_scan:    cmp     es:[di].MHL_keyboardShortcut,ax
                je      hotkey_found

                ; advance to next entry in list
                add     di,size MacroHotkeyList

start_scan:     cmp     es:[di].MHL_keyboardShortcut,0
                jne     hotkey_scan     ; not reached end of list: continue

                pop     ax,dx,di,es
                jmp     nohot_event

                ; found hotkey: send message to destination
hotkey_found:   push    bx,si,bp
                mov     ax,es:[di].MHL_message
                mov     bp,es:[di].MHL_data
                mov     si,{word}es:[di].MHL_destination
                mov     bx,{word}es:[di].MHL_destination+2
                mov     di,0            ; MessageFlags
                call    ObjMessage
                pop     bx,si,bp

                pop     ax,dx,di,es
                xor     al,al           ; kill message
                ret

nohot_event:    test    ds:recState,mask MS_recording
                                        ; recording?
                jnz     we_are_recording
                jmp     passthrough     ; no: don't do anything
we_are_recording:

                push    ax,bx,si,di,es

                test    dl,mask CF_RELEASE
                jz      norelease

                ; skip over releases immediately after start of recording
                test    ds:recState,mask MS_waitrelease
                jz      nosound
                jmp     noroom
norelease:

record_mouse:   test    ds:SoundState, 0ffffh
                jz     nosound          ; skip clicking if sound is disabled

                mov     ax,SST_KEY_CLICK
                call    UserStandardSound

nosound:        mov     ax,di
                les     di,ds:macroBuf  ; pointer to current macro

                mov     bx,es:[di].MEB_size
                add     bx,size MacroCannedEvent
                add     bx,size MacroCannedEvent
                cmp     bx,ds:bufSize   ; still room in buffer?
                jbe     roomleft

                ; no: set overflow flag and do not record
                or      ds:recState,mask MS_overflow
                jmp     noroom

roomleft:       sub     bx,size MacroCannedEvent
                sub     bx,size MacroCannedEvent

                push    ax,bx
                call    TimerGetCount
                mov     si,ax           ; we only use low word
                sub     si,ds:PrevTick  ; ticks since last event
                mov     ds:PrevTick,ax  ; tick count when event was executed
                pop     ax,bx

                cmp     ax,MSG_IM_BUTTON_CHANGE
                jne     notmouse
                push    ax
                mov     es:[di][bx].MCE_message,MSG_IM_PTR_CHANGE
                mov     ax,ds:LastPtrCX
                mov     es:[di][bx].MCE_CX,ax
                mov     ax,ds:LastPtrDX
                mov     es:[di][bx].MCE_DX,ax
                mov     ax,ds:LastPtrBP
                mov     es:[di][bx].MCE_BP,ax
                mov     es:[di][bx].MCE_ticks,si
                xor     si,si           ; don't wait prior to click event
                add     bx,size MacroCannedEvent
                pop     ax

notmouse:       mov     es:[di][bx].MCE_message,ax
                mov     es:[di][bx].MCE_CX,cx
                mov     es:[di][bx].MCE_DX,dx
                mov     es:[di][bx].MCE_BP,bp
                mov     es:[di][bx].MCE_ticks,si

                add     bx,size MacroCannedEvent

                mov     es:[di].MEB_size,bx
                and     ds:recState,not mask MS_waitrelease

noroom:         pop     ax,bx,si,di,es
                ret
MyMonitor       endp


;
;       MyMonitor2
;
MyMonitor2      proc    far
                cmp     di,MSG_META_MOUSE_PTR
                je      ptr_event
passthrough2:   ret

ptr_event:      mov     ds:LastPtrCX,cx
                mov     ds:LastPtrDX,dx
                push    ax
                mov     ax,mask PI_absX or mask PI_absY
                mov     ds:LastPtrBP,ax
                pop     ax
                jmp     passthrough2
MyMonitor2      endp


;
;       Playback Thread (must reside in fixed memory)
;
PlaybackThread  proc    far
                or      ds:recState,mask MS_playing
                                        ; we're playing back

                call    ImInfoInputProcess

                mov     si,offset MEB_data      ; start at first event
                les     di,ds:macroBuf          ; get pointer to current macro
                jmp     check_play
playing:
                mov     bp,si           ; pointer into current macro

                mov     ax,ds:playbackSpeed
                cmp     ax,7FFFh
                jne     setspeed
                mov     ax,es:[di][bp].MCE_ticks
setspeed:       or      ax,ax
                jz      nosleep
                call    TimerSleep
nosleep:
                test    ds:recState,mask MS_abort
                jnz     abort           ; someone set abort flag: stop it

                push    di
                mov     ax,es:[di][bp].MCE_message
                mov     cx,es:[di][bp].MCE_CX
                mov     dx,es:[di][bp].MCE_DX
                mov     bp,es:[di][bp].MCE_BP
                mov     di,0            ; MessageFlags
                call    ObjMessage
                pop     di

                add     si,size MacroCannedEvent
check_play:     cmp     si,es:[di].MEB_size     ; still within macro body?
                jb      playing                 ; yes: keep on playing

abort:          and     ds:recState, not mask MS_playing and not mask MS_abort
                                        ; no longer playing
                clr     cx,dx,bp,si
                jmp     ThreadDestroy
PlaybackThread  endp

MACROENG_FIXED  ends


MACROENG_TEXT   segment resource

;------------------------------------------------------------------------------
; void _pascal MacroInit(void);
;------------------------------------------------------------------------------
                global MACROINIT:far

MACROINIT       proc    far
                uses    bp
                .enter

                call    GeodeGetProcessHandle
                mov     ds:myGeodeHandle,bx

                mov     al,ML_DRIVER+1
                mov     bx,offset myMonitorData
                mov     cx,segment MyMonitor
                mov     dx,offset MyMonitor
                call    ImAddMonitor

                mov     al,ML_COMBINE+1
                mov     bx,offset myMonitor2Data
                mov     cx,segment MyMonitor2
                mov     dx,offset MyMonitor2
                call    ImAddMonitor

                mov     ds:recState,0   ; not doing anything right now
                mov     ds:playbackSpeed, -1
                                        ; default speed setting

                .leave
                ret
MACROINIT       endp


;------------------------------------------------------------------------------
; void _pascal MacroDeinit(void);
;------------------------------------------------------------------------------
                global MACRODEINIT:far

MACRODEINIT     proc    far
                .enter

                mov     al,mask MF_REMOVE_IMMEDIATE
                mov     bx,offset myMonitorData
                call    ImRemoveMonitor

                mov     al,mask MF_REMOVE_IMMEDIATE
                mov     bx,offset myMonitor2Data
                call    ImRemoveMonitor

                .leave
                ret
MACRODEINIT     endp


;------------------------------------------------------------------------------
; Boolean _pascal MacroStartRecording(MacroEventBuffer *buf, word bufsize,
;                                     Boolean sound);
;------------------------------------------------------------------------------
                global  MACROSTARTRECORDING:far

MACROSTARTRECORDING proc far _buf:fptr, _bufsize:word, _sound:word
                uses    di,es
                .enter

                ; set current macro
                mov     ax,{word}_buf
                mov     dx,{word}_buf+2
                mov     {word}ds:macroBuf,ax
                mov     {word}ds:macroBuf+2,dx

                ; turn click sound during recording on/off
                mov     ax,_sound
                mov     ds:SoundState, ax

                ; set buffer size
                mov     ax,_bufsize
                mov     ds:bufSize,ax

                ; initialize pointer into event buffer
                les     di,ds:macroBuf
                mov     es:[di].MEB_size,size MEB_size

                mov     ds:PrevTick,0   ; doesn't matter anyway
                or      ds:recState,mask MS_recording or mask MS_waitrelease
                                        ; we're recording
                mov     ax,FALSE        ; everything ok

                .leave
                ret
MACROSTARTRECORDING endp


;------------------------------------------------------------------------------
; Boolean _pascal MacroEndRecording(void);
;------------------------------------------------------------------------------
                global  MACROENDRECORDING:far

MACROENDRECORDING proc far
                uses    di,es
                .enter

                and     ds:recState,not mask MS_recording
                                        ; stop recording

                les     di,ds:macroBuf  ; pointer to current macro
                mov     es:[di].MEB_data.MCE_ticks,0
                                        ; never wait at the beginning
                mov     ax,FALSE        ; everything ok

                .leave
                ret
MACROENDRECORDING endp


;------------------------------------------------------------------------------
; Boolean _pascal MacroStartPlayback(MacroEventBuffer *buf, word speed);
;------------------------------------------------------------------------------
                global  MACROSTARTPLAYBACK:far

MACROSTARTPLAYBACK proc far _buf:fptr, _speed:word
                uses si,di,bp
                .enter

                ; set current macro
                mov     ax,{word}_buf
                mov     dx,{word}_buf+2
                mov     {word}ds:macroBuf,ax
                mov     {word}ds:macroBuf+2,dx

                ; pass playback speed
                mov     ax,_speed
                mov     ds:playbackSpeed,ax

                mov     al,PRIORITY_HIGH
                mov     cx,segment PlaybackThread
                mov     dx,offset PlaybackThread
                mov     di,512
                mov     bp,ds:myGeodeHandle
                call    ThreadCreate
                mov     ax,FALSE        ; everything ok

                .leave
                ret
MACROSTARTPLAYBACK endp


;------------------------------------------------------------------------------
; Boolean _pascal MacroAbortPlayback(void);
;------------------------------------------------------------------------------
                global  MACROABORTPLAYBACK:far

MACROABORTPLAYBACK proc far
                .enter

                or      ds:recState,mask MS_abort
                mov     ax,FALSE        ; everything ok

                .leave
                ret
MACROABORTPLAYBACK endp


;------------------------------------------------------------------------------
; MacroStatus _pascal MacroGetStatus(void);
;------------------------------------------------------------------------------
                global  MACROGETSTATUS:far

MACROGETSTATUS proc far
                .enter

                mov     al,ds:recState  ; return current playback/record state
                mov     ah,0

                .leave
                ret
MACROGETSTATUS endp


;------------------------------------------------------------------------------
; void _pascal MacroSetHotkeys(MacroHotkeyList *hot);
;------------------------------------------------------------------------------
                global  MACROSETHOTKEYS:far

MACROSETHOTKEYS proc far _hot:fptr
                .enter

                ; store new hotkey list
                mov     ax,{word}_hot
                mov     dx,{word}_hot+2
                mov     {word}ds:hotkeyList,ax
                mov     {word}ds:hotkeyList+2,dx

                .leave
                ret
MACROSETHOTKEYS endp


MACROENG_TEXT   ends
