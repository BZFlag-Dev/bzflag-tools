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
                conString = "SERVER=" + Configuration.Host + ";Port=" + Configuration.Port + ";" +
                "DATABASE=" + Configuration.Database + ";" +
                "UID=" + Configuration.Username + ";PASSWORD=" + Configuration.Password + ";";
            }

            MySqlConnection connection = new MySqlConnection(conString);
            connection.Open();

            return connection;
        }

        public void StorePlayerData (BZConnect connector)
        {
            MySqlConnection connection = Connect();

            string query = String.Format("INSERT INTO player_updates (whichTable, tableRecordID, notes) VALUES (@TABLE, @ID, @NOTE)");
            MySqlCommand command = new MySqlCommand(query, connection);
            command.ExecuteNonQuery();
        }

        public void StoreServerData(BZFSList.ServerEntry server)
        {
            MySqlConnection connection = Connect();

            string query = String.Format("INSERT INTO server_data (ServerHost, ServerName, Players, Observers, Timestamp) VALUES (@TABLE, @ID, @NOTE)");
            MySqlCommand command = new MySqlCommand(query, connection);
            command.ExecuteNonQuery();
        }

        public void StoreTotalData(int players, int servers)
        {
            MySqlConnection connection = Connect();

            string query = String.Format("INSERT INTO server_totals_log (Players, Servers, Timestamp) VALUES (@PLAYERS, @SERVERS, NOW())");
            MySqlCommand command = new MySqlCommand(query, connection);
            command.Parameters.Add(new MySqlParameter("PLAYERS", players));
            command.Parameters.Add(new MySqlParameter("SERVERS", servers));
            command.ExecuteNonQuery();
        }
    }
}
