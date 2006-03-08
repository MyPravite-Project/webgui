package WebGUI::Help::Asset_WSClient;

our $HELP = {
	'ws client add/edit' => {
		title => '61',
		body => '71',
		fields => [
                        {
                                title => '72',
                                description => '72 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '8',
                                description => '8 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '13',
                                description => '13 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '14',
                                description => '14 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '2',
                                description => '2 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '3',
                                description => '3 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '4',
                                description => '4 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '5',
                                description => '5 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '16',
                                description => '16 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '11',
                                description => '11 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '9',
                                description => '9 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '15',
                                description => '15 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '28',
                                description => '28 description',
                                namespace => 'Asset_WSClient',
                        },
                        {
                                title => '27',
                                description => '27 description',
                                namespace => 'Asset_WSClient',
                        },
		],
		related => [
			{
				tag => 'ws client template',
				namespace => 'Asset_WSClient'
			},
			{
				tag => 'wobjects using',
				namespace => 'Asset_Wobject'
			}
		]
	},
	'ws client template' => {
		title => '72',
		body => '73',
		fields => [
		],
		related => [
			{
				tag => 'ws client add/edit',
				namespace => 'Asset_WSClient'
			},
			{
				tag => 'wobject template',
				namespace => 'Asset_Wobject'
			}
		]
	},
};

1;
