#!/usr/bin/env perl
# Copyright 2026 Jonathan de Boyne Pollard
# Public Domain is not a thing in U.K. law, so this is MIT "Expat"/ISC/2 Clause BSD/FreeBSD licenced.

while(<>)
{
	chop;
	if ($_ =~ /^'(.+)':(.*)$/) {
		print STDOUT "U+".ord($1)." ".$2."\n";
	} elsif ($_ =~ /^(0x[[:xdigit:]]+):\s*$/) {
		print STDOUT "IND: ".$1."\n";
	} elsif ($_ =~ /^"(.*)":\s*$/) {
		print STDOUT "U+".uc($1)."\n";
	} elsif ($_ =~ /^\s*#\s*(.*)$/) {
		print STDOUT "\t".$1."\n";
	} elsif ($_ =~ /^\s*([.@]+)\s*$/) {
		$pattern = $1 =~ s/@/#/gr;
		print STDOUT $pattern."\n";
	} else {
		print STDOUT $_."\n";
	}
}

# vim:sts=2 sw=2 ts=2 noet
