<?php  
	include_once("db.php");
	
	function doHeader()
	{
		echo "<html><head></head><body>";
	}
	
	function doFooter ()
	{
		echo "</body><html>";
	}
	
	function doIndex()
	{
		doHeader();
		// list servers with players
		
		$db = ConnectToDB();
		
		$query = "SELECT ID, Players, Servers, Timestamp FROM server_totals ORDER BY Timestamp DESC LIMIT 1";

		$lastUpdate = GetFirstQueryResults ( SQLGet($query));
		$id = $lastUpdate[0];
		$players = $lastUpdate[1];
		$servers = $lastUpdate[2];
		$time = $lastUpdate[3];
		
		echo "<h2>Last Update $time $id</h2>Servers with Players $servers</br>Real Players $players</br><h3>Current Servers</h3>";
		
		$now  = date ("Y-m-d H:i:s", time() - (5*60));
		
		$query = "SELECT ID, ServerName, Players, Observers FROM server_updates WHERE Timestamp > '$now'";
		$currentServers = GetResults(SQLGet($query));
		if (!$currentServers)
			echo "<div>No servers</div>";
		else
		{
			foreach ($currentServers as $server)
			{
				$name = $server[1];
				$players = $server[2];
				$observers = $server[3];
				
				echo "<div>$name Players: $players Observers: $observers</div>";
			}
		}
		
		echo "<h2>current players</h2>";
		
		$query = "SELECT ID, PlayerName FROM player_names WHERE LastPlayed > '$now'";
		$currentServers = GetResults(SQLGet($query));
		if (!$currentServers)
			echo "<div>No players</div>";
		else
		{
			foreach ($currentServers as $server)
			{
				$name = $server[1];
				
				echo "<div>$name</div>";
			}
		}
		
		doFooter();
	}
	
	doIndex();
?>