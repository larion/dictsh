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

sub lookup ($self, $text) {
    my $mode;
    my @languages_for_current_mode;
    if ($self->mode eq 'dictionary') {
        @languages_for_current_mode = ($self->from, $self->to);
        $mode = sprintf("%s-%s-%s", $self->mode, @languages_for_current_mode);
    } else {
        @languages_for_current_mode = $self->from;
        $mode = sprintf("%s-%s", $self->mode, @languages_for_current_mode);
    }
    my $method = {
        dictionary    => 'translate',
        definition    => 'define',
        speech        => 'speak',
        thesaurus     => 'get_synonyms',
        encyclopedia  => 'get_article',
    }->{$self->mode};

    my $instance;
    for my $plugin_name (keys %{$self->plugin_config}) {
       my $plugin_conf = $self->plugin_config->{$plugin_name};
       $self->d("Checking plugin: $plugin_name\n");
       if ($plugin_conf->{supported_modes}{$mode}) { # so this plugin supports our current mode
            $self->d("$plugin_name can handle ${mode}!");
            if ($self->_plugins->{$plugin_name}) { # we already have an instance
                 $self->d("Loading $plugin_name from cache.");
                 $instance = $self->_plugins->{$plugin_name};
                 last;
            }
            # OK, then let's load it
            $self->_require_plugin($plugin_name);
            my $module_name =  $self->_plugin_name_to_module_name($plugin_name);
            $self->d("Successfully loaded. Initializing.");
            try {
                $self->_plugins->{$plugin_name} = $module_name->new($plugin_conf->{init_attributes});
                $instance = $self->_plugins->{$plugin_name};
            }
            catch {
                die "Failed to initialize plugin $plugin_name: $_";
            };
            $self->d("Initialized.");
            last;
        }
    }

    die "No handler for $mode found :(\n" unless $instance;
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

sub _plugin_name_to_module_name ($self, $plugin_name) {
    return 'App::Dict::Plugin::' . $plugin_name;
}

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
