use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'KSM::Logger',
    AUTHOR              => q{Karrick S. McDermott <karrick@karrick.net>},
    VERSION_FROM        => 'lib/KSM/Logger.pm',
    ABSTRACT_FROM       => 'lib/KSM/Logger.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::Class' => 0.35,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'KSM-Logger-*' },
);

sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';
.PHONY: rpm

rpm:	dist
	cpan2rpm --force --no-sign $(DISTVNAME).tar.$(SUFFIX)
MAKE_FRAG

    return $postamble;
}
