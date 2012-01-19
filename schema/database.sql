-- MySQL dump 10.13  Distrib 5.1.49, for debian-linux-gnu (i486)
--
-- Host: localhost    Database: bz_stats
-- ------------------------------------------------------
-- Server version	5.1.49-3

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `player_updates`
--

DROP TABLE IF EXISTS `player_updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_updates` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `PlayerName` text,
  `ServerName` text,
  `Team` text,
  `Score` text,
  `Timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `player_updates`
--

LOCK TABLES `player_updates` WRITE;
/*!40000 ALTER TABLE `player_updates` DISABLE KEYS */;
/*!40000 ALTER TABLE `player_updates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_totals`
--

DROP TABLE IF EXISTS `server_totals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_totals` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `Players` int(11) DEFAULT NULL,
  `Servers` int(11) DEFAULT NULL,
  `Timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_totals`
--

LOCK TABLES `server_totals` WRITE;
/*!40000 ALTER TABLE `server_totals` DISABLE KEYS */;
/*!40000 ALTER TABLE `server_totals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `server_updates`
--

DROP TABLE IF EXISTS `server_updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_updates` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ServerName` text,
  `Players` int(11) DEFAULT NULL,
  `Observers` int(11) DEFAULT NULL,
  `Timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `server_updates`
--

LOCK TABLES `server_updates` WRITE;
/*!40000 ALTER TABLE `server_updates` DISABLE KEYS */;
/*!40000 ALTER TABLE `server_updates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'bz_stats'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-01-19  0:20:42
