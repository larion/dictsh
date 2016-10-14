package App::Dict::Plugin::GoogleTranslate;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

use WWW::Google::Translate;

sub capabilities {
    my @langs = qw(
        af ach ak am ar az be bem bg bh bn br bs ca chr ckb co crs cs cy da de
        ee el en eo es et eu fa fi fo fr fy ga gaa gd gl gn gu ha haw hi hr ht
        hu hy ia id ig is it iw ja jw ka kg kk km kn ko kri ku ky la lg ln lo
        loz lt lua lv mfe mg mi mk ml mn mo mr ms mt ne nl nn no nso ny nyn oc
        om or pa pcm pl ps pt-BR pt-PT qu rm rn ro ru rw sd sh si sk sl sn so
        sq sr st su sv sw ta te tg th ti tk tl tn to tr tt tum tw ug uk ur uz
        vi wo xh yi yo zh zu
    );
    my $capabilities;
    for my $lang1 (@langs) {
        for my $lang2 (@langs) {
            push @$capabilities, "dictionary-$lang1-$lang2" unless $lang1 eq $lang2;
        }
    }
    return $capabilities;
}

sub init_options {
    {
        api_key => {
            text => 'please provide an API key:', # TODO provide URL
            validation => sub {
                my $api_key = shift;
                my $self_to_be = __PACKAGE__->new(api_key => $api_key);
                try {
                    $self_to_be->translate('en', 'de', 'test');
                }
                catch {
                    die "Not able to make a call with this API key. :( $_";
                }
            },
        },
    }
}


has api_key => (
    isa => 'Str',
    required => 1,
);

has _client => (
    isa     => 'WWW::Google::Translate',
    builder => '_build_client',
    lazy    => 1,
);

sub _build_client {
    my $self = shift;

    WWW::Google::Translate->new(
        {
            key => $self->api_key,
        }
    );
}

with 'App::Dict::Roles::Plugin';

use feature qw(signatures);
no warnings qw(experimental::signatures);

sub translate ($self, $lang1, $lang2, $text) {
    my $result = try {
        # Suppress warnings; we will rethrow the exception anyways
        # but I am not happy with WWW::Google::Translate printing
        # to STDOUT
        local $SIG{__WARN__} = sub {};
        $self->_client->translate(
            {
                q      => $text,
                source => $lang1,
                target => $lang2,
            }
        );
    } catch {
        die "WWW:Google:Translate says: $_";
    };
    my $translations = join "\n", map $_->{translatedText}, @{ $result->{data}->{translations} };
    return $translations;
}

=pod

=head1 NAME

App::Dict::Plugin::GoogleTranslate

=head1 DESCRIPTION

Plugin to translate with the Google Translate API. A wrapper around
WWW::Google::Translate to play well with App::Dict.

=head1 AUTHOR

Larion Garaczi

=head1 DATE

2016

=cut
