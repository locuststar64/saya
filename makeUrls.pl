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

my $configfile = exists $ENV{"SAYA_CONFIG"} ? $ENV{"SAYA_CONFIG"} : "saya.conf";
my $config = do($configfile);
if ( !$config ) {
    print("Could not load configuration from '$configfile'. $!\n");
    exit(1);
}

my $key      = "";
my $logURL   = exists $$config{"logURL"} ? $$config{"logURL"} : "";
my $filename = "";
my $tiny     = "";
my $optsok   = GetOptions(
    "key=s"      => \$key,
    "logURL=s"   => \$logURL,
    "filename=s" => \$filename,
    "tiny"       => \$tiny
);

if ( !$optsok or !$key or !$logURL ) {
    print <<EOF;
 Usage:
   --key=128ABCD                     Probe key in hexdeceimal REQUIRED
   --logURL=http://a.com/log.pl      URL to log script (default read from config)
   --filename=my.png                 File extension (default "")
   --tiny                            Create a tiny URL
EOF
    exit(1);
}

$filename = "/" . $filename if ($filename);

my $mainURL = $logURL . "/" . $key;

if ( !$tiny ) {
    print "$mainURL$filename\n";
    exit(0);
}

my $rc = eval {
    require HTTP::Tiny;
    HTTP::Tiny->import();
    1;
};

if ( !$rc ) {
    print
      "Error: Could not load HTTP::Tiny package. Try cpan install HTTP::Tiny\n";
    exit(1);
}

my $http    = HTTP::Tiny->new();
my $tinyURL = "http://tinyurl.com/api-create.php?"
  . $http->www_form_urlencode( { "url" => $mainURL } );
my $response = $http->get($tinyURL);
if ( !$$response{"success"} || !$$response{"content"} ) {
    print "Tinyurl.com request failed: "
      . $$response{"reason"}
      . "\n  $tinyURL\n";
    exit(1);
}
print $$response{"content"} . $filename . "\n";

