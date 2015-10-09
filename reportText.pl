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
use JSON qw/encode_json/;

my $saya = Saya->new($config);
die $_ if ( $saya->connect() );
my $suspects  = $saya->getSuspects();
my $sharedIPs = $saya->getSharedIPs();
$saya->disconnect();

my $user;
my $log;
foreach $user (@$suspects) {
    printf( "USER: %s (%s)\n\n", $$user{"user"}, $$user{"userid"} );
    printf( "  %-15s %-19s %-4s %-5s %-28s %s\n",
        "IP", "DATE", "HITS", "PROBE", "HOST", "REFERER" );
    foreach $log ( @{ $$user{"log"} } ) {
        printf(
            "  %-15s %-19s %-4s %-5d %-28s %s\n",
            $$log{"ip"},    $$log{"last"}, $$log{"hits"},
            $$log{"probe"}, $$log{"host"}, $$log{"referer"}
        );
    }
    printf("\n\n");
}

my $ip;
foreach $ip (@$sharedIPs) {
    printf( "SHARED IP: %s\n\n", $$ip{"ip"} );
    printf( "  %-15s %-10s %s\n", "DATE", "USERID", "USER" );
    foreach $user ( @{ $$ip{"users"} } ) {
        printf( "  %-15s %-10s %s\n",
            $$user{"last"}, $$user{"userid"}, $$user{"user"} );
    }
    printf("\n\n");
}

