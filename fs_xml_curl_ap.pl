#!/usr/bin/env perl
#===============================================================================
#
#         FILE: fs_xml_curl_ap.pl
#
#        USAGE: ./fs_xml_curl_ap.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Alexey Sibyakin (sibyakin@yahoo.com)
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 2017-12-05 02:43:12 PM
#     REVISION: ---
#===============================================================================

use utf8;
use 5.022;
use strict;
use warnings;

use Sys::Info;
use XML::LibXML;
use Mojolicious::Lite;

my $sysinfo = Sys::Info->new;
my $cpuinfo = $sysinfo->device( CPU => my %options );
my $workers =
  ( $cpuinfo->count * 2 );    # yes, we want twice more workers than cores

post '/xml_api/v1/example.com/dialplan' => sub {
    my $c = shift;
    $c->render( text => '/dialplan' );
};

post '/xml_api/v1/example.com/directory' => sub {
    my $c = shift;
    $c->render( template => 'example.com/directory', format => 'xml' );
};

any '/*' => sub {
    my $c = shift;
    $c->render( template => 404, format => 'xml' );
};

any '/' => sub {
    my $c = shift;
    $c->render( template => 404, format => 'xml' );
};

app->config( hypnotoad => { workers => $workers } );
app->start;
