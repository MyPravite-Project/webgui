package WebGUI::i18n::English::Poll;

our $I18N = {
	'1' => {
		message => q|Poll|,
		lastUpdated => 1031514049
	},

	'3' => {
		message => q|Active|,
		lastUpdated => 1031514049
	},

	'4' => {
		message => q|Who can vote?|,
		lastUpdated => 1031514049
	},

	'5' => {
		message => q|Graph Width|,
		lastUpdated => 1031514049
	},

	'6' => {
		message => q|Question|,
		lastUpdated => 1031514049
	},

	'7' => {
		message => q|Answers|,
		lastUpdated => 1031514049
	},

	'8' => {
		message => q|(Enter one answer per line. No more than 20.)|,
		lastUpdated => 1031514049
	},

	'9' => {
		message => q|Edit Poll|,
		lastUpdated => 1031514049
	},

	'10' => {
		message => q|Reset votes.|,
		lastUpdated => 1031514049
	},

	'11' => {
		message => q|Vote!|,
		lastUpdated => 1031514049
	},

	'20' => {
		message => q|Karma Per Vote|,
		lastUpdated => 1031514049
	},

	'61' => {
		message => q|Poll, Add/Edit|,
		lastUpdated => 1050183732
	},

	'71' => {
		message => q|Polls can be used to get the impressions of your users on various topics.
<br><br>
<b>Active</b><br>
If this box is checked, then users will be able to vote. Otherwise they'll only be able to see the results of the poll.
<br><br>

<b>Who can vote?</b><br>
Choose a group that can vote on this Poll.
<br><br>

<b>Karma Per Vote</b><br>
How much karma should be given to a user when they vote?
<p>

<b>Graph Width</b><br>
The width of the poll results graph. The width is measured in pixels.
<br><br>

<b>Question</b><br>
What is the question you'd like to ask your users?
<br><br>

<b>Answers</b><br>
Enter the possible answers to your question. Enter only one answer per line. Polls are only capable of 20 possible answers.
<br><br>

<b>Randomize answers?</b><br>
In order to be sure that the ordering of the answers in the poll does not bias your users, it is often helpful to present the options in a random order each time they are shown. Select "yes" to randomize the answers on the poll.
<p>

<b>Reset votes.</b><br>
Reset the votes on this Poll.
<br><br>
|,
		lastUpdated => 1050183732
	},

	'73' => {
		message => q|Poll Template|,
		lastUpdated => 1050183668
	},

	'74' => {
		message => q|The following variables are available to the poll template:

<b>canVote</b><br>
A condition indicating whether the user has the right to vote on this poll.
<p>

<b>question</b><br>
The poll question.
<p>

<b>form.start</b><br>
The beginning of the vote form.
<p>

<b>answer_loop</b><br>
A loop containing information about the answers in the poll.
<p>

<blockquote>

<b>answer.form</b><br>
The radio button for this answer.
<p>

<b>answer.text</b><br>
The text of the answer.
<p>

<b>answer.number</b><br>
The number of this answer. As in 1, 2, 3, etc.
<p>

<b>answer.graphWidth</b><br>
The width that the graph should be rendered for this answer. Based upon a percentage of the total graph size.
<p>


<b>answer.percent</b><br>
The percentage of the vote that this answer has received.
<p>

<b>answer.total</b><br>
The total number of votes that this answer has received.
<p>

</blockquote>


<b>form.submit</b><br>
The submit button for the poll form.
<p>

<b>form.end</b><br>
The end of the poll form.
<p>

<b>responses.label</b><br>
The label for the total responses. "Total Votes"
<p>

<b>responses.total</b><br>
The total number of votes that have been placed on this poll.
<p>

|,
		lastUpdated => 1050183668
	},

	'72' => {
		message => q|Randomize answers?|,
		lastUpdated => 1031514049
	},

	'12' => {
		message => q|Total Votes|,
		lastUpdated => 1050182699
	},

};

1;
