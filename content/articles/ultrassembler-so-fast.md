+++
title = "How is Ultrassembler so fast?"
date = 2025-08-15
+++

[Ultrassembler](https://github.com/Slackadays/Chata/tree/main/ultrassembler) is a superfast and complete RISC-V assembler library that I'm writing as a component of the bigger [Chata signal processing](https://github.com/Slackadays/Chata) project. 

"Why would you want to do this?" you might ask. First, existing RISC-V assemblers that conform the the entirety of the specification, `as` and `llvm-mc`, ship as binaries that you run as standalone programs. This is normally not an issue. However, in Chata's case, it needs to access a RISC-V assembler from within its C++ code. The usual way to accomplish this task is to use some ugly C function like `system()` to run external software as if it were a human or script running it from a command line. 

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

It gets even uglier once you realize you need temporary files and possibly have to artisanally craft the command beforehand. Additionally, invoking the assembler in this manner incurs a significant performance overhead on embedded systems which lack processing power. There has GOT to be a better way. Enter Ultrassembler.

With these two goals of speed and quality in mind, I wrote Ultrassembler as a completely standalone library with GNU `as` as the performance and standard conformity benchmark. The results are nothing short of staggering. After months of peformance optimization, Ultrassembler can assemble a test file with about 16 thousand RISC-V instructions over 10 times faster than `as`, and around 20 times faster than `llvm-mc`. 

Such performance ensures a good user experience on the platforms where Chata runs, but also as a consequence of this lack of overhead, you could also combine Ultrassembler with fantastic libraries like [libriscv](https://github.com/libriscv/libriscv) to implement low-to-no-cost RISC-V scripting in things like games, or maybe even in your JIT programming language!

So let's look at how exactly I made it this fast so you can reap the benefits too.

<span class="warning">WARNING!</span> &nbsp; The code you're about to see here is only current as of this article's publishing. The actual code Ultrassembler uses could be different by the time you read this in the future!

# Exceptions

Exceptions, C++'s first way of handling errors, are slow. Super duper slow. So slow, in fact, that many Programming Furus©️®️™️ say you should never ever use them. They'll infect your code with their slowness and transform you into a slow old hunchback in no time. 

Or so you would think.

C++ exceptions, despite being so derided, are in fact zero-overhead. Huh? Didn't I just say they were super duper slow? Let me explain.

It's not clear when exactly exceptions are slow. I had to do some research here. As it turns out, GCC's `libstdc++` uses a "zero-overhead" exception system, meaning that in the ideal normal case where C++ code calls zero exceptions, there is zero performance penalty. But when it does call an exception, it could be very slow depending on how the code is laid out. Most programmers, not knowing this, frequently use exceptions in their normal cases, and as a result, their programs are slow. Such mysterious behavior caught the attention of Programming Furus©️®️™️ and has made exceptions appear somewhat of a curse.

This tragic curse turns out to be a heavenly blessing for Ultrassembler. In the normal case, all instructions are properly used and there's no issue. But if there's some error somewhere, say somebody put in the wrong register, then Ultrassembler sounds the alarm. Since such mistakes only occur as a result of human error (ex bugs in codegen and Ultrassembler itself) the timeframe to report the error can expand to that of a human. As a result, even if an exception triggered by a mistake took a full 1 second (around a million times slower than it does in reality), it doesn't matter because the person percepting the error message can only do so in approximately that second timeframe.

"But hold on!" you exclaim. "What about std::expected?" In response to some programs which frequently need to handle errors not seen by humans, C++ added a system to reduce the overhead of calling errors, `std::expected`. I tried this in Ultrassembler and the results weren't pretty. It trades off exception speed for normal case speed. Since the normal case is the norm in Ultrassembler, `std::expected` incurred at least a 10% performance loss due to the way the `std::expected` object wraps two values (the payload and the error code) together. [See this C++ standard document for the juicy details.](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p2544r0.html)

The end result of the use of exceptions is that there is zero performance penalty to optimize out.

# Data structures

Between all of the RISC-V instruction set extensions, there are 2000+ individual "instructions" (many instructions are identical to one another with a slight numerical change). There are also hundreds of CSRs and just under a hundred registers. This requires data structures large enough to store the properties of thousands of entries. How do you do that? It's tricky. So, how about I just show you what Ultrassembler uses as of this writing:

```cpp
struct rvregister {
    RegisterType type; //1b
    RegisterID id; //1b
    uint8_t encoding;
    uint8_t padding;
};

const std::array<rvregister, 96> registers;

struct rvinstruction {
    RVInstructionID id; //2b
    RVInstructionFormat type; //1b
    uint8_t opcode;
    uint16_t funct;
    RVInSetMinReqs setreqs; //1b
    rreq regreqs = reg_reqs::any_regs; //1b
    special_snowflake_args ssargs = special_snowflake_args(); //2b
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
    ssflag flags; //1b
};

const std::array<rvinstruction, 2034> instructions;
```

Let's go over what each `struct` does.

## `rvregister`

`rvregister` is how Ultrassembler stores the data for all the RISC-V registers. What describes a register? You have its friendly name (like x0 or v20), an alias (like zero or fa1), what kind of register it is (integer, float, or vector?), and what raw encoding it looks like in instructions. You can get away with single bytes to represent the type and encoding. And, that's what we use here to keep data access simple. You could squeeze everything into one or two bytes, but after doing so, I couldn't find much of a speedup.

So why not store the name and alias? Ultrassembler does not actually reference the name nor the alias anywhere in its code. Why? Strings are very expensive. This fact is not obvious if you have not made software at the level of Ultrassembler, where string comparisons grind computation to a crawl. So we just don't use strings anywhere. In spite of this, the initializers of `const std::array<rvregister, 96> registers` do contain both the name and alias. Such inclusion enables external scripts to look at the array and generate code around it, which will be in the next section. But for now, know that we hate strings.

## `rvinstruction`

`rvinstruction` follows a similar idea, with the biggest differences being that it's much bigger, 2000+ entries versus 96, and there is more information to store per entry. This necessitates some extra memory saving magic because there are so many different instructions. We first need an ID for each instruction to do specific checks if needed. We have almost more than 2048 instructions (subject to future expansion) but less than 4196, so we'll need 2 bytes. There are fewer than 256 "types" of instructions (R, I, S, B, U, J, etc), so 1 byte is good. Same idea with all the other 

# Memory pools

In C++, by default, containers that dynamically allocate memory do so through the heap. The underlying OS provides the heap through assignment of a certain section of its virtual memory to the program requesting the heap memory. Heap allocation happens transparently most of the time. Unfortunately for us, it matters where exactly that memory is. Memory located far away from everything else (often the case with heap memory) unnecessarily clogs up the CPU's memory cache. Additionally, in C++, requesting that heap memory also requires a syscall every time the container geometrically changes size (roughly speaking, 1B -> 2B -> 4B -> 8B -> ... -> 1MB). Syscalls drastically slow down code execution because the OS needs to save all the registers, swap in the kernel's, and run the kernel code, all while clogging up the CPU cache again. Therefore, we need a way to allocate memory close to our variables with zero syscalls. 

The solution? Memory pools.

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
    inline static long pagesize = sysconf(_SC_PAGE_SIZE);

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
    // DBG(std::cout << "Allocating " << requested << " bytes, " << used << " used" << std::endl;)
    if (requested + used > pool.size()) {
        throw UASError(OutOfMemory, "Out of memory!");
    }
    void* ptr = reinterpret_cast<void*>(pool.data() + used);
    used += requested;
    return ptr;
}

void GlobalMemoryBank::reset() {
    DBG(std::cout << "Resetting memory bank, used " << used << " bytes" << std::endl;)
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
    // DBG(std::cout << "Allocating " << requested << " bytes, " << used << " used" << std::endl;)
    if (requested + used > pool.size()) {
        throw UASError(OutOfMemory, "Out of memory!");
    }
    void* ptr = reinterpret_cast<void*>(pool.data() + used);
    used += requested;
    return ptr;
}

void GlobalMemoryBank::reset() {
    DBG(std::cout << "Resetting memory bank, used " << used << " bytes" << std::endl;)
    used = 0;
}
```

These functions implement _allocating the memory_ and _resetting the memory bank_. Allocating should be obvious. However, resetting might not. As it stands, the memory pool simply gives up if it runs out of memory to allocate. We don't deallocate because such an operation would add extra overhead and subjects us to the issue of memory fragementation. Memory fragmentation is when you deallocate a small object from a large area of allocated memory, leaving a small area of unallocated memory laying in the otherwise allocated area. If you want to allocate a new object, tough luck, you probably can't fit it in this small area. You need to wait for the other objects to deallocate first. This cycle continues until your memory usage looks like Swiss cheese and doesn't support allocating any more objects, leading to a system crash. Normally, the OS kernel handles this problem transparently. Linux for example uses a "buddy allocator" to help deal with it. Memory fragmentation is also less of an issue with huge swaths of memory on modern systems. Our memory pool unfortunately lacks those luxuries of large memory and processing power for buddy allocators. Therefore, we provide the `reset` function to start everything over if the software using Ultrassembler receives an `OutOfMemory` exception.

Our memory pool trick lets Ultrassembler enjoy optimal memory locality and predefined memory usage while also completely eliminating syscalls and memory leaks, notwithstanding occasional memory bank resets.

# Value speculation

A while ago, I read [this article on something called L1 value speculation](https://mazzo.li/posts/value-speculation.html). The basic idea is to free the branch predictor by giving it extra work to do guessing the next value in the linked list. If it's right (usually it is) then you get a free speedup.

Ultrassembler does something similar. Instead of a linked list, we iterate through an array checking for specific combinations of characters that define the end of a sequence to copy. 

```cpp
auto ch = [&]() {
    DBG(return data.at(i);)
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

Eagle eyed readers will notice how there is an opportunity for memory overflow if we are at the end of a string and `i++;` then `preview = ch();` loads a character past the string `data`. However, Ultrassembler accounts for this by adding an extra null character to the input string `data` earlier in the code, so it's impossible to perform an illegal memory access. 

This optimization sped up parsing of the instruction names enough that the overall performance increased by about 10%.

# (Super) smart searches

Here's a trick I haven't seen anywhere else.

Imagine I provided you these words: apple, apricot, avocado, and banana. Now, what if I told you a mystery word I was looking for among the ones I provided was 7 letters long. You would immediately discard "apple" and "banana" because they're not 7 letters long. Now, I tell you that it starts with "a." You wouldn't discard any at this point because both "apricot" and "avocado" start with the letter a. Finally, I tell you that the second letter is "v." Immediately we know "avocado" is the mystery word because no other word remaining starts with "av."

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

Ultrassembler uses Python scripts to go through the listings and extract the string names for each instruction, register, CSR, and pseudoinstruction. Then, they generate C++ code which performs these precomputed lookups. 

There are no other instances of this that I know of. That's surprising, because codegen allows us to perform lookup of thousands of instructions with near-zero overhead. I estimate each instruction lookup takes on the order of 10 instructions to complete.

# Fast string comparisons

For the times where we can't or don't want to use a precomputed string search, Ultrassembler uses an optimized string comparison function to minimize overhead.

```cpp
bool fast_eq(const auto& first, const std::string_view& second) {
    // First make sure the sizes are equal because no two strings 
    // can ever be the same if they have different sizes. 
    // Also, this lets us save on future bound checks because we're already checking it here.
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

When you call a C++ function, you can choose to pass your arguments _by value_, or _by reference_. By default, C++ uses _by value_, which means the code internally makes a copy of the argument and provides that copy to the function. If you add a `&` to make it a reference instead (there are other ways to do this too) then the code generates a pointer to that original object and passes that pointer to the function. However, unlike pointers, references handle referencing and dereferencing transparently. As an aside, this also means Ultrassembler technically doesn't use pointers... anywhere!

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

# More optimizations

Here's a few more that aren't quite significant enough for their own sections but deserve a mention.

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

That's a lot of copies. So it would be great if we can avoid copying more of these characters in the future.

Then, we handle the case where the input string is like "(t4)" where there is no 0 at the beginning. Finally is the removal of the front parenthesis. 

## Call small lambda functions frequently

These three lambda functions both help make parsing faster and simplify the code:

```cpp
auto is_whitespace = [](const char& c) {
    return c == '\t' || c == ' ';
};
auto ch = [&]() {
    DBG(return data.at(i);)
    return data[i];
};
auto not_at_end = [](const char& c) {
    return c != '\n' && c != '#';
};
```

Why do they work? The simplification part is obvious, but maybe not for speed. One reason might be because the compiler now knows how often we do the same comparisons over and over. If it knows we do the same thing many times, it can optimize with that known fact.

Also note how the first and last functions violate the earlier optimization trick regarding passing fundamental types by value. That trick does not apply to lambda functions, where they could be inline and incur zero function call overhead. Passing by reference enables the zero function call overhead optimization.

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

The frame pointer is a specific feature on some CPU platforms. However, it's not actually needed anymore for modern CPUs, and it adds overhead. Therefore, we disable it to eliminate that overhead.

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