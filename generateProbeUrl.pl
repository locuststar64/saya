#!/usr/bin/perl
# The MIT License (MIT)
#
# Copyright (c) 2015 No Face Press, LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use Getopt::Long;
use strict;
use warnings;

my $config;

BEGIN {
    my $configfile =
      exists $ENV{"SAYA_CONFIG"} ? $ENV{"SAYA_CONFIG"} : "saya.conf";
    $config = do($configfile);
    if ( !$config ) {
        print("Could not load configuration from '$configfile'. $!\n");
        exit(1);
    }
    unshift( @INC, $$config{"sayaPath"} . "/lib" );
}

use Saya;

my $saya = Saya->new($config);
die $_ if ( $saya->connect() );

my $probe    = undef;
my $filename = "";
my $tiny     = "";
my $optsok   = GetOptions(
    "probe=s"    => \$probe,
    "filename=s" => \$filename,
    "tiny"       => \$tiny
);

if ( !$optsok or !defined($probe) ) {
    print <<EOF;
 Usage:
   --probe=12                        Probe id REQUIRED
   --filename=my.png                 File extension (default "")
   --tiny                            Create a tiny URL
EOF
    exit(1);
}

my $url;
my $err;

if ($tiny) {
    ( $url, $err ) = $saya->getTinyUrl( $probe, $filename );
}
else {
    ( $url, $err ) = $saya->getProbeUrl( $probe, $filename );
}

$saya->disconnect();

if ( !$url ) {
    print "$err\n" if ($err);
    print "Unknown error\n" if ( !$err );
    exit(1);
}

print "$url\n";

