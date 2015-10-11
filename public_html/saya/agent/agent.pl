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
use URL::Encode qw/url_params_mixed/;

print "Content-type: application/json\r\n\r\n";

my $saya = Saya->new($config);
if ( $saya->connect() ) {
    print '{"error":"Could not connect to database."}';
    exit(0);
}

if ( !exists $ENV{'QUERY_STRING'} ) {
    print '{"error":"no query"}';
    $saya->disconnect();
    exit(0);
}

my $note    = "";
my $creator = "";
if ( exists $ENV{'REMOTE_USER'} ) {
    $creator = $ENV{'REMOTE_USER'};
}

my $params = url_params_mixed( $ENV{'QUERY_STRING'} );

if ( !exists $$params{"url"} or !$$params{"url"} ) {
    print '{"error":"no url query parameter"}';
    $saya->disconnect();
    exit(0);
}

my ( $probe, $key ) = $saya->addProbe( $$params{"url"}, $creator, $note );

my $url;
my $err;

( $url, $err ) =
  $saya->getTinyUrl( $saya->getProbeUrl($probe), $$params{"file"} );

$saya->disconnect();

if ( !$url ) {
    print "{\"error\":\"$err\"}" if ($err);
    print '{"error":"Unknown error"}' if ( !$err );
    exit(0);
}

print '{"url":"' . $url . '","probe":' . $probe . ',"key":' . $key . '}';

$saya->disconnect();
