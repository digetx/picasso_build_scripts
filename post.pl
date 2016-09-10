#!/usr/bin/perl -w

use File::Temp;
use File::Slurp;
use LWP::UserAgent::Determined;
use LWP::ConnCache;
use HTTP::Cookies;
use Text::Template;
use utf8;
use strict;

use Env qw(FLOGIN FPASS FID TID);

binmode(STDOUT, ':utf8');
binmode(STDIN, ':utf8');

my $ua = LWP::UserAgent::Determined->new();
$ua->conn_cache(LWP::ConnCache->new());
$ua->cookie_jar(HTTP::Cookies->new());

sub forum_login {
	my ($uname, $passw) = @_;

	my $req = HTTP::Request->new(POST => 'https://forum.tegraowners.com/ucp.php?mode=login');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("login=Login&username=$uname&password=$passw");
	my $res = $ua->request($req);

	die 'Forum login failed' if ($res->decoded_content !~ /successfully logged in/);
}

sub mk_post_msg {
	my $tmpl = Text::Template->new(TYPE => 'FILE',  SOURCE => 'misc/post.tmpl');

	my %vars = (
		KVER => $ARGV[0],
		DURL => $ARGV[1],
	);

	my $txt = $tmpl->fill_in(HASH => \%vars);

	die "$Text::Template::ERROR" if (! defined $txt);

	my ($fh, $fpath) = File::Temp::tempfile();

	print $fh "$txt";

	system("nano $fpath");

	return read_file($fpath);
}

sub post {
	my $txt = shift;
	my $retries = 2;

RETRY:
	my $res = $ua->get("https://forum.tegraowners.com/posting.php?mode=reply&f=$FID&t=$TID");

	my ($creation_time)	= ($res->decoded_content =~ /name="creation_time" value="(\d+)"/);
	my ($form_token)	= ($res->decoded_content =~ /name="form_token" value="(\w+)"/);
	my ($topic_cur_post_id)	= ($res->decoded_content =~ /name="topic_cur_post_id" value="(\d+)"/);
	my ($lastclick)		= ($res->decoded_content =~ /name="lastclick" value="(\d+)"/);

	die if (! defined $creation_time);
	die if (! defined $form_token);
	die if (! defined $topic_cur_post_id);
	die if (! defined $lastclick);

	my $subject = 'Kernel ' . $ARGV[0] . ' release';

	sleep 5;

	$res = $ua->post("https://forum.tegraowners.com/posting.php?mode=reply&f=$FID&t=$TID",
		[ 'subject'		=> "$subject",
		  'message'		=> "$txt",
		  'creation_time'	=> "$creation_time",
		  'form_token'		=> "$form_token",
		  'topic_cur_post_id'	=> "$topic_cur_post_id",
		  'lastclick'		=> "$lastclick",
		  'topic_id'		=> "$TID",
		  'forum_id'		=> "$FID",
		  'notify'		=> '1',
		  'post'		=> 'Submit',
		],
		Content_Type => 'application/x-www-form-urlencoded',
	);

	return if ($res->decoded_content =~ /posted successfully/);

	goto RETRY if ($retries--);

	die 'Forum posting failed';
}

forum_login($FLOGIN, $FPASS);

my $post_txt = mk_post_msg();

post($post_txt);
