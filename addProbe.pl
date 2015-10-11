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

my $redirect      = "";
my $host_override = "";
my $creator       = "";
my $note          = "";
my $optsok        = GetOptions(
    "redirect=s" => \$redirect,
    "host=s"     => \$host_override,
    "creator=s"  => \$creator,
    "note=s"     => \$note
);

if ( !$optsok or !$redirect ) {
    print <<EOF;
 Usage:
   --redirect=http://a.com/i.png     Url to redirect users to (REQUIRED)
   --host=foo.com                    Host name override for hits (default "")
   --creator="bob"                   User name of the creator (default "")
   --note="for bob"                  Text note about probe (default "")
EOF
    exit(1);
}

my ( $id, $key ) =
  $saya->addProbe( $redirect, $creator, $note, $host_override );

printf( "%d %X\n", $id, $key );

$saya->disconnect();

