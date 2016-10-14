package App::Dict::Plugin::Synoniemen;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

use HTML::TreeBuilder::XPath;

sub capabilities {
        ['thesaurus-nl']
}

has init_options => (
    isa => 'HashRef',
    default => sub { {} },
);

with 'App::Dict::Roles::Plugin';

use feature qw(signatures);
no warnings qw(experimental::signatures);

sub get_synonyms ($self, $lang, $word) {
    die "The plugin Synoniemen supports only Dutch (nl)." unless $lang eq 'nl';
    my $htmltree = HTML::TreeBuilder::XPath->new_from_url("http://synoniemen.net/index.php?zoekterm=$word");
    my $result = join " ",
        $htmltree->findvalues('//dl[@class="alstrefwoordtabel"]/*/*');
    return $result;
}

=pod

=head1 NAME

App::Dict::Plugin::Synoniemen - Plugin to fetch Dutch synonyms from synoniemen.net

=head1 AUTHOR

Larion Garaczi

=head1 DATE

2016

=cut
