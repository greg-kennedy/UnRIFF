#!/usr/bin/perl
use strict;
use warnings;

# wrapper for reading
sub rd
{
  # args
  my ($fp, $size) = @_;
  my $rd_size = read($fp, my $buffer, $size);
  die "Short read on $fp: expected $size, got $rd_size: error $!\n" if $rd_size != $size;
  return $buffer;
}

die "Usage: ./UnRIFF.pl <infile.mp3> <outfile.mp3>\n" if scalar(@ARGV) != 2;
open (my $fpi, '<', $ARGV[0]) or die "Could not open file $ARGV[0]: $!\n";
binmode($fpi);
open (my $fpo, '>', $ARGV[1]) or die "Could not open file $ARGV[1]: $!\n";
binmode($fpo);

seek($fpi,0,2);
my $file_len = tell($fpi);
seek($fpi,0,0);
print "Parsing $ARGV[0] into $ARGV[1] ($file_len bytes)...\n";

# Read first 3 bytes to check for ID3v2 tag
my $header = rd($fpi,3);
if ($header eq 'ID3')
{
  # special ID3 handling
  print "\tInput file contains ID3v2 tag...\n";

  print $fpo $header;
  my $id3unused = rd($fpi,3);
  print $fpo $id3unused;

  # get size of ID3 tag
  my $id3size = rd($fpi,4);
  print $fpo $id3size;

  # unpack size and shuffle bits around
  my $tag_size = unpack('N', $id3size);
  $tag_size = ( (($tag_size & 0x7F000000) >> 3) |
                (($tag_size & 0x007F0000) >> 2) |
                (($tag_size & 0x00007F00) >> 1) |
                ($tag_size & 0x0000007F) );
  print "\tCopying $tag_size bytes from input to output...\n";

  my $tag = rd($fpi, $tag_size);
  print $fpo $tag;

  # update buffer
  $header = rd($fpi,3);
}

# grow header
$header .= rd($fpi,1);
die "Input does not appear to be a RIFF file, got '$header' instead\n" if ($header ne 'RIFF');
# success, find length of block
my $riff_size = unpack('V', rd($fpi,4));
print "\tFound RIFF identifier, with size $riff_size\n";

# search WAVE header
my $wave_header = rd($fpi,4);
die "Input is RIFF, but not RIFF-WAVE, got '$wave_header' instead\n" if ($wave_header ne 'WAVE');
print "\tFound WAVE chunk.\n";
# search fmt  header
my $fmt_header = rd($fpi,4);
die "Input is RIFF-WAVE, but lacks fmt chunk, got '$fmt_header' instead\n" if ($fmt_header ne 'fmt ');
# get fmt length
my $fmt_length = unpack('V', rd($fpi,4));
# get audio format
my $audio_fmt = unpack('v', rd($fpi,2));
die "Input has fmt subchunk, but is not type 85 (got $audio_fmt instead)\n" if ($audio_fmt != 85);
print "\tFound fmt  subchunk, length $fmt_length, audio format $audio_fmt\n";

# skip rest of fmt data
my $fmt_data = rd($fpi,$fmt_length - 2);

# next could be fact or (in damaged files) just data
my $data_header = rd($fpi,4);
if ($data_header eq 'data')
{
  print STDERR "WARN: expected fact subchunk, got data instead\n";
} else {
  die "Input is RIFF-WAVE, but lacks fact chunk, got '$data_header' instead\n" if ($data_header ne 'fact');
  # get fact length
  my $fact_length = unpack('V', rd($fpi,4));
  print "\tFound fact subchunk, length $fact_length\n";
  # skip rest of fact data
  my $fact_data = rd($fpi,$fact_length);

  # should be data chunk now
  $data_header = rd($fpi,4);
}

die "Input is RIFF-WAVE, but lacks data chunk, got '$data_header' instead\n" if ($data_header ne 'data');
my $data_size = unpack('V',rd($fpi,4));

# check for potential short-read
if (tell($fpi) + $data_size > $file_len)
{
  print STDERR "WARNING: DATA read size $data_size will extend past end of file, truncating...\n";
  $data_size = $file_len - tell($fpi);
}
print "\tCopying $data_size bytes of MP3 data to output.\n";
print $fpo rd($fpi,$data_size);
print "SUCCESS.\n";

if (tell($fpi) < $file_len)
{
  print STDERR "WARNING: Still have " . ($file_len - tell($fpi)) . " bytes left at EOF!\n";
}
