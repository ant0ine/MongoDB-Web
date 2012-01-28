package MongoDB::Web::Cursor;
use Moose;

has 'cursor' => (
    is => 'rw',
    isa => 'MongoDB::Cursor',
    required => 1,
);

has 'class' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

=head1 METHODS

=head2 $class->new( cursor => ..., class => ... )

=head2 $self->next

=cut

sub next {
    my $self = shift;
    my $doc = $self->cursor->next;
    return unless $doc;
    my $class = $self->class;
    return $class->new_from_document($doc);
}

=head2 $self->all

=cut

sub all {
    my $self = shift;
    my $class = $self->class;
    return map {
        $class->new_from_document($_)
    } $self->cursor->all;
}

sub _proxy {
    my $self = shift;
    my $mtd = shift;
    $self->cursor->$mtd(@_);
    return $self;
}

=head2 $self->count

=cut

sub count { shift->cursor->count(@_) }

=head2 $self->has_next

=cut

sub has_next { shift->cursor->has_next(@_) }

=head2 $self->reset

=cut

sub reset { shift->cursor->reset(@_) }

=head2 $self->explain

=cut

sub explain { shift->cursor->explain(@_) }

=head2 $self->snapshot

=cut

sub snapshot { shift->cursor->snapshot(@_) }

=head2 $self->skip( ... )

Proxy to MongoDB::Cursor::skip. Returns a MongoDB::Web::Cursor.

=cut

sub skip { shift->_proxy(skip => @_) }

=head2 $self->limit( ... )

Proxy to MongoDB::Cursor::limit. Returns a MongoDB::Web::Cursor.

=cut

sub limit { shift->_proxy(limit => @_) }

=head2 $self->sort( ... )

Proxy to MongoDB::Cursor::sort. Returns a MongoDB::Web::Cursor.

=cut

sub sort { shift->_proxy('sort' => @_) }

=head2 $self->hint( ... )

Proxy to MongoDB::Cursor::hint. Returns a MongoDB::Web::Cursor.

=cut

sub hint { shift->cursor->hint(@_) }

=head1 ACCESSING UNDERLYING MONGODB OBJECTS

=head2 $self->cursor

Returns the underlying MongoDB::Cursor

=cut

1;
