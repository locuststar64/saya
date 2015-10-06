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

my $forumDbh = DBI->connect(
    $$config{"forumDSN"}, $$config{"forumUser"},
    $$config{"forumPass"}, { RaiseError => 1 }
) or die $DBI::errstr;

my $sayaDbh = DBI->connect(
    $$config{"sayaDSN"}, $$config{"sayaUser"},
    $$config{"sayaPass"}, { RaiseError => 1 }
) or die $DBI::errstr;

sub saya_addUserEntry {
    my $userid   = "" . shift;
    my $ip       = shift;
    my $username = shift;
    my $updatesql =
      qq(update saya_users set last=date(), userid=?, user=? where ip=?;);
    my $rv = $sayaDbh->do( $updatesql, undef, $userid, $username, $ip );
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
    elsif ( $rv == 0 ) {
        my $insertsql =
qq(insert into saya_users (userid, ip,user,last) values (?,?,?,date()););
        $sayaDbh->do( $insertsql, undef, $userid, $ip, $username );
    }
}

sub saya_addUserHistoryEntry {
    my $userid   = "" . shift;
    my $ip       = shift;
    my $username = shift;
    my $updatesql =
      qq(update saya_user_history set last=date(), user=? where ip=? and userid=?;);
    my $rv = $sayaDbh->do( $updatesql, undef, $username, $ip , $userid);
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
    elsif ( $rv == 0 ) {
        my $insertsql =
qq(insert into saya_user_history (userid, ip,user,last) values (?,?,?,date()););
        $sayaDbh->do( $insertsql, undef, $userid, $ip, $username );
    }
}


sub saya_clearOldUserEntries {
    my $maxAge = $$config{"maxUserIPAge"};
    $sayaDbh->do(
        qq(delete from saya_users where last < date('now','-$maxAge day');))
      if ($maxAge);
}

sub updateDiscourseUsers {
    my $maxAge = $$config{"maxUserIPAge"};
    my $sql =
qq(select id, username, ip_address from users where not ip_address is null and ( last_seen_at  > current_date - $maxAge ) order by last_seen_at;);
    my $row;
    my $sth = $forumDbh->prepare($sql);
    $sth->execute();
    while ( $row = $sth->fetchrow_arrayref() ) {
        saya_addUserEntry( @$row[0], @$row[2], @$row[1] );
        saya_addUserHistoryEntry( @$row[0], @$row[2], @$row[1] );
    }
    $sth->finish();
}

saya_clearOldUserEntries();
updateDiscourseUsers();

$forumDbh->disconnect();
$sayaDbh->disconnect();
