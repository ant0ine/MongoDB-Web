package MongoDB::Web::Resource;
use Moose;
use MongoDB::OID;
use URI;

use MongoDB::Web;
use MongoDB::Web::Property;

use Moose::Util::TypeConstraints;

subtype 'URI',
    as 'Str',
    where { $_ eq MongoDB::Web->canonical_uri($_)},
    message { "$_ is not a canonical URI, set coerce => 1" };

coerce 'URI',
    from 'Str', via { MongoDB::Web->canonical_uri($_) };

subtype 'ArrayRefOfURI',
    as 'ArrayRef[URI]';

coerce 'ArrayRefOfURI',
    from 'ArrayRef[Str]',
    via { [ map { MongoDB::Web->canonical_uri($_) } @$_ ] },
;

has 'uri' => (
    traits => [qw( Property )],
    is => 'ro',
    isa => 'URI',
    required => 1,
    coerce => 1,
);

has '_id' => (
    traits => [qw( Property )],
    is => 'ro',
    isa => 'Object',
);

=head1 NAME

MongoDB::Web::Resource

=head1 SYNOPSIS

=head1 DESCRIPTION

Note that the Moose attributes are cached to improve performance. The cache is filled at first use, after that the class is unmutable.

=head1 METHODS

=head2 $class->new( uri => $uri )

=head2 $self->uri

=head1 ACCESSING UNDERLYING MONGODB OBJECTS

=head2 $self->mongodb_id

Returns the MongoDB ID of the document.

=cut

sub mongodb_id {
    my $self = shift;
    my $oid = $self->{_id};
    return $oid ? $oid->value : undef;
}

=head2 $self->document

=cut

sub document {
    my $self = shift;
    my $class = ref $self;

    my %document;
    for (@{ $class->_get_property_attributes }) {
        my $name = $_->name;
        my $value = $_->get_value($self);
        next unless defined $value;
        $document{$name} = $value;
    }
    return \%document;
}

=head2 $class->new_from_document( $document )

=cut

sub new_from_document {
    my $class = shift;
    my ($doc) = @_;

    # the objects stored in the db have already been validated.
    # don't use the Moose constructor that rerun all this
    # validation/coercion.
    my $self = bless $doc, $class;

    my $meta = $class->meta;
    # but for the non stored attributes, apply the defaults.
    $_->initialize_instance_slot($meta, $self)
        for @{ $class->_get_other_attributes };

    return $self;
}

my $Attr_cache = {};

sub _warm_attr_cache {
    my $class = shift;
    my $meta = $class->meta;
    $Attr_cache->{$class} = {
        prop => [],
        other => [],
    };
    for my $attr ($meta->get_all_attributes) {
        if ($attr->does('MongoDB::Web::Property')) {
            push @{ $Attr_cache->{$class}{prop} }, $attr;
        }
        else {
            push @{ $Attr_cache->{$class}{other} }, $attr;
        }
    }
}

sub _get_property_attributes {
    my $class = shift;
    $class->_warm_attr_cache unless $Attr_cache->{$class};
    return $Attr_cache->{$class}{prop};
}

sub _get_other_attributes {
    my $class = shift;
    $class->_warm_attr_cache unless $Attr_cache->{$class};
    return $Attr_cache->{$class}{other};
}

__PACKAGE__->meta->make_immutable;

1;
