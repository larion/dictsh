package App::Translator::Roles::Plugin;
use Moose::Role;

requires qw(capabilities init_options);

no Moose::Role;
1;

=pod

=head1 NAME

App::Translator::Roles::Plugin

=head1 DESCRIPTION

This is the main generic Role for App::Translator plugins. Actually you should
use more specific roles like App::Translator::Roles::Plugin::Dictionary which
also include this role but declares a more specific interface suitable for a
given type of plugin.

=head1 SYNOPSIS

    package App::Translator::Plugin::X;

    use Moose;
    use namespace::autoclean;

    has capabilities => (
        isa     => 'ArrayRef',
        default => sub {
            ['definition-nl','dictionary-nl-nl']
        },
    );

    has api_key => (
        isa => 'Str',
        required => 1,
    );

    with 'App::Translator::Roles::Plugin::Dictionary';

    sub init_options {
        my $class = shift;

        return {
            api_key => {
                validate => sub { ... },
                text     => 'Please provide an API key for X: ',
            }
        }
    }

    sub translate {
        my $self = shift;
        my ($lang, $word) = @_;
        ...
        return $translation;
    }

    __PACKAGE__->meta->make_immutable;
    1;

=head1 REQUIRES

=head2 $class->init_options()

    Class method. List of arguments for new with validation and text. See
    synopsis for an example.

=head2 $self->capabilities()

    List of capabilities a plugin has. Something like:

        [qw(definition-nl dictionary-nl-nl dictionary-nl-en)]

    A capability is a string of the form "$mode-$lang1-$lang2" where $mode is one of
    "definition", "dictionary", "encyclopedia", "thesaurus" and $lang1 and $lang2 are
    ISO 639 language codes.

=cut
