package MongoDB::Web;
use warnings;
use strict;

use URI;

our $VERSION = '0.01';

=head1 NAME

MongoDB::Web - MongoDB + Moose + URI

=head1 SYNOPSIS

 package WebPage;
 use Moose;
 extends 'MongoDB::Web::Resource';
 # inherits the 'uri' attribute

 # this attribute is a "Property"
 # it will be stored in mongodb
 has 'title' => (
     traits => [qw( Property )],
     is => 'rw',
     isa => 'Str',
 );

 # this attribute is not a Property
 # it won't be stored
 has 'is_fresh' => (
     is => 'rw',
     isa => 'Bool',
 );

 # this property store an ArrayRef of WebPage URIs
 has outlinks => (
     traits => [qw( Property )],
     is => 'rw',
     isa => 'ArrayRefOfURI',
     uri_isa => 'WebPage',
     coerce => 1,
 );

 package main;
 use MongoDB::Web::Store;

 my $store = MongoDB::Web::Store->new(
     database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_database
 );

 # new resources
 my $page1 = WebPage->new(
     uri => 'http://example.org/1',
     outlinks => [ 'http://example.org/2' ],
 );
 $store->save($page1);

 my $page2 = WebPage->new(
     uri => 'http://example.org/2',
     outlinks => [ 'http://example.org/1' ],
 );
 $store->save($page2);
 
 # load resources
 my $loaded = $store->load_by_uri('http://example.org/1'); # this is page1 

 my $cursor = $store->load_referers( WebPage => outlinks => $page2 );
 $loaded = $cursor->next; # this is $page1

=head1 DESCRIPTION

MongoDB Object Mapper that is designed to store Web Resources (ie: Object that are identified by an URI)

=head1 METHODS

=cut

my $canonical_uri_maker = sub {
    my ($uri) = @_;
    return URI->new($uri)->canonical->as_string;
};

=head2 $class->canonical_uri( $uri )

This method is used internaly to validate the URIs and to make them canonical.
It is critical to store the URIs in their canonical form as they are used as primary keys.
This method is used for the validation and the coercion of the URI and ArrayRefOfURI attributes.

=cut

sub canonical_uri {
    my $class = shift;
    my $uri = shift or die 'uri required';
    return $canonical_uri_maker->($uri);
}

=head2 $class->set_alternate_canonical_uri_maker( sub { my $uri = shift; ...; return $uri; } )

You can provide your own canonical_uri method as a replacement of the standard one.

=cut

sub set_alternate_canonical_uri_maker {
    my $class = shift;
    my $maker = shift or die 'maker required';
    die 'make must be a coderef' unless ref $maker eq 'CODE';
    $canonical_uri_maker = $maker;
}

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Antoine Imbert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
