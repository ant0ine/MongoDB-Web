#!perl -T
use Test::More tests => 4;

use_ok( 'MongoDB::Web' );
use_ok( 'MongoDB::Web::Store' );
use_ok( 'MongoDB::Web::Cursor' );
use_ok( 'MongoDB::Web::Resource' );

diag( "Testing MongoDB::Web $MongoDB::Web::VERSION, Perl $], $^X" );
