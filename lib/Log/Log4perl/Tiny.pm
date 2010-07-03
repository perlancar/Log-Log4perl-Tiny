package Log::Log4perl::Tiny;

our $VERSION = '0.1';

use warnings;
use strict;

our ($ALL, $TRACE, $DEBUG, $INFO, $WARN, $ERROR, $FATAL, $OFF);
my ($_instance, %name_of);

sub get_logger {
   $_instance ||= bless {
      level    => $INFO,
      fh       => \*STDERR,
      preamble => sub {
         my ($level) = @_;
         my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
           localtime();
         return sprintf '[%04d-%02d-%02d %02d:%02d:%02d] %5s ', $year + 1900,
           $mon + 1, $mday, $hour, $min, $sec, $name_of{$level};
      },
     },
     __PACKAGE__;
   return $_instance;
} ## end sub get_logger

BEGIN {
   no strict 'refs';

   for my $accessor (qw( level fh preamble )) {
      *{__PACKAGE__ . '::' . $accessor} = sub {
         my $self = shift;
         $self->{$accessor} = shift if @_;
         return $self->{$accessor};
      };
   } ## end for my $accessor (qw( level fh preamble ))

   my $index = 0;
   for my $name (qw( OFF FATAL ERROR WARN INFO DEBUG TRACE ALL )) {
      $name_of{$$name = $index++} = $name;
   }

   get_logger();    # inizialises $_instance;
} ## end BEGIN

sub import {
   my ($exporter, @list) = @_;
   my ($caller, $file, $line) = caller();
   no strict 'refs';

   my %done;
 ITEM:
   for my $item (@list) {
      next ITEM if $done{$item};
      if ($item eq ':levels') {
         for my $level (qw( ALL TRACE DEBUG INFO WARN ERROR FATAL OFF )) {
            *{$caller . '::' . $level} = \${$exporter . '::' . $level};
         }
      }
      elsif ($item eq ':subs') {
         for my $subname (
            qw(
            ALWAYS TRACE DEBUG INFO WARN ERROR FATAL
            LOGWARN LOGDIE LOGEXIT LOGCARP LOGCLUCK LOGCROAK LOGCONFESS
            get_logger
            )
           )
         {
            *{$caller . '::' . $subname} = \&{$exporter . '::' . $subname};
         } ## end for my $subname (qw(...
      } ## end elsif ($item eq ':subs')
      elsif ($item =~ /\A : (mimic | mask | fake) \z/mxs) {
         $INC{'Log/Log4perl.pm'} = __FILE__;
         *Log::Log4perl::import = sub { };
         *Log::Log4perl::easy_init = sub {
            my ($pack, $conf) = @_;
            if (ref $conf) {
               $_instance->level($conf->{level}) if exists $conf->{level};
            }
            elsif (defined $conf) {
               $_instance->level($conf);
            }
         };
      } ## end elsif ($item =~ /\A : (mimic | mask | fake) \z/mxs)
      elsif ($item eq ':easy') {
         push @list, qw( :levels :subs :fake );
      }
   } ## end for my $item (@list)

   return;
} ## end sub import

sub log {
   my $self  = shift;
   my $level = shift;
   return if $level > $self->{level};
   print {$self->{fh}} $self->{preamble}->(), @_, "\n";
   return;
} ## end sub log

sub ALWAYS { return $_instance->log($OFF,   @_); }
sub TRACE  { return $_instance->log($TRACE, @_); }
sub DEBUG  { return $_instance->log($DEBUG, @_); }
sub INFO   { return $_instance->log($INFO,  @_); }
sub WARN   { return $_instance->log($WARN,  @_); }
sub ERROR  { return $_instance->log($ERROR, @_); }
sub FATAL  { return $_instance->log($FATAL, @_); }

sub _exit {
   my $self = shift || $_instance;
   exit $self->{logexit_code} if defined $self->{logexit_code};
   exit 1;
}

sub LOGWARN {
   WARN(@_);
   CORE::warn(@_);
   _exit();
}

sub LOGDIE {
   FATAL(@_);
   CORE::die(@_);
   _exit();
}

sub LOGEXIT {
   FATAL(@_);
   _exit();
}

sub LOGCARP {
   WARN(@_);
   require Carp;
   Carp::carp(@_);
}

sub LOGCLUCK {
   WARN(@_);
   require Carp;
   Carp::cluck(@_);
}

sub LOGCROAK {
   FATAL(@_);
   require Carp;
   Carp::croak(@_);
}

sub LOGCONFESS {
   FATAL(@_);
   require Carp;
   Carp::confess(@_);
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Log::Log4perl::Tiny - [Una riga di descrizione dello scopo del modulo]

=head1 VERSION

This document describes Log::Log4perl::Tiny version 0.0.1. Most likely, this
version number here is outdate, and you should peek the source.


=head1 SYNOPSIS

   use Log::Log4perl::Tiny;

=for l'autore, da riempire:
   Qualche breve esempio con codice che mostri l'utilizzo pi� comune.
   Questa sezione sar� quella probabilmente pi� letta, perch� molti
   utenti si annoiano a leggere tutta la documentazione, per cui
   � meglio essere il pi� educativi ed esplicativi possibile.


=head1 DESCRIPTION

=for l'autore, da riempire:
   Fornite una descrizione completa del modulo e delle sue caratteristiche.
   Aiutatevi a strutturare il testo con le sottosezioni (=head2, =head3)
   se necessario.


=head1 INTERFACE 

=for l'autore, da riempire:
   Scrivete una sezione separata che elenchi i componenti pubblici
   dell'interfaccia del modulo. Questi normalmente sono formati o
   dalle subroutine che possono essere esportate, o dai metodi che
   possono essere chiamati su oggetti che appartengono alle classi
   fornite da questo modulo.


=head1 DIAGNOSTICS

=for l'autore, da riempire:
   Elencate qualunque singolo errore o messaggio di avvertimento che
   il modulo pu� generare, anche quelli che non "accadranno mai".
   Includete anche una spiegazione completa di ciascuno di questi
   problemi, una o pi� possibili cause e qualunque rimedio
   suggerito.


=over

=item C<< Error message here, perhaps with %s placeholders >>

[Descrizione di un errore]

=item C<< Another error message here >>

[Descrizione di un errore]

[E cos� via...]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for l'autore, da riempire:
   Una spiegazione completa di qualunque sistema di configurazione
   utilizzato dal modulo, inclusi i nomi e le posizioni dei file di
   configurazione, il significato di ciascuna variabile di ambiente
   utilizzata e propriet� che pu� essere impostata. Queste descrizioni
   devono anche includere dettagli su eventuali linguaggi di configurazione
   utilizzati.
  
Log::Log4perl::Tiny requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for l'autore, da riempire:
   Una lista di tutti gli altri moduli su cui si basa questo modulo,
   incluse eventuali restrizioni sulle relative versioni, ed una
   indicazione se il modulo in questione � parte della distribuzione
   standard di Perl, parte della distribuzione del modulo o se
   deve essere installato separatamente.

None.


=head1 INCOMPATIBILITIES

=for l'autore, da riempire:
   Una lista di ciascun modulo che non pu� essere utilizzato
   congiuntamente a questo modulo. Questa condizione pu� verificarsi
   a causa di conflitti nei nomi nell'interfaccia, o per concorrenza
   nell'utilizzo delle risorse di sistema o di programma, o ancora
   a causa di limitazioni interne di Perl (ad esempio, molti dei
   moduli che utilizzano filtri al codice sorgente sono mutuamente
   incompatibili).

None reported.


=head1 BUGS AND LIMITATIONS

=for l'autore, da riempire:
   Una lista di tutti i problemi conosciuti relativi al modulo,
   insime a qualche indicazione sul fatto che tali problemi siano
   plausibilmente risolti in una versione successiva. Includete anche
   una lista delle restrizioni sulle funzionalit� fornite dal
   modulo: tipi di dati che non si � in grado di gestire, problematiche
   relative all'efficienza e le circostanze nelle quali queste possono
   sorgere, limitazioni pratiche sugli insiemi dei dati, casi
   particolari che non sono (ancora) gestiti, e cos� via.

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.x itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo � software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl 5.8.x stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NEGAZIONE DELLA GARANZIA

Poich� questo software viene dato con una licenza gratuita, non
c'� alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "cos� com'�" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza per� limitarsi a questo)
eventuali garanzie implicite di commerciabilit� e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualit� ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilit�
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ci� non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software cos� come consentito dalla licenza di cui sopra, potr�
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacit� di utilizzo di questo software. Ci�
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, � stata avvisata della possibilit� di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilit� per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=head1 SEE ALSO

=for l'autore, da riempire:
   Una lista di moduli/link da considerare per completare le funzionalit�
   del modulo, o per trovarne di alternative.

=cut