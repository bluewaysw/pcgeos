#!/usr/bin/env perl
# Run the actual sizing and view-notification code without a GEOS runtime.
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);

sub read_source {
    open my $file, '<:raw', $_[0] or die $!;
    local $/;
    my $text = <$file>;
    $text =~ s/\r\n/\n/g;
    return $text;
}

my $root = "$FindBin::Bin/../../../..";
my $source = read_source("$FindBin::Bin/../urltext/URLTEXT.goc");
$source =~ /^(void _pascal URLTextInitializeImage\(.*?^})/ms
    or die "Cannot find image initialization\n";
my $sizing = $1;
$sizing =~ s/\@call NavigateFitToWindow::MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS\(\)/fitEnabled/g;
my $original = $sizing;
$original =~ s/URLTextInitializeImage/OriginalInitializeImage/;
$original =~ s{    /\* Fit inline images.*?(?=    /\*\n     \* actual size)}{}s
    or die "Cannot isolate fit calculation\n";
$original =~ s/    HTMLTextInstance \*textP;.*?WWFixedAsDWord maxScale, fitScale;\n//s;

my $view = read_source("$root/Library/Breadbox/Html4Par/htmlclas/htmltdrw.goc");
$view =~ /^(\@extern method HTMLTextClass, MSG_META_CONTENT_VIEW_SIZE_CHANGED\n\{.*?^})/ms
    or die "Cannot find view notification\n";
$view = $1;
$view =~ s/\@extern method HTMLTextClass, MSG_META_CONTENT_VIEW_SIZE_CHANGED\n\{/void ViewChanged(optr oself, word viewWidth)\n{\n    HTMLTextInstance *pself = ObjDerefVis(oself);/;
$view =~ s/\@callsuper\(\)/CheckEarlyWidth(oself, viewWidth)/;
$view =~ s/\@call self::MSG_META_UNSUSPEND\(\)/CheckEarlyWidth(oself, viewWidth)/;
$view =~ s/\@call oself::MSG_HTML_TEXT_CALCULATE_LAYOUT\(\)/CheckEarlyWidth(oself, viewWidth)/;
$view =~ s/\@call viewObj::MSG_GEN_VIEW_GET_WINDOW\(\)/0/;

my $toggle = read_source("$FindBin::Bin/../htmlview/UIRare.goc");
$toggle =~ /^(\@extern method HTMLVProcessClass, MSG_HMLVP_FIT_TO_WINDOW_CHANGED\n\{.*?^})/ms
    or die "Cannot find toggle handler\n";
$toggle = $1;
$toggle =~ s/\@extern method HTMLVProcessClass, MSG_HMLVP_FIT_TO_WINDOW_CHANGED/void ToggleChanged(word modifiedBooleans)/;
$toggle =~ s/\@record URLDocumentClass::MSG_URL_DOCUMENT_RELOAD\(\)/1/;
$toggle =~ s/\@send application::MSG_META_SEND_CLASSED_EVENT\(evt, TO_APP_MODEL\)/SendReload(evt)/;

my $header = read_source("$root/CInclude/html4par.goh");
my $defines = '';
for my $name (qw(HTS_VIEW_NOT_OPENED HTS_VIEW_SUSPENDED_FOR_OPEN
                 HTML_IMAGE_POS_RESERVED HTML_ANIMATION_VAR_FRAME_NOT_STARTED)) {
    $header =~ /^\s*(#define\s+\Q$name\E\s+[^\n]+)/m or die "Missing $name\n";
    $defines .= "$1\n";
}
my $tmp = tempdir(CLEANUP => 1);
open my $test, '>', "$tmp/check.c" or die $!;
print $test $defines;
print $test <<'C';
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef uint16_t word;
typedef uint32_t dword;
typedef uint32_t WWFixedAsDWord;
typedef struct { word WWF_frac; int16_t WWF_int; } WWFixed;
typedef struct { word XYS_width, XYS_height; } XYSize;
typedef struct { int16_t P_x, P_y; } Point;
typedef struct { int16_t XYO_x, XYO_y; } XYOffset;
typedef struct HTMLTextInstance *optr;
typedef struct HTMLTextInstance {
    word HTI_state, HTI_viewWidth, HTI_pageLeftMargin;
    optr HTI_myView;
} HTMLTextInstance;
typedef word WindowHandle;
typedef word EventHandle;
typedef struct {
    XYSize size, HID_size;
    WWFixed HID_tmatrixE11, HID_tmatrixE22;
    XYOffset HID_drawOffset;
    word hspace, HID_IADType, HID_frame, HID_loopCount;
    dword pos;
} HTMLimageData;
typedef struct { XYSize IAD_size; Point IAD_origin; word IAD_type; } ImageAdditionalData;
#define _pascal
#define ObjDerefVis(o) (o)
#define TEXT_ADDRESS_PAST_END UINT32_C(0x80000000)
#define WIT_COLOR 0
#define WCF_TRANSPARENT 0
#define WinSetInfo(w, t, c) ((void)(w))
#define COMPILE_OPTION_LIMIT_SCALING
#define MakeWWFixed(i) ((uint32_t)(i) << 16)
#define IntegerOf(i) ((word)((uint32_t)(i) >> 16))
#define FractionOf(i) ((word)(i))
#define RoundWWF(i) (IntegerOf(i) + (FractionOf(i) >= 0x8000 ? 1 : 0))
static word fitEnabled = 1, reloads;
/* Match signed, truncating kernel multiplication and unsigned division. */
static WWFixedAsDWord GrMulWWFixed(WWFixedAsDWord a, WWFixedAsDWord b)
{ return (uint32_t)(((int64_t)(int32_t)a * (int32_t)b) >> 16); }
static WWFixedAsDWord GrUDivWWFixed(WWFixedAsDWord a, WWFixedAsDWord b)
{
    uint64_t quotient;
    assert(b);
    quotient = ((uint64_t)a << 16) / b;
    assert(quotient <= UINT32_MAX);
    return (uint32_t)quotient;
}
static void CheckEarlyWidth(optr textP, word width)
{
    if (width) {
        assert(textP->HTI_viewWidth == width);
        assert(!(textP->HTI_state & HTS_VIEW_NOT_OPENED));
    }
}
static void SendReload(EventHandle evt) { assert(evt == 1); reloads++; }
C
print $test $original, "\n", $sizing, "\n", $view, "\n", $toggle;
print $test <<'C';
static word CheckImage(optr textP, word width, word height, word htmlWidth,
                       word htmlHeight, word hspace, dword pos)
{
    HTMLimageData image, original;
    ImageAdditionalData iad;
    dword used, limit;
    uint32_t x, y, ox, oy;
    int64_t difference;

    memset(&image, 0, sizeof(image));
    image.size.XYS_width = htmlWidth;
    image.size.XYS_height = htmlHeight;
    image.hspace = hspace;
    image.pos = pos;
    iad.IAD_size.XYS_width = width;
    iad.IAD_size.XYS_height = height;
    iad.IAD_origin.P_x = 13;
    iad.IAD_origin.P_y = -7;
    iad.IAD_type = 2;
    original = image;
    OriginalInitializeImage(textP, &original, &iad);
    URLTextInitializeImage(textP, &image, &iad);
    used = (dword)textP->HTI_pageLeftMargin + 1 + 2L * hspace;
    limit = used < textP->HTI_viewWidth ? textP->HTI_viewWidth - used : 1;
    if (!fitEnabled || (textP->HTI_state & HTS_VIEW_NOT_OPENED) ||
        !textP->HTI_viewWidth || pos >= HTML_IMAGE_POS_RESERVED ||
        (uint64_t)width * *(WWFixedAsDWord *)&original.HID_tmatrixE11 <= MakeWWFixed(limit)) {
        assert(!memcmp(&image, &original, sizeof(image)));
    } else {
        assert(image.HID_size.XYS_width <= limit);
        x = *(WWFixedAsDWord *)&image.HID_tmatrixE11;
        y = *(WWFixedAsDWord *)&image.HID_tmatrixE22;
        ox = *(WWFixedAsDWord *)&original.HID_tmatrixE11;
        oy = *(WWFixedAsDWord *)&original.HID_tmatrixE22;
        assert(x <= ox && y <= oy);
        /* Drawing untransforms the size, including its one-pixel minimum. */
        GrUDivWWFixed(MakeWWFixed(image.HID_size.XYS_width), x);
        GrUDivWWFixed(MakeWWFixed(image.HID_size.XYS_height), y);
        difference = (int64_t)x * oy - (int64_t)y * ox;
        assert(difference >= -2 * (int64_t)(ox + oy) &&
               difference <= 2 * (int64_t)(ox + oy));
    }
    x = RoundWWF(GrMulWWFixed(MakeWWFixed(width),
                              *(WWFixedAsDWord *)&image.HID_tmatrixE11));
    y = RoundWWF(GrMulWWFixed(MakeWWFixed(height),
                              *(WWFixedAsDWord *)&image.HID_tmatrixE22));
    assert(image.HID_size.XYS_width == (x ? (word)x : 1));
    assert(image.HID_size.XYS_height == (y ? (word)y : 1));
    assert(image.HID_drawOffset.XYO_x == (int16_t)-RoundWWF(GrMulWWFixed(
        MakeWWFixed(iad.IAD_origin.P_x), *(WWFixedAsDWord *)&image.HID_tmatrixE11)));
    assert(image.HID_drawOffset.XYO_y == (int16_t)-RoundWWF(GrMulWWFixed(
        MakeWWFixed(iad.IAD_origin.P_y), *(WWFixedAsDWord *)&image.HID_tmatrixE22)));
    assert(image.HID_IADType == 2);
    assert(image.HID_frame == HTML_ANIMATION_VAR_FRAME_NOT_STARTED);
    assert(image.HID_loopCount == 0);
    return image.HID_size.XYS_width;
}

int main(void)
{
    HTMLTextInstance frame = { HTS_VIEW_NOT_OPENED, 400, 10, 0 };
    HTMLTextInstance other;
    word width, retained;

    /* The default 400 and a zero notification must not shrink an image. */
    assert(CheckImage(&frame, 1000, 500, 0, 0, 0, 0) == 1000);
    ViewChanged(&frame, 0);
    assert(frame.HTI_state & HTS_VIEW_NOT_OPENED);
    assert(CheckImage(&frame, 1000, 500, 0, 0, 0, 0) == 1000);
    frame.HTI_state |= HTS_VIEW_SUSPENDED_FOR_OPEN;
    ViewChanged(&frame, 640);
    assert(!(frame.HTI_state & HTS_VIEW_SUSPENDED_FOR_OPEN));
    fitEnabled = 0;
    assert(CheckImage(&frame, 1000, 500, 0, 0, 0, 0) == 1000);
    CheckImage(&frame, 1000, 500, 1200, 200, 5, 0);
    fitEnabled = 1;
    CheckImage(&frame, 10000, 1, 0, 10, 0, 0);
    CheckImage(&frame, 8192, 1, 0, 8, 0, 0);
    assert(CheckImage(&frame, 100, 50, 0, 0, 0, 0) == 100);
    assert(CheckImage(&frame, 1000, 500, 200, 0, 0, 0) == 200);
    CheckImage(&frame, 1000, 500, 1200, 200, 5, 0);
    CheckImage(&frame, 1000, 500, 0, 600, 5, 0);
    assert(CheckImage(&frame, 1000, 500, 0, 0, 10, 0) == 609);
    assert(CheckImage(&frame, 0, 0, 0, 0, 0, 0) == 1);
    assert(CheckImage(&frame, 1000, 500, 0, 0, 0, HTML_IMAGE_POS_RESERVED) == 1000);
    other = frame;
    ViewChanged(&other, 320);
    assert(CheckImage(&other, 1000, 500, 0, 0, 0, 0) == 309);
    retained = frame.HTI_viewWidth;
    /* Navigation preserves the object's width; cached resolution uses it. */
    CheckImage(&frame, 1000, 500, 0, 0, 0, 0);
    assert(frame.HTI_viewWidth == retained);
    ViewChanged(&frame, 200);
    assert(CheckImage(&frame, 1000, 500, 0, 0, 0, 0) == 189);
    for (width = 1; width < 1100; width++) {
        ViewChanged(&frame, width);
        CheckImage(&frame, 997, 499, 1493, 173, 5, 0);
        CheckImage(&frame, 997, 499, 0, 0, 0, 0);
    }
    CheckImage(&frame, 1000, 500, 1200, 1, 65535, 0);
    CheckImage(&frame, 32767, 32767, 29489, 1, 65535, 0);
    CheckImage(&frame, 1000, 500, 0, 0, 65535, 0);
    frame.HTI_pageLeftMargin = 65535;
    CheckImage(&frame, 1000, 500, 0, 0, 0, 0);
    frame.HTI_viewWidth = 0;
    assert(CheckImage(&frame, 1000, 500, 0, 0, 0, 0) == 1000);
    ToggleChanged(0);
    assert(reloads == 0);
    ToggleChanged(1);
    assert(reloads == 1);
    puts("Fit to window checks passed");
    return 0;
}
C
close $test or die $!;
system('cc', '-std=c89', '-Wall', '-Wextra', '-Werror', '-Wno-unused-parameter',
       '-fno-strict-aliasing', "$tmp/check.c", '-o', "$tmp/check") == 0
    or die "Host compilation failed\n";
system("$tmp/check") == 0 or die "Fit to window check failed\n";

__END__
Manual acceptance (not performed by this host check):

- Load a page with a 1000x500 image, a small image, explicit widths below
  and above the view width, explicit differing width/height, and hspace=10.
  OFF retains original sizes; ON only shrinks oversized images, including
  spacing, without widening an otherwise narrow document.
- Change the toggle both ways: the document reloads. Exit normally and
  reopen: the selection persists as [HTMLView] fitToWindow.
- Load the same oversized image in two differently sized frames. Each
  uses its own GenView width. Resize, then resolve/reload images to check
  the new widths; already resolved images need not resize immediately.
- Repeat with a warm image cache. Inspect HTI_viewWidth before SHOW_ITEM,
  HID_tmatrixE11/E22 and HID_size at RESOLVE_IMAGE, and VTG_size plus twice
  hspace entering HCD_hardMinWidth. The cached path must use the known frame
  width. Repeat with an animation to check all frames use that geometry.
