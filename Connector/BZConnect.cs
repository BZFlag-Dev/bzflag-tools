using System;
using System.Collections.Generic;
using System.Text;
using System.Net.Sockets;
using System.Threading;
using System.Diagnostics;

namespace Connector
{
    public class BZConnect
    {
        public static double Timeout = 30;

        public string Host = string.Empty;
        public int Port = 5154;

        public bool Connected { get; protected set; }

        public bool DisconnectOnInfoComplete = true;

        TcpClient Connection = null;

        public enum ConnectionResult
        {
            Failed = 0,
            Complete,
            TimedOut,
            BadVersion,
            BadData,
            Disconnected,
            Errored,
        }

        public string LastError = string.Empty;

        public ConnectionResult Results = ConnectionResult.Failed;

        public BZConnect() { Connected = false; }
        public BZConnect(string host, int port)
        {
            Host = host;
            Port = port;
        }

        ~BZConnect()
        {
            Disconnect();
        }

        public ConnectionResult Connect(string host, int port)
        {
            Host = host;
            Port = port;
            return Connect();
        }

        public ConnectionResult Connect()
        {
            try
            {
                Connection = new TcpClient(Host, Port);

                Connected = Connection.Connected;
                DoNetworkConnection();
            }
            catch (System.Exception ex)
            {
                Results = ConnectionResult.Errored;
                LastError = ex.Message;
            }
            return Results;
        }

        public void Disconnect()
        {
            if (Connection != null)
            {
                if (Connection.Connected)
                {
                    NetworkStream n = Connection.GetStream();
                    if (n != null)
                        n.Close();
                }
                Connection.Close();
            }
        }

        protected void WriteSting(string str)
        {
            AddOutbound(Encoding.ASCII.GetBytes(str));
        }

        protected List<byte[]> OutboundMessages = new List<byte[]>();

        protected void AddOutbound(byte[] buffer)
        {
            lock (OutboundMessages)
            {
                OutboundMessages.Add(buffer);
            }
        }

        protected void SendStringNow(string str, NetworkStream stream)
        {
            if (stream.CanWrite)
            {
                byte[] b = Encoding.ASCII.GetBytes(str);
                stream.Write(b, 0, b.Length);
            }
        }

        protected void SendMessage(UInt16 code)
        {
            byte[] b = new byte[4];
            BufferUtils.WriteUInt16(0, b, 0);
            BufferUtils.WriteUInt16(code, b, 2);

            AddOutbound(b);
        }

        public static UInt16 MsgQueryGame = 0x7167;
        public static UInt16 MsgQueryPlayers = 0x7170;
        public static UInt16 MsgTeamUpdate = 0x7475;
        public static UInt16 MsgAddPlayer = 0x6170;

        public GameQuery GameInfo = new GameQuery();

        protected void SendQueryMessages()
        {
            SendMessage(MsgQueryGame);
            SendMessage(MsgQueryPlayers);
        }

        protected virtual void ConnectedtoBZFS()
        {
        }

        protected bool DisconnectNow = false;
        protected bool ExitConnectLoop = false;

        protected virtual bool InfoLoaded()
        {
            return DisconnectOnInfoComplete;
        }

        protected virtual void ProcessUnknownMessage(UInt16 code, byte[] data)
        {
        }

        protected void ProcessMessage(UInt16 code, byte[] data)
        {
            int offset = 0;
            lock (GameInfo)
            {
                if (code == MsgQueryGame)
                    GameInfo.UnpackQueryGame(data, ref offset);
                else if (code == MsgQueryPlayers)
                    GameInfo.UnpackQueryPlayers(data, ref offset);
                else if (code == MsgTeamUpdate)
                    GameInfo.UnpackTeamUpdate(data, ref offset);
                else if (code == MsgAddPlayer)
                    GameInfo.UnpackAddPlayer(data, ref offset);
                else
                    ProcessUnknownMessage(code, data);
            }

            if (GameInfo.Valid)
                DisconnectNow = InfoLoaded();
        }

        byte PlayerID = 255;
        protected void DoNetworkConnection()
        {
            Stopwatch t = new Stopwatch();
            double connectTimeout = 10.0;
            t.Start();
            while (!Connection.Connected)
            {
                Thread.Sleep(10);
                if (t.ElapsedMilliseconds > connectTimeout * 1000)
                {
                    Results = ConnectionResult.Failed;
                    LastError = "Initial connection failed to respond";
                    Disconnect();
                    return;
                }
            }

            NetworkStream stream = null;
            try
            {
                stream = Connection.GetStream();

                string header = "BZFLAG\r\n\r\n";
                try
                {
                    SendStringNow(header, stream);
                } 
                catch (System.Exception ex)
                {
                    Results = ConnectionResult.Errored;
                    LastError = "Data send error: " + ex.Message;
                    Disconnect();
                    return;
                }

                bool connected = false;
                string version = string.Empty;

                byte[] readBuffer = null;

                while (!ExitConnectLoop || Connection != null && Connection.Connected)
                {
                    if (t.ElapsedMilliseconds > Timeout * 1000)
                    {
                        Results = ConnectionResult.TimedOut;
                        LastError = "Data Retrieval timeout";
                        Disconnect();
                        return;
                    }

                    if (DisconnectNow)
                    {
                        Results = ConnectionResult.Complete;
                        Disconnect();
                        return;
                    }

                    if (stream.CanRead && stream.DataAvailable)
                    {
                        if (!connected)
                        {
                            byte[] b = new byte[9];
                            int read = stream.Read(b, 0, 9);
                            if (read == 9)
                            {
                                string v = Encoding.ASCII.GetString(b, 0, read);
                                if (!v.Contains("BZF"))
                                {
                                    break;
                                }

                                connected = true;
                                version = Encoding.ASCII.GetString(b, 4, 4);
                                PlayerID = b[8];
                                SendQueryMessages();
                                ConnectedtoBZFS();

                                if (stream.DataAvailable)
                                {
                                    b = new byte[1024];
                                    read = stream.Read(b, 0, 1024);
                                    v = Encoding.ASCII.GetString(b, 0, read);
                                }                            
                            }
                            else
                                break;
                        }
                        else
                        {
                            byte[] b = new byte[1024];
                            int read = stream.Read(b, 0, b.Length);
                            if (read > 0)
                            {
                                t.Reset();
                                t.Start();

                                if (readBuffer == null)
                                {
                                    readBuffer = new byte[read];
                                    Array.Copy(b, 0, readBuffer, 0, read);
                                }
                                else
                                {
                                    int oldLen = readBuffer.Length;

                                    Array.Resize(ref readBuffer, oldLen + read);
                                    Array.Copy(b, 0, readBuffer, oldLen, read);
                                }
                            }

                            // process any remaining message buffer
                            int offset = 0;
                            UInt16 len = BufferUtils.ReadUInt16(readBuffer, ref offset);
                            UInt16 code = BufferUtils.ReadUInt16(readBuffer, ref offset);

                            while (!ExitConnectLoop && readBuffer != null && readBuffer.Length >= 4 && (len + 4) <= readBuffer.Length)
                            {
                                byte[] data = null;

                                if (len > 0)
                                {
                                    data = new byte[len];
                                    Array.Copy(readBuffer, offset, data, 0, len);
                                }

                                if (len + 4 == readBuffer.Length)
                                    readBuffer = null;
                                else
                                {
                                    byte[] newBuf = new byte[readBuffer.Length - (len + 4)];
                                    Array.Copy(readBuffer, len + 4, newBuf, 0, newBuf.Length);
                                    readBuffer = newBuf;
                                }
                                ProcessMessage(code, data);

                                if (DisconnectNow)
                                {
                                    Results = ConnectionResult.Complete;
                                    Disconnect();
                                    return;
                                }

                                offset = 0;
                                if (readBuffer != null)
                                {
                                    len = BufferUtils.ReadUInt16(readBuffer, ref offset);
                                    code = BufferUtils.ReadUInt16(readBuffer, ref offset);
                                }                               
                            }
                        }
                    }

                    byte[] bufferToSend = null;
                    lock (OutboundMessages)
                    {
                        if (OutboundMessages.Count > 0)
                        {
                            bufferToSend = OutboundMessages[0];
                            OutboundMessages.RemoveAt(0);
                        }
                    }

                    while (bufferToSend != null)
                    {
                        if (Connection != null && Connection.Connected && stream.CanWrite)
                         {
                             try
                             {
                                 stream.Write(bufferToSend, 0, bufferToSend.Length);

                             }
                             catch (System.Exception ex)
                             {
                                 Results = ConnectionResult.Errored;
                                 LastError = "Data send error: " + ex.Message;
                                 Disconnect();
                                 return;
                             }
                        }
                        bufferToSend = null;
                        lock (OutboundMessages)
                        {
                            if (OutboundMessages.Count > 0)
                            {
                                bufferToSend = OutboundMessages[0];
                                OutboundMessages.RemoveAt(0);
                            }
                        }
                    }

                    Thread.Sleep(1000);
                }
            }
            catch (System.Exception ex)
            {
                Results = ConnectionResult.Disconnected;
                LastError = "Connection Died: " + ex.Message;
                Disconnect();
                return;
                
            }

            if (DisconnectNow)
            {
                Results = ConnectionResult.Complete;
                Disconnect();
            }
        }

        public delegate void ProcessFunction ( BZConnect connection );

        public static List<BZConnect> DoForeach(List<BZFSList.ServerEntry> servers, ProcessFunction function, int maxThreads )
        {
            List<BZConnect> completed = new List<BZConnect>();

            List<Worker> workers = new List<Worker>();
            int index = 0;

            while (index < servers.Count || workers.Count > 0)
            {
                if (index < servers.Count && workers.Count < maxThreads)
                {
                    Worker worker = new Worker();
                    worker.connection = new BZConnect(servers[index].Host, servers[index].Port);
                    worker.completionFunciton = function;

                    workers.Add(worker);
                    index++;
                    new Thread(new ThreadStart(worker.Do)).Start();
                }

                List<Worker> workersToDie = new List<Worker>();
                foreach (Worker worker in workers)
                {
                    if (worker.Done())
                    {
                        completed.Add(worker.connection);
                        workersToDie.Add(worker);
                    }
                }

                foreach (Worker worker in workersToDie)
                    workers.Remove(worker);
            }

            return completed;
        }

        public class Worker
        {
            public BZConnect connection = null;
            public ProcessFunction completionFunciton = null;

            protected object locker = new object();

            protected bool done = false;

            public bool Done()
            {
                lock (locker)
                    return done;
            }

            public void Do()
            {
                connection.Connect();

                if (completionFunciton != null)
                    completionFunciton(connection);
                lock (locker)
                    done = true;
            }
        }
    }

    public class BufferUtils
    {
        public static void WriteUInt16(UInt16 value, byte[] buffer, int offset)
        {
            byte[] b = BitConverter.GetBytes(value);
            if (BitConverter.IsLittleEndian)
                Array.Reverse(b);

            Array.Copy(b, 0, buffer, offset, b.Length);
        }

        public static Int32 ReadInt32(byte[] buffer, ref int offset)
        {
            byte[] iBuf = new byte[4];
            Array.Copy(buffer, offset, iBuf, 0, 4);
            offset += 4;
            if (BitConverter.IsLittleEndian)
            {
                Array.Reverse(iBuf);
            }
            return BitConverter.ToInt32(iBuf, 0);
        }

        public static UInt32 ReadUInt32(byte[] buffer, ref int offset)
        {
            byte[] iBuf = new byte[4];
            Array.Copy(buffer, offset, iBuf, 0, 4);
            offset += 4;
            if (BitConverter.IsLittleEndian)
            {
                Array.Reverse(iBuf);
            }
            return BitConverter.ToUInt32(iBuf, 0);
        }

        public static UInt16 ReadUInt16(byte[] buffer, ref int offset)
        {
            byte[] iBuf = new byte[2];
            Array.Copy(buffer, offset, iBuf, 0, 2);
            offset += 2;
            if (BitConverter.IsLittleEndian)
            {
                Array.Reverse(iBuf);
            }
            return BitConverter.ToUInt16(iBuf, 0);
        }

        public static Int16 ReadInt16(byte[] buffer, ref int offset)
        {
            byte[] iBuf = new byte[2];
            Array.Copy(buffer, offset, iBuf, 0, 2);
            offset += 2;
            if (BitConverter.IsLittleEndian)
            {
                Array.Reverse(iBuf);
            }
            return BitConverter.ToInt16(iBuf, 0);
        }

        public static Int16 ReadByte(byte[] buffer, ref int offset)
        {
            return buffer[offset++];
        }

        public static string ReadFixedString(byte[] buffer, ref int offset, int lenght)
        {
            byte[] iBuf = new byte[lenght];
            Array.Copy(buffer, offset, iBuf, 0, lenght);
            offset += lenght;
            return Encoding.ASCII.GetString(iBuf).Trim();
        }
    }
}
