#!/usr/bin/perl
# DEPENDENCIES: mplayer, curl, and perl's core JSON module
use strict;
use warnings;
use JSON 'decode_json';
use utf8;

my @data_object = decode_json `curl -s http://a.4cdn.org/wsg/catalog.json`;
# An array filled with perl hashes of arrays filled with perl hashes... (；￣Д￣)
my @pages = @{$data_object[0]};
my $x = 1;
my @threads;
for(my $i = 0; $i < scalar(@pages); $i++) {
        for(my $j = 0; $j < scalar(@{$pages[$i]{'threads'}}); $j++) {
                # Print the things that matter! (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧
                print "$x: $pages[$i]{'threads'}[$j]{'now'} $pages[$i]{'threads'}[$j]{'name'}";
                print " $pages[$i]{'threads'}[$j]{'sub'}" if $pages[$i]{'threads'}[$j]{'sub'};
                print "\nimages: $pages[$i]{'threads'}[$j]{'images'}";
                if($pages[$i]{'threads'}[$j]{'com'}) {
                        # I tried to be explicit in my formatting... ╮(￣ω￣;)╭
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/&#039;/'/g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<a href=".*">//g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<\/a>//g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<br>/\n/g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<span class="deadlink">/(dead)/g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<\/span>//g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/&lt;/</g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/&gt;/>/g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<wbr>//g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/&quot;/"/g;
                        $pages[$i]{'threads'}[$j]{'com'} =~ s/<span class="quote">//g;
                        print "\n$pages[$i]{'threads'}[$j]{'com'}";
                }
                print "\n\n_________________________________________________\n\n";
                $threads[$x] = "http://a.4cdn.org/wsg/thread/$pages[$i]{'threads'}[$j]{'no'}.json";
                $x++;
        }
}

print "thrad: ";
my $thrad = <>; chomp($thrad);
print "auto-playing $threads[$thrad] ...";
playplay($threads[$thrad]);
sub playplay {
        my @parse = decode_json `curl -s $_[0]`;
        my @posts = @{$parse[0]{'posts'}};
        for(my $i = 0; $i < scalar(@posts); $i++) {
                next unless $posts[$i]{'ext'};
                my $file = "http://i.4cdn.org/wsg/$posts[$i]{'tim'}".$posts[$i]{'ext'};
                print "PLAYING: http://i.4cdn.org/wsg/$posts[$i]{'tim'}".$posts[$i]{'ext'}."\n";
                if($posts[$i]{'com'}) {
                        $posts[$i]{'com'} =~ s/&#039;/'/g;
                        $posts[$i]{'com'} =~ s/<a href="#p\d+" class="quotelink">&gt;&gt;/>>/g;
                        $posts[$i]{'com'} =~ s/<\/a>//g;
                        $posts[$i]{'com'} =~ s/<br>/\n/g;
                        print "COMMENT: $posts[$i]{'com'}\n";
                }
                my $mplayer = `mplayer $file 1>/dev/null 2>/dev/null &`;
                while(`pgrep mplayer`) {
                        sleep 3;
                }
        }
}
