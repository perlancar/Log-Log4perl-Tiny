# vim: filetype=perl :
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw( set_logger log_is log_like );

use Test::Builder;
my $Test = Test::Builder->new();

my $logger;
sub set_logger { $logger = shift }

sub log_is (&$$) {
   my ($sub, $regex, $message) = @_;
   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $sub->($logger);
   close $fh;
   is($collector, $regex, $message);
} ## end sub log_is (&$$)

sub log_like (&$$) {
   my ($sub, $regex, $message) = @_;
   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $sub->($logger);
   close $fh;
   like($collector, $regex, $message);
} ## end sub log_like (&$$)

1;