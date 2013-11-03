use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Pastee',
    VERSION_FROM  => 'lib/Pastee.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.23',
    },
    MIN_PERL_VERSION => '5.008001'
);

