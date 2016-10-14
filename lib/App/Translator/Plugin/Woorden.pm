package App::Translator::Plugin::Woorden;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

use HTML::TreeBuilder::XPath;
use List::MoreUtils qw/after_incl/;

#has capabilities => (
#    isa     => 'ArrayRef',
#    default => sub {
#        ['definition-nl','dictionary-nl-nl']
#    },
#);

sub capabilities {
        ['definition-nl','dictionary-nl-nl']
}

has init_options => (
    isa => 'HashRef',
    default => sub { {} },
);

with 'App::Translator::Roles::Plugin';

use feature qw(signatures);
no warnings qw(experimental::signatures);

sub define ($self, $lang, $word) {
    die "The plugin Woorden supports only Dutch (nl)." unless $lang eq 'nl';
    my $htmltree = HTML::TreeBuilder::XPath->new_from_url("http://www.woorden.org/woord/$word");
    my $result = join "\n",
        grep { /\w/ }
        List::MoreUtils::before {/Kernerman Dictionaries|Zoektips|Bron:/}
        after_incl {/$word/}
        $htmltree->findvalues("//div[\@style]/*/*");
    return $result;
}


sub translate ($self, $lang1, $lang2, $word) { return $self->define($lang1, $word) }

=pod

=head1 NAME

App::Translator::Plugin::Woorden - Plugin to download dutch word definitions from woorden.org

=head1 AUTHOR

Larion Garaczi

=head1 DATE

2016

=cut
