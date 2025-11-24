#Assembly Hashmap
####A simple self contained implementation of a hashmap data structure
To build a brief demo of the code run `make example`<br>
`main.asm` is a poorly commented usage example if that's your preference
##Usage
Start off by initializing the data structure using `create_map`. All of the functions in this program use C-like calling conventions, and all fields are assumed to be 64 bits<br>
Size is the number of unique indecies the map will have. It's treated as a 64 bit unsigned int, but because each element is 24 bytes, and extra space is needed at the end<br>
of the structure to store the result of any hash collisions, this function allocates `size*32` bytes of space, so very large sizes (In the quadrillions) will cause issues, but you'll probably run out of ram before you run into this issue<br>
`map*   create_map(uint64 size);`<br>
To write any data to the map use `write_item`, you can also use `add_item` or `update_item`, as these are just aliases for the same function.<br>
This takes three arguments, a pointer to an initialized map, a string(char pointer) key, and an anonomous pointer to the data<br>
If there isn't enough memory in the map to write the new value it'll return -12 in RAX and you'll have to grow the map with `resize_map`<br>
`void   write_item(map* map, char* key, void* value);`<br>
To retrive data use `get_item`, it takes a map pointer, a string key, and returns the anonomous value pointer<br>
If no such value exists, it'll return -1<br>
`void*  get_item(map* map, char* key);`<br>
To remove a value from the map use `remove_item` function. It takes the same args as `get_item` but returns 0 for success, or a negative number for failure<br>
`int    remove_item(map* map, char* key);`<br>
If you're done with a map you can free the memory yourself using the `sys_unmap` syscall, or you can just pass it to the `destroy_map` function<br>
This function returns the result of the `sys_unmap` syscall, so you can use its docs to troubleshoot if something isn't working<br>
`int    destroy_map(map* map);`<br>
I haven't tested this function yet but it should work i think<br>
`map*   resize_map(map* map, uint64 size);`

