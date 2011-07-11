#!perl -T
use Test::More tests => 5;

use_ok( 'MongoDB::Web' );
use_ok( 'MongoDB::Web::Store' );
use_ok( 'MongoDB::Web::Store::Shortcuts' );
use_ok( 'MongoDB::Web::Cursor' );
use_ok( 'MongoDB::Web::Resource' );

diag( "Testing MongoDB::Web $MongoDB::Web::VERSION, Perl $], $^X" );
