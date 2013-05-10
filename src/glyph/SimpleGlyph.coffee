# # ttf.js - JavaScript TrueType Font library
#
# Copyright (C) 2013 by ynakajima (https://github.com/ynakajima)
#
# Released under the MIT license.

# ## Simple Glyph Class
class SimpleGlyph
  constructor: () ->
    @type = 'simple'
    @numberOfContours = 0
    @xMin = 0
    @yMin = 0
    @xMax = 0
    @yMax = 0
    @endPtsOfContours = []
    @instructionLength = 0
    @instructions = []
    @flags = []
    @xCoordinates = []
    @yCoordinates = []

    # _outline = [
    #   [ # first countour
    #     {x:  0, y:   0, on: false}, # coordinate
    #     {x: 40, y: -20, on: true },
    #     ...
    #   ],
    #   [ # second countour
    #     ...
    #   ],
    #   [....]
    # ]
    @_outline = []

    # set outline
    # @param {Object} outline
    # @return {SimpleGlyph} this
    @setOutline = (outline) ->
      @_outline = outline ? []
      @

    # return outline
    # @return {Object} outline
    @getOutline = () ->
      @_outline


  # Create SimpleGlyph instance from TTFDataView
  # @param {TTFDataView} view
  # @param {Number} offset 
  # @return {SimpleGlyph}
  @createFromTTFDataView: (view, offset) ->
    view.seek offset
    g = new SimpleGlyph()
    
    # number of contours
    g.numberOfContours = view.getShort()

    # no contours
    if g.numberOfContours is 0
      return g
    
    # xMin yMin xMax yMax
    g.xMin = view.getShort()
    g.yMin = view.getShort()
    g.xMax = view.getShort()
    g.yMax = view.getShort()
   
    # endPtsOfContours
    g.endPtsOfContours = for i in [1..g.numberOfContours]
      view.getUshort()

    # number of coordinates
    numberOfCoordinates = g.endPtsOfContours[g.endPtsOfContours.length - 1] + 1

    # instrunctions
    g.instructionLength = view.getUshort()
    if g.instructionLength > 0 
      g.instructions = for i in [1..g.instructionLength]
        view.getByte()
    
    # flags
    flags = []
    i = 0

    while i < numberOfCoordinates
      flag = view.getByte()
      flags.push flag
      i++

      # repeat
      if flag & Math.pow(2, 3)
        numRepeat = view.getByte()
        for j in [1..numRepeat]
          if i < numberOfCoordinates
            flags.push flag
            i++

    g.flags = flags

    # xCoordinates
    g.xCoordinates = for flag in flags
      x = 0
      if flag & Math.pow(2, 1) # short Vector
        x = (if flag & Math.pow(2, 4) then 1 else -1) * view.getByte()
      else
        x = if flag & Math.pow(2, 4) then 0 else view.getShort()

    # yCoordinates
    g.yCoordinates = for flag in flags
      y = 0
      if flag & Math.pow(2, 2) # short Vector
        y = (if flag & Math.pow(2, 5) then 1 else -1) * view.getByte()
      else
        y = if flag & Math.pow(2, 5) then 0 else view.getShort()

    # outline
    startPtOfContour = x = y = 0
    outline = for endPtOfcountour in g.endPtsOfContours
      contour = for i in [startPtOfContour..endPtOfcountour]
        x += g.xCoordinates[i]
        y += g.yCoordinates[i]
        {
          x: x
          y: y
          on: flags[i] & Math.pow(2, 0)
        }
      startPtOfContour = endPtOfcountour + 1
      contour

    g.setOutline outline
    
    # return glyph
    g

# exports
module.exports = SimpleGlyph
