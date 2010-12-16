package Dist::Zilla::Stash::Test;
# ABSTRACT: Test Dist::Zilla::Role::Stash::Plugins

use strict;
use warnings;
use Moose;
with 'Dist::Zilla::Role::Stash::Plugins';

sub expand_package {
	my ($self, $pack) = @_;
	my %exp = qw(
		+ Plus
		- Minus
		@ At
	);
	$pack =~ s/^([@+-])/$exp{$1}::/;
	"Test::$pack";
}

1;
