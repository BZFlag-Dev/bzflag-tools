using System;
using System.Collections.Generic;
using System.Text;

namespace Connector
{
    public enum TeamColors
    {
        Red,
        Green,
        Blue,
        Purple,
        Black,
        Observer,
        Unknown,
    }

    public class GameQuery
    {
        public class GameOptions
        {
            public bool SuperFlags = false;
            public bool Jumping = false;
            public bool Inertia = false;
            public bool Ricochet = false;
            public bool BadFlagShakable = false;
            public bool BadFlagAntidote = false;
            public bool HandicapEnabled = false;
            public bool NoTeamKills = false;

            public void SetFromBitmask(UInt16 optionsMask)
            {
                SuperFlags = (optionsMask & 0x0002) != 0;
                Jumping = (optionsMask & 0x0008) != 0;
                Inertia = (optionsMask & 0x0010) != 0;
                Ricochet = (optionsMask & 0x0020) != 0;
                BadFlagShakable = (optionsMask & 0x0040) != 0;
                BadFlagAntidote = (optionsMask & 0x0080) != 0;
                HandicapEnabled = (optionsMask & 0x0080) != 0;
                BadFlagAntidote = (optionsMask & 0x0100) != 0;
                NoTeamKills = (optionsMask & 0x0400) != 0;
            }

            public override string ToString()
            {
                string ret = "";
                if (SuperFlags)
                    ret += "SuperFlags,";
                if (Jumping)
                    ret += "Jumping,";
                if (Inertia)
                    ret += "Inertia,";
                if (Inertia)
                    ret += "Inertia,";
                if (Ricochet)
                    ret += "Ricochet,";
                if (BadFlagShakable)
                    ret += "BadFlagShakable,";
                if (BadFlagAntidote)
                    ret += "BadFlagAntidote,";
                if (HandicapEnabled)
                    ret += "HandicapEnabled,";
                if (NoTeamKills)
                    ret += "NoTeamKills,";

                if (ret.Length > 0)
                    ret = ret.TrimEnd(",".ToCharArray());

                return ret;
            }
        }

        public enum GameType
        {
            TeamFFA,
            ClassicCTF,
            OpenFFA,
            Rabbit,
            Unknown,
        }

        public GameType ServerGameType = GameType.Unknown;

        public TeamColors IDToTeam(int id)
        {
            switch (id)
            {
                case 0:
                    return TeamColors.Black;
                case 1:
                    return TeamColors.Red;
                case 2:
                    return TeamColors.Green;
                case 3:
                    return TeamColors.Blue;
                case 4:
                    return TeamColors.Purple;
                case 5:
                    return TeamColors.Observer;
            }
            return TeamColors.Unknown;
        }

        public GameOptions Options = new GameOptions();

        public int MaxPlayers = -1;
        public int MaxShots = -1;

        public class TeamInfo
        {
            public int CurrentSize = 0;
            public int MaxSize = 0;

            public int Won = 0;
            public int Lost = 0;

            public TeamInfo(int s)
            {
                CurrentSize = s;
                MaxSize = s;
            }
        }
        protected Dictionary<TeamColors, TeamInfo> Teams = new Dictionary<TeamColors, TeamInfo>();

        public TeamInfo GetTeam(TeamColors team)
        {
            if (!Teams.ContainsKey(team))
                Teams.Add(team, new TeamInfo(0));

            return Teams[team];
        }

        public TeamInfo GetTeam(int team)
        {
            return GetTeam(IDToTeam(team));
        }

        public string GetTeamList()
        {
            string ret = "";
            foreach (KeyValuePair<TeamColors, TeamInfo> team in Teams)
            {
                if (team.Value.MaxSize > 0)
                    ret += team.Key.ToString() + ",";
            }

            if (ret.Length > 0)
                ret = ret.TrimEnd(",".ToCharArray());
            return ret;
        }

        public class PlayerInfo
        {
            public int PlayerID = 0;
            public TeamColors Team = TeamColors.Unknown;
            public bool Human = false;
            public int Wins = 0;
            public int Losses = 0;
            public int TKs = 0;
            public string Callsign = string.Empty;
            public string Motto = string.Empty;
        }

        public Dictionary<int, PlayerInfo> Players = new Dictionary<int, PlayerInfo>();

        public double BadFlagShakeTime = -1;
        public int BadFlagShakeWins = -1;

        public int MaxPlayerScore = 0;
        public int MaxTeamScore = 0;
        public int MaxTime = 0;
        public int TimeElapsed;

        protected int PlayerCount = 0;
        protected int TeamCount = 0;

        protected int AllowedTeamCount = 0;

        public bool Valid { get; private set; }

        public void SetGameType (UInt16 t)
        {
            if (t == 0)
                ServerGameType = GameType.TeamFFA;
            else if (t == 1)
                ServerGameType = GameType.ClassicCTF;
            else if (t == 2)
                ServerGameType = GameType.OpenFFA;
            else if (t == 3)
                ServerGameType = GameType.Rabbit;
            else
                ServerGameType = GameType.Unknown;
        }

        public void UnpackQueryGame(byte[] buffer, ref int offset)
        {
            Valid = false;

            if (buffer == null)
            {
                PlayerCount = 0;
                Valid = true;
                return;
            }

            SetGameType(BufferUtils.ReadUInt16(buffer, ref offset));
            
            Options.SetFromBitmask(BufferUtils.ReadUInt16(buffer, ref offset));

            MaxPlayers = BufferUtils.ReadUInt16(buffer, ref offset);
            MaxShots = BufferUtils.ReadUInt16(buffer, ref offset);

            Teams.Clear();
            GetTeam(TeamColors.Black).CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Red).CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Green).CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Blue).CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Purple).CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Observer).CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);

            GetTeam(TeamColors.Black).MaxSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Red).MaxSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Green).MaxSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Blue).MaxSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Purple).MaxSize = BufferUtils.ReadUInt16(buffer, ref offset);
            GetTeam(TeamColors.Observer).MaxSize = BufferUtils.ReadUInt16(buffer, ref offset);

            BadFlagShakeWins = BufferUtils.ReadUInt16(buffer, ref offset);
            BadFlagShakeTime = BufferUtils.ReadUInt16(buffer, ref offset) / 10.0;

            MaxPlayerScore = BufferUtils.ReadUInt16(buffer, ref offset);
            MaxTeamScore = BufferUtils.ReadUInt16(buffer, ref offset);

            MaxTime = BufferUtils.ReadUInt16(buffer, ref offset);
            TimeElapsed = BufferUtils.ReadUInt16(buffer, ref offset);

            AllowedTeamCount = 0;
            foreach (KeyValuePair<TeamColors, TeamInfo> team in Teams)
            {
                if (team.Value.MaxSize > 0)
                    AllowedTeamCount++;
            }
        }

        protected int playersRead = 0;

        public void UnpackQueryPlayers(byte[] buffer, ref int offset)
        {
            Players.Clear();
            if (buffer == null)
            {
                TeamCount = 0;
                PlayerCount = 0;
            }
            else
            {
                TeamCount = BufferUtils.ReadUInt16(buffer, ref offset);
                PlayerCount = BufferUtils.ReadUInt16(buffer, ref offset);    
            }
            
            playersRead = 0;

            if (PlayerCount == 0)
                Valid = true;
        }

        public void UnpackTeamUpdate(byte[] buffer, ref int offset)
        {
            if (buffer != null)
            {
                int teamsToUpdate = BufferUtils.ReadByte(buffer, ref offset);

                for (int i = 0; i < teamsToUpdate; i++)
                {
                    TeamInfo team = GetTeam(IDToTeam(BufferUtils.ReadByte(buffer, ref offset)));

                    team.CurrentSize = BufferUtils.ReadUInt16(buffer, ref offset);
                    team.Won = BufferUtils.ReadUInt16(buffer, ref offset);
                    team.Lost = BufferUtils.ReadUInt16(buffer, ref offset);
                }
            }

            if (PlayerCount == 0 && Teams.Count >= AllowedTeamCount)
                Valid = true;
        }

        public void UnpackAddPlayer(byte[] buffer, ref int offset)
        {
            int playerID = BufferUtils.ReadByte(buffer, ref offset);

            if (!Players.ContainsKey(playerID))
                Players.Add(playerID, new PlayerInfo());

            PlayerInfo player = Players[playerID];
            player.PlayerID = playerID;
            player.Human = BufferUtils.ReadUInt16(buffer, ref offset) == 0;
            player.Team = IDToTeam(BufferUtils.ReadUInt16(buffer, ref offset));

            player.Wins = BufferUtils.ReadUInt16(buffer, ref offset);
            player.Losses = BufferUtils.ReadUInt16(buffer, ref offset);
            player.TKs = BufferUtils.ReadUInt16(buffer, ref offset);

            player.Callsign = BufferUtils.ReadFixedString(buffer, ref offset, 32);
            player.Motto = BufferUtils.ReadFixedString(buffer, ref offset, 128);

            if (Players.Count == PlayerCount && Teams.Count >= AllowedTeamCount)
                Valid = true;
        }
    }
}
