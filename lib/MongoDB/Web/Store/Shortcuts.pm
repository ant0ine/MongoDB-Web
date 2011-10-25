package MongoDB::Web::Store::Shortcuts;
use Moose::Role;

=head1 SYNOPSIS

 package WebPage;
 use Moose;
 extends 'MongoDB::Web::Resource';
 with 'MongoDB::Web::Store::Shortcuts';

 package main;
 use MongoDB::Web::Store;
 use WebPage;

 my $store = ...;
 WebPage->set_store( $store );

 my $page = WebPage->new( 'http://example.org' );
 $page->save;

=head1 DESCRIPTION

Using this role an setting the store gives you access to these shortcuts methods.

=cut

has store_access => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

my %class2store;

=head2 $class->set_store( $store )

Tell this role which store to use for this class.
To prevent error, the store can be set only once. 

=cut

sub set_store {
    my $class = shift;
    my ($store) = @_;
    die 'store required' unless $store;
    die 'store must be a MongoDB::Web::Store'
        unless $store->isa('MongoDB::Web::Store');
    die 'class must be a MongoDB::Web::Resource'
        unless $class->isa('MongoDB::Web::Resource');

    die 'store already set' if $class2store{$class};

    $class2store{$class} = $store;
}

sub _get_store {
    my $class = shift;
    $class = ref $class if ref $class;
    my $store = $class2store{$class}
        or die 'no store: use set_store';
    return $store;
}

=head2 $self->store_access( Bool )

Disable the load, load_referers, save, and remove methods.
This is usefull when you want this object to be render by a view,
to make sure this view does no IO (at least store IO)

=head2 $class->load_by_uri( $uri )

Short for $store->load_by_uri( $class => $uri )

=cut

sub load_by_uri {
    my $class = shift;
    return $class->_get_store->load_by_uri( $class => @_ );
}

=head2 $class->load_by_mongodb_id( $id )

Short for $store->load_by_mongodb_id( $class => $id )

=cut

sub load_by_mongodb_id {
    my $class = shift;
    return $class->_get_store->load_by_mongodb_id( $class => @_ );
}

=head2 $class->find( $query )

Short for $store->find( $class => $query )

=cut

sub find {
    my $class = shift;
    return $class->_get_store->find( $class => @_ );
}

=head2 $class->find_uri( $query )

Short for $store->find_uri( $class => $query )

=cut

sub find_uri {
    my $class = shift;
    return $class->_get_store->find_uri( $class => @_ );
}

=head2 $class->find_mongodb_id( $query )

Short for $store->find_mongodb_id( $class => $query )

=cut

sub find_mongodb_id {
    my $class = shift;
    return $class->_get_store->find_mongodb_id( $class => @_ );
}

=head2 $class->ensure_index( ... )

Short for $store->ensure_index($class => ...)

=cut

sub ensure_index {
    my $class = shift;
    return $class->_get_store->ensure_index($class => @_);
}

=head2 $class->drop_index( ... )

Short for $store->drop_index($class => ...)

=cut

sub drop_index {
    my $class = shift;
    return $class->_get_store->drop_index($class => @_);
}

=head2 $self->load( $property )

Short for $store->load( $self => $property )

=cut

sub load {
    my $self = shift;
    die 'no store access' unless $self->store_access;
    return $self->_get_store->load( $self => @_ );
}

=head2 $self->load_referers( $class => $property )

Short for $store->load_referers( $class => $property => $self )

=cut

sub load_referers {
    my $self = shift;
    my ($class, $property) = @_;
    die 'no store access' unless $self->store_access;
    return $self->_get_store->load_referers( $class => $property => $self );
}

=head2 $self->save

Short for $store->save($self)

=cut

sub save {
    my $self = shift;
    die 'no store access' unless $self->store_access;
    return $self->_get_store->save($self);
}

=head2 $self->remove

Short for $store->remove($self)

=cut

sub remove {
    my $self = shift;
    die 'no store access' unless $self->store_access;
    return $self->_get_store->remove($self);
}

1;
