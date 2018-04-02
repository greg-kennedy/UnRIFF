# UnRIFF
Some MP3s are in RIFF containers.  This tool will break them out.

## What
Trying to audit your MP3 collection?  MP3 is a stream format, not a container format.  So in MP3 history two solutions sprang up for this.
* Just pass around the raw streams anyway (95% of MP3s) plus ID3 tags bolted on somewhere, or
* Wrap MP3 in a RIFF container and distribute that.
These second class of files usually still play fine, but mp3check and similar tools will bomb with an error, as they only work on raw MP3 streams.

So, here is a Perl script you can use to "unRIFF" an MP3.

## How
`Usage: ./UnRIFF.pl <infile.mp3> <outfile.mp3>`

The tool reads from infile and writes to outfile.  Don't try to read and write the same file, that's stupid and probably going to just destroy your input file.

## Other
This was a quick-and-dirty script to get some files past mp3check validation.  It may not work for some, or many, cases.  Pull requests are gladly accepted!
