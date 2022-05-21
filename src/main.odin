package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:bufio"
import "core:bytes"
import "core:slice"

main :: proc() {
    if len(os.args) != 2 {
        fmt.println("Usage: bf [filename]")
        os.exit(-1)
    }
    file, ok := os.read_entire_file(os.args[1])
    if !ok {
        fmt.println("Invalid filepath")
        os.exit(-2)
    }

    Block :: struct {
        left_bracket: int,
        right_bracket: int,
    }
    blocks: [dynamic]Block
    defer delete(blocks)

    {
        bad_left_brackets: [dynamic]int
        defer delete(bad_left_brackets)
        bad_right_brackets: [dynamic]int
        defer delete(bad_right_brackets)
        loop0: for i := 0; i < len(file); i += 1 {
            if file[i] == '[' do append(&bad_left_brackets, i)
            else if file[i] == ']' {
                if len(bad_left_brackets) > 0 {
                    left_bracket := pop(&bad_left_brackets)
                    right_bracket := i
                    append(&blocks, Block{left_bracket, right_bracket})
                }
                else do append(&bad_right_brackets, i)
            }
        }
        i := 0
        j := 0
        if len(bad_left_brackets) > 0 || len(bad_right_brackets) > 0 do for {
            l := i < len(bad_left_brackets)
            r := j < len(bad_right_brackets)
            if !l && !r {
                os.exit(-3)
            }
            else if l && !r {
                report_error(file, "missing ]", bad_left_brackets[i])
                i += 1
            }
            else if r && !l {
                report_error(file, "missing [", bad_right_brackets[j])
                j += 1
            }
            else if i < j {
                report_error(file, "missing ]", bad_left_brackets[i])
                i += 1
            }
            else {
                report_error(file, "missing [", bad_right_brackets[j])
                j += 1
            }
        }
    }

    memory: [dynamic]u8
    defer delete(memory)
    mem_pos := 0
    append(&memory, 0)

    for i := 0; i < len(file); i += 1 {
        b := file[i]
        switch b {
            case '>':
                mem_pos += 1
                if mem_pos >= len(memory) {
                    append(&memory, 0)
                }
            case '<':
                mem_pos -= 1
                if mem_pos < 0 {
                    mem_pos = 0
                    insert_at(&memory, 0, 0)
                }
            case '+':
                if memory[mem_pos] == 255 do memory[mem_pos] = 0
                else do memory[mem_pos] += 1
            case '-':
                if memory[mem_pos] == 0 do memory[mem_pos] = 255
                else do memory[mem_pos] -= 1
            case '.':
                s := strings.clone_from_bytes([]byte{byte(memory[mem_pos])}, context.temp_allocator)
                fmt.print(s)
            case ',':
                fmt.println("\nEnter a character")
                fmt.print(">")
                buf := []byte{0}
                n, _ := os.read(os.stdin, buf[:])
                memory[mem_pos] = buf[0]
            case '[':
                if memory[mem_pos] == 0 {
                    for block in blocks {
                        if block.left_bracket == i {
                            i = block.right_bracket
                            break
                        }
                    }
                }
            case ']':
                if memory[mem_pos] != 0 {
                    for block in blocks {
                        if block.right_bracket == i {
                            i = block.left_bracket
                        }
                    }
                }
            case:

        }
    }
}

report_error :: proc(file: []byte, message: string, i: int) {
    line_beginning, line_end: int
    second_line_beginning: int
    n := 0
    for k := i; k >= 0; k -= 1 {
        if file[k] == '\n' {
            n += 1
            if n == 1 do second_line_beginning = k
            else if n == 2 {
                line_beginning = k
                break
            }
        }
    }
    for k := i; k < len(file); k += 1 {
        line_end = k
        if file[k] == '\n' do break
    }
    fmt.println("Error:", message)
    substring := file[line_beginning+1:line_end]
    fmt.printf("%v\n", string(substring))
    for k := second_line_beginning + 1; k < i; k += 1 {
        fmt.print(" ")
    }
    fmt.print("^\n\n")
}