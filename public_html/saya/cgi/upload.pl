#!/usr/bin/perl -CS
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
use utf8;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Encode q/encode_utf8/;

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

my $usergroup = param("usergroup");
my @filenames = param("file");
my @handles   = upload("file");

if ( $#filenames == -1 ) {
    my $file = 1;
    for ( my $index = 0 ; $file ; $index++ ) {
        $file = upload( "file" . $index );
        if ( $file && length($file) ) {
            push( @filenames, $file );
            push( @handles,   $file );
        }
    }
}

sub checkUser {

    return 0 if ( !exists $ENV{'REMOTE_USER'} );
    my $agent = $saya->getAgent( $ENV{'REMOTE_USER'} );
    return 0 if ( !$agent or !scalar( @{ $$agent{"usergroups"} } ) );

    #       $$agent{"usergroups"} = [2]; # XXX

    my @grp = ();
    foreach my $id ( @{ $$agent{"usergroups"} } ) {
        my $info = $saya->getUserGroupById($id);
        return 1 if ( $info && $$info{"name"} eq $usergroup );
    }
    return 0;
}

my $response = "Import failed";

if ( checkUser() == 1 ) {
    foreach my $handle (@handles) {
        open OUT, ">/tmp/x";
        print OUT $_ while (<$handle>);
        close(OUT);
        $saya->importUsersFromCSV( $usergroup, "/tmp/x" );
        $response = "Import complete";
    }
}
else {
    $response = "Not Authorized";
}

print "Content-type: text/html\r\n";
print "Content-Length: " . length( encode_utf8 $response) . "\r\n";
print "\r\n";
print "$response\n";

exit 0;

