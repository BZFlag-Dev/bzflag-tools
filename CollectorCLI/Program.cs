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

            bool GotList = false;

            List<BZFSList.ServerEntry> serversWithPlayers = new List<BZFSList.ServerEntry>();
            List<BZFSList.ServerEntry> allServers = new List<BZFSList.ServerEntry>();

            while (!done)
            {
                double WaitTime = redoTime * 1000;

                if (timer == null || timer.ElapsedMilliseconds >= WaitTime)
                {
                    BZFSList list = new BZFSList();
                    GotList = list.Update("http://my.bzflag.org/db/?action=LIST");

                    if (GotList)
                    {
                        serversWithPlayers = list.ServersWithRealPlayers(BZFSList.ServerEntry.BZFlagProduct, BZFSList.ServerEntry.BZFlagVersion);
                        allServers = list.ServersOfProduct(BZFSList.ServerEntry.BZFlagProduct, BZFSList.ServerEntry.BZFlagVersion);
                    }

                    if (GotList)
                    {
                        foreach (BZFSList.ServerEntry server in allServers)
                            new DBStore().StoreServerBasicInfo(server);
                    }
                   
                    foreach (BZFSList.ServerEntry server in serversWithPlayers)
                        new DBStore().StoreServerActivityData(server);

                    List<BZConnect> Connectors = new List<BZConnect>();

                    int totalPlayers = 0;
                    int totalServersWithPlayers = 0;
                    foreach (BZConnect con in BZConnect.DoForeach(serversWithPlayers, LogFunc, 5))
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
