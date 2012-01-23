<?php  
	include_once("db.php");
	
	function doHeader()
	{
		echo "	<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">
				<html>
				<head>
				<meta http-equiv=\"refresh\" content=\"300\"> 
				<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">
				<title>Untitled Document</title>
				<style type=\"text/css\">
				<!--
				body,td,th {
				font-family: Arial, Helvetica, sans-serif;
				font-size: 12px;
				color: #000;
				padding:0px;
				margin:0px;
			}
			body {
				background-color: #FFF;
			}
			a.topnav:link,a.topnav:visited {color:#FFF;text-decoration:none;}
			a.topnav:hover,a.topnav:active {color:#FFF;text-decoration:none;}
			
			#topnav
			{
				margin:0;
				padding:5px;
				margin-top:5px;
				margin-bottom:10px;
				background-color:#039;
				background-position:bottom;
				background-repeat:repeat-x;
				font-size:16px;
				color:#FFF;
				font-family:Arial, Helvetica, sans-serif;
			}
			
			tr.statbox{
				margin-top: 10px;
				borer-top: solid black;
				vertical-align: top;
			}
			
			.statbox{
				margin:0;
				pading:0;
				font-size:80%;
			}
			
			h2.statbox{
				margin:0;
				pading:0;
			}
			
			table.current_table{
				border: solid black;
				margin-left: 10px;
				margin-right: 10px;
				padding-left:15px;
				vertical-align: top;
			}
			
			.stat_table_header{
				color: red;
				height: 35px;
				margin-bottom: 10px;
				font-size:80%;
				width: 300px;
			}
			
			-->
			</style></head>
			
			<body>
			<img src=\"img/stat_logo.png\" width=\"441\" height=\"100\">
			
			<div id=\"topnav\" style=\"clear:both;width:100%;height:25px;\">
			<div style=\"float:left;width:200px;word-spacing:12px;font-size:90%;padding-left:15px;padding-top:6px;white-space:nowrap;text-align:left;\">
				<a class=\"topnav\" href=\"/index.php?action=none\" target=\"_top\">Home </a>
				<a class=\"topnav\" href=\"/index.php?action=servers\" target=\"_top\">Servers </a>
				<a class=\"topnav\" href=\"/index.php?action=players\" target=\"_top\">Players </a>
			</div>
			<div style=\"float:right;width:100px;word-spacing:6px;font-size:80%;padding-right:13px;padding-top:7px;color:#888888;white-space:nowrap;text-align:right;\">
				<a class=\"topnav\" href=\"/index.php?action=about\" target=\"_top\">About</a>
			</div>
			</div>";
	}
	
	function doFooter ()
	{
		echo "</body>
				<html>";
	}
	
	function doScores ( $now )
	{
		$db = ConnectToDB();
		
		// popular server
		
		$query = "SELECT ID, ServerName, Players, Observers FROM server_updates WHERE Timestamp > '$now' ORDER BY Players DESC LIMIT 1";
		$popularServer = GetFirstQueryResults ( SQLGet($query));
		if ($popularServer)
		{
			$popName = $popularServer[1];
			$popPlayers = $popularServer[2];
			$popObservers = $popularServer[3];
			
			echo "<h2>Most Popular Server</h2>
			<h3>$popName</h3>
			<h3>Players: $popPlayers</h3>
			<h3>Observers: $popObservers</h3>";
		}
		
		// top score
		$query = "SELECT ID, PlayerName, ServerName, Score, Team FROM player_updates WHERE Timestamp > '$now' ORDER BY Wins DESC LIMIT 1";
		$bestPlayer = GetFirstQueryResults (SQLGet($query));
		
		if ($bestPlayer)
		{
			$bestName = $bestPlayer[1];
			$bestServer = $bestPlayer[2];
			$bestScore = $bestPlayer[3];
			$bestTeam = $bestPlayer[4];
			
			echo "<h2>Most Wins</h2>
			<h3>$bestName($bestTeam) $bestScore</h3>
			</h4>&nbsp;on $bestServer</h4>";
		}
		
		// low score
		$query = "SELECT ID, PlayerName, ServerName, Score, Team FROM player_updates WHERE Timestamp > '$now' ORDER BY Losses DESC LIMIT 1";
		$worstPlayer = GetFirstQueryResults (SQLGet($query));
		
		if ($worstPlayer)
		{
			$bestName = $worstPlayer[1];
			$bestServer = $worstPlayer[2];
			$bestScore = $worstPlayer[3];
			$bestTeam = $worstPlayer[4];
			
			echo "<h2>Worst Player</h2>
			<h3>$bestName($bestTeam) $bestScore</h3>
			</h4>&nbsp;on $bestServer</h4>";
		}
		
		// teamkills
		$query = "SELECT ID, PlayerName, ServerName, Score, Team FROM player_updates WHERE Timestamp > '$now' ORDER BY Teamkills DESC LIMIT 1";
		$worstPlayer = GetFirstQueryResults (SQLGet($query));
		
		if ($worstPlayer)
		{
			$bestName = $worstPlayer[1];
			$bestServer = $worstPlayer[2];
			$bestScore = $worstPlayer[3];
			$bestTeam = $worstPlayer[4];
			
			echo "<h2>Biggest Jerk</h2>
			<h3>$bestName($bestTeam) $bestScore</h3>
			</h4>&nbsp;on $bestServer</h4>";
		}
	}
	
	function doPastStats( $days )
	{
		$db = ConnectToDB();
		
		$now  = date ("Y-m-d H:i:s", time() - ($days*60*24*60));
	
		$query = "SELECT ID, Players, Servers, Timestamp FROM server_totals  WHERE Timestamp > '$now' ORDER BY Players DESC LIMIT 1";
	
		$maxInTime = GetFirstQueryResults ( SQLGet($query));
		$maxID = $maxInTime[0];
		$mostPlayers = $maxInTime[1];
		$mostServers = $maxInTime[2];
		$maximumTime = $maxInTime[3];
		
		$query = "SELECT ID, Players, Servers, Timestamp FROM server_totals  WHERE Timestamp > '$now' ORDER BY Players ASC LIMIT 1";
	
		$maxInTime = GetFirstQueryResults ( SQLGet($query));
		$minID = $maxInTime[0];
		$leastPlayers = $maxInTime[1];
		$leastServers = $maxInTime[2];
		$minimumTime = $maxInTime[3];
		
		$query = "SELECT ID FROM server_names WHERE LastUpdate > '$now'";
	
		$servers_total = count(GetResults ( SQLGet($query)));
		
		echo "<h2>Server Populations</h2>
		<h3>Available Servers: $servers_total</h3>
		<h3>Most Popular Time: $maximumTime GMT</h3><h4>$mostPlayers Players, $mostServers Servers</43>
		<h3>Least Popular Time: $minimumTime GMT</h3><h4>$leastPlayers Players, $leastServers Servers</h4>";
		
		doScores($now);
	}
	
	function doCurrentStats()
	{
		$db = ConnectToDB();
		
		$now  = date ("Y-m-d H:i:s", time() - (6*60));
	
		$query = "SELECT ID, Players, Servers, Timestamp FROM server_totals ORDER BY Timestamp DESC LIMIT 1";
	
		$lastUpdate = GetFirstQueryResults ( SQLGet($query));
		$id = $lastUpdate[0];
		$players = $lastUpdate[1];
		$servers = $lastUpdate[2];
		$time = $lastUpdate[3];
		
		$query = "SELECT ID FROM server_names WHERE LastUpdate > '$now'";
	
		$servers_total = count(GetResults ( SQLGet($query)));
		
		echo "<h2>Servers</h2>
		<h3>Available Servers: $servers_total</h3>
		<h3>Current Games: $servers</h3><h4>&nbsp;</h4>
		<h3>Current Players: $players</h3><h4>&nbsp;</h4>";
		
		// popular server

		doScores($now);
	}
	
	function doOldPage()
	{
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
	}
	
	function doCurrentHeader()
	{
		$db = ConnectToDB();
		$now  = date ("Y-m-d H:i:s", time() - (6*60));
	
		$query = "SELECT ID, Players, Servers, Timestamp FROM server_totals ORDER BY Timestamp DESC LIMIT 1";
	
		$lastUpdate = GetFirstQueryResults ( SQLGet($query));
		$id = $lastUpdate[0];
		$players = $lastUpdate[1];
		$servers = $lastUpdate[2];
		$time = $lastUpdate[3];
		
		$query = "SELECT ID FROM server_names WHERE LastUpdate > '$now'";
	
		$servers_total = count(GetResults ( SQLGet($query)));
		return "<h1>Current</h1><strong>Last update" . $time ."</strong>";
	}
	
	function doCurrent()
	{
		echo "<table class=\"current_table\">
			<tr><td><div class=\"stat_table_header\">" . doCurrentHeader() . "</div></td><td><div class=\"stat_table_header\"><h1>Today</h1></div></td><td><div class=\"stat_table_header\"><h1>This Week</h1></div></td></tr>
			<tr class=\"statbox\"><td><div class=\"statbox\">";
			
		doCurrentStats();
		echo "</div></td><td><div class=\"statbox\">";
		doPastStats(1);
		echo "</div></td><td><div class=\"statbox\">";
		doPastStats(7);
		echo "</div></td></tr></table>";
	}
	
	doHeader();
	// list servers with players
	
	if (!isset($_REQUEST['action']) || $_REQUEST['action'] == "none")
		doCurrent();
	else if (isset($_REQUEST['action']) && $_REQUEST['action'] == "oldpage")
		doOldPage();
	
	doFooter();
?>