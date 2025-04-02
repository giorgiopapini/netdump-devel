## What is netdump-devel?
netdump-devel package provides the header files needed to develop a custom dissector for the netdump CLI tool (repo: https://github.com/giorgiopapini/netdump).

⚠️ To compile your custom dissector correctly, the netdump CLI tool must be installed in your system.

## Installation
netdump-devel can be installed manually using make, or installed by using a package manager (RPM on Fedora, CentOS and RHEL).
You can install netdump-devel in those ways:

1) Install the program using ```sudo make install``` after cloning the repo.
2) Install the program using a package manager.

## Compile a custom dissector
To compile a custom dissector as a shared lib the ```libnetdump.so``` shared lib is required. This library is installed during the netdmup CLI tool installation process

⚠️ ```libnetdump.so``` must be located inside ```/usr/lib``` or ```/usr/lib64``` or ```usr/local/lib``` or ```usr/local/lib64```.

To compile your custom dissectors as a shared lib ```(.so)``` follow these steps:

1) Navigate to the folder in which is stored ```your_dissector.c``` file.
2) Run ```gcc -fPIC -shared -o your_dissector.so your_dissector.c -lnetdump```.

Once ```your_dissector.so``` is compiled, run netdump CLI tool and execute ```dissectors -add "path-to-your-dissector"```.
Now your custom dissector is correctly loaded inside netdump and it is ready to use.

## Create your first custom dissector
