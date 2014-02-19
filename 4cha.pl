#!/usr/bin/perl

use strict; # Only needed by sticklers.
use warnings; # Only needed for debugging.
use HTML::FormatText; # The post comments are in HTML and this makes them pretty.
use POSIX; # This comes with ceil() which rounds floats to integers. I use this to round image sizes to the nearest kilobyte.
use JSON; # This turns the .json file into an array of hashes (but the 4chan json files aren't so simple...)
use Term::ANSIColor; # COLORS MUTHA FUCKA!
use Term::ReadKey; # Need this for GetTerminalSize(), this decides my margins for the post comments.
my($wchar, $hchar, $wpix, $hpix) = GetTerminalSize();
use Data::Dumper;

my $url = "https://api.4chan.org/boards.json"; 
my $board = "a";
my $page = "0";
print colored ['white'], "Hey! This is a 4chan API parser! VERSION 1.0a\nThere's still much to do, right now it can list the boards and threads on a board. the help doesn't work.\nIf you enter unexpected values you will get errors, there is no catching.\n";

# The main function. This will eventually handle all arguments and url modification. Eventually I intend to have it called by the other functions once they finish, which is why it can take arguments.
sub main {
	# elsif ($_[0] eq "catalog") {
	#     print "Board: "; chomp($board = <STDIN>);
	#     $url = "https://api.4chan.org/$board/catalog.json";
	#     catalog();
	# }
	print "What do you want to do? [(b)oards|(t)hreads|(h)elp]: "; chomp(my $opt = <STDIN>);
	if (lc($opt) =~ "boards" || lc($opt) =~ "b") {
		&boards;
	}
	elsif (lc($opt) =~ "threads" || lc($opt) =~ "t") {
		print "Board: "; chomp($board = <STDIN>);
		$url = "https://api.4chan.org/$board/0.json";
		&threads;
	}
	elsif (lc($opt) =~ "help" || lc($opt) =~ "h") {
		print "fuck off\n";
	}
}

# Downloads the JSON file at $url, stores it as $json, decodes $json's JSON into an array of an array of hashes (yup, it gets complicated later on.) and stores that as $data. Last it returns the appropriate array of hashes inside the array.
sub get_vars {
    system("wget", "-q", "--output-document=page.tmp", "$url"); #>not using LWP::Simple
    open(FILE, "<page.tmp");
    my $json = <FILE>;
    close(FILE);
    unlink("page.tmp");
    my $data = decode_json($json);

    if ($url eq 'https://api.4chan.org/boards.json') {
	return(@{$data->{boards}});
    }
    if ($url eq "https://api.4chan.org/$board/0.json") {
	return(@{$data->{threads}});
    }
    if ($url =~ m/(res)/) {
	return(@{$data->{posts}});
    }
    # # I need to find a workaround for the broken catalog.json file before this can be implemented.
    # if ($url eq 'https://api.4chan.org/$board/catalog.json') {
    # 	return(@{$data->{threads}});
    # }
}

# Neatly format and print out the list of available boards. A (NSFW) is appended if the board has prons.
sub boards {
    my @boards = &get_vars;
    for (my $i = 0; $i < 57; $i++) {
	print "#", $i+1, ": $boards[$i]->{board} - $boards[$i]->{title} ";
	print colored ['bold red'], "(NSFW)" if ($boards[$i]->{ws_board} == 0);
	print "\n";
    }
    &main;
}

# # The catalog is just a list of OP's (i.e. you won't see the latest 5 posts).
# sub catalog {
#     my @catalog = get_vars();
# }
my $z;
my $j;
# Format (as best as I can) and print out the threads on the board and page selected. Things get a little complicated in here, blame the shitty JSON!
sub threads {
    my @threads = &get_vars;
    my @images;
    $j = 0;
    for (my $i = 0; $i < scalar(@threads); $i++) {
	my @posthash = $threads[$i]->{posts};
	my $post_num = 0;
	my $line = HTML::FormatText->format_string("<hr />", leftmargin => 0, rightmargin => $wchar);
	print colored ['bold yellow'], "THREAD #$i ";
	for ($z = 0; $z < scalar(@{$posthash[0]}); $z++) {
	    my $post = $posthash[0][$z];
	    if ($z == 0) {
		$threads[$i]->{url} = "https://api.4chan.org/$board/res/$post->{no}.json";
	      	$post_num = $post->{omitted_posts} if (defined $post->{omitted_posts});
	    } else { print colored ['bright_yellow'], "POST #", $post_num + $z, " "; }
	    if (defined $post->{filename}) {
		print colored ['bright_blue'], "IMAGE #", $j;
		$j++;
	    }
	    print "\n";
	    &formatter($post);
	}
	$z = 0;
	print colored ['bold white'], "$line", "\n";
    }
    print "Thread number: "; chomp(my $opt = <STDIN>);
    $url = $threads[$opt]->{url};
    &posts;
}

# Formats and prints out all the posts in a thread. Coding this should be easy compared to the listing threads, I'm just lazy.
sub posts {
    my @posts = &get_vars;
    my @images;
    $j = 0;
    for ($z = 0; $z < scalar(@posts); $z++) {
	print colored ['bright_yellow'], "POST #", $z, " ";
	if (defined $posts[$z]->{filename}) {
	    print colored ['bright_blue'], "IMAGE #", $j;
	    $j++;
	}
	print "\n";
	&formatter($posts[$z]);
    }
}

# I found that it runs faster if you make sure the hash elements are defined before printing instead of just printing an undefined value (which perl will allow). That's why all the if (defined ...) shit.
# CULLAHS. CULLAHS ERRYWHERE, MUTHA FUCKA!
sub formatter {
    my $post = $_[0];
    if ($z == 0) {
	print colored ['white'], "$post->{replies} posts and $post->{images} images ";
	print colored ['white on_blue'], "[STICKY]" if (defined $post->{sticky});
	print colored ['white on_red'], "[CLOSED]" if (defined $post->{closed});
	print "\n";
    }
    print colored ['blue'], "$post->{sub} " if (defined $post->{sub});
    print colored ['bold red'], "(sage)" if (defined $post->{email} && lc($post->{email}) =~ "sage");
    print colored ['white on_black'], "$post->{email} " if (defined $post->{email} && lc($post->{email}) !~ "sage");
    print colored ['bold green'], "$post->{name}" if (defined $post->{name});
    print colored ['green'], "($post->{trip})" if (defined $post->{trip});
    print colored ['green'], "($post->{id})" if (defined $post->{id});
    print colored ['bold red'], " ## $post->{capcode}" if (defined $post->{capcode} && lc($post->{capcode}) =~ "admin");
    print colored ['bold magenta'], " ## $post->{capcode}" if (defined $post->{capcode} && lc($post->{capcode}) =~ "mod");
    print "\n";
    print colored ['cyan'], "File: $post->{tim}$post->{ext}-(".(ceil($post->{fsize} / 1024))." KB, $post->{w}x$post->{h}, $post->{filename}$post->{ext})\n" if (defined $post->{filename});
    print HTML::FormatText->format_string("$post->{com}", leftmargin => 0, rightmargin => $wchar) if (defined $post->{com});
    print "\n";
}

&main;
