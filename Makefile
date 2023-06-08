SRC=src/punctuation.txt src/numbers.txt src/math.txt src/textsymbols.txt src/latin.txt src/greek.txt src/cyrillic.txt src/hebrew.txt src/arabic.txt src/katakana.txt src/runes.txt src/wideascii.txt src/diacritics.txt src/diacrcomb.txt src/symbols.txt src/arrows.txt src/divisions.txt src/lines.txt src/shapes.txt src/grids.txt src/patterns.txt src/pictures.txt src/ctrl.txt
HEX=fontfiles/unscii-16.hex fontfiles/unscii-8.hex fontfiles/unscii-16-full.hex fontfiles/unscii-8-tall.hex fontfiles/unscii-8-thin.hex fontfiles/unscii-8-alt.hex fontfiles/unscii-8-fantasy.hex fontfiles/unscii-8-mcr.hex fontfiles/unscii-16-pc16.hex fontfiles/unscii-8-pc8.hex \
    fontfiles/unscii-8-alt-only.hex fontfiles/unscii-8-arcade-only.hex fontfiles/unscii-8-atari8-only.hex fontfiles/unscii-8-bbcg-only.hex fontfiles/unscii-8-c64-only.hex fontfiles/unscii-8-cpc-only.hex fontfiles/unscii-8-fantasy-only.hex fontfiles/unscii-8-mcr-only.hex fontfiles/unscii-16-pc16-only.hex fontfiles/unscii-8-pc8-only.hex fontfiles/unscii-8-pet-only.hex fontfiles/unscii-8-spectrum-only.hex fontfiles/unscii-8-st-only.hex fontfiles/unscii-8-topaz-only.hex

CC=gcc -Os

.SUFFIXES: .hex .svg .fnt .bdf .pcf .ttf
.PHONY: all fnt bdf pcf ttf bm2uns

all: fnt bdf pcf ttf bm2uns

hex: $(HEX)
fnt: $(HEX:.hex=.fnt)
bdf: $(HEX:.hex=.bdf)
svg: $(HEX:.hex=.svg)
pcf: $(HEX:.hex=.pcf)
ttf: $(HEX:.hex=.ttf)

VERSION=2.1.1f

ASSEMBLE16=perl ./assemble.pl
ASSEMBLE8=perl ./assemble.pl -8
HEX2BDF=perl ./hex2bdf.pl --version=$(VERSION)

### HEX ###

fontfiles/unscii-16.hex: $(SRC)
	$(ASSEMBLE16) $> > $@

fontfiles/unscii-8.hex: $(SRC)
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-tall.hex: fontfiles/unscii-8.hex
	perl ./doubleheight.pl < $> > $@

fontfiles/unscii-16-full.hex: fontfiles/unscii-16.hex unifont.hex fsex-adapted.hex
	perl ./merge-otherfonts.pl $> > $@

fontfiles/unscii-8-thin.hex: $(SRC) src/font-thin.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-alt.hex: $(SRC) src/font-alt.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-fantasy.hex: $(SRC) src/font-fantasy.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-mcr.hex: $(SRC) src/font-mcr.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-pc8.hex: $(SRC) src/font-pc8.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-16-pc16.hex: $(SRC) src/font-pc16.txt
	$(ASSEMBLE16) $> > $@

fontfiles/unscii-8-alt-only.hex: src/font-alt.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-arcade-only.hex: src/font-arcade.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-atari8-only.hex: src/font-atari8.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-bbcg-only.hex: src/font-bbcg.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-c64-only.hex: src/font-c64.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-cpc-only.hex: src/font-cpc.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-fantasy-only.hex: src/font-fantasy.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-mcr-only.hex: src/font-mcr.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-16-pc16-only.hex: src/font-pc16.txt
	$(ASSEMBLE16) $> > $@

fontfiles/unscii-8-pc8-only.hex: src/font-pc8.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-pet-only.hex: src/font-pet.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-spectrum-only.hex: src/font-spectrum.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-st-only.hex: src/font-st.txt
	$(ASSEMBLE8) $> > $@

fontfiles/unscii-8-topaz-only.hex: src/font-topaz.txt
	$(ASSEMBLE8) $> > $@

### FNT ###

.hex.fnt:
	vtfontcvt $< $@

### PCF ###

.hex.bdf:
	$(HEX2BDF) --variant='16' --rows=16 < $< > $@

.bdf.pcf:
	bdftopcf < $< > $@

### SVG ###

.hex.svg: vectorize
	./vectorize 16 16 < $< > $@

### TTF/OTF/WOFF ###

.svg.ttf: makevecfonts.ff
	./makevecfonts.ff $*

### tools ###

uns2uni.tr: $(SRC)
	$(ASSEMBLE8) -t $> > $@

vectorize: vectorize.c
	$(CC) vectorize.c -o $@

bm2uns: bm2uns.c bm2uns.i
	$(CC) -O3 bm2uns.c -o $@ `sdl-config --libs --cflags` -lSDL_image -lm

bm2uns.i: unscii-8.hex bm2uns-prebuild.pl
	./bm2uns-prebuild.pl | sort > $@

uns2uni: uns2uni.tr makeconverters.pl
	./makeconverters.pl

uni2uns: uns2uni.tr makeconverters.pl
	./makeconverters.pl

### release ###

clean:
	rm -f fontfiles/*.hex fontfiles/*.pcf fontfiles/*.ttf fontfiles/*.otf fontfiles/*.woff fontfiles/*.fnt
	rm -f *~ vectorize bm2uns bm2uns.i *.o uns2uni.tr uns2uni uni2uns DEADJOE

srcpackage: clean
	cd .. && tar czf unscii-$(VERSION)-src.tar.gz unscii-$(VERSION)-src

web:
	cp *.pcf *.ttf *.otf *.woff *.hex ../web/
	cp ../unscii-$(VERSION)-src.tar.gz ../web/
