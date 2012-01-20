using System;
using System.Collections.Generic;
using System.Text;

using System.Net;
using System.IO;

namespace Connector
{
    public class BZFSList
    {
        public class ServerEntry
        {
            public string Line = string.Empty;

            public string Host = string.Empty;
            public int Port = 5154;
            public string IP = string.Empty;

            public string Product = string.Empty;
            public int Version = 0;

            public static string BZFlagProduct = "BZFS";
            public static int BZFlagVersion = 221;

            public GameQuery GameInfo = new GameQuery();

            public string Description = string.Empty;

            public int TotalPlayers { get; private set; }
            public int NonObservers { get; private set; }

            public string ServerInfoBlock = string.Empty;

            public ServerEntry(string line)
            {
                TotalPlayers = 0;
                NonObservers = 0;

                Parse(line);
            }

            protected byte GetHexValue(byte b)
            {
                if (b <= 57)
                    return(byte)(b - 48);

                return (byte)(10 + (b - 97));
            }

            protected byte ReadHex8(byte[] buffer, ref int offset)
            {
                if (buffer.Length < offset)
                    return 0;

                byte[] b = new byte[2];
                Array.Copy(buffer, offset, b, 0, 2);
                offset += 2;

                return (byte)((GetHexValue(b[0]) * 16) + GetHexValue(b[1]));
            }

            protected UInt16 ReadHex16(byte[] buffer, ref int offset)
            {
                return (UInt16)((ReadHex8(buffer, ref offset) * 256) + ReadHex8(buffer, ref offset));
            }

            public void Parse(string line)
            {
                Line = line;
                string[] parts = line.Split(" ".ToCharArray(), 5);
                if (parts.Length != 5)
                    return;

                string[] hostParts = parts[0].Split(":".ToCharArray());
                Host = hostParts[0];
                if (hostParts.Length > 1)
                    int.TryParse(hostParts[1], out Port);

                Version = -1;
                if (parts[1].Length == 8)
                {
                    Product = parts[1].Substring(0, 4);
                    int.TryParse(parts[1].Substring(4, 4), out Version);

                    if (Version == -1)
                        Product = parts[1];
                }
                else
                    Product = parts[1];

                if (Product == BZFlagProduct && Version == BZFlagVersion)
                {
                    //parse the update package
                    ServerInfoBlock = parts[2];
                    byte[] rawPackData = Encoding.ASCII.GetBytes(parts[2]);

                    int offset = 0;

                    GameInfo.SetGameType(ReadHex16(rawPackData, ref offset));
                    GameInfo.Options.SetFromBitmask(ReadHex16(rawPackData, ref offset));

                    GameInfo.MaxShots = ReadHex16(rawPackData, ref offset);
                    GameInfo.BadFlagShakeWins = ReadHex16(rawPackData, ref offset);
                    GameInfo.BadFlagShakeTime = ReadHex16(rawPackData, ref offset);
                    GameInfo.MaxPlayerScore = ReadHex16(rawPackData, ref offset);
                    GameInfo.MaxTeamScore = ReadHex16(rawPackData, ref offset);
                    GameInfo.MaxTime = ReadHex16(rawPackData, ref offset);

                    GameInfo.MaxPlayers = ReadHex8(rawPackData, ref offset);

                    GameInfo.GetTeam(TeamColors.Black).CurrentSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Black).MaxSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Red).CurrentSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Red).MaxSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Green).CurrentSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Green).MaxSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Blue).CurrentSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Blue).MaxSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Purple).CurrentSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Purple).MaxSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Observer).CurrentSize = ReadHex8(rawPackData, ref offset);
                    GameInfo.GetTeam(TeamColors.Observer).MaxSize = ReadHex8(rawPackData, ref offset);

                    NonObservers = GameInfo.GetTeam(TeamColors.Black).CurrentSize + GameInfo.GetTeam(TeamColors.Red).CurrentSize + GameInfo.GetTeam(TeamColors.Green).CurrentSize + GameInfo.GetTeam(TeamColors.Blue).CurrentSize + GameInfo.GetTeam(TeamColors.Purple).CurrentSize;
                    TotalPlayers = NonObservers + GameInfo.GetTeam(TeamColors.Observer).CurrentSize;
                }

                IP = parts[3];

                Description = parts[4];
            }
        }

        public List<ServerEntry> Servers = new List<ServerEntry>();

        public bool Update(string url)
        {
            Servers.Clear();

            try
            {
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);

                WebResponse responce = request.GetResponse();

                Stream stream = responce.GetResponseStream();
                StreamReader reader = new StreamReader(stream);

                while (!reader.EndOfStream)
                    Servers.Add(new ServerEntry(reader.ReadLine()));

                reader.Close();
                stream.Close();
                return true;
            }
            catch (System.Exception ex)
            {
                Console.WriteLine("Error in list serer update : " + ex.Message);
            }
            return false;
        }

        public List<ServerEntry> ServersWithRealPlayers()
        {
            List<ServerEntry> outServers = new List<ServerEntry>();

            foreach (ServerEntry server in Servers)
            {
                if (server.NonObservers > 0)
                    outServers.Add(server);
            }

            return outServers;
        }

        public List<ServerEntry> ServersWithRealPlayers(string product, int version)
        {
            List<ServerEntry> outServers = new List<ServerEntry>();

            foreach (ServerEntry server in ServersOfProduct(product,version))
            {
                if (server.NonObservers > 0)
                    outServers.Add(server);
            }

            return outServers;
        }


        public List<ServerEntry> ServersOfProduct( string product, int version)
        {
            List<ServerEntry> outServers = new List<ServerEntry>();

            foreach (ServerEntry server in Servers)
            {
                if (server.Product == product && server.Version == version)
                    outServers.Add(server);
            }

            return outServers;
        }

        public List<ServerEntry> ServersOfHost(string host)
        {
            List<ServerEntry> outServers = new List<ServerEntry>();

            string upperHost = host.ToUpper();

            foreach (ServerEntry server in Servers)
            {
                if (server.Host.ToUpper().Contains(upperHost))
                    outServers.Add(server);
            }

            return outServers;
        }
    }
}
