using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using Connector;

namespace CollectorGUI
{
    public partial class Form1 : Form
    {
        public class ServerInfo
        {
            public BZConnect connector = null;
            public BZFSList.ServerEntry server = null;

            public override string ToString()
            {
                if (server == null)
                    return "Unknown";

                return server.Host + ":" + server.Port.ToString();
            }
        }
        List<ServerInfo> servers = new List<ServerInfo>();

        ThreadedListWalker walker = new ThreadedListWalker();
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            BZFSList list = new BZFSList();
            list.Update("http://my.bzflag.org/db/?action=LIST");

            List<BZFSList.ServerEntry> serversWithPlayers = list.ServersOfProduct("BZFS",221);

            listView1.Items.Clear();

            foreach (BZFSList.ServerEntry server in serversWithPlayers)
            {
                ServerInfo s = new ServerInfo();
                s.server = server;
                s.connector = walker.NewConnection(server.Host, server.Port);
                servers.Add(s);

                ListViewItem item = new ListViewItem();
                item.StateImageIndex = 1;
                item.Tag = s;
                item.Text = s.ToString();

                listView1.Items.Add(item);
            }


            timer1.Interval = 100;
            timer1.Tick += new EventHandler(timer1_Tick);
            timer1.Start();
        }

        void timer1_Tick(object sender, EventArgs e)
        {
            foreach (ListViewItem item in listView1.Items)
            {
                ServerInfo s = item.Tag as ServerInfo;

                if (s == null)
                    continue;

                if (s.connector.Valid())
                    item.StateImageIndex = 0;
                if (s.connector.TimedOut())
                    item.StateImageIndex = 2;
                else
                    item.StateImageIndex = 1;
            }
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
           walker.Kill();
        }

        private void listView1_SelectedIndexChanged(object sender, EventArgs e)
        {
            textBox1.Text = string.Empty;

            if (listView1.SelectedItems.Count == 0)
                return;

            ServerInfo s = listView1.SelectedItems[0].Tag as ServerInfo;
            if (s == null)
                return;

            textBox1.Text = "Server " + s.server.Host + ":" + s.server.Port.ToString() + "(" + s.server.IP + ")\r\n";
            if (s.connector.Valid())
            {
                textBox1.Text += "Players : " + s.connector.GameInfo.Players.Count.ToString() + "\r\n";

                foreach (KeyValuePair<int,GameQuery.PlayerInfo> player in s.connector.GameInfo.Players)
                {
                    textBox1.Text += player.Value.PlayerID.ToString() + " " + player.Value.Callsign + " : " + player.Value.Team.ToString() + "\r\n";
                }
            }
        }
    }
}
