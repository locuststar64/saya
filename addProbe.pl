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

my $id            = 0;
my $isactive      = 1;
my $redirect      = "";
my $host_override = "";
my $note          = "";
my $optsok        = GetOptions(
    "id=s"       => \$id,
    "active=i"   => \$isactive,
    "redirect=s" => \$redirect,
    "host=s"     => \$host_override,
    "note=s"     => \$note
);

if ( !$optsok or !$redirect ) {
    print <<EOF;
 Usage:
   --redirect=http://a.com/i.png     Url to redirect users to (REQUIRED)
   --id=128ABCD                      Probe number in hexdeceimal, generated if missing
   --active=1                        Is the probe active, 0 or 1?  (default $isactive)
   --host=foo.com                    Host name override for hits (default "")
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
    my $probe = shift;
    return 0 if ( !$probe );
    my $sth = $sayaDbh->prepare(qq(select 1 from saya_probes where id=?;));
    $sth->execute($probe);
    my $rtn = $sth->fetchrow_arrayref() ? 1 : 0;
    $sth->finish();
    return $rtn;
}

$isactive = $isactive ? 1 : 0;
$id = hex($id) if ($id);
if ($id) {
    if ( saya_probeExists($id) ) {
        printf( "Error: Probe %X already exists.\n", $id );
        exit(1);
    }
}
else {
    do {
        $id = int( rand( time() ) * 1000 );
    } while ( saya_probeExists($id) );
}

my $sth = $sayaDbh->prepare(
qq(insert into saya_probes (id, isactive, redirect, host_override, note) values (?,?,?,?,?);)
);
$sth->execute( $id, $isactive, $redirect, $host_override, $note )
  or die($DBI::errstr);
$sth->finish();

printf( "%X\n", $id );

$sayaDbh->disconnect();

