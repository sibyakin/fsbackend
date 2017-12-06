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

any '/xml_api/v1/dialplan' => sub {
    my $c = shift;
    $c->render_later;

    # <?xml version="1.0" encoding="UTF-8"?>
    my $xml = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    # <document type="freeswitch/xml">
    my $document = $xml->createElement('document');
    $document->setAttribute( 'type' => 'freeswitch/xml' );
    $xml->setDocumentElement($document);

    # <section name="dialplan">
    my $section = $xml->createElement('section');
    $section->setAttribute( 'name' => 'dialplan' );
    $document->appendChild($section);

    # <context name="default">
    my $context = $xml->createElement('context');
    $context->setAttribute( 'name' => 'default' );
    $section->appendChild($context);

    # <extension name="default">
    my $extension = $xml->createElement('extension');
    $extension->setAttribute( 'name' => 'default' );
    $context->appendChild($extension);

    # <condition>
    my $condition = $xml->createElement('condition');
    $extension->appendChild($condition);

    # <action application="" data="">
    my $action = $xml->createElement('action');
    $action->setAttribute( 'application' => 'hangup' );
    $condition->appendChild($action);

    $c->render( data => $xml );
};

any '/xml_api/v1/directory' => sub {
    my $c = shift;
    $c->render_later;
    $c->render( template => 'directory', format => 'xml' );
};

# Uncomment this if you want to prevent FreeSWITCH to fallback
# to local xml configs if this backend cannot satisfy request
#
#any '/*' => sub {
#    my $c = shift;
#    $c->render( template => 404, format => 'xml' );
#};

app->config( hypnotoad => { workers => $workers } );
app->start;
