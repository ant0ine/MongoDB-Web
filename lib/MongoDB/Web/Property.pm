package MongoDB::Web::Property;
use Moose::Role;

has uri_isa => (
    is        => 'rw',
    isa       => 'Str',
);

=head2 $self->uri_isa

=cut

package Moose::Meta::Attribute::Custom::Trait::Property;
sub register_implementation { 'MongoDB::Web::Property' }

1;

