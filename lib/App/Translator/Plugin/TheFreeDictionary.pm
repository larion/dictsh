package App::Translator::Plugin::TheFreeDictionary;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;

use HTML::TreeBuilder::XPath;

sub capabilities {
        ['definition-en','dictionary-en-en']
}

has init_options => (
    isa => 'HashRef',
    default => sub { {} },
);

has _client => (
    isa => 'HTTP::Tiny',
    default => sub { HTTP::Tiny->new },
    lazy    => 1,
);

with 'App::Translator::Roles::Plugin';

use feature qw(signatures);
no warnings qw(experimental::signatures);

sub define ($self, $lang, $word) {
    die "The plugin TheFreeDictionary supports only English (en)." unless $lang eq 'en';
    my $response = $self->_client->get("http://www.thefreedictionary.com/$word");
    die sprintf(
        "Failed to fetch page from theefreedictionary.com:\n error: %s\n content: %s\n",
        $response->{error},
        $response->{content},
    ) unless $response->{success};
    my $htmltree = HTML::TreeBuilder::XPath->new_from_content($response->{content});
    my @results = $htmltree->findvalues('//*[@id="Definition"]//div[@class="ds-list" or @class="ds-single"]');
    return join "\n", @results;
}


sub translate ($self, $lang1, $lang2, $word) { return $self->define($lang1, $word) }

=pod

=head1 NAME

App::Translator::Plugin::TheFreeDictionary - Plugin to get English word definitions from thefreedictionary.com

=head1 AUTHOR

Larion Garaczi

=head1 DATE

2016

=cut
