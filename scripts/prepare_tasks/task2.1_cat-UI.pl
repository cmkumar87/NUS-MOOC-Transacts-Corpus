#!/usr/bin/perl -w
use strict;
#use warnings qw(FATAL utf8);
require 5.0;

##
#
# Author : Muthu Kumar C
# compute tf and df for the corpus of threads
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

my $datahome = "$path/../data";

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
    #	@courses = ('reasonandpersuasion-001');
     @courses = ('classicalcomp-001');
	
}
elsif ($corpus eq 'd14'){
	@courses = ('ml-005');
}
elsif ($corpus eq 'd61'){
	# @courses = ('maps-002');
    # @courses = ('bioinfomethods1-001');
    @courses= ('neuralnets-2012-001');
    # @courses=('solarsystem-001');
    #@courses = ('advancedchemistry-001');
    #    @courses = ('dynamics1-001');
    #@courses = ('comparch-002');
    #@courses = ('smac-001');
    #@courses = ('medicalneuro-002');
    #    @courses = ('maththink-004');
    #@courses = ('casebasedbiostat-002');
	# @courses = ('organalysis-003');
	# @courses = ('diabetes-001');
	# @courses = ('amnhearth-002');
	# @courses = ('friendsmoneybytes-004');
	# @courses = ('gamification-003');
	# @courses = ('globalwarming-002');
	# @courses = ('howthingswork1-002');
	# @courses = ('marriageandmovies-001');
    #@courses = ('warhol-001');
	# 'modernmiddleeast-001'	
}


#this code prepares a csv with 5 columns
#getthreads
#print threadtype
#print threadtitle
#print posts
#print options

#my $csvfile = "input-peer.csv";
my $csvfile = "input-d14.csv";
my $outpath = "$path/../data/mturk/csv";
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
  $forumidsquery	.= "and forumname in('Lecture','Homework','Exam','General','Project','Discussion','PeerA')";
 #$forumidsquery	.= "and forumname in('Homework')";
 # $forumidsquery	.= "and forumname in('Lecture')";
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

    # our %selected=('Do lecture quizzes need to be 100% correct for course completion?',[1],'When are weekly lectures and assets release?',[1],'Open interval notation: ]ab[ ?',[1,2],'defining limits',[1],'“All foreign cars are badly made” What is the negation of this sentence?',[1,3],'Question about sets and elements - need help.',[1,2,3],'Lecture 10B minute 11',[1]);
 open FILE1, "output.txt" or die;
my %selected;
while (my $line=<FILE1>) {
    # $line =~ s/^"//;
    # $line =~ s/"$//g;
   #chomp($line);
   local $/;
   # map {
   my ($word1,$posts) = split /:/, $line;
   #print "$posts"; 
   #$selected{$word1} =  split /,/, @posts ;
   $selected{$word1} = [ split /\s*,\s*/, $posts];    # return a list of a key and a value array
   # };# split /\n/, <FILE1>; 
   };

use Data::Dumper;
print Dumper \%selected;


    foreach my $thread (@threads){
		
    print ref(%selected);
    # close($fh);
	our @titles = keys %selected;
		my $threadid 	= $thread->[0];
		if (!defined $inst_replied){
			$inst_replied = $thread->[3];
		}
		my $threadtitle = $thread->[4];
		my $forumid		= $thread->[6];
		if($threadtitle ~~ @titles){
		#round 1 reason threads 
		# if($threadid ne 461 && $threadid ne 299 && $threadid ne 129 && $threadid ne 296 && $threadid ne 281 
			# && $threadid ne 273 && $threadid ne 119){  
			# next;
		# }
		
		# round 1 classic threads 
	 	# if($threadid ne 52 && $threadid ne 30 && $threadid ne 166 && $threadid ne 258 && $threadid ne 244 && 
			# $threadid ne 100){  
			# next;
		# }

		# skip round 1 threads
		#classic
	 	# if($threadid eq 52 || $threadid eq 30 || $threadid eq 166 || $threadid eq 258 || $threadid eq 244 || 
			# $threadid eq 100){  
			# next;
		# }
		
		#reason
		# if( $threadid eq 461 || $threadid eq 299 || $threadid eq 129 || $threadid eq 296 || $threadid eq 281 
			# || $threadid eq 273 || $threadid eq 119 ){
			# next;
		# }

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
			if($post_order ~~ @posts_replied_to){
			printPost($csvfh, \%post);
			}
			
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
				#my @posts_replied_to = $selected{$threadtitle};
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

	my @post_replied_to = [1,2,6];

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
							
							<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'requests\'>Instructor requests justification (asks students to justify why they say something)<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'resolves\'>Instructor resolves/concludes the (ONLY subject-related) discussion<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'elaborates\'>Instructor elaborates or brings in NEW (ONLY subject-related) material<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'social\'>Instructor only socialises OR corrects course-organisational errors (ALL course logistics-related)<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'none\'>No relation with Instructor's post<br>
							
							</td></tr>
							</tbody></table></h5></div></label>
							</td></tr>";
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
}#}

sub printPost{
	my ($csvfh, $post)	= @_;
	
	my $post_text		= $post->{'post_text'};
	my $post_user		= $post->{'user'};
	my $post_order		= $post->{'order'};
	my $postvotes		= $post->{'votes'};
	
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
		$text_to_print .= "<table width=\'100\%\' style=\'border: 2px solid grey;\' cellpadding=10>
							<tr><td><label><div class=\'course-forum-post-header\'>
							<h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\'  style=\'font-size:14\'><tbody>
							<tr><td>POST #$post->{'order'} by User #$post_user</td></tr>
							</tbody></table></h5></div></label></td></tr>
							<tr><td><div dir=\'auto\' class=\'course-forum-post-text\' style=\'font-size:14; line-height: 140\%\'>
							$post_text</div></td></tr>";
		$text_to_print	 = printVotes($text_to_print, $postvotes);
		$text_to_print	.= "<tr><td><label><div class=\'course-forum-post-header\'><h5 class=\'course-forum-post-byline\'>
							<table width=\'100\%\'  style=\'font-size:14\'><tbody>
							<tr>
							<!--<td style=\'text-align:left\'>1) Yes, the instructor replies to this student post &nbsp;&nbsp;<input type=\'checkbox\' onclick=\'enableCombo(this,$post_order)\' value=\'$post_order\' name=\'$post_order\'></td>
							<td>--><a href=\'\#ipost\'>Go to Instructor's post</a>
							
							<!--<div class=\'couponcode\'>Paraphrase
    						<span class=\'coupontooltip\'>Content 1</span>
							</div>

							<div class=\'couponcode\'>Second Link
   							<span class=\'coupontooltip\'> Content 2</span>
							</div>-->				
							


							<tr><td colspan = \'2\'>\&nbsp\;</td></tr>
							<!--<tr><td style=\'text-align:left\'>2.1) Categorise the reply type &nbsp;
							<select disabled=\'\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' onChange=\'enableCombo2(this,$post_order)\'>
							<option value disabled selected> -- select an option -- </option>
							<option value=\'paraphrase\'>Paraphrase</option> 
							<option value=\'feedback\'>Feedback Request</option> 
							<option value=\'clarification\'>Clarification</option>
							<option value=\'refinement\'>Refinement</option>
							<option value=\'juxtaposition\'>Juxtaposition</option>
							<option value=\'justify\'>Justification Request</option> 
							<option value=\'critique\'>Reasoning Critique</option> 
							<option value=\'summary\'>Integration / Summarisation</option> 
							<option value=\'extension\'>Extension</option> 
							<option value=\'completion\'>Completion</option> 
							<option value=\'appreciation\'>Appreciation</option>
							<option value=\'answer\'>Generic answer</option> 
							<option value=\'agreement\'>Agreement</option> 
							<option value=\'disagreement\'>Disagreement</option>							
							<option value=\'other\'>Other</option></select>
							</select>
							</td></tr>
							<tr><td style=\'text-align:left\'>2.2) Assign a second reply type (optional) &nbsp;
							<select disabled=\'\' id=\'$post_order"."_2nd_discourse_type\' name=\'$post_order"."_2nd_discourse_type\'>
							<option value disabled selected> -- select an option -- </option>
							<option value=\'clarification\'>Clarification</option>
							<option value=\'answer\'>Generic answer</option> 
							</select>							
							</select>
							</td></tr>-->

							<!--<tr><td style=\'text-align:left\'>2.1) Social or Errata? &nbsp;
							<select enabled=\'\' id=\'$post_order"."_socialerrata_type\' name=\'$post_order"."_socialerrata_type\' onChange=\'AnswerDropdown(this,$post_order)\'>
							<option value enabled selected> -- select an option -- </option>
							<option value=\'social\' title=\'The student starts a purely social discussion\'>Social</option>
							<option value=\'errata\' title=\'Class organisation/logistics errors are pointed out, has nothing to do with the course content.'>Errata</option>
							<option value=\'notsocialerrata\'>None of the above</option>
							</select></select>

							<tr><td style=\'text-align:left\'>2.2) If neither, classify the reply type among &nbsp;
							<select disabled=\'\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' onChange=\'ElseCaseDropdown(this,$post_order)\'>
							<option value disabled selected> -- select an option -- </option>
							<option value=\'appreciation\' title=\'Instructor appreciates this reasoning.\'>Appreciation</option>
							<option value=\'agreement\' title=\'Instructor simply agrees with these comments. The reason might by simply stated without further elaboration or discussion.\'>Agreement</option>
							<option value=\'disagreement\' title=\'Instructor simply disagrees with these comments. The reason might by simply stated without further elaboration or discussion.\'>Disagreement</option>
							<option value=\'justify\' title=\'Instructor asks student to justify his position.\'>Justification Request</option>
							<option value=\'critique\' title=\'Instructor points out that the reasoning is not correct, usually through a negative response\'>Reasoning Critique</option>
							<option value=\'paraphrase\' title=\'Instructor only paraphrases or rephrases the idea from this post.\'>Paraphrase</option>
							<option value=\'refinement\' title=\'Instructor refines or defends his position, but may also partially concede to the points of this post and restate his position to clarify on those.\'>Refinement</option> 
							<option value=\'extension\' title=\'Instructor brings in completely new ideas in addition to this post, aimed at inciting further discussion.\'>Extension</option> 
							<option value=\'juxtaposition\' title=\'Instructor adds alternative ideas to compare and contrast, aimed at inciting further discussion\'>Juxtaposition</option>
							<option value=\'completion\' title=\'Instructor completes the answer given by this student.\'>Completion</option> 
							<option value=\'noneoftheabove\'>None of the above</option>
							</select></select>
							</td></tr>
							<tr><td style=\'text-align:left\'>2.3) If 'None of the above' selected above &nbsp;
							<select disabled=\'\' id=\'$post_order"."_2ndbr_elsecase_type\' name=\'$post_order"."_2ndbr_elsecase_type\'>
							<option value disabled selected> -- select an option -- </option>
							<option value=\'clarification\' title=\'The instructor clarifies the doubts expressed by this post.\'>Clarification</option>
							<option value=\'answer\' title=\'The instructor merely gives a factual answer, does not go into details.\'>Generic answer</option> 
							<option value=\'other\' title=\'The instructor does not answer this post.\'>Other/ No relation with Instructor post</option>
							</select>							
							</select>-->
							<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'requests\'>Instructor requests justification (asks students to justify why they say something)<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'resolves\'>Instructor resolves/concludes the (ONLY subject-related) discussion<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'elaborates\'>Instructor elaborates or brings in NEW (ONLY subject-related) material<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'social\'>Instructor only socialises OR corrects course-organisational errors (ALL course logistics related)<br>
							<input type = \'radio\' id=\'$post_order"."_discourse_type\' name=\'$post_order"."_discourse_type\' value= \'none\'>No relation with Instructor's post<br>

							</td></tr>
	

							</tbody></table></h5></div></label>
							</td></tr>";
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
