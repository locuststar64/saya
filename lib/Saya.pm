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
use HTTP::Tiny;
use JSON qw/decode_json/;
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

# Disconects from the database.
sub disconnect {
    my $self = shift;
    if ( $$self{"_dbh"} ) {
        $$self{"_dbh"}->disconnect();
        $$self{"_dbh"} = undef;
    }
}

#
# Returns information about the IP address.  Data is requested from ipinfo.io
# and cached locally in the database.
#
#  On success, the followind fields are returned.  However, some
#  fields may not exist if they do not have data.
#
# {
#    'country' => 'US',
#    'org' => '37.3860,-122.0838',
#    'ip' => '8.8.8.8',
#    'postal' => '94040',
#    'region' => 'California',
#    'hostname' => 'google-public-dns-a.google.com',
#    'city' => 'AS15169 Google Inc.',
#    'loc' => 'google-public-dns-a.google.com',
#    'phone' => '123'
#  }
#
#  On error...
# {
#    'err' => 1,
#    'reason' => 'bla bla bla'
# }
#
sub getIPInfo {
    my $self = shift;
    my $ip   = shift;

    my $sql =
qq(select hostname, loc, org, city, region, country, postal, phone from saya_ipinfo where ip=?;);
    my $sth = $$self{"_dbh"}->prepare($sql);
    $sth->execute($ip);
    my $row = $sth->fetchrow_arrayref();

    if ( !$row ) {
        my $http     = HTTP::Tiny->new();
        my $url      = "http://ipinfo.io/$ip/json";
        my $response = $http->get($url);

        if ( !$$response{"success"} || !$$response{"content"} ) {
            return { err => 1, reason => $$response{"reason"} };
        }

        my $data = decode_json( $$response{"content"} );

        # prevent undefined fields
        print "XXX: caching\n";
        my $sql2 =
qq(insert into saya_ipinfo (ip, hostname, loc, org, city, region, country, postal, phone, created) values (?,?,?,?,?,?,?,?,?,datetime()););
        my $sth2 = $$self{"_dbh"}->prepare($sql2);
        $sth2->execute(
            $ip,               $$data{"hostname"}, $$data{"hostname"},
            $$data{"loc"},     $$data{"org"},      $$data{"region"},
            $$data{"country"}, $$data{"postal"},   $$data{"phone"}
        );
        $sth2->finish();

        # rerun query
        $sth->execute($ip);
        $row = $sth->fetchrow_arrayref();
    }

    $sth->finish();

    my $rtn = { ip => $ip };

    # prevent undefined fields
    $$rtn{"hostname"} = @$row[0] if ( @$row[0] );
    $$rtn{"loc"}      = @$row[1] if ( @$row[1] );
    $$rtn{"org"}      = @$row[2] if ( @$row[2] );
    $$rtn{"city"}     = @$row[3] if ( @$row[3] );
    $$rtn{"region"}   = @$row[4] if ( @$row[4] );
    $$rtn{"country"}  = @$row[5] if ( @$row[5] );
    $$rtn{"postal"}   = @$row[6] if ( @$row[6] );
    $$rtn{"phone"}    = @$row[7] if ( @$row[7] );
    return $rtn;
}

# Removes all data that is past its expiration data.
#
sub purgeOldData {
    my $self = shift;

    $$self{"_dbh"}->do(
qq(delete from saya_ipinfo where created < date('now','-$$self{maxIPInfoAge} day');)
    );
    $$self{"_dbh"}->do(
qq(delete from saya_log where last < date('now','-$$self{maxLogAge} day');)
    );
    $$self{"_dbh"}->do(
qq(delete from saya_users where last < date('now','-$$self{maxUserIPAge} day');)
    );
}

# Updates the suspects table with current information.
sub updateSuspects {
    my $self = shift;

    $$self{"_dbh"}->do(qq(delete from saya_suspects;));

    $$self{"_dbh"}->do(
qq(insert into saya_suspects select distinct saya_users.ip from saya_users inner join saya_log on saya_users.ip = saya_log.ip;)
    );

}

# Check if a host is valoid for tracking.
#
# @param host the host name
# @return 1 if valid, 0 otherwise
sub isValidHost {
    my $self = shift;
    my $host = shift;
    return 0 if ( !$host );
    my $sth =
      $$self{"_dbh"}->prepare(qq(select 1 from saya_nolog where host=?;));
    $sth->execute($host);
    my $rtn = $sth->fetchrow_arrayref() ? 0 : 1;
    $sth->finish();
    return $rtn;
}

# Returns the probe information by key.
#
# @param probe the probe id
# @return probe info, undef otherwise
sub getProbe {
    my $self  = shift;
    my $probe = shift;
    return undef if ( !defined($probe) );
    my $sth =
      $$self{"_dbh"}->prepare(
qq(select id, key, redirect, isactive, host_override, creator, note from saya_probes where key=?;)
      );
    $sth->execute($probe);
    my $row = $sth->fetchrow_arrayref();
    my $rtn =
      ( !$row )
      ? undef
      : {
        id            => @$row[0],
        key           => @$row[1],
        redirect      => @$row[2],
        isactive      => @$row[3],
        host_override => @$row[4],
        creator       => @$row[5],
        note          => @$row[6]
      };
    $sth->finish();
    return $rtn;
}

# Returns the probe information by id.
#
# @param probe the probe id
# @return probe info, undef otherwise
sub getProbeById {
    my $self  = shift;
    my $probe = shift;
    return undef if ( !defined($probe) );
    my $sth =
      $$self{"_dbh"}->prepare(
qq(select id, key, redirect, isactive, host_override, creator, note from saya_probes where id=?;)
      );
    $sth->execute($probe);
    my $row = $sth->fetchrow_arrayref();
    my $rtn =
      ( !$row )
      ? undef
      : {
        id            => @$row[0],
        key           => @$row[1],
        redirect      => @$row[2],
        isactive      => @$row[3],
        host_override => @$row[4],
        creator       => @$row[5],
        note          => @$row[6]
      };
    $sth->finish();
    return $rtn;
}

# Adds a new log entry.
#
# @param ip - remote ip address
# @param host - referer host name
# @param ref - rreferer URL
# @param probe - probe id that triggered the log
# @return undef on sucess, error message on fail
sub addLogEntry {
    my $self  = shift;
    my $ip    = shift;
    my $host  = shift;
    my $ref   = shift;
    my $probe = shift;
    return if ( !$host || !$ip || !$ref || !defined($probe) );
    my $updatesql =
qq(update saya_log set last=datetime(), hits=hits+1, referer=? where ip=? and host=? and probe=?;);
    my $rv = $$self{"_dbh"}->do( $updatesql, undef, $ref, $ip, $host, $probe );

    if ( $rv < 0 ) {
        return $DBI::errstr;
    }

    if ( $rv == 0 ) {
        my $insertsql =
qq(insert into saya_log (ip, host,referer,probe,last,hits) values (?,?,?,?,datetime(),1););
        $$self{"_dbh"}->do( $insertsql, undef, $ip, $host, $ref, $probe );
    }
}

# Converts a hex string to a number.
# This fixes the 32 bite limitation of
# the native perl # hex function.
#
# @param s the hex string, invalid characters will signal stop of number passively.
# @return the numberic value
sub fromHex {
    my $self = shift;
    my $s    = shift;
    my $v    = 0;
    my %x    = (
        0 => 0,
        1 => 1,
        2 => 2,
        3 => 3,
        4 => 4,
        5 => 5,
        6 => 6,
        7 => 7,
        8 => 8,
        9 => 9,
        a => 10,
        b => 11,
        c => 12,
        d => 13,
        e => 14,
        f => 15,
        A => 10,
        B => 11,
        C => 12,
        D => 13,
        E => 14,
        F => 15
    );

  FH_LAST: for my $i ( 0 .. length($s) - 1 ) {
        my $ch = substr( $s, $i, 1 );
        last FH_LAST if ( !exists $x{$ch} );
        $v = $v * 16 + $x{$ch};
    }

    return $v;
}

# Returns the log URL associated with a probe.
#
# @param probeId = the probe id
# @param filename - optional filename to place at the end of the url.
# @return the url or undef if probe not found.
sub getProbeUrl {
    my $self     = shift;
    my $probeId  = shift;
    my $filename = shift;
    $filename = "" if ( !$filename );
    $filename = "/" . $filename if ($filename);

    my $probeInfo = $self->getProbeById($probeId);
    return undef if ( !$probeInfo );
    my $key = sprintf( "%X", $$probeInfo{"key"} );
    my $url = $$self{"logURL"} . "/" . $key . $filename;
    return $url;
}

# Returns the tiny url wrapper.
#
# @param url - the url to wrap
# @param filename - optional filename to place at the end of the url.
# @return the url or (undef, errmessage) if failed
sub getTinyUrl {
    my $self     = shift;
    my $url      = shift;
    my $filename = shift;
    $filename = "" if ( !$filename );
    $filename = "/" . $filename if ($filename);
    my $http    = HTTP::Tiny->new();
    my $tinyURL = "http://tinyurl.com/api-create.php?"
      . $http->www_form_urlencode( { "url" => $url } );
    my $response = $http->get($tinyURL);

    if ( !$$response{"success"} || !$$response{"content"} ) {
        return ( undef, $$response{"reason"} );
    }
    return $$response{"content"} . $filename;
}

# Returns if a probe key exist.
#
# @param key - the probe key
# @return 1 if exists, 0 otherwise
sub probeKeyExists {
    my $self = shift;
    my $key  = shift;
    return 0 if ( !$key );
    my $sth =
      $$self{"_dbh"}->prepare(qq(select 1 from saya_probes where key=?;));
    $sth->execute($key);
    my $rtn = $sth->fetchrow_arrayref() ? 1 : 0;
    $sth->finish();
    return $rtn;
}

# Returns the new probe id for a destination url.
#
# @param redirect - the url to generate a probe for
# @param creator - (optional) name of the user who is creating the probe.
# @param note - (optional) note
# @param host_override - (optional) hostname to use
# @return the (probe id, key) or (0, error message)  if failed
sub addProbe {
    my $self          = shift;
    my $redirect      = shift;
    my $creator       = shift;
    my $note          = shift;
    my $host_override = shift;
    my $key;

    #generate the probe key
    do {
        $key = int( rand( time() ) * 1000 );
    } while ( $self->probeKeyExists($key) );

    # Generate the id
    my $sth = $$self{"_dbh"}->prepare(qq(select max(id) from saya_probes;));
    $sth->execute();
    my $id  = 1;
    my $row = $sth->fetchrow_arrayref();
    $id = @$row[0] + 1 if ($row);
    $sth->finish();

    $sth =
      $$self{"_dbh"}->prepare(
qq(insert into saya_probes (id, key, isactive, redirect, host_override, creator, note) values (?,?,1,?,?,?,?);)
      );
    $sth->execute( $id, $key, $redirect, $host_override, $creator, $note )
      or return ( 0, $DBI::errstr );
    $sth->finish();

    return ( $id, $key );

}
