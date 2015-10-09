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
#
package Saya;

use DBI;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

our $VERSION = '0.10';

my $className = "Saya";

# Constructor
#
# Param config file
sub new {
    my $class = shift;
    my $self  = shift;
    bless $self, $class;
    return $self;
}

# Connect to the database
#
# @returns undef on success or err message on error
#
sub connect {
    my $self = shift;

    $$self{"_dbh"} = DBI->connect(
        $$self{"sayaDSN"}, $$self{"sayaUser"},
        $$self{"sayaPass"}, { RaiseError => 1 }
    );

    return $$self{"_dbi"} ? undef : $DBI::errstr;
}

# Returns a list of suspects.  A suspect is a user that was potentially identified in a logged site.
#  [
#        {
#            userid,
#            user,
#            log   => [
#                {
#                    host,
#                    referer,
#                    last,
#                    hits,
#                    probe,
#                    ip
#                }
#                ...
#            ]
#        }
#  ]
sub getSuspects {
    my $self     = shift;
    my @suspects = ();
    my $sql =
qq(select distinct saya_users.userid, saya_users.user from saya_users inner join saya_suspects on saya_users.ip = saya_suspects.ip order by saya_users.user;);
    my $sql2 =
qq(select distinct saya_log.host,saya_log.referer,saya_log.last,saya_log.hits,saya_log.ip,saya_log.probe from saya_log inner join saya_users on saya_users.ip = saya_log.ip where saya_users.userid=? order by saya_log.host, saya_log.ip;);
    my $row;
    my $sth  = $$self{"_dbh"}->prepare($sql);
    my $sth2 = $$self{"_dbh"}->prepare($sql2);
    $sth->execute();

    while ( $row = $sth->fetchrow_arrayref() ) {
        my @list = ();
        my $row2;
        $sth2->execute( @$row[0] );
        while ( $row2 = $sth2->fetchrow_arrayref() ) {
            push(
                @list,
                {
                    host    => @$row2[0],
                    referer => @$row2[1],
                    last    => @$row2[2],
                    hits    => @$row2[3],
                    probe   => @$row2[5],
                    ip      => @$row2[4]
                }
            );
        }
        $sth2->finish();
        push(
            @suspects,
            {
                userid => @$row[0],
                user   => @$row[1],
                log    => \@list
            }
        );
    }
    $sth->finish();

    return \@suspects;
}

# Returns duplicate IP usage
#  [
#        {
#            ip,
#            users   => [
#                {
#                    last,
#                    userid,
#                    user
#                }
#                ...
#            ]
#        }
#  ]
sub getSharedIPs {
    my $self = shift;

    # Report on duplicate IP usage
    my @dups = ();
    my $sql =
qq(select ip from saya_users group by ip having count(*) > 1 order by ip;);
    my $sql2 =
      qq(select userid, user, last from saya_users where ip=? order by user;);
    my $row;
    my $sth  = $$self{"_dbh"}->prepare($sql);
    my $sth2 = $$self{"_dbh"}->prepare($sql2);
    $sth->execute();

    while ( $row = $sth->fetchrow_arrayref() ) {
        my $row2;
        my @list = ();
        $sth2->execute( @$row[0] );
        while ( $row2 = $sth2->fetchrow_arrayref() ) {
            push(
                @list,
                {
                    last   => @$row2[2],
                    userid => @$row2[0],
                    user   => @$row2[1]
                }
            );
        }
        push(
            @dups,
            {
                ip    => @$row[0],
                users => \@list
            }
        );
        $sth2->finish();

    }
    $sth->finish();

    return \@dups;
}

sub disconnect {
    my $self = shift;
    if ( $$self{"_dbh"} ) {
        $$self{"_dbh"}->disconnect();
        $$self{"_dbh"} = undef;
    }
}
