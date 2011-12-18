#!/usr/bin/perl
#
# Usage: udgrep [options]
use strict;
use LWP::Simple;
use LWP::UserAgent;

# Set UserAgent
my $browser = LWP::UserAgent->new("UD Bot [via LWP] Ver: 2.3");

# Call appropriate routines
if ($#ARGV < 0 || $#ARGV > 1) {
    help();
}
elsif ($ARGV[0] eq "-w") {
    whoList();
}
elsif ($ARGV[0] eq "-n") {
    news();
}
elsif ($ARGV[0] eq "-c") {
    clan()
}
elsif ($ARGV[0] eq "-h") {
    getHelp($ARGV[1]);
}
elsif ($ARGV[0] eq "-p") {
    player($ARGV[1]);
}
elsif ($ARGV[0] eq "-l") {
    polls();
}
elsif ($ARGV[0] eq "-r") {
    results($ARGV[1]);
}
elsif ($ARGV[0] eq "-s") {
    stats();
}
elsif ($ARGV[0] eq "-d") {
    dev();
}
else {
    help();
}

# Error | Usage screen
sub help {
    print "Usage: udgrep [options]\n";
    print "Options:\n";
    print "  -w     -- Extract the current WHO list\n";
    print "  -n     -- Extract the recent news\n";
    print "  -c     -- List all active clans\n";
    print "  -h     -- Retrieve help information\n";
    print "  -l     -- Retrieve an active poll list\n";
    print "  -s     -- Retrieve stats page\n";
    print "  -d     -- Retrieve dev pages\n";
#    print "  -r <ID>     -- Check a poll\'s results\n";
    print "  -p <player> -- Lookup a specific player\n";
    exit;
}

# Output whoson.php
sub whoList {
    my $playersOn = get_page("http://dreams.daestroke.com/whoson.php");
    $playersOn =~ s/.*<table border=0>//ms; # Drop everything before list
    $playersOn =~ s/<\/table>.*//ms;        # Drop everything after list
    $playersOn =~ s/<[^>]*>//g;             # Strip all html tags
    $playersOn =~ s/profile //g;            # Drop leading "profile "
    $playersOn =~ s/&nbsp;/ /gms;           # Fixes level one players
    print "Who's on:" . $playersOn;
}

# Recent news
sub news {
    my $recentNews = get_page("http://dreams.daestroke.com/index.php");
    $recentNews =~ s/.*?Posted(.*)<a href="news\.php">.*/$1/gs;
    $recentNews =~ s/<p>/\n/gs;
    $recentNews =~ s/<[^>]*>//g;
    $recentNews =~ s/\r/\n/gms;
    print "Recent News:\nPosted" . $recentNews;
}

# Extract current clan list
sub clan {
    my $currClans = get_page("http://dreams.daestroke.com/clans.php");
    $currClans =~ s/.*?Full Timeline(.*?)<\/table>.*/$1/gs;
    $currClans =~ s/<[^>]*>//g;
    $currClans =~ s/\r/\n/gms;
    $currClans =~ s/&lt;/</gms;
    $currClans =~ s/&gt;/>/gms;

    my @clans = split('\n', $currClans);
    
    my $count = 3;
    while ($count <= @clans) {
        if (@clans[$count] =~ /Active/) {
            print @clans[$count-2] . "\n"
        }
        $count++;
    }
}

# Retrieve the active poll list
sub polls {
    my $currPolls = get_page("http://dreams.daestroke.com/poll.php");
    $currPolls =~ s/.*?Comments<\/th>(.*?)CLOSED.*/$1/gs;
    print "Active polls:\n\n";

    my @polls = split('<tr>', $currPolls);

    $currPolls = "";
    my $count = 0;
    while ($count <= @polls) {
        if (@polls[$count] =~ /Take Poll/) {
            my @pollData = split('<\/td>', @polls[$count]);
            
            my $pollID = @pollData[2];
            $pollID =~ s/.*id=(.*?)\".*/$1/gs;
            
            $currPolls = $pollID . ") " . @pollData[0] . " -- " . @pollData[1] . " -- " . @pollData[4] . "\/" . @pollData[5] . "\n";
            
            $currPolls =~ s/<[^>]*>//g;
            print $currPolls
        }
        $count++;
    }
}

# Display the results of a poll by its ID
sub results {
    my $pollID = "@_";
    my $pollResults = get_page("http://dreams.daestroke.com/poll_results.php?id=$pollID");
    
    $pollResults =~ s/\r/\n/gms;
    $pollResults =~ /.*auto;\">(.*?)<p>.*Count(.*?)<\/table>.*/g;

print $2;
#    my @resultsEntry = split(

    $pollResults =~ s/<[^>]*>//g;

#    print $pollResults;
}

# Retrieve stats page
sub stats {
    my $statsPage = get_page("http://dreams.daestroke.com/stats_collect.php");
    $statsPage =~ s/.*Top 10 Item Collectors(.*?)<\/table>.*Top 10 Set Collectors(.*?)<\/table>.*/$1 $2/gs;

    $statsPage =~ s/.*?<\/th><\/tr>(.*?)    <\/table>.*/$1/gs;
    $statsPage =~ s/.*?tr>//g;
    $statsPage =~ s/<td>(.*?)<\/td>\n<td>(.*?)<\/td>.*/$1    $2/g;
    $statsPage =~ s/^\n//gms;

    $statsPage =~ s/<td align.*?cellspacing="0">//gs;
    $statsPage =~ s/.?    <\/td>\n/Top 10 Item Collectors/s;
    $statsPage =~ s/.?    <\/td>\n/\nTop 10 Set Collectors/s;
   
    print $statsPage . "\n";
}

sub dev {
    my $devPage = get_page("http://dreams.daestroke.com/showfile.php?file=ondev.rn");
    $devPage =~ s/.*<pre>(.*?)<\/pre>.*<em>(.*?)\.<\/em>.*/$1 \n\n$2/gs;
    $devPage =~ s/<[^>]*>//g;

    my $prodPage = get_page("http://dreams.daestroke.com/showfile.php?file=onprod.rn");
    $prodPage =~ s/.*<pre>(.*?)<\/pre>.*<em>(.*?)\.<\/em>.*/$1 \n\n$2/gs;
    $prodPage =~ s/<[^>]*>//g;

    print "UD Development Status:\n" . $devPage . "\n\n";
    print "UD Production Status:\n" . $prodPage . "\n";
}

# Retrieve help information
sub getHelp {
    my $getHelp = "@_";
    print "Help for " . $getHelp . ":\n";
    $getHelp = get_page("http://dreams.daestroke.com/help.php?term=$getHelp");
    $getHelp =~ s/.*<\/form><hr>(.*?)<\/div>.*/$1/gs;
#    $getHelp =~ s/.*<hr>(.*?)<\/table>.*/$1/gs;
    $getHelp =~ s/<[^>]*>//g;
    $getHelp =~ s/&lt;/</g;
    $getHelp =~ s/&gt;/>/g;
#    $getHelp =~ s/\r/\n/gms;
#    $getHelp =~ s/\n$//g;
    print $getHelp . "\n";
}

# Extract player profile.php?name=$name
sub player {
    my $name = "@_";                        # Get the name passed by user
    $name =~ tr[A-Z][a-z];                  # Make name lowercase; !important
    $name =~ s/\b(\w)/uc($1)/eg;            # Cap first letter; !important
    my $player = get_page("http://dreams.daestroke.com/profile.php?name=$name");

    my $link = $player;
    my $home = "";
    my $img = "";
    $link =~ s/.*$name(.*)<pre>.*/$1/gs;    # Extract homepageurl
    if ($link =~ /href=/) {
        $home = $player;
        $home =~ s/.*href=\"(.*?)\".*/$1/gs;
    }
    if ($link =~ /src=/) {                  # Extract imageurl
        $img = $player;
        $img =~ s/.*src=\"(.*?)\".*/$1/gs;
    }
    
    $player =~ s/.*<pre>(.*)<\/pre>.*/$1/gs;    # Grab player description
    $player =~ s/\r/\n/gms;                     # Convert lineFeeds->lineBreaks
    print "Player profile for: ".$name."\nHomepage: ".$home;
    print "\nImage: ".$img."\n\n".$player."\n";
}

# Returns the url passed to it
sub get_page {
    my $pageContent = $browser->get("@_")->content || die "Couldn't get url\n";
    return $pageContent;
}

exit(0);
