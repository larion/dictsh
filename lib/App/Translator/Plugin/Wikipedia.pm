package App::Translator::Plugin::Wikipedia;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

use JSON;
use HTTP::Tiny;
use URI;
use HTML::FormatText;

use feature qw(signatures);
no warnings qw(experimental::signatures);

has _client => (
    isa     => 'HTTP::Tiny',
    default => sub { HTTP::Tiny->new },
    lazy    => 1,
);

#has capabilities => (
#    isa     => 'ArrayRef',
#    default => sub {
#		my @lang_list = qw(
#			ab ace ady af ak als am ang an rup as ast av ay az bal bm bjn bms ba bar bh bpy
#			bi no bs br bug my bxr yue bcl ch ce chr chy ny cv kw co cr crh da de dv dsb nl
#			dz pa et arz eml en myv eu ee fo hif fj frp fur ff gag gl gan glk gom got kl gn
#			gu ht hak ha haw mrj hsb hr is io ig ilo iu ia ie ik jv kbd kab xal kn pam krc
#			kaa ks csb km ki rw rn kv koi kg ku ky lad lbe lo ltg lez lt lij li ln jbo lmo
#			nds lg lb hu mai mg ml mt gv mr mzn mhr cdo nan min xmf mwl mdf mi na nv nap nl
#			ne new pih nrm frr lrc se nso nov nn nah oc cu or om os pfl pi pag pap ps pdc
#			pcd pms pl pnt qu ksh rm rue sah sm smg sg sa sc stq sco gd st sn scn szl
#			simple sd si sl sk so ckb azb srn sh su fi sv ss arc tl ty tg ta tara tt tet bo
#			ti tpi to ts tn tcy tum tk tyv tw tr udm ur ug uz ve vec vep la ga eo lv ca rmy
#			vro vo wa war cy vls fy pnb id ms pt es fr it sq vi sw ro ceb wo wuu xh yi yo
#			zam diq zea za zu cs el be old bg sr mk mn ru uk hy he ar fa hi bn te th ka ja
#			zh ko
#		);
#		my @capabilities = map {"encyclopedia-$_"} @lang_list;
#		return \@capabilities;
#    },
#);

sub capabilities {
    my @lang_list = qw(
        ab ace ady af ak als am ang an rup as ast av ay az bal bm bjn bms ba bar bh bpy
        bi no bs br bug my bxr yue bcl ch ce chr chy ny cv kw co cr crh da de dv dsb nl
        dz pa et arz eml en myv eu ee fo hif fj frp fur ff gag gl gan glk gom got kl gn
        gu ht hak ha haw mrj hsb hr is io ig ilo iu ia ie ik jv kbd kab xal kn pam krc
        kaa ks csb km ki rw rn kv koi kg ku ky lad lbe lo ltg lez lt lij li ln jbo lmo
        nds lg lb hu mai mg ml mt gv mr mzn mhr cdo nan min xmf mwl mdf mi na nv nap nl
        ne new pih nrm frr lrc se nso nov nn nah oc cu or om os pfl pi pag pap ps pdc
        pcd pms pl pnt qu ksh rm rue sah sm smg sg sa sc stq sco gd st sn scn szl
        simple sd si sl sk so ckb azb srn sh su fi sv ss arc tl ty tg ta tara tt tet bo
        ti tpi to ts tn tcy tum tk tyv tw tr udm ur ug uz ve vec vep la ga eo lv ca rmy
        vro vo wa war cy vls fy pnb id ms pt es fr it sq vi sw ro ceb wo wuu xh yi yo
        zam diq zea za zu cs el be old bg sr mk mn ru uk hy he ar fa hi bn te th ka ja
        zh ko
    );
    my @capabilities = map {"encyclopedia-$_"} @lang_list;
    return \@capabilities;
}

sub init_options { {} }

with 'App::Translator::Roles::Plugin';

sub get_article {
    my $self = shift;
    my ($lang, $title) = @_;
    my $uri = URI->new("https://$lang.wikipedia.org/w/api.php");
    $uri->query_form(
        format    => 'json',
        action    => 'query',
        prop      => 'extracts',
        titles    => $title,
        redirects => 'true',
    );
    my $response = $self->_client->get($uri->as_string);
    die "$response->{reason}\n" unless $response->{success};
    my $decoded_content = decode_json($response->{content});
    use Data::Dumper;
    my ($page) = values %{$decoded_content->{query}{pages}};
    my $result = HTML::FormatText->format_string($page->{extract});
    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
