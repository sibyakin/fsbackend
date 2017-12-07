#!/usr/bin/env perl
#===============================================================================
#
#         FILE: start_server.pl
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

use Mojo::Server::Hypnotoad;

my $server = Mojo::Server::Hypnotoad->new;
$server->run('./fsbackend_app.pl');
