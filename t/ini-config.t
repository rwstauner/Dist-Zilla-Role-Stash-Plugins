use strict;
use warnings;
use Test::More;
use Test::MockObject;

use Dist::Zilla::Tester;
use lib 't/lib';

my %confs = (
	't/ini-none' => undef,
	't/ini-sep'  => {
		mods => {
			'Test::Minus::PlugName' => { 'Attr::Name' => 'oops' },
			'Test::Plus::Mod::Name' => { '!goo-ber' => 'nuts', pea => 'nut' }
		},
		'argument_separator'  => '^([^|]+)\|([^|]+)$',
		_config => {
			'-PlugName|Attr::Name' => 'oops',
			'+Mod::Name|!goo-ber'  => 'nuts',
			'+Mod::Name|pea'       => 'nut',
		}
	},
	't/ini-test' => {
		mods => {
			'Test::At::ABundle' => {'fakeattr' => 'fakevalue1'},
			'Test::Minus::APlugin' => {'fakeattr' => 'fakevalue2'},
			'Test::ASection' => {'heading' => 'head5'},
			'Test::Minus::APlug::Name' => {'config' => 'confy'},
			'Test::Plugin' => {'strung' => 'high'},
		},
		'argument_separator'  => '^(.+?)\W+(\w+)$',
		_config => {
			'@ABundle-fakeattr'    => 'fakevalue1',
			'-APlugin/fakeattr'    => 'fakevalue2',
			'ASection->heading'    => 'head5',
			'-APlug::Name::config' => 'confy',
			'Plugin|strung'        => 'high',
		}
	}
);

my $mock = Test::MockObject->new;
foreach my $dir ( keys %confs ){

	my $zilla = Dist::Zilla::Tester->from_config(
		{ dist_root => $dir },
		{}
	);

	$zilla->build;

	my $mods = defined($confs{$dir}) ? delete($confs{$dir}->{mods}) : undef;

	is_deeply($zilla->stash_named('%Test'), $confs{$dir}, "stash matches in $dir");

	next unless $mods;

	foreach my $mod ( keys %$mods ){
		$mock->fake_module($mod, new => sub { bless {}, $_[0] });
		my $plug = $mod->new();
		isa_ok($plug, $mod);
		my $stash = $zilla->stash_named('%Test')->get_stashed_config($plug);
		is_deeply($stash, $mods->{$mod}, 'stashed config expected');
	}
}

done_testing;
