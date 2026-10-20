#!/usr/bin/env perl

$rows=2;

sub doublebytes
{
  my $r='';
  foreach(split('',$_[0])) { $r.=$_.$_; }
  return $r;
}

while(<>)
{
  chop;
  if ($_ =~ /^([\.\#]+)(\s*.*)$/) {
    $d = &doublebytes($1);
    print STDOUT $d.$2."\n";
    for (my $n = 1; $n < $rows; $n++) {
      print STDOUT $d."\n";
    }
  } else {
    if ($_ =~ /^8x16\s*$/) {
      $rows=1;
      print STDOUT "16x16\n";
    } elsif ($_ =~ /^8x8\s*$/) {
      $rows=2;
      print STDOUT "16x16\n";
    } else {
      print STDOUT $_."\n";
    }
  }
}

# vim:sts=2 sw=2
