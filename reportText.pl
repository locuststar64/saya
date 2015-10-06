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
use JSON qw/encode_json/;

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

my $sql =
qq(select distinct saya_users.userid, saya_users.user from saya_users inner join saya_suspects on saya_users.ip = saya_suspects.ip;);
my $sql2 =
qq(select distinct saya_log.host,saya_log.referer,saya_log.last,saya_log.hits,saya_log.ip,saya_log.probe from saya_log inner join saya_users on saya_users.ip = saya_log.ip where saya_users.userid=?;);
my $row;
my $sth  = $sayaDbh->prepare($sql);
my $sth2 = $sayaDbh->prepare($sql2);
$sth->execute();

while ( $row = $sth->fetchrow_arrayref() ) {
    printf( "USER: %s (%s)\n\n", @$row[1], @$row[0] );
    printf( "  %-15s %-10s %4s %-8s %-28s %s\n",
        "IP", "DATE", "HITS", "PROBE", "HOST", "REFERER" );
    my $row2;
    $sth2->execute( @$row[0] );
    while ( $row2 = $sth2->fetchrow_arrayref() ) {
        printf( "  %-15s %-10s %4s %-8d %-28s %s\n",
            @$row2[4], @$row2[2], @$row2[3], @$row2[5], @$row2[0], @$row2[1] );
    }
    printf("\n\n");
    $sth2->finish();
}
$sth->finish();

# Report on duplicate IP usage
$sql  = qq(select ip from saya_users group by ip having count(*) > 1;);
$sql2 = qq(select userid, user, last from saya_users where ip=?;);
$sth  = $sayaDbh->prepare($sql);
$sth2 = $sayaDbh->prepare($sql2);
$sth->execute();

while ( $row = $sth->fetchrow_arrayref() ) {
    printf( "SHARED IP: %s\n\n", @$row[0] );
    printf( "  %-15s %-10s %s\n", "DATE", "USERID", "USER" );
    my $row2;
    $sth2->execute( @$row[0] );
    while ( $row2 = $sth2->fetchrow_arrayref() ) {
        printf( "  %-15s %-10s %s\n", @$row2[2], @$row2[0], @$row2[1] );
    }
    printf("\n\n");
    $sth2->finish();
}
$sth->finish();

$sayaDbh->disconnect();
