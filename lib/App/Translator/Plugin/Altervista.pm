package App::Translator::Plugin::Altervista;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use HTTP::Tiny;
use URI;

use feature qw(signatures);
no warnings qw(experimental::signatures);

has client => (
    isa     => 'HTTP::Tiny',
    default => sub { HTTP::Tiny->new },
    lazy    => 1,
);

has api_key => (
    isa      => 'Str',
    required => 1,
);

#has capabilities => (
#    isa     => 'ArrayRef',
#    default => sub {
#        [
#            'thesaurus-en', 'thesaurus-es', 'thesaurus-de', 'thesaurus-fr',
#            'thesaurus-it'
#        ];
#    },
#);

sub capabilities {
        [
            'thesaurus-en', 'thesaurus-es', 'thesaurus-de', 'thesaurus-fr',
            'thesaurus-it'
        ];
}

sub init_options {
    {
        api_key => {
            text => 'please provide an API key (you can get one at http://thesaurus.altervista.org/thesaurus/v1):',
            validation => sub {
                my $api_key = shift;
                my $self_to_be = __PACKAGE__->new(api_key => $api_key);
                try {
                    $self_to_be->get_synonyms('en', 'test');
                }
                catch {
                    die "Not able to make a call with this API key. :( $_";
                }
            },
        },
    }
}

with 'App::Translator::Roles::Plugin';

sub get_synonyms {
    my $self = shift;
    my ($lang, $word) = @_;
    my $locale = {
        en => 'en_US',
        es => 'es_ES',
        de => 'de_DE',
        fr => 'fr_FR',
        it => 'it_IT',
    }->{$lang};
    die "unsupported language: " . $lang unless $locale;
    my $uri = URI->new('http://thesaurus.altervista.org/thesaurus/v1');
    $uri->query_form(
        word     => $word,
        language => $locale,
        key      => $self->api_key,
        output   => 'json',
    );
    my $response = $self->client->get($uri->as_string);
    die "$response->{reason}\n" unless $response->{success};
    my $decoded_content = decode_json($response->{content});
    my $results_raw =  $decoded_content->{response};
    my @results = map
        {
            my $syn_group = $_->{list};
            $syn_group->{category} . " " . ( $syn_group->{synonyms} =~ s/|/ /r )
        }
        @$results_raw;
    return join "\n", @results;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
