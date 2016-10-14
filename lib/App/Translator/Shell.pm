package App::Translator::Shell;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;
use Encode qw(encode_utf8);

use feature qw(signatures);
no warnings qw(experimental::signatures);

has translator => (
    isa      => 'App::Translator', # XXX App::Translator::Core
    required => 1,
);

has stdout => (
    isa      => 'FileHandle',
    required => 0,
);

has _dispatch_table => (
    isa => 'HashRef',
    default => sub {
        {
            'change-language'   => '_do_change',
            'switch'            => '_do_switch',
            'mode'              => '_do_mode_change',
            'debug'             => '_do_debug',
            'add-plugin'        => '_do_add_plugin',
			'remove-plugin'     => '_do_remove_plugin',
            'help' 			    => '_do_help',
        }
    },
);

has min_chars_for_pager => (
    isa => 'Int',
    default => 5000,
);

has min_lines_for_pager => (
    isa => 'Int',
    default => 40,
);

has prompt_format => (
    isa     => 'HashRef[Str]', # TODO keys must be of type TranslatorMode
    default => sub {
        {
            dictionary   => '%s - %s > ',
            thesaurus    => 'Thesaurus (%s) > ',
            definition   => 'Define (%s) > ',
            encyclopedia => 'Encyclopedia (%s) > ',
        }
    }
);

has help_text => (
	isa     => 'Str',
    default => sub {
        return <<EOH
COMMANDS

/c(hange-language) lang1 [lang2]              change languages
/s(witch)                                     switch primary and secondary languages
/m(ode) mode                                  change mode (mode has to be one of: dictionary, thesaurus, definition, encyclopedia)
/a(dd-plugin) plugin-name [plugin-arguments]  add a plugin
/r(emove-plugin) plugin-name                  remove a plugin
/d(ebug)                                      turn on debug mode
/h(elp)                                       display this text

EXAMPLES:

/c en de       sets primary language to English and secondary language to German
/c it          sets primary language to Italian
/m e           switches to encyclopedia mode
/m t           switches to thesaurus mode
/a GoogleTranslate api_key XXXX    adds 'GoogleTranslate' plugin with api key XXXX
/r Woorden        removes 'Woorden' plugin

EOH
    }
);

sub get_prompt($self) {
    my $method = "_get_prompt_values_" . $self->translator->mode;
    return sprintf($self->prompt_format->{$self->translator->mode}, $self->$method);
}

sub _get_prompt_values_dictionary($self) { ($self->translator->from, $self->translator->to); }
sub _get_prompt_values_thesaurus($self) { $self->translator->from; }
sub _get_prompt_values_definition($self) { $self->translator->from; }
sub _get_prompt_values_speech($self) { $self->translator->from; }
sub _get_prompt_values_encyclopedia($self) { $self->translator->from; }

sub _dispatch ($self, $method, @args) {
    my @matching_methods = grep {/^$method/} keys %{$self->_dispatch_table};
    if (@matching_methods > 1) {
        die "Ambiguous command, matches: @matching_methods\n";
    }
    if (@matching_methods == 0) {
        die "Sorry no matching methods\n";
    }

    my $method_match = $self->_dispatch_table->{$matching_methods[0]};
    return $self->$method_match(@args);
}

sub _do_change ($self, $lang1, $lang2 = undef) {
    $self->translator->from($lang1);
    $self->translator->to($lang2) if $lang2;
    print {$self->stdout} "OK\n";
}

sub _do_switch ($self) {
        my $from = $self->translator->from;
        $self->translator->from($self->translator->to);
        $self->translator->to($from);
        print {$self->stdout} "OK\n";
}

sub _do_debug ($self) {
    $self->translator->debug_messages(!$self->translator->debug_messages);
    print {$self->stdout} "Debug messages: " . ($self->translator->debug_messages ? "On\n" : "Off\n");
}

sub _do_mode_change ($self, $mode) {
    my $mode_quoted = quotemeta($mode);
    if ('thesaurus' =~ m/^$mode_quoted/) {
        $self->translator->mode("thesaurus");
        print {$self->stdout} "OK\n";
    }
    elsif ('dictionary' =~ m/^$mode_quoted/) {
        $self->translator->mode("dictionary");
        print {$self->stdout} "OK\n";
    }
    elsif ('definition' =~ m/^$mode_quoted/) {
        $self->translator->mode("definition");
        print {$self->stdout} "OK\n";
    }
    elsif ('encyclopedia' =~ m/^$mode_quoted/) {
        $self->translator->mode("encyclopedia");
        print {$self->stdout} "OK\n";
    } else {
        print {$self->stdout} "Unknown mode: $mode_quoted\n";
    }
}

sub _do_add_plugin ($self, $plugin_name, @plugin_args) {
    my $real_plugin_name = ucfirst $plugin_name;
    my $args = { @plugin_args }; # TODO this is not safe
    my $capabilities= try {
        $self->translator->add_plugin($real_plugin_name, $args);
    }
    catch {
        print {$self->stdout} "Couldn't add plugin: $_";
        0;
    };
    return unless $capabilities;
    print {$self->stdout} "OK\n";
    my $capability_list;
    if (@$capabilities <=  100) {
        $capability_list = join(', ', @$capabilities);
    } else {
        $capability_list = join(', ', @{$capabilities}[0..99]) . "...";
    }
    print {$self->stdout} "$plugin_name can handle the following modes: $capability_list\n";
}

sub _do_remove_plugin ($self, $plugin_name) {
    my $real_plugin_name = ucfirst $plugin_name;
    $self->translator->remove_plugin($plugin_name);
    print {$self->stdout} "OK\n";
}

sub _do_help ($self) {
	print {$self->stdout} $self->help_text;
}

sub _execute_command ($self, $command) {
    my ($method, @args) = split ' ', $command;
    return $self->_dispatch($method, @args);
}

sub process ($self, $input) {
    if (my ($command) = $input =~ m/^[!\/](.*)/) {
        return $self->_execute_command($command);
    }
    else {
        try {
            my $result = encode_utf8($self->translator->lookup($input));
            my $line_count = split "\n", $result;
            if ( (length($result) > $self->min_chars_for_pager) or ($line_count > $self->min_lines_for_pager)) {
                my $pager = $ENV{PAGER} || 'less';
                open(my $less, '|-', $pager, '-e') || die "Cannot pipe to $pager: $!";
                print $less $result;
                close($less);
                # XXX also print a bit to STDOUT?
            } else {
                print {$self->stdout} $result, "\n";
            }
        } catch {
            print {$self->stdout} "error: $_\n"
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
