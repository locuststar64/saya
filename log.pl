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

sub redirect {
    my $status = shift;
    my $url    = shift;
    print
"Status: $status Moved\r\nLocation: $url\r\nCache-control: private, max-age=10800, s-maxage=0\r\nContent-type: text/plain\r\nContent-length: 0\r\n\r\n";
}

sub defaultExit {
    redirect( 301, $$config{"notFoundUrl"} );
    exit(0);
}

defaultExit() if ( !exists $ENV{'PATH_INFO'} );

my ($probe) = $ENV{'PATH_INFO'} =~ m#^/([0-9A-F]+)#;
defaultExit() if ( !$probe );

my $saya = Saya->new($config);
defaultExit() if ( $saya->connect() );

my $probeInfo = $saya->getProbe( $saya->fromHex($probe) );
defaultExit() if ( !$probeInfo );

redirect( 302, $$probeInfo{"redirect"} );
exit(0) if ( $$probeInfo{"isactive"} == 0 );

my $ref = $ENV{'HTTP_REFERER'};

my $ip = undef;
$ip = $ENV{'HTTP_X_REAL_IP'} if ( exists $ENV{'HTTP_X_REAL_IP'} );
$ip = $ENV{'HTTP_X_FORWARDED_FOR'} if ( !$ip && exists $ENV{'HTTP_X_FORWARDED_FOR'} );
$ip = $ENV{'REMOTE_ADDR'} if ( !$ip && exists $ENV{'REMOTE_ADDR'} );

exit(0) if ( !$ref || !$ip );

my ($host) = $ref =~ m!https?://([^:/]+)!;
exit(0) if ( $saya->isValidHost($host) == 0 );

$host = $$probeInfo{"host_override"} if ( $$probeInfo{"host_override"} );
$saya->addLogEntry( $ip, $host, $ref, $$probeInfo{"id"} );

$saya->disconnect();
