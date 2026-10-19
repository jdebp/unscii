SRC=src/punctuation.txt \
    src/numbers.txt \
    src/math.txt \
    src/mathematicalalphabet.txt \
    src/textsymbols.txt \
    src/latin.txt \
    src/greek.txt \
    src/cyrillic.txt \
    src/hebrew.txt \
    src/arabic.txt \
    src/katakana.txt \
    src/runes.txt \
    src/wideascii.txt \
    src/diacritics.txt \
    src/diacrcomb.txt \
    src/symbols.txt \
    src/arrows.txt \
    src/divisions.txt \
    src/lines.txt \
    src/shapes.txt \
    src/grids.txt \
    src/patterns.txt \
    src/pictures.txt \
    src/ctrl.txt
FNT1=fontfiles/fsex-adapted.fnt \
     fontfiles/unscii-16-16-pet-and-bbcg.fnt \
     fontfiles/unscii-8-8-pet-and-bbcg.fnt \
     fontfiles/unscii-8-8-dragon-and-atari.fnt
HEX1=fontfiles/unscii-8-8.hex \
     fontfiles/unscii-8-16.hex \
     fontfiles/unscii-16-16.hex \
     fontfiles/unscii-8-8-thin.hex \
     fontfiles/unscii-8-8-alt.hex \
     fontfiles/unscii-8-8-fantasy.hex \
     fontfiles/unscii-8-8-mcr.hex \
     fontfiles/unscii-8-8-pc.hex \
     fontfiles/unscii-8-16-pc.hex \
     fontfiles/unscii-8-8-alt-only.hex \
     fontfiles/unscii-8-8-arcade-only.hex \
     fontfiles/unscii-8-8-atari-only.hex \
     fontfiles/unscii-16-16-bbcg-only.hex \
     fontfiles/unscii-8-8-bbcg-only.hex \
     fontfiles/unscii-8-8-c64-only.hex \
     fontfiles/unscii-8-8-cpc-only.hex \
     fontfiles/unscii-8-8-dragon-only.hex \
     fontfiles/unscii-8-8-fantasy-only.hex \
     fontfiles/unscii-8-8-mcr-only.hex \
     fontfiles/unscii-8-8-pc-only.hex \
     fontfiles/unscii-8-16-pc-only.hex \
     fontfiles/unscii-8-8-pet-only.hex \
     fontfiles/unscii-16-16-pet-only.hex \
     fontfiles/unscii-8-8-spectrum-only.hex \
     fontfiles/unscii-8-8-st-only.hex \
     fontfiles/unscii-8-16-tall.hex \
     fontfiles/unscii-8-8-topaz-only.hex \
     fontfiles/unscii-8-8-trs80-only.hex \
     fontfiles/unifont-fallback.hex \
     fontfiles/unifont-controls.hex \
     fontfiles/unifont-narrow.hex
# These fonts are too big for the vt(4) font file format.
HEX2=fontfiles/unscii-8-16-full.hex \
     fontfiles/unscii-16-16-full.hex \
     fontfiles/unifont-full.hex

.SUFFIXES: .hex .svg .fnt .bdf .pcf .ttf
.PHONY: all fnt bdf pcf ttf bm2uns

all: vtfontcvt fnt bdf pcf ttf bm2uns

hex: $(HEX1) $(HEX2)
fnt: vtfontcvt $(HEX1:.hex=.fnt) $(FNT1)
bdf: $(HEX1:.hex=.bdf) $(HEX2:.hex=.bdf)
pcf: $(HEX1:.hex=.pcf) $(HEX2:.hex=.pcf)
svg: vectorize $(HEX1:.hex=.svg) $(HEX2:.hex=.svg)
ttf: vectorize $(HEX1:.hex=.ttf) $(HEX2:.hex=.ttf)

VERSION=2.1.1f

ASSEMBLE16BY16=perl ./assemble.pl -16x16
ASSEMBLE8BY16=perl ./assemble.pl -8x16
ASSEMBLE8BY8=perl ./assemble.pl -8x8
HEX2BDF=perl ./hex2bdf.pl --version=$(VERSION)

### HEX ###

fontfiles/unifont-narrow.hex: unifont_narrow.hex
	printf '# Height: %d\n' 16 > $@.tmp
	printf '# This is a variable-width font.\n' >> $@.tmp
	cat $> | perl ./hex-sort.pl >> $@.tmp
	mv $@.tmp $@

fontfiles/unifont-controls.hex: unifont_controls.hex
	printf '# Height: %d\n' 16 > $@.tmp
	printf '# This is a variable-width font.\n' >> $@.tmp
	cat $> | perl ./hex-sort.pl >> $@.tmp
	mv $@.tmp $@

fontfiles/unifont-fallback.hex: unifont_fallback0.hex unifont_fallback1.hex unifont_fallback2.hex unifont_fallback3.hex
	printf '# Height: %d\n' 16 > $@.tmp
	printf '# Width: %d\n' 16 >> $@.tmp
	cat $> | perl ./hex-sort.pl >> $@.tmp
	mv $@.tmp $@

fontfiles/unifont-full.hex: unifont_fallback0.hex unifont_fallback1.hex unifont_fallback2.hex unifont_fallback3.hex unifont_narrow.hex unifont_controls.hex unifont_wide.hex unifont_wide_smp.hex
	printf '# Height: %d\n' 16 > $@.tmp
	printf '# This is a variable-width font.\n' >> $@.tmp
	cat $> | perl ./hex-sort.pl >> $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-16.hex: $(SRC)
	$(ASSEMBLE16BY16) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-16.hex: $(SRC)
	$(ASSEMBLE8BY16) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8.hex: $(SRC)
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-16-tall.hex: fontfiles/unscii-8-8.hex
	perl ./doubleheight.pl < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-16-full.hex: fontfiles/unscii-8-16.hex fontfiles/unifont-full.hex fsex-adapted.hex
	printf '# Height: %d\n' 16 > $@.tmp
	printf '# Width: %d\n' 8 >> $@.tmp
	perl ./merge-otherfonts.pl $> >> $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-16-full.hex: fontfiles/unscii-16-16.hex fontfiles/unifont-full.hex fsex-adapted.hex
	printf '# Height: %d\n' 16 > $@.tmp
	printf '# Width: %d\n' 16 >> $@.tmp
	perl ./merge-otherfonts.pl $> >> $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-thin.hex: $(SRC) src/font-thin.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-alt.hex: $(SRC) src/font-alt.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-fantasy.hex: $(SRC) src/font-fantasy.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-mcr.hex: $(SRC) src/font-mcr.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-pc.hex: $(SRC) src/font-pc8.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-16-pc.hex: $(SRC) src/font-pc16.txt
	$(ASSEMBLE8BY16) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-alt-only.hex: src/font-alt.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-arcade-only.hex: src/font-arcade.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-atari-only.hex: src/font-atari8.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-bbcg-only.hex: src/font-bbcg.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-16-bbcg-only.hex: src/font-bbcg16.txt
	$(ASSEMBLE16BY16) $> >> $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-c64-only.hex: src/font-c64.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-cpc-only.hex: src/font-cpc.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-dragon-only.hex: src/font-mc6847t1.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-fantasy-only.hex: src/font-fantasy.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-mcr-only.hex: src/font-mcr.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-16-pc-only.hex: src/font-pc16.txt
	$(ASSEMBLE8BY16) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-pc-only.hex: src/font-pc8.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-pet-only.hex: src/font-pet.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-16-pet-only.hex: src/font-pet16.txt
	$(ASSEMBLE16BY16) $> >> $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-spectrum-only.hex: src/font-spectrum.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-st-only.hex: src/font-st.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-topaz-only.hex: src/font-topaz.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-trs80-only.hex: src/font-mc6670p.txt
	$(ASSEMBLE8BY8) $> > $@.tmp
	mv $@.tmp $@

### FNT ###

.hex.fnt:
	./vtfontcvt $< > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-pet-and-bbcg.fnt: fontfiles/unscii-8-8-pet-only.hex fontfiles/unscii-8-8-bbcg-only.hex
	./vtfontcvt $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-16-pet-and-bbcg.fnt: fontfiles/unscii-16-16-pet-only.hex fontfiles/unscii-16-16-bbcg-only.hex
	./vtfontcvt $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-8-dragon-and-atari.fnt: fontfiles/unscii-8-8-dragon-only.hex fontfiles/unscii-8-8-atari-only.hex
	./vtfontcvt $> > $@.tmp
	mv $@.tmp $@

fontfiles/fsex-adapted.fnt: fsex-adapted.hex
	./vtfontcvt $> > $@.tmp
	mv $@.tmp $@

### PCF ###

.hex.bdf:
	$(HEX2BDF) --variant='8' --rows=8 < $< > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16.bdf: fontfiles/unscii-16.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-full.bdf: fontfiles/unscii-16-full.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-8-tall.bdf: fontfiles/unscii-8-tall.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-pc16.bdf: fontfiles/unscii-16-pc16.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-bbcg-only.bdf: fontfiles/unscii-16-bbcg-only.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-pc16-only.bdf: fontfiles/unscii-16-pc16-only.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@

fontfiles/unscii-16-pet-only.bdf: fontfiles/unscii-16-pet-only.hex
	$(HEX2BDF) --variant='16' --rows=16 < $> > $@.tmp
	mv $@.tmp $@


.bdf.pcf:
	bdftopcf < $< > $@.tmp
	mv $@.tmp $@

### SVG ###

.hex.svg:
	./vectorize 16 16 < $< > $@.tmp
	mv $@.tmp $@

### TTF/OTF/WOFF ###

.svg.ttf: makevecfonts.ff
	./makevecfonts.ff $*

### tools ###

uns2uni.tr: $(SRC)
	$(ASSEMBLE8BY8) -t $> > $@.tmp
	mv $@.tmp $@

vtfontcvt: vtfontcvt.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) vtfontcvt.cpp -o $@

vectorize: vectorize.c
	$(CC) $(CCFLAGS) $(CPPFLAGS) vectorize.c -o $@

bm2uns: bm2uns.c bm2uns.i
	$(CC) $(CCFLAGS) $(CPPFLAGS) -O3 bm2uns.c -o $@ `sdl-config --libs --cflags` -lSDL_image -lm

bm2uns.i: fontfiles/unscii-8.hex bm2uns-prebuild.pl
	./bm2uns-prebuild.pl | sort > $@.tmp
	mv $@.tmp $@

uns2uni: uns2uni.tr makeconverters.pl
	./makeconverters.pl

uni2uns: uns2uni.tr makeconverters.pl
	./makeconverters.pl

### release ###

clean:
	rm -f fontfiles/*.hex fontfiles/*.pcf fontfiles/*.ttf fontfiles/*.otf fontfiles/*.woff fontfiles/*.fnt
	rm -f *~ vectorize vtfontcvt bm2uns bm2uns.i *.o uns2uni.tr uns2uni uni2uns DEADJOE

srcpackage: clean
	cd .. && tar czf unscii-$(VERSION)-src.tar.gz unscii-$(VERSION)-src

web:
	cp *.pcf *.ttf *.otf *.woff *.hex ../web/
	cp ../unscii-$(VERSION)-src.tar.gz ../web/
