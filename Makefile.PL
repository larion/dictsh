use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::Translator',
    AUTHOR        => 'Larion Garaczi <larion@cpan.org>',
    VERSION_FROM  => 'lib/App/Dict.pm',
    ABSTRACT_FROM =>  'lib/App/Dict.pm',
    PREREQ_PM => {
        'HTTP::Tiny'                => 0,
        'HTML::FormatText'          => 0,
        'HTML::TreeBuilder::XPath'  => 0,
        'List::MoreUtils'           => 0,
        'JSON'                      => 0,
        'Moose'                     => 0,
        'MooseX::HasDefaults::RO'   => 0,
        'MooseX::StrictConstructor' => 0,
        'URI'                       => 0,
        'namespace::autoclean'      => 0,
        'Carp'                      => 0,
    },
    EXE_FILES => [
            'bin/dictsh',
    ],
);
