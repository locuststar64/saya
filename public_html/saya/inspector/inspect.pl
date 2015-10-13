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

use Data::Dumper;
# get ip info
my %ipset = ();
my %probeset = ();
my $item;
my $ip;
foreach $item ( @$suspects ) {
   my $log;
   foreach $log ( @{$$item{"log"}} ) {
	$ipset{$$log{"ip"}} = 1;
	$probeset{$$log{"probe"}} = 1;
   }
}
foreach $item ( @$sharedIPs ) {
   $ipset{$$item{"ip"}} = 1;
}

my @keys = keys(%ipset);
my %ips =  ();
foreach $ip ( @keys ) {
  my $entry = $saya->getIPInfo($ip);
  $ips{$ip} = $entry if ($entry);
}

@keys = keys(%probeset);
my %probes =  ();
my $probe;
foreach $probe ( @keys ) {
  my $entry = $saya->getProbeById($probe);
   if ($entry) {
		 $$entry{"key"} = sprintf("%X", $$entry{"key"});
  $probes{$probe} = $entry;
	}
}

$saya->disconnect();

my $data = {
    suspects => $suspects,
    dupips   => $sharedIPs,
    probes   => \%probes,
    ips   => \%ips
};

my $json = encode_json($data);

print "Content-type: application/json\r\n";
print "Content-Length: " . length($json) . "\r\n";
print "\r\n";
print "$json\n";
