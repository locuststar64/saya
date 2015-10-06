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

sub redirect {
    my $status = shift;
    my $url    = shift;
    print
"Status: $status Moved\r\nLocation: $url\r\nCache-control: private, max-age=10800, s-maxage=0\r\nContent-type: text/plain\r\nContent-length: 0\r\n\r\n";
}

sub saya_isValidHost {
    my $host = shift;
    return 0 if ( !$host );
    my $sth = $sayaDbh->prepare(qq(select 1 from saya_nolog where host=?;));
    $sth->execute($host);
    my $rtn = $sth->fetchrow_arrayref() ? 0 : 1;
    $sth->finish();
    return $rtn;
}

sub saya_getProbe {
    my $probe = shift;
    return undef if ( !defined($probe) );
    my $sth = $sayaDbh->prepare(
qq(select id, redirect, isactive, host_override from saya_probes where key=?;)
    );
    $sth->execute($probe);
    my $row = $sth->fetchrow_arrayref();
    my $rtn =
      ( !$row )
      ? undef
      : {
        id            => @$row[0],
        redirect      => @$row[1],
        isactive      => @$row[2],
        host_override => @$row[3]
      };
    $sth->finish();
    return $rtn;
}

sub saya_addLogEntry {
    my $ip        = shift;
    my $host      = shift;
    my $ref       = shift;
    my $probeInfo = shift;
    return if ( !$host || !$ip || !$ref || !$probeInfo );
    $host = $$probeInfo{"host_override"} if ( $$probeInfo{"host_override"} );
    my $updatesql =
qq(update saya_log set last=datetime(), hits=hits+1, referer=? where ip=? and host=? and probe=?;);
    my $rv =
      $sayaDbh->do( $updatesql, undef, $ref, $ip, $host, $$probeInfo{"id"} );

    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
    elsif ( $rv == 0 ) {
        my $insertsql =
qq(insert into saya_log (ip, host,referer,probe,last,hits) values (?,?,?,?,datetime(),1););
        $sayaDbh->do( $insertsql, undef, $ip, $host, $ref, $$probeInfo{"id"} );
    }
}

sub defaultExit {
    redirect( 301, $$config{"notFoundUrl"} );
    exit(0);
}

defaultExit() if ( !exists $ENV{'PATH_INFO'} );

my ($probe) = $ENV{'PATH_INFO'} =~ m#^/([0-9A-F]+)#;
defaultExit() if ( !$probe );

my $probeInfo = saya_getProbe( hex $probe );
defaultExit() if ( !$probeInfo );

redirect( 302, $$probeInfo{"redirect"} );
exit(0) if ( $$probeInfo{"isactive"} == 0 );

my $ref = $ENV{'HTTP_REFERER'};

my $ip = $ENV{'REMOTE_HOST'};
$ip = $ENV{'HTTP_X_REAL_IP'} if ( !$ip );

exit(0) if ( !$ref || !$ip );

my ($host) = $ref =~ m!https?://([^:/]+)!;
exit(0) if ( saya_isValidHost($host) == 0 );

saya_addLogEntry( $ip, $host, $ref, $probeInfo );

$sayaDbh->disconnect();

