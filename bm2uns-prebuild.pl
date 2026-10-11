#!/usr/bin/env perl

%done={};

sub regglyph_in
{
  my($u,$hex)=@_;

  if(!%done{$hex})
  {
    $done{$hex}=1;
    print '';
    for($i=0;$i<8;$i++){
      print '0x'.substr($hex,$i*2,2);
      print ',' if($i!=7);
    }
    print ',0x'.$a[0].",\n"
  }
}

sub regglyph
{
  my($u,$hex)=@_;
  return if length($hex)!=16;
  
  $u=oct('0x'.$u);

#  if(($u>=0x20 && $u<=0x7e) || (($u>=0xa0 && $u<=0x2ff) && ($u!=0xad)) || ($u>=0x2400 && $u<=0x2bff) || ($u>=0xff61 && $u<=0xff9f)
#     || ($u>=0x16a0 && $u<=0x16ff) || ($u>=0xe100 && $u<=0xebff))

  if(($u==0x20 || ($u>=0x2400 && $u<=0x2bff)
               || ($u>=0xe081 && $u<=0xebff))
               && ($u!=0x25fd && $u!=0x25fe && $u!=0x2615 && $u!=0x26aa
                  && $u!=0x26ab && $u!=0x26f5 && $u!=0x2b55))
  {
    &regglyph_in($u,$hex);
    # maybe inc 1right alt
  }
}

sub incfont
{
  #print '/*'.$_[0]."*/\n";
  open(F,'src/'.$_[0]);
  while(<F>)
  {
    chop;
    if(substr($_,0,2) eq 'U+')
    {
      &regglyph($u,$hex);
      $u=substr($_,2,5);
      $hex='';
    } else
    {
      $_=substr($_,0,8);
      if($_ =~ /^[\.\#]*$/)
      {
        tr/\.\#/01/;
        $hex.=sprintf('%02X',ord(pack('B8',$_)));
      }
    }
  }
  &regglyph($u,$hex);
  $hex='';
  close(F);
}

open(F,'fontfiles/unscii-8.hex');
while(<F>)
{
  chop;
  @a=split(':',$_);
  &regglyph(@a);
}
close(F);

incfont('font-c64.txt');
incfont('font-arcade.txt');
incfont('font-topaz.txt');
incfont('font-fantasy.txt');
incfont('font-mcr.txt');
incfont('font-alt.txt');
incfont('font-cpc.txt');
incfont('font-pc8.txt');
incfont('font-atari8.txt');
incfont('font-bbcg.txt');
incfont('font-st.txt');
incfont('font-thin.txt');
incfont('font-spectrum.txt');
incfont('font-pet.txt');
incfont('font-mc6670p.txt');
incfont('font-mc6847t1.txt');
