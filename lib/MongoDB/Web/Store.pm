package MongoDB::Web::Store;
use Moose;
use MongoDB::OID;

use MongoDB::Web;
use MongoDB::Web::Resource;
use MongoDB::Web::Cursor;

has 'database' => (
    is => 'rw',
    isa => 'MongoDB::Database',
    required => 1,
);

=head1 NAME

=head1 SYNOPSIS

 my $store = MongoDB::Web::Store->new(
     database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_web
 );

=head1 DESCRIPTION

=head1 METHODS

=head2 $class->new( database => $mdb )

Takes a MongoDB::Database in argument.

=head2 $self->load_by_uri( $class => $uri )

=cut

sub load_by_uri {
    my $self = shift;
    my $class = shift or die 'class required';
    my $uri = shift or die 'uri required';

    $uri = MongoDB::Web->canonical_uri($uri);
    my $c = $self->class_to_collection($class);

    my $doc = $c->find_one(
        { uri => $uri },
    );
    return unless $doc;
    return $class->new_from_document($doc);
}

=head2 $self->load_by_mongodb_id( $class => $id )

=cut

sub load_by_mongodb_id {
    my $self = shift;
    my $class = shift or die 'class required';
    my $id = shift or die 'id required';

    my $oid = MongoDB::OID->new( value => $id );
    my $c = $self->class_to_collection($class);

    my $doc = $c->find_one(
        { _id => $oid },
    );

    return unless $doc;
    return $class->new_from_document($doc);
}

=head2 $self->load( $resource => $property );

If the property type is URI then return the resource.
If the property type is ArrayRefOfURI then return a cursor.

=cut

sub load {
    my $self = shift;
    my $resource = shift or die 'resource required';
    die "must be a MongoDB::Web::Resource"
        unless $resource->isa('MongoDB::Web::Resource');
    my $property = shift or die 'property required';

    my $attr = $resource->meta->find_attribute_by_name( $property )
        or die 'property not found';
    my $type = $attr->type_constraint->name;

    die 'type must be URI or ArrayRefOfURI'
        unless $type eq 'URI' || $type eq 'ArrayRefOfURI';

    my $class = $attr->uri_isa
        or die "uri_isa not specified, cannot use load()";
    die "class must inherit from MongoDB::Web::Resource"
        unless $class->isa('MongoDB::Web::Resource');

    if ($type eq 'URI') {
        my $uri = $attr->get_value($resource)
            or die "URI attribute $property has no value";
        return $self->load_by_uri( $class => $uri );
    }
    else {
        my $uris = $attr->get_value($resource) || [];
        return $self->find($class => { uri => { '$in' => $uris } });
    }
}

=head2 $self->load_referers( $class => $property => $resource )

Note the misspelling inherited from the HTTP rfc. It's MongoDB-Web after all :)
Return a cursor.

=cut

sub load_referers {
    my $self = shift;
    my $class = shift or die 'class required';
    die "class $class must inherit from MongoDB::Web::Resource"
        unless $class->isa('MongoDB::Web::Resource');
    my $property = shift or die 'property required';
    my $resource = shift or die 'resource required';
    die "must be a MongoDB::Web::Resource"
        unless $resource->isa('MongoDB::Web::Resource');

    my $uri = $resource->uri;
    return $self->find( $class => { $property => $uri } );
}

=head2 $self->find( $class => $query )

Return a MongoDB::Web::Cursor that will instanciate the objects from the documents.

=cut

sub find {
    my $self = shift;
    my $class = shift or die 'class required';
    my $cursor = $self->raw_find($class => @_);
    return MongoDB::Web::Cursor->new(cursor => $cursor, class => $class);
}

=head2 $self->raw_find( $class => $query )

Same as find, but return a MongoDB::Cursor instead of a Mongo::Web::Cursor.

This is useful if you want to retrieve only a few properties from a document.
eg: $self->raw_find( $class => $query )->fields( ... )

=cut

sub raw_find {
    my $self = shift;
    my $class = shift or die 'class required';
    my $query = shift or die 'query required';
    my $c = $self->class_to_collection($class);
    return $c->find($query);
}

=head2 $self->raw_update( $class => $mongodb_id => $properties)

Perform and atomic, in-place update, given a mongodb_id and a set of properties.

=cut

sub raw_update {
    my $self = shift;
    my $class = shift or die 'class required';
    my $id = shift or die 'id required';
    my $props = shift or die 'properties required';
    my $c = $self->class_to_collection($class);
    my $oid = MongoDB::OID->new( value => $id );
    $c->update({ _id => $oid }, { '$set' => $props });
}

=head2 $self->find_uri( $class => $query )

Same parameters as the find method, but returns an arrayref of uris.

=cut

sub find_uri {
    my $self = shift;
    my $class = shift or die 'class required';
    my $query = shift or die 'query required';
    return [
        map { $_->{uri} }
        $self->raw_find($class => $query)
            ->fields({ uri => 1 })
            ->all
    ];
}

=head2 $self->find_mongodb_id( $class => $query )

Same parameters as the find method, but returns an arrayref of mongodb ids.

=cut

sub find_mongodb_id {
    my $self = shift;
    my $class = shift or die 'class required';
    my $query = shift or die 'query required';
    return [
        map { $_->{_id}->value }
        $self->raw_find($class => $query)
            ->fields({ _id => 1 })
            ->all
    ];
}

=head2 $self->save( $resource )

Convert the object into a document, and upsert it into the right collection.

=cut

# TODO support options safe ?
sub save {
    my $self = shift;
    my ($resource) = @_;
    die "must be a MongoDB::Web::Resource"
        unless $resource->isa('MongoDB::Web::Resource');
    my $class = ref $resource;
    my $c = $self->class_to_collection($class);
    return $c->update(
        { uri => $resource->uri },
        $resource->document,
        { upsert => 1 }
    );
}

=head2 $self->remove($resource)

=cut

# TODO support option safe ?
sub remove {
    my $self = shift;
    my ($resource) = @_;
    die "must be a MongoDB::Web::Resource"
        unless $resource->isa('MongoDB::Web::Resource');
    my $class = ref $resource;
    my $c = $self->class_to_collection($class);
    return $c->remove({ uri => $resource->uri });
}

=head2 $self->ensure_index( $class => ... )

=cut

sub ensure_index {
    my $self = shift;
    my $class = shift or die 'class required';
    my $c = $self->class_to_collection($class);
    return $c->ensure_index(@_);
}

=head2 $self->drop_index( $class => ... )

=cut

sub drop_index {
    my $self = shift;
    my $class = shift or die 'class required';
    my $c = $self->class_to_collection($class);
    return $c->drop_index(@_);
}

=head1 ACCESSING UNDERLYING MONGODB OBJECTS.

=head2 $self->database

Returns the MongoDB::Database object.

=head2 $self->class_to_collection_name( $class_name )

=cut

# TODO support custom mapping
sub class_to_collection_name {
    my $self = shift;
    my ($class) = @_;
    die "class required" unless $class;
    $class =~ s/::/_/g;
    return lc $class;
}

=head2 $self->class_to_collection( $class_name )

=cut

my %uri_index_ensured;

sub class_to_collection {
    my $self = shift;
    my ($class) = @_;
    my $c_name = $self->class_to_collection_name($class);
    my $c = $self->database->$c_name();

    # don't run this all the times;
    unless ($uri_index_ensured{$c_name}) {
        $c->ensure_index({ uri => 1 }, { unique => 1 });
        $uri_index_ensured{$c_name}++;
    }

    return $c;
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

__PACKAGE__->meta->make_immutable;

1;
