#! /usr/bin/perl

use warnings;
use strict;
use utf8;

use Term::ReadLine;
use Encode qw(encode_utf8 decode_utf8);
use Try::Tiny;
use Readonly;
use YAML::XS;

use App::Translator;
use App::Translator::Shell;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $config = YAML::XS::LoadFile('.app-dict.yml');

my $translator = App::Translator->new(
    from           => $config->{primary_language},
    to             => $config->{secondary_language},
    debug_messages => $config->{debug},
);

my $term = Term::ReadLine->new('dictionary CLI');
my $out = $term->OUT || \*STDOUT;
printf $out "langsh (v%s)\nFor help type /h\n", $translator->VERSION;

my $plugin_config = $config->{Plugins};
for my $plugin (keys %$plugin_config) {
    print "Loading plugin $plugin:";
    my $success = try {
        $translator->add_plugin($plugin, $plugin_config->{$plugin}{init_attributes});
    } catch {
        print " NOK: $_\n";
        0;
    };
    print " OK\n" if $success;
}


my $shell = App::Translator::Shell->new(
    translator => $translator,
    stdout     => $out,
);

while (defined ($_ = $term->readline($shell->get_prompt))) {
    # TODO decode according to locale
    my $decoded_command = decode_utf8($_);
	next unless $decoded_command =~ /\w/;
    $term->addhistory($decoded_command);
    try { $shell->process($decoded_command); }
    catch { print "error: $_"; };
}
