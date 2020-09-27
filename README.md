<!-- omit in toc -->
# x9incexc_language-selection

<!-- omit in toc -->
## Table of contents

- [Introduction](#introduction)
- [The repos](#the-repos)
- [Languages, pros & cons](#languages-pros--cons)
	- [Bash](#bash)
	- [C# (dotnet core)](#c-dotnet-core)
	- [C++ 17](#c-17)
	- [Go](#go)
	- [Python](#python)
	- [Rust](#rust)

## Introduction

The goal with these four related repositories, is to use a relatively simple project objective (produce a list of filtered files for consumption by programs that provide something like a `--files-from` command-line option), as a testbed to determine which programming language is most suitable for a broader family of more complex and related future products. Not all (or possibly any) projects are or possibly ever will be feature complete, though some more so than others. (Which is not the goal.) If any do make it to feature complete, they'll be migrated out of [x9-testlab](https://github.com/x9-testlab) and into [Jim Collier](https://github.com/jim-collier)'s main profile.

## The repos

| Language | Repo |
|:---|:---|
| Bash | [x9incexc-bash](https://github.com/x9-testlab/x9incexc-bash) |
| C# (dotnet core) | [x9incexc-cs](https://github.com/x9-testlab/x9incexc-cs) |
| C++ 17 | [x9incexc-cpp](https://github.com/x9-testlab/x9incexc-cpp) |
| Go | [x9incexc-go](https://github.com/x9-testlab/x9incexc-go) |

## Languages, pros & cons

### Bash

- Repo: [x9incexc-bash](https://github.com/x9-testlab/x9incexc-bash)
- Overall best suited for:
	- Task automation
	- Small but serious system tools that can be maintained in a single file
	- Proofs-of-concept
- Overall not well-suited for:
	- Highly complex programs
	- Anything requiring a GUI
	- Fully cross-platform programs
	- Modular programs
- Pros related to this project:
	- I ([Jim](https://github.com/jim-collier)) am very proficient in Bash, even as limited as it is, and have a well-established toolkit.
	- Bash projects tend to be much simpler to maintain, by inherently relying heavily on high-level POSIX tools to do all of the heavy lifting.
	- As a result of the previous axiom, Bash scripts, if thoughtfully designed, paradoxically tend to perform well.
	- Bash script can even use Sqlite3 CLI interface without much fuss or complexity, though that often necessarily involves iteration - something Bash is very slow at. So its far better to stick with well-established, long-term API-stable, universally-installed POSIX tools. And if it just can't be done with POSIX tools (something surprisingly hard to do), then Bash shouldn't really be considered.
	- There is at least one good Bash linter now, which is a great help.
- Cons related to this project:
	- No type safety.
	- No true interactive debugging.
	- Not object-oriented, although various projects like these fake it to varying limited degrees:
		- [Skull](https://github.com/tomas/skull)
		- [bash-oop](https://github.com/lenormf/bash-oop)
		- [bash-scripts/objects](https://github.com/mnorin/bash-scripts/tree/master/objects)
	- Limited private and/or protected members (basically just `local -r varName`).
	- Interpreted line-by-line.
	- Modern Bash programming only works on limited environments:
		- Linux, BSD
		- Windows Subsystem for Linux (WSL or WSL2)
	- MacOS with a more recent Bash environment installed through Homebrew or MacPorts.
- Contenter? For this proof-of-concept project, absolutely. Not so much for the bigger projects on the horizon.

**Bottom line**: Bash is among the best languages for system task automation, and contrary to popular belief, even well-suited for small, focused utility programs. But although it is good for proofs-of-concept for larger projects, it's not cut out for the larger objectives of this project, or larger, more complex programs in general.

### C# (dotnet core)

- Repo: [x9incexc-cs](https://github.com/x9-testlab/x9incexc-cs)
- Overall best suited for:
- Overall not well-suited for:
- Pros related to this project:
	- I ([Jim](https://github.com/jim-collier)) am reasonably fluent in C#, so it's fairly quick and natural dev effort.
	- Dotnet core C# performs well.
	- Inherently cross-platform.
	- Dotnet core C# can now be "compiled" to a single machine-cde executable requiring no runtime. (Or more specifically, no preinstalled runtime. It actually gets included in the executable.)
	- With the right compile flags, dotnet core C# can compile to a single small executable that itself can run on any platform without modification - as long as the correct runtime environment is already installed.
- Cons related to this project:
- Contender?

**Bottom line**:

	- •There's no way to statically link Sqlite3 into an exe; it has to be already installed. (There are kludges that allow packing it in the executable for runtime extraction, but it has to be the right one for the target platform, it's still not statically linked, and it's liable to trigger antivirus.)
	- The standard C# ADO-compatible Sqlite3 wrapper is currently broken, when it comes to compiling down to a single exe, due to a collision between the compiler-generated x86 and x86-64 target folders.
	- Single executables with the runtime built-in are huge, and actually self-extract to a temporary location before running. •Smaller executables that require pre-installed runtimes, are susceptible to almost certain bitrot in the long run. •**Many of these cons are individual deal-breakers for a project of this nature, which needs to be entirely self-contained and resistant to long-term bitrot.**

I ([Jim](https://github.com/jim-collier)) adore C#, especially now with dotnet core. But that doesn't mean it's the right tool for this job.

### C++ 17

- Repo: [x9incexc-cpp](https://github.com/x9-testlab/x9incexc-cpp)
- Overall best suited for:
- Overall not well-suited for:
- Pros related to this project:
	- Compiles to single tiny machine code executable with no preexisting runtime required.
	- Sqlite3 can easily be statically linked into the final binary.
- Cons related to this project:
- Contender?

**Bottom line**:

•The ultimate in small footprint, speed, long-term maintainability, and long-term resistance to bitrot. •Easy to compile and statically link Sqlite3 as part of the build workflow. | What follows here is mostly opinion, but certainly not unique opinion: •Even with C++ 17, the language remains inscrutably arcane, anachronistic, and over-reliant on cryptic combinations of symbols rather than keywords, as syntax. •The investment in time to become an expert is daunting. •No one human - not even Stroustrup - can hold the entire language in one's head. •When even average C++ projects need a committee to decide and enforce what subset of C++ will be used and how, you know there may be a more fundamental problem suggesting that - while a language may be excellent - it may be too complex for human use. •Setting up the toolchain for C++ is always a bear. That should never be, say, 33% of a project effort. What build system? How to organize? What compiler? •Making that toolchain also be seamlessly cross-platform - especially including Windows - is a major headache. | All else being equal, C++ requires too much time fiddling with toolchain, cross-platform issues, mysterious syntax errors and other complexities of the language, and opportunities for leaks and segfaults. It's off the table.


 Same benefits as C# and CPP version (, but smaller, faster, more maintainable over a longer period of time, and has no external dependencies - not even sqlite3.

### Go

- Repo: [x9incexc-go](https://github.com/x9-testlab/x9incexc-go)
- Overall best suited for:
	- Rapid application development
	- Single executables with no external runtime dependencies
- Overall not well-suited for:
- Pros related to this project:
	- Being "strongly opinionated" is a good thing for quickly learning a new language, as there's often only one idiomatic way of doing something, baked into the language.
	- The entire language can be arguably held in the head of a single human being.
	- Compiles to single small machine code executable with no preexisting runtime required.
	- Can cross compile to different OSes, from one OS.
	- Sqlite3 can be statically linked into the final binary.
- Cons related to this project:
	- "Traditional" (e.g. Java, C++, C#) OOP idioms don't work well in Rust.
- Contender? Yes!

**Bottom line**: Go is a promising contender for the crown. Time will tell if topples C#, which is already looking promising.

### Python

- Overall best suited for:
	- Quick learning
	- Math and scientific applications
	- Rapid prototyping and tweaking
	- Consistent cross-platform behavior
	- Circumstances where it can be reliably depended upon that everyone has the same version Python runtime installed
	- Quick and easy Sqlite3 support
- Overall not well-suited for:
	- Runtime-free distributables
	- Small, single-file, machine code binary executables
	- High performance
	- Long-term or even medium-term resistance to bitrot
		- OS support for older runtime libraries gets dropped, third-party library support (e.g. sqlite3) gets dropped, etc.
- Pros related to this project:
	- I ([Jim](https://github.com/jim-collier)) am reasonably fluent in Python
	- Rapid prototyping and development
	- Sqlite3 bindings
	- Very easy to read and debug
	- Very free of what makes C++ such a bear to work with: Strings of arcane symbols as "syntax".
- Cons related to this project:
	- Dependency hell, especially involving "toolbox" code
	- Correct runtime must be installed
	- Guaranteed long-term bitrot
- Contender? Absolutely not

**Bottom line**: The myriad runtime and library dependencies - and resulting real-world, long-term bitrot issues of Python, make it a non-starter for this project. Furthermore the lack of a single-file, dependency-free machine code executable is also a problem. While "compilers" exist for Python, they only bundle up the runtime, are incredibly complex to get working, and somehow still usually requires the Python runtime to be installed.

### Rust

Since Rust is not being seriously considered - mainly due to it's complex syntax which in some cases is somehow even more arcane than C++, and steep learning curve - the pros and cons are not very well fleshed out.

- Overall best suited for:
	- Mission-critical, performance-focused, memory-safe binaries
	- Cross-platform without as many toolchain headaches as C++
	- Compiling to webassembly
	- Single executables with no external runtime dependencies
	- CS students learning a new language from scratch
- Overall not well-suited for:
	- Rapid application development
- Pros related to this project:
	- Small, fast, statically-linked machine-code executables with no external dependencies
- Cons related to this project:
	- Steed learning curve
	- "Traditional" (e.g. Java, C++, C#) OOP idioms don't work well in Rust.
- Contender? No.

**Bottom line**: Rust is too much of a departure from "traditional" OOP, and too sprawling of a new language, to make it worth it for this project. (There would need to be other requirements that Rust excels at, to make it worth the investment.)