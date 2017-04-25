package App::Dict::Result;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Moose;
with 'Throwable';

has text => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

use overload
    '""' => sub { my $self = shift; return $self->text};

1;
