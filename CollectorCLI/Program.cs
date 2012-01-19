using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;

using System.Xml;
using System.Xml.Serialization;

using System.IO;
using System.Threading;

using Connector;
using DatabaseStore;

namespace CollectorCLI
{
    class Program
    {
        public static void LogFunc(BZConnect con)
        {
            new DBStore().StorePlayerData(con);
        }

        public static void LoadConfig ()
        {
            FileInfo cfg = new FileInfo("config.xml");
            if (!cfg.Exists)
            {
                FileStream fs = cfg.OpenWrite();
                XmlSerializer xml = new XmlSerializer(typeof(DBStore.Config));
                xml.Serialize(fs, DBStore.Configuration);
                fs.Close();
            }
            else
            {
                FileStream fs = cfg.OpenRead();
                XmlSerializer xml = new XmlSerializer(typeof(DBStore.Config));
                DBStore.Configuration = (DBStore.Config)xml.Deserialize(fs);
                fs.Close();
            }
        }

        static void Main(string[] args)
        {
            bool done = false;

            LoadConfig();

            Stopwatch timer = null;

            double redoTime = 5*60;

            while (!done)
            {
                if (timer == null || timer.ElapsedMilliseconds >= (redoTime * 1000))
                {
                    BZFSList list = new BZFSList();
                    list.Update("http://my.bzflag.org/db/?action=LIST");

                  
                    List<BZFSList.ServerEntry> servers = list.ServersWithRealPlayers(BZFSList.ServerEntry.BZFlagProduct, BZFSList.ServerEntry.BZFlagVersion);

                    foreach (BZFSList.ServerEntry server in servers)
                        new DBStore().StoreServerData(server);

                    List<BZConnect> Connectors = new List<BZConnect>();

                    int totalPlayers = 0;
                    int totalServersWithPlayers = 0;
                    foreach (BZConnect con in BZConnect.DoForeach(servers, LogFunc, 5))
                    {
                        totalServersWithPlayers++;

                        if (con.Results != BZConnect.ConnectionResult.Complete)
                            continue;

                        foreach (KeyValuePair<int, GameQuery.PlayerInfo> player in con.GameInfo.Players)
                        {
                            if (player.Value.Human && player.Value.Team != TeamColors.Observer)
                                totalPlayers++;
                        }
                    }


                    FileInfo file = new FileInfo("results.csv");
                    StreamWriter sw = file.AppendText();

                    string line = DateTime.Now.ToString() + "," + totalServersWithPlayers.ToString() + "," + totalPlayers.ToString();

                    sw.WriteLine(line);
                    sw.Close();
                    file = null;

                    new DBStore().StoreTotalData(totalPlayers, totalServersWithPlayers);

                    Console.WriteLine(line);
                    if (timer == null)
                        timer = new Stopwatch();

                    timer.Reset();
                    timer.Start();
                }
                Thread.Sleep(1000);
            }
        }
    }
}
