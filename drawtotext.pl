#!/usr/bin/env perl

while(<>)
{
	chop;
	if ($_ =~ /^([[:xdigit:]]+):\s*([-#]+)\s*$/) {
		print STDOUT "U+IGNORE\tIND: ".$1."\n";
		$pattern = $2 =~ s/-/./gr;
		print STDOUT $pattern."\n";
	} elsif ($_ =~ /^\s*([-#]+)\s*$/) {
		$pattern = $1 =~ s/-/./gr;
		print STDOUT $pattern."\n";
	} elsif ($_ =~ /^\s*#\s*(.*)$/) {
		print STDOUT "\t".$1."\n";
	} else {
		print STDOUT $_."\n";
	}
}

# vim:sts=2 sw=2 ts=2 noet
