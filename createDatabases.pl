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
use DBI;

my $configfile = exists $ENV{"SAYA_CONFIG"} ? $ENV{"SAYA_CONFIG"} : "saya.conf";
my $config = do($configfile);
if ( !$config ) {
    print("Could not load configuration from '$configfile'. $!\n");
    exit(1);
}

my $sayaDbh = DBI->connect(
    $$config{"sayaDSN"}, $$config{"sayaUser"},
    $$config{"sayaPass"}, { RaiseError => 1 }
) or die $DBI::errstr;

$sayaDbh->do(
qq(create table saya_log ( ip VARCHAR(15), host VARCHAR(128), referer VARCHAR(256), last DATE, hits INT, probe INT, PRIMARY KEY (ip, host) );)
) or die($DBI::errstr);

$sayaDbh->do(
qq(create table saya_users ( ip VARCHAR(15), userid VARCHAR(64), user VARCHAR(128), last DATE, PRIMARY KEY (ip) );)
) or die($DBI::errstr);

$sayaDbh->do(
    qq(create table saya_suspects ( ip VARCHAR(15), PRIMARY KEY (ip) );))
  or die($DBI::errstr);

$sayaDbh->do(
    qq(create table saya_nolog ( host VARCHAR(128), PRIMARY KEY (host) );))
  or die($DBI::errstr);

$sayaDbh->do(
qq(create table saya_probes ( id INT, key INT, isactive INT, redirect VARCHAR(256), host_override VARCHAR(128), note VARCHAR(256), PRIMARY KEY (id) );)
) or die($DBI::errstr);

$sayaDbh->do( qq(create index saya_key_index on saya_probes ( key );) )
  or die($DBI::errstr);

$sayaDbh->disconnect();

