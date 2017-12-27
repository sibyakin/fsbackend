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
use Sys::Info;
use XML::LibXML;
use Mojolicious::Lite;
use Mojo::Pg;

my $pg = Mojo::Pg->new('postgresql://127.0.0.1/fsbackend');

post '/xml_api/v1/dialplan' => sub {
    my $c   = shift;
    my $xml = mkxml();
    addaction( $xml, 'set', 'sip_sticky_contact=true' );
    addaction( $xml, 'hangup' );
    $c->render( data => $xml );
};

post '/xml_api/v1/directory' => sub {
    my $c   = shift;
    my $act = $c->req->body_params->param('action');
    my $id  = $c->req->body_params->param('sip_auth_username');
    if ( $act eq 'sip_auth' ) {

        # SQL::Abstract pod can explain a lot
        my $user = $pg->db->select(
            'accounts',
            [
                'id',               'password',
                'domain',           'acl',
                'vm_password',      'toll_allow',
                'context',          'caller_id_name',
                'caller_id_number', 'callgroup'
            ],
            { id => $id }
        )->hash;
        $c->stash(
            id               => $user->{id},
            password         => $user->{password},
            domain           => $user->{domain},
            acl              => $user->{acl},
            vm_password      => $user->{vm_password},
            toll_allow       => $user->{toll_allow},
            context          => $user->{context},
            caller_id_name   => $user->{caller_id_name},
            caller_id_number => $user->{caller_id_number},
            callgroup        => $user->{callgroup}
        );
    }
    $c->render( template => 'directory', format => 'xml' );
};

# Uncomment this if you want to prevent FreeSWITCH to fallback
# to local xml configs if this backend cannot satisfy request
#
#any '/*' => sub {
#    my $c = shift;
#    $c->render( template => 404, format => 'xml' );
#};

# Subroutine usage examples:
#
# addaction ("$xml", "fs app")
# addaction ("$xml", "fs app", "params of app")

sub addaction {
    my ( $xml, $app, $dat ) = @_;

    # Cool xpath stuff
    # be aware! context forcing (@=>$) magica here:
    my ($condition) =
      $xml->findnodes('/document/section/context/extension/condition');

    # <action application="" data="">
    my $action = $xml->createElement('action');
    $action->setAttribute( 'application' => $app );
    $action->setAttribute( 'data' => $dat ) if $dat;
    $condition->appendChild($action);

    return;

}

# LibXML boilerplate stuff

sub mkxml {

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

    return $xml;

}

my $sysinfo = Sys::Info->new;
my $cpuinfo = $sysinfo->device( CPU => my %options );

# yes, we want twice more workers than cores. Or more...
my $workers = ( $cpuinfo->count * 2 );
app->config( hypnotoad => { workers => $workers } );
app->start;

__DATA__

@@ directory.xml.ep
<?xml version="1.0" encoding="UTF-8"?>
<document type="freeswitch/xml">
  <section name="directory" description="User Directory">
    <domain name="<%= $domain %>">
      <params>
        <param name="dial-string" value="${sofia_contact(${dialed_user}@${dialed_domain})}"/>
      </params>
      <groups>
        <group name="default">
          <users>
            <user id="<%= $id %>" cacheable="true">
              <params>
                <param name="auth-acl" value="<%= $acl %>"/>
                <param name="password" value="<%= $password %>"/>
                <param name="vm-password" value="<%= $vm_password %>"/>
              </params>
              <variables>
                <variable name="toll_allow" value="<%= $toll_allow %>"/>
                <variable name="user_context" value="<%= $context %>"/>
                <variable name="effective_caller_id_name" value="<%= $caller_id_name %>"/>
                <variable name="effective_caller_id_number" value="<%= $caller_id_number %>"/>
                <variable name="callgroup" value="<%= $callgroup %>"/>
              </variables>
            </user>
          </users>
        </group>
      </groups>
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
