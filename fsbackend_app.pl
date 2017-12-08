#!/usr/bin/env perl
#===============================================================================
#
#         FILE: fsbackend_app.pl
#
#        USAGE: ./start_server.pl
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

use EV;    # just to be sure
use DDP colored => 1;    # needed for debug only
use Sys::Info;
use XML::LibXML;
use Mojolicious::Lite;

post '/xml_api/v1/dialplan' => sub {
    my $c = shift;
    $c->render_later;
    say p $c->req->params;

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

post '/xml_api/v1/directory' => sub {
    my $c = shift;
    $c->render_later;
    say p $c->req->params;
    $c->render( template => 'directory', format => 'xml' );
};

# Uncomment this if you want to prevent FreeSWITCH to fallback
# to local xml configs if this backend cannot satisfy request
#
#any '/*' => sub {
#    my $c = shift;
#    $c->render( template => 404, format => 'xml' );
#};

my $sysinfo = Sys::Info->new;
my $cpuinfo = $sysinfo->device( CPU => my %options );
my $workers =
  ( $cpuinfo->count * 2 );    # yes, we want twice more workers than cores

app->config( hypnotoad => { workers => $workers } );
app->start;

__DATA__

@@ directory.xml.ep
<?ml version="1.0" encoding="UTF-8"?>
<document type="freeswitch/xml">
    <section name="directory">
        <domain name="example.com">
            <params>
                <param name="dial-string" value="{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})},${verto_contact(${dialed_user}@${dialed_domain})}"/>
                <param name="jsonrpc-allowed-methods" value="verto"/>
            </params>
            <users>
                <user id="1000" cacheable="true">
                    <params>
                        <param name="auth-acl" value="users"/>
                        <param name="password" value="1000"/>
                        <param name="vm-password" value="1000"/>
                    </params>
                    <variables>
                        <variable name="toll_allow" value="domestic,international,local"/>
                        <variable name="accountcode" value="1000"/>
                        <variable name="user_context" value="default"/>
                        <variable name="effective_caller_id_name" value="Extension 1000"/>
                        <variable name="effective_caller_id_number" value="1000"/>
                        <variable name="outbound_caller_id_name" value="Extension 1000"/>
                        <variable name="outbound_caller_id_number" value="1000"/>
                        <variable name="callgroup" value="techsupport"/>
                    </variables>
                </user>
            </users>
        </domain>
    </section>
</document>

@@ 404.xml.ep
<?xml version="1.0" encoding="UTF-8"?>
<document type="freeswitch/xml">
    <section name="result">
            <result status="not found" />
    </section>
</document>
