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

#include <algorithm>
#include "graph/PlanarGraph.h"

namespace graph {

  void PlanarGraph::readFaces() {

      // Create a sorted list of Nodes by the x coordinate.
      NodeVector xnodes = nodeList.getCopy();
      std::sort( xnodes.begin(), xnodes.end(), compareNodesX );

      // Perform a sweep while reading faces
      for ( size_t i = 0; i < xnodes.size(); i++ ) {
        extractFaces( xnodes[i] );
      }
  }

  void PlanarGraph::extractFaces( Node* node ) {
    Edge* startEdge = node->getFirstOutgoingEdge();
    if ( !startEdge ) return;
    Edge* edge = startEdge;

    // Cycle through the outgoing edges.
    do {
      if ( edge->getFace() == NULL ) {
        extractFace( edge );
      }
      edge = node->getOutgoingList().next( edge );
    } while ( edge != startEdge );
  }

  void PlanarGraph::extractFace( Edge* edge ) {
    Face* face = new Face( this );
    Edge* startEdge = edge;

    do {
      face->addEdge( edge );
      edge = edge->getTarget()->getOutgoingList().prev( edge );
    } while ( edge != startEdge );

    // check if the face is degenerate.
    if ( face->size() < 3 ) {
      delete face;
      return;
    }

    faceList.add( face );
    ++faces;
  }

  Node* PlanarGraph::closestNode( const Vector2Df v ) {
    if (nodes == 0) return NULL;

    // get first existing node
    Node* result = NULL;
    {
      size_t i = 0;
      while ( result == NULL ) {
        result = nodeList.get(i);
        i++;
      }
    }
    float distance = result->distanceTo( v );

    for ( size_t i = 0; i < nodeList.size(); i++ ) {
      if ( nodeList.get(i) != NULL ) {
        if (nodeList.get(i)->distanceTo( v ) < distance) {
          result = nodeList.get(i);
          distance = result->distanceTo( v );
        }
      }
    }
    return result;
  }

  Edge* PlanarGraph::closestEdge( const Vector2Df v ) {
    if (edges == 0) return NULL;

    // get first existing node
    Edge* result = NULL;
    {
      size_t i = 0;
      while ( result == NULL ) {
        result = edgeList.get(i);
        i++;
      }
    }
    float distance = result->distanceTo( v );

    for ( size_t i = 0; i < edgeList.size(); i++ ) {
      Edge* edge = edgeList.get( i );
      if ( edge != NULL && !edge->isReversed( ) ) {
        if ( edge->distanceTo( v ) < distance ) {
          result = edge;
          distance = result->distanceTo( v );
        }
      }
    }
    return result;
  }

  void PlanarGraph::split( Vector2Df a, Vector2Df b ) {
    NodeVector splitPoints;
    for ( size_t i = 0; i < edgeList.size(); i++ ) {
      Edge* edge = edgeList.get( i );
      if ( edge != NULL && !edge->isReversed( ) ) {
        Vector2Df r1;
        Vector2Df r2;
        if ( math::intersect2D( edge->getSource( )->vector(), edge->getTarget( )->vector(), a, b, r1, r2 ) == 1 ) {
          splitPoints.push_back( splitEdge( edge, r1 ) );
        }
      }
    }
    if ( splitPoints.empty() ) return;
    std::sort( splitPoints.begin(), splitPoints.end(), compareNodesX );
    for ( size_t i = 0; i < splitPoints.size()-1; i++ ) {
      addConnection( splitPoints[i], splitPoints[i+1] );
    }
  }


} // end namespace graph

// Local Variables: ***
// mode:C++ ***
// tab-width: 8 ***
// c-basic-offset: 2 ***
// indent-tabs-mode: t ***
// End: ***
// ex: shiftwidth=2 tabstop=8
