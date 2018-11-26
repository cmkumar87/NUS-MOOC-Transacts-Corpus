#!/usr/bin/perl -w
use strict;
#use warnings qw(FATAL utf8);
require 5.0;

##
#
# Author : Radhika Nikam, modified from script xx by Muthu
# Script to genrate MTURK CSV annotation file for task 2.2
# Created in Mar, 2014
#
##

# Run without -stem flag first and then with -stem flag
# to get a vector with all + stemmed versions

use DBI;
use FindBin;
use Getopt::Long;

my $path;	# Path to binary directory

BEGIN{
	if ($FindBin::Bin =~ /(.*)/) 
	{
		$path  = $1;
	}
}

use lib "$path/../lib";
use Model;
#use Utility;
our $c1;
### USER customizable section
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "1.0";
### END user customizable section

sub License{
	#print STDERR "# Copyright 2014 \251 Muthu Kumar C\n";
}

sub Help{
	print STDERR "Usage: $progname -h\t[invokes help]\n";
  	print STDERR "       $progname [-idf -tf -thread[all|inst] -stem -uni -bi -q -debug]\n";
	print STDERR "Options:\n";
	print STDERR "\t-q \tQuiet Mode (don't echo license).\n";
	print STDERR "\t-debug \tPrint additional debugging info to the terminal.\n";
}

my $help			= 0;
my $quite			= 0;
my $debug			= 0;
my $forumtype;
my $threadtype		= 'inst';

#database table names with defaults
my $posttable		= 'post2';
my $commenttable	= 'comment2';
my $corpus			= 'd61';
my $test			= 0;
my $course;

$help = 1 unless GetOptions(
				'course=s'	=> \$course,
				'thread=s'	=> \$threadtype,
				'corpus=s'	=> \$corpus,
				'test'		=> \$test,	
				'debug'		=> \$debug,
				'h' 		=> \$help,
				'q' 		=> \$quite
			);

# Run without -stem flag first and then with -stem flag
# to get a vector with all + stemmed versions
			
if ( $help ){
	Help();
	exit(0);
}

if (!$quite){
	License();
}

if ($threadtype eq 'inst'){
	$posttable = 'post2';
	$commenttable ='comment2';
}
if ($threadtype eq 'noinst'){
	$posttable = 'post';
	$commenttable ='comment';
}

my $datahome = "$path/../../data";

my $dbh = Model::getDBHandle("$datahome",1,undef,'cs6207');

# counts only posts where an instructor/TA/Staff has replied to a post
print  "\n threadtype.. $threadtype";
print  "\t posttab: $posttable \t commenttab: $commenttable ";

my $countofthreads	= "select count(1) from thread 
						where forumid=? and courseid=? 
						and inst_replied =?";
						
my $postsquery		= "select id, post_text, votes, user, post_order
						from $posttable
						where thread_id=? 
						and courseid=? and forumid=?
						order by post_order";
				  
my $poststh			= $dbh->prepare($postsquery)
						or die "Couldn't prepare user insert statement: " . $DBI::errstr;
				
my $commentsquery	= "select id, comment_text, votes, user
						from $commenttable
						where post_id=? and thread_id=? 
						and courseid=? and forumid=? 
						order by id";
					 
my $commentssth		= $dbh->prepare($commentsquery) 
						or die "Couldn't prepare user insert statement: " . $DBI::errstr;

my $instpostqry		= "select u.postid, p.post_time, p.post_text, p.votes, p.post_order, u.user_title  
						from user u, post p
						where user_title in (\"Instructor\",\"Staff\",
												\"Coursera Staff\", \"Community TA\", 
												\"Coursera Tech Support\"
											)
										and u.threadid = p.thread_id and u.courseid = p.courseid
										and u.id = p.user and u.forumid = p.forumid	and u.postid = p.id
										and u.threadid = ?
										and u.courseid = ?
										and u.forumid = ?";
										
my $instpoststh = $dbh->prepare($instpostqry)
						or die "Couldn't prepare user insert statement: " . $DBI::errstr;

my $instcmntqry = "select u.postid, p.post_time, p.comment_text, p.votes, u.user_title 
					from user u, comment p
					where user_title in (\"Instructor\",\"Staff\",
											\"Coursera Staff\", \"Community TA\", 
											\"Coursera Tech Support\"
										)
										and u.threadid = p.thread_id and u.courseid = p.courseid
										and u.id = p.user and u.forumid = p.forumid and u.postid = p.id
										and u.threadid = ? 
										and u.courseid = ?	
										and u.forumid = ?";
										
my $instcmntsth = $dbh->prepare($instcmntqry)
						or die "Couldn't prepare user insert statement: " . $DBI::errstr;

my @courses;

if ($corpus eq 'pilot'){
	@courses = ('reasonandpersuasion-001');
}
elsif ($corpus eq 'nus'){
	# @courses = ('randomness-001','classicalcomp-001','reasonandpersuasion-001');
	@courses = ('reasonandpersuasion-001');
	# @courses = ('classicalcomp-001');
	
}
elsif ($corpus eq 'd14'){
	@courses = ('ml-005');
}
elsif ($corpus eq 'd61'){
	# @courses = ('maps-002');
	# @courses = ('organalysis-003');
	# @courses = ('diabetes-001');
	# @courses = ('amnhearth-002');
	# @courses = ('friendsmoneybytes-004');
	#@courses = ('gamification-003');
	# @courses = ('globalwarming-002');
	# @courses = ('howthingswork1-002');
    #  @courses = ('marriageandmovies-001');
    #	@courses = ('warhol-001');
    #@courses = ('smac-001');
    #@courses = ('analyze-001');
    #@courses = ('optimization-002');
    # @courses = ('bioinfomethods1-001');
    #       @courses = ('neuralnets-2012-001');
	# 'modernmiddleeast-001A
#	@courses = ('medicalneuro-002')
	#@courses = ('maththink-004')	
#	@courses = ('maps-002')
	#@courses = ('solarsystem-001')
	#@courses = ('smac-001')
        #@courses = ('rprog-003')
        @courses = ('dynamics1-001')

}


#this code prepares a csv with 5 columns
#getthreads
#print threadtype
#print threadtitle
#print posts
#print options

#my $csvfile = "input-peer.csv";
my $csvfile = $courses[0] . "-2.2.csv";
my $outpath = "$path/../mturk_input_files";
# open (my $csvfh, ">:encoding(iso-8859-1)", "$outpath/$csvfile");
open (my $csvfh, ">:encoding(UTF-8)", "$outpath/$csvfile") 
	or die "Cannot open file $csvfile at $outpath/$csvfile";

#print file headers
my $headers = { 1 => 'threadtype,'	,
				2 => 'threadtitle,'	,
				3 => 'posts,' 		,
				4 => 'inst_post'
			  };
printHeaders($csvfh, $headers);

my $forumidsquery	= "select id,courseid,forumname from forum ";
 $forumidsquery		= Model::appendListtoQuery($forumidsquery,\@courses, 'courseid ','where ');
 $forumidsquery	.= "and forumname in('Homework','Lecture','Exam','General','Project','Discussion','PeerA')";
 #$forumidsquery	.= "and forumname in('Homework')";
 #$forumidsquery	.= "and forumname in('Lecture')";
 # $forumidsquery		.= "and forumname in('Exam')";
 # $forumidsquery		.= "and forumname in('Project','Discussion','PeerA')";
 # $forumidsquery	.= "and forumname in('General')";
 # $forumidsquery	.= "and forumname in('Project','Discussion')";
 # $forumidsquery	.= "and forumname in('Project','Discussion','PeerA')";

my $forumrows		= $dbh->selectall_arrayref($forumidsquery) or die "Courses query failed! ";
								
foreach my $forumrow ( @$forumrows ){
	my $forumid		= @$forumrow[0];
	my $coursecode	= @$forumrow[1];
	$forumtype		= @$forumrow[2];
	
	my $inst_replied	= (($threadtype eq 'inst') || ($threadtype eq 'nota') )?1 :0 ;
	my $number_of_threads	= @{$dbh->selectcol_arrayref($countofthreads,undef,$forumid,$coursecode,$inst_replied)}[0];
	
	if( $number_of_threads == 0){ 
		print "\n$number_of_threads  threads found for $forumid with inst_reply = $inst_replied";
		next;
	}
	
	my @threads		= undef;
	
	if ($threadtype eq 'inst'){
		print "\n Picking threads where an instructor or ta has replied\n";
		@threads = @{Model::Getthreadids($dbh, $coursecode, $forumid, "inst_replied=1")};
	}
	elsif ($threadtype eq 'noinst'){
		print "\n Picking threads where an instructor has **not** replied\n";
		@threads = @{Model::Getthreadids($dbh, $coursecode, $forumid, "inst_replied<>1")};
	}
	else{
		print "\n Picking all threads";
		@threads = @{Model::Getthreadids($dbh, $coursecode, $forumid, undef)};
	}
	
	print "\n Starting to loop over all the threads for $coursecode \t $forumid \n";

	;

        #our %selected = ('The jet of 3C273'=>{1=>'elaborates'},'Quasar questions'=>{1=>'resolves'},'Dark matter'=>{1=>'resolves'},'does the hubble constant allow parts of the universe to never be observed'=>{1=>''});
	#our %annotated = ('GHGs in lower atmosphere - are they harmless?',['resolves','none']);
  open FILE1, "out2.txt" or die;
  my %selected;
  my @post1;
  while (my $line=<FILE1>) {
      # $line =~ s/^"//;
      # $line =~ s/"$//g;
     #chomp($line);
     #local $/;
     # map {
     my ($title,$post) = split(/\:/, $line);
     print "$post";
        #my @post1 = split(/\t/, $posts,2);
        # print "@post1[0]\n";
        #foreach  my $p(@post1){
        	my ($p_num,$p_cat) = split(/,/, $post); 
		#print "$p_cat";
        	($p_cat = $p_cat) =~ s/\s//g;
	        $selected{$title}{$p_num + 0} = $p_cat;
        #}
    };
use Data::Dumper;
print Dumper \%selected;
print ref(%selected);

foreach my $thread(@threads){
    our @titles = keys %selected;
		my $threadid 	= $thread->[0];
		if (!defined $inst_replied){
			$inst_replied = $thread->[3];
		}
		my $threadtitle = $thread->[4];
		my $forumid		= $thread->[6];
        #print($threadtitle . "\n");
        #next;

	if($threadtitle ~~ @titles){
	#if (grep{$_ =~ $threadtitle} @titles){

		my $usercounter	= 1;
		my %userAnonMap = ();
		
		my $forumname	= 	Model::getForumname($dbh,$forumid,$coursecode);
		$poststh->execute($threadid,$coursecode,$forumid) or die $DBI::errstr;
		my $posts = $poststh->fetchall_hashref('post_order');
		
		# if ($poststh->rows == 0) {
			# print "\n No post records for $threadid $coursecode $forumid";
		# }
		my $number_of_posts = $poststh->rows;
		
		foreach my $order ( sort {$a <=> $b } keys %$posts ){
			$commentssth->execute($posts->{$order}{'id'}, $threadid, $coursecode, $forumid) 
							or die $DBI::errstr;
			my $comments = $commentssth->fetchall_hashref('id');
			
			# if ($commentssth->rows == 0) {
				# print "\n No records for $threadid $coursecode $forumid";
			# }
			$number_of_posts += $commentssth->rows;			
		}
		
		if ($number_of_posts < 1 ){ next;}
		
		print $csvfh "\"$forumname\"";
		print $csvfh "\,";
		
		print $csvfh "\"";
		$threadtitle =~ s/\"/\'/g;
		printtoCSV($csvfh, $threadtitle);
		print $csvfh "\",";
		
		print $csvfh "\"";
		
		my $post_order = 0;
		foreach my $order ( sort {$a <=> $b } keys %$posts ){
			my %post = ();
			
			$post_order ++;
			$post{'id'}				= $posts->{$order}{'id'};
			
			$posts->{$order}{'post_text'}	=~ s/\"/\'/g;
			
			$post{'post_text'}		= $posts->{$order}{'post_text'};			
			$post{'votes'}			= $posts->{$order}{'votes'};
			$post{'order'}			= $post_order;
			
		
			#sanity check
			if(!defined $posts->{$order}{'post_text'}){
				print "\n $coursecode \t $forumid \t $threadid \t $order \n";
				foreach my $label (keys %{$posts->{$order}}){
					print " $label \t";
				}
                                print "\n sanity check failed"; 
				exit(0);
			}
			else{
				print "\n $forumid \t $threadid \t $order \t $posts->{$order}{'id'} \t $posts->{$order}{'post_order'}";
			}
			
			#skip empty posts. some posts don't have any text as they may been deleted
			if($post{'post_text'} =~ /^\s+$/ || length($post{'post_text'}) eq 0){ 
				next; 
			}
			
			if (	!exists $userAnonMap{$posts->{$order}{'user'}}	){
				$userAnonMap{$posts->{$order}{'user'}}	= $usercounter;
				$usercounter ++;
			}
			$post{'user'}			= $userAnonMap{$posts->{$order}{'user'}};

			$commentssth->execute($post{'id'}, $threadid, $coursecode, $forumid) or die $DBI::errstr;
			my $comments = $commentssth->fetchall_hashref('id');
			
			if ($commentssth->rows == 0) {
				# print "\n No comment records for $threadid $coursecode $forumid";
			}
			my @posts_replied_to = $selected{$threadtitle};
			$c1 = $selected{$threadtitle}{$post_order};
			if($post_order ~~ @posts_replied_to){
					
			printPost($csvfh, \%post);}
			
			foreach my $id ( sort {$a <=> $b } keys %$comments ){
				print "\n comment: $post{'id'} \t $threadid \t $coursecode \t $forumid \n";
				my %comment = ();
				$post_order ++;
				$comment{'id'}						= $comments->{$id}{'id'};			
				$comments->{$id}{'comment_text'}	=~ s/\"/\'/g;

				$comment{'post_text'}				= $comments->{$id}{'comment_text'};
				
				$comment{'votes'}					= $comments->{$id}{'votes'};
				$comment{'order'}					= $post_order;
				
				#skip empty comments. some comemnts don't have any text as they may been deleted
				if($comment{'post_text'} =~ /^\s+$/ || length($comment{'post_text'}) eq 0){ 
					next; 
				}
				
				if (	!exists $userAnonMap{$comments->{$id}{'user'}} ){
					$userAnonMap{$comments->{$id}{'user'}}	= $usercounter;
					$usercounter ++;
				}
				$comment{'user'}			= $userAnonMap{$comments->{$id}{'user'}};
				my @posts_replied_to = $selected{$threadtitle};
				$c1 = $selected{$threadtitle}{$post_order};
				if($post_order ~~ @posts_replied_to){

				
				printComment($csvfh, \%comment);}
				
			}##comment loop ends

		}##post loop ends
		print $csvfh "\"";
		print $csvfh "\,";
		
		$instpoststh->execute($threadid,$coursecode,$forumid) 
											or die $DBI::errstr;
		my $instposts = $instpoststh->fetchall_hashref('postid');
		
		$instcmntsth->execute($threadid,$coursecode,$forumid)
											or die $DBI::errstr; 	
		my $instcmnts = $instcmntsth->fetchall_hashref('postid');
		
		if (!defined $instposts && !defined $instcmnts){
			next;
		}
		elsif ( (keys %$instposts == 0) && (keys %$instcmnts == 0) ){
			next;
		}
		
		my $firstpostTime = 99999999999;
		my $firstpost = 999999999;
		my $isfirstpost_comment = 0;
		foreach my $post (keys %$instposts){
			my $postTime = $instposts->{$post}{'post_time'};
			($firstpostTime,$firstpost,$isfirstpost_comment) = ($postTime < $firstpostTime) ? ($postTime,$post,0): ($firstpostTime,$firstpost,$isfirstpost_comment)
		}
		#print "$coursecode \t $threadid \t $firstpostTime \t $firstpost\n";
		foreach my $post (keys %$instcmnts){
			my $postTime = $instcmnts->{$post}{'post_time'};
			($firstpostTime,$firstpost,$isfirstpost_comment) = ($postTime < $firstpostTime) ? ($postTime,$post,1): ($firstpostTime,$firstpost,$isfirstpost_comment);	
		}
		
		my %instructor_post = ();			
		#instructor post
		$instructor_post{'order'}		= "instructor_post";
		$instructor_post{'user'}		= "instructor";
		
		if(!$isfirstpost_comment){
			$instposts->{$firstpost}{'post_text'}	=~ s/\"/\'/g;
			$instructor_post{'post_text'}			= $instposts->{$firstpost}{'post_text'};
			$instructor_post{'id'}			= $instposts->{$firstpost}{'postid'};
			$instructor_post{'votes'}		= $instposts->{$firstpost}{'votes'};
			$instructor_post{'user_title'}	= $instposts->{$firstpost}{'user_title'};
			
			if(!defined $instructor_post{'post_text'}){
				die "BUG BUG! $coursecode \t $threadid \t $firstpost\t";
			}
			print $csvfh "\"";
			printPost($csvfh, \%instructor_post);
			print $csvfh "\"";
		}
		else{
			#die "BUG HERE! $coursecode \t $threadid \t $firstpost\t \n";
			$instcmnts->{$firstpost}{'comment_text'}	=~ s/\"/\'/g;
			$instructor_post{'post_text'}				= $instcmnts->{$firstpost}{'comment_text'};
			$instructor_post{'id'}			= $instcmnts->{$firstpost}{'postid'};
			$instructor_post{'votes'}		= $instcmnts->{$firstpost}{'votes'};
			$instructor_post{'user_title'}	= $instcmnts->{$firstpost}{'user_title'};
		
			if(!defined $instructor_post{'post_text'}){
				die "BUG BUG! $coursecode \t $threadid \t $firstpost\t";
			}
			print $csvfh "\"";
			printComment($csvfh, \%instructor_post);
			print $csvfh "\"";
		}
				
		print $csvfh "\n";
	}	
	}##thread loop ends
}


close $csvfh;


sub printtoCSV{
	my ($csvfh, $field) =@_;
	print $csvfh "$field";
}

sub printHeaders{
	my ($csvfh, $headers) = @_;
	
	if (keys %$headers eq 0){
		print "Exception: headers hash empty";
		exit(0);
	}
	
	foreach my $header (sort {$a<=>$b} keys %$headers){
		printtoCSV($csvfh, $headers->{$header});
	}
	print $csvfh "\n";
}

sub printOptions{
	my ($csvfh, $number_of_posts) = @_;
	foreach my $post_id (1..$number_of_posts){
		print $csvfh "<label><input name=\'post1\' type=\'checkbox\' value=\'post1\' />POST # $post_id</label><br/>";
	}
}

sub printComment{
	my ($csvfh, $post)	= @_;
	
	my $post_text		= $post->{'post_text'};
	my $post_user		= $post->{'user'};
	my $post_order		= $post->{'order'};
	my $postvotes		= $post->{'votes'};
	my $post_id			= $post->{'id'};


	#our $c1=$selected{$threadtitle}{$post_order};;#$t[0];


	if(!defined $post_text){
		print "\n printPost.. undef post_text \t ";
		exit(0);
	}

	my $text_to_print	 = "<div class=\'course-forum-post-container\'>
								<div class=\'course-forum-post-top-container\'>	";
	$text_to_print		.= "<div class=\'course-forum-comments-container\'>
								<div class=\'course-forum-post-view-container\'> ";
			
	if($post_order ne "instructor_post" ){
		#	if($post_order ~~ @post_replied_to ){
			
		if (!defined $post_text){ die; print $post_order}
		elsif($c1 eq "elaborates"){
				$text_to_print .= "<table width=\'100\%\' style=\'border: 2px solid grey;\' cellpadding=10>
									<tr><td><label><div class=\'course-forum-post-header\'>
									<h5 class=\'course-forum-post-byline\'>
									<table width=\'100\%\'  style=\'font-size:14\'><tbody>
									<tr><td>POST #$post->{'order'} by User #$post_user</td></tr>
									</tbody></table></h5></div></label></td></tr>
									<tr><td><div dir=\'auto\' class=\'course-forum-post-text\' style=\'font-size:14; line-height: 140\%\'>
									$post_text</div></td></tr>";
				$text_to_print	 = printVotes($text_to_print, $postvotes);
				$text_to_print	.= "<tr><td><label><div class=\'course-forum-post-header\'>
									<h5 class=\'course-forum-post-byline\'>
									<table width=\'100\%\'  style=\'font-size:14\'><tbody>
									<!--<tr><td style=\'text-align:left\'>1) Yes, the instructor replies to this student post &nbsp;&nbsp;<input type=\'checkbox\' onclick=\'enableCombo(this,$post_order)\' value=\'$post_order\' name=\'$post_order\'> </td>-->	
									<td><a href=\'\#ipost\'>Go to Instructor's post</a></td></tr>
									<tr><td colspan = \'2\'>\&nbsp\;</td></tr>
									
									<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'clarifies\'>Instructor clarifies or explains concept in detail(assuming student posed a question)<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'extension\'>Instructor brings up something new that could incite further discussion<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'juxtaposition\'>Instructor contrasts two concepts<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'refinement\'>Instructor concedes to criticism and refines his explanation in light of that criticism<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'critique\'>Instructor criticises the student's reasoning<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'nota\'>None of the above<br>
									</td></tr>
									</tbody></table></h5></div></label>
									</td></tr>";
	}
	elsif($c1 eq "resolves"){
				$text_to_print .= "<table width=\'100\%\' style=\'border: 2px solid grey;\' cellpadding=10>
									<tr><td><label><div class=\'course-forum-post-header\'>
									<h5 class=\'course-forum-post-byline\'>
									<table width=\'100\%\'  style=\'font-size:14\'><tbody>
									<tr><td>POST #$post->{'order'} by User #$post_user</td></tr>
									</tbody></table></h5></div></label></td></tr>
									<tr><td><div dir=\'auto\' class=\'course-forum-post-text\' style=\'font-size:14; line-height: 140\%\'>
									$post_text</div></td></tr>";
				$text_to_print	 = printVotes($text_to_print, $postvotes);
				$text_to_print	.= "<tr><td><label><div class=\'course-forum-post-header\'>
									<h5 class=\'course-forum-post-byline\'>
									<table width=\'100\%\'  style=\'font-size:14\'><tbody>
									<!--<tr><td style=\'text-align:left\'>1) Yes, the instructor replies to this student post &nbsp;&nbsp;<input type=\'checkbox\' onclick=\'enableCombo(this,$post_order)\' value=\'$post_order\' name=\'$post_order\'> </td>-->	
									<td><a href=\'\#ipost\'>Go to Instructor's post</a></td></tr>
									<tr><td colspan = \'2\'>\&nbsp\;</td></tr>
									
									<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'agreement\'>Instructor ONLY agrees with the student.(If he explains his stance, don't mark this)<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'disagreement\'>Instructor ONLY disagrees with the student.(If he explains his stance, don't mark this)<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'generic\'>Instructor gives generic reply. He does not explain beyond a line or two.<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'appreciation\'>Instructor appreciates the student's reasoning and thanks him.<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'completion\'>Instructor acknowledges that student's answer is almost correct and then completes his answer.<br>
									<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'nota\'>None of the above<br>
									</td></tr>
									</tbody></table></h5></div></label>
									</td></tr>";
	}
	}
	else{
		$text_to_print	.=	"<table width=\'100%\' style=\'border: 2px solid blue;\' cellpadding=10>
							<tr><td><div class=\'course-forum-post-header\'><h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\' style=\'font-size:14\' ><tbody>
							<tr><td><font color=\'red\'>Instructor\'s Post</font></td></tr>
							</tbody></table></h5></div></td></tr>
							<tr><td>
							
							<div id = \'ipost\' class=\'course-forum-post-text\' dir=\'auto\' style=\'font-size:14.5; line-height: 140\%\'>$post_text</div>
							<div class=\'stuck\'><font color=\'red\'>Instructor's post</font>: $post_text</div>
							<!--<div class=\'stuck\' id = \'ipost2\'>class=\'course-forum-post-text\' dir=\'auto\' style=\'font-size:14.5; line-height: 140\%\'>$post_text</div>-->
							</td></tr>";
		$text_to_print	 = printVotes($text_to_print, $postvotes);
	}
	
	$text_to_print .= "</table></div></div></div></div>";
	$text_to_print	=~ s/\n/ /g;
	print $csvfh $text_to_print;
}

sub printPost{
	my ($csvfh, $post)	= @_;
	
	my $post_text		= $post->{'post_text'};
	my $post_user		= $post->{'user'};
	my $post_order		= $post->{'order'};
	my $postvotes		= $post->{'votes'};
	#my @cat1 = ["resolves","social","elaborates"];
	#my $c1 = "resolves";
	#our $c1;
	if(!defined $post_text){
		print "\n printPost.. undef post_text \t ";
		exit(0);
	}
	
	my $text_to_print	= "<div class=\'course-forum-post-container\'>
							<div class=\'course-forum-post-top-container\'>	
							<div class=\'course-forum-post-view-container\'>	
						  ";
			
	if($post_order ne "instructor_post"){
		if (!defined $post_text){ die "post_text not defined. exiting.."; }
		elsif($c1 eq "elaborates"){
		$text_to_print .= "<table width=\'100\%\' style=\'border: 2px solid grey;\' cellpadding=10>
							<tr><td><label><div class=\'course-forum-post-header\'>
							<h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\'  style=\'font-size:14\'><tbody>
							<tr><td>POST #$post->{'order'} by User #$post_user</td></tr>
							</tbody></table></h5></div></label></td></tr>
							<tr><td><div dir=\'auto\' class=\'course-forum-post-text\' style=\'font-size:14; line-height: 140\%\'>
							$post_text</div></td></tr>";
		$text_to_print	 = printVotes($text_to_print, $postvotes);
		$text_to_print	.= "<tr><td><label><div class=\'course-forum-post-header\'>
							<h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\'  style=\'font-size:14\'><tbody>
							<!--<tr><td style=\'text-align:left\'>1) Yes, the instructor replies to this student post &nbsp;&nbsp;<input type=\'checkbox\' onclick=\'enableCombo(this,$post_order)\' value=\'$post_order\' name=\'$post_order\'> </td>-->	
							<td><a href=\'\#ipost\'>Go to Instructor's post</a></td></tr>
							<tr><td colspan = \'2\'>\&nbsp\;</td></tr>
							
							<form><br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'clarifies\'>Instructor clarifies or explains concept in detail(assuming student posed a question)<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'extension\'>Instructor brings up something new that could incite further discussion<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'juxtaposition\'>Instructor contrasts two concepts<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'refinement\'>Instructor concedes to criticism and refines his explanation in light of that criticism<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'critique\'>Instructor criticises the student's reasoning<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'nota\'>None of the above<br></form>
							</td></tr>
							</tbody></table></h5></div></label>
							</td></tr>";
	}
	elsif($c1 eq "resolves"){
		$text_to_print .= "<table width=\'100\%\' style=\'border: 2px solid grey;\' cellpadding=10>
							<tr><td><label><div class=\'course-forum-post-header\'>
							<h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\'  style=\'font-size:14\'><tbody>
							<tr><td>POST #$post->{'order'} by User #$post_user</td></tr>
							</tbody></table></h5></div></label></td></tr>
							<tr><td><div dir=\'auto\' class=\'course-forum-post-text\' style=\'font-size:14; line-height: 140\%\'>
							$post_text</div></td></tr>";
		$text_to_print	 = printVotes($text_to_print, $postvotes);
		$text_to_print	.= "<tr><td><label><div class=\'course-forum-post-header\'>
							<h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\'  style=\'font-size:14\'><tbody>
							<!--<tr><td style=\'text-align:left\'>1) Yes, the instructor replies to this student post &nbsp;&nbsp;<input type=\'checkbox\' onclick=\'enableCombo(this,$post_order)\' value=\'$post_order\' name=\'$post_order\'> </td>-->	
							<td><a href=\'\#ipost\'>Go to Instructor's post</a></td></tr>
							<tr><td colspan = \'2\'>\&nbsp\;</td></tr>
							
							<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'agreement\'>Instructor ONLY agrees with the student.(If he explains his stance, don't mark this)<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'disagreement\'>Instructor ONLY disagrees with the student.(If he explains his stance, don't mark this)<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'generic\'>Instructor gives generic reply. He does not explain beyond a line or two.<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'appreciation\'>Instructor appreciates the student's reasoning and thanks him.<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'completion\'>Instructor acknowledges that student's answer is almost correct and then completes his answer.<br>
							<input type = \'radio\' name=\'$post_order"."_discourse_type\' value= \'nota\'>None of the above<br>
							</td></tr>
							</tbody></table></h5></div></label>
							</td></tr>";
	}
	}
	else{
		$text_to_print	.=	"<table width=\'100%\' style=\'border: 2px solid blue;\' cellpadding=10>
							<tr><td><div class=\'course-forum-post-header\'><h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\' style=\'font-size:14\' ><tbody>
							<tr><td><font color=\'red\'>Instructor\'s Post</font></td></tr>
							</tbody></table></h5></div></td></tr>
							<tr><td>
							<div id = \'ipost\' class=\'course-forum-post-text\' dir=\'auto\' style=\'font-size:14.5; line-height: 140\%\'>$post_text</div>
							<div class=\'stuck\'><font color=\'red\'>Instructor's post</font> : $post_text</div>
							</td></tr>";
		$text_to_print	 = printVotes($text_to_print, $postvotes);
	}
	
	$text_to_print .= "</table></div></div></div>";
	$text_to_print	=~ s/\n/ /g;
	
	print $csvfh $text_to_print;
}


sub printVotes{
	my ($text_to_print, $postvotes) = @_;
	
	$text_to_print .= "<tr><td><div class=\'course-forum-post-vote-controls\' data-tooltip-position=\'down\' data-tooltip=\'Please use votes to bring attention to thoughtful, helpful posts.\' aria-expanded=\'false\' aria-haspopup=\'true\'>
			<div class=\'course-forum-post-vote-button course-forum-post-vote-up course-forum-vote-inactive\' role=\'button\' data-direction-value=\'1\' aria-label=\'Vote this post up.\' tabindex=\'0\'><font size=\'2\'>Upvotes:</div>
			<span class=\'course-forum-post-vote-count course-forum-votes-positive\'>$postvotes</span></font></div></td></tr>";
	return $text_to_print;
}
