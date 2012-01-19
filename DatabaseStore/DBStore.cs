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
        }

        public static Config Configuration = new Config();

        protected MySqlConnection Connect()
        {
            string conString = string.Empty;

            lock (Configuration)
            {
                if (Configuration.Host == string.Empty)
                    return null;

                conString = "SERVER=" + Configuration.Host + ";Port=" + Configuration.Port + ";" +
                "DATABASE=" + Configuration.Database + ";" +
                "UID=" + Configuration.Username + ";PASSWORD=" + Configuration.Password + ";";
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

        public void StorePlayerData (BZConnect connector)
        {
            MySqlConnection connection = Connect();
            if (connection == null)
                return;

            foreach (KeyValuePair<int,GameQuery.PlayerInfo> player in connector.GameInfo.Players)
            {
                string query = String.Format("INSERT INTO player_updates (PlayerName, ServerName, Team, Score, Timestamp) VALUES (@PLAYER, @SERVER, @TEAM, @SCORE, @TIMESTAMP)");
                
                try
                {
                    MySqlCommand command = new MySqlCommand(query, connection);
                    command.Parameters.Add(new MySqlParameter("PLAYER", player.Value.Callsign));
                    command.Parameters.Add(new MySqlParameter("SERVER", connector.Host + ":" + connector.Port.ToString()));
                    command.Parameters.Add(new MySqlParameter("TEAM", player.Value.Team.ToString()));
                    command.Parameters.Add(new MySqlParameter("SCORE", player.Value.Wins.ToString() + ":" + player.Value.Losses.ToString() + ":" + player.Value.TKs.ToString()));
                    command.Parameters.Add(new MySqlParameter("TIMESTAMP", DateTime.Now));
                    command.ExecuteNonQuery();
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

        public void StoreServerData(BZFSList.ServerEntry server)
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
                command.Parameters.Add(new MySqlParameter("TIMESTAMP", DateTime.Now));
                command.ExecuteNonQuery();

                connection.Close();
                connection.Dispose();
            }
            catch (System.Exception ex)
            {
                Console.WriteLine("error in StoreServerData " + ex.Message);
            }
            
        }

        public void StoreTotalData(int players, int servers)
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
                command.Parameters.Add(new MySqlParameter("TIMESTAMP", DateTime.Now));
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
