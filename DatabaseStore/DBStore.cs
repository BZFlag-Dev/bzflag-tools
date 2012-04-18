using System;
using System.Collections.Generic;
using System.Text;

using Connector;
using MySql.Data.MySqlClient;

namespace DatabaseStore
{
    public class DBStore
    {
        public class Config
        {
            public string Host = string.Empty;
            public string Port = "3306";
            public string Username = string.Empty;
            public string Password = string.Empty;
            public string Database = string.Empty;

            public string DatabaseSystem = "MYSQL";

            public class ConfigItem
            {
                public string Key = string.Empty;
                public string Value = string.Empty;
            }

            public List<ConfigItem> ExtraItems = new List<ConfigItem>();
        }

        public static Config Configuration = new Config();

        protected DBStore()
        {

        }

        public static DBStore NewDBConnect()
        {
            lock (Configuration)
            {
                if (Configuration.DatabaseSystem == "MYSQL")
                    return new MYSQLDb();
            }

            return new DBStore();
        }

        public virtual void StorePlayerData (BZConnect connector)
        {
        }

        public virtual void StoreServerActivityData(BZFSList.ServerEntry server)
        { 
        }

        public virtual void StoreServerBasicInfo(BZFSList.ServerEntry server)
        { 
        }

        public virtual void StoreTotalData(int players, int servers)
        {
        }
    }

    public class MYSQLDb : DBStore
    {
        internal MYSQLDb()
        {

        }

        protected MySqlConnection Connect()
        {
            string conString = string.Empty;

            lock (DBStore.Configuration)
            {
                if (DBStore.Configuration.Host == string.Empty)
                    return null;

                conString = "SERVER=" + DBStore.Configuration.Host + ";Port=" + DBStore.Configuration.Port + ";" +
                "DATABASE=" + DBStore.Configuration.Database + ";" +
                "UID=" + DBStore.Configuration.Username + ";PASSWORD=" + DBStore.Configuration.Password + ";";
            }

            try
            {
                MySqlConnection connection = new MySqlConnection(conString);
                connection.Open();

                return connection;
            }
            catch (System.Exception ex)
            {
                Console.WriteLine("error connecting to db " + ex.Message);
                return null;
            }

        }

        public override void StorePlayerData(BZConnect connector)
        {
            MySqlConnection connection = Connect();
            if (connection == null)
                return;

            DateTime now = DateTime.Now.ToUniversalTime();
            foreach (KeyValuePair<int, GameQuery.PlayerInfo> player in connector.GameInfo.Players)
            {
                string query = String.Format("INSERT INTO player_updates (PlayerName, ServerName, Team, Score, Wins, Losses, Teamkills, Timestamp) VALUES (@PLAYER, @SERVER, @TEAM, @SCORE, @WINS, @LOSSES, @TKS, @TIMESTAMP)");

                try
                {
                    MySqlCommand command = new MySqlCommand(query, connection);
                    command.Parameters.Add(new MySqlParameter("PLAYER", player.Value.Callsign.Trim().Replace("\0","")));
                    command.Parameters.Add(new MySqlParameter("SERVER", connector.Host + ":" + connector.Port.ToString()));
                    command.Parameters.Add(new MySqlParameter("TEAM", player.Value.Team.ToString()));
                    command.Parameters.Add(new MySqlParameter("SCORE", player.Value.Wins.ToString() + ":" + player.Value.Losses.ToString() + ":" + player.Value.TKs.ToString()));
                    command.Parameters.Add(new MySqlParameter("TIMESTAMP", now));

                    command.Parameters.Add(new MySqlParameter("WINS", player.Value.Wins.ToString()));
                    command.Parameters.Add(new MySqlParameter("LOSSES", player.Value.Losses.ToString()));
                    command.Parameters.Add(new MySqlParameter("TKS", player.Value.TKs.ToString()));

                    command.ExecuteNonQuery();

                    query = String.Format("SELECT ID FROM player_names WHERE PlayerName=@PLAYER");

                    command = new MySqlCommand(query, connection);
                    command.Parameters.Add(new MySqlParameter("PLAYER", player.Value.Callsign.Trim().Replace("\0", "")));
                    MySqlDataReader reader = command.ExecuteReader();

                    if (reader != null && reader.Read())
                    {
                        Int64 ID = reader.GetInt64(0);

                        reader.Close();
                        query = String.Format("UPDATE player_names SET LastPlayed=@TIMESTAMP WHERE ID=@ID");

                        command = new MySqlCommand(query, connection);
                        command.Parameters.Add(new MySqlParameter("ID", ID));
                        command.Parameters.Add(new MySqlParameter("TIMESTAMP", now));
                        command.ExecuteNonQuery();
                    }
                    else
                    {
                        reader.Close();
                        query = String.Format("INSERT INTO player_names (PlayerName, LastPlayed) VALUES (@PLAYER, @TIMESTAMP)");

                        command = new MySqlCommand(query, connection);
                        command.Parameters.Add(new MySqlParameter("PLAYER", player.Value.Callsign.Trim().Replace("\0", "")));
                        command.Parameters.Add(new MySqlParameter("TIMESTAMP", now));
                        command.ExecuteNonQuery();
                    }
                }
                catch (System.Exception ex)
                {
                    Console.WriteLine("error in StorePlayerData " + ex.Message);
                    Console.WriteLine(query);
                }

            }

            connection.Close();
            connection.Dispose();
        }

        public override void StoreServerActivityData(BZFSList.ServerEntry server)
        {
            MySqlConnection connection = Connect();
            if (connection == null)
                return;
            try
            {
                string query = String.Format("INSERT INTO server_updates (ServerName, Players, Observers, Timestamp) VALUES (@SERVER, @PLAYERS, @OBSERVERS, @TIMESTAMP)");
                MySqlCommand command = new MySqlCommand(query, connection);

                command.Parameters.Add(new MySqlParameter("PLAYERS", server.NonObservers));
                command.Parameters.Add(new MySqlParameter("SERVER", server.Host + ":" + server.Port.ToString()));
                command.Parameters.Add(new MySqlParameter("OBSERVERS", server.TotalPlayers - server.NonObservers));
                command.Parameters.Add(new MySqlParameter("TIMESTAMP", DateTime.Now.ToUniversalTime()));
                command.ExecuteNonQuery();

                connection.Close();
                connection.Dispose();
            }
            catch (System.Exception ex)
            {
                Console.WriteLine("error in StoreServerData " + ex.Message);
            }
        }

        public override void StoreServerBasicInfo(BZFSList.ServerEntry server)
        {
            MySqlConnection connection = Connect();
            if (connection == null)
                return;

            DateTime now = DateTime.Now.ToUniversalTime();
            string serverName = server.Host + ":" + server.Port.ToString();
            string query = string.Empty;

            try
            {
                query = String.Format("SELECT ID FROM server_names WHERE ServerName=@SERVER");

                MySqlCommand command = new MySqlCommand(query, connection);
                command.Parameters.Add(new MySqlParameter("SERVER", serverName));
                MySqlDataReader reader = command.ExecuteReader();

                if (reader != null && reader.Read())
                {
                    Int64 ID = reader.GetInt64(0);

                    reader.Close();
                    query = String.Format("UPDATE server_names SET Description=@DESCRIPTION, GameType=@GAMETYPE, GameFlags=@FLAGS, Teams=@TEAMS, LastUpdate=@TIMESTAMP WHERE ID=@ID");

                    command = new MySqlCommand(query, connection);
                    command.Parameters.Add(new MySqlParameter("ID", ID));
                    command.Parameters.Add(new MySqlParameter("DESCRIPTION", server.Description));
                    command.Parameters.Add(new MySqlParameter("GAMETYPE", server.GameInfo.ServerGameType.ToString()));
                    command.Parameters.Add(new MySqlParameter("FLAGS", server.GameInfo.Options.ToString()));
                    command.Parameters.Add(new MySqlParameter("TEAMS", server.GameInfo.GetTeamList()));
                    command.Parameters.Add(new MySqlParameter("TIMESTAMP", now));
                    command.ExecuteNonQuery();
                }
                else
                {
                    reader.Close();
                    query = String.Format("INSERT INTO server_names (ServerName, Description, GameType, GameFlags, Teams, LastUpdate) VALUES (@SERVER, @DESCRIPTION, @GAMETYPE, @FLAGS, @TEAMS, @TIMESTAMP)");

                    command = new MySqlCommand(query, connection);
                    command.Parameters.Add(new MySqlParameter("SERVER", serverName));
                    command.Parameters.Add(new MySqlParameter("DESCRIPTION", server.Description));
                    command.Parameters.Add(new MySqlParameter("GAMETYPE", server.GameInfo.ServerGameType.ToString()));
                    command.Parameters.Add(new MySqlParameter("FLAGS", server.GameInfo.Options.ToString()));
                    command.Parameters.Add(new MySqlParameter("TEAMS", server.GameInfo.GetTeamList()));
                    command.Parameters.Add(new MySqlParameter("TIMESTAMP", now));
                    command.ExecuteNonQuery();
                }
            }
            catch (System.Exception ex)
            {
                Console.WriteLine("error in StoreServerBasicInfo " + ex.Message);
                Console.WriteLine(query);
            }

            connection.Close();
            connection.Dispose();
        }

        public override void StoreTotalData(int players, int servers)
        {
            MySqlConnection connection = Connect();
            if (connection == null)
                return;

            try
            {
                string query = String.Format("INSERT INTO server_totals (Players, Servers, Timestamp) VALUES (@PLAYERS, @SERVERS, @TIMESTAMP)");
                MySqlCommand command = new MySqlCommand(query, connection);
                command.Parameters.Add(new MySqlParameter("PLAYERS", players));
                command.Parameters.Add(new MySqlParameter("SERVERS", servers));
                command.Parameters.Add(new MySqlParameter("TIMESTAMP", DateTime.Now.ToUniversalTime()));
                command.ExecuteNonQuery();
                connection.Close();
                connection.Dispose();
            }
            catch (System.Exception ex)
            {
                Console.WriteLine("error in StoreServerData " + ex.Message);
            }
        }
    }
}
