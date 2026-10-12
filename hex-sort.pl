#!/usr/bin/perl
#
# Copyright (C) 1998, 2013 Roman Czyborra, Paul Hardy
# (Adapted for Unscii project by viznut in 2014)
# (Adapted from hex2bdf by Jonathan de Boyne Pollard in 2026)
#
# LICENSE:
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
use Getopt::Long;

$result = GetOptions ();

while (<>) {
	chomp;
	$glyph{hex($1)} = $2 if /^([0-9a-fA-F]+):([0-9a-fA-F]+)/;
}
@chars = sort {$a <=> $b} keys %glyph;

foreach $character (@chars)
{
	printf "%06X:%s\n", $character, $glyph{$character};
}
