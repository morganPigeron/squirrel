package main

import "core:testing"
import "core:math"
import "core:slice"
import "core:log"

/*
  add to visited,
  calculate real cost of neig,
  calculate total h + real,
  go to lowest total score


  keep a list of frontier
  keep a list of visited

  at the end find the shortest path by going from the end to the start 
*/

Cell :: struct {
    heuristic: int,
    path_cost: int,
    blocked:  bool,
    is_solution: bool,
}

Land :: struct {
    cells: []Cell,
    width: int,
    height: int,
    start: int,
    end: int,
    visited: [dynamic]int,
    border: [dynamic]int,
    found: bool,
    solution: []int,
}

step :: proc (l: ^Land) {

    // check initial state
    if len(l.visited) == 0 && len(l.border) == 0 {
        // set start as visited and found neighbors
        append(&l.visited, l.start)
        l.cells[l.start].path_cost = 0
        l.cells[l.start].heuristic = heuristic(l^, i_to_pos(l^, l.start))

        buffer :[4]int
        append(&l.border, ..find_neighbor(l^, l.start, &buffer))

        for b in l.border {
            l.cells[b].heuristic = heuristic(l^, i_to_pos(l^, b))
            l.cells[b].path_cost = 1
        }
        
    } else {
        
        next := find_next_to_visit(l^)

        if l.end == next {
            //end as been reached
            finalize(l)
            
        } else {

            append(&l.visited, next)

            neighbors :[4]int
            found := find_neighbor(l^, next, &neighbors)

            for index in found {

                // if already known, ignore
                if slice.contains(l.border[:], index) ||
                    slice.contains(l.visited[:], index) {
                        continue
                    }

                // append next in border and compute cell properties
                append(&l.border, index)
                l.cells[index].heuristic = heuristic(l^, i_to_pos(l^, index))
                l.cells[index].path_cost = l.cells[next].path_cost + 1
                
            }        
        }
    }
}

finalize :: proc (l: ^Land) {
    l.found = true
    final := &l.cells[l.end]
    
    l.solution = make([]int, final.path_cost + 1)
    l.solution[final.path_cost] = l.end
    log.debugf("len solution %v", len(l.solution))
    
    propagate: for i := final.path_cost - 1; i >= 0; i -= 1 {
        //find neighbor with less path_cost
        current := l.solution[i+1]
        
        neighbors :[4]int
        found := find_neighbor(l^, current, &neighbors)

        min_cost := i + 1     
        for neigh_i in found {

            //end condition
            if l.start == neigh_i {
                l.solution = l.solution[i:]
                l.solution[0] = l.start
                break propagate
            }
            
            if (!slice.contains(l.visited[:], neigh_i) &&
                !slice.contains(l.border[:], neigh_i)) ||
                l.cells[neigh_i].blocked {
                log.debugf("id %v is ignored", neigh_i)
                continue
            }
            
            if l.cells[neigh_i].path_cost <= min_cost {
                l.solution[i] = neigh_i
                min_cost = l.cells[neigh_i].path_cost
                log.debugf("id %v is in solution, min cost: %v", neigh_i, min_cost)
            }
        }
    }
    
    for cell in l.solution {
        log.debugf("%v", cell)
        l.cells[cell].is_solution = true
    }
}

find_next_to_visit :: proc (land: Land) -> (result: int) {
    
    if len(land.border) == 0 {
        result = 0
    } else {
        result = land.border[0]
        minimum := max(int)
        for index in land.border[1:] {
            if slice.contains(land.visited[:], index) || land.cells[index].blocked {
                continue
            }
            s := score(land.cells[index])
            if minimum > s {
                minimum = s
                result = index
            }
        }
    }
    
    return 
}

score :: proc (c: Cell) -> int {
    return c.heuristic
}

toggle_block :: proc (land: ^Land, index: int) {
    land.cells[index].blocked = !land.cells[index].blocked
}

find_neighbor :: proc (land: Land, index: int, buffer: ^[4]int) -> []int {
    center := i_to_pos(land, index)
    count := 0
    
    // top
    if center.y > 0 {
        buffer[count] = pos_to_i(land, center + {0,-1})
        count += 1
    }
    // left
    if center.x > 0 {
        buffer[count] = pos_to_i(land, center + {-1,0})
        count += 1
    }
    // right
    if center.x < land.width - 1 {
        buffer[count] = pos_to_i(land, center + {1,0})
        count += 1
    }
    // bottom
    if  center.y < land.height - 1 {
        buffer[count] = pos_to_i(land, center + {0,1})
        count += 1
    }

    return buffer[:min(count, 4)]
}

pos_to_i :: #force_inline proc (land: Land, pos: [2]int) -> int {
    assert(pos.x * pos.y <= len(land.cells) - 1)
    return pos.x + pos.y * land.width
}

i_to_pos :: #force_inline proc (land: Land, i: int) -> [2]int {
    assert(i <= len(land.cells) - 1)
    return {
        i % land.width,
        i / land.height,
    }
}

dist :: proc (a: [2]int, b: [2]int) -> [2]int {
    return {
        abs(b.x - a.x),
        abs(b.y - a.y),
    }
}

heuristic :: proc (land: Land, at_pos: [2]int) -> int {
    // must never overestimate heuristique to work
    to_end     := dist(at_pos, i_to_pos(land ,land.end))
    total := to_end
    dist := total.x * total.x + total.y * total.y
    return dist
}

new_land :: proc(width: int, height: int, start: [2]int, end: [2]int) -> Land {

    cells := make([]Cell, width * height)
    
    land := Land{
        cells = cells[:],
        width = width,
        height = height,
        visited = make([dynamic]int, 0, (width + height)/2),
        border = make([dynamic]int, 0, (width + height)/2),
    }

    land.start = pos_to_i(land, start)
    land.end = pos_to_i(land, end)
    return land
}

delete_land :: proc(l: ^Land) {
    delete(l.visited)
    delete(l.border)
    delete(l.cells)
    delete(l.solution)
}

@(test)
test_pos_to_i :: proc(t: ^testing.T) {
    l := new_land(10,10,{1,1},{8,8})
    defer delete_land(&l)
    testing.expect(t, l.start == 11)
    testing.expect(t, l.end == 88)
}

@(test)
test_i_to_pos :: proc(t: ^testing.T) {
    l := new_land(10,10,{1,1},{8,8})
    defer delete_land(&l)
    testing.expect(t, i_to_pos(l, 11) == {1,1})
    testing.expectf(t, i_to_pos(l, 88) == {8,8}, "%v", i_to_pos(l, 88))
}

@(test)
test_dist_a_to_b :: proc(t: ^testing.T) {
    l := new_land(10,10,{1,1},{8,8})
    defer delete_land(&l)
    s := i_to_pos(l, l.start)
    e := i_to_pos(l, l.end)
    testing.expect(t, dist(s, e) == {7,7})
    testing.expect(t, dist(e, s) == {7,7})
}

