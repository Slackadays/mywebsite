+++
title = "How is Ultrassembler so fast?"
date = 2025-08-30
+++

[Ultrassembler](https://github.com/Slackadays/Chata/tree/main/ultrassembler) is a superfast and complete RISC-V assembler library that I'm writing as a component of the bigger [Chata signal processing](https://github.com/Slackadays/Chata) project. 

Assemblers take in a platform-dependent assembly language and output that platform's native machine code which runs directly on the processor.

![Infographic showing the RISC-V assembly process for addi](/RISC-V-assembly-safe.svg)

<span class="inline-quote">"Why would you want to do this?"</span> you might ask. First, existing RISC-V assemblers that conform the the entirety of the specification, `as` and `llvm-mc`, ship as binaries that you run as standalone programs. This is normally not an issue. However, in Chata's case, it needs to access a RISC-V assembler from within its C++ code. The alternative is to use some ugly C function like `system()` to run external software as if it were a human or script running a command in a terminal. 

Here's an example of what I'm talking about:

```cpp
#include <iostream>
#include <string>
#include <stdlib.h>

int main() {
    std::string command = "riscv64-linux-gnu-as code.s -o code.bin";

    int res = std::system(command.data());

    if (res != 0) {
        std::cerr << "Error executing command: " << command << std::endl;
    }
    return res;
}
```

It gets even worse once you realize you need temporary files and possibly have to artisanally craft the command beforehand. Additionally, invoking the assembler in this manner incurs a significant performance overhead on embedded systems which lack significant processing power. There must be a better way. 

Enter Ultrassembler.

With these two goals of speed and standard conformance in mind, I wrote Ultrassembler as a completely standalone library with GNU `as` as the speed and standard conformity benchmark. 

The results are nothing short of staggering. 

After months of peformance optimization, Ultrassembler can assemble a test file with about 16 thousand RISC-V instructions over 10 times faster than `as`, and around 20 times faster than `llvm-mc`. To put it another way, it only takes about 1000 CPU instructions (+-50% depending on platform) to assemble one RISC-V instruction, while it takes 10,000 for `as` and 20,000 for `llvm-mc`. This happens with plain old C++ code only and no platform-specific assembly code, although integrating assembly could crank up the speed even further.

Such performance ensures a good user experience on the platforms where Chata runs, but also as a consequence of this lack of overhead, you could also combine Ultrassembler with fantastic libraries like [libriscv](https://github.com/libriscv/libriscv) to implement low-to-no-cost RISC-V scripting in things like games, or maybe even in your JIT programming language!

Let's look at some of the ways I made Ultrassembler this fast so that you can reap the benefits too.

<span class="warning">WARNING!</span> &nbsp; The code you're about to see here is only current as of this article's publishing. The actual code Ultrassembler uses could be different by the time you read this in the future!

# Exceptions

Exceptions, C++'s first way of handling errors, are slow. Super duper slow. Mega slow. So slow, in fact, that many Programming Furus©️®️™️ say you should never ever use them. They'll infect your code with their slowness and transform you into a slow old hunchback in no time. 

Or so you would think.

C++ exceptions, despite being so derided, are in fact zero-overhead. Huh? Didn't I just say they were super duper slow? Let me explain.

It's not clear when exactly exceptions are slow. I had to do some research here. As it turns out, GCC's `libstdc++` uses a so-called "zero-overhead" exception system, meaning that in the ideal normal case where the C++ code calls zero exceptions, there is zero performance penalty. But when it does call an exception, it could become very slow depending on how the code is laid out. Most programmers, not knowing this, frequently use exceptions in their normal cases, and as a result, their programs are slow. Such mysterious behavior caught the attention of Programming Furus©️®️™️ and has made exceptions appear somewhat of a curse.

This tragic curse turns out to be a heavenly blessing for Ultrassembler. In the normal case, there are zero errors to report as a result of proper usage of RISC-V instructions. But if there's some error somewhere, say somebody put in the wrong register, then Ultrassembler sounds the alarm. Since such mistakes only occur as a result of human error (ex bugs in codegen and Ultrassembler itself) the timeframe in which to report the error can expand to that of a human. As a result, even if an exception triggered by a mistake took a full 1 second (about a million times slower than it does in reality), it doesn't matter because the person percepting the error message can only do so in approximately that second timeframe.

<span class="inline-quote">"But hold on!"</span> you exclaim. <span class="inline-quote">"What about std::expected?"</span> In response to some programs which frequently need to handle errors not seen by humans, C++ added a system to reduce the overhead of calling errors, `std::expected`. I tried this in Ultrassembler and the results weren't pretty. It trades off exception speed for normal case speed. Since the normal case is the norm in Ultrassembler, `std::expected` incurred at least a 10% performance loss due to the way the `std::expected` object wraps two values (the payload and the error code) together. [See this C++ standard document for the juicy details.](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p2544r0.html)

The end result of the use of exceptions is that there is zero performance penalty to optimize out.

# Fast data structures

Between all of the RISC-V instruction set extensions, there are 2000+ individual "instructions" (many instructions are identical to one another with a slight numerical change). There are also hundreds of CSRs and just under a hundred registers. This requires data structures large enough to store the properties of thousands of entries. How do you do that? It's tricky. So, how about I just show you what Ultrassembler uses as of this writing:

```cpp
struct rvregister {
    RegisterType type; //1B
    RegisterID id; //1B
    uint8_t encoding;
    uint8_t padding;
};

const std::array<rvregister, 96> registers;

struct rvinstruction {
    RVInstructionID id; //2B
    RVInstructionFormat type; //1B
    uint8_t opcode;
    uint16_t funct;
    RVInSetMinReqs setreqs; //1B
    rreq regreqs = reg_reqs::any_regs; //1B
    special_snowflake_args ssargs = special_snowflake_args(); //2B
};

// We use a strong typedef to define both rreq and ssflag, but the underlying is a uint8_t in both cases

namespace ssarg {

constexpr ssflag get_imm_for_rs = ssflag(0b00000001);
constexpr ssflag use_frm_for_funct3 = ssflag(0b00000010);
constexpr ssflag special_handling = ssflag(0b00000100);
constexpr ssflag swap_rs1_rs2 = ssflag(0b00001000);
constexpr ssflag use_funct_for_imm = ssflag(0b00010000);
constexpr ssflag no_rs1 = ssflag(0b00100000);
constexpr ssflag has_custom_reg_val = ssflag(0b01000000);

}

struct special_snowflake_args {
    uint8_t custom_reg_val = 0;
    ssflag flags; //1B
};

const std::array<rvinstruction, 2034> instructions;
```

Let's go over what each `struct` does.

## `rvregister`

`rvregister` is how Ultrassembler stores the data for all the RISC-V registers. What describes a register? You have its friendly name (like x0 or v20), an alias (like zero or fa1), what kind of register it is (integer, float, or vector?), and what raw encoding it looks like in instructions. You can get away with single bytes to represent the type and encoding. And, that's what we use here to keep data access simple. You could squeeze everything into one or two bytes through clever bitmasking, but after doing so, I couldn't find much of a speedup. This could be situational and so you should not dismiss such a trick.

Why not store the name and alias strings? Ultrassembler does not actually reference the name nor the alias anywhere in its code. Why? Strings are very expensive. This fact is not obvious if you have not made software at the level of Ultrassembler, where string comparison and manipulation grind computation to a crawl. So we just don't use strings anywhere. In spite of this, the initializers of `const std::array<rvregister, 96> registers` do contain both the name and alias, but the constructors silently discard these data. Such inclusion enables external scripts to look at the array and generate code around it. We'll look at that in the next section. But for now, know that we hate strings.

## `rvinstruction`

`rvinstruction` follows a similar idea, with the biggest differences being that it's much bigger, 2000+ entries versus 96, and that there is more information to store per entry. This necessitates some extra memory saving magic because there are so many different instructions. We first need an ID for each instruction to do specific checks if needed. We have almost more than 2048 instructions (subject to future expansion) but less than 4196, so we'll need 2 bytes. There are fewer than 256 "types" of instructions (R, I, S, B, U, J, etc.), so 1 byte is good. Same idea with all the other fields. Similarly to `rvregister`, it would be possible to use bitmasking to compress everything, but this might not result in a significant speedup.

## `special_snowflake_args`

In RISC-V, many instructions require special attention because they have a special encoding, do something special, or are otherwise different from the rest of the herd. To avoid hardcoding behavior handling as much as possible, `special_snowflake_args` encodes specific properties that many of these special instructions share, such as getting an immediate value instead of a register, swapping the `rs1` and `rs2` registers (or `vs1` and `vs2`), or omitting a register entirely. We can encode all these properties in a binary way so we use a custom bitmask system to save all the properties in a single byte. `custom_reg_val`, however, is a separate 1-byte field because registers use 5 bits, and only exists in tandem with `has_custom_reg_val`.

All together, we are able to use only 20kB of memory to save all the instructions, not withstanding future entries. This fits nicely into many CPU data caches.

# Preallocated memory pools

In C++, by default, containers that dynamically allocate memory do so through the heap. The underlying OS provides the heap through assignment of a certain section of its virtual memory to the program requesting the heap memory. Heap allocation happens transparently most of the time. Unfortunately for us, it matters where exactly that memory is. Memory located far away from everything else (often the case with heap memory) unnecessarily clogs up the CPU's memory cache. Additionally, in C++, requesting that heap memory also requires a syscall every time the container geometrically changes size (roughly speaking, 1B -> 2B -> 4B -> 8B -> ... -> 1MB). Syscalls drastically slow down code execution (more so than yo mama is big) because the OS needs to save all the registers, swap in the kernel's, and run the kernel code, all while clogging up the CPU cache again. Therefore, we need a way to allocate memory close to our variables with zero syscalls. 

The solution? 

Preallocated memory pools.

C++ offers a totally neato way to use the containers you know and love with a custom crafted memory allocator of your choice. 

Here's how Ultrassembler does it.

```cpp
constexpr size_t memory_pool_size = 33554432;

template <class T>
class MemoryBank;

typedef std::basic_string<char, std::char_traits<char>, MemoryBank<char>> ultrastring;

template <typename T>
using ultravector = std::vector<T, MemoryBank<T>>;

class GlobalMemoryBank {
    inline static std::array<std::byte, memory_pool_size> pool;
    inline static size_t used = 0; 
    inline static long pagesize = sysconf(_SC_PAGE_SIZE); // This only happens once :)

public:
    void* grab_some_memory(size_t requested);

    void reset();
};

extern GlobalMemoryBank memory_bank;

template <class T>
class MemoryBank {
public:
    using value_type = T;

    MemoryBank() = default;

    [[nodiscard]] T* allocate(size_t requested) {
        std::size_t bytes = requested * sizeof(T);
        return reinterpret_cast<T*>(memory_bank.grab_some_memory(bytes));
    }

    void deallocate(T* ptr, size_t requested) { return; }

    bool operator==(const MemoryBank&) const { return true; }
};

// In another file...

void* GlobalMemoryBank::grab_some_memory(size_t requested) {
    if (requested + used > pool.size()) {
        throw UASError(OutOfMemory, "Out of memory!");
    }
    void* ptr = reinterpret_cast<void*>(pool.data() + used);
    used += requested;
    return ptr;
}

void GlobalMemoryBank::reset() {
    used = 0;
}
```

Let's go through this section by section.

```cpp
constexpr size_t memory_pool_size = 33554432;

template <class T>
class MemoryBank;

typedef std::basic_string<char, std::char_traits<char>, MemoryBank<char>> ultrastring;

template <typename T>
using ultravector = std::vector<T, MemoryBank<T>>;
```

This is boilerplate defining _how big our memory pool is_ (in bytes), declaring _the regular memory pool class_ (annoying!), what our _special memory pool string_ is an alias of (a standard string but with the regular memory pool allocator), and the same creation of _a vector using the regular memory pool_.

```cpp
class GlobalMemoryBank {
    inline static std::array<std::byte, memory_pool_size> pool;
    inline static size_t used = 0;
    inline static long pagesize = sysconf(_SC_PAGE_SIZE);

public:
    void* grab_some_memory(size_t requested);

    void reset();
};

extern GlobalMemoryBank memory_bank;
```

This class defines the _memory pool wrapper_ that the actual allocator uses. Why? This has to do with how C++ uses custom allocators. When you use a container with a custom allocator, each declaration of that container creates a separate instance of that container _and the allocator class_. Therefore, if you added the memory pool array as a member of this custom allocator class, each declaration of the container would result in separate instantiations of the underlying memory pool object. This is UNACCEPTABLE for Ultrassembler. Therefore, we instead use a helper class that the allocators call to. As a consequence, it allows us to add memory pool functionality controlled independently of the containers through calls to the helper `GlobalMemoryBank` class in the future.

```cpp
template <class T>
class MemoryBank {
public:
    using value_type = T;

    MemoryBank() = default;

    [[nodiscard]] T* allocate(size_t requested) {
        std::size_t bytes = requested * sizeof(T);
        return reinterpret_cast<T*>(memory_bank.grab_some_memory(bytes));
    }

    void deallocate(T* ptr, size_t requested) { return; }

    bool operator==(const MemoryBank&) const { return true; }
};
```

This is the actual _custom allocator_ object that we pass to C++ containers. The definition of a custom allocator in C++ is simply a class that provides the `allocate` and `deallocate` functions publicly. That's literally it. There are in fact more potential functions that you could add to handle specific uses, but `allocate` and `deallocate` are all we need for Ultrassembler. We define this class as a template because the return value of the `allocate` function must match the underlying type of the container using the allocator class. We furthermore define the `==` operator because C++ requires that two objects using allocators match their allocators. You'll normally never notice this because the default allocator for all C++ containers, `std::allocator`, provides all the allocator functions and operator comparison functions, and as a result, handles all comparisons transparently. Ultrassembler only uses equality. Finally, we provide a default constructor `MemoryBank() = default;` as this is what the C++ standard expects too from allocator classes.

```cpp
void* GlobalMemoryBank::grab_some_memory(size_t requested) {
    if (requested + used > pool.size()) {
        throw UASError(OutOfMemory, "Out of memory!");
    }
    void* ptr = reinterpret_cast<void*>(pool.data() + used);
    used += requested;
    return ptr;
}

void GlobalMemoryBank::reset() {
    used = 0;
}
```

These functions implement _allocating the memory_ and _resetting the memory bank_. Allocating should be obvious. However, resetting might not. As it stands, the memory pool simply gives up if it runs out of memory to allocate. We don't deallocate because such an operation would add extra overhead and subjects us to the issue of memory fragementation. Memory fragmentation is when you deallocate a small object from a large area of allocated memory, leaving a small area of unallocated memory laying in the otherwise allocated area. If you want to allocate a new object, tough luck, you probably can't fit it in this small area. You need to wait for the other objects to deallocate first. This cycle continues until your memory usage looks like Swiss cheese and doesn't support allocating any more objects, leading to a system crash. Normally, the OS kernel handles this problem transparently. Linux for example uses a "buddy allocator" to help deal with it. Memory fragmentation is also less of an issue with huge swaths of memory on modern systems. Our memory pool unfortunately lacks those luxuries of large memory and processing power for buddy allocators. Therefore, we provide the `reset` function to start everything over if the software using Ultrassembler receives an `OutOfMemory` exception.

Our memory pool trick lets Ultrassembler enjoy optimal memory locality and predefined memory usage while also completely eliminating syscalls (almost) and memory leaks, notwithstanding occasional memory bank resets.

# Value speculation

A while ago, I read [this fascinating article on something called L1 value speculation](https://mazzo.li/posts/value-speculation.html). The basic idea is to free the branch predictor by giving it extra work to do guessing the next value in the linked list. If it's right (usually it is) then you get a free speedup.

Ultrassembler does something similar. Instead of a linked list, we iterate through an array checking for specific combinations of characters that define the end of a sequence to copy. 

```cpp
auto ch = [&]() {
    return data[i];
};

volatile char preview;
while (i < data.size() && not_at_end(ch()) && !is_whitespace(ch())) {
    c.inst.push_back(ch());
    i++;
    preview = ch();
}
```

As built-in strings in C++ are super duper mega slow even with custom allocators, we spend a lot of time on `c.inst.push_back(ch());`. There's fortunately a workaround. If the CPU knows that we'll be accessing the next character in the target string, why not queue it up first? This is exactly what `volatile char preview;` and `preview = ch();` accomplish. We already have an opportunity for speculation with the `i++;` and `i < data.size();`. Although I'm not 100% sure, my hypothesis on why `preview` provides a speedup is that the branch predictor can only handle `i < data.size()` and not additionally the character loading of `ch()`. Therefore, we should preemptively load `ch()` during `c.inst.push_back(ch());`. 

Eagle eyed readers will notice how there is an opportunity for memory overflow if we are at the end of a string and `i++;` then `preview = ch();` loads a character past the string `data`. However, Ultrassembler accounts for this by preemptively adding an extra null character to the input string `data` earlier in the code, ensuring that such illegal memory accesses are impossible by definition. 

This optimization sped up parsing of the instruction names enough that the overall Ultrassembler performance increased by about 10%.

# (Super) smart searches

Here's one weird trick I haven't seen anywhere else.

Imagine I provided you these words: apple, apricot, avocado, and banana. 

Now, what if I told you a mystery word I was looking for among the ones I provided was 7 letters long. You would immediately discard "apple" and "banana" because they're not 7 letters long. Now, I tell you that it starts with "a." You wouldn't discard any at this point because both "apricot" and "avocado" start with the letter a. Finally, I tell you that the second letter is "v." Immediately we know "avocado" is the mystery word because no other word remaining starts with "av."

This is the basic idea behind the instruction, register, CSR, and pseudoinstruction lookup systems in Ultrassembler. There's a rub, though. The code for these lookups looks something like this:

```cpp
const uint16_t fast_instr_search(const ultrastring& inst) {
    const auto size = inst.size();

    if (size == 2) {
        if (inst[0] == 's') {
            if (inst[1] == 'd') return 44;
            if (inst[1] == 'w') return 17;
            if (inst[1] == 'b') return 15;
            if (inst[1] == 'h') return 16;
        }
        if (inst[0] == 'o') {
            if (inst[1] == 'r') return 35;
        }
        if (inst[0] == 'l') {
            if (inst[1] == 'd') return 43;
            if (inst[1] == 'w') return 12;
            if (inst[1] == 'b') return 10;
            if (inst[1] == 'h') return 11;
        }
    }

    if (size == 3) {
        etc...
```

Clearly, there's a lot of work to do if you've got thousands of entries like the instructions array does. There's a fix for that though! 

Enter codegen. 

Ultrassembler uses artisan-crafted Python scripts to traverse through the listings and extract the string names for each instruction, register, CSR, and pseudoinstruction. Then, these scripts generate C++ code which performs these precomputed lookups. 

Here's what the instruction search script looks like. <span class="warning">WARNING!</span> If this script looks ugly, it's because Python is one of the worst programming languages out there for anything more than mere supportive, throwaway software like this.

```python
input = "src/instructions.cpp"
output = "src/generated/instruction_search.cpp"

import re

content = ""
with open(input, "r") as file:
    content = file.read()

regex = "(?<={)\"([\w.]+)\""

instructions = re.findall(regex, content)

for i in range(len(instructions)):
    instructions[i] = (instructions[i], i, len(instructions[i]))

instructions.sort()

print(instructions)

min_len = min([i[2] for i in instructions])

max_len = max([i[2] for i in instructions])

depth = 0

current_instr = ""

code = "// SPDX-License-Identifier: MPL-2.0\n"
code += "// The generate_instruction_search.py script automatically generated this code. DO NOT MODIFY!\n"
code += "#include \"../instructions.hpp\"\n"
code += "#include \"../ultrassembler.hpp\"\n\n"
code += "namespace ultrassembler_internal {\n\n"
code += "const uint16_t fast_instr_search(const ultrastring& inst) {\n"
code += "    const auto size = inst.size();\n\n"

def ind():
    return "    " * (depth + 2)

def instr_exists(instr, length):
    for i in instructions:
        if i[0] == instr and i[2] == length:
            return True
    return False
    
def prefix_exists(prefix, length):
    for i in instructions:
        if i[0].startswith(prefix) and i[2] == length:
            return True
    return False

potentialchars = ""

for instr in instructions:
    for char in instr[0]:
        if char not in potentialchars:
            potentialchars += char

def process_depth(current_len):
    global code, current_instr, depth
    for letter in potentialchars:
        if instr_exists(current_instr + letter, current_len):
            code += ind() + f"if (inst[{depth}] == '{letter}') return {instructions[[i[0] for i in instructions].index(current_instr + letter)][1]};\n"
        elif prefix_exists(current_instr + letter, current_len):
            code += ind() + f"if (inst[{depth}] == '{letter}') {{\n"
            current_instr += letter
            depth += 1
            process_depth(current_len)
            depth -= 1
            current_instr = current_instr[:-1]
            code += ind() + "}\n"

for i in range(min_len, max_len + 1):
    code += f"    if (size == {i}) {{\n"
    process_depth(i)
    code += "    }\n\n"

code += "    return instr_search_failed;\n"
code += "}\n\n"
code += "} // namespace ultrassembler_internal"

print(code)

with open(output, "w") as file:
    file.write(code)
```

Let's go through it section by section.

```python
input = "src/instructions.cpp"
output = "src/generated/instruction_search.cpp"

import re

content = ""
with open(input, "r") as file:
    content = file.read()
```

This simply tells the script what file to read and where to generate the code, imports the regex package, and reads the input file.

```python
regex = "(?<={)\"([\w.]+)\""

instructions = re.findall(regex, content)

for i in range(len(instructions)):
    instructions[i] = (instructions[i], i, len(instructions[i]))

instructions.sort()

print(instructions)
```

This regex searches for all instances of quotes in the instruction C++ code. That code looks like this:

```cpp
const std::array<rvinstruction, 2034> instructions = {
        {{"lui", LUI, U, op_LUI, 0b000, RVI, int_reg},
         {"auipc", AUIPC, U, op_AUIPC, 0b000, RVI, int_reg},
         {"jal", JAL, J, op_JAL, 0b000, RVI, int_reg}, etc...
```

Then, it creates a new array with the instruction name, what position it is in the array, and its length. This might seem redundant at first, but it's helpful later. We then sort all the insructions alphabetically (also important!) and show all of them for debugging/status purposes.

```python
min_len = min([i[2] for i in instructions])

max_len = max([i[2] for i in instructions])

depth = 0

current_instr = ""

code = "// SPDX-License-Identifier: MPL-2.0\n"
code += "// The generate_instruction_search.py script automatically generated this code. DO NOT MODIFY!\n"
code += "#include \"../instructions.hpp\"\n"
code += "#include \"../ultrassembler.hpp\"\n\n"
code += "namespace ultrassembler_internal {\n\n"
code += "const uint16_t fast_instr_search(const ultrastring& inst) {\n"
code += "    const auto size = inst.size();\n\n"

def ind():
    return "    " * (depth + 2)

def instr_exists(instr, length):
    for i in instructions:
        if i[0] == instr and i[2] == length:
            return True
    return False
    
def prefix_exists(prefix, length):
    for i in instructions:
        if i[0].startswith(prefix) and i[2] == length:
            return True
    return False

potentialchars = ""

for instr in instructions:
    for char in instr[0]:
        if char not in potentialchars:
            potentialchars += char
```

This is a lot of boilerplate for the algorithm later to come. We find the shortest and longest instructions. We add the first parts of the generated file. We define an indentation helper for nice formatting. We define additional helper functions to check if a whole instruction exists with a given name and length or if there is an instruction with the provided prefix and length. Finally, we assemble an array with all the characters to search for that the instructions use to avoid unnecessary computation later.

```python
def process_depth(current_len):
    global code, current_instr, depth
    for letter in potentialchars:
        if instr_exists(current_instr + letter, current_len):
            code += ind() + f"if (inst[{depth}] == '{letter}') return {instructions[[i[0] for i in instructions].index(current_instr + letter)][1]};\n"
        elif prefix_exists(current_instr + letter, current_len):
            code += ind() + f"if (inst[{depth}] == '{letter}') {{\n"
            current_instr += letter
            depth += 1
            process_depth(current_len)
            depth -= 1
            current_instr = current_instr[:-1]
            code += ind() + "}\n"

for i in range(min_len, max_len + 1):
    code += f"    if (size == {i}) {{\n"
    process_depth(i)
    code += "    }\n\n"
```

Here's where the magic happens. We process one instruction length depth at a time. Like the algorithm we talked about at the beginning of this section, we start with the shortest possible "words" and work our way to the longest. Each depth step works through a search of all the possible characters and first checks if we have already found an instruction. If there is such an instruction, we add it to the code. Alternatively, if there is no such instruction but there is in fact an instruction that starts with the current sequence, we go down a depth level because we know that eventually, we will find an instruction with an exact match. Once we've gone through all of the possible instructions and depths, we exit the `for` loop.

```python
code += "    return instr_search_failed;\n"
code += "}\n\n"
code += "} // namespace ultrassembler_internal"

print(code)

with open(output, "w") as file:
    file.write(code)
```

This completes the generated search function, shows it all for debugging/status purposes, and finally writes the generated code to the output file path.

There are no other instances of this kind of codegen that I know of. That's surprising, because codegen allows us to perform lookup of thousands of instructions with near-zero overhead. I estimate each instruction lookup takes on the order of 10 instructions to complete.

Here's what the resulting compiled assembly looks like on my x86 PC:

```
0000000000029340 <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE>:
   29340:	f3 0f 1e fa          	endbr64 
   29344:	48 8b 47 08          	mov    0x8(%rdi),%rax
   29348:	48 83 f8 02          	cmp    $0x2,%rax
   2934c:	0f 84 c6 00 00 00    	je     29418 <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE+0xd8>
   29352:	48 83 f8 03          	cmp    $0x3,%rax
   29356:	75 28                	jne    29380 <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE+0x40>
   29358:	48 8b 17             	mov    (%rdi),%rdx
   2935b:	0f b6 0a             	movzbl (%rdx),%ecx
   2935e:	80 f9 61             	cmp    $0x61,%cl
   29361:	0f 84 79 2b 00 00    	je     2bee0 <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE+0x2ba0>
   29367:	80 f9 64             	cmp    $0x64,%cl
   2936a:	0f 85 58 10 00 00    	jne    2a3c8 <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE+0x1088>
   29370:	80 7a 01 69          	cmpb   $0x69,0x1(%rdx)
   29374:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
   29379:	0f 84 09 2f 00 00    	je     2c288 <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE+0x2f48>
   2937f:	c3                   	ret
   # There are thousands more lines of this!
```

And RISC-V:

```
000000000007c33c <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE>:
   7c33c:	7179                	addi	sp,sp,-48
   7c33e:	f406                	sd	ra,40(sp)
   7c340:	e42a                	sd	a0,8(sp)
   7c342:	6522                	ld	a0,8(sp)
   7c344:	00089317          	auipc	t1,0x89
   7c348:	afc33303          	ld	t1,-1284(t1) # 104e40 <_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcEN22ultrassembler_internal10MemoryBankIcEEE4sizeEv@@Base+0xad9c4>
   7c34c:	9302                	jalr	t1
   7c34e:	ec2a                	sd	a0,24(sp)
   7c350:	6762                	ld	a4,24(sp)
   7c352:	4789                	li	a5,2
   7c354:	22f71c63          	bne	a4,a5,7c58c <_ZN22ultrassembler_internal17fast_instr_searchERKNSt7__cxx1112basic_stringIcSt11char_traitsIcENS_10MemoryBankIcEEEE+0x250>
   7c358:	4581                	li	a1,0
   7c35a:	6522                	ld	a0,8(sp)
   7c35c:	00089317          	auipc	t1,0x89
   7c360:	c6433303          	ld	t1,-924(t1) # 104fc0 <_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcEN22ultrassembler_internal10MemoryBankIcEEEixEm@@Base+0xaaef8>
   7c364:	9302                	jalr	t1
   # Also thousands more lines of this!
```

# Compile-time templates

This is similar to script codegen but with native C++ only.

One of the verification steps in Ultrassembler involves checking that the immediate value of an instruction (for example, `addi t0, t1, 100`) fits within some known range. C++ allows us to both cleanly invoke this check for an arbitrary range and do so with little to no runtime overhead to calculate that range.

Here's how it works.

```cpp
template <auto bits>
void verify_imm(const auto& imm) {
    using T = decltype(bits);
    if constexpr (std::is_signed_v<T>) {
        if (imm < -(1 << (bits - 1)) || imm >= (1 << (bits - 1))) {
            throw UASError(ImmOutOfRange, "Immediate " + to_ultrastring(imm) + " is out of range [" + to_ultrastring(-(1 << (bits - 1))) + ", " + to_ultrastring((1 << (bits - 1))) + ")", 0, 0);
        }
    } else if constexpr (std::is_unsigned_v<T>) {
        if (imm < 0 || imm >= (1u << bits)) {
            throw UASError(ImmOutOfRange, "Immediate " + to_ultrastring(imm) + " is out of range [0, " + to_ultrastring((1u << bits)) + ")", 0, 0);
        }
    }
}
```

Each invocation looks something like `verify_imm<5u>(imm)`. We supply a numeric literal and the immediate variable to check. C++'s template facilities then check whether we've supplied a signed or unsigned numeric literal, as RISC-V instruction can vary whether they expect signed or unsigned numbers only. We then calculate the lowest possible number (`-(1 << (bits - 1))` for signed and `0` for unsigned) and the highest possible number (`(1 << (bits - 1))` for signed and `(1u << bits)` for unsigned) and check the input against that. We then throw an error if it doesn't fit these calculated constraints or return silently if it does.

The `if constexpr` tells the compiler to generate each signed or unsigned execution path at compile time depending on what numeric literal we've provided, allowing us to make each function call as pretty and fast as possible.

# Fast string comparisons

For the times where we can't or don't want to use a precomputed string search, Ultrassembler uses an optimized string comparison function to minimize overhead.

```cpp
bool fast_eq(const auto& first, const std::string_view& second) {
    if (first.size() != second.size()) { 
        return false;
    }
    for (size_t i = 0; i < first.size(); i++) {
        if (first[i] != second[i]) {
            [[likely]] return false;
        } else {
            [[unlikely]] continue;
        }
    }
    return true;
}
```

How does this work? First, we check to make sure the input strings are the same length. It's impossible by definition for them to be the same if they have different lengths. Then, we compare them character by character. Here, we use C++20's `[[likely]]` and `[[unlikely]]` tags to help the compiler optimize the positioning of each comparison. It's statistically more likely to have a comparison failure than a success because we are usually comparing one input string against many possible options but it can only match with up to one.

# Reference bigger-than-fundamental objects in function arguments

This one surprised me.

When you call a C++ function, you can choose to pass your arguments _by value_, or _by reference_. By default, C++ uses _by value_, which means the code internally makes a copy of the argument and provides that copy to the function. If you add a `&` to make it a reference instead (there are other ways to do this too) then the code generates a pointer to that original object and passes that pointer to the function. However, unlike pointers, references handle referencing and dereferencing transparently. As an aside, this also means Ultrassembler technically doesn't use pointers... anywhere! Pointers are horrible.

One of the most common pieces of C++ optimization advice is to use references whenever possible to avoid the copy overhead incurred by value references. It might surprise you, then, to find out that the following code is vastly faster due to the use of a value argument:

```cpp
size_t parse_this_line(size_t i, const ultrastring& data, assembly_context& c) {
    // code that does "i++;" a lot
}

// later, in a different function:
for (size_t i = 0; i < data.size();) {
    i = parse_this_line(i, data, c);
    // etc...
}
```

If we had applied the Programming Furus©️®️™️'s advice to pass `i` by reference, it would have looked like:

```cpp
void parse_this_line(size_t& i, const ultrastring& data, assembly_context& c) {
    // code that does "i++;" a lot
}

// later, in a different function:
for (size_t i = 0; i < data.size();) {
    parse_this_line(i, data, c);
    // etc...
}
```

So why is the first one faster? Here's why.

Under the hood of all programming languages, you have assembly code which translates to the CPU's machine code. There are also no variables. Instead, you've got registers which hold raw data and raw memory. In most application processors today, the registers are 64 bits wide, and maybe wider for special vector operations which don't matter here. 64 bits happens to match the maximum width of so-called _fundamental types_ in C and C++ which are integers and most common floats. Therefore, we can fit at least one fundamental type into each register.

Quick refresher of the registers in RISC-V:

![Infographic of the integer RISC-V registers](/RISC-V-registers-safe.svg)

Assembly also has little concept of a function call. Internally, all function calls do is clear out the current registers, load them with the function parameters, then jump to the function's address. This means all function calls involve at least one copy per argument, whether it's a fundamental type or a pointer to a fundamental type or a pointer to something else.

```
# Here's what this looks like in RISC-V assembly.
# Say we have a number in register t0, like 69.

addi t0, x0, 69

# We also have a function foobar that takes a single integer argument (like "void foobar(size_t arg)" in C/C++)
# We can copy that register (and therefore its value) to argument register a0 before calling foobar

addi a0, t0, 0

jal foobar

# The copying of this value only took one step!
```

You can see where we're going. If our goal is to minimize copying, it would be better to copy a fundamental type once than to generate a pointer, copy that, then dereference that pointer to get the underlying value. That is the crux of this subtle optimization trick. The cost to copy one register is less than the cost to copy a register holding a pointer. 

Note how I've only talked about fundamental types. Any type which does not fit in a single register, AKA many structs, containers, or anything else that isn't a fundamental type, costs more to copy by value in multiple registers than it does to copy a single register holding a pointer. I don't know of any Programming Furu©️®️™️ that makes this distinction clear.

# Don't do insertions or deletions

One of the steps to assemble a jump operation in RISC-V assembly is to calculate the offset of bytes to the jump target. However, this is often impossible unless all other instructions are already assembled. Ultrassembler does its best to avoid insertions or deletions through a clever trick to assemble jump instructions with a placeholder jump offset and then insert the correct offset in-place at the end.

Here's how it works:

```cpp
void solve_label_offsets(assembly_context& c) {
    using enum RVInstructionFormat;
    for (size_t i = 0; i < c.label_locs.size(); i++) {
        if (!c.label_locs.at(i).is_dest) {
            for (size_t j = 0; j < c.label_locs.size(); j++) {
                if (c.label_locs.at(j).is_dest && c.label_locs.at(j).id == c.label_locs.at(i).id) {
                    uint32_t inst = 0;

                    if (c.label_locs.at(i).i_bytes == 2) {
                        inst = reinterpret_cast<uint16_t&>(c.machine_code.at(c.label_locs.at(i).loc));
                    } else if (c.label_locs.at(i).i_bytes == 4) {
                        inst = reinterpret_cast<uint32_t&>(c.machine_code.at(c.label_locs.at(i).loc));
                    }

                    int32_t offset = c.label_locs.at(j).loc - c.label_locs.at(i).loc;

                    if (c.label_locs.at(i).format == Branch) {
                        inst &= 0b00000001111111111111000001111111;
                        inst |= ((offset >> 11) & 0b1) << 7;      // Add imm[11]
                        inst |= ((offset >> 1) & 0b1111) << 8;    // Add imm[4:1]
                        inst |= ((offset >> 5) & 0b111111) << 25; // Add imm[10:5]
                        inst |= ((offset >> 12) & 0b1) << 31;     // Add imm[12]
                    } else if (c.label_locs.at(i).format == J) {
                        inst &= 0b00000000000000000000111111111111;
                        inst |= ((offset >> 12) & 0b11111111) << 12;  // Add imm[19:12]
                        inst |= ((offset >> 11) & 0b1) << 20;         // Add imm[11]
                        inst |= ((offset >> 1) & 0b1111111111) << 21; // Add imm[10:1]
                        inst |= ((offset >> 20) & 0b1) << 31;         // Add imm[20]
                    } else if (c.label_locs.at(i).format == CJ) {
                        inst &= 0b1110000000000011;
                        inst |= ((offset >> 5) & 0b1) << 2;   // Add offset[5]
                        inst |= ((offset >> 1) & 0b111) << 3; // Add offset[3:1]
                        inst |= ((offset >> 7) & 0b1) << 6;   // Add offset[7]
                        inst |= ((offset >> 6) & 0b1) << 7;   // Add offset[6]
                        inst |= ((offset >> 10) & 0b1) << 8;  // Add offset[10]
                        inst |= ((offset >> 8) & 0b11) << 9;  // Add offset[9:8]
                        inst |= ((offset >> 4) & 0b1) << 11;  // Add offset[4]
                        inst |= ((offset >> 11) & 0b1) << 12; // Add offset[11]
                    } else if (c.label_locs.at(i).format == CB) {
                        inst &= 0b1110001110000011;
                        inst |= ((offset >> 5) & 0b1) << 2;   // Add offset[5]
                        inst |= ((offset >> 1) & 0b11) << 3;  // Add offset[2:1]
                        inst |= ((offset >> 6) & 0b11) << 5;  // Add offset[7:6]
                        inst |= ((offset >> 3) & 0b11) << 10; // Add offset[4:3]
                        inst |= ((offset >> 8) & 0b1) << 12;  // Add offset[8]
                    }

                    if (c.label_locs.at(i).i_bytes == 2) {
                        reinterpret_cast<uint16_t&>(c.machine_code.data()[c.label_locs.at(i).loc]) = inst;
                    } else if (c.label_locs.at(i).i_bytes == 4) {
                        reinterpret_cast<uint32_t&>(c.machine_code.data()[c.label_locs.at(i).loc]) = inst;
                    }
                }
            }
        }
    }
}
```

When we find a jump instruction that needs later TLC, we save its location and some other attributes to a special array. Then, after the rest of the code is done assembling, we go back through each jump instruction and calculate the correct offset and insert that offset in-place in the correct instruction format.

I believe this is faster than what some other assemblers do for instructions which jump to a location reachable within the constraints of the offset's size. However, it's not useful for far jumps, which require a separate helper instruction to extend the jump. Ultrassembler doesn't support those yet.

# More optimizations

Here's a few more optimization tricks that aren't quite significant enough for their own sections but deserve a mention anyway.

## Memory padding

There are a few strings which Ultrassembler frequently reads and writes. To insure against runtime memory pool allocation overhead, we preemptively allocate a good amount of memory.

```cpp
c.inst.reserve(32);
c.arg1.reserve(32);
c.arg2.reserve(32);
c.arg3.reserve(32);
c.arg4.reserve(32);
c.arg5.reserve(32);
c.arg6.reserve(32);
c.arg_extra.reserve(32);
c.machine_code.reserve(128000);
```

I found that 32 bytes gave the biggest speedup for small strings, and sizes above a few kB are more appropriate for the machine code output.

## Inline some functions

Sometimes, functions are faster when you mark them `inline` to suggest that the code have a copy for each invocation. This tends to work better for smaller functions.

```cpp
inline const uint8_t decode_encoding_length(const uint8_t opcode) {
    if ((opcode & 0b11) != 0b11) {
        return 2;
    } else {
        return 4;
    }
}
```

Try it and see what works best for your own code.

## Minimize string stripping copies

Here's a special case of minimizing string copying. This function removes the parentheses and optionally the number 0 from a string like "0(t4)":

```cpp
void remove_extraneous_parentheses(ultrastring& str) {
    if (str.back() == ')') {
        str.pop_back();
    }
    if (str.front() == '0') {
        str.erase(0, 1);
    }
    if (str.front() == '(') {
        str.erase(0, 1);
    }
}
```

Why do we tackle the last character first? When you erase one or more characters from a string, C++ internally copies every individual character after setting the characters to erase to blank. In other words, it looks a little like this:

```
# Erase "foo" from "foobar"

foobar

 oobar

  obar

   bar

b  bar

ba bar

barbar

barba

barb

bar
```

That's a lot of copies. So it would be great if we can avoid copying more of these characters in the future. Then, we handle the case where the input string is like "(t4)" where there is no 0 at the beginning. Finally is the removal of the front parenthesis. 

This optimization yielded a surprising speedup (several percent overall) due to how often the case of "0(reg)" shows up in RISC-V assembly.

## Call small lambda functions frequently

These three lambda functions both help make parsing faster and simplify the code:

```cpp
auto is_whitespace = [](const char& c) {
    return c == '\t' || c == ' ';
};
auto ch = [&]() {
    return data[i];
};
auto not_at_end = [](const char& c) {
    return c != '\n' && c != '#';
};
```

Why do they work? The simplification part is obvious, but maybe not for speed. One reason might be because the compiler now knows how often we do the same comparisons over and over. If it knows we do the same thing many times, it can optimize with that known fact.

Also note how the first and last functions violate the earlier optimization trick regarding passing fundamental types by value. That trick does not entirely apply to lambda functions, which work differently, where they could be inline and incur zero function call overhead. Passing by reference enables the zero function call overhead optimization.

## Strip out the compilation junk

By default, C++ compilers like GCC and Clang add in a lot of junk that we can safely strip out. Here's how we do it in CMake:

```cmake
target_compile_options(objultra PRIVATE -fno-rtti -fno-stack-protector -fomit-frame-pointer)
```

### -fno-rtti

RTTI is runtime type identification. Only some software uses this feature but it adds nonzero overhead to all. Therefore, we disable it to eliminate that overhead.

### -fno-stack-protector

The stack protector is a feature that many Programming Furus©️®️™️ peddle to improve security. However, it adds considerable overhead, and does nothing for security outside of a specific attack. Therefore, we disable it to eliminate that overhead.

### -fomit-frame-pointer

The frame pointer is a specific feature on some CPU platforms (like x86). However, it's not actually needed anymore for modern CPUs, and it adds overhead. Therefore, we disable it to eliminate that overhead.

## Link-time optimization

Link-time optimization, or LTO, is a more intelligent way for the compiler to optimize your code than regular optimization passes. It can enable some serious speedups if your code benefits from function inlining or has code across many files. It's been supported for a while now but isn't enabled by default. Here's how to enable it in CMake:

```cmake
include(CheckIPOSupported)
check_ipo_supported(RESULT lto_supported)
if(lto_supported AND NOT NO_LTO)
  set_property(TARGET ${this_target} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  if(CMAKE_COMPILER_IS_GNUCXX)
    list(APPEND CMAKE_CXX_COMPILE_OPTIONS_IPO "-flto=auto") # set the thread amount to what is available on the CPU
  endif()
endif()
```

This has been nothing but a benefit for Ultrassembler.

## Make structs memory-friendly

This struct holds variables that most of the Ultrassembler code uses:

```cpp
struct assembly_context {
    ultrastring inst;
    ultrastring arg1;
    ultrastring arg2;
    ultrastring arg3;
    ultrastring arg4;
    ultrastring arg5;
    ultrastring arg6;
    ultrastring arg_extra;
    ultravector<uint8_t> machine_code;
    ultravector<RVInstructionSet> supported_sets;
    ultravector<std::pair<ultrastring, int>> labels;
    ultravector<label_loc> label_locs;
    ultravector<std::pair<ultrastring, ultrastring>> constants;
    ultravector<directive_options> options;
    int32_t custom_inst = 0;
    uint32_t line = 1;
    uint32_t column = 0;
    uint16_t inst_offset = 0;
};
```

We order them in descending memory size, from 32 bytes for `ultrastring` to 2 for `uint16_t`. This packs the members the most efficient way possible for memory usage.

Also, these variables are not in the global scope or a namespace because holding them all in a struct enables multithreaded operation. It would be possible to add `thread_local` to each one to enable multithreading easily, but in testing, this added enormous overhead compared to a plain old struct.

## Memory locality

Memory locality is the general idea that the most frequently accessed memory should be close together. Ultrassembler has many such cases, and we already help ensure memory locality through preallocated memory pools. We go further by ensuring sections of code which frequently work on one area of memory get their own space to work with.

Here's an example:

```cpp
void make_inst(assembly_context& c) {
    // boilerplate

    uint32_t inst = 0;

    // code which modifies this inst variable

    reinterpret_cast<uint32_t&>(c.machine_code[c.machine_code.size() - bytes]) = inst;
}
```

We work on the local `inst` variable to prevent far reaches across memory to the `c.machine_code` vector. When we're done, we write to `c.machine_code` once and invoke only one far memory access as a result.

# Conclusion

Congrats if you read all the way here!

Hopefully you've learned something new and/or useful. Although I've crafted the optimizations here for Ultrassembler, there's nothing stopping you from applying the same underlying principles to your own code. 

Check out Ultrassembler: [https://github.com/Slackadays/Chata/tree/main/ultrassembler](https://github.com/Slackadays/Chata/tree/main/ultrassembler)