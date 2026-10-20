#!/usr/bin/env perl

my $doing=0;
my $charname='';
my $width=8, $height=16;
while(<>)
{
	chop;
	if ($_ =~ /^COMMENT\s+(.*)$/) {
		print STDOUT "\t".$1."\n";
	} elsif ($_ =~ /^FONTBOUNDINGBOX\s+([[:digit:]]+)\s+([[:digit:]]+)\s+[-[:digit:]]+\s+[-[:digit:]]+\s*$/) {
		$width=$1;
		$height=$2;
	} elsif ($_ =~ /^ENCODING\s+([[:digit:]]+)\s*$/) {
		printf(STDOUT "U+%04X\t%s\n",$1,$charname);
		$charname='';
	} elsif ($_ =~ /^BITMAP\s*$/) {
		$doing=1;
		printf(STDOUT "%dx%d\n", $width, $height);
	} elsif ($_ =~ /^STARTCHAR\s+(.*)$/) {
		$charname=$1;
	} elsif ($_ =~ /^ENDCHAR\s*$/) {
		print STDOUT "\n" if ($doing);
		$doing=0;
	} elsif ($doing && $_ =~ /^([[:xdigit:]]+)\s*$/) {
		if ($width > 8) {
			$_ = unpack("B${width}",pack("n",hex($1)));
		} else {
			$_ = unpack("B${width}",pack("C",hex($1)));
		}
		tr/01/.#/;
		print STDOUT $_."\n";
	}
}

# vim:sts=2 sw=2 ts=2 noet
