#!/usr/bin/env perl
# Copyright 2026 Jonathan de Boyne Pollard
# Public Domain is not a thing in U.K. law, so this is MIT "Expat"/ISC/2 Clause BSD/FreeBSD licenced.

sub tohex {
	my $r='';
	$r.=unpack("H2",$_) foreach split('',$_[0]);
	return $r;
}

my $doing=0;
my $bitmap='', $charname='', $codepoint=-1;
my $width=8, $height=16;
while(<>)
{
	chop;
	if ($_ =~ /^COMMENT\s+(.*)$/) {
		print STDOUT "#\t".$1."\n";
	} elsif ($_ =~ /^FONTBOUNDINGBOX\s+([[:digit:]]+)\s+([[:digit:]]+)\s+[-[:digit:]]+\s+[-[:digit:]]+\s*$/) {
		$width=$1;
		$height=$2;
		print STDOUT "# Width: ".$1."\n";
		print STDOUT "# Height ".$2."\n";
	} elsif ($_ =~ /^ENCODING\s+([[:digit:]]+)\s*$/) {
		$codepoint=$1;
	} elsif ($_ =~ /^BITMAP\s*$/) {
		$doing=1;
	} elsif ($_ =~ /^STARTCHAR\s+(.*)$/) {
		$charname=$1;
	} elsif ($_ =~ /^ENDCHAR\s*$/) {
		printf(STDOUT "%04X:%s\n",$codepoint,&tohex($bitmap)) if $doing;
		$codepoint=-1;
		$bitmap='';
		$doing=0;
	} elsif ($doing && $_ =~ /^([[:xdigit:]]+)\s*$/) {
		if ($width > 8) {
			$bitmap.=pack("n",hex($1));
		} else {
			$bitmap.=pack("C",hex($1));
		}
	}
}

# vim:sts=2 sw=2 ts=2 noet
