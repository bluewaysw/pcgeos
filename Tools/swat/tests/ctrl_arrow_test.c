#include <assert.h>

#define UP_ARROW_ASCII         0xc8
#define DOWN_ARROW_ASCII       0xd0
#define LEFT_ARROW_ASCII       0xcb
#define RIGHT_ARROW_ASCII      0xcd
#define HOME_ASCII             0xc7
#define END_ASCII              0xcf
#define CURSES_KEYS_TEST

#include "../cursesKeys.h"

int
main(void)
{
    static const unsigned char plainUp[] = "[A";
    static const unsigned char ctrlUp[] = "[1;5A";
    static const unsigned char ctrlDown[] = "[1;5B";
    static const unsigned char plainLeft[] = "[D";
    static const unsigned char ctrlLeft[] = "[1;5D";
    static const unsigned char ctrlRight[] = "[1;5C";
    static const unsigned char shiftUp[] = "[1;2A";
    static const unsigned char shiftLeft[] = "[1;2D";
    static const unsigned char ctrlShiftDown[] = "[1;6B";
    static const unsigned char ctrlAltShiftUp[] = "[1;8A";
    static const unsigned char ctrlShiftRight[] = "[1;6C";
    static const unsigned char ss3Left[] = "OD";
    static const unsigned char ctrlHome[] = "[1;5H";
    static const unsigned char ctrlEndTilde[] = "[4;5~";
    static const unsigned char longModifier[] =
        "[1;555555555555555555555555555D";

    assert(CursesDecodeArrow(plainUp, 2) == UP_ARROW_ASCII);
    assert(CursesDecodeArrow(ctrlUp, 5) == CTRL_UP_ASCII);
    assert(CursesDecodeArrow(ctrlDown, 5) == CTRL_DOWN_ASCII);
    assert(CursesDecodeArrow(plainLeft, 2) ==
           LEFT_ARROW_ASCII);
    assert(CursesDecodeArrow(ctrlLeft, 5) ==
           CTRL_LEFT_ASCII);
    assert(CursesDecodeArrow(ctrlRight, 5) ==
           CTRL_RIGHT_ASCII);
    assert(CursesDecodeArrow(shiftUp, 5) == UP_ARROW_ASCII);
    assert(CursesDecodeArrow(shiftLeft, 5) ==
           LEFT_ARROW_ASCII);
    assert(CursesDecodeArrow(ctrlShiftDown, 5) ==
           CTRL_DOWN_ASCII);
    assert(CursesDecodeArrow(ctrlAltShiftUp, 5) ==
           CTRL_UP_ASCII);
    assert(CursesDecodeArrow(ctrlShiftRight, 5) ==
           CTRL_RIGHT_ASCII);
    assert(CursesDecodeArrow(ss3Left, 2) == LEFT_ARROW_ASCII);
    assert(CursesDecodeArrow(longModifier,
           sizeof(longModifier) - 1) == LEFT_ARROW_ASCII);

    /*
     * The modifier parameter on its own. An absent parameter and a
     * nonsensical one both have to read as "unmodified".
     */
    assert(CursesEscapeModifier(plainUp, 2) == 1);
    assert(CursesEscapeModifier(ctrlUp, 5) == 5);
    assert(CursesEscapeModifier(shiftUp, 5) == 2);
    assert(CursesEscapeModifier(ctrlHome, 5) == 5);
    assert(CursesEscapeModifier(ctrlEndTilde, 5) == 5);
    assert(CursesEscapeModifier(longModifier,
           sizeof(longModifier) - 1) == 1);
    assert(!ESC_MOD_HAS_CTRL(1));
    assert(!ESC_MOD_HAS_CTRL(2));
    assert(ESC_MOD_HAS_CTRL(5));
    assert(ESC_MOD_HAS_CTRL(6));
    assert(ESC_MOD_HAS_CTRL(8));

    assert(CursesControlKey(UP_ARROW_ASCII, 1) ==
           CTRL_UP_ASCII);
    assert(CursesControlKey(DOWN_ARROW_ASCII, 1) ==
           CTRL_DOWN_ASCII);
    assert(CursesControlKey(LEFT_ARROW_ASCII, 1) ==
           CTRL_LEFT_ASCII);
    assert(CursesControlKey(RIGHT_ARROW_ASCII, 1) ==
           CTRL_RIGHT_ASCII);
    assert(CursesControlKey(HOME_ASCII, 1) == CTRL_HOME_ASCII);
    assert(CursesControlKey(END_ASCII, 1) == CTRL_END_ASCII);
    assert(CursesControlKey(LEFT_ARROW_ASCII, 0) ==
           LEFT_ARROW_ASCII);
    assert(CursesControlKey(HOME_ASCII, 0) == HOME_ASCII);

    assert(CursesDecodeDosExtendedKey(0x8d) == CTRL_UP_ASCII);
    assert(CursesDecodeDosExtendedKey(0x91) == CTRL_DOWN_ASCII);
    assert(CursesDecodeDosExtendedKey(0x48) == UP_ARROW_ASCII);
    assert(CursesDecodeDosExtendedKey(0x50) == DOWN_ARROW_ASCII);
    assert(CursesDecodeDosExtendedKey(0x73) == CTRL_LEFT_ASCII);
    assert(CursesDecodeDosExtendedKey(0x74) == CTRL_RIGHT_ASCII);
    assert(CursesDecodeDosExtendedKey(0x75) == CTRL_END_ASCII);
    assert(CursesDecodeDosExtendedKey(0x77) == CTRL_HOME_ASCII);

    return 0;
}
