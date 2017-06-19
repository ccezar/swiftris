//
//  FullLineShape.swift
//  Swiftris
//
//  Created by Caio Cezar Lopes dos Santos on 17/06/17.
//  Copyright © 2017 Bloc. All rights reserved.
//

class FullLineShape: Shape {
    /*
     Orientations 0 and 180:
     
     | 0•|
     | 1 |
     | 2 |
     | X |
     
     Orientations 90 and 270:
     
     | 0•| 1 | 2 | X |
     
     • marks the row/column indicator for the shape
     
     */
    
    init(column: Int, row: Int) {
        super.init()
        self.column = column
        self.row = row
        
        for index in 0..<NumColumns {
            blocks.append(Block(column: index, row: row, color: .random()))
        }
    }
    
    init(column: Int, row: Int, blocks: [Block]) {
        super.init()
        self.column = column
        self.row = row
        self.blocks = blocks
    }
    
    // Hinges about the second block
    
    override var blockRowColumnPositions: [Orientation: Array<(columnDiff: Int, rowDiff: Int)>] {
        var zeroOneEighty = [(columnDiff: Int, rowDiff: Int)]()
        for column in 0..<NumColumns {
            zeroOneEighty.append((0, column))
        }
        
        var ninetyTwoSeventy = [(columnDiff: Int, rowDiff: Int)]()
        for column in 0..<NumColumns {
            ninetyTwoSeventy.append((column, 0))
        }
        
        return [
            Orientation.zero:       zeroOneEighty,
            Orientation.oneEighty:  zeroOneEighty,
            Orientation.ninety:     ninetyTwoSeventy,
            Orientation.twoSeventy: ninetyTwoSeventy
        ]
    }
    
    override var bottomBlocksForOrientations: [Orientation: Array<Block>] {
        return [
            Orientation.zero:       [blocks[NumColumns - 1]],
            Orientation.ninety:     blocks,
            Orientation.oneEighty:  [blocks[NumColumns - 1]],
            Orientation.twoSeventy: blocks
        ]
    }
}

