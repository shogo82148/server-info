#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Encode::Guess qw/euc-jp shiftjis 7bit-jis/;
use Getopt::Long;

my %opts = ();
GetOptions(
    \%opts,
    'help',
    'os',
    'mecab',
    'tinysvm',
    'yamcha',
    'crfpp',
    'cabocha',
    'perl',
    'python',
    'ruby',
    'emacs',
    'pukiwiki',
    'mediawiki',
    'markdown',
    'html');

my $info_subs = [
    ['OS Settings', 'os', \&info_os],
    ['Perl Settings', 'perl', \&info_perl],
    ['Python Settings', 'python', \&info_python],
    ['Ruby Settings', 'ruby', \&info_ruby],
    ['MeCab Settings', 'mecab', \&info_mecab],
    ['TinySVM Settings', 'tinysvm', \&info_tinysvm],
    ];

my @info_list = ();
for my $info(@$info_subs) {
    if($opts{$info->[1]}) {
        push(@info_list, [$info->[0], $info->[2]()]);
    }
}

if(@info_list==0) {
    for my $info(@$info_subs) {
        push(@info_list, [$info->[0], $info->[2]()]);
    }
}

if($opts{pukiwiki}) {
    for my $info(@info_list) {
        print "**$info->[0]\n";
        for my $item(@{$info->[1]}) {
            print "|$item->[0]|$item->[1]|\n";
        }
        print "\n";
    }
} elsif($opts{mediawiki}) {
    for my $info(@info_list) {
        print "=== $info->[0] ===\n";
        print "{|cellspacing=\"0\" border=\"1\" style=\"width:80%;\"\n";
        for my $item(@{$info->[1]}) {
            print "|-\n!style=\"width:200px\"|$item->[0]\n|$item->[1]\n";
        }
        print "|}\n\n";
    }
} elsif($opts{markdown}) {
    for my $info(@info_list) {
        print "# $info->[0]\n";
        for my $item(@{$info->[1]}) {
            print "- $item->[0]:  $item->[1]\n";
        }
        print "\n";
    }
} elsif($opts{html}) {
    print "<html><head><title>info</title></head><body>\n";
    for my $info(@info_list) {
        print "<h1>$info->[0]</h1>\n";
        print "<table><tbody>\n";
        for my $item(@{$info->[1]}) {
            print "<tr><td>$item->[0]</td><td>$item->[1]</td></tr>\n";
        }
        print "</tbody></table>\n\n";
    }
    print "</body></html>\n";
} else {
    for my $info(@info_list) {
        print "# $info->[0]\n";
        for my $item(@{$info->[1]}) {
            print "- $item->[0]:  $item->[1]\n";
        }
        print "\n";
    }
}

# OS
sub info_os {
    my $kernel_name = rmLF(`uname -s`);
    my $node_name = rmLF(`uname -n`);
    my $kernel_release = rmLF(`uname -r`);
    my $kernel_version = rmLF(`uname -v`);
    my $os = rmLF(`uname -o`);
    my $distribution_path = `ls /etc -F | grep "release\$\\\|version\$"`;
    my $distribution = rmLF(`cat /etc/$distribution_path`);
    my $cpuinfo = load_cpuinfo();
    my $num_cpu = @$cpuinfo;
    my $cpu_model = $cpuinfo->[0]{"model name"};
    my $meminfo = load_meminfo();
    my $mem_total = $meminfo->[0]{"MemTotal"};
    my $lang = $ENV{LANG};

    return [
        ['Distribution', $distribution],
        ['OS', $os],
        ['Kernel Name', $kernel_name],
        ['Kernel Release', $kernel_release],
        ['Kernel Version', $kernel_version],
        ['Node Name', $node_name],
        ['System Encoding', $lang],
        ['Number of CPUs', $num_cpu],
        ['CPU Model', $cpu_model],
        ['Memory Total', $mem_total],
        ];
}


# MeCab
sub info_mecab {
    my $mecab_ver = `mecab -v 2> /dev/null`;
    if($mecab_ver) {
        while(chomp $mecab_ver) {};

        # absolute path
        my $mecab_path = rmLF(`which mecab`);

        #The path to the system dictionary
        my $sys_dict_path = `mecab-config --dicdir`;
        $sys_dict_path =~ s/\n//g;

        #Encoding of the system dictionary
        my $test = `echo MeCab | mecab`;
        my $enc = Encode::Guess::guess_encoding($test);
        $enc = ref $enc ? $enc->name : $enc;

        #List of user dictionary
        my $rcpath = `mecab-config --sysconfdir`;
        $rcpath =~ s/\n//g;
        my $mecabrc = `echo $rcpath/mecabrc`;
        my $user_dict = 'None';
        if($mecabrc =~ /^userdic\s*=\s*(.*)$/) {
            $user_dict = $1;
        }

        #Perl Binding
        my $perl_binding = `perl -MMeCab -e 'print \$MeCab::VERSION' 2> /dev/null`;
        if($perl_binding and $perl_binding =~ /^[0-9.]+$/) {
            $perl_binding = rmLF($perl_binding);
        } else {
            $perl_binding = "Not Installed";
        }

        #Python Binding
        my $python_binding = `python -m MeCab -c 'print MeCab.VERSION' 2> /dev/null`;
        if($python_binding and $python_binding =~ /^[0-9.]+$/) {
            $python_binding = rmLF($python_binding);
        } else {
            $python_binding = "Not Installed";
        }

        #Ruby Binding
        my $ruby_binding = `ruby -rMeCab -e 'print MeCab::VERSION' 2> /dev/null`;
        if($ruby_binding and $ruby_binding =~ /^[0-9.]+$/) {
            $ruby_binding = rmLF($ruby_binding);
        } else {
            $ruby_binding = "Not Installed";
        }

        return [
            ['MeCab Version', $mecab_ver],
            ['Absolute Path', $mecab_path],
            ['System Dictionary Path', $sys_dict_path],
            ['System Dictionary Encode', $enc],
            ['User Dictionary', $user_dict],
            ['Perl Binding', $perl_binding],
            ['Python Binding', $python_binding],
            ['Ruby Binding', $ruby_binding],
            ];
    } else {
        return [
            ['MeCab Version', 'Not Installed'],
            ];
    }
}

#TinySVM
sub info_tinysvm {
    my $version = `svm_learn --version 2> /dev/null`;
    if($version and $version=~/(svm_learn of [0-9.]+)/) {
        $version = $1;
        my $path = rmLF(`which svm_learn`);
        my $perl_binding = rmLF(`perl -MTinySVM -e 'print "Installed"' 2> /dev/null` or 'Not Installed');
        my $python_binding = rmLF(`python -m TinySVM -e 'print "Installed"' 2> /dev/null` or 'Not Installed');
        my $ruby_binding = rmLF(`ruby -r TinySVM -e 'print "Installed"' 2> /dev/null` or 'Not Installed');

        return [
            ['Version', $version],
            ['Absolute Path', $path],
            ['Perl Binding', $perl_binding],
            ['Python Binding', $python_binding],
            ['Ruby Binding', $ruby_binding],
            ];
    } else {
        return [
            ['TinySVM Version', 'Not Installed'],
            ];
    }
}

#Perl
sub info_perl {
    return [
        ['Version', $]],
        ['Absolute Path', rmLF(`which perl`)],
        ];
}

# Python
sub info_python {
    my $version = `python -V |& cat`;
    unless($version && $version =~ /Python \d\.\d\.\d/) {
        return [
            ['Version', 'Not Installed'],
            ];
    }

    return [
        ['Version', rmLF($version)],
        ['Absolute Path', rmLF(`which python`)],
        ['BeautifulSoup', getPyModuleVer('BeautifulSoup')],
        ['mechanize', getPyModuleVer('mechanize')],
        ['python-twitter', getPyModuleVer('twitter')],
        ['tweepy', getPyModuleVer('tweepy')],
        ['simplejson', getPyModuleVer('simplejson')],
        ['setuptools', getPyModuleVer('setuptools')],
        ['JCC', getPyJccVer()],
        ];
}

# Ruby
sub info_ruby {
    my $version = `ruby --version 2> /dev/null`;
    if($version) {
        return [
            ['Version', rmLF($version)],
            ['Absolute Path', rmLF(`which ruby`)],
            ];
    } else {
        return [
            ['Version', 'Not Installed'],
            ];
    }
}

sub rmLF {
    my $str = shift;
    $str =~ s/\n//g;
    return $str;
}

sub load_cpuinfo
{
    my @info = ();
    local $/ = '';
    open my $cpuinfo, "<", "/proc/cpuinfo";
    while(my $block = <$cpuinfo>) {
        my %proc;
        for my $line(split /\n/, $block) {
            my ($name, $val) = split /:/, $line;
            $name =~ s/^\s*//; $name =~ s/\s*$//;
            $val =~ s/~\s*//; $val =~ s/\s*$//;
            $proc{$name} = $val;
        }
        push @info, \%proc;
    }

    return \@info;
}

sub load_meminfo
{
    my @info = ();
    local $/ = '';
    open my $meminfo, "<", "/proc/meminfo";
    while(my $block = <$meminfo>) {
        my %proc;
        for my $line(split /\n/, $block) {
            my ($name, $val) = split /:/, $line;
            $name =~ s/^\s*//; $name =~ s/\s*$//;
            $val =~ s/~\s*//; $val =~ s/\s*$//;
            $proc{$name} = $val;
        }
        push @info, \%proc;
    }

    return \@info;
}

sub getPyModuleVer
{
    my $module = shift;
    my $version = `python -M $module -c 'print $module.__version__' 2> /dev/null`;
    return 'Not Installed' unless($version);
    $version = rmLF($version);
    if($version=~/^\((.*)\)$/) {
        my $v = $1;
        my @a = grep(/[0-9]+/, split(/,/, $v));
        $version = join ".", map({$_-0} @a);
    }
    return $version;
}

sub getPyJccVer
{
    my $path = `python -c 'import jcc;print jcc.__path__' 2> /dev/null`;
    if($path =~ /(JCC-[0-9.]+)/) {
        return $1;
    }
    return 'Not Installed';
}
