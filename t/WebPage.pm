package WebPage;
use Moose;
extends 'MongoDB::Web::Resource';
with 'MongoDB::Web::Store::Shortcuts';

has 'title' => (
    traits => [qw( Property )],
    is => 'rw',
    isa => 'Str',
);

# this attribute has no Property trait
# it won't be stored
has 'is_fresh' => (
    is => 'rw',
    isa => 'Bool',
);

has outlinks => (
    traits => [qw( Property )],
    is => 'rw',
    isa => 'ArrayRefOfURI',
    uri_isa => 'WebPage',
    coerce => 1,
);

1;
