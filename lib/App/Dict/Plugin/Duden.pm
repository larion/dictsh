package App::Dict::Plugin::Duden;

use utf8;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

use HTML::TreeBuilder::XPath;

sub capabilities {
        ['definition-de','dictionary-de-de']
}

has init_options => (
    isa => 'HashRef',
    default => sub { {} },
);

with 'App::Dict::Roles::Plugin';

use feature qw(signatures);
no warnings qw(experimental::signatures);

sub define ($self, $lang, $word) {
    die "The plugin Duden supports only German (de)." unless $lang eq 'de';
    #use Encode qw/decode_utf8/;
    #my $word = decode_utf8($word);
    my %umlaut_mapping = (
        ä   => 'ae',
        ö   => 'oe',
        ü   => 'ue',
    );
    for my $umlaut (keys %umlaut_mapping) {
        my $replacement = $umlaut_mapping{$umlaut};
        $word =~ s/$umlaut/$replacement/g;
    }
    warn $word;
    my $htmltree = HTML::TreeBuilder::XPath->new_from_url("http://www.duden.de/rechtschreibung/$word");
    my @results = $htmltree->findvalues('//li[contains(@id,\'Bedeutung\')]/text()');
    if (!@results) {
        @results = $htmltree->findvalues('//div[@class="entry"]/text()');
    }
    return join " ", @results;
}


sub translate ($self, $lang1, $lang2, $word) { return $self->define($lang1, $word) }

=pod

=head1 NAME

App::Dict::Plugin::Duden - Plugin to get german word definitions from duden.de

=head1 AUTHOR

Larion Garaczi

=head1 DATE

2016

=cut
