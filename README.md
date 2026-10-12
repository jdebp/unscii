# UNSCII

A bitmapped Unscii font based on classic system fonts.

See [http://viznut.fi/unscii/](http://viznut.fi/unscii/) for more.

The compiled font files are also included in fontfiles/ for your convenience.

Font compilation starts from the file src/unscii.txt which also contains some more documentation, including information about the rest of the files in the src directory.

The .hex format is basically the same as in [the Unifont project](https://savannah.gnu.org/projects/unifont/).
Each line consists of codepoint:hexbitmap, and the length of the bitmap string indicates whether the glyph is 8x8, 8x16 or 16x16.
FreeBSD vt(4) tooling introduced comments into .hex files in 2014.

## Licensing

You can consider it Public Domain (or CC-0) except for the files
derived from or containing parts of Roman Czyborra's Unifont project,
(e.g. unifont*.hex, hex2bdf.pl, hex2yaff.pl, unscii-16-full.*) which fall under GPL;
and vtfontcvt, which is MIT licenced (public domain not being a thing in U.K. law).
See [https://savannah.gnu.org/projects/unifont/](https://savannah.gnu.org/projects/unifont/) for more.

## Files

The program code in this directory:
- Makefile: builds the font files and some other stuff
- assemble.pl: compiles the files under src/ into .hex files.
- bm2uns.c: converts arbitrary bitmaps into unscii art (needs SDL_image)
- bm2uns-prebuild.pl: builds some tables for bm2uns.c
- checkwidths.pl: checks if the glyph widths in a .hex file match terminal usage
- doubleheight.pl: stretches the 8x8 glyphs in a .hex file into 8x16
- hex2bdf.pl: converts a .hex file into X11 .bdf format (from Unifont)
- hex2yaff.pl: converts a .hex file into [.yaff format](https://github.com/robhagemans/monobit/blob/master/YAFF.md)
- makeconverters.pl: makes shell scripts that convert between Unicode and legacy Unscii
- makevecfonts.ff: a Fontforge script to build ttf/otf/woff fonts from an .svg font
- merge-otherfonts.pl: fills in the missing glyphs from unifont.hex and fsex-adapted.hex
- hex-sort.pl: sorts a .hex file into codepoint order, useful for when combining .hex files with cat
- vectorize.c: builds a .svg font file from a .hex file
- vtfontcvt.cpp: builds a .fnt font file (FreeBSD's vt(4) font format) from a .hex file

Other files in this directory:
- fsex-adapted.hex: Fixedsys Excelsior, [an older public domain font from Darien Valentine et al.](https://github.com/kika/fixedsys/) with some similarities to Unscii
- Unifont, the GNU Unicode bitmap font, split into parts for size reasons:
 - unifont_controls.hex: actual ECMA-35 control characters, used by a few, but not many, applications and even excluded from processing by some font tools; so factored out
 - unifont_fallback0.hex: mechanistically extracted fallback glyphs that have a dotted box around text
 - unifont_fallback1.hex: mechanistically extracted fallback glyphs that have hex characters on a solid background with 2 pixel gutters
 - unifont_fallback2.hex: mechanistically extracted fallback glyphs that have hex characters on a solid background with 2 pixel line gaps
 - unifont_fallback3.hex: mechanistically extracted fallback glyphs that have hex characters on a solid background with no gutters nor line gaps
 - unifont_narrow.hex: all of the non-fallback non-control narrow glyphs, from all planes
 - unifont_wide.hex: all of the non-fallback non-control wide glyphs, from only the BMP
 - unifont_wide_smp.hex: all of the non-fallback non-control wide glyphs, from the SMPs

## Font naming scheme

Unifont font files have names begining with `unifont-`.
Unscii font files have names begining with `unscii-`.

In a variation from Viznut's original scheme, because 16 by 16 fonts are now generated as well, Unscii font file names then have both the height and the width.

Unscii fonts ending in `-only` contain only the font from the named system.
The unadorned `-16-16`, `-8-16`, and `-8-8` Unscii fonts are the vanilla Unscii repertoire.
The non-`-only` versions with extra suffixes such as `-pc` patch in the named systems
Not all of the systems are patched in.

The `-pet-and-bbcg` variants are special to FreeBSD's vt(4) font file format, which can hold two fonts in a single file, for two different weights.
These fonts use PETSCII for normal weight, and BBC Micro for bold weight.

## Tool and font format limitations

Fonts are converted from .bdf format to .pcf format using bdftopcf(1) from xfonts-utils.
This utility only works for the Basic Multilingual Plane.
So hex2bdf.pl simply silently ignores all Supplementary Planes.

FreeBSD's vt(4) .fnt file format can only handle 65535 glyphs per file.
(The file header records the glyph count with a 32-bit integer; but the map entries store glyph numbers using 16-bit integers.)
The full GNU Unifont is much larger than this, so it is not possible to make a single unifont.fnt file with the entire font in it.

Moreover, each wide character counts as two glyphs in a .fnt file, and the number of wide characters in GNU Unifont has gone up a lot since Unscii was first created in 2016 (the time of Unicode 9).
Only unifont_narrow.hex (and the fallbacks and controls) is small enough to fit into a single .fnt file nowadays.
So the system builds several .fnt files (and related files in other formats):
- unifont-fallback.fnt: all of the fallbacks
- unifont-controls.fnt: all of the controls, for the few applications that do actually need to show glyphs in these ranges
- unifont-narrow.fnt: all of the non-fallback non-control narrow character glyphs, from all planes

Some better way of splitting up unifont_wide.hex and unifont_wide_smp.hex, probably by language group, is required in the future.
