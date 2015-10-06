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
use Getopt::Long;

my $key           = 0;
my $isactive      = 1;
my $redirect      = "";
my $host_override = "";
my $creator       = "";
my $note          = "";
my $optsok        = GetOptions(
    "key=s"      => \$key,
    "active=i"   => \$isactive,
    "redirect=s" => \$redirect,
    "host=s"     => \$host_override,
    "creator=s"  => \$creator,
    "note=s"     => \$note
);

if ( !$optsok or !$redirect ) {
    print <<EOF;
 Usage:
   --redirect=http://a.com/i.png     Url to redirect users to (REQUIRED)
   --key=128ABCD                     Probe key in hexdeceimal, generated if missing
   --active=1                        Is the probe active, 0 or 1?  (default $isactive)
   --host=foo.com                    Host name override for hits (default "")
   --creator="bob"                   User name of the creator (default "")
   --note="for bob"                  Text note about probe (default "")
EOF
    exit(1);
}

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

sub saya_probeExists {
    my $key = shift;
    return 0 if ( !$key );
    my $sth = $sayaDbh->prepare(qq(select 1 from saya_probes where key=?;));
    $sth->execute($key);
    my $rtn = $sth->fetchrow_arrayref() ? 1 : 0;
    $sth->finish();
    return $rtn;
}

$isactive = $isactive ? 1 : 0;

# Generate the key
$key = hex($key) if ($key);
if ($key) {
    if ( saya_probeExists($key) ) {
        printf( "Error: Probe %X already exists.\n", $key );
        exit(1);
    }
}
else {
    do {
        $key = int( rand( time() ) * 1000 );
    } while ( saya_probeExists($key) );
}

# Generate the id
my $sth = $sayaDbh->prepare(qq(select max(id) from saya_probes;));
$sth->execute();
my $probe_id = 1;
my $row      = $sth->fetchrow_arrayref();
$probe_id = @$row[0] + 1 if ($row);
$sth->finish();

$sth = $sayaDbh->prepare(
qq(insert into saya_probes (id, key, isactive, redirect, host_override, creator, note) values (?,?,?,?,?,?,?);)
);
$sth->execute( $probe_id, $key, $isactive, $redirect, $host_override, $creator, $note )
  or die($DBI::errstr);
$sth->finish();

printf( "%X\n", $key );

$sayaDbh->disconnect();

