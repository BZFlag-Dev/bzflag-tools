/* bzflag
 * Copyright (c) 1993 - 2008 Tim Riker
 *
 * This package is free software;  you can redistribute it and/or
 * modify it under the terms of the license found in the file
 * named COPYING that should have accompanied this file.
 *
 * THIS PACKAGE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */
/** 
 * @file FaceGenerator.h
 * @author Kornel Kisielewicz kornel.kisielewicz@gmail.com
 * @brief Implements a Generator class that works on graph faces.
 */

#ifndef __FACEGENERATOR_H__
#define __FACEGENERATOR_H__

#include "Generator.h"
#include "Material.h"
#include "globals.h"
#include "Output.h"

/** 
 * @class FaceGenerator
 * @brief Class for the map generator working on graphs. 
 */
class FaceGenerator : public Generator {
public:
  /** 
   * Constructor, just runs it's inherited constructor. 
   */
  FaceGenerator( RuleSet* _ruleset ) : Generator( _ruleset ) {};
  /** 
   * Parses options. 
   */
  void parseOptions( CCommandLineArgs* /*opt*/ );
  /**
   * Runs the generator. 
   */
  void run( );
  /**
   * Destructor.
   */
  virtual ~FaceGenerator( ) {}
private:
  /** 
   * Creates the first "face" of the graph, by adding edges and nodes 
   * around the world.
   */
  void createInitialGraph( );
  /**
   * Creates the layout of the major roads. Stores them in the graph.
   * Generation is controlled by already stored options.
   */
  void runPrimaryRoadGeneration( );
  /**
   * Creates the layout of the secondary roads. To save on collision 
   * tests these are stored inside the faces made by the primary 
   * road network. In case of a normal bzw map, there would be
   * only a few primary roads.
   */
  void runSecondaryRoadGeneration( );
  /** 
   * The final level of road network generation is the subdivision of
   * lots created by secondary road generation into lots acceptable by
   * the ruleset (e.g. with no degenerated faces). This method also is
   * responsible for pushing zones.
   */
  void subdivideFace( graph::Face* face );
};

#endif /* __FACEGENERATOR_H__ */

// Local Variables: ***
// mode:C++ ***
// tab-width: 8 ***
// c-basic-offset: 2 ***
// indent-tabs-mode: t ***
// End: ***
// ex: shiftwidth=2 tabstop=8
