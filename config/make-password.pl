#!/usr/bin/perl

use MIME::Base64;
use Digest::MD5 qw(md5_base64);
use strict;

my $shuffle = 1;
my $alpha = 0;

while (1) {
    if ($ARGV[0] eq '-s') {
	$shuffle = !$shuffle;
	shift @ARGV;
    } elsif ($ARGV[0] eq '-a') {
	$alpha = 1;
	shift @ARGV;
    } else {
	last;
    }
}

if ($#ARGV != 1) {
    print STDERR "Usage: make-password [-s] [-a] <identifier> <key-file>\n";
    print STDERR "  key-file should contains secret, unpredictable data\n";
    print STDERR "  -s: toggle shuffling (on by default)\n";
    print STDERR "  -a: alphanumeric only\n";
    exit 1;
}

my $passphrase = $ARGV[0];

undef $/;

my $keyfile = $ARGV[1];
my $bits;

open (KEYFILE, $keyfile);

while (length($bits) < 20) {
    read KEYFILE, $bits, 20, length($bits)
}

my $md5 = md5_base64($passphrase, $bits);
my $md5_chars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

my $prefix = substr($md5, 0, 5);

my $i6 = index $md5_chars, substr($md5, 5, 1);
my $i7 = index $md5_chars, substr($md5, 6, 1);
my $i8 = index $md5_chars, substr($md5, 7, 1);

my $punctuation = ".!#%&()*+,-./<=>?";
my $digits = "0123456789";
my $p6 = substr $punctuation, ($i6 % length $punctuation), 1;
my $p7 = substr $digits, ($i7 % 10), 1;
my $p8 = substr $digits, ($i8 % 10), 1;

my $unshuffled = $prefix . $p6 . $p7 . $p8;

if ($alpha) {
    my $alphanumeric = substr($md5_chars, 0, 62);
    $unshuffled = '';
    for (my $j = 0; $j < 8; $j++) {
	my $i = index $md5_chars, substr($md5, $j, 1);
	$unshuffled .= substr $alphanumeric, ($i % 62), 1;
    }
}

if ($shuffle) {
    my $shuffled;
    my $i9 = index $md5_chars, substr($md5, 8, 1);
    my $i10 = index $md5_chars, substr($md5, 9, 1);
    my $i11 = index $md5_chars, substr($md5, 10, 1);
    my $perm = ($i9 * 4096 + $i10*64 + $i11) % 40320;
    my @used;
    for (my $i = 8; $i >= 1; $i--) {
	my $j = $perm % $i; # -> use the jth unused index
	$perm /= $i;
	my $k;
	for ($k = 0; $j != 0 || $used[$k]; $k++) {
	    if (!$used[$k]) { $j--; }
	}
	$used[$k] = 1;
	$shuffled .= substr($unshuffled, $k, 1);
    }
    print $shuffled, "\r\n";
} else {
    print $unshuffled, "\r\n";
}
