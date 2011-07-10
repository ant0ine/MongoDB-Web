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
    is => 'rw',
    isa => 'URI',
    required => 1,
    coerce => 1,
);

# TODO make it unmutable

=head1 NAME

MongoDB::Web::Resource

=head1 SYNOPSIS

=head1 DESCRIPTION

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
    my $meta = $self->meta;

    my @properties = 
        grep { $_->does('MongoDB::Web::Property') }
        $meta->get_all_attributes;

    my %document;
    $document{$_->name} = $_->get_value($self) for @properties;
    return \%document;
}

=head2 $class->new_from_document( $document )

=cut

sub new_from_document {
    my $class = shift;
    my ($doc) = @_;
    return bless $doc, $class;
}

1;
