#ifndef CURSES_KEYS_H
#define CURSES_KEYS_H

/*
 * Key codes for the control-modified navigation keys. These are the
 * extended scan codes an enhanced PC keyboard produces for the
 * combinations, biased by 0x80 the way CursesReadInput biases every other
 * extended key -- except for Ctrl+Up and Ctrl+Down, whose scan codes
 * (0x8d, 0x91) would bias into ordinary control characters and are
 * therefore given codes of their own here.
 */
#define CTRL_UP_ASCII          0xf1
#define CTRL_DOWN_ASCII        0xf2
#define CTRL_LEFT_ASCII        0xf3
#define CTRL_RIGHT_ASCII       0xf4
#define CTRL_END_ASCII         0xf5
#define CTRL_HOME_ASCII        0xf7

/*
 * True if the modifier parameter of a CSI sequence has the control bit.
 * The parameter is 1 plus a mask of 1 for Shift, 2 for Alt and 4 for Ctrl.
 */
#define ESC_MOD_HAS_CTRL(m)    ((((m) - 1) & 4) != 0)

#if defined(_LINUX) || defined(CURSES_KEYS_CONTROL) || \
    defined(CURSES_KEYS_TEST)
/*
 * Map a navigation key to its control-modified code. Keys that have no
 * such code, and every key when control isn't down, are returned as-is.
 */
static int
CursesControlKey(int key, int control)
{
    if (control) {
        switch (key) {
        case UP_ARROW_ASCII:
            return CTRL_UP_ASCII;
        case DOWN_ARROW_ASCII:
            return CTRL_DOWN_ASCII;
        case LEFT_ARROW_ASCII:
            return CTRL_LEFT_ASCII;
        case RIGHT_ARROW_ASCII:
            return CTRL_RIGHT_ASCII;
        case HOME_ASCII:
            return CTRL_HOME_ASCII;
        case END_ASCII:
            return CTRL_END_ASCII;
        }
    }
    return key;
}
#endif

#if defined(_LINUX) || defined(CURSES_KEYS_TEST)
/*
 * Fetch the modifier parameter of a CSI sequence, i.e. the number
 * following the first ';'. A sequence without one is unmodified, which is
 * reported as 1. An implausibly large parameter is reported the same way
 * rather than overflowing: it can only come from a malformed sequence.
 */
static int
CursesEscapeModifier(const unsigned char *seq, int len)
{
    int     i;
    int     mod;

    for (i = 1; i < len; i++) {
        if (seq[i] != ';') {
            continue;
        }

        mod = 0;
        for (i++; (i < len) && (seq[i] >= '0') && (seq[i] <= '9'); i++) {
            mod = (mod * 10) + seq[i] - '0';
            if (mod > 255) {
                return 1;
            }
        }
        return (mod != 0) ? mod : 1;
    }

    return 1;
}

#endif

#if defined(CURSES_KEYS_TEST)
/*
 * Decode a CSI cursor-key sequence, honouring the modifier parameter.
 * CursesDecodeEscape in curses.c does the same job as part of a larger
 * parse; this exists so that the modifier handling can be exercised on
 * its own, and is therefore only built for the test.
 */
static int
CursesDecodeArrow(const unsigned char *seq, int len)
{
    int key;

    if (len < 2) {
        return -1;
    }
    switch (seq[len - 1]) {
    case 'A':
        key = UP_ARROW_ASCII;
        break;
    case 'B':
        key = DOWN_ARROW_ASCII;
        break;
    case 'C':
        key = RIGHT_ARROW_ASCII;
        break;
    case 'D':
        key = LEFT_ARROW_ASCII;
        break;
    default:
        return -1;
    }
    if (seq[0] != '[') {
        return key;
    }
    return CursesControlKey(key,
                            ESC_MOD_HAS_CTRL(CursesEscapeModifier(seq, len)));
}
#endif

#if defined(_MSDOS) || defined(CURSES_KEYS_TEST)
static int
CursesDecodeDosExtendedKey(int scan)
{
    /* These enhanced scan codes would wrap into control characters. */
    if (scan == 0x8d) {
        return CTRL_UP_ASCII;
    }
    if (scan == 0x91) {
        return CTRL_DOWN_ASCII;
    }
    return (0x80 + scan) & 0xff;
}
#endif

#endif
