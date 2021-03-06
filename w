#!/usr/bin/perl -w
# ~/bin/w
# Search for potentially misspelled words
# Output is:
# misspellled
# woord (WOORD, Woord, woord, woord's)

# originally this was a dict of all words
# but sorting it overflowed
%letter_map = ();
# now we have a dict per letter

# read all input
while (<>) {
  next unless /./;
  s/^/ /;
  while (s/([^\\])\\[rtn]/$1 /g) {}
  s/[^a-zA-Z']+/ /g;
  while (s/([A-Z]{2,})([A-Z][a-z]{2,})/ $1 $2 /g) {}
  while (s/([a-z']+)([A-Z])/$1 $2/g) {}
  for my $token (split /\s+/, $_) {
    $token =~ s/^'+(.*)/$1/;
    $token =~ s/(.*?)'+$/$1/;
    next unless $token =~ /./;
    my $key = lc $token;
    $key =~ s/'[sd]$//;
    my $char = substr $key, 0, 1;
    $letter_map{$char} = () unless defined $letter_map{$char};
    my %word_map = ();
    %word_map = %{$letter_map{$char}{$key}} if defined $letter_map{$char}{$key};
    $word_map{$token} = 1;
    $letter_map{$char}{$key} = \%word_map;
  }
}
# group related words
for my $char (sort keys %letter_map) {
  for my $plural_key (sort keys($letter_map{$char})) {
    my $key = $plural_key;
    if ($key =~ /.s$/) {
      if ($key =~ /ies$/) {
        $key =~ s/ies$/y/;
      } else {
        $key =~ s/s$//;
      }
    } elsif ($key =~ /.[^aeiou]ed$/) {
      $key =~ s/ed$//;
    } else {
      next;
    }
    next unless defined $letter_map{$char}{$key};
    my %word_map = %{$letter_map{$char}{$key}};
    for $word (keys($letter_map{$char}{$plural_key})) {
      $word_map{$word} = 1;
    }
    $letter_map{$char}{$key} = \%word_map;
    delete $letter_map{$char}{$plural_key};
  }
}
# exclude dictionary words
open DICT, '<', '/usr/share/dict/words';
while ($word = <DICT>) {
  chomp $word;
  my $lower_word = lc $word;
  my $char = substr $lower_word, 0, 1;
  next unless defined $letter_map{$char}{$lower_word};
  delete $letter_map{$char}{$word};
  next if $lower_word eq $word;
  my %word_map = %{$letter_map{$char}{$lower_word}};
  delete $word_map{$word};
  if (%word_map) {
    $letter_map{$char}{$lower_word} = \%word_map;
  } else {
    delete $letter_map{$char}{$lower_word};
  }
}
close DICT;
# display the remainder
for my $char (sort keys %letter_map) {
  for $key (sort keys($letter_map{$char})) {
    my %word_map = %{$letter_map{$char}{$key}};
    my @words = keys(%word_map);
    if (scalar(@words) > 1) {
      print $key." (".(join ", ", sort { length($a) <=> length($b) || $a cmp $b } @words).")";
    } else {
      print $words[0];
    }
    print "\n";
  }
}

