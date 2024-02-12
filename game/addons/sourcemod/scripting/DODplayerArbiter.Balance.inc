#endinput
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

#define BALANCE_CALL_PERIOD 5*60
#define BALANCE_CALL_COUNT  3
#define BALANCE_CALL_SUPPORT_PERIOD 1*60
#define BALANCE_VOTE_PERIOD 15*60
#define BALANCE_VOTE_GAME_PAUSE 10
#define SND_VOTE_START	"k64t\\votestart.mp3"
#define SND_VOTE_FINISH	"k64t\\votefinish.mp3"
// Global Var
int g_balance_call_period = BALANCE_CALL_PERIOD;
int g_balance_call_count  = BALANCE_CALL_COUNT;
int g_balance_call_support_period = BALANCE_CALL_SUPPORT_PERIOD;
int g_balance_vote_period = BALANCE_VOTE_PERIOD; 
int g_balance_vote_game_pause = BALANCE_VOTE_GAME_PAUSE;

int g_Balance_vote_status; // 0-call, 1-vote, 2-off
int g_Balance_last_vote;
char snd_votestart[]=SND_VOTE_START; //Sound vote start
char snd_votefinish[]=SND_VOTE_FINISH;//Sound vote finish
char part1[32]; //tmp var
//***********************************************
public Action Command_Say(int client, int args){
//***********************************************
if (g_Balance_vote_status==0)
	{
	#if defined DEBUG
	DebugPrint("Command_Say.Client %d, args %d",client,args);
	#endif
	//Do not use GetCmdArg. It not response cyrilic 
	char argstext[128];
	int pos;
	GetCmdArgString(argstext, sizeof(argstext)); // argstext=карту de_dust2
	StripQuotes(argstext);
	pos = BreakString(argstext, part1, sizeof(part1));
	int len = pos;
	int key_word_cnt=1;
	char key_word[]="баланс";
	for (int i=0;i!=key_word_cnt;i++)
		if (strcmp(part1, key_word[i], false) == 0)
			{		
			if (pos==-1) part1[0]=0;
			else BreakString(argstext[len], part1, sizeof(part1));
			cmd_Elect_Player();
			return Plugin_Stop;
			}
	}		
return Plugin_Continue;
}
//***********************************************
int cmd_Elect_Player(){
//***********************************************
#if defined DEBUG
DebugPrint("cmd_Elect_Player");
#endif
}

