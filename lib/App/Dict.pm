package App::Dict;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Try::Tiny;

our $VERSION = "0.01";

use feature qw(signatures);
no warnings qw(experimental::signatures);

enum DictMode => [qw(dictionary thesaurus definition encyclopedia speech)];

has plugin_config => (
    isa => 'HashRef',
    default => sub { {} },
);

has _plugins => (
    isa => 'HashRef[App::Dict::Roles::Plugin]',
    default => sub {{}},
);

has from => (
    isa      => 'Str',
    required => 1,
    is       => 'rw',
);

has to => (
    isa      => 'Str',
    required => 1,
    is       => 'rw',
);

has mode => (
    isa     => 'DictMode',
    default => 'dictionary',
    is      => 'rw',
);

has debug_messages => (
    isa     => 'Bool',
    default => 0,
    is      => 'rw',
);

sub d {
    my $self = shift;
    my $msg  = shift;
    warn "DEBUG: $msg" if $self->debug_messages;
};

sub get_current_mode_name ($self) {
    my @languages_for_current_mode;
    if ($self->mode eq 'dictionary') {
        @languages_for_current_mode = ($self->from, $self->to);
        return sprintf("%s-%s-%s", $self->mode, @languages_for_current_mode);
    } else {
        @languages_for_current_mode = $self->from;
        return sprintf("%s-%s", $self->mode, @languages_for_current_mode);
    }
}

sub get_plugin_instance_for_current_mode ($self) {
    my $mode = $self->get_current_mode_name;

    my $instance;
    for my $plugin_name (keys %{$self->plugin_config}) {
       my $plugin_conf = $self->plugin_config->{$plugin_name};
       $self->d("Checking plugin: $plugin_name\n");
       if ($plugin_conf->{supported_modes}{$mode}) { # so this plugin supports our current mode
            $self->d("$plugin_name can handle ${mode}!\n");
            if ($self->_plugins->{$plugin_name}) { # we already have an instance
                 $self->d("$plugin_name found in cache.\n");
                 $instance = $self->_plugins->{$plugin_name};
                 last;
            }
            # OK, then let's load it
            $self->_require_plugin($plugin_name);
            my $module_name =  $self->_plugin_name_to_module_name($plugin_name);
            $self->d("Successfully loaded $plugin_name. Initializing.");
            try {
                $self->_plugins->{$plugin_name} = $module_name->new($plugin_conf->{init_attributes});
                $instance = $self->_plugins->{$plugin_name};
            }
            catch {
                die "Failed to initialize plugin $plugin_name: $_";
            };
            $self->d("$plugin_name Initialized.");
            last;
        }
    }
    return $instance
}

sub can_handle_current_mode ($self) { $self->get_plugin_instance_for_current_mode ? 1 : 0 }

sub lookup ($self, $text) {
    my $instance = $self->get_plugin_instance_for_current_mode;

    die "No handler for @{[ $self->get_current_mode_name ]} found :(\n" unless $instance;

    my @languages_for_current_mode = $self->mode eq 'dictionary' ? ($self->from, $self->to) : ($self->from);

    my $method = {
        dictionary    => 'translate',
        definition    => 'define',
        speech        => 'speak',
        thesaurus     => 'get_synonyms',
        encyclopedia  => 'get_article',
    }->{$self->mode};

    return $instance->$method(@languages_for_current_mode, $text);
}

sub add_plugin ($self, $name, $plugin_args) {
    $self->_require_plugin($name);
    my $module_name = $self->_plugin_name_to_module_name($name);
    # XXX validation
    #
    # MOP (attribute trait) or $class->init_opts? (MOP would be nicer)
    #my $debug_text = "Adding plugin $module_name with capabilities: " . join(', ' @{$module_name->capabilities});
    #$self->d($debug_text));
    my @capabilities = @{$module_name->capabilities};
    $self->d("Adding plugin $module_name (with capabilities: @capabilities)");
    $self->plugin_config->{$name} = {
        init_attributes => $plugin_args,
        supported_modes => { map +($_ => 1), @capabilities },
    };
    return [@capabilities];
}

sub remove_plugin ($self, $name) {
    my $module_name = $self->_plugin_name_to_module_name($name);
    $self->d("Removing plugin $module_name");
    delete $self->plugin_config->{$name};
}

sub list_loaded_plugins ($self) {
    return $self->plugin_config
}

sub _plugin_name_to_module_name ($self, $plugin_name) { 'App::Dict::Plugin::' . $plugin_name }

sub _require_plugin ($self, $plugin_name) {
    my $module_name = $self->_plugin_name_to_module_name($plugin_name);
    my $path = ($module_name =~ s{::}{/}gr) . '.pm';
    $self->d("Loading $plugin_name ($path)");
    eval { require $path };
    if ($@) {
        die "Failed to load plugin $plugin_name: $@";
    }
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

App::Dict - Main controller module for dictsh

=head1 SYNOPSIS

	$dict = App::Dict->new();
	$dict->add_plugin('GoogleTranslate', {api_key => 'XXX'});
	$dict->mode('dictionary');
	$dict->from('en');
	$dict->to('de');
	my $result = $dict->lookup('whatever');

	$dict->add_plugin('Wikipedia');
	$dict->mode('encyclopedia');
	$dict->from('en');
	$result = $dict->lookup('Alexandria');

=head1 DESCRIPTION

This is the controller module that manages the plugins and which can be used to query
different dictionaries/encyclopedia programatically. For the command-line application
itself see bin/dictsh.

=head1 ATTRIBUTES

=head2 from

The source language.

=head2 to

The target language in dictionary mode. Not relevant in modes other than 'dictionary'.

=head2 mode

The mode. Can be one of qw(dictionary thesaurus definition encyclopedia speech).

=head1 METHODS

=head2 lookup($text)

Look up a given text or word in the current mode.

=head2 add_plugin($name, $plugin_args)

Add a plugin with the given arguments

=head2 remove_plugin($name)

Remove plugin with name $name

=head2 list_loaded_plugins

Return a data structure of loaded plugins and their settings.

=head1 AUTHOR

This module is written by Larion Garaczi <larion@cpan.org> (2016-2017)

=head1 SOURCE CODE

The source code for this module is hosted on GitHub L<https://github.com/larion/app-dict>.

Feel free to contribute :)

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2016-2017 Larion Garaczi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
