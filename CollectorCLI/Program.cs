using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;

using System.IO;
using System.Threading;

using Connector;
namespace CollectorCLI
{
    class Program
    {
        public static void LogFunc(BZConnect con)
        {
           
        }

        static void Main(string[] args)
        {
            bool done = false;

            Stopwatch timer = null;

            double redoTime = 5*60;

            while (!done)
            {
                if (timer == null || timer.ElapsedMilliseconds >= (redoTime * 1000))
                {
                    BZFSList list = new BZFSList();
                    list.Update("http://my.bzflag.org/db/?action=LIST");

                    List<BZFSList.ServerEntry> servers = list.ServersWithRealPlayers(BZFSList.ServerEntry.BZFlagProduct, BZFSList.ServerEntry.BZFlagVersion);

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
                            if (player.Value.Team != TeamColors.Observer)
                                totalPlayers++;
                        }
                    }


                    FileInfo file = new FileInfo("results.csv");
                    StreamWriter sw = file.AppendText();

                    string line = DateTime.Now.ToString() + "," + totalServersWithPlayers.ToString() + "," + totalPlayers.ToString();

                    sw.WriteLine(line);
                    sw.Close();
                    file = null;

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
