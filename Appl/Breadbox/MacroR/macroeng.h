typedef struct {
  KeyboardShortcut      MHL_keyboardShortcut;
  optr                  MHL_destination;
  word                  MHL_message;
  word                  MHL_data;
} MacroHotkeyList;

typedef struct {
  Message               MCE_message;
  word                  MCE_CX;
  word                  MCE_DX;
  word                  MCE_BP;
  word                  MCE_ticks;
} MacroCannedEvent;

typedef struct {
  word                  MEB_size;
  MacroCannedEvent      MEB_data[1];
} MacroEventBuffer;

typedef ByteFlags MacroStatus;
  #define MS_recording 0x80
  #define MS_playing   0x40
  #define MS_overflow  0x20

void _pascal MacroInit(void);
void _pascal MacroDeinit(void);

void _pascal MacroSetHotkeys(MacroHotkeyList *hot);

MacroStatus _pascal MacroGetStatus(void);

Boolean _pascal MacroStartRecording(MacroEventBuffer *buf, word bufsize,
                                    Boolean sound);
Boolean _pascal MacroEndRecording(void);

Boolean _pascal MacroStartPlayback(MacroEventBuffer *buf, word speed);
Boolean _pascal MacroAbortPlayback(void);

